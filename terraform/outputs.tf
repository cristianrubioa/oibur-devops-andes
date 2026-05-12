output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this as base_url in Postman)"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = aws_ecr_repository.main.repository_url
}

output "codecommit_clone_url_http" {
  description = "CodeCommit HTTPS clone URL"
  value       = aws_codecommit_repository.main.clone_url_http
}

output "codecommit_clone_url_ssh" {
  description = "CodeCommit SSH clone URL"
  value       = aws_codecommit_repository.main.clone_url_ssh
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "ecs_execution_role_arn" {
  description = "ECS task execution role ARN — use in taskdef.json executionRoleArn"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN — use in taskdef.json taskRoleArn"
  value       = aws_iam_role.ecs_task.arn
}

output "ssm_database_url_arn" {
  description = "SSM parameter ARN for DATABASE_URL — use in taskdef.json secrets"
  value       = aws_ssm_parameter.database_url.arn
}

output "ssm_auth_token_arn" {
  description = "SSM parameter ARN for AUTH_BEARER_TOKEN — use in taskdef.json secrets"
  value       = aws_ssm_parameter.auth_token.arn
}

output "aws_account_id" {
  description = "AWS account ID — use to update taskdef.json placeholders"
  value       = data.aws_caller_identity.current.account_id
}

output "taskdef_update_command" {
  description = "Run this after terraform apply to update taskdef.json with real ARNs"
  value = <<-EOT
    Update taskdef.json replacing:
      <ACCOUNT_ID> → ${data.aws_caller_identity.current.account_id}
      <REGION>     → ${var.aws_region}
    executionRoleArn → ${aws_iam_role.ecs_execution.arn}
    taskRoleArn      → ${aws_iam_role.ecs_task.arn}
  EOT
}
