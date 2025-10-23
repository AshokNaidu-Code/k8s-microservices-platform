# ==============================================================================
# AWS Provider Configuration Variables
# ==============================================================================

variable "aws_region" {
  description = "The AWS region to deploy the resources into."
  type        = string
  default     = "us-east-1"
}

# ==============================================================================
# EC2 Instance Configuration Variables - ENHANCED FOR PRODUCTION
# ==============================================================================

variable "ami_id" {
  description = "The AMI ID for the EC2 instances (Ubuntu Server 24.04 LTS recommended)."
  type        = string
  # IMPORTANT: This AMI is for us-east-1. Update this value if you use a different region.
  default     = "ami-0c02fb55731490381"  # Ubuntu 24.04 LTS in us-east-1
}

# ENHANCED: Better instance types for production
variable "instance_type_control_plane" {
  description = "EC2 instance type for control plane (needs more resources)"
  type        = string
  default     = "t3.medium"  # UPGRADED: 2 vCPU, 4GB RAM (from t2.medium: 2 vCPU, 4GB RAM)
}

variable "instance_type_worker" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"  # UPGRADED: 2 vCPU, 2GB RAM (from t2.medium: 2 vCPU, 4GB RAM)
}

# ENHANCED: Configurable disk sizes to prevent disk exhaustion
variable "root_volume_size_control_plane" {
  description = "Root volume size (GB) for control plane"
  type        = number
  default     = 50  # UPGRADED: From 8GB default to 50GB
}

variable "root_volume_size_worker" {
  description = "Root volume size (GB) for worker nodes"
  type        = number
  default     = 30  # UPGRADED: From 8GB default to 30GB
}

# ENHANCED: SSH key configuration
variable "ssh_public_key" {
  description = "The content of the SSH public key (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}

# ENHANCED: Cluster identification
variable "cluster_name" {
  description = "Name identifier for the Kubernetes cluster"
  type        = string
  default     = "k8s-microservices"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "production"
}
