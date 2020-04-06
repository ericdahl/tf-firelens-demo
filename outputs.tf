output "aws_instance_jumphost_public_ip" {
  value = "${aws_instance.jumphost.public_ip}"
}

output "aws_alb_httpbin_ec2_firehose" {
  value = "${aws_alb.httpbin_ec2_firehose.*.dns_name}"
}