Note: The code in the README may have quite a few errors which are interntionally left as is; you may use this as a learning opportunity or clone the updated code, from github https://github.com/dockrphage/terraform-local-lab.git

Here is the step-by-step implementation guide for **Day 07: The Kubernetes Provider**.

Now that we have a running Kind cluster (from Day 06), we will use Terraform to deploy actual Kubernetes resources (Pods, Services, Deployments) **inside** that cluster.

### **📂 Prerequisites**
1.  Ensure your **Kind Cluster** from Day 06 is running.
    *   Run: `kubectl cluster-info` to verify.
    *   If it's not running, run `terraform apply` in the `Day06-Kind-Cluster` folder first.
2.  Ensure `kubectl` is configured to talk to the cluster (it should be automatically configured by `kind create cluster`).

---

### **📂 Folder Structure**
Create a new folder named `Day07-K8s-Provider`.
Inside, create:
1.  `main.tf`
2.  `variables.tf`
3.  `outputs.tf`

---

### **Step 1: Configure the Provider (`main.tf`)**
We need to tell Terraform how to talk to Kubernetes. Since we are using a local Kind cluster, the provider will automatically pick up your local `kubeconfig` file.

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

# 1. Configure the Kubernetes Provider
# It automatically reads ~/.kube/config
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-${var.cluster_name}" # Matches the context from Day 06
}

# 2. Define the Namespace (Best Practice)
resource "kubernetes_namespace" "lab" {
  metadata {
    name = "${var.cluster_name}-lab"
  }
}

# 3. Deploy a simple Pod (Hello World)
resource "kubernetes_pod" "hello" {
  metadata {
    name      = "hello-pod"
    namespace = kubernetes_namespace.lab.metadata[0].name
    labels = {
      app = "hello-world"
    }
  }

  spec {
    container {
      name  = "hello-container"
      image = "nginx:latest"

      port {
        container_port = 80
      }
    }
  }
}

# 4. Expose the Pod with a Service (ClusterIP)
resource "kubernetes_service" "hello-svc" {
  metadata {
    name      = "hello-service"
    namespace = kubernetes_namespace.lab.metadata[0].name
  }

  spec {
    selector = {
      app = "hello-world"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP" # Default, internal only
  }
}
```

**Key Concepts:**
*   `provider "kubernetes"`: Connects to the cluster. `config_context` ensures we talk to the correct Kind cluster if you have multiple.
*   `kubernetes_namespace`: Creates a dedicated folder for our resources.
*   `kubernetes_pod`: The simplest unit. We define the container image and ports.
*   `kubernetes_service`: Exposes the pod internally. Note the `selector` matches the pod's `labels`.

---

### **Step 2: Define Variables (`variables.tf`)**
We need to know which cluster to talk to.

**Copy this into `variables.tf`:**
```hcl
# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster to target"
  type        = string
  default     = "terraform-lab" # Must match Day 06 default
}
```

---

### **Step 3: Define Outputs (`outputs.tf`)**
Let's see what we created.

**Copy this into `outputs.tf`:**
```hcl
# outputs.tf

output "namespace_name" {
  value = kubernetes_namespace.lab.metadata[0].name
}

output "pod_ip" {
  value = kubernetes_pod.hello.status[0].pod_ip
}

output "service_cluster_ip" {
  value = kubernetes_service.hello-svc.status[0].load_balancer[0].ingress[0].ip # Might be empty for ClusterIP
  # Better for ClusterIP:
  value = kubernetes_service.hello-svc.spec[0].cluster_ip
}

output "kubectl_command" {
  value = "kubectl get pods -n ${kubernetes_namespace.lab.metadata[0].name}"
}
```

---

### **Step 4: Run & Verify**

Open your terminal in `Day07-K8s-Provider`.

#### **1. Initialize**
```bash
terraform init
```
*You will see the `kubernetes` and `helm` providers downloading.*

#### **2. Plan**
```bash
terraform plan
```
**👀 What to look for:**
*   `+ kubernetes_namespace.lab`
*   `+ kubernetes_pod.hello`
*   `+ kubernetes_service.hello-svc`

#### **3. Apply**
```bash
terraform apply
```
*Type `yes`.*

**Wait for it:**
Terraform will create the namespace, then the pod (which takes a few seconds to pull the image), then the service.

#### **4. Verify with kubectl**
Run the command provided in the output:
```bash
kubectl get pods -n terraform-lab-lab
```
**Expected Output:**
```text
NAME          READY   STATUS    RESTARTS   AGE
hello-pod     1/1     Running   0          1m
```

Check the service:
```bash
kubectl get svc -n terraform-lab-lab
```
**Expected Output:**
```text
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
hello-service   ClusterIP   10.96.123.45     <none>        80/TCP    1m
```

---

### **Step 5: The "Drift" Experiment**
Kubernetes is great at self-healing. Let's see how Terraform handles it.

1.  **Delete the Pod manually:**
    ```bash
    kubectl delete pod hello-pod -n terraform-lab-lab
    ```
2.  **Run `terraform plan`:**
    *   **Observation:** Terraform will say `+ create` the pod again.
    *   *Why?* Terraform's state expects the pod to exist. It doesn't know Kubernetes auto-healed it (K8s actually recreates it immediately, but Terraform sees the name change or ID change and wants to enforce the exact definition).
3.  **Run `terraform apply`:**
    *   It will recreate the pod with a new name or update the existing one depending on how K8s handled the deletion.

---

### **Step 6: Advanced - Expose via NodePort (Optional)**
Currently, the service is `ClusterIP` (internal only). Let's expose it to your host machine.

1.  Open `main.tf`.
2.  Change the service type:
    ```hcl
    type = "NodePort"
    ```
3.  Run `terraform apply`.
4.  **Find the Port:**
    ```bash
    kubectl get svc -n terraform-lab-lab
    ```
    Look at the `PORT(S)` column. It will look like `80:30001/TCP`. The `30001` is the NodePort.
5.  **Access it:**
    Open your browser to `http://localhost:30001`. You should see the Nginx welcome page!

---

### **Step 7: Cleanup**
```bash
terraform destroy
```
*Type `yes`.*
This will delete the namespace, pod, and service.

---

### **Summary of Day 07**
*   **Kubernetes Provider**: Allows Terraform to manage K8s resources just like Docker containers.
*   **Namespaces**: Logical isolation for resources.
*   **Labels & Selectors**: How Services find Pods.
*   **ClusterIP vs NodePort**: Internal vs External access.

