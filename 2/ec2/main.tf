resource "aws_instance" "web" {
  ami           = var.AMIID
  instance_type = var.InstanceType
  count = var.icount

  tags = {
    Name = "My WebServer - ${count.index}"
  }
}

