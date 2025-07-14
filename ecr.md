# Terraform Plan – ECR Registry & Container Build/Push

> This document outlines the Terraform **plan** (not the full code) for building the `frontend` and `backend` containers with the [kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs) provider, publishing them to a private **Elastic Container Registry (ECR)** repository using the **AWS** provider, and doing so in a **modular** way that can be extended easily.

---

## 1  High-level Architecture

1. **Module: `ecr_docker_images`** – creates one ECR repository *per* service (frontend, backend) and builds/pushes its Docker image.
2. **Root configuration** – instantiates the module once, passing a map of services → build context.
3. **Networking / ECS** – provisioned separately (future modules). This plan only covers registry & image pipeline.

![architecture](./docs/img/ecr-build-flow.png)

---

## 2  Module Responsibilities (`modules/ecr_docker_images`)

| Responsibility | Terraform Resources (indicative) |
|----------------|----------------------------------|
|Create ECR repo | `aws_ecr_repository`, `aws_ecr_lifecycle_policy` |
|Build image     | `docker_image` (provider `docker`) |
|Tag & push      | `docker_registry_image`            |

### Resource design

* **for_each everywhere** – the module accepts `var.services` (map of objects) and iterates so that adding a service is one-line in root.
* **build tag invalidation** – a `local.build_suffix` is concatenated into the image tag so that bumping the suffix forces a new digest & push.
* **Least-privilege IAM** – future improvement (separate iam module). For now, assume TF is executed by a role with `ecr:*` & `secretsmanager:GetSecretValue`.

---

## 3  Key `locals` & Variables

```hcl
locals {
  # Bump this value to trigger a fresh docker build even if source did not change
  build_version = "1"           # <── increment manually when you need a rebuild

  # Convenience map of services – this can live in root module
  services = {
    frontend = {
      context   = "${path.root}/frontend"   # Build context path
      dockerfile = "Dockerfile"             # Relative to context
    }
    backend = {
      context   = "${path.root}/backend"
      dockerfile = "Dockerfile"
    }
  }
}
```

---

## 4  Providers

```hcl
terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws   = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "docker" {
  registry_auth {
    address  = aws_ecr_authorization_token.auth.proxy_endpoint
    username = aws_ecr_authorization_token.auth.user_name
    password = aws_ecr_authorization_token.auth.password
  }
}
```
> The `aws_ecr_authorization_token` data source makes a one-time ECR login that the docker provider re-uses.

---

## 5  Root Module Usage Example

```hcl
module "ecr_docker_images" {
  source   = "./modules/ecr_docker_images"

  aws_region = var.aws_region
  services   = local.services        # map(frontend, backend, ...)
  tag_suffix = local.build_version   # forces rebuild when incremented
}
```

---

## 6  Inside `modules/ecr_docker_images` (pseudo-code)

```hcl
variable "services" {
  type = map(object({
    context    = string
    dockerfile = string
  }))
}

variable "tag_suffix" {
  type    = string
  default = "1"
}

# ── Iterate over services ────────────────────────────
resource "aws_ecr_repository" "this" {
  for_each = var.services
  name     = each.key
  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_ecr_authorization_token" "auth" {}

resource "docker_image" "this" {
  for_each = var.services
  name         = "${aws_ecr_repository.this[each.key].repository_url}:${var.tag_suffix}"
  build {
    context    = each.value.context
    dockerfile = each.value.dockerfile
  }
}

resource "docker_registry_image" "push" {
  for_each = var.services
  name          = docker_image.this[each.key].name
  keep_remotely = true   # avoids old tag deletions
}
```

---

## 7  Best-practice Notes

1. **State** – use the *local* backend for now (no remote S3/DynamoDB). Migrate to a remote backend later when multi-user collaboration is needed.
2. **Lifecycle Policy** – add an ECR policy to retain only recent images to save space.
3. **CI/CD Integration** – run `terraform plan`/`apply` inside your pipeline after tests pass.
4. **Secrets Handling** – Docker build args should be passed via `TF_VAR_*` environment variables or from AWS Secrets Manager (future module).

---

## 8  Future Extensions

* **ECS & Fargate module** – consume the `repository_url` outputs to deploy tasks/services behind an ALB.
* **Secrets Manager module** – write-only secrets injection for backend task definition.
* **Image promotion** – introduce a second tag (`latest`) or CodePipeline for promotion flows.

---

## 9  Next Steps

1. Put the above snippets into `root/main.tf`, `modules/ecr_docker_images/*.tf`, `versions.tf`, and `variables.tf` files.
2. Run `terraform init` and `terraform plan` to verify resource graph.
3. Increment `locals.build_version` whenever you need to force a rebuild.

> *Remember:* **Never** commit state files or hard-coded credentials. Use IAM roles/OIDC in CI and remote backend for state.
