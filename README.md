# tf-firelens-demo

Demo ECS application illustrating how to use [ECS FireLens](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_firelens.html) to:

- ship logs to CloudWatch
    - adds metadata like task-id to log

        ```json
        {
            "container_id": "4bc3dc769980270dda04757ebc869de045c89bc8491123642e058f8c522ff783",
            "container_name": "/ecs-httpbin-fargate-10-httpbin-ecd2a483b192d6a94c00",
            "ecs_cluster": "arn:aws:ecs:us-east-1:123456789:cluster/tf-ecs-fargate",
            "ecs_task_arn": "arn:aws:ecs:us-east-1:123456789:task/tf-ecs-fargate/9355824e63ee43d49dfbd3b33edeed7e",
            "ecs_task_definition": "httpbin-fargate:10",
            "log": "10.0.2.45 - - [25/Nov/2019:01:55:26 +0000] \"GET / HTTP/1.1\" 200 12026 \"-\" \"ELB-HealthChecker/2.0\"",
            "source": "stdout"
        }
        ```

- ships logs to Kinesis Firehose to an S3 bucket
    
# TODO
- [ ] cleanup/organize
- [ ] add external fluentd server
- [ ] refactor services to submodules?
