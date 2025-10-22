output "control_plane_ip" {
  description = "Public IP address of the Kubernetes Control Plane node."
  # FIX: Removed [0] because control_plane is a single resource.
  value = aws_instance.control_plane.public_ip
}

output "worker_ips" {
  description = "List of Public IP addresses for the Kubernetes Worker nodes."
  # Worker nodes use 'count', so they need the splat operator [*] to get all IPs.
  value = aws_instance.worker[*].public_ip
}
