# GCP Docker Infrastructure with Terraform & Ansible

This project automates the provisioning of a Google Cloud Platform (GCP) Compute Engine instance using **Terraform** and deploys a Dockerized Nginx application using **Ansible**.

## Features

- **Infrastructure**: Provisions a GCP VM instance with a specific persistent boot disk.
- **Security**: Configures a distinct Service Account and Firewall rules to allow HTTP/HTTPS access.
- **Configuration**: Installs Docker Engine and a sample Nginx container using Ansible.
- **Automation**: Includes a helper script (`setup.sh`) to handle authentication, Terraform commands, and output validation.

## Prerequisites

Before running this project, ensure you have the following installed:

- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- **SSH Key**: The project expects an SSH key at `~/.ssh/ansible_ed25519`.
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/ansible_ed25519 -C "ansible"
  ```

## Configuration

The main configuration is located in `main.tf`. You **must** update the `locals` block to match your environment:

```hcl
locals {
  project_id       = "<project-id>"                # <--- REPLACE with your GCP Project ID
  network          = "default"                # Your VPC network Name
  image            = "ubuntu-2404-noble..."   # VM Image
  ssh_user         = "ansible"                # SSH Username
  private_key_path = "~/.ssh/ansible_rsa" # Path to your private key
  # ...
}
```

## Usage

### Option 1: Quick Start (Recommended)

Use the provided setup script to handle authentication and deployment:

```bash
./setup.sh
```

This script will:

1.  Check for required tools (`gcloud`, `terraform`).
2.  Authenticate with GCP (if not already logged in).
3.  Initialize and validate Terraform configuration.
4.  Plan and apply the infrastructure.
5.  Trigger the Ansible playbook (via `local-exec` provisioner) to install Docker and Nginx.

### Option 2: Manual Deployment

If you prefer to run commands manually:

1.  **Authenticate**:

    ```bash
    gcloud auth application-default login
    ```

2.  **Initialize Terraform**:

    ```bash
    terraform init
    ```

3.  **Apply Infrastructure**:

    ```bash
    terraform apply
    ```

    _This will automatically trigger the Ansible playbook provisioner upon successful VM creation._

4.  **Access the Application**:
    After deployment, Terraform will output the public IP URL:
    ```bash
    terraform output docker_ip
    ```
    Open the URL in your browser to see the "Welcome to nginx!" page.

## Project Structure

- **`main.tf`**: The core Terraform configuration. Defines the Provider, Service Account, Firewall, and Compute Instance. It uses a `local-exec` provisioner to call Ansible.
- **`docker.yaml`**: The Ansible playbook that applies the `docker` role.
- **`roles/docker/`**: Ansible role that:
  - Installs Docker Engine.
  - Starts the Docker service.
  - Pulls and runs an Nginx container.
- **`setup.sh`**: Helper script for easy deployment.

## Cleanup

To destroy the created infrastructure and avoid costs:

```bash
terraform destroy
```
