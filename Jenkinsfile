// filepath: Jenkinsfile
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        TERRAFORM_VERSION = '1.6.0'
        KUBECTL_VERSION = '1.31.0'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        CLUSTER_NAME = 'dev-microservices-cluster'
        EKS_CLUSTER_ENDPOINT = credentials('eks-cluster-endpoint')
    }
    
    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Choose Terraform action')
        choice(name: 'SERVICE', choices: ['all', 'order-service', 'user-service'], description: 'Select microservice to deploy')
        booleanParam(name: 'SKIP_INFRA', defaultValue: false, description: 'Skip infrastructure deployment')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Install Tools') {
            steps {
                script {
                    // Install Terraform
                    sh '''
                        if ! command -v terraform &> /dev/null; then
                            wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/
                            rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        fi
                    '''
                    
                    // Install kubectl
                    sh '''
                        if ! command -v kubectl &> /dev/null; then
                            curl -s -o /usr/local/bin/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
                            chmod +x /usr/local/bin/kubectl
                        fi
                    '''
                    
                    // Install AWS CLI
                    sh '''
                        if ! command -v aws &> /dev/null; then
                            curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                            unzip -o awscliv2.zip
                            ./aws/install
                            rm -rf awscliv2.zip aws
                        fi
                    '''
                }
            }
        }
        
        stage('Configure AWS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION
                        aws configure set output json
                    '''
                }
            }
        }
        
        // ==================== INFRASTRUCTURE STAGES ====================
        stage('Terraform Init') {
            when {
                expression { return !params.SKIP_INFRA }
            }
            steps {
                dir('terraform') {
                    sh '''
                        terraform init -upgrade
                        terraform workspace select dev || terraform workspace new dev
                    '''
                }
            }
        }
        
        stage('Terraform Validate') {
            when {
                expression { return !params.SKIP_INFRA }
            }
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { return !params.SKIP_INFRA && params.ACTION == 'plan' }
            }
            steps {
                dir('terraform') {
                    sh '''
                        terraform plan -out=tfplan \
                            -var="environment=dev" \
                            -var="region=${AWS_REGION}"
                    '''
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { return !params.SKIP_INFRA && params.ACTION == 'apply' }
            }
            steps {
                dir('terraform') {
                    sh '''
                        terraform apply -auto-approve \
                            -var="environment=dev" \
                            -var="region=${AWS_REGION}"
                    '''
                }
                // Update kubeconfig after EKS creation
                sh '''
                    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                '''
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { return !params.SKIP_INFRA && params.ACTION == 'destroy' }
            }
            steps {
                dir('terraform') {
                    input message: 'Are you sure you want to destroy infrastructure?', ok: 'Destroy'
                    sh '''
                        terraform destroy -auto-approve \
                            -var="environment=dev" \
                            -var="region=${AWS_REGION}"
                    '''
                }
            }
        }
        
        // ==================== BUILD STAGES ====================
        stage('Build Docker Images') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]
                    
                    services.each { service ->
                        dir(service) {
                            echo "Building Docker image for ${service}..."
                            sh """
                                docker build -t ${service}:${DOCKER_IMAGE_TAG} .
                                docker tag ${service}:${DOCKER_IMAGE_TAG} ${service}:latest
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        def services = params.SERVICE == 'all' ? 
                            ['order-service', 'user-service'] : 
                            [params.SERVICE]
                        
                        def ecr_repo = credentials('ecr-repository')
                        
                        services.each { service ->
                            echo "Pushing ${service} to ECR..."
                            sh """
                                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ecr_repo
                                docker tag ${service}:latest ${ecr_repo}/${service}:${DOCKER_IMAGE_TAG}
                                docker tag ${service}:latest ${ecr_repo}/${service}:latest
                                docker push ${ecr_repo}/${service}:${DOCKER_IMAGE_TAG}
                                docker push ${ecr_repo}/${service}:latest
                            """
                        }
                    }
                }
            }
        }
        
        // ==================== DEPLOYMENT STAGES ====================
        stage('Update K8s Manifests') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]
                    
                    def ecr_repo = credentials('ecr-repository')
                    
                    services.each { service ->
                        sh """
                            sed -i 's|image: .*|image: ${ecr_repo}/${service}:${DOCKER_IMAGE_TAG}|' k8s/${service}-deployment.yaml
                        """
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
                    
                    services.each { service ->
                        echo "Deploying ${service} to EKS..."
                        sh """
                            kubectl apply -f k8s/${service}-deployment.yaml
                            kubectl rollout status deployment/${service} -n default --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    sh '''
                        echo "Checking pod status..."
                        kubectl get pods -n default
                        echo "Checking services..."
                        kubectl get svc -n default
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    def services = params.SERVICE == 'all' ? 
                        ['order-service', 'user-service'] : 
                        [params.SERVICE]
                    
                    services.each { service ->
                        echo "Waiting for ${service} to be ready..."
                        sh """
                            for i in {1..30}; do
                                POD_NAME=\$(kubectl get pods -n default -l app=${service} -o jsonpath='{.items[0].metadata.name}')
                                if [ ! -z "\$POD_NAME" ]; then
                                    STATUS=\$(kubectl get pod \$POD_NAME -n default -o jsonpath='{.status.phase}')
                                    if [ "\$STATUS" == "Running" ]; then
                                        echo "${service} is running"
                                        break
                                    fi
                                fi
                                sleep 2
                            done
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            emailext (
                subject: "SUCCESS: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Successful</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build:</b> #${env.BUILD_NUMBER}</p>
                    <p><b>Action:</b> ${params.ACTION}</p>
                    <p><b>Service:</b> ${params.SERVICE}</p>
                    <p><b>Docker Tag:</b> ${DOCKER_IMAGE_TAG}</p>
                """,
                to: 'team@example.com'
            )
        }
        failure {
            echo 'Pipeline failed!'
            emailext (
                subject: "FAILED: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Failed</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build:</b> #${env.BUILD_NUMBER}</p>
                    <p><b>Action:</b> ${params.ACTION}</p>
                    <p><b>Service:</b> ${params.SERVICE}</p>
                """,
                to: 'team@example.com'
            )
        }
        always {
            cleanWs()
        }
    }
}