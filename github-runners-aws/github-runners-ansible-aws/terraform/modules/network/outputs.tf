output "security_group_id" {
  description = "The ID of the GitHub Runner security group"
  value       = aws_security_group.github_runner_sg.id
}
