data "template_file" "httpbin_fargate_cloudwatch" {
  template = "${file("templates/tasks/httpbin-fargate-cloudwatch.json")}"
}

resource "aws_ecs_task_definition" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.httpbin_fargate_cloudwatch.rendered}"
  family                = "httpbin-fargate"

  requires_compatibilities = [
    "FARGATE",
  ]

  execution_role_arn = "${module.ecs.aws_iam_role_ecs_task_execution_arn}"

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  task_role_arn = "${aws_iam_role.task_httpbin_fargate_cloudwatch.arn}"
}

resource "aws_iam_role" "task_httpbin_fargate_cloudwatch" {
  name = "task-httpbin-fargate-cloudwatch"

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

resource "aws_iam_policy" "task_httpbin_fargate_cloudwatch" {
  name = "task_httpbin_fargate_cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_httpbin_fargate_cloudwatch" {
  role       = "${aws_iam_role.task_httpbin_fargate_cloudwatch.name}"
  policy_arn = "${aws_iam_policy.task_httpbin_fargate_cloudwatch.arn}"
}

resource "aws_ecs_service" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name            = "httpbin-fargate-cloudwatch"
  cluster         = "${module.ecs.cluster_name}"
  task_definition = "${aws_ecs_task_definition.httpbin_fargate_cloudwatch.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      "${module.vpc.sg_allow_8080}",
      "${module.vpc.sg_allow_egress}",
      "${module.vpc.sg_allow_vpc}",
    ]

    subnets = [
      "${module.vpc.subnet_private1}",
    ]
  }

  depends_on = [
    "aws_alb.httpbin_fargate_cloudwatch",
  ]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.httpbin_fargate_cloudwatch.arn}"
    container_name   = "httpbin"
    container_port   = 8080
  }
}

resource "aws_cloudwatch_log_group" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name = "/ecs/httpbin-fargate-cloudwatch"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "httpbin_fargate_cloudwatch_firelens" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name = "/ecs/httpbin-fargate-firelens"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "httpbin_fargate_cloudwatch_firelens_app" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name = "/ecs/httpbin-fargate-firelens-app"

  retention_in_days = 7
}

resource "aws_alb" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name = "httpbin-fargate-cloudwatch"

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

resource "aws_alb_listener" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  default_action {
    target_group_arn = "${aws_alb_target_group.httpbin_fargate_cloudwatch.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.httpbin_fargate_cloudwatch.arn}"
  port              = 80
}

resource "aws_alb_target_group" "httpbin_fargate_cloudwatch" {
  count = "${var.enable_fargate_httpbin_cloudwatch == "true" ? 1 : 0}"

  name                 = "httpbin-fargate-cloudwatch"
  vpc_id               = "${module.vpc.vpc_id}"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 5
    timeout             = 2
  }
}
