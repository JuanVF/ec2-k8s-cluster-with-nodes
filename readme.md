# Build Kubernetes Cluster out of EC2 Nodes

Disclaimer: This project is a customization of "https://github.com/Ahmad-Faqehi/Terraform-Bulding-K8S" by @Ahmad-Faqehi.

This project can create a Kubernetes Cluster that can be used remotely by using EC2 instances. The creation is done using Terraform and this customization can cherry pick which instance type to use for each ec2 instance node.

# AWS Resources

- EC2: Creates a master node and worker nodes. You can select what instance type to use in your tfvars.

- VPC: Creates the required VPC resources to enable the cluster to used and access it.

- S3 Initialization bucket: Uses a bucket to initialize the worker nodes.

# Pre Requirements

1 - Create a .pem file to be able to access the instance.

2 - Create access_keys and secret_keys, preferable with a service account!

# How to use it

1 - Clone this repository

2 - Create a `tfvars` file.

3 - Run the `make plan FILE_NAME=<tfvars file>` command to check the resources to be created.

4 - Run the `make deploy FILE_NAME=<tfvars file>` command to deploy to AWS.

# Get the kubeconfig

You can by accessing the master node using this command

> scp -i <Your_Key_Piar> ubuntu@<MasterNode_Public_IP>:/tmp/admin.conf .

Then you can use that `.conf` file using kubectl or Lens to check the cluster!

# Destroy

Destroy the cluster by using

> terraform destroy -var-file=<tfvars_file>
