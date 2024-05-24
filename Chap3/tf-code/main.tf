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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.selected.id

  tags = {
    Name = "public_gateway"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.selected.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    cidr_block = aws_vpc.selected.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "public_subnet_routing" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.r.id
}


data "aws_iam_policy" "ec2ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ssm_default_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-core"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "ec2-ssm-core"
  }
}


resource "aws_iam_policy_attachment" "ec2_ssm_core" {
  name = "ec-ssm-core"
  #users      = [aws_iam_user.user.name]
  roles = [aws_iam_role.ec2_ssm_role.name]
  #groups     = [aws_iam_group.group.name]
  policy_arn = data.aws_iam_policy.ec2ssm.arn

}

resource "aws_iam_policy_attachment" "ec2_ssm_default" {
  name = "ec-ssm-core"
  #users      = [aws_iam_user.user.name]
  roles = [aws_iam_role.ec2_ssm_role.name]
  #groups     = [aws_iam_group.group.name]
  policy_arn = data.aws_iam_policy.ssm_default_policy.arn

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
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_iam_instance_profile" "ec2_ssm_iam_intsance_profile" {
  name = "ec2_ssm_iam_intsance_profile"
  role = aws_iam_role.ec2_ssm_role.name
}


resource "aws_instance" "web" {
  ami           = "ami-05b46bc4327cf9d99"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.example.id

  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_iam_intsance_profile.name

  user_data = <<EOF
                #/bin/sh
                sudo yum -y install httpd
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Hello AWS in Action!</title></head><body><p>Hello AWS in Action!</p></body></html>' > /var/www/html/index.html
                EOF

  associate_public_ip_address = true
  tags = {
    Name = "HelloWorld"
  }

}

