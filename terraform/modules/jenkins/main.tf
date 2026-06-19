data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.large"
  subnet_id            = var.private_subnet_id
  security_groups      = [var.jenkins_sg_id]
  iam_instance_profile = var.instance_profile_name
  key_name             = var.key_name
  user_data            = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project}-jenkins"
  }
}
