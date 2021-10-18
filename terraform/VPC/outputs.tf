output "vpc_id" {
    value = aws_vpc.vpc1.id
}

output "subnet_id" {
    value = aws_subnet.public_subnet.id
}