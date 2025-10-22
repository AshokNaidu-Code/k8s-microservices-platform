# infrastructure/keys.tf

# Imports the public key content provided via the CLI variable
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-platform-key" # Name that will appear in AWS console
  public_key = var.ssh_public_key
}