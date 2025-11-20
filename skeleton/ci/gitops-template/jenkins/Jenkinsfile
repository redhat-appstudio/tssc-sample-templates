/* Generated from templates/gitops-template/Jenkinsfile.njk. Do not edit directly. */

pipeline {
    agent {
        kubernetes {
            yaml """
              apiVersion: v1
              kind: Pod
              spec:
                containers:
                - name: 'runner'
                  image: 'quay.io/redhat-appstudio/rhtap-task-runner:latest'
                  securityContext:
                    privileged: true
            """
        }
    }
    environment {
        HOME = "${WORKSPACE}"
        DOCKER_CONFIG = "${WORKSPACE}/.docker"
        ROX_CENTRAL_ENDPOINT = credentials('ROX_CENTRAL_ENDPOINT')
        /* Used to verify the image signature and attestation */
        COSIGN_PUBLIC_KEY = credentials('COSIGN_PUBLIC_KEY')
        /* URL of the BOMbastic api host (e.g. https://sbom.trustification.dev) */
        TRUSTIFICATION_BOMBASTIC_API_URL = credentials('TRUSTIFICATION_BOMBASTIC_API_URL')
        /* URL of the OIDC token issuer (e.g. https://sso.trustification.dev/realms/chicken) */
        TRUSTIFICATION_OIDC_ISSUER_URL = credentials('TRUSTIFICATION_OIDC_ISSUER_URL')
        TRUSTIFICATION_OIDC_CLIENT_ID = credentials('TRUSTIFICATION_OIDC_CLIENT_ID')
        TRUSTIFICATION_SUPPORTED_CYCLONEDX_VERSION = credentials('TRUSTIFICATION_SUPPORTED_CYCLONEDX_VERSION')
        /* Set this to the user for your specific registry */
        IMAGE_REGISTRY_USER = credentials('IMAGE_REGISTRY_USER')
        REKOR_HOST = credentials('REKOR_HOST')
        TUF_MIRROR = credentials('TUF_MIRROR')
        TRUSTIFICATION_OIDC_CLIENT_SECRET = credentials('TRUSTIFICATION_OIDC_CLIENT_SECRET')
        /* Set this password for your specific registry */
        IMAGE_REGISTRY_PASSWORD = credentials('IMAGE_REGISTRY_PASSWORD')
        QUAY_IO_CREDS = credentials('QUAY_IO_CREDS')
        /* ARTIFACTORY_IO_CREDS = credentials('ARTIFACTORY_IO_CREDS') */
        /* NEXUS_IO_CREDS = credentials('NEXUS_IO_CREDS') */
        COSIGN_SECRET_PASSWORD = credentials('COSIGN_SECRET_PASSWORD')
        COSIGN_SECRET_KEY = credentials('COSIGN_SECRET_KEY')
        ROX_API_TOKEN = credentials('ROX_API_TOKEN')
        GITOPS_AUTH_PASSWORD = credentials('GITOPS_AUTH_PASSWORD')
    }
    stages {
        stage('init') {
            steps {
                container('runner') {
                    sh '''
                        cp -R /work/* .
                        env
                        git config --global --add safe.directory $WORKSPACE
                        echo "running init"
                        ./tssc/init.sh
                    '''
                }
            }
        }
        stage('Verify Conforma') {
            steps {
                container('runner') {
                    sh '''
                        echo "running gather-deploy-images"
                        ./tssc/gather-deploy-images.sh
                        echo "running verify-conforma"
                        ./tssc/verify-conforma.sh
                    '''
                }
            }
        }

        stage('Upload SBOM') {
            steps {
                container('runner') {
                    sh '''
                        echo "running gather-images-to-upload-sbom"
                        ./tssc/gather-images-to-upload-sbom.sh
                        echo "running download-sbom-from-url-in-attestation"
                        ./tssc/download-sbom-from-url-in-attestation.sh
                        echo "running upload-sbom-to-trustification"
                        ./tssc/upload-sbom-to-trustification.sh
                    '''
                }
            }
        }

    }
}
