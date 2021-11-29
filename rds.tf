resource "aws_db_instance" "db" {
  identifier           = "db"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.23"
  instance_class       = "db.t3.micro"
  name                 = "db"
  username             = local.db_creds.username
  password             = local.db_creds.password
  #parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  depends_on = [data.aws_secretsmanager_secret_version.db_creds]
}