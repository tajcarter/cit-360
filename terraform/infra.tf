# add your VPC ID to default below and initialize variables

variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-ed8a7b8a"
}

variable "db_username" {
  description = "Username for DB"
  default = "root"
}

variable "db_password" {}

provider "aws" {
  region = "us-west-2"
}

#Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

#Create Elastic IP

resource "aws_eip" "tuto_eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.gw"]
}

#Create NAT gateway

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.tuto_eip.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  depends_on = ["aws_internet_gateway.gw"]
}
#Public Routing Table

resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#Public Subnets

resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.1.0/24"
  availability_zone = "us-west-2a"

  tags {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.2.0/24"
  availability_zone = "us-west-2b"

  tags {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.3.0/24"
  availability_zone = "us-west-2c"

  tags {
    Name = "public_c"
  }
}
#Public Routing Table Associations

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#Private Routing Table

resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
  tags {
    Name = "private_routing_table"
  }
}

#Private Subnets

resource "aws_subnet" "private_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.4.0/22"
  availability_zone = "us-west-2a"

  tags {
    Name = "private_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.8.0/22"
  availability_zone = "us-west-2b"

  tags {
    Name = "private_b"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.12.0/22"
  availability_zone = "us-west-2c"

  tags {
    Name = "private_c"
  }
}

#Private Routing Table Associations

resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#Security Group Rules

resource "aws_security_group" "nat" {
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb" {
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks =["172.31.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create EC2 instances

resource "aws_instance" "bastion" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id  = "${aws_subnet.public_subnet_a.id}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  associate_public_ip_address = "true"
  key_name = "cit360"
}

resource "aws_instance" "web_b" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  associate_public_ip_address = "false"
  key_name = "cit360"
}

resource "aws_instance" "web_c" {
  ami = "ami-5ec1673e"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  associate_public_ip_address="false"
  key_name = "cit360"
}

#Create DB subnet group

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "main"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
}

#Create MariaDB Instance

resource "aws_db_instance" "default_db" {
  allocated_storage = 5
  engine = "mariadb"
  engine_version = "10.0.24"
  identifier = "weeb-man"
  instance_class = "db.t2.micro"
  storage_type = "gp2"
  multi_az = "false"
  name = "my_db"
  username = "${var.db_username}"
  password = "${var.db_password}"
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.id}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

#Create a new load balancer

resource "aws_elb" "elb" {
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

instances = ["${aws_instance.web_b.id}", "${aws_instance.web_c.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  connection_draining = true
  connection_draining_timeout = 60
  cross_zone_load_balancing = true
  idle_timeout = 60

  tags {
    Name = "myelb"
  }
}


