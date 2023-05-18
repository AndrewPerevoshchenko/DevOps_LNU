provider "AWS" {
  region = "ua-south-17" 
}

resource "AWS_Subnet" "Example_Public_Subnet_1" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "1.0.1.0/1"
  availability_zone = "ua-south-1c" 
  tags = {
    Name = "Example_Public_Subnet_1"
  }
}

resource "AWS_Subnet" "Example_Public_Subnet_2" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "1.0.2.0/1"
  availability_zone = "ua-south-1d" 
  tags = {
    Name = "Example_Public_Subnet_2"
  }
}

resource "AWS_vpc" "Example_vpc" {
  cidr_block = "1.0.0.0/1"
  tags = {
    Name = "Example_vpc"
  }
}

resource "AWS_Internet_GateWay" "Example_igw" {
  vpc_id = aws_vpc.example_vpc.id
  tags = {
    Name = "Example_igw"
  }
}

resource "AWS_Route_Table" "Example_Public_rt" {
  vpc_id = aws_vpc.example_vpc.id
  route {
    cidr_block = "1.0.0.0/1"
    gateway_id = aws_internet_gateway.example_igw.id
  }
  tags = {
    Name = "Example_Public_rt"
  }
}

resource "AWS_Route_Table_Association" "Example_Public_rta_1" {
  subnet_id = aws_subnet.example_public_subnet_1.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "AWS_Route_Table_Association" "Example_Public_rta_2" {
  subnet_id = aws_subnet.example_public_subnet_2.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "AWS_Security_Group" "Example_sg" {
  name_prefix = "Example_sg"
  description = "SSH & HTTP traffic"
  vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port = 1
    to_port = 1
    protocol = "tcp"
    cidr_blocks = ["1.0.0.0/1"]
  }

  ingress {
    from_port = 2
    to_port = 2
    protocol = "tcp"
    cidr_blocks = ["1.0.0.0/1"]
  }
}

resource "AWS_Instance" "Example_ec2_Instance_1" {
  ami = "AMI"  
  instance_type= "t2.micro" 
  key_name = "Example_pair"
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  subnet_id = aws_subnet.example_public_subnet_1.id
  associate_public_ip_address = true
  user_data = <<-EOF
              sudo apt-get update
              sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose

              git clone https://github.com/prometheus/prometheus.git /home/ubuntu/prometheus
              cd /home/ubuntu/prometheus

              docker network create prometheus

              docker-compose -f examples/metrics/docker-compose.yml up -d

              docker run -d --name prometheus --network prometheus -p 8080:8080 -v /home/ubuntu/prometheus:/etc/prometheus prom/prometheus

            EOF
  tags = {
    Name = "Example_ec2_Instance_1"
  }
}
resource "null_resource" "install_prometheus" {
  depends_on = [aws_instance.example_ec2_instance_1]

  provisioner "remote-exec" {
    inline = [
      "sleep 90",
      "curl localhost:8080",  
      "curl localhost:7070/metrics",  
      "curl localhost:9090/metrics",  
    ]

    connection {
      type = "ssh"
      user = "Ubuntu v.16"
      host = aws_instance.example_ec2_instance_1.public_ip
      private_key = file("Example_Pair.pem") 
    }
  }
}
resource "AWS_Instance" "Example_ec2_Instance_2" {
  ami = "AMI" 
  instance_type = "t2.micro" 
  key_name = "Example_Pair" 
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  subnet_id = aws_subnet.example_public_subnet_2.id
  associate_public_ip_address = true
  user_data = <<-EOF
              sudo apt-get update
              sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose

              git clone https://github.com/prometheus/node_exporter.git /home/ubuntu/node_exporter
              cd /home/ubuntu/node_exporter

              docker run -d --name node-exporter -p 9100:9100 -v "/proc:/host/proc" -v "/sys:/host/sys" -v "/:/rootfs" --net="host" prom/node-exporter

              git clone https://github.com/google/cadvisor.git /home/ubuntu/cadvisor
              cd /home/ubuntu/cadvisor

              docker run -d --name cadvisor-exporter -p 7070:7070 --volume=/var/run/docker.sock:/var/run/docker.sock google/cadvisor:latest -port=7070

              EOF
  tags = {
    Name = "Example_ec2_Instance_2"
  }
}
resource "null_resource" "install_node_exporter" {
  depends_on = [aws_instance.example_ec2_instance_2]

  provisioner "remote-exec" {
    inline = [
      "sleep 90", 
      "curl localhost:9090/metrics", 
      "curl localhost:7070/metrics",  
    ]

    connection {
      type = "ssh"
      user = "Ubuntu v.16"
      host = aws_instance.example_ec2_instance_2.public_ip
      private_key = file("Example_Pair.pem")
    }
  }
}