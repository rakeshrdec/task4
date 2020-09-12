provider "aws" {
 region = "ap-south-1"
 profile = "default"
}
resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "my-task4-vpc"
  }
}
resource "aws_subnet" "subnet-1a" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "ap-south-1a"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true
tags = {
  Name = "public-subnet-1a"
}
}
resource "aws_subnet" "subnet-1b" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "ap-south-1b"
  cidr_block = "192.168.1.0/24"
   map_public_ip_on_launch = false
tags = {
  Name = "private-subnet-1b"
}
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "my-task4-gateway"
  }
}
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "my-routes-for-outside"
  }
}
resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.subnet-1a.id
  route_table_id = aws_route_table.route.id
}


resource "aws_eip" "eip" {
  vpc      = true
}


resource "aws_nat_gateway" "gw" {
depends_on = [aws_internet_gateway.gateway]
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet-1a.id
  tags = {
    Name = "NAT gateway"
  }
}
resource "aws_route_table" "nat_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    Name = "nat-routes"
  }
}

resource "aws_route_table_association" "route_associate_nat" {
  subnet_id      = aws_subnet.subnet-1b.id
  route_table_id = aws_route_table.nat_route.id
}

 resource "aws_security_group" "wordpress-sg" {
  depends_on = [aws_vpc.main]
  vpc_id      = aws_vpc.main.id
      ingress {
    description = "Creating SSH security group"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "Creating HTTP security group"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "Creating MySQL port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
 Name = "wordpress-sg"
}
}
 resource "aws_security_group" "mysql-sg" {
 depends_on = [aws_vpc.main]
 vpc_id      = aws_vpc.main.id
   
    ingress {
    description = "Creating MySQL port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
 Name = "mysql-sg"
}
}

resource "aws_instance" "wordpress" {
  ami           = "ami-0151caa79dbe9bd27"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1a.id
  vpc_security_group_ids = [ aws_security_group.wordpress-sg.id ] 
   key_name = "key11" 
  tags = {
    Name = "Wordpress"
  }
}
resource "aws_instance" "mysql" {
  ami           = "ami-76166b19"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1b.id
  vpc_security_group_ids = [ aws_security_group.mysql-sg.id ] 
  key_name = "key11" 
  tags = {
    Name = "mysql"
  }
}
output "IP_Address" {
value = aws_instance.wordpress.public_ip
}

output "VPC_ID" {
value = aws_vpc.main.id
}






