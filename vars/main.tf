# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.myCIDR
  tags = {
    Name = var.vpctags
  }
}