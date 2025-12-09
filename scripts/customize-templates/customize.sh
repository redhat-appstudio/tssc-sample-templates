#!/bin/bash

# Script to customize RHADS sample templates with forked repositories for pipelines
# and customized app deployment namespace in templates

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOTDIR=$(realpath $SCRIPTDIR/../..)

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
DRY_RUN="false" # Default to false, can be overridden by --dry-run flag

# Default values for customization flags
UPDATE_PIPELINE_REF="${UPDATE_PIPELINE_REF:-true}"

# Variable for customizing default app namespace (optional)
DEFAULT_APP_NAMESPACE="${DEFAULT_APP_NAMESPACE:-}"

# Variable for forking pipeline repository before customization
FORK_REPOS="${FORK_REPOS:-true}"

SRC_TEKTON=$ROOTDIR/skeleton/ci/source-repo/tekton/.tekton
GITOPS_TEKTON=$ROOTDIR/skeleton/ci/gitops-template/tekton/.tekton
TEMPLATES_DIR=$ROOTDIR/templates

export PROPERTIES_FILE="$ROOTDIR/properties"

# Upstream repository configuration (can be overridden via environment variables)
UPSTREAM_TEMPLATES_REPO="https://github.com/redhat-appstudio/tssc-sample-templates"
UPSTREAM_TEMPLATES_BRANCH="${UPSTREAM_TEMPLATES_BRANCH:-main}"
UPSTREAM_PIPELINES_REPO="https://github.com/redhat-appstudio/tssc-sample-pipelines"
UPSTREAM_PIPELINES_BRANCH="${UPSTREAM_PIPELINES_BRANCH:-main}"

# Headers for GitHub API authentication
HTTP_CODE_HEADER="\n%{http_code}"
API_HEADER="Accept: application/vnd.github+json"
AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"

# Git current repository information
CURRENT_GIT_ORG=""
CURRENT_GIT_REPO=""
CURRENT_GIT_BRANCH=""

# Branch name for customization (generated once in main() and reused)
CUSTOMIZE_BRANCH_NAME=""

# Extracted org/repo information (set by extract_org_and_repo() and used across functions)
EXTRACTED_ORG=""
EXTRACTED_REPO=""

TARGET_PATHS=(
    "$SRC_TEKTON"
    "$GITOPS_TEKTON"
    "$TEMPLATES_DIR"
)

# Function to log messages
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Function to check if GitHub token is provided
check_github_variables() {
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log "ERROR" "❌ GitHub token (GITHUB_TOKEN) must be set"
        return 1
    fi
    log "INFO" "✅ GitHub token (GITHUB_TOKEN) is set"
    return 0
}

# Function to extract org and repo name from GitHub URL
# Sets global variables EXTRACTED_ORG and EXTRACTED_REPO
extract_org_and_repo() {
    local repo_url=$1
    
    if [[ $repo_url =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
        EXTRACTED_ORG="${BASH_REMATCH[1]}"
        EXTRACTED_REPO="${BASH_REMATCH[2]}"
        EXTRACTED_REPO="${EXTRACTED_REPO%.git}"
        return 0
    else
        log "ERROR" "Invalid repository URL format: $repo_url"
        return 1
    fi
}

# Function to check if repository exists in organization
check_repo_exists() {
    local org=$1
    local repo_name=$2
    
    local response
    response=$(curl -s -w "$HTTP_CODE_HEADER" \
        -H "$API_HEADER"  \
        -H "$AUTH_HEADER" \
        "https://api.github.com/repos/$org/$repo_name" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    if [[ "$http_code" == "200" ]]; then
        return 0  # Repository exists
    else
        return 1  # Repository does not exist
    fi
}

# Function to create a branch from upstream
create_branch_from_upstream() {
    local upstream_org=$1
    local fork_org=$2
    local repo_name=$3
    local branch_name=$4
    local upstream_branch=$5
    local dry_run=$6
    
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY RUN] Would create branch: $branch_name from $upstream_org/$repo_name:$upstream_branch in $fork_org/$repo_name"
        return 0
    fi
    
    log "INFO" "Creating branch $branch_name from $upstream_org/$repo_name:$upstream_branch in $fork_org/$repo_name..."
    
    # Get the SHA of upstream branch
    log "INFO" "Getting SHA from upstream: $upstream_org/$repo_name branch: $upstream_branch"
    
    local sha=""
    local ref_response
    ref_response=$(curl -s -w "$HTTP_CODE_HEADER" \
        -H "$API_HEADER" \
        -H "$AUTH_HEADER" \
        "https://api.github.com/repos/$upstream_org/$repo_name/git/ref/heads/$upstream_branch" 2>/dev/null)
    
    local http_code=$(echo "$ref_response" | tail -n1)
    local body=$(echo "$ref_response" | sed '$d')
    
    if [[ "$http_code" == "200" ]]; then
        sha=$(echo "$body" | sed -n 's/.*"sha": *"\([^"]*\)".*/\1/p' | head -n 1)
        log "INFO" "Got SHA from upstream: $sha"
    else
        log "WARN" "HTTP $http_code when getting upstream branch SHA"
    fi
    
    if [[ -z "$sha" ]]; then
        log "ERROR" "Failed to get SHA from upstream branch $upstream_org/$repo_name:$upstream_branch"
        return 1
    fi
    
    # Create new branch in the forked repo using the upstream SHA
    log "INFO" "Creating branch $branch_name in $fork_org/$repo_name with SHA from upstream"
    local create_response
    create_response=$(curl -s -w "$HTTP_CODE_HEADER" \
        -X POST \
        -H "$API_HEADER" \
        -H "$AUTH_HEADER" \
        "https://api.github.com/repos/$fork_org/$repo_name/git/refs" \
        -d "{\"ref\":\"refs/heads/$branch_name\",\"sha\":\"$sha\"}" 2>/dev/null)
    
    local http_code=$(echo "$create_response" | tail -n1)
    if [[ "$http_code" == "201" ]]; then
        log "INFO" "✅ Created branch: $branch_name"
        return 0
    else
        log "ERROR" "❌ Failed to create branch. HTTP $http_code"
        return 1
    fi
}

# Function to check if a GitHub account is an organization
check_is_organization() {
    local account=$1
    
    local response
    response=$(curl -s -w "$HTTP_CODE_HEADER" \
        -H "$API_HEADER" \
        -H "$AUTH_HEADER" \
        "https://api.github.com/orgs/$account" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    if [[ "$http_code" == "200" ]]; then
        return 0  # Is an organization
    else
        return 1  # Is a user account or doesn't exist
    fi
}

# Function to fork a repository using GitHub API
fork_repository() {
    local upstream_org=$1
    local target_org=$2
    local repo_name=$3
    local dry_run=$4
    
    if [[ "$dry_run" == "true" ]]; then
        echo "  [DRY RUN] Would fork: $upstream_org/$repo_name -> $target_org/$repo_name"
        return 0
    fi
    log "INFO" "Forking $upstream_org/$repo_name to $target_org/$repo_name..."
    
    # Check if target is an organization or user account
    local fork_data
    if check_is_organization "$target_org"; then
        fork_data="{\"organization\":\"$target_org\"}"
        log "INFO" "Target is an organization, forking to organization account"
    else
        fork_data="{}"
        log "INFO" "Target is a user account, forking to user account"
    fi
    
    # Fork using GitHub API
    local fork_response
    fork_response=$(curl -s -w "$HTTP_CODE_HEADER" \
        -X POST \
        -H "$API_HEADER" \
        -H "$AUTH_HEADER" \
        "https://api.github.com/repos/$upstream_org/$repo_name/forks" \
        -d "$fork_data" 2>/dev/null)
    
    local http_code=$(echo "$fork_response" | tail -n1)
    local body=$(echo "$fork_response" | sed '$d')
    
    if [[ "$http_code" == "202" ]] || [[ "$http_code" == "200" ]]; then
        log "INFO" "✅ Successfully forked: $target_org/$repo_name"
        return 0
    else
        log "ERROR" "❌ Failed to fork repository. HTTP $http_code: $body"
        return 1
    fi
}

# Function to get and store git repository information
get_git_info() {
    # Get the remote URL
    local remote_url
    if ! remote_url=$(git remote get-url origin 2>/dev/null); then
        log "ERROR" "Git remote 'origin' not found"
        return 1
    fi
    
    # Extract organization and repository from URL
    if ! extract_org_and_repo "$remote_url"; then
        log "ERROR" "Could not extract organization/repository from URL: $remote_url"
        return 1
    fi
    
    CURRENT_GIT_ORG="$EXTRACTED_ORG"
    CURRENT_GIT_REPO="$EXTRACTED_REPO"
    CURRENT_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    return 0
}

# Function to verify current git repo is not upstream
verify_is_repo_fork() {
    log "INFO" "Verifying current repository is not upstream..."
    
    if [[ "$CURRENT_GIT_ORG" == "redhat-appstudio" ]]; then
        log "ERROR" "❌ Current repository organization is 'redhat-appstudio'"
        echo "Please run this script from your forked repository"
        return 1
    fi
    
    log "INFO" "✅ Repository is a fork (not upstream)"
    return 0
}

# Function to create and checkout branch from upstream templates
checkout_template_branch() {
    echo -e "\n--- Creating New Branch from Upstream Templates ---\n"
    
    # Add or update upstream remote (always ensure correct URL)
    if git remote set-url upstream "$UPSTREAM_TEMPLATES_REPO" 2>/dev/null; then
        log "INFO" "Updated upstream remote URL: $UPSTREAM_TEMPLATES_REPO"
    elif git remote add upstream "$UPSTREAM_TEMPLATES_REPO" 2>/dev/null; then
        log "INFO" "Added upstream remote: $UPSTREAM_TEMPLATES_REPO"
    else
        log "ERROR" "Failed to add or update upstream remote"
        return 1
    fi
    
    # Fetch from upstream
    log "INFO" "Fetching from upstream branch: $UPSTREAM_TEMPLATES_BRANCH"
    if ! git fetch upstream "$UPSTREAM_TEMPLATES_BRANCH"; then
        log "ERROR" "Failed to fetch from upstream branch: $UPSTREAM_TEMPLATES_BRANCH"
        return 1
    fi
    
    # Create and checkout branch from upstream
    log "INFO" "Creating and checking out branch: $CUSTOMIZE_BRANCH_NAME from upstream/$UPSTREAM_TEMPLATES_BRANCH"
    if ! git checkout -b "$CUSTOMIZE_BRANCH_NAME" "upstream/$UPSTREAM_TEMPLATES_BRANCH"; then
        log "ERROR" "Failed to create and checkout branch: $CUSTOMIZE_BRANCH_NAME"
        return 1
    fi
    
    return 0
}

# Function to check if target files are already modified or uncommitted
check_pre_existing_changes() {
    log "INFO" "Checking for pre-existing changes in target files..."
    local pre_existing_files=()
    
    # Check each target file/folder for uncommitted changes
    for path in "${TARGET_PATHS[@]}"; do
        if git status --porcelain "$path" 2>/dev/null | grep -q "^"; then
            pre_existing_files+=("$path")
        fi
    done
    
    if [[ ${#pre_existing_files[@]} -gt 0 ]]; then
        log "ERROR" "❌ Pre-existing uncommitted changes detected in target files"
        for file in "${pre_existing_files[@]}"; do
            echo "  - $file"
        done
        echo "Manually commit or stash the pre-existing changes before running the script."
        return 1
    else
        log "INFO" "✅ No pre-existing changes in target files"
        return 0
    fi
}

# Function to run automated git workflow
run_automated_git_workflow() {
    echo -e "\n--- Automated Git Commit ---\n"
    log "INFO" "Starting automated git commit and push..."
    
    log "INFO" "Output of 'git status' command:"
    git status --short
    
    local files_staged=0
    
    # Use TARGET_PATHS variable to stage changes
    for path in "${TARGET_PATHS[@]}"; do
        if git status --porcelain "$path" 2>/dev/null | grep -q "^"; then
            git add "$path"
            log "INFO" "✅ Staged $path"
            files_staged=$((files_staged + 1))
        fi
    done
    
    if [[ $files_staged -eq 0 ]]; then
        log "WARN" "No target files have changes to stage"
        return 1
    fi
    
    echo "Total files/folders staged: $files_staged"
    
    # Commit the changes
    local commit_message="Customize templates for ${CURRENT_GIT_ORG}"
    log "INFO" "Committing changes with message: $commit_message"
    
    if ! git commit -m "$commit_message"; then
        log "ERROR" "Failed to commit changes"
        return 1
    fi
    
    echo "✅ Committed changes successfully"
    
    # Push changes to remote
    log "INFO" "Pushing changes to branch ${CURRENT_GIT_BRANCH}..."
    
    if git push origin "${CURRENT_GIT_BRANCH}"; then
        log "INFO" "✅ Pushed changes to branch: ${CURRENT_GIT_BRANCH}"
    else
        log "WARN" "Failed to push changes automatically"
        echo "You may need to push manually: git push origin ${CURRENT_GIT_BRANCH}"
    fi
    
    return 0
}

# Function to update Tekton pipeline references
update_tekton_definition() {
    echo -e "\n--- Updating Tekton pipeline references ---\n"
    log "INFO" "Running update-tekton-definition..."

    if [[ -z "${PIPELINE__REPO__URL:-}" ]] || [[ -z "${PIPELINE__REPO__BRANCH:-}" ]]; then
        log "ERROR" "Both pipeline variables (PIPELINE__REPO__URL and PIPELINE__REPO__BRANCH) must be set"
        return 1
    fi

    echo "Using Pipeline Repository: $PIPELINE__REPO__URL with Branch: $PIPELINE__REPO__BRANCH"

    if "$ROOTDIR/scripts/update-tekton-definition" "$PIPELINE__REPO__URL" "$PIPELINE__REPO__BRANCH"; then
        log "INFO" "✅ Tekton pipeline references updated successfully"
        return 0
    else
        log "ERROR" "Failed to update Tekton pipeline references"
        return 1
    fi
}

# Function to fork repositories (integrated from fork_repos.sh)
run_fork_repos() {
    echo -e "\n--- Forking Repositories ---\n"
    
    # Use current repository's organization for forking
    local fork_org="$CURRENT_GIT_ORG"
    log "INFO" "FORK_REPOS is enabled, forking repository in $fork_org"
    
    # Use the global branch name variable (generated in main())
    local branch_name="$CUSTOMIZE_BRANCH_NAME"
    
    # Extract upstream organization and repository from UPSTREAM_PIPELINES_REPO
    if ! extract_org_and_repo "$UPSTREAM_PIPELINES_REPO"; then
        log "ERROR" "Invalid upstream repository URL format: $UPSTREAM_PIPELINES_REPO"
        return 1
    fi
    local upstream_org="$EXTRACTED_ORG"
    local upstream_repo="$EXTRACTED_REPO"
    
    # Check if repository already exists, else fork it
    if check_repo_exists "$fork_org" "$upstream_repo"; then
        echo "  ℹ️  Repository already exists: $fork_org/$upstream_repo"
    else
        if ! fork_repository "$upstream_org" "$fork_org" "$upstream_repo" "$DRY_RUN"; then
            log "ERROR" "Failed to fork repository"
            return 1
        fi
    fi
    
    # Wait for fork to be available (we get SHA from upstream, so no need to wait for branches to sync)
    if [[ "$DRY_RUN" == "false" ]]; then
        local retry_count=0
        while [[ $retry_count -lt 5 ]] && ! check_repo_exists "$fork_org" "$upstream_repo"; do
            log "INFO" "Waiting for fork to complete... (attempt $((retry_count + 1))/5)"
            sleep 2
            retry_count=$((retry_count + 1))
        done
    fi
    
    # Create branch from upstream
    if ! create_branch_from_upstream "$upstream_org" "$fork_org" "$upstream_repo" "$branch_name" "$UPSTREAM_PIPELINES_BRANCH" "$DRY_RUN"; then
        log "WARN" "Failed to create branch $branch_name in $upstream_repo, continuing..."
    fi
    
    # Update properties file with Pipelines repository URLs and branches
    echo -e "\n--- Updating Properties File ---\n"
    sed -i "s|^export PIPELINE__REPO__URL=.*|export PIPELINE__REPO__URL=https://github.com/$fork_org/$upstream_repo|" "$PROPERTIES_FILE"
    sed -i "s|^export PIPELINE__REPO__BRANCH=.*|export PIPELINE__REPO__BRANCH=$branch_name|" "$PROPERTIES_FILE"
    
    log "INFO" "✅ Properties file updated successfully!"
    
    # Source properties file to load updated repository URLs and branches
    source "$PROPERTIES_FILE"
    log "INFO" "Reloaded properties file with updated repository URLs"
 
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "✅ Dry run completed. Use without --dry-run to actually fork repositories."
    else
        log "INFO" "Fork repositories completed successfully"
    fi
    
    return 0
}

# Function to update customize app namespace
update_app_namespace_in_templates() {
    echo -e "\n--- Update Namespace and Templates ---\n"

    local namespace_value=$1
    sed -i "s|^export DEFAULT__DEPLOYMENT__NAMESPACE__PREFIX=.*|export DEFAULT__DEPLOYMENT__NAMESPACE__PREFIX=$namespace_value|" "$PROPERTIES_FILE"
    log "INFO" "Updated DEFAULT__DEPLOYMENT__NAMESPACE__PREFIX to $namespace_value in $PROPERTIES_FILE"
    
    log "INFO" "Running update-templates script..."
    if "$ROOTDIR/scripts/update-templates"; then
        log "INFO" "✅ update-templates script completed successfully"
        return 0
    else
        log "ERROR" "❌ update-templates script failed"
        return 1
    fi
}

# Function to check all prerequisites
check_prerequisites() {
    echo -e "\n--- Prerequisites Check ---\n"
    
    local prerequisites_passed=true
    
    log "INFO" "Check 1: GitHub token (GITHUB_TOKEN) is set"
    if ! check_github_variables; then
        prerequisites_passed=false
    fi

    log "INFO" "Check 2: Repository is not upstream (redhat-appstudio)"
    if ! verify_is_repo_fork; then
        prerequisites_passed=false
    fi
    
    log "INFO" "Check 3: No pre-existing changes in target files"
    if ! check_pre_existing_changes; then
        prerequisites_passed=false
    fi
    
    if [[ "$prerequisites_passed" == "true" ]]; then
        log "INFO" "All prerequisites checks passed"
        return 0
    else
        log "ERROR" "Prerequisites checks failed"
        log "INFO" "❌ Please fix the issues above before running the customization"
        return 1
    fi
}

# Function to display usage
usage() {
    echo ""
    echo "Script to customize RHADS sample templates with forked repositories and customize app namespace"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --dry-run               Run in dry-run mode (only update files, don't commit/push)"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN            GitHub personal access token"
    echo "  FORK_REPOS              Automatically fork pipeline repository (default: true)"
    echo "  UPDATE_PIPELINE_REF     Update Tekton pipeline references (default: true)"
    echo "  DEFAULT_APP_NAMESPACE   Customize default deployment namespace prefix (optional)"
    echo ""
    echo "Following environment variables are required if FORK_REPOS=false:"
    echo "  PIPELINE__REPO__URL     URL of your forked or custom pipeline repository"
    echo "  PIPELINE__REPO__BRANCH  Branch name to use from the pipeline repository"
    echo ""
}

# Function to parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        local arg=$1
        case $arg in
            -h|--help)
                usage
                exit 0
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $arg"
                usage
                exit 1
                ;;
        esac
    done
}

main() {
    # Parse command-line arguments
    parse_arguments "$@"
    
    echo ""
    echo "=========================================="
    echo "  RHADS Sample Templates Customization"
    echo "=========================================="
    echo ""
    
    echo "Configuration:"
    echo "  Dry Run:                    $DRY_RUN"
    echo "  Fork Repositories:          $FORK_REPOS"
    echo "  Update Pipeline References: $UPDATE_PIPELINE_REF"
    if [[ -n "${DEFAULT_APP_NAMESPACE:-}" ]]; then
        echo "  Update Custom Namespace:    $DEFAULT_APP_NAMESPACE"
    fi
    
    # Get git repository information once (exported for all functions)
    log "INFO" "Getting git repository information..."
    if ! get_git_info; then
        log "ERROR" "Failed to get git repository information, exiting"
        exit 1
    fi
    log "INFO" "Current Repository: $CURRENT_GIT_ORG/$CURRENT_GIT_REPO (branch: ${CURRENT_GIT_BRANCH})"
    
    # Check prerequisites before proceeding
    if ! check_prerequisites; then
        log "ERROR" "Prerequisites check failed, exiting"
        exit 1
    fi
    
    # Generate timestamp-based branch name once and reuse it
    local branch_suffix=$(date +%Y%m%d_%H%M%S)
    CUSTOMIZE_BRANCH_NAME="customize_${branch_suffix}"
    log "INFO" "Generated branch name: $CUSTOMIZE_BRANCH_NAME"
    
    # Step 1: Create and checkout branch from upstream templates
    if ! checkout_template_branch; then
        log "ERROR" "Failed to create and checkout branch from upstream templates, exiting"
        exit 1
    fi
    
    # Update CURRENT_GIT_BRANCH to reflect the new branch
    CURRENT_GIT_BRANCH="$CUSTOMIZE_BRANCH_NAME"
    
    # Step 2: Fork repositories if enabled, else validate repository variables
    if [[ "$FORK_REPOS" == "true" ]]; then
        if ! run_fork_repos; then
            log "ERROR" "Fork repositories step failed, exiting"
            exit 1
        fi
    else
        log "INFO" "Skipping fork repositories step (FORK_REPOS=false)"
    fi
    
    # Step 3: Update Tekton pipeline references
    if [[ "$UPDATE_PIPELINE_REF" == "true" ]]; then
        if ! update_tekton_definition; then
            log "ERROR" "Failed to update Tekton pipeline references"
            exit 1
        fi
    else
        log "INFO" "Skipping Tekton pipeline reference update (UPDATE_PIPELINE_REF=false)"
    fi
    
    # Step 4: Update namespace and run update-templates if DEFAULT_APP_NAMESPACE is set
    if [[ -n "${DEFAULT_APP_NAMESPACE:-}" ]]; then
        if ! update_app_namespace_in_templates "$DEFAULT_APP_NAMESPACE"; then
            log "ERROR" "Failed to update default app namespace to $DEFAULT_APP_NAMESPACE"
            exit 1
        fi
    else
        log "INFO" "Skipping namespace update (DEFAULT_APP_NAMESPACE not set)"
    fi
    
    # Step 5: Commit and push changes (unless dry run)
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Dry run mode enabled - skipping commit and push"
        if [[ "$FORK_REPOS" == "true" ]]; then
            log "INFO" "Fork repositories step enabled, but changes were not committed or pushed"
        fi
    else
        if run_automated_git_workflow; then
            log "INFO" "Automated git workflow completed successfully"
        else
            log "WARN" "Automated git workflow failed"
            log "INFO" "Manually commit and push the changes to your organization"
        fi
    fi
    
    echo -e "\n--- ✅ Customization Completed Successfully ---\n"
    echo "Your Developer Hub catalog url:"
    echo " https://github.com/${CURRENT_GIT_ORG}/${CURRENT_GIT_REPO}/blob/${CURRENT_GIT_BRANCH}/all.yaml"
}

# Run main workflow with all arguments
main "$@"
