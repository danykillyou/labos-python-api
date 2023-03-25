# Define the provider and AWS region
provider "aws" {
  region = "us-west-2"
}

data "local_file" "public_key" {
  filename = "/home/daniel/.ssh/id_ed25519.pub"
}

# Define the VPC and subnets
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
#  name_prefix = "daniel.mandelel-vpc"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "my-igw"
  }
}
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "my-route-table"
  }
}

resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}


resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
#  name_prefix = "daniel.mandelel-subnet"
}

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Define the security group
resource "aws_security_group" "web" {
  name_prefix = "daniel.mandelel-web"
  vpc_id      = aws_vpc.myvpc.id
egress {
    from_port = 1
    to_port   = 65000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# Define the EC2 instance
resource "aws_instance" "myinstance" {
  ami           = "ami-0efa651876de2a5ce"
  instance_type = "t2.micro"
#  name_prefix   = "daniel.mandelel"
 
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true

  # Install the application and server on the instance
  user_data = <<-EOF
#!/bin/bash
mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && echo '${data.local_file.public_key.content}' >> ~/.ssh/authorized_keys

sudo yum update

sudo yum install docker -y

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose
sudo systemctl enable docker.service
sudo systemctl start docker.service

EOF

  # Tag the instance
  tags = {
    Name = "github-api-server"
  }
}



# Define the output
output "public_ip" {
  value = aws_instance.myinstance.public_ip
}

