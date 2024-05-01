# --------------------------------
#             VPC
# --------------------------------

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "kubernetes_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "kubernetes vpc"
  }
}

resource "aws_subnet" "kubernetes_subnet" {
  vpc_id            = aws_vpc.kubernetes_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "kubernetes subnet"
  }
}

resource "aws_internet_gateway" "kubernetes_ig" {
  vpc_id = aws_vpc.kubernetes_vpc.id

  tags = {
    Name = "kubernetes internet gateway"
  }
}

resource "aws_route_table" "kubernetes_rt" {
  vpc_id = aws_vpc.kubernetes_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.kubernetes_ig.id
  }

  tags = {
    Name = "kubernetes route table"
  }
}

resource "aws_route_table_association" "kubernetes_rta" {
  subnet_id      = aws_subnet.kubernetes_subnet.id
  route_table_id = aws_route_table.kubernetes_rt.id
}

resource "aws_security_group" "kubernetes_sg" {
  name   = "kubernetes ports"
  vpc_id = aws_vpc.kubernetes_vpc.id

  # internet protocol
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # kubernetes api server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # etcd server client API
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # sh port
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort ports
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------
#     Kubernetes Bucket Setup
# --------------------------------

resource "aws_s3_bucket" "setup_bucket" {
  bucket        = var.setup_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "setup_bucket_acl_ownership" {
  bucket = aws_s3_bucket.setup_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [aws_s3_bucket.setup_bucket]
}

resource "aws_s3_bucket_acl" "setup_bucket_acl" {
  bucket     = aws_s3_bucket.setup_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.setup_bucket_acl_ownership]
}

# --------------------------------
#     Kubernetes Config
# --------------------------------

resource "aws_instance" "kubernetes_master_node" {
  ami           = var.kubernetes_ami_id
  subnet_id     = aws_subnet.kubernetes_subnet.id
  instance_type = var.kubernetes_master_node_instance_type
  key_name      = var.pem_file

  associate_public_ip_address = true

  security_groups = [aws_security_group.kubernetes_sg.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  tags = {
    Name = "kubernetes_master_node"
  }

  user_data_base64 = base64encode("${templatefile("scripts/install_kubernetes_masternode.sh", {
    access_key        = var.access_key,
    secret_key        = var.secret_key,
    region            = var.region,
    setup_bucket_name = var.setup_bucket_name
  })}")

  depends_on = [aws_s3_bucket.setup_bucket, aws_subnet.kubernetes_subnet]
}

resource "aws_instance" "kubernetes_worker_node" {
  ami           = var.kubernetes_ami_id
  count         = length(var.kubernetes_worker_nodes_instance_types)
  subnet_id     = aws_subnet.kubernetes_subnet.id
  instance_type = var.kubernetes_worker_nodes_instance_types[count.index]
  key_name      = var.pem_file

  associate_public_ip_address = true

  security_groups = [aws_security_group.kubernetes_sg.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  tags = {
    Name = "kubernetes_worker_node_${count.index + 1}"
  }

  user_data_base64 = base64encode("${templatefile("scripts/install_kubernetes_workernode.sh", {
    access_key        = var.access_key,
    secret_key        = var.secret_key,
    region            = var.region,
    setup_bucket_name = var.setup_bucket_name,
    worker_number     = "${count.index + 1}"
  })}")

  depends_on = [aws_s3_bucket.setup_bucket, aws_subnet.kubernetes_subnet, aws_instance.kubernetes_master_node]
}
