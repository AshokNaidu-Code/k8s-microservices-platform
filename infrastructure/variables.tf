# ==============================================================================
# AWS Provider Configuration Variables
# ==============================================================================

variable "aws_region" {
  description = "The AWS region to deploy the resources into."
  type        = string
  default     = "us-east-1" # Change this to your preferred region if needed
}

# ==============================================================================
# EC2 Instance Configuration Variables
# ==============================================================================

variable "ami_id" {
  description = "The AMI ID for the EC2 instances (Ubuntu Server 22.04 LTS recommended)."
  type        = string
  # IMPORTANT: This AMI is for us-east-1. Update this value if you use a different region.
  default     = "ami-0360c520857e3138f"
}

variable "instance_type" {
  description = "The EC2 instance type to use for all cluster nodes."
  type        = string
  # t2.medium provides enough CPU and memory for a small Kubernetes cluster.
  default     = "t2.medium"
}

variable "ssh_public_key" {
  description = "The content of the SSH public key (e.g., ~/.ssh/id_rsa.pub) to be injected into the virtual machines for secure access."
  type        = string
  sensitive   = true
}
