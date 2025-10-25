resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.control_plane_instance_type
  subnet_id              = aws_subnet.k8s_public.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = aws_key_pair.k8s_key.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Control Plane Node"
              EOF
  )

  tags = {
    Name = "${var.cluster_name}-control-plane"
    Role = "control-plane"
  }

  depends_on = [aws_internet_gateway.k8s_igw]
}

resource "aws_instance" "workers" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.k8s_public[count.index].id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = aws_key_pair.k8s_key.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Worker Node ${count.index + 1}"
              EOF
  )

  tags = {
    Name = "${var.cluster_name}-worker-${count.index + 1}"
    Role = "worker"
  }
}

output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_public_ips" {
  value = [for w in aws_instance.workers : w.public_ip]
}
