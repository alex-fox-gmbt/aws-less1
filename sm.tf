resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "dbadminsecret" {
  name = "dbadminsec"
}

resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.dbadminsecret.id
  secret_string = <<EOF
   {
    "username": "dbadmin",
    "password": "${random_password.password.result}"
   }
EOF
}

data "aws_secretsmanager_secret" "dbadminsecret" {
  arn = aws_secretsmanager_secret.dbadminsecret.arn
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.aws_secretsmanager_secret.dbadminsecret.arn
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_creds.secret_string
  )
}
