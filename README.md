# LMS Auto-K8s-Deployment — EKS Lab

Deploy a Python Library Management System on Kubernetes using Terraform.

---

## Prerequisites

Make sure these are installed:

```bash
terraform -v
docker -v
kubectl version --client
aws --version
```

---

## Project Structure

```
lms-eks-deployment/
  terraform-eks/
    main.tf
  k8s/
    library-deployment.yaml
    library-service.yaml
```

---

## Step 1 — Configure AWS CLI

```bash
aws configure
```

Verify your identity:

```bash
aws sts get-caller-identity
```

---

## Step 2 — Push Docker Image to ECR

Authenticate Docker to ECR:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Build image:

```bash
docker build -t lms-project .
```

Tag image:

```bash
docker tag lms-project:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/lms-project:latest
docker tag lms-project:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/lms-project:1.0
```

Push image:

```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/lms-project:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/lms-project:1.0
```

Verify image exists in ECR:

```bash
aws ecr describe-images --repository-name lms-project --region us-east-1
```

---

## Step 3 — Provision Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

> Takes 10-15 minutes. Creates VPC, Subnets, IGW, Route Tables, EKS Cluster, and Worker Nodes automatically.

---

## Step 4 — Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name auto-k8s-deployment
```

Verify nodes are ready:

```bash
kubectl get nodes
```

---

## Step 5 — Deploy Application

```bash
kubectl apply -f k8s/library-deployment.yaml
kubectl apply -f k8s/library-service.yaml
```

---

## Step 6 — Verify Deployment

Check pods are running:

```bash
kubectl get pods
```

Check service and get external IP:

```bash
kubectl get svc
```

Test application in browser:

```
http://<external-ip>/
http://<external-ip>/books
http://<external-ip>/add/NewBook
```

---

## Step 7 — Test Scaling

Scale up to 6 pods:

```bash
kubectl scale deployment library-deployment --replicas=6
```

Check pods:

```bash
kubectl get pods
```

Scale back down to 4:

```bash
kubectl scale deployment library-deployment --replicas=4
```

---

## Step 8 — Destroy (When Done)

Always delete Kubernetes resources first to remove the LoadBalancer:

```bash
kubectl delete -f k8s/library-service.yaml
kubectl delete -f k8s/library-deployment.yaml
```

Wait 2 minutes, then destroy infrastructure:

```bash
terraform destroy
```

---

## Useful Commands

```bash
# Check your AWS identity
aws sts get-caller-identity

# Check cluster nodes
kubectl get nodes

# Check pods
kubectl get pods

# Check service external IP
kubectl get svc

# Check why a pod is failing
kubectl describe pod <pod-name>

# Check images in ECR
aws ecr describe-images --repository-name lms-project --region us-east-1

# Check EKS cluster details
aws eks describe-cluster --name auto-k8s-deployment --region us-east-1
```

---

## Infrastructure Details

| Resource | Value |
|---|---|
| Cluster Name | auto-k8s-deployment |
| Region | us-east-1 |
| VPC CIDR | 10.0.0.0/16 |
| Subnet 1 | 10.0.1.0/24 — us-east-1a |
| Subnet 2 | 10.0.2.0/24 — us-east-1b |
| Node Type | t3.medium |
| Min Nodes | 1 |
| Desired Nodes | 2 |
| Max Nodes | 3 |
