resource "aws_codecommit_repository" "main" {
  repository_name = "blacklist-microservice"
  description     = "Mirror of GitHub repo for CI/CD pipeline — Entrega 3"
  tags            = local.tags
}
