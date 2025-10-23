# infrastructure/keys.tf
# SSH Key Pair Configuration

resource "aws_key_pair" "k8s_key" {
  key_name   = "${var.cluster_name}-key"  # ENHANCED: Dynamic name based on cluster
  public_key = var.ssh_public_key
  
  tags = {
    Name        = "${var.cluster_name}-key"
    Environment = var.environment
  }
}
