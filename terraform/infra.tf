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
        subnet_id = "${aws_subnet.private_subnet_a.id}"

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

        tags {
                Name = "private_route_table"
        }
}

resource "aws_route" "private_route" {
        route_table_id = "${aws_route_table.private_route_table.id}"
        destination_cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat.id}"

}

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


#security group for Bastion instance

resource "aws_security_group" "bastion" {
        name = "bastion"
        description = "Allow access from your current public IP address to an instance on port 22 (SSH)"
        ingress {
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["172.31.0.0/24"]
        }

        vpc_id = "${var.vpc_id}"
}

