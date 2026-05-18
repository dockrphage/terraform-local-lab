 **Day 1** of your Terraform learning plan. 
 This project will create a text file on your computer and spin up an Nginx web server in a Docker container.

Note: The code in the README may have one or two errors which is interntionally left as is; for updated code, refer github
https://github.com/dockrphage/terraform-local-lab.git

### **1. Project Setup**

Create a new folder on your computer (e.g., `terraform-local-lab`) and open it in your code editor (VS Code recommended).

Inside this folder, create the following files:
1.  `main.tf`
2.  `variables.tf`
3.  `outputs.tf`

---

### **2. The Code**

#### **File: `variables.tf`**
Define the inputs to make your code dynamic.

```hcl
# variables.tf

variable "container_image" {
  description = "The Docker image to run"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "The port to expose for the container"
  type        = number
  default     = 80
}

variable "local_file_content" {
  description = "Content to write to the local file"
  type        = string
  default     = "Hello from Terraform Local Lab!"
}
```

#### **File: `main.tf`**
Define the resources. Note that we are using the **Docker Provider** and the **Local Provider**.

```hcl
# main.tf

# 1. Configure the Providers
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# 2. Create a Local File
resource "local_file" "greeting" {
  filename = "${path.module}/hello.txt"
  content  = var.local_file_content
}

# 3. Start a Docker Container
# Note: The docker provider automatically uses your local Docker daemon
resource "docker_container" "web_server" {
  image = var.container_image
  name  = "terraform-nginx-${random_id.server_id.hex}"
  
  # Map the container port to the host port
  ports {
    internal = var.container_port
    external = var.container_port
  }

  # Ensure the container restarts unless explicitly stopped
  restart = "unless-stopped"
}

# 4. Generate a random ID to make container names unique
resource "random_id" "server_id" {
  byte_length = 4
}
```

*Note: You will need the `random` provider. Let's add it to the `terraform` block above:*

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

#### **File: `outputs.tf`**
Display useful information after the deployment.

```hcl
# outputs.tf

output "file_path" {
  description = "Path to the created local file"
  value       = local_file.greeting.filename
}

output "container_id" {
  description = "ID of the running Docker container"
  value       = docker_container.web_server.id
}

output "container_ip" {
  description = "IP address of the container"
  value       = docker_container.web_server.ip_address
}

output "access_url" {
  description = "URL to access the Nginx server"
  value       = "http://localhost:${var.container_port}"
}
```

---

### **3. How to Run It**

Open your terminal in the project folder and run these commands in order:

#### **Step 1: Initialize Terraform**
This downloads the necessary providers (`docker`, `local`, `random`).
```bash
terraform init
```
*You should see a success message with "Terraform has been successfully initialized!"*

#### **Step 2: Plan the Execution**
See what Terraform is about to do.
```bash
terraform plan
```
*Look for the output: `+` signs indicate resources to be created. It will show you it will create `local_file.greeting`, `docker_container.web_server`, and `random_id.server_id`.*

#### **Step 3: Apply the Changes**
Create the resources.
```bash
terraform apply
```
*Type `yes` when prompted.*

**Expected Output:**
```text
local_file.greeting: Creating...
local_file.greeting: Creation complete after 0s
docker_container.web_server: Creating...
docker_container.web_server: Creation complete after 5s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

access_url = "http://localhost:80"
container_id = "sha256:..."
container_ip = "172.17.0.2"
file_path = "./hello.txt"
```

#### **Step 4: Verify**
1.  **Check the file:** Open the `hello.txt` file in your project folder. It should say "Hello from Terraform Local Lab!".
2.  **Check Docker:** Run `docker ps` in your terminal. You should see an `nginx` container running.
3.  **Check the Web:** Open your browser and go to `http://localhost:80`. You should see the "Welcome to nginx!" page.

---

### **4. Your First Challenge (Day 1 Task)**

Now that it's running, try to **modify** the infrastructure:

1.  Open `variables.tf`.
2.  Change `local_file_content` to `"My Terraform Lab is working!"`.
3.  Change `container_port` to `8080`.
4.  Run `terraform plan` again.
5.  Run `terraform apply`.
6.  Check `hello.txt` again.
7.  Open `http://localhost:8080` in your browser.

### **5. Cleanup**

When you are done for the day, tear everything down:

```bash
terraform destroy
```
*Type `yes`. This will stop the container, remove it, and delete the `hello.txt` file.*

---
