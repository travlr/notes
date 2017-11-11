# Service Account
- is a special account that can be used by services and apps running on gce
  instance to interact with other gcp apis

- is an identity an instance or app is running with
  - the identity is used id apps running on the vm instance to other gcp
    services
    - e.g:
      - write an app that reads and writes files on gcs, it must first
        authenticate to the gcs api
      - so, create a sa and grant the sa access to the gcs api
      - then, update the app code to pass the sa credentials to gcs api
      - the app authenticates seamlessly to the api without embedding any
        secret keys or user credentials in the instances, image or app code

- apps use sa credentials to
  - authorize themselves to a set of apis
  - perform actions within the permissions granted to the sa and vm instance

- firewall rules can be created to allow or deny traffic to and from instances
  based on the sa that owns the instances

- sa can be used to create instances and other resources
  - a resource created by the sa is then owned by the sa

- the sa of an existing instance can be changed

- an instance can only have one sa

- there are two types
  1. user managed
  2. google managed

## User Managed
- include new sa and gce default sa

### New Sa
- new sa that the user explicity creates
  - use google IAM
  - after sa creation..
    - grant account IAM roles
    - set up instances to run as the sa
    - apps running on the instance can use the sa to make requests to other
      google apis

### GCE Default SA (DSA)
- all projects come with the gce default sa
  - identified using an email addr:
    - [PROJECT_NUMBER]-compute@developer.gserviceaccount.com

- the dsa has the following attributes:
  1. automatically created by the gcp console project
    - the name and email address are auto generated

  2. automatically added as a project editor to the project
  3. enabled on all instances created by gcloud or the console
     - comes with a specific set of permissions.
     - can be overridden by specifying another service account
       - when creating the instance
       - when explicity disabling sa for the instance

- user has full control over this account
- user created instances from the gcp console or gcloud are automatically
  enabled to run as the dsa with the following access scopes:
  - RO access to gcs    
    (https://www.googleapis.com/auth/devstorage.read_only)
  - W access to gce logs
    (https://www.googleapis.com/auth/logging.write)
  - W access to publish metric data to gcp projects
    (https://www.googleapis.com/auth/monitoring.write)
  - RO access to service management features required for google cloud
    endpoints (alpha)
    (https://www.googleapis.com/auth/service.management.readonly)
  - RW access to service control features required for google cloud
    endpoints (alpha)
    (https://www.googleapis.com/auth/servicecontrol)

- api created instances (not gcloud or console) the dsa does not come
  enabled with the instance
  - the dsa can be enabled by explicity specifying it as part of the   
    request payload (???)

## Google Managed SA
- are created and managed by google
- assigned to the project automatically
- represent google services and each have some level of access to the project

### Google APIs SA
- all projects are enabled with a google api sa
- identified via email addr [PROJECT_NUMBER]@cloudservices.gserviceaccount.com
- runs internal google processes on "your" behalf
- the sa is owned by google
- not listed in the sa section of the console
- automatically granted project editor role
- is listed on the IAM section of the console
- is only deleted when the project is deleted
- the user can change the roles granted to this sa, including revoking access
  to the project
- certain resources rely on this sa
  - e.g:
    - managed instance groups and autoscaling use the credentials of this sa to
      create, delete and manage instances

## SA Permissions
- the level of service the sa has is determined by the combination of
  - access scopes (ASs) granted to the instance
  - IAM roles granted to the sa

- both ASs and IAM roles are needed for an instance to run as an sa
  - ASs authorize the access an instance has
  - IAM restricts that access to the roles granted to the sa

- there are many ASs
  - also just set the "cloud-platform" AS
    - authorizes access to all GCP services then limit them via IAM roles
    - https://www.googleapis.com/auth/cloud-platform
    - e.g.:
      - grant IAM roles
        - roles/compute.instanceAdmin.v1
        - roles/storage.objectViewer
        - roles/compute.networkAdmin
      - the sa only has permissions of these roles

    - e.g. 2:
        - a more restrictive scope like gcs RO scope
          - https://www.googleapis.com/auth/devstorage.read_only
          - set roles/storage.objectAdmin role
          - the instance is only able to manage gcs objects even though the
            roles/storage.ObjectAmdin role was granted
            - the gcs RO scope does not authorize the instance to manipulate
              gcs data

  - Generally, each API method doc also lists the scopes required
    - e.g.
      - instance.insert method provides a list in the "authorization" section

## Access Scopes (ASs)
- are the legecy method of specifying permissions for the instance
- before IAM, ASs were the only mechanism
- are still required for setting up an instances as an sa
- apply on a per-  basis
  - set ASs when creating and instance
  - persist only for the life of an instance

- MUST enable the respective API on the project that the SA belongs to
  - e.g.
    - grant AS for GCS on an instance
      - allows the instance to call gcs API _ONLY_IF_ the gcs API is enabled on
        the project
- example ASs include
  - https://www.googleapis.com/auth/cloud-platform
    - full access to GCP

  - https://www.googleapis.com/auth/compute
    - full control access to GCE

  - https://www.googleapis.com/auth/compute.readonly
    - RO access to gce

  - https://www.googleapis.com/auth/devstorage.read_only
    - RO access to gcs

  - https://www.googleapis.com/auth/logging.write
    - W access to GCE logs

## IAM Roles
- required
- e.g.
  - grant a SA the IAM role for GCS objects or GCS buckets or both

- are account specific
  - a granted role to a SA can be used by any instance running as that SA
- some IAM roles are in beta
  - use primitive roles if an IAM role is not available

- ASs are required as well

## Creating and Enabling SAs for Instances
- a SA is a special account whose credentials can be used in app code to
  access other gcp services

- procedure:
  1. can use IAM to create new SA
  2. then grant IAM roles
  3. then authorize an instance to run as that SA

- to create a new SA
  1. [See IAM Service Accounts Doc](https://goo.gl/gNajbJ)
    - similar to adding a member to a project
    - but, the SA belongs to the apps rather than being an end-user
    - run:
      - `gcloud iam service-accounts create my-sa-123 --display-name   
        "my-account"`
      - outputs the SA => "Created service account [my-sa-123]"

    - grant one or more roles to the SA

  2. get the sa email
    - needed to setup the instance to run as a sa
    - verify the sa email in the console
      a. go to sa page in console
      b. if prompted select project
      c look for the new sa and make note of the email
        - the email is derived from the sa id
        - e.g. [SA_NAME]@[PROJECT_ID].iam.gserviceaccount.com

  3. grant iam roles to the sa
    - [See "Understanding Roles"](https://goo.gl/gJys1m) to see a full list of
      IAM roles

  4. setup an instance to run as sa



## Setting up a New Instance to Run as a Service Account
- after creating the sa, a new instance can be run as the sa
- to assign or change a sa for an existing instance [see "Changing the SA and
Access Scopes for an Instance"](## Changing the SA and Access Scopes for an Instance)
- multiple instances can use the same sa
  - any change to the sa affects all the instances
  - includes any changes to IAM roles

- an instance can only have one sa
- provide the sa email and desired ASs when creating a new instance
- generally, just set the "cloud-platform" AS
- e.g.:

  ```BASH
  gcloud compute instances create [INSTANCE_NAME] --service-account [SERVICE_ACCOUNT_EMAIL] --scopes [SCOPES, ...]
  ```
  - [SCOPES] is a comma-separated list of full scope URIs or scope aliases
    - see [scope URIs](https://goo.gl/3ZTtDB)
    - see [scope aliases](https://goo.gl/aWt6ot)

  ```BASH
  gcloud compute instances create example-vm \
    --service-account 123-my-sa@my-project-123.iam.gserviceaccount.com \
    --scopes https://www.googleapis.com/auth/cloud-platform
  ```

  - aliases can be used for scopes instead of the full URIs (gcloud only)
    - e.g.
      - "storage-full" == https://www.googleapis.com/auth/devstorage.full_control

- after the instance is setup as the sa, the sa "credentials" can be used from
  within an instance in several ways:
  1. Use the application default credentials and a client library
    - used to easily authenticate apps
  2. Request and use access tokens directly in app
  3. Use gcloud and gsutil commands
    - automatically recognize and use the sa and enabled scopes

## Authenticating Applications with a Client Library

- client libs can use the [Application Default Credentials](https://goo.gl/YFwVqc)
  - authenticate with google apis and send requests to those apis
  - allow apps to obtain Credentials from multiple sources so an app can be
    tested locally and then deployed to gce without changing app code
    - local development.. the app can authenticate using an env var or the
      cloud sdk
    - app running on an instance.. authenticate using the sa that has been
      enabled on the instance

- e.g.
  - uses [python client lib](https://goo.gl/n0CKWT) to authenticate and make
    requests to the cloud storage api
    - list buckets in a project

  - procedure:
    1. obtain auth credentials for cloud storage api
    2. initialize cloud storage service with the build() method and creds
    3. list buckets in cs

  - [see this for python code](https://goo.gl/YFwVqc)

## Authenticating Applications Directly with Access Tokens
- some app might need to request an oauth2 access token (AT)
- does not use client library, gclud or gsutil
- there are several options for obtaining and using these ATs
  - e.g.
    - use curl to create a simple request
    - use programming lang for more flexibility

  - curl
    1. on the instance where the app runs, query the [metadata server](https://goo.gl/8yH4rL) for an AT

    ```BASH
    curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
-H "Metadata-Flavor: Google"
    ```
    returns response

    ```JSON
    {
      "access_token":"ya29.AHES6ZRN3-HlhAPya30GnW_bHSb_QtAS08i85nHq39HE3C2LTrCARA",
      "expires_in":3599,
      "token_type":"Bearer"
    }
    ```

    2. copy the value of the AT.. use it to send requests to the api
      - e.g.. print a list of instances in the project from a zone

      ```BASH
      curl https://www.googleapis.com/compute/v1/projects/[PROJECT_ID]/zones/[ZONE]/instances \
-H "Authorization":"Bearer [ACCESS_TOKEN]"
      ```

- ATs expire after a short period of time
- ATs can be requested multiple times and frequently
- There is a limit to the number of ATs per SA at a time
  - currently 600
  - reaching limit produces SERVICE_ACCOUNT_TOO_MANY_TOKENS error
  - requires deleting old tokens to create new tokens on the sa or deleting
    instances to reduce the number of distinct scope sets the sa uses

## Authenticating Tools on an Instance Using a Service Account
- some apps might use gcloud or gsutil
  - installed on some images by default
  - automatically recognize an instance sa and relevant permissions granted to
    the sa
    - therefore, no need to use `gcloud auth login`
    - make sure the IAM roles needed are set for the sa
- other tools require auth
  - via client library
  - using ATs directly in the app (see above)

## Changing the Service Account and Access Scopes for an Instance
- use cases
  - running the instance as a different identity
  - instance needs a different set of scopes to call the required apis

- e.g.
  - change AS to grant access to new API
  - change an instance so that it runs as a SA instead of default SA

- requires the instance be stopped
  - see [stopping and instance](https://goo.gl/2irOYK)
  - see [restarting the instance](https://goo.gl/G5BxM8)

- ```BASH
  gcloud compute instances set-service-account [INSTANCE_NAME] \
    [--service-account [SERVICE_ACCOUNT_EMAIL] | --no-service-account] \
    [--no-scopes | --scopes [SCOPES,...]]
  ```

- ```BASH
  gcloud compute instances set-service-account example-instance \
    --service-account my-sa-123@my-project-123.iam.gserviceaccount.com \
    --scopes compute-rw,storage-ro
  ```

## obtaining a Service Account Email
- ```BASH
  gcloud compute instances describe [INSTANCE_NAME] --format json
  ```

- ```JSON
  {
      ...
      "serviceAccounts":[
         {
            "email":"123845678986-compute@developer.gserviceaccount.com",
            "scopes":[
               "https://www.googleapis.com/auth/devstorage.full_control"
            ]
         }
      ]
      ...
   }
  ```

- if no sa is set.. the response does not have the serviceAccounts property
- make a [request to the service account api](https://goo.gl/5qwiaC)

## Using the Compute Engine Default Service Account
- Before assiging IAM roles to the CEDSA
  - granting an IAM role to the dsa affects all instances running as a dsa
  - "project editor" permissions are enabled by default
    - it must be revoked to use IAM roles

- IT IS BEST TO CREATE A NEW SA and not use the dsa
- CAUTION
  - if an existing instance is using a dsa and relys on editor access..
    - most gcp products provide IAM roles to supplement editor access
    - some products don't have IAM roles (must use project editor for now)

- to grant IAM role to dsa..
  1. go to the IAM page in the console
  2. select a project (if prompted)
  3. look for dsa accout
  4. expand the drop down menu in the "Role(s)" column
  5. remove editor access and save
  6. [grant IAM roles](https://goo.gl/p3aRND) to the sa

- to setup a new instance using dsa:
  ```BASH
  gcloud compute instances create [INSTANCE_NAME] \
       --scopes cloud-platform
  ```

## Best Practices
- each instance should run as a SA with minimum permissions necessary
  1. create new sa (not use dsa)
  2. grant iam roles to the sa only for what is needed
  3. configure instance to run as that sa
  4. grant instance the `https://www.googleapis.com/auth/cloud-platform` scope
