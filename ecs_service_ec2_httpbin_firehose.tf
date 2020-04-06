data "template_file" "httpbin_ec2_firehose" {
  template = "${file("templates/tasks/httpbin-ec2-firehose.json")}"
}


resource "aws_ecs_task_definition" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  container_definitions = "${data.template_file.httpbin_ec2_firehose.rendered}"
  family                = "httpbin-ec2"

  execution_role_arn = "${module.ecs.aws_iam_role_ecs_task_execution_arn}"

  task_role_arn = "${aws_iam_role.task_httpbin_ec2_firehose.arn}"
}

resource "aws_iam_role" "task_httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  name = "task-httpbin-ec2_firehose"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "task_httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  name = "task_httpbin_ec2_firehose"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "firehose:PutRecordBatch"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  role       = "${aws_iam_role.task_httpbin_ec2_firehose.name}"
  policy_arn = "${aws_iam_policy.task_httpbin_ec2_firehose.arn}"
}

resource "aws_ecs_service" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose == "true" ? 1 : 0}"

  name            = "httpbin-ec2-firehose"
  cluster         = "${module.ecs.cluster_name}"
  task_definition = "${aws_ecs_task_definition.httpbin_ec2_firehose.arn}"
  desired_count   = 1
  launch_type     = "EC2"

  depends_on = [
    "aws_alb.httpbin_ec2_firehose",
  ]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.httpbin_ec2_firehose.arn}"
    container_name   = "httpbin"
    container_port   = 8080
  }
}

resource "aws_alb" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose == "true" ? 1 : 0}"

  name = "httpbin-ec2-firehose"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_80}",
  ]
}

resource "aws_alb_listener" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose == "true" ? 1 : 0}"

  default_action {
    target_group_arn = "${aws_alb_target_group.httpbin_ec2_firehose.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.httpbin_ec2_firehose.arn}"
  port              = 80
}

resource "aws_alb_target_group" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose == "true" ? 1 : 0}"

  name                 = "httpbin-ec2-firehose"
  vpc_id               = "${module.vpc.vpc_id}"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5
  target_type          = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 5
    timeout             = 2
  }
}

resource "aws_cloudwatch_log_group" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose == "true" ? 1 : 0}"

  name = "/ecs/httpbin-ec2-firelens-firehose"

  retention_in_days = 7
}

resource "aws_kinesis_firehose_delivery_stream" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  name = "httpbin-ec2-firelens-app"

  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = "${aws_iam_role.httpbin_ec2_firehose.arn}"
    bucket_arn = "${aws_s3_bucket.httpbin_ec2_firehose.arn}"

    buffer_interval = 60

    compression_format = "GZIP"
  }
}

resource "aws_s3_bucket" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  bucket = "tf-firehose-httpbin-ec2"
  acl    = "private"
}

resource "aws_iam_role" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  name = "httpbin-ec2-firehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  name = "httpbin_ec2_firehose"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [

  {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.httpbin_ec2_firehose.arn}",
                "${aws_s3_bucket.httpbin_ec2_firehose.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.httpbin_ec2_firehose.arn}"
        }

  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "httpbin_ec2_firehose" {
  count = "${var.enable_ec2_httpbin_firehose ? 1 : 0}"

  role       = "${aws_iam_role.httpbin_ec2_firehose.name}"
  policy_arn = "${aws_iam_policy.httpbin_ec2_firehose.arn}"
}
