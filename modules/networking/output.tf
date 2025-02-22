output "aws_vpc" {
  value = aws_vpc.main
}

# output "aws_subnet" {
#   value = aws_subnet.public.id
# }

 output "aws_subnets" {
    value = aws_subnet.public[*]
 }