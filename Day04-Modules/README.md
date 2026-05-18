Here is the step-by-step implementation guide for **Day 04: Modularity & Reusability**.
Note: There are a few errors in the code which I (unlike the previous days) have not corrected in the notes below. This gives you a learning opportunity if you wish to try and correct it. Otherswise if you want the correct code, the same can be found in the github https://github.com/dockrphage/terraform-local-lab/tree/main/Day04-Modules 

In professional Terraform, you never keep all your code in one giant file. You break logic into **Modules** (reusable building blocks). This allows you to use the same "Web Server" code in Dev, Staging, and Production without copy-pasting.

### **📂 Folder Structure**
Create a new folder named `Day04-Modules`.
Inside, create this structure:

```text
Day04-Modules/
├── main.tf              # Root configuration (calls the module)
├── variables.tf         # Root variables
├── outputs.tf           # Root outputs
└── modules/
    └── docker-service/  # The module folder
        ├── main.tf      # The reusable logic
        ├── variables.tf # The module's inputs
        └── outputs.tf   # The module's outputs
```

---

### **Step 1: Create the Module (The "Building Block")**
First, we create the reusable component. This module will be responsible for spinning up a **single** Docker container.

Create the folder `modules/docker-service` and add these three files.

#### **File: `modules/docker-service/variables.tf`**
Define what the module needs to run.
```hcl
# modules/docker-service/variables.tf

variable "name" {
  description = "The name of the container"
  type        = string
}

variable "image" {
  description = "The Docker image to use"
  type        = string
}

variable "port" {
  description = "The port to expose (0 if none)"
  type        = number
  default     = 0
}

variable "command" {
  description = "Optional command to run (e.g., sleep for alpine)"
  type        = string
  default     = null
}
```

#### **File: `modules/docker-service/main.tf`**
The logic. Note that we **do not** need `terraform` or `provider` blocks here if the root calls them, but for a standalone module, it's good practice to rely on the root's provider configuration (which is automatic).

```hcl
# modules/docker-service/main.tf

# We need a unique ID for the container name to avoid conflicts if re-run
resource "random_id" "id" {
  byte_length = 4
}

resource "docker_container" "service" {
  name  = "${var.name}-mod-${random_id.id.hex}"
  image = var.image

  ports {
    count    = var.port > 0 ? 1 : 0
    internal = var.port
    external = var.port
  }

  # Handle commands (like sleep for alpine)
  command = var.command != null ? [var.command] : null
  
  restart = "unless-stopped"
}
```

#### **File: `modules/docker-service/outputs.tf`**
What should the root configuration know about this module?
```hcl
# modules/docker-service/outputs.tf

output "container_id" {
  value = docker_container.service.id
}

output "container_ip" {
  value = docker_container.service.ip_address
}

output "container_name" {
  value = docker_container.service.name
}
```

---

### **Step 2: The Root Configuration (The "Caller")**
Now, we use the module in our main `Day04-Modules` folder. We will deploy **two** different services using the **same** module code.

#### **File: `main.tf`**
```hcl
# Day04-Modules/main.tf

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

# We need a random ID for the module naming prefix
resource "random_id" "prefix" {
  byte_length = 4
}

# --- Module 1: Nginx Web Server ---
module "web_server" {
  source = "./modules/docker-service"

  name  = "web"
  image = "nginx:latest"
  port  = 80
}

# --- Module 2: Redis Cache ---
module "cache_server" {
  source = "./modules/docker-service"

  name  = "redis"
  image = "redis:alpine"
  port  = 6379
}

# --- Module 3: Alpine (Worker) ---
module "worker" {
  source = "./modules/docker-service"

  name    = "worker"
  image   = "alpine:latest"
  port    = 0
  command = "sleep 3600"
}
```

**Key Takeaway:**
Notice how clean `main.tf` is? We didn't write a single `resource "docker_container"`. We just called `module "web_server"`, `module "cache_server"`, etc. If we want to change how a container is created (e.g., add a restart policy), we only change it in **one place** (`modules/docker-service/main.tf`), and it updates everywhere.

#### **File: `outputs.tf` (Root)**
Let's gather the outputs from the modules.
```hcl
# Day04-Modules/outputs.tf

output "web_ip" {
  description = "IP of the web server"
  value       = module.web_server.container_ip
}

output "redis_ip" {
  description = "IP of the redis server"
  value       = module.cache_server.container_ip
}

output "all_names" {
  description = "Names of all containers"
  value = [
    module.web_server.container_name,
    module.cache_server.container_name,
    module.worker.container_name
  ]
}
```

---

### **Step 3: Run & Verify**

Open your terminal in `Day04-Modules`.

#### **1. Initialize**
```bash
terraform init
```
*Notice:* You will see a message like `Downloading modules...`. Terraform scanned the `./modules/docker-service` folder and downloaded it (locally).

#### **2. Plan**
```bash
terraform plan
```
**👀 What to look for:**
You will see three blocks of `+ create` actions:
*   `module.web_server...`
*   `module.cache_server...`
*   `module.worker...`

#### **3. Apply**
```bash
terraform apply
```
Type `yes`.

#### **4. Verify**
1.  **Check Docker:**
    ```bash
    docker ps
    ```
    You should see 3 containers: `web-mod-xxxx`, `redis-mod-xxxx`, `worker-mod-xxxx`.
2.  **Test:**
    *   Open `http://localhost:80` (Nginx).
    *   Check if Redis is running (it's on port 6379).

---

### **Step 4: The "Refactor" Experiment (The Power of Modules)**
This is why we use modules. Let's change a global setting.

1.  Open `modules/docker-service/main.tf`.
2.  Change the `restart` policy from `"unless-stopped"` to `"always"`.
    ```hcl
    restart = "always"
    ```
3.  Run `terraform plan`.
    *   **Observation:** Terraform will say `3 to change`. It will update the restart policy for **all three** containers because they all use the same module.
4.  Run `terraform apply`.
    *   **Result:** All containers are updated instantly.

**Imagine:** If you had 50 microservices, changing the restart policy in 50 different files would be a nightmare. With modules, you change it in **one file**.

---

### **Step 5: Cleanup**
```bash
terraform destroy
```
*Type `yes`. All modules and their internal resources are destroyed.*

---

### **Summary of Day 04**
*   **Module:** A folder containing Terraform code that can be reused.
*   **`source`**: Tells the root where to find the module (e.g., `./modules/docker-service`).
*   **Encapsulation:** The root doesn't know *how* the container is built, only *what* it needs (inputs) and *what* it gets back (outputs).
*   **DRY (Don't Repeat Yourself):** Logic is written once, used many times.

---

### **Ready for Day 05?**
Next, we will move to **Week 2, Day 05: Conditional Logic**. We will learn how to conditionally deploy resources (e.g., "Deploy Prometheus ONLY if `env = 'prod'`"). This introduces `count` and `conditions` in a modular way.

