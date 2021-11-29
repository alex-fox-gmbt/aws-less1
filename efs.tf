resource "aws_efs_file_system" "main" {
  creation_token   = "main"

  tags = merge(var.tags, { Name = "main" })  
}

resource "aws_efs_mount_target" "efs_pub1" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.sub_pub1.id
  security_groups = [aws_security_group.instance.id]
}

resource "aws_efs_mount_target" "efs_pub2" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.sub_pub2.id
  security_groups = [aws_security_group.instance.id]
}