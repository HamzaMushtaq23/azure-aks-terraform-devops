# Azure AKS Terraform DevOps Project

End-to-end Azure DevOps project demonstrating Infrastructure as Code with Terraform, containerization with Docker, image management with Azure Container Registry (ACR), and application deployment to Azure Kubernetes Service (AKS).

The project uses separate Terraform Plan and Apply pipelines for infrastructure and an automated CI/CD pipeline for the application.

---

## 1. Project Overview

This project creates and manages the following Azure infrastructure:

- Azure Resource Group
- Azure Virtual Network (VNet)
- Azure Subnet
- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)
- AKS-to-ACR `AcrPull` role assignment
- Azure Storage backend for Terraform remote state

The application is:

1. Built into a Docker image.
2. Pushed to Azure Container Registry.
3. Deployed to AKS using Kubernetes manifests.
4. Exposed through a Kubernetes `LoadBalancer` service.

Terraform infrastructure changes and application changes follow separate deployment flows.

---

# 2. Architecture

```text
                         GitHub Repository
                                |
                 +--------------+--------------+
                 |                             |
                 v                             v
        Terraform Plan Pipeline        Application CI/CD
                 |                             |
                 v                             v
          terraform plan               Docker Build
                 |                             |
                 v                             v
       Terraform Plan Artifact              ACR
                 |                             |
                 v                             v
       Terraform Apply Pipeline              AKS
                 |                             |
                 v                             v
       Azure Infrastructure              Kubernetes
                                           Deployment
                                               |
                                               v
                                         LoadBalancer
                                               |
                                               v
                                          Web Browser
Terraform Backend
terraform-bootstrap/
        |
        v
Azure Storage Account
        |
        v
Blob Container
        |
        v
terraform/ remote state
        |
        v
tfstate/azure-aks.tfstate
3. Technologies Used
Microsoft Azure
Azure Kubernetes Service (AKS)
Azure Container Registry (ACR)
Azure Virtual Network
Azure Storage
Terraform
Docker
Kubernetes
Azure DevOps
GitHub
Azure CLI
kubectl
4. Repository Structure
azure-aks-terraform-devops/
|
├── app/
│   ├── Dockerfile
│   └── index.html
|
├── k8s/
│   ├── deployment.yml
│   └── service.yml
|
├── pipelines/
│   ├── terraform-plan.yml
│   ├── terraform-apply.yml
│   └── app-ci-cd.yml
|
├── terraform/
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
|
├── terraform-bootstrap/
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── version.tf
|
└── .gitignore

.terraform/, Terraform state files, and real terraform.tfvars files must not be committed to Git.

5. Prerequisites

Install the following if you want to work with the project locally:

Azure CLI
az version
Terraform
terraform version
kubectl
kubectl version --client
Docker
docker version
Git
git --version

You also need:

An Azure subscription
A GitHub account/repository
An Azure DevOps organization/project
Permission to create Azure resources
Permission to create Azure role assignments
6. Azure Authentication

Login to Azure:

az login

Check subscriptions:

az account list -o table

Select the required subscription:

az account set --subscription "<SUBSCRIPTION_ID>"

Verify:

az account show

For local Terraform authentication using a service principal:

$env:ARM_CLIENT_ID="<CLIENT_ID>"
$env:ARM_CLIENT_SECRET="<CLIENT_SECRET>"
$env:ARM_TENANT_ID="<TENANT_ID>"
$env:ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"

Never commit the client secret to GitHub.

7. Terraform Bootstrap

The terraform-bootstrap directory creates the Azure Storage resources used as the remote Terraform backend.

Go to:

cd terraform-bootstrap

Initialize Terraform:

terraform init

Review the configuration:

terraform plan

Create the backend resources:

terraform apply

Confirm:

yes

The bootstrap Terraform state is local.

This is intentional because the bootstrap configuration creates the backend that the main Terraform configuration depends on.

8. Terraform Remote Backend

The main Terraform configuration uses Azure Blob Storage as its remote backend.

The backend is configured in:

terraform/backend.tf

The Terraform state is stored remotely, for example:

tfstate/azure-aks.tfstate

This prevents the main Terraform state from being stored inside the Git repository.

After creating or recreating the backend, go to the main Terraform directory:

cd ..\terraform

Initialize/reconfigure:

terraform init -reconfigure

If Terraform reports that the backend configuration has changed, use:

terraform init -reconfigure
9. Main Terraform Infrastructure

The main infrastructure is defined under:

terraform/

The infrastructure includes:

Resource Group
    |
    +-- VNet
    |     |
    |     +-- Subnet
    |
    +-- AKS
    |
    +-- ACR
    |
    +-- AKS -> ACR AcrPull Role Assignment

The project uses:

Resource Group: azure-aks-rg
AKS Cluster:    azure-aks-cluster
ACR:            azureaksacr01

ACR Login Server:
azureaksacr01.azurecr.io

The Azure region is controlled through Terraform variables.

10. AKS Networking

The AKS cluster uses Azure CNI networking.

The relevant configuration is:

network_profile {
  network_plugin    = "azure"
  load_balancer_sku = "standard"
  service_cidr      = "10.10.0.0/16"
  dns_service_ip    = "10.10.0.10"
}

The VNet uses:

10.0.0.0/16

The AKS subnet uses:

10.0.1.0/24

The Kubernetes service CIDR is:

10.10.0.0/16

The service CIDR is intentionally different from the VNet and subnet ranges to avoid overlapping networks.

11. AKS Node Configuration

The default AKS node pool is configured in main.tf.

Example:

default_node_pool {
  name           = "system"
  node_count     = var.node_count
  vm_size        = var.vm_size
  vnet_subnet_id = azurerm_subnet.aks.id
}

The project uses:

VM Size: Standard_B2s_v2

The number of nodes is controlled through Terraform variables.

12. AKS and ACR Authentication

ACR administrator authentication is disabled:

admin_enabled = false

Instead, the AKS kubelet identity receives the AcrPull role:

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

This allows AKS to pull private container images from ACR without using an ACR administrator password.

13. Create Main Infrastructure Manually

From:

cd terraform

Initialize:

terraform init -reconfigure

Check formatting:

terraform fmt -check

Validate:

terraform validate

Create a plan:

terraform plan

Apply:

terraform apply

Confirm:

yes

Verify Terraform state:

terraform state list
14. Azure DevOps Setup

Create an Azure DevOps project.

Create the following service connections.

Azure Service Connection

Name:

Azure-Service-Connection

Used for:

Terraform
Azure CLI
AKS credentials
Azure resource operations
ACR Service Connection

Name:

ACR-Service-Connection

Used by the Docker task to authenticate with Azure Container Registry.

15. Terraform Plan Pipeline

Pipeline file:

pipelines/terraform-plan.yml

The pipeline triggers automatically when changes are pushed to main.

Flow:

GitHub
   |
   v
Terraform Plan Pipeline
   |
   +-- Install Terraform
   |
   +-- terraform init
   |
   +-- terraform fmt -check
   |
   +-- terraform validate
   |
   +-- terraform plan
   |
   v
Terraform Plan Artifact

The plan is saved as:

tfplan

and published as the:

terraform-plan

pipeline artifact.

16. Terraform Apply Pipeline

Pipeline file:

pipelines/terraform-apply.yml

The Apply pipeline is intentionally configured with:

trigger: none

Therefore it does not automatically apply infrastructure changes.

The flow is:

Terraform Plan
      |
      v
Review Plan
      |
      v
Manually Run Apply Pipeline
      |
      v
terraform-production Approval
      |
      v
Download Terraform Plan
      |
      v
terraform apply tfplan

This provides human approval before infrastructure changes are applied.

17. Terraform Production Environment

Create an Azure DevOps environment named:

terraform-production

Configure an approval/check if required.

The Apply pipeline uses this environment so infrastructure changes can be manually approved before deployment.

18. Terraform State Locking

Terraform uses the Azure Blob backend to lock the state during operations.

If a pipeline fails unexpectedly, a stale lock may remain.

Example:

Error acquiring the state lock
state blob is already locked

First make sure no Terraform operation is currently running.

Then from:

cd terraform

initialize the backend:

terraform init -reconfigure

If the lock is genuinely stale, use the lock ID reported by Terraform:

terraform force-unlock "<LOCK_ID>"

Do not force-unlock an active Terraform operation.

19. Application Dockerfile

The application uses Nginx.

File:

app/Dockerfile

Contents:

FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

The HTML application is:

app/index.html
20. Kubernetes Deployment

File:

k8s/deployment.yml

The application deployment uses:

replicas: 2

Example:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-aks-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: azure-aks-app
  template:
    metadata:
      labels:
        app: azure-aks-app
    spec:
      containers:
        - name: azure-aks-app
          image: azureaksacr01.azurecr.io/azure-aks-app:latest
          ports:
            - containerPort: 80

The CI/CD pipeline replaces the image with the build-specific image tag during deployment.

21. Kubernetes Service

File:

k8s/service.yml

The application uses:

type: LoadBalancer

Example:

apiVersion: v1
kind: Service
metadata:
  name: azure-aks-app
spec:
  type: LoadBalancer
  selector:
    app: azure-aks-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

Azure provisions a public LoadBalancer endpoint for the application.

22. Application CI/CD Pipeline

Pipeline file:

pipelines/app-ci-cd.yml

This pipeline triggers automatically when changes are pushed to main.

Flow:

GitHub
   |
   v
Build
   |
   +-- Docker Build
   |
   +-- Docker Push
   |
   v
Azure Container Registry
   |
   v
Deploy
   |
   +-- Get AKS Credentials
   |
   +-- kubectl apply deployment.yml
   |
   +-- kubectl apply service.yml
   |
   +-- kubectl set image
   |
   +-- kubectl rollout status
   |
   v
AKS
23. Docker Image Tagging

The application pipeline uses the Azure DevOps Build ID:

tag: '$(Build.BuildId)'

The resulting image looks like:

azureaksacr01.azurecr.io/azure-aks-app:<BUILD_ID>

For example:

azureaksacr01.azurecr.io/azure-aks-app:123

Using a unique build tag allows each deployment to be associated with a specific pipeline build.

24. Verify ACR

From Azure CLI:

az acr show `
  --name azureaksacr01 `
  --resource-group azure-aks-rg `
  --query loginServer `
  -o tsv

Expected:

azureaksacr01.azurecr.io

List repositories:

az acr repository list `
  --name azureaksacr01 `
  -o table

List image tags:

az acr repository show-tags `
  --name azureaksacr01 `
  --repository azure-aks-app `
  -o table
25. Connect to AKS

Login:

az login

Select the subscription:

az account set --subscription "<SUBSCRIPTION_ID>"

Get AKS credentials:

az aks get-credentials `
  --resource-group azure-aks-rg `
  --name azure-aks-cluster `
  --overwrite-existing

Check the current context:

kubectl config current-context
26. Verify AKS Nodes

Run:

kubectl get nodes

Example:

NAME                                STATUS   ROLES
aks-system-xxxxxxxx-vmss000000     Ready    <none>
aks-system-xxxxxxxx-vmss000001     Ready    <none>
27. Verify Pods

Run:

kubectl get pods

For more details:

kubectl get pods -o wide

Expected:

azure-aks-app-xxxxxxxxxx-xxxxx   1/1   Running
azure-aks-app-xxxxxxxxxx-xxxxx   1/1   Running
28. Verify Deployment

Run:

kubectl get deployment

Detailed information:

kubectl describe deployment azure-aks-app

Check the deployed image:

kubectl get deployment azure-aks-app `
  -o jsonpath='{.spec.template.spec.containers[0].image}'
29. Verify Service

Run:

kubectl get service azure-aks-app

Example:

NAME            TYPE           CLUSTER-IP     EXTERNAL-IP
azure-aks-app   LoadBalancer   10.x.x.x       <PUBLIC-IP>

Wait until the EXTERNAL-IP is assigned.

Then open:

http://<EXTERNAL-IP>

in a browser.

30. Manually Deploy Kubernetes Resources

If required, first authenticate to AKS:

az aks get-credentials `
  --resource-group azure-aks-rg `
  --name azure-aks-cluster `
  --overwrite-existing

Apply deployment:

kubectl apply -f k8s/deployment.yml

Apply service:

kubectl apply -f k8s/service.yml

Check:

kubectl get pods
kubectl get service
31. Changing the Number of Pods

Pods are controlled by Kubernetes, not Terraform.

Current configuration:

replicas: 2

To permanently change to four pods:

replicas: 4

Then:

git add k8s/deployment.yml
git commit -m "Scale application to four replicas"
git push

The App CI/CD pipeline will deploy the change.

You can also test scaling manually:

kubectl scale deployment azure-aks-app --replicas=4

Verify:

kubectl get pods

A manual change is not stored in Git. A later deployment can overwrite it. For permanent configuration, change the YAML and commit it.

32. Changing the Number of AKS Nodes

Nodes are infrastructure and are therefore managed by Terraform.

Change the Terraform variable:

node_count = 3

Then:

terraform plan

Review the change.

With the current Azure DevOps design:

Git Push
   |
   v
Terraform Plan automatically
   |
   v
Review
   |
   v
Manually run Terraform Apply
   |
   v
AKS node count changes

You do not need to destroy the AKS cluster to change the node count.

33. Infrastructure Changes vs Application Changes

The project separates infrastructure from application deployment.

Change	Where	Pipeline
AKS node count	Terraform	Plan → Manual Apply
AKS VM size	Terraform	Plan → Manual Apply
VNet	Terraform	Plan → Manual Apply
Subnet	Terraform	Plan → Manual Apply
AKS settings	Terraform	Plan → Manual Apply
ACR settings	Terraform	Plan → Manual Apply
Pod replicas	Kubernetes YAML	App CI/CD
Container image	Docker/App	App CI/CD
HTML application	app/index.html	App CI/CD
Service configuration	Kubernetes YAML	App CI/CD
34. Automatic vs Manual Pipelines

The current setup intentionally works this way:

                    Git Push to main
                           |
              +------------+------------+
              |                         |
              v                         v
        Terraform Plan             App CI/CD
              |                         |
           Automatic                Automatic
              |                         |
              v                         v
       Plan Artifact              Docker Build
              |                         |
              v                         v
       Manual Apply               Push to ACR
              |                         |
           Approval                    Deploy
              |                         |
              v                         v
       Azure Infrastructure             AKS

This prevents infrastructure from being automatically modified every time application code changes.

35. Destroy Infrastructure

When the environment is no longer needed, go to:

cd terraform

Review what will be deleted:

terraform plan -destroy

Then:

terraform destroy

Confirm:

yes

This removes the Terraform-managed main infrastructure.

It does not delete:

GitHub repository
Azure DevOps project
Azure DevOps pipelines
Local source code
36. Destroying the Terraform Backend

The bootstrap/backend should normally be kept if you frequently recreate the project.

If you want to remove everything, first destroy the main infrastructure:

cd terraform
terraform destroy

Only after the main infrastructure has been destroyed should you destroy the bootstrap resources:

cd ..\terraform-bootstrap
terraform destroy
Important

Deleting the backend also deletes the remote Terraform state.

Therefore:

DO NOT delete the backend while
main Terraform-managed resources still exist.

Otherwise Terraform can lose its record of existing resources.

For a temporary learning environment, deleting the backend after the main infrastructure is gone is safe.

37. Recreating the Project Later

If both the infrastructure and backend were destroyed, recreate them in this order.

Step 1: Bootstrap
cd terraform-bootstrap
terraform init
terraform apply
Step 2: Main Terraform
cd ..\terraform
terraform init -reconfigure
terraform plan

Then either:

terraform apply

or use the Azure DevOps Terraform Plan and Apply pipelines.

Step 3: Application

Run the App CI/CD pipeline.

The pipeline will:

Build Docker image
      ↓
Push to ACR
      ↓
Connect to AKS
      ↓
Deploy Kubernetes manifests
      ↓
Update image
      ↓
Wait for rollout
38. Recommended Project Lifecycle

For infrastructure changes:

1. Modify Terraform
2. Commit and push
3. Terraform Plan runs automatically
4. Review plan
5. Manually run Apply
6. Approve terraform-production
7. Infrastructure changes

For application changes:

1. Modify application
2. Commit and push
3. App CI/CD runs automatically
4. Docker image is built
5. Image pushed to ACR
6. AKS deployment updated
7. New application version becomes available
39. Troubleshooting
Terraform says the state is locked

Check whether another Terraform operation is running.

If the lock is stale:

terraform force-unlock "<LOCK_ID>"

Do not force-unlock an active operation.

Terraform backend configuration changed

Run:

terraform init -reconfigure
AKS pods are not starting

Check:

kubectl get pods

Then:

kubectl describe pod <POD_NAME>

Check logs:

kubectl logs <POD_NAME>
ImagePullBackOff

Check:

kubectl describe pod <POD_NAME>

Verify:

ACR exists
Image exists in ACR
AKS has AcrPull
Image name is correct
Image tag exists

Check the AKS-to-ACR role assignment if necessary.

Website is not accessible

Check:

kubectl get service azure-aks-app

Wait for:

EXTERNAL-IP

Also check:

kubectl get pods
kubectl get deployment

All pods should be Running and the deployment should have the desired number of available replicas.

Pipeline cannot authenticate to Azure

Verify that:

Azure-Service-Connection

exists and is authorized for the Azure DevOps pipelines.

Docker push fails

Verify the ACR login server:

az acr show `
  --name azureaksacr01 `
  --resource-group azure-aks-rg `
  --query loginServer `
  -o tsv

Expected:

azureaksacr01.azurecr.io

Also verify:

ACR-Service-Connection

has access to the registry.

40. Security Practices

Never commit:

*.tfvars
*.tfstate
.env
client secrets
passwords
API keys
private keys

The .gitignore should contain rules such as:

**/.terraform/

*.tfstate
*.tfstate.*

*.tfvars
*.tfvars.json

.env
.env.*

.vscode/

The example variable files should remain committed:

terraform.tfvars.example

Do not put real credentials inside them.

ACR administrator authentication is disabled in this project. AKS uses managed identity/RBAC for pulling images.

41. Useful Commands Cheat Sheet
Azure
az login
az account show
az account list -o table
az group list -o table
Terraform
terraform init -reconfigure
terraform fmt
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform plan -destroy
terraform destroy
terraform state list
AKS
az aks get-credentials `
  --resource-group azure-aks-rg `
  --name azure-aks-cluster `
  --overwrite-existing

kubectl get nodes
kubectl get pods
kubectl get pods -o wide
kubectl get deployment
kubectl get service
kubectl get all
Kubernetes
kubectl apply -f k8s/deployment.yml
kubectl apply -f k8s/service.yml

kubectl scale deployment azure-aks-app --replicas=4

kubectl rollout status deployment/azure-aks-app

kubectl describe deployment azure-aks-app

kubectl logs <POD_NAME>
ACR
az acr show `
  --name azureaksacr01 `
  --resource-group azure-aks-rg `
  --query loginServer `
  -o tsv

az acr repository list `
  --name azureaksacr01 `
  -o table

az acr repository show-tags `
  --name azureaksacr01 `
  --repository azure-aks-app `
  -o table
42. Complete Deployment Flow
                         GITHUB
                            |
          +-----------------+------------------+
          |                                    |
          v                                    v
   TERRAFORM CHANGES                     APP CHANGES
          |                                    |
          v                                    v
 Terraform Plan                         App CI/CD
          |                                    |
          v                                    v
   Plan Artifact                         Docker Build
          |                                    |
          v                                    v
 Manual Terraform Apply                       ACR
          |                                    |
          v                                    v
      Azure AKS                              AKS
          |                                    |
          |                              Kubernetes
          |                              Deployment
          |                                    |
          +----------------+-------------------+
                           |
                           v
                     Web Application
43. Final Infrastructure

After successful deployment, the environment contains:

Azure
│
├── Resource Group
│
├── VNet
│   └── Subnet
│
├── AKS Cluster
│   └── Node Pool
│       └── Application Pods
│
├── Azure Container Registry
│   └── azure-aks-app:<BUILD_ID>
│
└── Load Balancer
    └── Public Application Endpoint

The project demonstrates:

Infrastructure as Code using Terraform
Terraform remote state using Azure Blob Storage
Terraform Plan/Apply separation
Azure DevOps approvals
Docker containerization
Azure Container Registry
Kubernetes deployment
AKS
Automated application CI/CD
GitHub-based source control
Azure CLI and kubectl operations

The complete workflow is:

GitHub
   ↓
Azure DevOps
   ↓
Terraform Plan
   ↓
Manual Terraform Apply
   ↓
Azure Infrastructure
   ↓
Docker Build
   ↓
Azure Container Registry
   ↓
AKS
   ↓
Kubernetes
   ↓
LoadBalancer
   ↓
Web Application
