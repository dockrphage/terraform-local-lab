Here is the step-by-step implementation guide for **Day 05: Conditional Logic**.
Note: There are a few errors in the code which I (unlike the previous days) have not corrected in the notes below. This gives you a learning opportunity if you wish to try and correct it. Otherswise if you want the correct code, the same can be found in the github

In this exercise, you will learn how to make your infrastructure dynamic. You will create a system that automatically adds or removes resources based on a variable (e.g., enabling monitoring only in "Production" or adding a firewall only if `enable_security` is true).

### **📂 Folder Structure**
Create a new folder named `Day05-Conditional`.
Inside, create:
1.  `main.tf`
2.  `variables.tf`
3.  `outputs.tf`
4.  (Optional) `terraform.tfvars` (for easy testing)

---

### **Concept: Two Ways to Condition**
1.  **`count`**: Used to create multiple copies of a resource (e.g., 0 to N).
2.  **`if` (Conditional Expressions)**: Used to include or exclude a resource entirely (e.g., 0 or 1).

We will use **`count`** today because it's the most common pattern for "Scaling up/down" or "Enabling/Disabling" features.

---

### **Step 1: Define the Configuration (`variables.tf`)**
We will define a flag to control whether we include a "Monitoring" container.

**Copy this into `variables.tf`:**
```hcl
# variables.tf

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_monitoring" {
  description = "Whether to deploy the monitoring stack (Prometheus)"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of web server replicas"
  type        = number
  default     = 1
}
```

---

### **Step 2: The Logic (`main.tf`)**
Here we use the **`count`** meta-argument to conditionally create resources.

**Copy this into `main.tf`:**
```hcl
# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_id" "env_id" {
  byte_length = 4
}

# --- Resource 1: Web Servers (Dynamic Replicas) ---
# If replica_count is 3, this creates 3 containers. If 1, it creates 1.
resource "docker_container" "web_server" {
  count = var.replica_count
  
  name  = "web-${var.environment}-${random_id.env_id.hex}-${count.index}"
  image = "nginx:latest"
  
  ports {
    internal = 80
    external = 8080 + count.index # Port 8080, 8081, etc.
  }

  restart = "unless-stopped"
}

# --- Resource 2: Monitoring (Conditional) ---
# We use a conditional expression: (var.enable_monitoring ? [1] : [])
# If true -> count = 1 (creates 1 container)
# If false -> count = [] (creates 0 containers)
resource "docker_container" "monitoring" {
  count = var.enable_monitoring ? [1] : []

  name  = "prometheus-${var.environment}-${random_id.env_id.hex}"
  image = "prom/prometheus:latest"
  
  ports {
    internal = 9090
    external = 9090
  }

  # Pass environment as an argument to the container
  command = ["--config.file=/etc/prometheus/prometheus.yml"]
  
  restart = "unless-stopped"
}

# --- Resource 3: Optional Firewall (Another Example) ---
# Let's say we only want a "firewall" container if the environment is 'prod'
resource "docker_container" "firewall" {
  # Only create if environment is "prod"
  count = var.environment == "prod" ? [1] : []

  name  = "firewall-${var.environment}-${random_id.env_id.hex}"
  image = "alpine:latest"
  command = ["sleep", "3600"]
  
  restart = "unless-stopped"
}
```

**Key Logic Explained:**
*   `count = var.replica_count`: Simple loop based on a number.
*   `count = var.enable_monitoring ? [1] : []`: This is the magic.
    *   If `true`, it evaluates to `[1]` (a list with one item) -> Creates 1 resource.
    *   If `false`, it evaluates to `[]` (an empty list) -> Creates 0 resources.
*   `count.index`: Used to give each replica a unique name (0, 1, 2...).

---

### **Step 3: Outputs (`outputs.tf`)**
We need to see what was created. Since we are using `count`, the outputs will be lists.

**Copy this into `outputs.tf`:**
```hcl
# outputs.tf

output "web_ips" {
  description = "List of IP addresses for web servers"
  value       = docker_container.web_server[*].ip_address
}

output "web_count" {
  description = "Number of web servers running"
  value       = length(docker_container.web_server)
}

output "monitoring_active" {
  description = "Is monitoring running?"
  value       = var.enable_monitoring ? "Yes" : "No"
}

output "monitoring_ip" {
  description = "IP of the monitoring container (if active)"
  value       = var.enable_monitoring ? docker_container.monitoring[0].ip_address : null
}
```

---

### **Step 4: Run & Verify (Scenario A: Dev Environment)**

#### **1. Initialize**
```bash
terraform init
```

#### **2. Apply (Default: Dev, No Monitoring)**
Since `default` in `variables.tf` sets `environment = "dev"` and `enable_monitoring = false`:
```bash
terraform apply
```
*Type `yes`.*

**👀 Observation:**
*   You should see **1** web server created.
*   You should see **0** monitoring containers.
*   You should see **0** firewall containers.
*   Output `monitoring_active` should say "No".

#### **3. Verify**
```bash
docker ps
```
You should see only the `web-dev-...` container.

---

### **Step 5: Run & Verify (Scenario B: Production with Monitoring)**

Now, let's change the variables dynamically using a command line flag (no need to edit files).

#### **1. Plan with New Values**
```bash
terraform plan \
  -var="environment=prod" \
  -var="enable_monitoring=true" \
  -var="replica_count=2"
```

**👀 Observation:**
*   Terraform will say:
    *   `+` 2 web servers (instead of 1).
    *   `+` 1 monitoring container (Prometheus).
    *   `+` 1 firewall container (Alpine).
*   It will *not* destroy the old ones immediately; it will plan to add the new ones.

#### **2. Apply New Values**
```bash
terraform apply \
  -var="environment=prod" \
  -var="enable_monitoring=true" \
  -var="replica_count=2"
```
*Type `yes`.*

**👀 Observation:**
*   Terraform will add 1 more web server.
*   Terraform will add the Prometheus container.
*   Terraform will add the Firewall container.

#### **3. Verify**
```bash
docker ps
```
You should now see:
*   2 Web servers (`web-prod-...-0`, `web-prod-...-1`).
*   1 Prometheus (`prometheus-prod-...`).
*   1 Firewall (`firewall-prod-...`).

**Open your browser:**
*   `http://localhost:8080` (First web server).
*   `http://localhost:9090` (Prometheus UI).

---

### **Step 6: The "Drift" Challenge (Advanced)**
Try to **remove** the monitoring container manually.
1.  Find the Prometheus container ID: `docker ps | grep prometheus`.
2.  Delete it: `docker rm -f <id>`.
3.  Run `terraform apply` again (with the same vars).
4.  **Result:** Terraform will detect the drift and recreate the Prometheus container automatically.

---

### **Step 7: Cleanup**
Always clean up with the variables you used to create them, or just destroy everything:
```bash
terraform destroy
```
*Type `yes`.*

---

### **Summary of Day 05**
*   **`count`**: Allows you to create N resources (e.g., 1 to 10 replicas).
*   **Conditional Expressions (`? :`)**: Allows you to create 0 or 1 resources based on logic.
*   **Dynamic Infrastructure**: You can change your entire architecture (Dev vs. Prod) just by changing variables, without touching the code.

---

### **Ready for Day 06?**
Next, we will move to **Week 3: Kubernetes with Kind**. We will set up a real Kubernetes cluster using Terraform and start managing K8s resources (Pods, Deployments, Services).
