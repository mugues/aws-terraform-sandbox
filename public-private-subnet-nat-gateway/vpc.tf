resource "aws_vpc" "vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags {
        Name = "terraform-aws-vpc"
    }
}

/*
  The key-pair to connect to ec2 instances
*/
resource "aws_key_pair" "auth" {
  key_name   = "${var.aws_key_name}"
  public_key = "${file(var.aws_key_path)}"
}

/*
  Public Subnet
*/
resource "aws_subnet" "public_subnet_eu_west_1a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.public_subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"
  tags = {
  	Name =  "Subnet public az 1a"
  }
}

/*
  Private Subnet
*/
resource "aws_subnet" "private_subnet_eu_west_1a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_subnet_cidr}"
  availability_zone = "eu-west-1a"
  tags = {
  	Name =  "Subnet private az 1a"
  }
}


/*
  Internet Gateway
*/
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
        Name = "InternetGateway"
    }
}

/*
  Route to the internet
*/
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}


/*
  Elastic IP for the NAT gateway
  We will create this IP to assign it the NAT Gateway
*/
resource "aws_eip" "eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}

/*
  NAT gateway
  Make sure to create the nat in a internet-facing subnet (public subnet)
*/
resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.eip.id}"
    subnet_id = "${aws_subnet.public_subnet_eu_west_1a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}


/*
  Private route table and the route to the internet
  This will allow all traffics from the private subnets to the internet through the NAT Gateway (Network Address Translation)
 */
resource "aws_route_table" "private_route_table" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags {
        Name = "Private route table"
    }
}

resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
}


/*
  Create Route Table Associations
  we will now associate our subnets to the different route tables
*/

# Associate subnet public_subnet_eu_west_1a to public route table
resource "aws_route_table_association" "public_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.public_subnet_eu_west_1a.id}"
    route_table_id = "${aws_vpc.vpc.main_route_table_id}"
}

# Associate subnet private_subnet_eu_west_1a to private route table
resource "aws_route_table_association" "private_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.private_subnet_eu_west_1a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}
