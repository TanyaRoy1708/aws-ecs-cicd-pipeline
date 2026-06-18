output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "jenkins_role_arn" {
  value = aws_iam_role.jenkins_ec2.arn
}

output "jenkins_instance_profile_name" {
  value = aws_iam_instance_profile.jenkins.name
}

