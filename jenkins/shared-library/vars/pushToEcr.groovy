def call(Map config = [:]) {
    def registry = config.required('registry')
    def repoName = config.required('repoName')
    def tag = config.required('tag')
    def region = config.get('region', 'us-east-1')

    echo "Authenticating with AWS ECR in region ${region}..."
    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${registry}"

    echo "Tagging image ${repoName}:${tag} for ECR..."
    sh "docker tag ${repoName}:${tag} ${registry}/${repoName}:${tag}"

    echo "Pushing image to ECR..."
    sh "docker push ${registry}/${repoName}:${tag}"
}
