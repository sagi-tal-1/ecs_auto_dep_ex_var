Steps to Deploy:

1. Download the .tgz file or git clone



2 .Clone the repository to your local machine using git clone <repository_url>.
Navigate into the cloned repository:

--AWS Configuration:

Make sure AWS CLI is configured on your system. You can configure it using:

aws configure

*** You need the AWS Access Key and Secret Access Key with sufficient permissions (listed below).


Run Terraform Commands:

Initialize Terraform:

terraform init

terraform plan

terraform apply


-- testing : 


*copy alb_dns_name from Outputs or application_url  and you shuld see 
"message":"Hello from container instance #{container:DockerId}" 



Terraform Output:


Outputs:

alb_dns_name: (This value will be known after applying the Terraform configuration. This is the DNS name of the AWS Application Load Balancer (ALB)).
application_url: (This value will be known after applying. This is the URL to access the deployed application).
container_name: my-container-nginx (The name of the container running NGINX in the ECS task).
container_names:
nginx: my-container-nginx (Name of the NGINX container).
nodejs: my-container-nodejs (Name of the Node.js container).
debug_ecs_service:
service_id: (This value will be known after applying).
service_name: ECS-s-node (Name of the ECS service running the Node.js container).
instance_ips: (This value will be known after applying. IP addresses of instances in the ECS cluster).
key_file_path: (This value will be known after applying. The path to the SSH key file for accessing the instances).
key_name: (This value will be known after applying. The name of the SSH key used for the EC2 instances).
module_path: . (Path to the current module, which is the root module in this case).
rendered_user_data: (This value is sensitive and not shown. It may contain user-data for EC2 instances).
selected_ecs_optimized_ami_id: ami-0ec3e36ea5ad3df41 (The ECS-optimized AMI ID used for the EC2 instances).
ssh_commands: (These will be known after applying. Commands to SSH into the instances).
task_definition_container_name_for_nginx: my-container-nginx (The name of the container in the ECS task definition for NGINX).






********************
Minimum IAM Permissions for Running This Terraform:
Role Management:

iam:CreateRole
iam:DeleteRole
iam:AttachRolePolicy
iam:DetachRolePolicy
iam:GetRole
iam:PassRole
Policy Management:

iam:CreatePolicy
iam:DeletePolicy
iam:PutRolePolicy
iam:DeleteRolePolicy
iam:GetPolicy
iam:GetPolicyVersion
iam:CreatePolicyVersion
iam:DeletePolicyVersion
Instance Profile Management:

iam:CreateInstanceProfile
iam:DeleteInstanceProfile
iam:AddRoleToInstanceProfile
iam:RemoveRoleFromInstanceProfile
iam:GetInstanceProfile
