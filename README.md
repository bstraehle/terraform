# Terraform

Terraform is an open-source infrastructure as code software tool created by HashiCorp. Users define and provide data center infrastructure using a declarative configuration language known as HashiCorp Configuration Language (HCL).

See https://www.terraform.io/downloads, https://registry.terraform.io, and https://cloud.hashicorp.com/products/terraform.

## Install on Amazon Linux

```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

## Commands

```
terraform init
terraform plan
terraform apply -auto-approve

terraform destroy -auto-approve
```

## Example: EKS Cluster and Kubernetes Resource Provisioning

```
ssh -i <key-pair>.pem ec2-user@<public-ipv4-address>
```

```
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
```

- Init/plan/apply files in eks directory

```
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

- Init/plan/apply file in kubernetes directory

```
kubectl get nodes,services,deployments
```

## Resources

- https://learn.hashicorp.com/tutorials/terraform/eks
- https://learn.hashicorp.com/tutorials/terraform/aks
- https://learn.hashicorp.com/tutorials/terraform/gke
- https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider
