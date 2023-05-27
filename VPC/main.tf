resource "aws_vpc" "devops" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "devops-vpc"
  }
}

resource "aws_subnet" "public-sn1a" {
  vpc_id                  = aws_vpc.devops.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-sn1a"
  }
}

resource "aws_subnet" "private-sn1a" {
  vpc_id            = aws_vpc.devops.id
  cidr_block        = "10.0.0.64/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-sn1a"
  }
}

resource "aws_subnet" "public-sn1b" {
  vpc_id            = aws_vpc.devops.id
  cidr_block        = "10.0.0.128/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-sn1b"
  }
}

resource "aws_subnet" "private-sn1b" {
  vpc_id            = aws_vpc.devops.id
  cidr_block        = "10.0.0.192/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-sn1b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops.id

  tags = {
    Name = "devops-igw"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.devops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-sn1a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private-sn1a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_eip" "nat-eip" {
  vpc = true
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-sn1a.id

  tags = {
    Name = "NAT"
  }

}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.devops.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "pa" {
  subnet_id      = aws_subnet.public-sn1b.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "pb" {
  subnet_id      = aws_subnet.private-sn1b.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.devops.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "web" {
  ami             = "ami-0bef6cc322bfff646"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.public-sn1a.id
  key_name        = "apr23"
  security_groups = [aws_security_group.allow_tls.id]
  user_data       = <<EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        systemctl start httpd
        systemctl enable httpd
        echo "<h1> Welcome AWS Sessions. Hellow world from $(hostname -f) </h1>" > /var/www/html/index.html
     EOF
  tags = {
    Name = "WebServer"
  }
}

resource "aws_lb_target_group" "MyAppTG" {
  name        = "MyAppTG"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.devops.id
}

resource "aws_lb" "MyALB" {
  name               = "MYAppALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = [aws_subnet.public-sn1a.id, aws_subnet.public-sn1b.id]



  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.MyAppTG.arn
  target_id        = aws_instance.web.private_ip
  port             = "80"
  depends_on       = [aws_instance.web]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.MyALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.MyAppTG.arn
  }
}