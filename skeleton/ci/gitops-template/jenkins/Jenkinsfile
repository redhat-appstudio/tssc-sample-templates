library identifier: 'RHTAP_Jenkins@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://github.com/redhat-appstudio/tssc-sample-jenkins.git'])

pipeline {
    agent any
    stages {
        stage('Compute Image Changes') {
            steps {
                script {
                    rhtap.info('gather_deploy_images')
                    rhtap.gather_deploy_images()
                }
            }
        }
        stage('Verify EC') {
            environment {
                COSIGN_PUBLIC_KEY = credentials('COSIGN_PUBLIC_KEY')
            }
            steps {
                script {
                    rhtap.info('verify_enterprise_contract')
                    rhtap.verify_enterprise_contract()
                }
            }
        }
    }
}