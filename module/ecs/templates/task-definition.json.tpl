[
  {
    "name": "app",
    "image": "${container_image}",
    "cpu": ${cpu},
    "memory": ${memory},
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${container_port},
        "protocol": "tcp"
      }
    ],
    "environment": [
      { "name": "DB_HOST", "value": "${database_host}" },
      { "name": "DB_NAME", "value": "${database_name}" }
    ],
    "secrets": [
      { "name": "DB_USERNAME", "valueFrom": "${database_secret_arn}:username::" },
      { "name": "DB_PASSWORD", "valueFrom": "${database_secret_arn}:password::" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${awslogs_group}",
        "awslogs-region": "${awslogs_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": [ "CMD-SHELL", "curl -f http://localhost:${container_port}/ || exit 1" ],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
    }
  }
]
