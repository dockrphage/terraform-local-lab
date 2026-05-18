Note: The code in the README may have quite a few errors which are interntionally left as is; you may use this as a learning opportunity or clone the updated code, from github https://github.com/dockrphage/terraform-local-lab.git

Here is the step-by-step implementation guide for **Day 08: The Helm Provider**.

Today, we stop writing raw Kubernetes YAML and start using **Helm Charts**. Helm is the "package manager" for Kubernetes (like `apt` or `yum` but for K8s). It allows you to install complex applications (like Prometheus, Grafana, or WordPress) with a single Terraform resource.

### **📂 Prerequisites**
1.  Ensure your **Kind Cluster** is still running from Day 06/07.
    *   `kubectl cluster-info`
2.  Ensure you have the `helm` CLI installed (optional, but helpful for debugging).
    *   `brew install helm` or `choco install kubernetes-helm`

---

### **📂 Folder Structure**
Create a new folder named `Day08-Helm-Apps`.
Inside, create:
1.  `main.tf`
2.  `variables.tf`
3.  `outputs.tf`

---

### **Step 1: Configure the Helm Provider (`main.tf`)**
We will use the `helm` provider to install the **Prometheus** monitoring stack. This will deploy 10+ containers (Server, Alertmanager, Node Exporter, etc.) automatically.

**Copy this into `main.tf`:**
```hcl
# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# 1. Provider Configuration (Same as Day 07)
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-${var.cluster_name}"
}

# 2. Add the Prometheus Community Chart Repository
# We run this as a resource so it happens before the install
resource "helm_release" "prometheus_repo" {
  name = "prometheus-community"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "" # Empty chart name, just adds the repo
  
  # We don't actually "install" a chart here, just add the repo
  # But the resource ensures the repo is available for the next resource
}

# 3. Deploy Prometheus (The Main Event)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.17.0" # Pin a specific version for stability

  # Create the namespace automatically
  namespace = "monitoring"
  create_namespace = true

  # Override default values to make it lighter for our local lab
  set {
    name  = "server.service.type"
    value = "NodePort" # Expose port 80 on the node
  }
  
  set {
    name  = "server.service.nodePort"
    value = "30090"    # Specific port for easy access
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"    # Disable disk storage for speed in local lab
  }

  # Depend on the repo resource (though usually not strictly needed if repo URL is provided directly)
  # But good practice if you split the repo addition into a separate step later
  depends_on = [helm_release.prometheus_repo]
}

# 4. Deploy Grafana (Bonus: Visualize the data)
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.0.0" # Pin version

  namespace = "monitoring"
  create_namespace = true

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "service.nodePort"
    value = "30300"
  }

  # Get the admin password from the secret (advanced output)
  set {
    name  = "adminPassword"
    value = "adminpassword"
  }
}
```

**Key Concepts:**
*   `helm_release`: The core resource. It points to a repository, a chart name, and a version.
*   `set`: Allows you to override values in the `values.yaml` of the chart without downloading the file. This is how you customize the installation.
*   `create_namespace = true`: Terraform will automatically create the `monitoring` namespace if it doesn't exist.
*   **NodePort**: We expose these internal tools so you can access them via `http://localhost:<port>`.

---

### **Step 2: Define Variables (`variables.tf`)**
We need the cluster name again.

**Copy this into `variables.tf`:**
```hcl
# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "terraform-lab"
}
```

---

### **Step 3: Define Outputs (`outputs.tf`)**
Let's get the URLs to access the dashboards.

**Copy this into `outputs.tf`:**
```hcl
# outputs.tf

output "prometheus_url" {
  description = "URL to access Prometheus UI"
  value       = "http://localhost:30090"
}

output "grafana_url" {
  description = "URL to access Grafana UI"
  value       = "http://localhost:30300"
}

output "grafana_password" {
  description = "Admin password for Grafana"
  value       = "adminpassword"
  sensitive   = true # Hides it in the output log
}
```

---

### **Step 4: Run & Verify**

Open your terminal in `Day08-Helm-Apps`.

#### **1. Initialize**
```bash
terraform init
```
*You will see the `helm` provider downloading. It may take a moment.*

#### **2. Plan**
```bash
terraform plan
```
**👀 What to look for:**
You will see a single `+` for `helm_release.prometheus` and `helm_release.grafana`.
*Wait... only 2 resources?*
Yes! Terraform is deploying **20+ Kubernetes resources** (Deployments, Services, ConfigMaps, Secrets, ServiceAccounts) with just **2 lines of code**. This is the power of Helm + Terraform.

#### **3. Apply**
```bash
terraform apply
```
*Type `yes`.*

**👀 What happens:**
1.  Terraform adds the Helm repositories.
2.  It creates the `monitoring` namespace.
3.  It downloads the Prometheus chart and deploys all its components.
4.  It does the same for Grafana.
5.  **Wait:** This might take 2-5 minutes as it pulls large Docker images.

#### **4. Verify**
Once `terraform apply` finishes, check the outputs:
```text
prometheus_url = "http://localhost:30090"
grafana_url    = "http://localhost:30300"
```

1.  **Open Prometheus:** Go to `http://localhost:30090`.
    *   You should see the Prometheus UI.
    *   Click **Status** -> **Targets**. You should see all your Kind nodes and Prometheus itself as "UP".
2.  **Open Grafana:** Go to `http://localhost:30300`.
    *   Login: `admin` / `adminpassword` (as defined in `set`).
    *   Click **Dashboards** -> **Browse**. You should see pre-built dashboards for Kubernetes.

---

### **Step 5: The "Upgrade" Experiment**
Let's simulate an application update.

1.  Open `main.tf`.
2.  Find the `helm_release.grafana` block.
3.  Change the `value` in the `set` block for `service.nodePort` from `30300` to `30301`.
    ```hcl
    set {
      name  = "service.nodePort"
      value = "30301"
    }
    ```
4.  Run `terraform plan`.
    *   **Observation:** Terraform will say `~ update` for the Grafana release. It knows exactly which value changed.
5.  Run `terraform apply`.
6.  **Verify:** Try to access `http://localhost:30300` (should fail) and `http://localhost:30301` (should work).

---

### **Step 6: Cleanup**
This is the most satisfying part.

```bash
terraform destroy
```
*Type `yes`.*

**👀 What happens:**
*   Terraform runs `helm uninstall prometheus` and `helm uninstall grafana`.
*   It deletes the `monitoring` namespace.
*   All 20+ containers created by Helm are removed instantly.

Verify with `kubectl get pods -A`. The `monitoring` namespace should be gone.

---

### **Summary of Day 08**
*   **Helm + Terraform**: The ultimate combo for deploying complex apps.
*   **`helm_release`**: Manages the entire lifecycle of a chart.
*   **`set`**: Dynamic configuration without downloading files.
*   **Abstraction**: You manage high-level "Apps," not low-level "Pods."

---

