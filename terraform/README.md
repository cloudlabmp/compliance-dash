# Terraform Infrastructure for NIST-800 Compliance Dashboard

This directory contains the Terraform configuration for deploying the NIST-800 Compliance Dashboard application on AWS. The infrastructure is modularized to manage different components of the stack independently.

## Overview

The Terraform setup provisions the following core components:

-   **Networking (VPC)**: A dedicated Virtual Private Cloud (VPC) to host all resources securely.
-   **Kubernetes Cluster (EKS)**: A managed Kubernetes cluster to orchestrate the application containers.
-   **Container Registry (ECR)**: Private Docker container registries for the backend and frontend applications.
-   **Database Credentials**: Manages access to an existing database via AWS Secrets Manager.
-   **Application Deployments**: Kubernetes deployments for the backend and frontend services.
-   **Ingress**: An AWS Application Load Balancer (ALB) to expose the frontend and backend APIs to the internet.
-   **IAM Roles for Service Accounts (IRSA)**: Securely provides AWS permissions to Kubernetes pods.
-   **Secrets Management**: Uses AWS Secrets Manager to handle sensitive data like database credentials and API keys.

## Modules

The infrastructure is broken down into the following modules:

### `modules/vpc`

-   **Purpose**: Creates the foundational networking layer.
-   **Resources**:
    -   `aws_vpc`: The main VPC.
    -   `aws_subnet`: Public and private subnets across multiple availability zones.
    -   `aws_internet_gateway`: To provide internet access.
    -   `aws_nat_gateway`: To allow resources in private subnets to access the internet.
    -   `aws_route_table`: To control traffic routing.

### `modules/eks`

-   **Purpose**: Provisions the managed Kubernetes cluster.
-   **Resources**:
    -   `aws_eks_cluster`: The EKS control plane.
    -   `aws_eks_node_group`: The worker nodes where application pods will run.
    -   `aws_iam_role`: IAM roles for the EKS cluster and node groups.

### `modules/ecr`

-   **Purpose**: Creates private repositories to store Docker images.
-   **Resources**:
    -   `aws_ecr_repository`: One repository for the `backend` and one for the `frontend`.



### `modules/backend` & `modules/frontend`

-   **Purpose**: Deploys the application services onto the EKS cluster.
-   **Resources**:
    -   `kubernetes_deployment`: Manages the application pods.
    -   `kubernetes_service`: Exposes the application pods internally within the cluster.
    -   `kubernetes_config_map`: For application configuration.

### `modules/ingress`

-   **Purpose**: Manages external access to the application services.
-   **Resources**:
    -   `helm_release`: Installs the AWS Load Balancer Controller.
    -   `kubernetes_ingress_v1`: Defines the routing rules for the ALB, directing traffic to the `frontend` and `backend` services.
    -   `aws_iam_role` and `aws_iam_policy`: For the ALB controller's service account (using IRSA).

### `modules/irsa`

-   **Purpose**: A reusable module to create IAM Roles for Kubernetes Service Accounts.
-   **Resources**:
    -   `aws_iam_role`: An IAM role that trusts the EKS OIDC provider.
    -   `aws_iam_policy`: An IAM policy with the required permissions.
    -   `aws_iam_role_policy_attachment`: Attaches the policy to the role.
    -   `kubernetes_service_account`: The service account in Kubernetes.
    -   `kubernetes_annotations`: Links the service account to the IAM role.
