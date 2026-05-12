resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/blacklist-microservice"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = "blacklist-microservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "blacklist-microservice"
    image     = "${aws_ecr_repository.main.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 5000
      protocol      = "tcp"
    }]
    environment = [
      { name = "NEW_RELIC_APP_NAME",                    value = "blacklist-microservice" },
      { name = "NEW_RELIC_DISTRIBUTED_TRACING_ENABLED", value = "true" },
      { name = "NEW_RELIC_LOG",                         value = "stdout" }
    ]
    secrets = [
      { name = "DATABASE_URL",            valueFrom = aws_ssm_parameter.database_url.arn },
      { name = "AUTH_BEARER_TOKEN",       valueFrom = aws_ssm_parameter.auth_token.arn },
      { name = "NEW_RELIC_LICENSE_KEY",   valueFrom = aws_ssm_parameter.new_relic_license_key.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/blacklist-microservice"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = local.tags
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "blacklist-microservice"
    container_port   = 5000
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # After the first CodeDeploy deployment, the active task definition revision
  # and active target group are managed by CodeDeploy — not Terraform.
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.tags
}
