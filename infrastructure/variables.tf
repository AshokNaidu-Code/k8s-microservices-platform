variable "aws_region" {
  description = "The AWS region to deploy the resources into."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "k8s-microservices-platform"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances (Ubuntu Server 22.04 LTS recommended)."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The EC2 instance type to use for all cluster nodes."
  type        = string
  default     = "t2.medium"
}

variable "ssh_public_key" {
  description = "The content of the SSH public key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for control plane"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for workers"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}
