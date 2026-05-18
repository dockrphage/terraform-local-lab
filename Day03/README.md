Here is the step-by-step guide for **Day 03: `for_each` & Collections**.

In this exercise, you will learn how to create **multiple resources** with a single block of code by iterating over a list or map. This is how you scale from "one server" to "hundreds of servers."

### **📂 Folder Setup**
Create a new folder named `Day03-For-Each`.
Inside, create these three files:
1.  `variables.tf`
2.  `main.tf`
3.  `outputs.tf`

---

### **Step 1: Define the Data ( `variables.tf` )**
Instead of hardcoding a single image, we will define a **Map** of services. A map is like a dictionary where every key (e.g., "web", "cache") has a value (image name and port).

**Copy this into `variables.tf`:**
```hcl
# variables.tf

variable "services" {
  description = "A map of services to deploy. Key = name, Value = config"
  type = map(object({
    image = string
    port  = number
  }))

  default = {
    web = {
      image = "nginx:latest"
      port  = 80
    }
    redis = {
      image = "redis:alpine"
      port  = 6379
    }
    alpine = {
      image = "alpine:latest"
      port  = 0 # Alpine doesn't expose a port by default, we'll skip mapping if 0
    }
  }
}
```
*Note: We included `alpine` which has `port = 0`. We will handle this logic in the next step.*

---

### **Step 2: The Magic of `for_each` ( `main.tf` )**
This is the core. We will use `for_each` to loop through the `var.services` map and create a container for every entry.

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

# We still need a random ID for unique naming
resource "random_id" "server_id" {
  byte_length = 4
}

# THE LOOP: Create a container for every item in var.services
resource "docker_container" "multi_service" {
  # Loop through the map: for_each = var.services
  for_each = var.services

  # Use the key (e.g., "web", "redis") for the container name
  name  = "${each.key}-terraform-${random_id.server_id.hex}"
  
  image = each.value.image
  dynamic "ports" {
    # Only map ports if the port is greater than 0 (skip alpine)
    for_each = each.value.port > 0 ? [each.value.port] : []
    content {
        internal = ports.value
        external = ports.value
        }
  }

  # Optional: Keep them running
  restart = "unless-stopped"
  
  # For alpine, run a command so it doesn't exit immediately
  command = each.key == "alpine" ? ["sleep", "3600"] : null
}
```

**Key Concepts Explained:**
*   `for_each = var.services`: Tells Terraform to run this block once for every item in the map.
*   `each.key`: The name of the service (e.g., `"web"`, `"redis"`).
*   `each.value`: The object containing `image` and `port`.
*   `count = each.value.port > 0 ? 1 : 0`: A conditional to skip port mapping for `alpine` (since it has no port).

---

### **Step 3: Output the Results ( `outputs.tf` )**
We need to see what was created. Since we have multiple containers, we will output a **Map** of their IP addresses.

**Copy this into `outputs.tf`:**
```hcl
# outputs.tf

output "deployed_services" {
  description = "List of deployed service names and their IPs"
  value = {
    for key, container in docker_container.multi_service : key => container.network_data[0].ip_address
  }
}

output "container_names" {
  description = "Full names of all containers"
  value       = [for c in docker_container.multi_service : c.name]
}
```
*Note: The `for` expression here is a **list comprehension**, which is slightly different from `for_each` but very similar. It builds a new map/list from the resources.*

---

### **Step 4: Run & Verify**

Open your terminal in the `Day03-For-Each` folder.

#### **1. Initialize**
```bash
terraform init
```

#### **2. Plan**
```bash
terraform plan
```
**👀 What to look for:**
You should see `+` signs for **3** docker containers being created:
*   `docker_container.multi_service["web"]`
*   `docker_container.multi_service["redis"]`
*   `docker_container.multi_service["alpine"]`

#### **3. Apply**
```bash
terraform apply
```
Type `yes`.

#### **4. Verify**
1.  **Check the Output:** Terraform will print the IPs of all three containers.
2.  **Check Docker:**
    ```bash
    docker ps
    ```
    You should see three containers running:
    *   `web-terraform-xxxx` (Nginx)
    *   `redis-terraform-xxxx` (Redis)
    *   `alpine-terraform-xxxx` (Sleeping)

3.  **Test Connectivity:**
    *   Open browser to `http://localhost:80` (You should see Nginx).
    *   Try to connect to Redis (if you have a Redis client) or just confirm it's running.

---

### **Step 5: The "Scale" Experiment (Homework)**
This is the power of IaC.

1.  Open `variables.tf`.
2.  Add a new service to the `default` map:
    ```hcl
    postgres = {
      image = "postgres:15"
      port  = 5432
    }
    ```
3.  Run `terraform plan`.
    *   **Observation:** Terraform sees **one** new resource to add (`postgres`). It did **not** touch the existing three.
4.  Run `terraform apply`.
    *   **Result:** PostgreSQL is up in seconds.

**Why is this better?**
In the old way (Day 1), you would have to copy-paste the `resource "docker_container"` block 4 times and rename everything. Here, you just added **2 lines** to a list, and Terraform did the rest.

---

### **Step 6: Cleanup**
```bash
terraform destroy
```
*Type `yes`. All 4 containers will be removed instantly.*

---

### **Summary of Day 03**
*   **`for_each`**: Loops through a map to create resources dynamically.
*   **`each.key` / `each.value`**: Accesses the data inside the loop.
*   **Scalability**: Adding 100 services only requires adding 100 lines to a variable list, not 100 blocks of code.

**Ready for Day 04?**
Next, we will tackle **Modularity**. We will take this loop logic and break it into a separate folder (`modules/`) so we can reuse it for different projects. This is how real-world Terraform is structured.