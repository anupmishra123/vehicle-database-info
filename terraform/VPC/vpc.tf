resource "aws_vpc" "vpc1" {
    cidr_block              = "10.0.0.0/16"
    instance_tenancy        = "default"
    enable_dns_hostnames    = true
    enable_dns_support      = true

    tags = {
        Name = "My VPC"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.vpc1.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "my-public-subnet1"
    }
}

resource "aws_internet_gateway" "IGW1" {
    vpc_id          = aws_vpc.vpc1.id
    tags = {
        Name = "IG1"
    }
}

resource "aws_route_table" "public_route1" {
    vpc_id         = aws_vpc.vpc1.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW1.id
    }

    tags = {
        Name = "Public Route table"
    }
}

resource "aws_route_table_association" "public_route_association" {
    subnet_id       = aws_subnet.public_subnet.id
    route_table_id  = aws_route_table.public_route1.id
}

resource "aws_network_acl_rule" "default_rule_deny" {
    network_acl_id  = aws_vpc.vpc1.default_network_acl_id
    rule_number     = 100
    egress          = false
    protocol        = "-1"
    rule_action     = "deny"
    cidr_block      = aws_vpc.vpc1.cidr_block
    from_port       = 0
    to_port         = 65535
}

resource "aws_network_acl" "allow_access" {
    vpc_id = aws_vpc.vpc1.id
    subnet_ids = [ aws_subnet.public_subnet.id ]

    tags = {
      "Name" = "my-network-acl"
    }

    ingress {
        protocol    = "tcp"
        rule_no     = "100"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "22"
        to_port     = "22"
        }

    ingress {
        protocol    = "tcp"
        rule_no     = "200"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "80"
        to_port     = "80"
    }

    ingress {
        protocol    = "tcp"
        rule_no     = "300"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "443"
        to_port     = "443"
    }
    
    ingress {
        protocol    = "tcp"
        rule_no     = "400"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "1024"
        to_port     = "65535"
    }
    
    egress {
        protocol    = "tcp"
        rule_no     = "100"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "22"
        to_port     = "22"
    }

    egress {
        protocol    = "tcp"
        rule_no     = "200"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "80"
        to_port     = "80"
    }

    egress {
        protocol    = "tcp"
        rule_no     = "300"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "443"
        to_port     = "443"
    }
    
    egress {
        protocol    = "tcp"
        rule_no     = "400"
        action      = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = "1024"
        to_port     = "65535"
    }
}
