locals {
  name_prefix = "${var.project_name}-microservice"
  tags = {
    Project   = "blacklist-microservice"
    ManagedBy = "Terraform"
    Course    = "Entrega4"
  }
}
