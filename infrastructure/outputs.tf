output "control_plane_ip" {
  value       = aws_instance.control_plane.public_ip
  description = "Control Plane public IP address"
}

output "worker_ips" {
  value       = [for w in aws_instance.workers : w.public_ip]
  description = "List of worker node public IP addresses"
}

output "vpc_id" {
  value       = aws_vpc.k8s_vpc.id
  description = "VPC ID"
}

output "security_group_id" {
  value       = aws_security_group.k8s_nodes.id
  description = "Security group for K8s nodes"
}
