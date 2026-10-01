# DevOps Diplom

Infrastructure and Kubernetes configuration for the DevOps diplom project.

## Architecture

```text
Internet
   |
   v
Yandex Network Load Balancer :80
   |
   v
Traefik NodePort :30080
   |
   +-- /         -> devops-diplom-app
   |
   +-- /grafana  -> Grafana

Kubernetes:
- 1 control-plane node
- 2 worker nodes
- Calico CNI
- containerd

Monitoring:
- Prometheus
- Grafana
- Alertmanager
- node-exporter
- kube-state-metrics
```

## Repository structure

```text
terraform/
  bootstrap/        Terraform backend and service account bootstrap
  infrastructure/   VPC, subnets, security group, VMs and Network Load Balancer

ansible/
  inventory/        Kubespray inventory and cluster variables

kubernetes/
  app/              Application Deployment, Service and Ingress
  monitoring/       Grafana Ingress and NetworkPolicy
  traefik/          Traefik Helm values

monitoring/
  kube-prometheus/  Reproducible kube-prometheus installation and patches
```

## Terraform

Terraform state for the main infrastructure is stored remotely in Yandex Object Storage.

The bootstrap configuration creates the backend resources separately from the main infrastructure.

Public application IP:

```bash
terraform -chdir=terraform/infrastructure output -raw traefik_load_balancer_ip
```

Application:

```text
http://<load-balancer-ip>/
```

Grafana:

```text
http://<load-balancer-ip>/grafana/
```

## Kubernetes

The cluster is deployed with Kubespray.

Current Kubernetes version:

```text
v1.36.0
```

Cluster verification:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Monitoring

Monitoring is installed using a pinned kube-prometheus revision.

Grafana dashboards and Prometheus datasource are provisioned automatically.

## Secrets

Credentials, Terraform state, generated kubeconfig files and other sensitive artifacts are excluded from Git via `.gitignore`.

## Terraform CI/CD

GitHub Actions validates and plans Terraform changes for pull requests targeting `main`.

For pushes to `main`, the workflow runs:

```text
fmt -> init -> validate -> plan -> apply
```

Terraform credentials are provided through GitHub Actions secrets and are not stored in the repository.
