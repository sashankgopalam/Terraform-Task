provider "aws" {
  region  = "us-east-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-VPC"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "Internet-Gateway"
  }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"

  }

  tags = {
    Name = "public-route"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.r.id
}
resource "aws_security_group" "sg1" {
  name        = "securitygroup-1"
  description = "Allow ssh_http_icmp-Protocols"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security-Group-1"
  }
}
resource "aws_instance" "App-1" {
  ami = "ami-00c39f71452c08778"
  instance_type = "t2.micro"
  key_name = "prog-acc"
  vpc_security_group_ids = [ "${aws_security_group.sg1.id}" ]
  subnet_id = aws_subnet.public.id
tags ={
    Name = "Public-App"
  }

}
resource "aws_instance" "App-2" {
  ami = "ami-00c39f71452c08778"
  instance_type = "t2.micro"
  key_name = "prog-acc"
  vpc_security_group_ids = [ "${aws_security_group.sg1.id}" ]
  subnet_id = aws_subnet.private.id
tags ={
    Name = "Private-App"
  }
}
resource "aws_eip" "bar" {
  vpc = true
  instance = aws_instance.App-2.id
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.bar.id}"
  subnet_id     = "${aws_subnet.public.id}"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "Nat-Gateway"
  }
}
resource "aws_route_table" "r1" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"

  }

tags = {
    Name = "private-route"
  }
}
resource "aws_route_table_association" "ab" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.r1.id
}
