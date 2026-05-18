Note: The code in the README may have quite a few errors which are interntionally left as is; you may use this as a learning opportunity or clone the updated code, from github https://github.com/dockrphage/terraform-local-lab.git

Here is the step-by-step implementation guide for **Day 06: Setting up a Kind Cluster with Terraform**.


This is a major milestone. We are moving from managing single containers to managing a full **Kubernetes Cluster**.

**Important Note:** Terraform does not have a native "Kind" resource. Kind is a CLI tool. To bridge this, we will use the **`null_resource`** with a **`local-exec`** provisioner. This tells Terraform: "Run this specific shell command on your machine to create the cluster."

### **📂 Prerequisites Check**
Before starting, ensure you have these installed:
1.  **Docker Desktop** (Running).
2.  **Kind CLI**: `brew install kind` (Mac) or `choco install kind` (Windows) or download from [kind.sigs.k8s.io](https://kind.sigs.k8s.io).
3.  **kubectl**: `brew install kubectl` (Required to interact with the cluster later).
4.  **Terraform**.

---

### **📂 Folder Structure**
Create a new folder named `Day06_Setting-up-Kind-Cluster`.
Inside, create:
1.  `main.tf`
2.  `variables.tf`
3.  `outputs.tf`

---

### **Step 1: Define Variables (`variables.tf`)**
We will make the cluster name and the number of worker nodes configurable.

**Copy this into `variables.tf`:**
```hcl
# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "terraform-lab"
}

variable "nodes" {
  description = "Number of worker nodes (control plane is always 1)"
  type        = number
  default     = 2
}

variable "kubernetes_version" {
  description = "K8s version (e.g., v1.28.0)"
  type        = string
  default     = "v1.28.0"
}
```

---

### **Step 2: The Cluster Logic (`main.tf`)**
We will use a `null_resource` to run the `kind create cluster` command. We also need a `local-exec` provisioner to `destroy` the cluster when you run `terraform destroy`.

**Copy this into `main.tf`:**
```hcl
# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# 1. Generate a unique ID for this run (helps avoid naming conflicts if you run multiple times)
resource "random_id" "cluster_id" {
  byte_length = 4
}

# 2. The "Create" Logic
resource "null_resource" "kind_cluster" {
  # Trigger recreation if vars change
  triggers = {
    cluster_name = var.cluster_name
    nodes        = var.nodes
    k8s_version  = var.kubernetes_version
  }

  # --- CREATE ---
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Kind cluster: ${var.cluster_name}-${random_id.cluster_id.hex}..."
      # Create a config file dynamically
      cat <<EOF > kind-config.yaml
      kind: Cluster
      apiVersion: kind.x-k8s.io/v1alpha4
      nodes:
      - role: control-plane
      ${join("\n", [for i in range(var.nodes) : "- role: worker"])}
      EOF
      
      kind create cluster --name ${var.cluster_name}-${random_id.cluster_id.hex} --config kind-config.yaml --image kindest/node:${var.kubernetes_version}
      echo "Cluster created successfully!"
    EOT
  }

  # --- DESTROY ---
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Destroying Kind cluster: ${var.cluster_name}-${random_id.cluster_id.hex}..."
      kind delete cluster --name ${var.cluster_name}-${random_id.cluster_id.hex}
      rm -f kind-config.yaml
      echo "Cluster destroyed."
    EOT
  }
}

# 3. Wait for kubectl to be ready (Optional but good practice)
# This ensures the cluster context is loaded before Terraform finishes
resource "null_resource" "wait_for_k8s" {
  depends_on = [null_resource.kind_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cluster to be ready..."
      # Wait for at least 30 seconds for kubeconfig to settle
      sleep 30
      kubectl cluster-info
    EOT
  }
}
```

**How it works:**
*   `null_resource`: A placeholder that doesn't create cloud resources but runs scripts.
*   `provisioner "local-exec"`: Runs a command on your **local machine** (where Terraform is running).
*   `heredoc (<<-EOT ... EOT)`: Allows us to write multi-line shell scripts directly in HCL.
*   `depends_on`: Ensures the `wait_for_k8s` script runs only *after* the cluster is created.

---

### **Step 3: Outputs (`outputs.tf`)**
We want to know the cluster name and verify the connection.

**Copy this into `outputs.tf`:**
```hcl
# outputs.tf

output "cluster_name" {
  description = "Full name of the created cluster"
  value       = "${var.cluster_name}-${random_id.cluster_id.hex}"
}

output "kubectl_context" {
  description = "The kubectl context name"
  value       = "${var.cluster_name}-${random_id.cluster_id.hex}"
}

output "nodes_info" {
  description = "List of nodes in the cluster"
  value = [for node in local.nodes : node]
}

# We need a local value to get node count (optional, but useful)
locals {
  nodes = var.nodes
}
```

---

### **Step 4: Run & Verify**

Open your terminal in `Day06-Kind-Cluster`.

#### **1. Initialize**
```bash
terraform init
```

#### **2. Plan**
```bash
terraform plan
```
*You will see `null_resource.kind_cluster` and `null_resource.wait_for_k8s` to be created.*

#### **3. Apply**
```bash
terraform apply
```
*Type `yes`.*

**👀 What happens:**
1.  Terraform runs `kind create cluster ...`.
2.  It creates a Docker container acting as the K8s control plane.
3.  It creates `N` worker nodes (containers).
4.  It waits 30 seconds.
5.  It runs `kubectl cluster-info`.
6.  **Output:** You will see the cluster name and context.

#### **4. Verify with kubectl**
In a **new** terminal window (or after the apply finishes), run:
```bash
kubectl cluster-info --context=kind-${var.cluster_name}-${random_id.cluster_id.hex}
```
*Note: If you don't know the exact ID, just run `kubectl config get-contexts` to find the `kind-<name>` context.*

Then check the nodes:
```bash
kubectl get nodes
```
**Expected Output:**
```text
NAME                        STATUS   ROLES           AGE   VERSION
terraform-lab-xxxx-control-plane   Ready    control-plane   2m    v1.28.0
terraform-lab-xxxx-worker          Ready    <none>          2m    v1.28.0
terraform-lab-xxxx-worker2         Ready    <none>          2m    v1.28.0
```
*(Assuming default `nodes = 2`)*

---

### **Step 5: The "Change" Experiment**
Let's scale the cluster.

1.  Open `variables.tf`.
2.  Change `nodes` from `2` to `3`.
3.  Run `terraform plan`.
    *   **Observation:** Terraform will see that the `triggers` changed. It will plan to **destroy** the old cluster and **create** a new one with 3 workers.
    *   *Note:* Kind clusters are usually "immutable" in this setup. Terraform destroys the old one and builds a new one because the cluster name (with the random ID) changes or the config changes.
4.  Run `terraform apply`.
    *   Watch the logs: It deletes the old cluster and creates the new one.

---

### **Step 6: Cleanup**
This is the most important part of IaC.

```bash
terraform destroy
```
*Type `yes`.*

**👀 What happens:**
*   Terraform runs the `when = destroy` provisioner.
*   It executes `kind delete cluster --name <name>`.
*   It removes the Docker containers.
*   It cleans up the `kind-config.yaml` file.

Verify with `docker ps`. The Kind nodes should be gone.

---

### **Summary of Day 06**
*   **`null_resource`**: Used to run scripts when no native resource exists.
*   **`local-exec`**: Runs commands on your local machine.
*   **`triggers`**: Forces recreation when configuration changes.
*   **Idempotency**: Terraform ensures the cluster exists in the state you defined.

---

