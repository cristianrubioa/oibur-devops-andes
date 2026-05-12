resource "aws_ssm_parameter" "database_url" {
  name  = "/blacklist/DATABASE_URL"
  type  = "SecureString"
  value = "postgresql+psycopg2://blacklist_user:${var.db_password}@${aws_db_instance.postgres.endpoint}/blacklist_db"
  tags  = local.tags
}

resource "aws_ssm_parameter" "auth_token" {
  name  = "/blacklist/AUTH_BEARER_TOKEN"
  type  = "SecureString"
  value = var.auth_bearer_token
  tags  = local.tags
}

resource "aws_ssm_parameter" "new_relic_license_key" {
  name  = "/blacklist/NEW_RELIC_LICENSE_KEY"
  type  = "SecureString"
  value = var.new_relic_license_key
  tags  = local.tags
}
