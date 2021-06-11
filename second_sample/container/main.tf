provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_ecs_cluster" "sugar_ecs_cluster" {
    name = "sugar-ecs-cluster"
}

resource "aws_ecs_task_definition" "sugar_ecs_task" {
    family = "sugar-ecs-task"
    cpu = "256"
    memory = "512"
    network_mode = "awsvpc"
    requires_compatibilities = [ "FARGATE" ]
    container_definitions = file("./container_definitions.json")
    execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# サービスは起動するタスクの数を定義でき、指定した数のタスクを維持する
resource "aws_ecs_service" "sugar_ecs_service" {
    name = "sugar-ecs-service"
    cluster = aws_ecs_cluster.sugar_ecs_cluster.arn
    task_definition = aws_ecs_task_definition.sugar_ecs_task.arn  
    desired_count = 2
    launch_type = "FARGATE"
    platform_version = "1.3.0"
    health_check_grace_period_seconds = 60

    network_configuration {
        assign_public_ip = false
        security_groups = [module.nginx_sg.security_group_id]

        subnets = [
            aws_subnet.sugar_private_0.id,
            aws_subnet.sugar_private_1.id,
        ]
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.sugar_tg.arn
        container_name = "sugar-container"
        container_port = 80
    }

    lifecycle {
        ignore_changes = [task_definition]
    }

    depends_on = [
      aws_lb_listener.sugar_http
    ]
}

module "nginx_sg" {
    source = "./security_group"
    name = "nginx-sg"
    vpc_id = aws_vpc.sugar_vpc.id
    port = 80
    cidr_blocks = [aws_vpc.sugar_vpc.cidr_block]
}