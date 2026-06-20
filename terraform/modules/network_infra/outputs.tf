output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "security_group_tasks" {
  value = aws_security_group.tasks.id
}

output "security_group_alb" {
  value = aws_security_group.alb.id
}