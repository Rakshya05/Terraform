
# Terraform | Provider | Version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Creating a VPC
resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "demo-vpc"
  }
}

# Creating Public Subnet
resource "aws_subnet" "demo-public-subnet" {
  vpc_id            = aws_vpc.demo-vpc
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "demo-public-subent"
  }
}

# Creating Private Subnet
resource "aws_subnet" "private-subent" {
  vpc_id            = aws_vpc.demo-vpc
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "demo-private-subent"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-igw"
  }
}

# Assigning Elastic_IP - * It cost budget
resource "aws_eip" "demo-eip" {
  domain = "vpc" # Specify that the EIP should be associated with a VPC

  tags = {
    Name = "demo-eip"
  }
}

# Creating NAT Gateway
resource "aws_nat_gateway" "demo-ngw" {
  subnet_id     = aws_subnet.demo-public-subent.id
  allocation_id = aws_eip.demo-eip

  tags = {
    Name = "demo-ngw"
  }

  # Ensure proper ordering by adding an explicit dependency on the Internet Gateway for the VPC
  depends_on = [aws_internet_gateway.demo-igw]
}

# Creating Public Route Table
resource "aws_route_table" "demo-public-rt" {
  vpc_id = aws_vpc.demo-vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw
  }

  tags = {
    Name = "demo-public-rt"
  }
}

# Creating Private Route Table
resource "aws_route_table" "demo-private-rt" {
  vpc_id = aws_vpc.lbb-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.demo-ngw
  }

  tags = {
    Name = "demo-private-rt"
  }
}

# Creating Security Group
resource "aws_security_group" "lbb-ssh-sg" {
  name   = "demo-ssh-sg"
  vpc_id = aws_vpc.demo-vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "demo-ssh-sg"
  }
}

# Creating Public EC2 Instance
resource "aws_instance" "public_ec2" {
  ami                         = "ami-0f5daaa3a7fb3378b"
  instance_type               = "t2.micro"
  key_name                    = "tf-test-key"
  vpc_security_group_ids      = [aws_security_group.demo-ssh-sg.id]
  subnet_id                   = aws_subnet.demo-public-subnet
  associate_public_ip_address = true # Ensure that the instance gets a public IP address

  tags = {
    Name = "Public-EC2"
  }
}

# Creating Private EC2 Instance
resource "aws_instance" "private_ec2" {
  ami                    = "ami-0f5daaa3a7fb3378b"
  instance_type          = "t2.micro"
  key_name               = "tf-test-key"
  vpc_security_group_ids = [aws_security_group.demo-ssh-sg.id]
  subnet_id              = aws_subnet.demo-public-subnet

  tags = {
    Name = "Private-EC2"
  }
}

# Associating Public Subnet with Public Route Table
resource "aws_route_table_association" "demo-rta-public-subent-1" {
  subnet_id      = aws_subnet.demo-public-subnet
  route_table_id = aws_route_table.demo-private-rt
}

# Associating Private Subnet with Private Route Table
resource "aws_route_table_association" "demo-rta-private-subent-1" {
  subnet_id      = aws_subnet.demo-public-subnet
  route_table_id = aws_route_table.demo-private-rt
}
