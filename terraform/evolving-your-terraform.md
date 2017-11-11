# Evolving Your Terraform

[YouTube Video]

- The -.tfstate file is a single source of truth (be careful)
- The Terralith
  - Characteristics
    - Single state file
    - Single definition file
    - Hard coded config
    - local state
  - Pain Points
    - Can't manage environments separately
    - Config not that intuitive
    - Maintenannce challenge: Duplicate Defs (Not DRY)

- Multi Terralith
  - Characteristics
    - Envs - Separate State Mgmt
    - Multiple Terraform Definitions files
    - Better use of variables
  - Pain Points
    - Manage Envs separately (solved)
    - More intuitive config (partially solved)
    - Not DRY

- Terramod - Use modules
  - Characteristics
    - Reusable modules
    - Envs compose themselves from modules
    - Restructuring of repo
  - Pain Points
    - Manage Envs separately (solved)
    - More intuitive config (solved)
    - Not DRY (partially solved)
  - Client 1
    - Three modular divisions
      1. Core
        - VPC
        - All subnets
        - Core Routing & Gateways
        - Bastion Host (OpenVPN server)
      2. K8s-cluster
        - Instances
        - Security Groups
      3. Database
        - Amazon RDS
        - DB subnet Group
    - Repo layout (https://github.com/mycompany/myproject)
      - /envs/[test|prod]
        - config.tf
        - terraform.tf
        - terraform.tfvars
        - terraform.tfstate
      - modules
        - /core
          - input.tf
          - core.tf
          - output.tf
        - /K8s-cluster
          - input.tf
          - dns.tf
          - vms.tf
          - output.tf
        - /database
    - The inputs.tf and outputs.tf define the "Contract" of the module !
    - The terraform.tf file now becomes a sort of gluing module
      - It only contains (imports) the module resources and their variable/output interpolations

- [Terramod (powered up)]
  - Nested modules
    - base modules (low level infrastructure specific)
    - logical modules (system specific)

  - Sometimes dedicated module repo
  - module divisions
      - core
          - vpc
          - all subnets
          - core routing & gateways
          - bastion host (openVPN server)
      - k8s-cluster
          - instances
          - security groups
      - database
          - amazon RDS
          - db subnet group
  - Repo layout
      - /envs/[test|prod]
        - config.tf
        - terraform.tf
        - terraform.tfvars
        - terraform.tfstate
      - modules
        - /project
            - /core
              - input.tf
              - core.tf

              ```tf
              module "vpc" {
                  source = "../../common/aws/network/vpc"
                  cidr    = "${var.vpc_cidr}"
              }

              module "dmz-subnet" {
                  source = "../../common/aws/network/pub-subnet"
                  vpc_fd = "${module.vpc.vpc_id}"
                  subnet_cidrs = [ "${var.dmz_cidr}" ]
              }

              module "priv-subnet" {
                  source = "../../common/aws/network/priv-subnet"
                  vpc_id = "${module.vpc.vpc_id}"
                  subnet_cidrs = [ "${var.priv_cidr}" ]
              }
              ```
              - output.tf
            - /K8s-cluster
              - input.tf
              - dns.tf
              - vms.tf
              - output.tf
            - /database
        - /common
          - aws
            - network
              - VPC
              - pub_subnet
              - priv_subnet
            - comps
              - instance
              - db-instance

  - Now the core modules are composed only of base modules (in the common directory)
  - Lack of a module count parameter means that for each needed instance of a sub-module.. it must be repeated in the higher level terraform file
    - See issue #953
    - Three instances needs three repeated module declarations

  - The next Pain Point...
    - Can't manage logical parts of infrastructure independently
    - solution is "Terraservices"

- [Terraservices]
  - Take logical components and manage them independently
  - Characteristics
    - independently manage logical components
      - Isolate & reduces risk
      - Aids with multi-team setups
    - Distributed (remote state)
    - Requires additional orchestration effort
  - Multiple state files
    - One per component
    - All "env/logical component" combinations have their own state file
      - For each env..
        - Core, K8s-cluster and DB have...
          - terraform.tfstate
          - terraform.tfvars
          - config.tf
          - terraform.tf

          ```tf
          # Optional but explicit! (Needs 0.9+)
          terraform {
              backend "local" {
                  path = "terraform.tfstate"
              }
          }

          module "core" {
              source = "../../modules/core"
              cidr    = "${var.vpc_cidr}"
              ...
          }
          ```
          - outputs.tf

          ```tf
          output "priv_subnet_id" {
              value = "${module.core.priv_subnet_id}"
          }
          ```

  - Repo layout
     - /envs/[test|prod]
      - /core
        - terraform.tfstate
        - terraform.tfvars
        - xxx.tf

      - /k8s-cluster
        - terraform.tfstate
        - terraform.tfvars
        - terraform.tf

        ```tf
        data "terraform_remote_state" "core" {
         backend = "s3"
         config {
           region = "eu-west-1"
           bucket = "myco/myproj/test"
           key = "core/terraform.tfstate"
           encrypt = "true"
         }
        }

        module "k8s-cluster" {
         source = "../../modules/k8s-cluster"
         num_nodes = "${var.k8s_nodes}"
         priv_subnet = "${data.terraform_remote_state.core.priv_subnet_id}"
        }
        ```

      - /database
        - terraform.tfstate
        - terraform.tfvars
        - xxx.tf

    - /modules
        - /project
            - /core
              - input.tf
              - core.tf

                  ```tf
                  module "vpc" {
                      source = "../../common/aws/network/vpc"
                      cidr    = "${var.vpc_cidr}"
                  }

                  module "dmz-subnet" {
                      source = "../../common/aws/network/pub-subnet"
                      vpc_fd = "${module.vpc.vpc_id}"
                      subnet_cidrs = [ "${var.dmz_cidr}" ]
                  }

                  module "priv-subnet" {
                      source = "../../common/aws/network/priv-subnet"
                      vpc_id = "${module.vpc.vpc_id}"
                      subnet_cidrs = [ "${var.priv_cidr}" ]
                  }
                  ```

              - output.tf

            - /K8s-cluster
              - input.tf
              - dns.tf
              - vms.tf
              - output.tf

            - /database

          - /common
            - aws
              - network
                - VPC
                - pub_subnet
                - priv_subnet

              - comps
                - instance
                - db-instance

  - Remote State Files
    - Needs "backend" declaration
      - [See: youtube video]
      - Helps with security of secrets as well
      - Ex.. backend "s3"

  - Move modules into their own repositories
    - `https://github.com/myco/`
      - /myproj-core
      - /myproj-k8s
      - /myproj-db
      - /myproj-modcommon

-   Orchestrating Terraform
  - Jenkins
  - custom scripts
  - shared services
  - READMEs


[Youtube Video]: https://youtu.be/wgzgVm7Sqlk
[Terramod (powered up)]: https://youtu.be/wgzgVm7Sqlk?t=913
[Terraservices]: https://youtu.be/wgzgVm7Sqlk?t=1224
[See: youtube video]: https://youtu.be/wgzgVm7Sqlk?t=1342
