data "template_file" "script" {
  template = file("user_data.sh")
  vars = {
    efs_id            = "${aws_efs_file_system.main.id}"
    db_host           = "${aws_db_instance.db.address}"
    db_name           = "${aws_db_instance.db.name}"
    db_admin_username = "${local.db_creds.username}"
    db_admin_password = "${local.db_creds.password}"
  }
  depends_on = [aws_efs_file_system.main,
                data.aws_secretsmanager_secret_version.db_creds]
}
