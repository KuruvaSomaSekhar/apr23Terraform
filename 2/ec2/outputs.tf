output "privateIP" {
    value = aws_instance.web[*].private_ip
}

output "InstanceID" {
    value = aws_instance.web[*].id
}
