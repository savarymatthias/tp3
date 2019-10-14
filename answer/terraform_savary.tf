# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  access_key = ""
  secret_key = ""
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
} 

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = # add a CIDR block here
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-12c4e678"]
  }
}

resource "aws_instance" "web_savary" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "savary-key"
 
  
  provisioner "remote-exec" {
    inline = [
	"sudo apt install maven",
	"sudo apt install git",
	"sudo apt install default-jdk"
	]
	
	connection {
	type = "ssh"
	host =  "${self.public_ip}"
	user= "ubuntu"
	private_key = "${file("key.pem")}"
  }

}
}

resource "aws_key_pair" "deployer" {
  key_name   = "savary-key"
  public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoCKBX+Dd0GGP1fn/DX31FmpYtOCYqs85EYfNrKegrN/Om316xJonzKzjyluNoAft4/RpnTVj3/gY6uJRvxFZsoB4bBu0GRIvPnMZ70SFdjuC3vjtB7cRDCRX0M8wdnjHHVF0EnWLCOPCFbe3H0GM46poYLzCdUj8NgBz5M9OSGSj3w7NVYyw8Nm1V4PAtKHfMvTS5QD9kLOMBEYQ8s+0KgWXStbh69lieMURVw8rn5BrhYhc+2FDuMqaJTLBARJi0MWrWnluKBkPaM1EbYvKAKVsrg8suMkr7zSJvQj+iUG+xQ2mubkk+dmFvv4H+zDUQ24cXDkQyrTWShBDhdKmpQIDAQAB"
}

resource "aws_vpc" "lgu_vpc"{
	cidr_block="172.16.0.0/16"
	enable_dns_hostnames= true
	enable_dns_support = true
	
	tags = {
		Name = "lgu_vpc"
	}
	
}

resource "aws_subnet" "lgu_sn"{
	cidr_block = "${cidrsubnet(aws_vpc.lgu_vpc.cidr_block,3,1)}"
	vpc_id = "${aws_vpc.lgu_vpc.id}"
	availability_zone = "us-east-1a"
	map_public_ip_on_launch = true
	
	tags = {
		Name = "lgu_sn"
	}
}

resource "aws_internet_gateway" "lgu_igw"{
	vpc_id = "${aws_vpc.lgu_vpc.id}"
}

resource "aws_route_table" "lgu_rt"{
	vpc_id = "${aws_vpc.lgu_vpc.id}"
	
	route{
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.lgu_igw.id}"
	}
	
	tags =  {
		Name = "lgu_rt"
	}
}

resource "aws_route_table_association" "lgu_rta" {
	subnet_id = "${aws_subnet.lgu_sn.id}"
	route_table_id = "${aws_route_table.lgu_rt.id}"
}




 