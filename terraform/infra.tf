# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-ed8a7b8a"
}

#region 
provider "aws" {
  region = "us-west-2"
}

#creates internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags  {
    Name = "default_ig"
  }
}

#this will create the IP and assign it to the NAT Gateway
resource "aws_eip" "lb"{
	vpc = true 
	depends_on = ["aws_internet_gateway.gw"]
}

#aws NAT Gateway
resource "aws_nat_gateway" "nat" {
	allocation_id = "${aws_eip.lb.id}"
	subnet_id = "${aws_subnet.public_subnet_a.id}"
	
	depends_on = ["aws_internet_gateway.gw"]
}


#_________________________________________________________________________________________________
#aws public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

#creates public subnets
resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}
 
 
#
#associate subnet public_subnet to public route table

resource "aws_route_table_association" "public_subnet_a" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
	
}
#-----------------------------------------------

#creates public subnets
resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_b"
    }
}
  
#
#associate subnet public_subnet to public route table

resource "aws_route_table_association" "public_subnet_b" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
	
}

#-----------------------------------------------

#creates public subnets
resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_c"
    }
}
  
#
#associate subnet public_subnet to public route table

resource "aws_route_table_association" "public_subnet_c" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
	
}



#_________________________________________________________________________________________________
#creates the private route table
resource "aws_route_table" "private_route_table" {
	vpc_id = "${var.vpc_id}"
	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = "${aws_nat_gateway.nat.id}"
	}	
	tags {
		Name = "private_route_table"
	}
}

/*
resource "aws_route" "private_route" {
	route_table_id = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"

}
*/
 
#creates private subnets
resource "aws_subnet" "private_subnet_a" {
        vpc_id = "${var.vpc_id}"
        cidr_block = "172.31.8.0/22"    
        availability_zone = "us-west-2a"
        tags = {
                Name = "private_a"
        }
}


 
#associate subnet private_subnet to private route table

resource "aws_route_table_association" "private_subnet_a" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}
 

#-------------------------------------------

#creates private subnets 
resource "aws_subnet" "private_subnet_b" {
	vpc_id = "${var.vpc_id}"
	cidr_block = "172.31.4.0/22"
	availability_zone = "us-west-2b"
	tags = {
		Name = "private_b"
	}
}

 
#associate subnet private_subnet to private route table

resource "aws_route_table_association" "private_subnet_b" {
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

#-------------------------------------------

#creates private subnets 
resource "aws_subnet" "private_subnet_c" {
	vpc_id = "${var.vpc_id}"
	cidr_block = "172.31.12.0/22"
	availability_zone = "us-west-2c"
	tags = {
		Name = "private_c"
	}
}

 
#associate subnet private_subnet to private route table

resource "aws_route_table_association" "private_subnet_c" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}


# Bastion instance
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.bastion.id}"]
    tags {
        Name = "Bastion"
    }
}


#security group for Bastion instance

resource "aws_security_group" "bastion" {
	name = "bastion"
	description = "Allow access from your current public IP address to an instance on port 22 (SSH)"
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
	
	vpc_id = "${var.vpc_id}"
}

#__________________________________________________________________________________
#new code for assignment 3 : assignment 2 code above also edited 
#__________________________________________________________________________________

#security group for DB

resource "aws_security_group" "default" {
        name = "allow_all"
        description = "Allow all inbound traffic"

        ingress {
                from_port = 0
                to_port = 0
                protocol = "tcp"
                cidr_blocks = ["172.31.0.0/16"]
        }
        tags {
                name = "allow_all"
        }
}

#security group for the the instnace

resource "aws_security_group" "allow_all" {
        name = "access_all"
        description = "allow all inbound traffic"

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
                from_port = -1
                to_port = -1
                protocol = "icmp"
                cidr_blocks = ["0.0.0.0/0"]
        }

	egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }

        vpc_id = "${var.vpc_id}"
}


#security group for ELB

resource "aws_security_group" "elb" {
        name = "elb"
        description = "allow access from anywhere to an instance on port 80 (http)"

        ingress {
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
}


#referencing the subnet group for the db

resource "aws_db_subnet_group" "db-1" {
        name = "main"
        subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
        tags {
                name = "db subnet group"
        }
}


#relations database service (RDS) instance
resource "aws_db_instance" "rds-1" {
        allocated_storage = 5
        engine = "mariadb"
        engine_version = "10.0.24"
        identifier = "weeb-man"
        instance_class = "db.t2.micro"
        multi_az = false
        storage_type = "gp2"
        username = "${var.username}"
        password = "${var.password}"
        vpc_security_group_ids = ["${aws_security_group.default.id}"]
        db_subnet_group_name = "${aws_db_subnet_group.db-1.id}"

        tags {
                name = "mariadb instance"
        }
}


#elastic load balancer
resource "aws_elb" "elb" {
        name = "elb"

        subnets = ["${aws_subnet.public_subnet_b.id}" , "${aws_subnet.public_subnet_c.id}"]
        security_groups = ["${aws_security_group.elb.id}"]

        listener {
                instance_port = 80
                instance_protocol = "HTTP"
                lb_port = 80
                lb_protocol = "HTTP"
        }

        health_check {
                healthy_threshold = 2
                unhealthy_threshold = 2
                timeout = 5
                target = "HTTP:80/"
                interval = 30
        }


        instances = ["${aws_instance.webserver_b.id}" , "${aws_instance.webserver_c.id}"]
        cross_zone_load_balancing = true
        idle_timeout = 400
        connection_draining = true
        connection_draining_timeout = 60

        tags {
                name = "terraform_elb"
        }
}


#webserver instance
resource "aws_instance" "webserver_b" {
        ami = "ami-5ec1673e"

        subnet_id = "${aws_subnet.private_subnet_b.id}"
        instance_type = "t2.micro"
        key_name = "${var.aws_key_name}"
        security_groups = ["${aws_security_group.allow_all.id}"]

        tags {
                name = "webserver_b"
                service = "curriculum"
        }
}

resource "aws_instance" "webserver_c" {
        ami = "ami-5ec1673e"

        subnet_id = "${aws_subnet.private_subnet_c.id}"
        instance_type = "t2.micro"
        key_name = "${var.aws_key_name}"
        security_groups = ["${aws_security_group.allow_all.id}"]

        tags {
                name = "webserver_c"
                service = "curriculum"
        }
}

