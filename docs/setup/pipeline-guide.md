# Jenkins CI/CD Pipeline Guide

This document explains the design, stages, and quality gates defined in the pipeline.

---

## Shared Library Configuration in Jenkins

The pipeline references a shared library via `@Library('my-shared-library') _`. To configure this in Jenkins:

1. Navigate to **Manage Jenkins** -> **System**.
2. Scroll to the **Global Pipeline Libraries** section.
3. Click **Add**:
   - Name: `my-shared-library`
   - Default Version: `main` (or the branch you want to pull)
   - Retrieval Method: **Modern SCM** (select Git)
   - Project Repository: *[Your Git repository URL]*
4. Click **Save**.

Now, when a job runs, Jenkins will automatically pull the custom Groovy steps under `jenkins/shared-library/vars/` and make them available to your pipeline.

---

## Pipeline Stages Overview

Each step in the pipeline runs inside an isolated, ephemeral Docker container agent to avoid package version pollution and dependency conflicts on the Jenkins host.

```
+---------------+      +---------------+      +---------------+      +----------------------+
|  Checkout     | ---> |  Secret Scan  | ---> |  Lint Check   | ---> |  IaC Static Analysis |
|  (Controller) |      |  (Gitleaks)   |      |   (Ruff)      |      |      (Checkov)       |
+---------------+      +---------------+      +---------------+      +----------------------+
                                                                                |
                                                                                v
+----------------------+      +---------------+      +------------------+       |
|  SonarQube Quality   | <--- |  Unit Tests   | <--- |    Terraform     | <-----+
|      Gate (SAST)     |      |   (Pytest)    |      |  Format/Validate |
+----------------------+      +---------------+      +------------------+
          |
          v
+----------------------+      +---------------+      +------------------+
|   Trivy Dependency   | ---> | Docker Build  | ---> |   Trivy Image    |
|      Scan (FS)       |      | (Local Agent) |      |    Scan (OS)     |
+----------------------+      +---------------+      +------------------+
                                                              |
                                                              v
                              +---------------+      +------------------+
                              |  Slack Alert  | <--- |  ECS Deployment  | <--- ECR Push
                              +---------------+      +------------------+
```

### 1. Checkout
* **Agent**: Runs on the controller node.
* **Logic**: Standard checkout from SCM to pull the source code.

### 2. Secret Scan
* **Agent**: `zricethezav/gitleaks:latest`
* **Logic**: Scans the codebase for exposed private keys, tokens, or credentials. It is configured to run with `softFail: true` in development, but will fail the pipeline if critical leaks are merged.

### 3. Lint Check
* **Agent**: `python:3.11-slim`
* **Logic**: Installs `ruff` and checks code compliance and style rules in the `/app` directory.

### 4. IaC Scan
* **Agent**: `bridgecrew/checkov:latest`
* **Logic**: Statically scans the `/terraform` files against 1000+ security policies. 

### 5. Terraform Format & Validation
* **Agent**: `hashicorp/terraform:latest`
* **Logic**: 
  - `terraform fmt -check` ensures code styling is standardized.
  - `terraform init -backend=false` initializes Terraform without credentials.
  - `terraform validate` verifies semantic and syntactic correctness of modules.

### 6. Unit Tests
* **Agent**: `python:3.11-slim`
* **Logic**: Installs application dependencies (`app/requirements.txt`) and runs unit tests via `pytest`.

### 7. SonarQube Quality Gate
* **Agent**: `sonarsource/sonar-scanner-cli:latest`
* **Logic**: 
  - Runs SAST (Static Application Security Testing) scan on the `/app` Python source.
  - Submits results to the SonarQube server.
  - Triggers `waitForQualityGate` to poll the webhook and **fails the build** if the Quality Gate status is not `PASSED`.

### 8. Trivy Dependency Scan (FS Scan)
* **Agent**: `aquasec/trivy:latest`
* **Logic**: Statically analyzes the project directory (filesystem) to scan for vulnerable libraries and dependencies. Runs with `--exit-code 1` on `CRITICAL` severity to block the pipeline if critical vulnerability alerts are generated.

### 9. Docker Build
* **Agent**: `docker:24-cli` with mapped host docker socket.
* **Logic**: Builds the Docker container and tags the build with an immutable identifier: `${BUILD_NUMBER}-${GIT_COMMIT[0..6]}`.

### 10. Trivy Image Scan
* **Agent**: `aquasec/trivy:latest`
* **Logic**: Performs an OS-layer vulnerability scan of the newly built Docker image. Blocks ECR push if `CRITICAL` vulnerabilities are detected.

### 11. Push to ECR
* **Agent**: `amazon/aws-cli:latest` with mapped host docker socket.
* **Logic**: Log into AWS ECR using instance profile credentials, tags the image with the registry path, and pushes the immutable image tag to the registry.

### 12. Deploy to ECS
* **Agent**: `amazon/aws-cli:latest`
* **Logic**: Fetches the active ECS Task Definition, updates the container image to the new immutable tag, registers the new task revision, updates the service, and polls using `aws ecs wait services-stable` until the rolling update stabilizes.

---

## Post-Build Notifications

The pipeline uses the **Slack Notification Plugin** to send alerts to a `#ci-cd-alerts` channel:
- **On Success**: Sends a green-colored card with the job name, build number, and build status.
- **On Failure**: Sends a red-colored card with link details to the failing build.
