# ==============================================================================
# CONTROL PLANE INSTANCE - PRODUCTION ENHANCED
# ==============================================================================

resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_control_plane  # CHANGED: Now uses control_plane specific type
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true
  
  # References the resources defined in network.tf
  subnet_id                   = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  # ENHANCED: Larger root volume to prevent disk exhaustion
  root_block_device {
    volume_type           = "gp3"                               # ENHANCED: gp3 is faster than gp2
    volume_size           = var.root_volume_size_control_plane  # ENHANCED: Configurable size (50GB default)
    delete_on_termination = true
    encrypted             = true  # ENHANCED: Enable encryption
    
    tags = {
      Name = "${var.cluster_name}-control-plane-root"
    }
  }

  # ENHANCED: Monitoring for observability
  monitoring = true

  # ENHANCED: Security best practices - IMDSv2 only
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  # ENHANCED: CPU credits configuration for burstable instances
  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name                = "${var.cluster_name}-control-plane"
    Role                = "control-plane"
    Environment         = var.environment
    ManagedBy           = "Terraform"
    KubernetesCluster   = var.cluster_name
  }

  depends_on = [
    aws_internet_gateway.k8s_gw
  ]
}

# ==============================================================================
# WORKER INSTANCES - PRODUCTION ENHANCED (Using count to create 3 nodes)
# ==============================================================================

resource "aws_instance" "worker" {
  count                       = 3
  ami                         = var.ami_id
  instance_type               = var.instance_type_worker  # CHANGED: Now uses worker specific type
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  # References the resources defined in network.tf
  subnet_id                   = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  # ENHANCED: Larger root volume to prevent disk exhaustion
  root_block_device {
    volume_type           = "gp3"                           # ENHANCED: gp3 is faster than gp2
    volume_size           = var.root_volume_size_worker     # ENHANCED: Configurable size (30GB default)
    delete_on_termination = true
    encrypted             = true  # ENHANCED: Enable encryption
    
    tags = {
      Name = "${var.cluster_name}-worker-${count.index + 1}-root"
    }
  }

  # ENHANCED: Monitoring for observability
  monitoring = true

  # ENHANCED: Security best practices - IMDSv2 only
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  # ENHANCED: CPU credits configuration for burstable instances
  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name                = "${var.cluster_name}-worker-${count.index + 1}"
    Role                = "worker"
    WorkerIndex         = count.index + 1
    Environment         = var.environment
    ManagedBy           = "Terraform"
    KubernetesCluster   = var.cluster_name
  }

  depends_on = [
    aws_internet_gateway.k8s_gw
  ]
}
