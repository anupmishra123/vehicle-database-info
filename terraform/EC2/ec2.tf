module "vpc" {
    source = "../VPC"
}

module "ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=tags/0.18.0"
  ssh_public_key_path   = "../secrets"
  namespace             = "vehicle-demo"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

provider "aws" {
    region      = "us-east-1"
    access_key  = ""
    secret_key  = ""
}

resource "aws_instance" "web-server" {
    ami                         = data.aws_ami.Ubuntu.id
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = module.vpc.public_subnet_id
    vpc_security_group_ids      = [aws_security_group.webserver_group.id]
    key_name                    = aws_key_pair.my_key.id
    
    tags = {
      "Name"    = "webserver_instance"
      "owner"   = "Anup Mishra"
    }
}


resource "aws_instance" "private_application_server" {
    ami                         = data.aws_ami.Ubuntu.id
    instance_type               = "t2.micro"
    subnet_id                   = module.vpc.private_subnet_id
    vpc_security_group_ids      = [aws_security_group.sg_lb.id]
    key_name                    = aws_key_pair.my_key.id
    
    tags = {
      "Name"    = "application_instance"
      "owner"   = "Anup Mishra"
    }
}

resource "aws_key_pair" "my_key" {
    key_name    = "ec2-access"
    public_key  = module.ssh_key_pair.public_key
}

resource "aws_security_group" "webserver_group" {
    vpc_id  = module.vpc.vpc_id
    name    = "Webserver_security_group"
}

resource "aws_security_group_rule" "webserver_group_rule1" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "ingress"
    from_port           = 22
    to_port             = 22
    cidr_blocks         = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "webserver_group_rule2" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "ingress"
    from_port           = 80
    to_port             = 80
    cidr_blocks         = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "webserver_group_rule3" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "ingress"
    from_port           = 443
    to_port             = 443
    cidr_blocks         = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "webserver_group_rule4" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "egress"
    from_port           = 22
    to_port             = 22
    cidr_blocks         = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "webserver_group_rule5" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "egress"
    from_port           = 443
    to_port             = 443
    cidr_blocks         = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "webserver_group_rule6" {
    security_group_id   = aws_security_group.webserver_group.id
    protocol            = "tcp"
    type                = "egress"
    from_port           = 80
    to_port             = 80
    cidr_blocks         = ["0.0.0.0/0"]
}
 
resource "aws_security_group" "sg_lb" {
    vpc_id              = module.vpc.vpc_id
    name                = "webserver-sg_lb"

    tags = {
      "Description" = "Security Group of Load Balancer"
    }
}

resource "aws_security_group_rule" "sg_lb_rule1" {
    security_group_id           = aws_security_group.sg_lb.id
    protocol                    = "tcp"
    type                        = "ingress"
    from_port                   = 80
    to_port                     = 80
    cidr_blocks                 = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_lb_rule2" {
    security_group_id           = aws_security_group.sg_lb.id
    protocol                    = "tcp"
    type                        = "ingress"
    from_port                   = 22
    to_port                     = 22
    cidr_blocks                 = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_lb_rule3" {
    security_group_id           = aws_security_group.sg_lb.id
    protocol                    = "-1"
    type                        = "egress"
    from_port                   = 0
    to_port                     = 0
    cidr_blocks                 = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balance_webserver" {
    name                = "webserver-loadbalancer"
    internal            = false
    load_balancer_type  = "application"
    security_groups     = [ aws_security_group.sg_lb.id, aws_security_group.webserver_group.id ]
    subnets             = [ module.vpc.public_subnet_id, module.vpc.private_subnet_id]
    ip_address_type     = "ipv4"
}

resource "aws_lb_target_group" "target_instance" {
    name                = "target-instance-ip"
    target_type         = "instance"
    port                = 5000
    protocol            = "HTTP"
    vpc_id              = module.vpc.vpc_id
}

resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.load_balance_webserver.arn
    port                = 80
    protocol            = "HTTP"

    default_action {
      type              = "forward"
      target_group_arn  = aws_lb_target_group.target_instance.arn
    }
  
}
 
resource "aws_lb_target_group_attachment" "private_ip" {
    target_group_arn    = aws_lb_target_group.target_instance.arn
    target_id           = aws_instance.private_application_server.id
    port                = 80
}

