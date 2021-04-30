terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "VPC from terraform"
  }
}

resource "aws_subnet" "webserver_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.32/27"
  map_public_ip_on_launch = true

  tags = {
    Name = "Webserver Subnet"
  }
}

resource "aws_subnet" "mysql_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.64/27"
  map_public_ip_on_launch = false

  tags = {
    Name = "MySQL Subnet"
  }
}

resource "aws_subnet" "mongodb_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.96/27"
  map_public_ip_on_launch = false

  tags = {
    Name = "MongoDB Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.webserver_subnet.id
  route_table_id = aws_route_table.default.id
}

resource "aws_security_group" "http_sg" {
  name        = "http_sg"
  description = "Security group untuk inbound port http"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "http traffic allowed"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http_sg"
  }
}

resource "aws_security_group" "https_sg" {
  name        = "https_sg"
  description = "Security group untuk inbound port https"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "https traffic allowed"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "https_sg"
  }
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "Security group untuk inbound port ssh"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh traffic allowed"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh_sg"
  }
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql_sg"
  description = "Security group untuk inbound mysql port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh traffic allowed"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql_sg"
  }
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Security group untuk inbound mongodb port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh traffic allowed"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb_sg"
  }
}

resource "aws_security_group" "inbound_all_sg" {
  name        = "inbound_all_sg"
  description = "Security group untuk inbound icmp ipv4 port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "icmp ipv4 traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "inbound_all_sg"
  }
}

resource "aws_security_group" "outbound_all_sg" {
  name        = "outbound_all_sg"
  description = "Security group untuk all port outbound"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "outbound_all_sg"
  }
}

resource "aws_eip" "webserver_vm" {
  instance   = aws_instance.webserver_vm.id
  vpc        = true
  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat_gateway" {
  instance = aws_instance.nat_vm.id
  vpc      = true
}

resource "aws_route_table" "mysql_subnet_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat_vm.id
  }
}

resource "aws_route_table_association" "mysql_subnet_route_table_association" {
  subnet_id      = aws_subnet.mysql_subnet.id
  route_table_id = aws_route_table.mysql_subnet_route_table.id
}


resource "aws_route_table" "mongodb_subnet_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat_vm.id
  }
}

resource "aws_route_table_association" "mongodb_subnet_route_table_association" {
  subnet_id      = aws_subnet.mongodb_subnet.id
  route_table_id = aws_route_table.mongodb_subnet_route_table.id
}

resource "aws_instance" "webserver_vm" {
  ami           = "ami-042e8287309f5df03"
  instance_type = "t2.micro"
  key_name      = "kuliah"
  vpc_security_group_ids = [
    aws_security_group.outbound_all_sg.id,
    aws_security_group.ssh_sg.id,
    aws_security_group.http_sg.id,
    aws_security_group.https_sg.id,
  ]
  subnet_id = aws_subnet.webserver_subnet.id

  tags = {
    Name = "Webserver Instance"
  }
}

resource "aws_instance" "mysql_vm" {
  ami           = "ami-042e8287309f5df03"
  instance_type = "t2.micro"
  key_name      = "kuliah"
  vpc_security_group_ids = [
    aws_security_group.outbound_all_sg.id,
    aws_security_group.mysql_sg.id,
    aws_security_group.ssh_sg.id,
  ]
  subnet_id = aws_subnet.mysql_subnet.id
  tags = {
    Name = "MySQL Instance"
  }
}

resource "aws_instance" "mongodb_vm" {
  ami           = "ami-042e8287309f5df03"
  instance_type = "t2.micro"
  key_name      = "kuliah"
  vpc_security_group_ids = [
    aws_security_group.outbound_all_sg.id,
    aws_security_group.mongodb_sg.id,
    aws_security_group.ssh_sg.id,
  ]
  subnet_id = aws_subnet.mongodb_subnet.id
  tags = {
    Name = "MongoDB Instance"
  }
}

resource "aws_instance" "nat_vm" {
  ami           = "ami-01ef31f9f39c5aaed"
  instance_type = "t2.micro"
  key_name      = "kuliah"
  vpc_security_group_ids = [
    aws_security_group.outbound_all_sg.id,
    aws_security_group.inbound_all_sg.id,
  ]
  source_dest_check = false
  subnet_id = aws_subnet.webserver_subnet.id
  tags = {
    Name = "NAT Instance"
  }
}

output "Webserver_vm_public_ip" {
  value = aws_eip.webserver_vm.public_ip
}

output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}