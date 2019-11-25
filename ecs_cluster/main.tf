provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}"

  tags = {
    ClusterName = "${var.cluster_name}"
  }
}
