# Terraform

[![CI](https://github.com/bstraehle/terraform/actions/workflows/ci.yml/badge.svg)](https://github.com/bstraehle/terraform/actions/workflows/ci.yml)

[Terraform](https://developer.hashicorp.com/terraform) is an infrastructure as code tool by HashiCorp. You describe infrastructure in HashiCorp Configuration Language (HCL), and Terraform creates, updates, and destroys it to match.

This repo provisions an Amazon EKS cluster and deploys the demo [MVC app](https://github.com/bstraehle/dotnet-mvc-app) and [REST API](https://github.com/bstraehle/dotnet-rest-api) to it.

## Table of Contents

1. [Layout](#1-layout)
2. [Prerequisites](#2-prerequisites)
3. [Provision the EKS Cluster](#3-provision-the-eks-cluster)
4. [Deploy the Apps](#4-deploy-the-apps)
5. [Clean Up](#5-clean-up)
6. [CI](#6-ci)
7. [Resources](#7-resources)

## 1. Layout

| Directory | What it does |
| --- | --- |
| [`eks/`](eks) | VPC ([terraform-aws-modules/vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) 6.7.3) and EKS cluster ([terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) 21.29.0): Kubernetes 1.37, one managed node group (AL2023, `t3.medium`, 2 nodes), core add-ons, and an [access entry](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html) that makes you cluster admin |
| [`kubernetes/`](kubernetes) | Reads the cluster from the `eks` state and deploys the apps with the module below |
| [`modules/demo-apps/`](modules/demo-apps) | Namespace `demo` (enforces the restricted Pod Security Standard), plus a ServiceAccount, Deployment (one replica, because both apps keep per-pod state), and Service per app. Pods run as non-root with a read-only filesystem, probes, and resource limits. Same design as [bstraehle/kubernetes](https://github.com/bstraehle/kubernetes). |

Two separate workspaces keep the cluster's lifecycle apart from the workloads, so you can redeploy apps without touching the cluster.

## 2. Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) with credentials that can create VPC, EKS, IAM, and EC2 resources
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

On Amazon Linux:

```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

Configure AWS credentials, e.g. with `aws configure` or by exporting them:

```shell
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
```

> Note: This creates billable resources (EKS control plane, EC2 nodes, a NAT gateway, and a load balancer). Destroy them when done.

## 3. Provision the EKS Cluster

The EKS API endpoint is public but only reachable from the CIDRs in `api_allowed_cidrs`, which has no default. Allow your current public IP:

```shell
git clone https://github.com/bstraehle/terraform.git
cd terraform/eks

cat > terraform.tfvars <<EOF
api_allowed_cidrs = ["$(curl -s https://checkip.amazonaws.com)/32"]
EOF

terraform init
terraform plan
terraform apply
```

Provisioning takes about 15 minutes. Optional variables: `region` (default `us-west-2`), `cluster_name` (`terraform-eks`), `kubernetes_version` (`1.37`), `node_instance_types`, `node_count`. `node_count.desired` only applies when the node group is created; to resize an existing group, change `min`/`max` or use the AWS console or CLI.

Configure kubectl and check the nodes:

```shell
$(terraform output -raw configure_kubectl)
kubectl get nodes
```

## 4. Deploy the Apps

```shell
cd ../kubernetes

terraform init
terraform apply

kubectl -n demo get deployments,pods,services
terraform output mvc_app_url
```

Open the `mvc_app_url` (the load balancer takes a few minutes to resolve) and choose **Demo** to list data from the API. To deploy another image tag: `terraform apply -var image_tag=<tag>`.

The demo apps have no authentication and serve plain HTTP, so the load balancer only accepts clients from `api_allowed_cidrs` in the `eks` workspace. Override this with `-var 'mvc_app_allowed_cidrs=["<cidr>"]'`. Cross-zone load balancing is enabled, so every zone of the load balancer can reach the nodes.

## 5. Clean Up

Destroy in reverse order, so the app's load balancer is deleted before the VPC:

```shell
cd kubernetes && terraform destroy
cd ../eks && terraform destroy
```

## 6. CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push and pull request, and weekly. It creates no AWS resources:

- `terraform fmt` and `terraform validate` for every root and module, and checks that the lock files are current.
- `terraform test` for [`modules/demo-apps`](modules/demo-apps/tests) with a mocked provider, which asserts the ports and security settings.
- [TFLint](https://github.com/terraform-linters/tflint) with the recommended and AWS rulesets.
- [Trivy](https://trivy.dev/) misconfiguration scan. Accepted findings are documented in [`.trivyignore`](.trivyignore).
- End to end: applies `modules/demo-apps` to a kind cluster, checks `/Demo/List`, which goes from the MVC app through to the API, and checks that a second plan shows no drift.

## 7. Resources

- [Provision an EKS cluster (AWS)](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks)
- [Provision an AKS cluster (Azure)](https://developer.hashicorp.com/terraform/tutorials/kubernetes/aks)
- [Provision a GKE cluster (Google Cloud)](https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke)
- [Manage Kubernetes resources via Terraform](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider)
- [Terraform Registry](https://registry.terraform.io/)
