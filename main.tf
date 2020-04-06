provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = "${var.admin_cidr}"
}

module "ecs" {
  source = "ecs_cluster"

  cluster_name = "${var.name}"
}

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "${var.name}"
  public_key = "${var.public_key}"
}

data "aws_ami" "freebsd_11" {
  most_recent = true

  owners = ["118940168514"]

  filter {
    name = "name"

    values = [
      "FreeBSD 11.1-STABLE-amd64*",
    ]
  }
}

module "ecs_ec2" {
  source = "ecs_ec2"


  name = "${var.name}"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
  ]

  key_name = "${aws_key_pair.ssh_public_key.key_name}"

  subnets = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]

}



resource "aws_instance" "jumphost" {
  ami                    = "${data.aws_ami.freebsd_11.image_id}"
  instance_type          = "t2.small"
  subnet_id              = "${module.vpc.subnet_public1}"
  vpc_security_group_ids = ["${module.vpc.sg_allow_22}", "${module.vpc.sg_allow_egress}"]
  key_name               = "${aws_key_pair.ssh_public_key.key_name}"

  user_data = <<EOF
#!/usr/bin/env sh

export ASSUME_ALWAYS_YES=YES

pkg update -y
pkg install -y bash
chsh -s /usr/local/bin/bash ec2-user
EOF

  tags {
    Name      = "jumphost"
    ManagedBy = "tf-ecs-fargate"
  }
}
