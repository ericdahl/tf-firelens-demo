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

## httpbin-fargate-firehose

ships logs to Kinesis Firehose to an S3 bucket

- ECS Fargate Service `httpbin-fargate-firehose`
    - Containers
        - httpbin: http://httpbin.org type container (http debugging)
            - log configuration:  awsfirelens
                - Name: firehose
                - delivery_stream: httpbin-fargate-firelens-app
        - redis: vanilla redis container (not linked into any other container)  
            - log configuration:  awsfirelens
                            - Name: firehose
                            - delivery_stream: httpbin-fargate-firelens-app
        - firelens
            - log configuration: awslogs
                - awslogs-stream-prefix: firelens
                - awslogs-group: /ecs/httpbin-fargate-firelens-firehose
                
## Notes

- `awsfirelens` log driver is synatic sugar for fluentd log driver
- logs routed over unix local socket to firelens container

## EC2 firehose data flow

```
[app container] -> (fluentd log driver local unix socket) -> [fluent-bit firelens container] -> Firehose
```

- httpbin container has `LogConfig` for `fluentd` with
    - "fluentd-address": "unix:///var/lib/ecs/data/firelens/c6c182f6a4a4462e972f34f357b6daac/socket/fluent.sock",
        - note: c6c182f6a4a4462e972f34f357b6daac is the ID part of Task ARN
    - "fluentd-async-connect": "true",
    - "tag": "httpbin-firelens-c6c182f6a4a4462e972f34f357b6daac"
    - **note** task definition said `"logDriver": "awsfirelens"` - this was translated by ECS on container creation
- fluent-bit firelens container has `
    - LogConfig` for `awslogs` with
        - settings:
            - "awslogs-credentials-endpoint": "/v2/credentials/1234567-1234-1234-1234-1234567",
            - "awslogs-group": "/ecs/httpbin-ec2-firelens-firehose",
            - "awslogs-region": "us-east-1",
            - "awslogs-stream": "firelens/firelens/c6c182f6a4a4462e972f34f357b6daac"
        - this is just for fluent-bit stdout logs
    - mounts for
    
    ```
            {
                "Type": "bind",
                "Source": "/var/lib/ecs/data/firelens/c6c182f6a4a4462e972f34f357b6daac/config/fluent.conf",
                "Destination": "/fluent-bit/etc/fluent-bit.conf",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            },
            {
                "Type": "bind",
                "Source": "/var/lib/ecs/data/firelens/c6c182f6a4a4462e972f34f357b6daac/socket",
                "Destination": "/var/run",
                "Mode": "",
                "RW": true,
                "Propagation": "rprivate"
            }
        ],
    ```
  
        - note: these mounts are not in task definition. `firelensConfiguration` in task definition
          automatically injects these mounts on container creation
          
      - fluent-bit config is 
      
      ```
        [ec2-user@ip-10-0-103-81 firelens]$ cat /var/lib/ecs/data/firelens/c6c182f6a4a4462e972f34f357b6daac/config/fluent.conf
        
        [INPUT]
            Name forward
            unix_path /var/run/fluent.sock
        
        [INPUT]
            Name forward
            Listen 0.0.0.0
            Port 24224
        
        [INPUT]
            Name tcp
            Tag firelens-healthcheck
            Listen 127.0.0.1
            Port 8877
        
        [FILTER]
            Name record_modifier
            Match *
            Record ec2_instance_id i-084db98f2a1b712de
            Record ecs_cluster tf-firelens-demo
            Record ecs_task_arn arn:aws:ecs:us-east-1:12345678:task/tf-firelens-demo/c6c182f6a4a4462e972f34f357b6daac
            Record ecs_task_definition httpbin-ec2:13
        
        [OUTPUT]
            Name null
            Match firelens-healthcheck
        
        [OUTPUT]
            Name firehose
            Match redis-firelens*
            delivery_stream httpbin-ec2-firelens-app
            region us-east-1
        
        [OUTPUT]
            Name firehose
            Match httpbin-firelens*
            delivery_stream httpbin-ec2-firelens-app
            region us-east-1
        ```
    - This `firehose` output plugin is from here: https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit

    
# TODO
- [ ] Firehose -> Splunk demo
- [ ] cleanup/organize
- [ ] add external fluentd server
- [ ] refactor services to submodules?
