/* Generated from templates/source-repo/Jenkinsfile.njk. Do not edit directly. */

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
        /* GITOPS_AUTH_USERNAME = credentials('GITOPS_AUTH_USERNAME') */
        /* Set this to the user for your specific registry */
        IMAGE_REGISTRY_USER = credentials('IMAGE_REGISTRY_USER')
        REKOR_HOST = credentials('REKOR_HOST')
        TUF_MIRROR = credentials('TUF_MIRROR')
        /* Used to verify the image signature and attestation */
        COSIGN_PUBLIC_KEY = credentials('COSIGN_PUBLIC_KEY')
        /* Custom Root CA to be used in scripts as trusted */
        /* CUSTOM_ROOT_CA = credentials('CUSTOM_ROOT_CA') */
        ROX_API_TOKEN = credentials('ROX_API_TOKEN')
        GITOPS_AUTH_PASSWORD = credentials('GITOPS_AUTH_PASSWORD')
        /* Set this password for your specific registry */
        IMAGE_REGISTRY_PASSWORD = credentials('IMAGE_REGISTRY_PASSWORD')
        /* Default registry is set to quay.io */
        QUAY_IO_CREDS = credentials('QUAY_IO_CREDS')
        /* ARTIFACTORY_IO_CREDS = credentials('ARTIFACTORY_IO_CREDS') */
        /* NEXUS_IO_CREDS = credentials('NEXUS_IO_CREDS') */
        COSIGN_SECRET_PASSWORD = credentials('COSIGN_SECRET_PASSWORD')
        COSIGN_SECRET_KEY = credentials('COSIGN_SECRET_KEY')
    }
    stages {
        stage('pre-init') {
            steps {
                container('runner') {
                    sh '''
                        cp -R /work/* .
                        env
                        git config --global --add safe.directory $WORKSPACE
                    '''
                }
            }
        }
        stage('init') {
            steps {
                container('runner') {
                    sh '''
                        echo "running init"
                        ./tssc/init.sh
                    '''
                }
            }
        }

        stage('build') {
            steps {
                container('runner') {
                    sh '''
                        echo "running buildah-tssc"
                        ./tssc/buildah-tssc.sh
                        echo "running cosign-sign-attest"
                        ./tssc/cosign-sign-attest.sh
                    '''
                }
            }
        }

        stage('deploy') {
            steps {
                container('runner') {
                    sh '''
                        echo "running update-deployment"
                        ./tssc/update-deployment.sh
                    '''
                }
            }
        }

        stage('scan') {
            steps {
                container('runner') {
                    sh '''
                        echo "running acs-deploy-check"
                        ./tssc/acs-deploy-check.sh
                        echo "running acs-image-check"
                        ./tssc/acs-image-check.sh
                        echo "running acs-image-scan"
                        ./tssc/acs-image-scan.sh
                    '''
                }
            }
        }

        stage('summary') {
            steps {
                container('runner') {
                    sh '''
                        echo "running show-sbom-rhdh"
                        ./tssc/show-sbom-rhdh.sh
                        echo "running summary"
                        ./tssc/summary.sh
                    '''
                }
            }
        }

    }
}
