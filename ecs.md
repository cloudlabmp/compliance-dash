# ECS Deployment Plan for Compliance Dashboard

## Current Infrastructure Analysis

### Existing Resources (Already Deployed)
- **ECR Repositories**: Two repositories created for frontend and backend containers
- **Secrets Manager**: Two secrets configured:
  - `compliance-dash-dev-backend-aws-credentials`
  - `compliance-dash-dev-backend-openai-key`
- **Container Images**: Both frontend and backend images built and pushed to ECR with versioned tags

### Missing Infrastructure for ECS
The following resources need to be created to deploy the containers to ECS:

## ECS Deployment Architecture

### 1. Networking Infrastructure
- **VPC**: Create a dedicated VPC with public and private subnets across 2 AZs (free tier friendly)
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: Single NAT in one AZ (minimize costs, use t3.nano if needed)
- **Route Tables**: Separate routing for public and private subnets
- **Security Groups**: 
  - ALB security group (HTTP/HTTPS inbound)
  - ECS service security groups (container ports)

### 2. Application Load Balancer (ALB)
- **ALB**: Public-facing load balancer in public subnets
- **Target Groups**: 
  - Frontend target group (port 80/3000)
  - Backend target group (port 3001/8080)
- **Listeners**: 
  - HTTP listener (port 80) with routing rules
  - Optional HTTPS listener (port 443) for bonus points

### 3. ECS Infrastructure
- **ECS Cluster**: Fargate cluster for serverless container deployment
- **Task Definitions**: 
  - Frontend task definition with container specs
  - Backend task definition with container specs and secrets integration
- **ECS Services**: 
  - Frontend service with ALB integration
  - Backend service with internal load balancing
- **Service Discovery**: Enable for internal communication

### 4. IAM Security
- **Task Execution Role**: For ECS to pull images and access CloudWatch
- **Task Role**: For backend service to access Secrets Manager
- **Security Groups**: Least privilege network access

## Implementation Plan

### Phase 1: Networking Module
Create `modules/networking/` with:
- VPC with 2 public subnets, 2 private subnets
- Internet Gateway and single NAT Gateway
- Route tables and associations
- Security groups for ALB and ECS services

### Phase 2: Load Balancer Module  
Create `modules/alb/` with:
- Application Load Balancer in public subnets
- Target groups for frontend and backend
- Listeners with path-based routing
- Health checks configuration

### Phase 3: ECS Module
Create `modules/ecs/` with:
- ECS Fargate cluster
- Task definitions for both services
- ECS services with auto-scaling
- Service discovery namespace

### Phase 4: IAM Module
Create `modules/iam/` with:
- ECS task execution role
- ECS task role with Secrets Manager permissions
- Policies following least privilege principle

### Phase 5: Integration
Update `main.tf` to orchestrate all modules:
- Pass ECR image URIs from existing module
- Configure service-to-service communication
- Set up CloudWatch logging

## Container Configuration

### Frontend Service
- **Port**: 80 (internal), exposed via ALB
- **Health Check**: `/` endpoint
- **Resources**: 0.25 vCPU, 512 MB RAM (free tier)
- **Tags**: Both version-specific (`v1.0.1-YYYYMMDD-HHMM`) and `latest`

### Backend Service  
- **Port**: 3001 (internal), accessible from frontend
- **Health Check**: `/health` endpoint
- **Resources**: 0.25 vCPU, 512 MB RAM (free tier)
- **Environment Variables**: 
  - Reference to Secrets Manager ARNs
  - API endpoints configuration
- **Tags**: Both version-specific and `latest`

## Security Implementation

### Secrets Management
- Backend task role permissions to read specific secrets
- Runtime secret injection (not environment variables)
- No secrets in task definitions or terraform state

### Network Security
- Private subnets for ECS tasks
- Security groups with minimal required ports
- ALB in public subnets only

### IAM Security
- Separate roles for task execution vs. task runtime
- Least privilege permissions
- Resource-specific ARN policies

## Expected Outputs

After deployment, Terraform will output:
- **Frontend URL**: Public ALB DNS name for frontend access
- **Secret ARNs**: Names/ARNs of secrets being used
- **ECS Cluster**: Cluster name and ARN
- **Service Endpoints**: Internal service discovery endpoints

## Free Tier Considerations

- **Fargate**: 20GB-hours of compute per month (sufficient for development)
- **ALB**: 750 hours per month (always-on coverage)
- **NAT Gateway**: Minimize to single AZ, consider NAT instances for cost optimization
- **ECR**: 500MB storage included
- **Secrets Manager**: 30-day free trial, then minimal cost per secret

## Success Criteria

1.  Public user can access frontend via ALB HTTP endpoint
2.  Frontend can successfully call backend via internal routing
3.  Backend retrieves OpenAI API key from Secrets Manager at runtime
4.  All infrastructure provisioned via Terraform modules
5.  No secrets exposed in plaintext, state, or version control
6.  Both containers tagged with version and latest tags

## Next Steps

1. Create networking module with VPC and subnets
2. Create ALB module with target groups and listeners  
3. Create ECS module with cluster, tasks, and services
4. Create IAM module with required roles and policies
5. Update main.tf to integrate all modules
6. Test deployment and verify all success criteria