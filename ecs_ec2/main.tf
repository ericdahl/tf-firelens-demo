data "aws_ami" "ecs" {
  most_recent = true

  owners = [ "591542846629" ]

  filter {
    name   = "name"
    values = ["*amzn2-ami-ecs-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_autoscaling_group" "default" {
  name = "${var.name}"

  min_size         = "1"
  max_size         = "1"
  desired_capacity = "1"

  vpc_zone_identifier = [
    "${var.subnets}",
  ]

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.default.id}"
        version = "$Latest"
      }

      override = [
        {
          instance_type = "m5.large"
        },
        {
          instance_type = "m5a.large"
        }
      ]
    }

    instances_distribution {
      on_demand_percentage_above_base_capacity = "0"
    }
  }
}


resource "aws_launch_template" "default" {
  name = "${var.name}"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.ec2_instance_profile.name}"
  }

  image_id      = "${data.aws_ami.ecs.image_id}"
  instance_type = "m5.large"
  key_name      = "${var.key_name}"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [
    "${var.security_groups}",
  ]

  user_data = "${base64encode(data.template_file.cloud_init.rendered)}"
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/templates/cloud-init.yml")}"

  vars {
    cluster_name = "${var.name}"
  }
}