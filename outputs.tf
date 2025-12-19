output "alb_dns_name" {
  description = "The URL of your Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "latest_ecs_ami_id" {
  description = "The AMI ID Terraform found for you"
  value       = data.aws_ami.ecs_optimized.id
}