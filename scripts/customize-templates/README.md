# Customize Templates

The `customize.sh` script customizes Red Hat Advanced Developer Suite (RHADS) sample software templates by replacing existing Tekton pipeline references with your forked repository URLs and updating default app namespace.

[Here](https://docs.redhat.com/en/documentation/red_hat_advanced_developer_suite_-_software_supply_chain/1.7/html/customizing_red_hat_advanced_developer_suite_-_software_supply_chain/customizing-sample-pipelines_default) is the reference document.


## How the Script Works

The `customize.sh` script performs these steps:

1. **Verifies prerequisites**: Checks repository is a fork, GitHub token is set, and no pre-existing changes exist
2. **Creates branch from upstream**: Creates a new timestamped branch from the upstream templates branch and checks it out
3. **Forks pipelines repository** (if `FORK_REPOS=true`): Automatically forks [`tssc-sample-pipelines`](https://github.com/redhat-appstudio/tssc-sample-pipelines) to your GitHub organization/user and creates a timestamped branch from the upstream branch
4. **Updates Tekton pipeline references** (if `UPDATE_PIPELINE_REF=true`): Updates pipeline URLs in `.tekton/` directories
5. **Updates namespace** (if `DEFAULT_APP_NAMESPACE` is set): Updates namespace in `properties` file and regenerates templates
6. **Commits and pushes changes** (unless `--dry-run`): Automatically stages, commits, and pushes all changes


## Prerequisites

Before customizing the sample software templates, ensure you have the following prerequisites in place:

1. **Fork the templates repository** (Required): You must fork and clone the [TSSC sample templates](https://github.com/redhat-appstudio/tssc-sample-templates) repository. The script will not run if the current repository is `redhat-appstudio/tssc-sample-templates`.

2. **Fork pipelines repository** (Optional):
   - **Option A**: Let the script automatically fork it by setting `FORK_REPOS=true`
   - **Option B**: Manually fork and set up:
     * Fork the [TSSC sample pipelines](https://github.com/redhat-appstudio/tssc-sample-pipelines) repository on GitHub

## Command-Line Options

The `customize.sh` script supports the following command-line options:

- **`-h, --help`**: Show help message with usage information and exit
- **`--dry-run`**: Run in dry-run mode (only update files, don't commit/push changes). By default, the script commits and pushes changes automatically.

```bash
$ ./scripts/customize-templates/customize.sh -h

Script to customize RHADS sample templates with forked repositories and customize app namespace

Usage: ./scripts/customize-templates/customize.sh [OPTIONS]

Options:
  -h, --help              Show this help message
  --dry-run               Run in dry-run mode (only update files, don't commit/push)

Environment Variables:
  GITHUB_TOKEN            GitHub personal access token
  FORK_REPOS              Automatically fork pipeline repository (default: true)
  UPDATE_PIPELINE_REF     Update Tekton pipeline references (default: true)
  DEFAULT_APP_NAMESPACE   Customize default deployment namespace prefix (optional)

Following environment variables are required if FORK_REPOS=false:
  PIPELINE__REPO__URL     URL of your forked or custom pipeline repository
  PIPELINE__REPO__BRANCH  Branch name to use from the pipeline repository
```

## Configuration Variables

Required variables:

- **`GITHUB_TOKEN`**: GitHub personal access token with repository permissions

The following variables have default value and update if requires:

- **`UPDATE_PIPELINE_REF`** (default: `true`): Enable/disable Tekton pipeline reference updates
- **`DEFAULT_APP_NAMESPACE`** (optional): Customize the default deployment namespace prefix and regenerate templates
- **`FORK_REPOS`** (default: `true`): Automatically fork `tssc-sample-pipelines` to your GitHub organization

These variables are required if `FORK_REPOS=false` and you already have your pipeline forked repository setup:

- **`PIPELINE__REPO__URL`**: URL of your forked or custom pipeline repository
- **`PIPELINE__REPO__BRANCH`**: Branch name of your forked or custom pipeline repository

### Upstream Branch Configuration

By default, the script uses the `main` branch for both upstream repositories:
- **Templates repository**: `redhat-appstudio/tssc-sample-templates` (branch: `main`)
- **Pipelines repository**: `redhat-appstudio/tssc-sample-pipelines` (branch: `main`)

If you need to use a different upstream branch, you can set the following environment variables:

```bash
# Override upstream branch
export UPSTREAM_TEMPLATES_BRANCH="release-v1.8.x"
export UPSTREAM_PIPELINES_BRANCH="release-v1.8.x"
```

## Steps to Run the Script

### 1. Fork and Set Up Your Repository

Fork the repository and clone it:

```bash
# Fork the repository on GitHub (via web interface)
# Then clone your forked repository
git clone https://github.com/your-username/tssc-sample-templates.git
cd tssc-sample-templates
```

**Note:** The script will automatically create a branch from upstream branch when you run it.

### 2. Set Repository Variables

You have two options for setting up repository references:

**Option A: Auto-fork repositories**

```bash
export GITHUB_TOKEN=your-github-token
export FORK_REPOS=true
```

The script will fork the pipeline repository to your current repository's organization.

**Option B: Use existing repositories**

Set the repository URLs as environment variables:

```bash
export FORK_REPOS=false
export PIPELINE__REPO__URL=https://github.com/<your-org>/tssc-sample-pipelines
export PIPELINE__REPO__BRANCH=main
```

### 3. Run the Script

Run the customization script:

```bash
# Run normally (commits and pushes changes automatically)
./scripts/customize-templates/customize.sh

# Run in dry-run mode (only updates files, doesn't commit/push)
./scripts/customize-templates/customize.sh --dry-run
```

**Optional:** Set customization flags if you want to override defaults:

```bash
# Customize default app namespace (optional)
export DEFAULT_APP_NAMESPACE=my-custom-namespace
```

### 4. Push and Review Changes

By default, the script automatically commits and pushes changes. If you ran the script with `--dry-run`, the script only updates files and you need to manually commit and push:

```bash
# Review and commit the changes
git status
git add <files>

# Commit the changes
git commit -m "Customize templates for your-org"

# Push the changes to your org
git push origin $(git branch --show-current)
```

