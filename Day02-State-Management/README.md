---

### **Week 1, Day 2: State Management & Drift Detection**

**Goal:** Understand *why* the `terraform.tfstate` file exists, how Terraform uses it to track reality, and what happens when reality changes without Terraform's knowledge (Drift).

#### **1. The Concept**
Terraform is **declarative**. You tell it *what* you want (e.g., "I want an Nginx container"), not *how* to do it.
To know if it needs to create, update, or destroy anything, Terraform compares your **Configuration** (`main.tf`) against its **State** (`terraform.tfstate`).

*   **Configuration:** What you *want*.
*   **State:** What Terraform *thinks* currently exists.
*   **Reality:** What is actually running in Docker.

If these three don't match, things break.

---

#### **2. The Experiment: Detecting Drift**

Let's simulate a scenario where someone (you!) manually changes the infrastructure, bypassing Terraform.

**Step A: Ensure your resources are running**
If you haven't already, run the Day 1 code again:
```bash
terraform init
terraform apply
```
*Keep the terminal open.*

**Step B: Check the State File**
Open the `terraform.tfstate` file in your project folder using a text editor.
*   **Do not edit it!** Just look at it.
*   You will see a JSON file containing the IDs, names, and attributes of your Docker container and local file.
*   **Key Takeaway:** This file is the **Source of Truth**. Terraform trusts this file more than the actual cloud/docker environment.

**Step C: Introduce "Drift" (The Manual Change)**
Let's manually delete the container **without** telling Terraform.

1.  Open your terminal.
2.  Find the container ID:
    ```bash
    docker ps
    ```
3.  Stop and remove it manually:
    ```bash
    docker stop <container_name_or_id>
    docker rm <container_name_or_id>
    ```
    *(Or just `docker rm -f <id>`)*

**Step D: Let Terraform Detect the Drift**
Now, go back to your Terraform terminal and run:
```bash
terraform plan
```

**👀 What happened?**
You should see output like this:
```text
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
+ create

Terraform will perform the following actions:

  # docker_container.web_server will be created
  + id = (known after apply)
  + image = "nginx:latest"
  + name = "terraform-nginx-..."
  ...

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Why?**
*   **Configuration (`main.tf`):** Says "I want a container."
*   **State (`terraform.tfstate`):** Says "I have a container with ID `xyz`."
*   **Reality (Docker):** "No container found."
*   **Terraform's Logic:** "My state says `xyz` exists, but reality says it's gone. I must recreate it to match my state."

**Step E: Fix the Drift**
Run `terraform apply` again.
*   Terraform will see the difference, create the container again, and update its state to match the new reality.

---

#### **3. Advanced Experiment: The "Lost" Resource**

Now let's do the reverse. Let's create a resource **outside** of Terraform and see if Terraform knows about it.

1.  **Create a new container manually:**
    ```bash
    docker run -d --name manual-nginx -p 8081:80 nginx
    ```
2.  **Run `terraform plan`:**
    *   **Result:** Terraform will likely say `No changes. Your infrastructure matches the configuration.`
    *   **Why?** Because `manual-nginx` is **not** in your `terraform.tfstate` file. Terraform only manages what it created. It is "blind" to resources it didn't create.

**Challenge:** How do you bring `manual-nginx` under Terraform control?
*   *Answer:* You would use `terraform import`. (We will cover this in Week 4, Day 19).

---

#### **4. The Danger of Manual Edits**

**Scenario:** You manually change the port of the running container (e.g., via Docker Desktop or CLI).
*   Terraform doesn't know your port changed.
*   Next time you run `terraform apply`, Terraform sees the port in `main.tf` is `80`, but the running container is `8080`.
*   Terraform will **destroy** the `8080` container and **create** a new `80` container.
*   **Result:** **Downtime** and potential data loss if you weren't using persistent volumes.

**Lesson:** **Never** make changes to infrastructure managed by Terraform outside of Terraform. Always use `terraform apply`.

---

#### **5. Cleanup (The Safe Way)**

Now, let's clean up properly.
```bash
terraform destroy
```
*   Watch the output. Terraform will stop and remove the container and delete the file.
*   Verify with `docker ps`. The container should be gone.
*   Verify with `ls`. The `hello.txt` file should be gone.

---

### **Summary of Day 2**
1.  **State File (`tfstate`):** The map Terraform uses to track resources.
2.  **Drift:** When reality differs from the state (e.g., manual deletion).
3.  **Detection:** `terraform plan` compares State vs. Reality and suggests fixes.
4.  **Golden Rule:** If Terraform manages it, **only** Terraform should change it.

---

### **Your Homework for Day 2**
1.  Run `terraform apply` to create the resources.
2.  Manually edit the `hello.txt` file (change the text inside).
3.  Run `terraform plan`. Does Terraform detect the change?
    *   *Hint:* The `local_file` resource usually detects drift because it reads the file content on every plan.
4.  Run `terraform apply` to see if it "fixes" the file back to the original content.

**Next section** We will move on to `for_each` and collections to create multiple containers at once. This is where Terraform starts to feel like magic.

