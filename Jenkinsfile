pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        CLUSTER_NAME = 'dev-microservices-cluster'
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
        choice(name: 'SERVICE', choices: ['all', 'order-service', 'user-service'], description: 'Service')
        booleanParam(name: 'SKIP_INFRA', defaultValue: true, description: 'Skip infra (keep true for now)')
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning repo...'
                checkout scm
            }
        }

        stage('Install Basic Tools') {
            steps {
                sh '''
                    sudo apt update -y
                    sudo apt install -y unzip curl
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ?
                        ['order-service', 'user-service'] :
                        [params.SERVICE]

                    services.each { service ->
                        dir(service) {
                            echo "Building ${service}..."
                            sh """
                                docker build -t ${service}:${DOCKER_IMAGE_TAG} .
                            """
                        }
                    }
                }
            }
        }

        stage('Verify Docker Images') {
            steps {
                sh 'docker images'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
