// Microservices Deployment Pipeline - SIMPLIFIED
pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        CLUSTER_NAME = 'dev-microservices-cluster'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        ECR_REGISTRY = credentials('ecr-registry-url')
    }

    parameters {
        choice(name: 'SERVICE', choices: ['all', 'order-service', 'user-service'], description: 'Select service(s) to deploy')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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
                            sh "docker build -t ${service}:${DOCKER_IMAGE_TAG} ."
                        }
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]

                    withAWS(region: env.AWS_REGION, credentials: 'aws-credentials') {
                        sh '''
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        '''

                        services.each { service ->
                            sh '''
                                docker tag ${service}:${DOCKER_IMAGE_TAG} \
                                    ${ECR_REGISTRY}/${service}:${DOCKER_IMAGE_TAG}
                                docker push ${ECR_REGISTRY}/${service}:${DOCKER_IMAGE_TAG}
                                docker push ${ECR_REGISTRY}/${service}:latest
                            '''
                        }
                    }
                }
            }
        }

        stage('Update Manifests') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]

                    services.each { service ->
                        sh '''
                            sed -i "s|image: .*|image: ${ECR_REGISTRY}/${service}:${DOCKER_IMAGE_TAG}|" \
                                k8s/${service}-deployment.yaml
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]

                    withAWS(region: env.AWS_REGION, credentials: 'aws-credentials') {
                        sh '''
                            aws eks update-kubeconfig \
                                --name ${CLUSTER_NAME} \
                                --region ${AWS_REGION}
                        '''

                        services.each { service ->
                            sh '''
                                kubectl apply -f k8s/${service}-deployment.yaml
                                kubectl rollout status deployment/${service} \
                                    -n default --timeout=5m
                            '''
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "=== Pods Status ==="
                    kubectl get pods -n default
                    echo ""
                    echo "=== Services Status ==="
                    kubectl get svc -n default
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
