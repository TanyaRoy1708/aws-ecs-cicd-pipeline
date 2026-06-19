# Jenkins & SonarQube Setup Guide

This guide details the setup process for Jenkins and SonarQube on the EC2 instance provisioned by Terraform.

> **Steps 1–3 (Docker, SonarQube, Jenkins installation) are fully automated** via the EC2 `user_data` bootstrap script ([user-data.sh](file:///d:/projects-github/aws-ecs-cicd-pipeline/terraform/modules/jenkins/user-data.sh)). After `terraform apply`, wait ~3 minutes for the instance to boot and the script to complete, then proceed directly to Step 4 below.
>
> You can verify the bootstrap completed by SSH-ing in and checking:
> ```bash
> ssh -i /path/to/key.pem ubuntu@<EC2_PUBLIC_IP>
> tail -f /var/log/user-data.log   # Should show "script completed"
> ```

---


## Step 4: Configure SonarQube via GUI

1. **Access SonarQube UI**:
   Open a browser to `http://<EC2_PUBLIC_IP>:9000` (ensure security groups allow inbound port `9000`).
2. **Login & Reset Password**:
   * Default Username: `admin`
   * Default Password: `admin`
   * Set a new secure password.
3. **Create the Project**:
   * Go to **Create Project** -> **Manually**.
   * Project Key & Display Name: `devops-toolbox`
   * Click **Set Up**.
4. **Generate Global Token**:
   * Go to **My Account** -> **Security** (click the user icon in the top right).
   - Generate a token of type **Global Token**. Save this token securely.
5. **Create Webhook to Jenkins**:
   * Go to **Administration** -> **Configuration** -> **Webhooks** -> **Create**.
   * Name: `Jenkins Webhook`
   * URL: `http://localhost:8080/sonarqube-webhook/` (use `localhost` since they share the same host)

---

## Step 5: Configure Jenkins UI & Integration

1. **Unlock Jenkins**:
   * Retrieve the initial admin password from the host terminal:
     ```bash
     sudo cat /var/lib/jenkins/secrets/initialAdminPassword
     ```
   * Navigate to `http://<EC2_PUBLIC_IP>:8080` (ensure security groups allow inbound port `8080`).
   * Paste the key and choose **Install Suggested Plugins**.
2. **Install Extra Plugins**:
   * Navigate to **Manage Jenkins** -> **Plugins** -> **Available Plugins**.
   * Find and install:
     * `SonarQube Scanner`
     * `Docker Pipeline`
     * `Pipeline: Shared Groovy Libraries`
   * Select "Restart Jenkins when installation is complete".
3. **Configure SonarQube Credentials**:
   * Go to **Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials (unrestricted)** -> **Add Credentials**.
   * Kind: `Secret text`
   - Secret: *[Paste the SonarQube Global Token generated in Step 4]*
   - ID: `sonarqube-token`
4. **Configure SonarQube Server Connection**:
   * Go to **Manage Jenkins** -> **System**.
   * Scroll to **SonarQube installations**.
   * Click **Add SonarQube**:
     * Name: `SonarQube`
     * Server URL: `http://localhost:9000`
     * Server authentication token: select `sonarqube-token`
5. **Create the CI/CD Pipeline Job**:
   * Click **New Item** on the Jenkins homepage.
   * Name: `devops-toolbox`, choose **Pipeline**, click **OK**.
   * Scroll down to the **Pipeline** configuration block:
     * Definition: `Pipeline script from SCM`
     * SCM: `Git`
     * Repository URL: *[Your Git repository URL]*
     * Branch Specifier: `*/main`
     * Script Path: `Jenkinsfile`
   * Click **Save**.
