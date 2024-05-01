# -------------------------------------------
#               AWS Variables
# -------------------------------------------

variable "region" {
  description = "AWS Region to use"
  default     = "us-east-1"
}

variable "access_key" {
  description = "AWS Access Key to use"
  #default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "secret_key" {
  description = "AWS Secret Key to use"
  #default     = "XXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "pem_file" {
  description = "The PEM file to be able to access"
  #default     = "file_name_without_pem_extension"
}


# --------------------------------------------
#           Kubernetes Variables
# --------------------------------------------

variable "setup_bucket_name" {
  description = "The kubernetes setup bucket name"
  #default     = "A random name"
}

variable "kubernetes_ami_id" {
  description = "The kubernetes AMIs to use for each node"
  default     = "ami-0e001c9271cf7f3b9" # us-east-1 | Ubuntu 22.04 
}

variable "kubernetes_master_node_instance_type" {
  description = "The Kubernetes Instance Type"
  default     = "t2.medium" # Not as expensive, enough resources
}

variable "kubernetes_worker_nodes_instance_types" {
  description = "The instance type for each kubernetes worker node"
  type        = list(string)
  default     = ["t2.small", "t2.medium"]
}
