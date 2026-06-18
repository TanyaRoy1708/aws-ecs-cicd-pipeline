output "jenkins_instance_id" {
  value       = aws_instance.jenkins.id
  description = "The Instance ID of the Jenkins server"
}

output "jenkins_private_ip" {
  value       = aws_instance.jenkins.private_ip
  description = "The private IP address of the Jenkins server"
}
