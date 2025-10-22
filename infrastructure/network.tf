# Define the VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k8s-vpc"
  }
}

# Define the Internet Gateway
resource "aws_internet_gateway" "k8s_gw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

# Define the Public Subnet
resource "aws_subnet" "k8s_public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Instances in this subnet get public IPs

  tags = {
    Name = "k8s-public-subnet"
  }
}

# Define the Route Table and link it to the Internet Gateway
resource "aws_route_table" "k8s_public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_gw.id
  }

  tags = {
    Name = "k8s-public-rt"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "k8s_public_rt_association" {
  subnet_id      = aws_subnet.k8s_public_subnet.id
  route_table_id = aws_route_table.k8s_public_rt.id
}

# ==============================================================================
# SECURITY GROUP DEFINITION
# ==============================================================================
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-security-group"
  description = "Security group for the Kubernetes cluster nodes"
  vpc_id      = aws_vpc.k8s_vpc.id

  # --- INGRESS RULES ---

  # 1. ALLOW SSH from anywhere for provisioning (REQUIRED FIX)
  ingress {
    description = "Allow SSH from anywhere for Ansible access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH from any IP
  }

  # 2. ALLOW Kubernetes API access (Control Plane) from anywhere
  ingress {
    description = "Allow Kubernetes API access"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 3. Allow NodePort services (30000-32767) from anywhere
  ingress {
    description = "Allow NodePort access"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. ALLOW All traffic within the VPC (for Pod/Node communication)
  ingress {
    description = "Allow all traffic within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block] # 10.0.0.0/16
  }

  # --- EGRESS RULES ---

  # 5. Allow ALL outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}
