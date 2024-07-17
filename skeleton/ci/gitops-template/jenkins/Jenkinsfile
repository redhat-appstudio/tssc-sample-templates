library identifier: 'RHTAP_Jenkins@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
   remote: 'https://github.com/redhat-appstudio/tssc-sample-jenkins.git'])

pipeline { 
    agent any
    stages {
        stage('Compute Image Changes') {
            steps {
                script { 
                    rhtap.info ("Compute Image Changes")
                    rhtap.gather_deploy_images() 
                }
            }
        }  
        stage('verify EC') {
            steps {
                script { 
                    rhtap.info ("Validate Enteprise Contract")
                    rhtap.verify_enterprise_contract() 
                }
            } 
        }  
    }
}