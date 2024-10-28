# from init
export REBUILD=${REBUILD-true}
export SKIP_CHECKS=${SKIP_CHECKS-true}

CI_TYPE=${CI_TYPE:-jenkins}

# from buildah-rhtap
TAG=$(git rev-parse HEAD)
export IMAGE_URL=${IMAGE_URL-${{ values.image }}:$CI_TYPE-$TAG}
export IMAGE=${IMAGE-$IMAGE_URL}

export DOCKERFILE=${DOCKERFILE-${{ values.dockerfile }}}
export CONTEXT=${CONTEXT-${{ values.buildContext }}}
export TLSVERIFY=${TLSVERIFY-false}
export BUILD_ARGS=${BUILD_ARGS-""}
export BUILD_ARGS_FILE=${BUILD_ARGS_FILE-""}

# from ACS_*.*
export DISABLE_ACS=${DISABLE_ACS-false}
# Optionally set ROX_CENTRAL_ENDPOINT here instead of configuring a Jenkins secret
# export ROX_CENTRAL_ENDPOINT=central-acs.apps.user.cluster.domain.com:443
export INSECURE_SKIP_TLS_VERIFY=${INSECURE_SKIP_TLS_VERIFY-true}

# for gitops, if acs scans are set, we still may not want that repo 
# to be updates so include an option to disable

export DISABLE_GITOPS_UPDATE=${DISABLE_GITOPS_UPDATE-false}
export GITOPS_REPO_URL=${{ values.repoURL }}

export PARAM_IMAGE=${PARAM_IMAGE-$IMAGE}
# Recompute this every time, otherwise it will be set BEFORE the file exists
# and be stuck at latest
export PARAM_IMAGE_DIGEST=$(cat "$BASE_RESULTS/buildah-rhtap/IMAGE_DIGEST" 2>/dev/null || echo "latest")

# From Summary
export SOURCE_BUILD_RESULT_FILE=${SOURCE_BUILD_RESULT_FILE-""}

# gather images params

export TARGET_BRANCH=${TARGET_BRANCH-""}
# enterprise contract
export POLICY_CONFIGURATION=${POLICY_CONFIGURATION-"github.com/enterprise-contract/config//rhtap-jenkins"}
#internal, assumes jenkins is local openshift
export REKOR_HOST=${REKOR_HOST-http://rekor-server.rhtap-tas.svc}
export IGNORE_REKOR=${IGNORE_REKOR-false}
export INFO=${INFO-true}
export STRICT=${STRICT-true}
export EFFECTIVE_TIME=${EFFECTIVE_TIME-now}
export HOMEDIR=${HOMEDIR-$(pwd)}
export TUF_MIRROR=${TUF_MIRROR-http://tuf.rhtap-tas.svc}
