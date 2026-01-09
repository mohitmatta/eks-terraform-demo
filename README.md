# Deploying Containerized Applications on Amazon EKS (Elastic Kubernetes Service)

Welcome to **part 2** of the [Kubernetes in AWS Series](https://github.com/mohitmatta/eks-terraform-demo/blob/main/README.md) series.

This represents a **completely automated setup** for containerized microservices and web applications using **Amazon EKS (Elastic Kubernetes Service)**, facilitated by Terraform and shell scripts.

We will create and launch:

- **A microservice backed by a document database**, utilizing:  
  - **Amazon DynamoDB** for efficient, serverless NoSQL data management.

- **A Docker container** for the Flask microservice, designed for **Amazon EKS** deployment.

- **Modern container registry processes**, uploading all images to:  
  - **Amazon ECR (Elastic Container Registry)**.

- **Kubernetes tasks on Amazon EKS**, handling containerized applications at scale.

- **Kubernetes configurations** encompassing **Deployments**, **Services**, and **Ingress** for robust, scalable operations.

- **NGINX acting as a centralized Ingress controller**, directing all services via a single **AWS Load Balancer**.

## Categorizing Amazon EKS: PaaS or IaaS?

When implementing Kubernetes through **Amazon Elastic Kubernetes Service (EKS)**, a frequent inquiry emerges:

> Is EKS classified as Infrastructure as a Service (IaaS) or Platform as a Service (PaaS)?

EKS enables specification of compute and scaling parameters — suggesting IaaS. However, it manages the Kubernetes control plane, simplifies provisioning, and conceals much operational complexity — pointing to PaaS.

The most accurate view: **EKS provides a PaaS-style interface on IaaS infrastructure**. It integrates declarative APIs with AWS-native resource allocation.

---

### Managed Control Plane, Declarative Setup

With **EKS**, installation or maintenance of the Kubernetes control plane is unnecessary. AWS oversees all aspects — including:

- Control plane uptime and expansion
- Version updates and fixes
- Integrated monitoring and protection

Manual EC2 instance launches for worker nodes are avoided. Instead, node group configurations are defined, and AWS handles the compute infrastructure provisioning — through a **declarative, automated process** resembling PaaS.

---

### Autoscaling and Node Handling: IaaS Beneath the Surface

Although direct EC2 instance management is not required, EKS employs **Auto Scaling Groups (ASGs)** for worker node provisioning and scaling. You specify:

- Node group instance types and capacities  
- Minimum and maximum quantities  
- Autoscaling based on cluster metrics

AWS manages:

- VM setup and health monitoring  
- Automatic repairs and updates  
- Availability zone-aware placement

This is supported by standard IaaS, orchestrated via Kubernetes abstractions.

---

### Load Balancer Setup

EKS seamlessly integrates with AWS load balancing. Creating a Kubernetes `Service` of type `LoadBalancer` triggers automatic provisioning of an:

- **Elastic Load Balancer (ELB)** or **Application Load Balancer (ALB)**, based on annotations.

Health checks and backend configurations are handled automatically — by the Kubernetes **cloud controller manager**. This automation exemplifies PaaS: define the service, and infrastructure adapts.

---

### Tagging: The Underlying Connection

Amazon EKS extensively uses **resource tagging** for component management:

- Subnet tags indicate networks for node placement.
- EC2 instance tags assist the Kubernetes autoscaler in tracking and scaling groups.
- ELB and security group tags link resources to the cluster.

These tags are rarely manipulated directly — yet they are crucial for EKS's cloud-native, automated functioning.

---

### Final Thoughts

**Amazon EKS offers a managed Kubernetes solution that combines PaaS ease with IaaS versatility**:

- Control plane installation and management are eliminated.
- Infrastructure is defined declaratively.
- AWS handles underlying EC2-based compute.

In comparison to fully abstracted offerings like **AWS RDS** or **Managed Microsoft AD**, EKS provides a balanced approach — granting control when needed, automation otherwise.

## AWS Architecture

The **EKS setup we're constructing** features a fully managed **Amazon EKS cluster** in the `us-east-1` region.

It comprises:

- A fully managed **control plane** from AWS
- Separate **node groups**:
  - `flask-app` for the Flask microservice and payment-node nodegroup for payment application.

Inside the cluster, **pods** execute containerized apps such as `flask-app-1`.

The architecture integrates with key AWS services:

- **Amazon VPC** for secure, cloud-based networking
- **Amazon ECR** for Docker image storage and management
- **Amazon DynamoDB** for rapid, serverless NoSQL data
- An external **Elastic Load Balancer** for traffic distribution
- An **NGINX Ingress Controller** for routing to cluster services

Infrastructure is defined via **Terraform**, with application handling through `kubectl`.


![eks](./diagrams/aws-k8s.drawio.png)

This illustration depicts the AWS infrastructure supporting the EKS cluster, featuring EC2 node groups in private subnets, a Network Load Balancer for external traffic, and linked services like DynamoDB and Elastic Container Registry.

![eks-infra](./diagrams/aws-k8s-infra.drawio.png)

## Requirements

* [An AWS Account](https://aws.amazon.com/console/)
* [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 
* [Install Latest Terraform](https://developer.hashicorp.com/terraform/install)
* [Install Postman](https://www.postman.com/downloads/) for testing
* [Install Docker](https://docs.docker.com/engine/install/)

## Clone this Repository

```bash
git clone https://github.com/mohitmatta/eks-terraform-demo.git
cd eks-terraform-demo
```
## Execute the Build

Execute [check_env](check_env.sh) followed by [apply](apply.sh).

```bash
~/aws-k8s$ ./apply.sh
NOTE: Validating that required commands are found in your PATH.
NOTE: aws is found in the current PATH.
NOTE: docker is found in the current PATH.
NOTE: terraform is found in the current PATH.
NOTE: All required commands are available.
NOTE: Checking AWS cli connection.
NOTE: Successfully logged into AWS.
NOTE: Building ECR Instance.
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
[...]
```

### **Build Stages Overview**

The build is divided into four stages:

#### 1. Set Up ECR Repositories and VPC
- Establishes **Amazon Elastic Container Registry (ECR)** repositories for image storage.
- Configures the **Amazon VPC** and networking for the EKS cluster.

#### 2. Create and Upload Docker Images
- Constructs Docker images for the **Flask stock microservice** and **Payment app**.
- Uploads all images to their **ECR repositories**.

#### 3. Deploy Amazon EKS Cluster
- Launches the **Amazon EKS cluster** with two managed node groups:
  - `flask-nodes` for the Flask microservice
  - `payment-nodes` for payment containers

#### 4. Launch Applications with `kubectl`
- Links `kubectl` to the new EKS cluster.
- Deploys Kubernetes manifests:
  - [flask-app.yaml](./03-eks/yaml/flask-app.yaml.tmpl) for the microservice  
  - [games.yaml](./03-eks/yaml/games.yaml.tmpl) for game containers

## Exploring Build Results in AWS Console

![consoles](./diagrams/consoles.gif)

## API Endpoints Overview

### `/flask-app/api/gtg` (GET)
- **Function**: Health verification.
- **Output**: 
  - `{"connected": "true", "instance-id": <instance_id>}` (with `details` parameter).
  - 200 OK without content otherwise.

### `/flask-app/api/<name>` (GET)
- **Function**: Fetch candidate by name.
- **Output**: 
  - Candidate information (JSON) at status `200`.
  - `"Not Found"` at status `404` if absent.

### `/flask-app/api/<name>` (POST)
- **Function**: Add or modify candidate by name.
- **Output**: 
  - `{"CandidateName": <name>}` at status `200`.
  - `"Unable to update"` at status `500` on error.

### `/flask-app/api/candidates` (GET)
- **Function**: Retrieve all candidates.
- **Output**: 
  - Candidate list (JSON) at status `200`.
  - `"Not Found"` at status `404` if none.

### `/games/tetris` (GET)
 - **Function**: Opens JavaScript Tetris game in browser.

      ![eks](./diagrams/tetris.png)

### `/games/frogger` (GET)
 - **Function**: Opens JavaScript Frogger game in browser.

      ![eks](./diagrams/frogger.png)

### `/games/breakout` (GET)
 - **Function**: Opens JavaScript Breakout game in browser.

      ![eks](./diagrams/breakout.png)

## Kubernetes Cluster Verification and Autoscaling Demonstration

This tutorial covers verifying your Kubernetes cluster via `kubectl` and demonstrating autoscaling with a basic load test.

---

### Step 1: Verify Pod Deployments

Begin by listing pods in the default namespace:

```bash
kubectl get pods
```


---

### Step 2: Inspect Deployment Status

Confirm `Deployment` resources:

```bash
kubectl get deployments
```

---

### Step 3: Validate Ingress Configuration

Review Ingress :

```bash
kubectl get ingress
```

---

### Step 4: Review Node Status

Display cluster nodes:

```bash
kubectl get nodes
```

---

### Step 5: Generate Load with Stress Test

Deploy a demanding workload:

```bash
kubectl apply -f stress.yaml
```

⏱️ **Pause ~5 minutes** for autoscaling activation.

Re-check nodes:

```bash
kubectl get nodes
```

---

### Step 6: Remove Load Generator

Eliminate the stress workload:

```bash
kubectl delete -f stress.yaml
```

⏱️ **Pause ~5 minutes** for cluster downscaling.

Verify nodes again:

```bash
kubectl get nodes
```

---

### Recap

This validates:

- Pod and deployment readiness
- Ingress setup
- Node availability and autoscaler functionality





