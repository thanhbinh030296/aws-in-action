provider "aws" {
  access_key = var.b0ttle_access_key
  secret_key = var.b0ttle_secret_access_key
  region     = var.b0ttle_region
}

resource "aws_vpc" "selected" {
  cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.selected.id
  availability_zone = "ap-southeast-1a"
  cidr_block        = "10.0.0.0/20"
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.selected.id


  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-05b46bc4327cf9d99"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.example.id

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  

  associate_public_ip_address =true

  tags = {
    Name = "HelloWorld"
  }

}

