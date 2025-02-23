output "aws_vpc" {
  value = aws_vpc.main
}

 output "aws_subnets" {
    value = aws_subnet.public[*]
 }