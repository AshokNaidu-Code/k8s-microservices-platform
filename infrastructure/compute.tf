# ==============================================================================
# 1. CONTROL PLANE INSTANCE
# ==============================================================================
resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true
  
  # References the resources defined in network.tf
  subnet_id                   = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-control-plane"
    Role = "control-plane"
  }
}

# ==============================================================================
# 2. WORKER INSTANCES (Using count to create 3 nodes)
# ==============================================================================
resource "aws_instance" "worker" {
  count                       = 3
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  # References the resources defined in network.tf
  subnet_id                   = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}