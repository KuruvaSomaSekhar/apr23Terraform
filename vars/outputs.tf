output "vpcID" {
  value = aws_vpc.myvpc.id
}

output "cidroutput" {
  value = aws_vpc.myvpc.cidr_block
}
