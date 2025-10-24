resource "aws_key_pair" "k8s_key" {
  key_name   = "${var.cluster_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.cluster_name}-key"
  }
}
