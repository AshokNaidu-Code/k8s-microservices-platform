provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "k8s_worker" {
  count         = 3
  ami           = "<ami-id>"
  instance_type = "t3.medium"
  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

# See README in this folder for initialization and commands.
