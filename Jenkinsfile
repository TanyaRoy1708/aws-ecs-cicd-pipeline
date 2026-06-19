// Load the shared library (configure this in Jenkins System Settings under "Global Pipeline Libraries" as "my-shared-library")
@Library('my-shared-library') _

pipeline {
    agent none  // Each stage runs in its own custom Docker agent for isolation

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID     = '123456789012' // Replace with actual AWS Account ID
        ECR_REPO           = 'devops-toolbox'
        ECR_REGISTRY       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
        ECS_CLUSTER        = 'devops-cluster'
        ECS_SERVICE        = 'devops-service'
        ECS_TASK_FAMILY    = 'devops-toolbox'
        // Define an immutable versioned tag: Build Number + Git Commit Hash
        IMAGE_TAG          = "${env.BUILD_NUMBER}-${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'latest'}"
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage('Secret Scan') {
            agent {
                docker {
                    image 'zricethezav/gitleaks:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                secretScan(softFail: true)
            }
        }

        stage('Lint Check') {
            agent {
                docker { image 'python:3.11-slim' }
            }
            steps {
                sh 'pip install ruff'
                sh 'ruff check app/'
            }
        }

        stage('IaC Scan') {
            agent {
                docker { image 'bridgecrew/checkov:latest' }
            }
            steps {
                iacScan(softFail: true, directory: 'terraform')
            }
        }

        stage('Terraform Validate') {
            agent {
                docker { image 'hashicorp/terraform:latest' }
            }
            steps {
                tfValidate(directory: 'terraform')
            }
        }

        stage('Unit Tests') {
            agent {
                docker { image 'python:3.11-slim' }
            }
            steps {
                sh 'pip install -r app/requirements.txt pytest'
                sh 'PYTHONPATH=. pytest app/'
            }
        }

        stage('SonarQube Quality Gate') {
            agent {
                docker { image 'sonarsource/sonar-scanner-cli:latest' }
            }
            steps {
                // Execute SAST checks via the shared library step
                sonarScan(projectKey: 'devops-toolbox', sources: 'app')
            }
        }

        stage('Trivy Dependency Scan') {
            agent {
                docker { image 'aquasec/trivy:latest' }
            }
            steps {
                // Stage A: Filesystem dependency vulnerability scan (failing on CRITICAL findings)
                trivyScan(type: 'fs', target: 'app', reportFile: 'trivy-fs-report.txt')
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-fs-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Build') {
            agent {
                docker {
                    image 'docker:24-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ./app"
            }
        }

        stage('Trivy Image Scan') {
            agent {
                docker { image 'aquasec/trivy:latest' }
            }
            steps {
                // Stage B: Built container image OS-layer scan (failing on CRITICAL findings)
                trivyScan(type: 'image', target: "${ECR_REPO}:${IMAGE_TAG}", reportFile: 'trivy-image-report.txt')
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-image-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Push to ECR') {
            agent {
                docker {
                    image 'amazon/aws-cli:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                // Push the immutable versioned tag to ECR registry
                pushToEcr(registry: ECR_REGISTRY, repoName: ECR_REPO, tag: IMAGE_TAG, region: AWS_DEFAULT_REGION)
            }
        }

        stage('Deploy to ECS') {
            agent {
                docker { image 'amazon/aws-cli:latest' }
            }
            steps {
                // Run rolling update to ECS and wait for stability
                deployToEcs(
                    cluster: ECS_CLUSTER,
                    service: ECS_SERVICE,
                    taskFamily: ECS_TASK_FAMILY,
                    registry: ECR_REGISTRY,
                    repoName: ECR_REPO,
                    tag: IMAGE_TAG,
                    region: AWS_DEFAULT_REGION
                )
            }
        }
    }

    post {
        success {
            // Trigger Slack notification on build success
            slackNotify(status: 'SUCCESS', channel: '#ci-cd-alerts')
        }
        failure {
            // Trigger Slack notification on build failure
            slackNotify(status: 'FAILURE', channel: '#ci-cd-alerts')
        }
    }
}
