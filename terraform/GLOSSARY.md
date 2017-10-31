- MODULE:
    - Self-contained packages of terraform configuarations that are managed as a group.
    - Are reusable components
    - Improve organization
    - Treat pieces of infrastructure as a black box
    - The module block is very similar to a Resource block
    - The "Root module" is the current working directory when `$ terraform apply` or `$ terraform get` are run
    - The `$ terraform get` command must be called to download the modules prior to `$ terraform plan`
        - Does not check for updates.. can be called multiple times without adverse affect
            - For updates use the `--update` flag
    - FIelds:
        - source:
            - The only mandatory field
            - labels where the module can be found
            - automatically downloaded by terraform and managed
            - variety of sources include:
                - Git
                - Mercurial
                - HTTP
                - file paths
        - others.. : 
            - parameters ...fill them in with the proper values
    - `
        module "assets_bucket" {
            source = "./publish_bucket"
            name  = "assets"
        }
        
        module "media_bucket" {
            source = "./publish_bucket"
            name  = "media"
        }
      `
        - Shown above are two instances of the "publish_bucket" module.. 
        - They have instance names of "assets_bucket" and "media_bucket"
        - Resource names in the module get prefixed by `module.<module-instance-name> when
          instantiated
            - Example:
                - "publish_bucket creates" "aws_s3_bucket.the_bucket" and 
                  "aws_iam_access_key.deploy_user"
                - The full name of them are then...
                    - "module.assets_bucket.aws_s3_bucket.the_bucket"
                    - "module.assets_bucket.aws_iam_access_key.deploy_user"
    - Terraform Registry
        - Lists official modules for download
        - Has a versioning feature
    - See the "module sources" documentation for a list of all sources supported
        - Local file paths
        - Terraform Registry
        - Github
        - Bitbucket
        - Generic Git/Mercurial Repos
        - HTTP urls
        - S3 buckets
    - Parameters such as "servers" map directly to variables
        - Any data type including maps and lists
    - A resource in one module cannot directly depend on resources or attributes in other
      modules, unless those are exported through outputs
    - Using module outputs via the command line requires the module name before the variable:
        - `$ terraform output -module=consul server_availability_zone`
        
- OUTPUTS:
    - Resources and Modules utilize outputs
    - See the module code or reference to see what it outputs
    - To reference a variable that is available from a module, create an output block like this:
            `
            output "consul_address" {
                value = "${module.consul.server_address}"
            `
    - Syntax: `${module.NAME.ATTRIBUTE}`

- PROVIDER:
    - Responsible for creating and managing resources.
    
- PROVISIONER: 
    - Responsible for image initialization or software provisioning steps.

- REGISTRY:
    - Repository of community provided modules
    - See examples of how terraform configurations are written
    - Find pre-made modules for infrastructure components your project requires
    - Non-registry modules do not support versioning, documentation generation and more
    - Contains both verified and non-verified modules
    - Usage in the "source" field example:
        - namespace/name/provider ... "hashicorp/consul/aws"
    - Versioning
        - Each module in the registry is versioned
        - They follow "semantic versioning"
        - <0.11 terraform only supports downloading the latest version
    - Publishing modules
        - Support 
            - versioning
            - automated document generation
            - version history browsing
            - examples
            - README
            - ..more
        - Managed by Git and Github
            - Once published, new versions are released by simply pushing a properly formed tag
        - No manual annotations are needed for publishing
            - All aspects are extracted and auto-generated on the site
        - Must be a Github repo
        - The repo name must be in the form: "terraform-PROVIDER-NAME"
            - Provider is the primary provider associated with the module
            - Name is a unique name for the module
                - may contain hyphens
                    - "terraform-aws-consul"
                    - "terraform-google-vault"
        - The Github repo description is used to populate the short description of the module
        - Must adhere to the "standard module structure"
        - Releases are detected by creating and pushing tags
            - must be a semantic version
            - can be prefixed with a "v"
            - examples
                - "v1.0.4"
                - "0.9.2"
        - Initial publication requires a tag

- RESOURCE:
    - Physical component.. e.g. Machine instance
    - Logical component.. e.g. Heroku application

- RESOURCE SCHEDULERS:

  Terraform is not limited to physical providers like AWS,GCP or Digital Ocean, but also cluster schedulers like Kubernetes, etc can also be provisioned.

- TERRAFORM:

  Provides a flexible abstraction of resources and providers.

  - Physical Hardware
  - Virtual Machines
  - Containers
  - Email providers
  - DNS providers 

- GRAPH:
    - Use to display a graph of the dependencies
    - `$ terraform graph`
    - Use the `-module-depth` parameter to limit the graph
    
- TAINT:
    - Use to taint specific resources within a module
    - `$ terraform taint -module=salt_master aws_instance.salt_master
    - It is currently not possible to taint an entire module
