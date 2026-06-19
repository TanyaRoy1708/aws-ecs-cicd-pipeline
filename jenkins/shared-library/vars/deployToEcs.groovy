def call(Map config = [:]) {
    def cluster = config.required('cluster')
    def service = config.required('service')
    def taskFamily = config.required('taskFamily')
    def registry = config.required('registry')
    def repoName = config.required('repoName')
    def tag = config.required('tag')
    def region = config.get('region', 'us-east-1')
    
    echo "Deploying new task definition revision to ECS Service: ${service} in Cluster: ${cluster}..."
    
    sh """
        # Fetch current task definition
        TASK_DEF_JSON=\$(aws ecs describe-task-definition --task-definition ${taskFamily} --region ${region})
        
        # Prepare clean JSON with updated container image
        NEW_TASK_DEF=\$(echo "\$TASK_DEF_JSON" | jq --arg IMAGE "${registry}/${repoName}:${tag}" '.taskDefinition | .containerDefinitions[0].image = \$IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')
        
        # Register the new task definition
        NEW_TASK_DEF_ARN=\$(aws ecs register-task-definition --region ${region} --cli-input-json "\$NEW_TASK_DEF" --query 'taskDefinition.taskDefinitionArn' --output text)
        echo "Registered new Task Definition ARN: \$NEW_TASK_DEF_ARN"
        
        # Update the ECS service to use the new revision
        aws ecs update-service --cluster ${cluster} --service ${service} --task-definition "\$NEW_TASK_DEF_ARN" --region ${region}
        
        # Wait for the service to stabilize (rolling update complete)
        echo "Waiting for ECS service stabilization (this may take a few minutes)..."
        aws ecs wait services-stable --cluster ${cluster} --services ${service} --region ${region}
        echo "ECS deployment completed successfully!"
    """
}
