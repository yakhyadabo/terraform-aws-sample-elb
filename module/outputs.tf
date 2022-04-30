output "hostnames" {
  value = aws_elb.service.dns_name
}