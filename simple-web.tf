variable "awsprops" {
  type          = map(string)
  default = {
    region              = "us-west-1"
    vpc                 = "vpc-bc399ada"
    ami                 = "ami-098f55b4287a885ba"
    itype               = "t2.micro"
    publicip            = true
    keyname             = "your_keyname_here"
    secgroupname        = "simple-web-sg"
  }
}

provider "aws" {
  region        = "us-west-1"
  access_key    = "put_your_aws_access_key_here"
  secret_key    = "put_your_aws_secret_key_here"
}

resource "aws_security_group" "simple-web-sg" {
  name          = lookup(var.awsprops, "secgroupname")
  description   = lookup(var.awsprops, "secgroupname")
  vpc_id        = lookup(var.awsprops, "vpc")

  // To Allow Inbound SSH Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Inbound Port 80 Transport
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

 // To Allow ALL Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "myInstance" {
  ami           = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  echo "<p> My Instance! </p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF

  vpc_security_group_ids = [
    aws_security_group.simple-web-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    volume_size = 10
    volume_type = "gp2"
  }

  tags = {
    Name        = "simple-web"
    OS          = "CentOS"
  }

  depends_on = [ aws_security_group.simple-web-sg ]
}

output "DNS" {
  value = aws_instance.myInstance.public_dns
}

output "IP" {
  value = aws_instance.myInstance.public_ip
}
