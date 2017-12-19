
Istio provides and easy way to create a network of deployed services

# Components and Considerations

- Load Balancing
- S2S and E2E Auth
- Monitoring
- Service Discovery
- Failure Recovery
- Metrics collection and reporting
- Intelligent Routing
    - A/B testing
    - Canary releases
    - etc
- Resiliency
    - timeouts
    - retries
    - circuit breakers
    - etc
- Rate limiting
- Access Control
- Attributes
- Mixer
- Pilot
- Policy Application is extensible
    - API calls within the service mesh
    - resources which are not necessarily expressed at API 
        - quota to amount of CPU consumed
    - maintained as a distinct service with its own API 
        - allows services to directly integrate with it as needed
- Istio assumes
    - a service registry
        - keep track of the pods/VMs of a service
    - new instances of a service are automatically registered with the SR
    - unhealthy instances are automatically removed
        - kubernetes (builtin)
        - See solutions for VM based apps
- Service discovery
    - Pilot 
        - consumes info from the service registry
        - provides platform-agnostic service discovery interface
        - dynamically updates load-balancing pools accordingly
    - services access each other using DNS names
    - all http traffic bound to a service is automatically re-routed through Envoy
    - Envoy distributes traffic across instances in the LB pool
- Load balancing modes
    - round robin
    - random
    - weighted least request
- Health checks
    - Envoy follows a circuit breaker style pattern to classify instances as unhealthy or healthy
        - based on failure rates for the health check API call
    - automatic ejection of unhealthy pods from the LB pool
    - Services can actively shed load by responding with HTTP 503 to a health check
        - the service instance will be immediately removed from the caller's LB pool

# Mixer

- A platform independent component
    - Usage policy
    - Access Control
    - Telemetry Data
- Flexible plugin model
    - enables interfacing with variety of host envs and infrastructure backends
    - abstracts istio managed services from above bullet's details
- Uses "Mixer Configuration"
    - DSL to control how API calls and L4 traffic flow across various services
    - configure service level properties such as 
        - circuit breakers
        - timeouts
        - retries
        - common continuous deployment tasks
            - canary deployments
            - A/B testing
            - staged rollouts (% based)
    - example: simple rule to send 100% of incoming traffic for a "reviews" service to 
      "v1" can be described using the Rules DSL as follows:
        ```yaml
        apiVersion: config.istio.io/v1alpha2
        kind: RouteRule
        metadata:
            name: reviews-default
        spec:
            destination:
                name: reviews
            route:
            - labels:
                version: v1
             weight: 100
         ```
    - "destination" is the name of the service
    - "labels" identify specific service instances
        - e.g. ...kubernetes... only pods with the label "v1" will recieve traffic
- 3 kinds of traffic management rules in istio
    - Route Rules
    - Destination Policies (not the same as mixer policies)
    - Egress Rules

# Pilot

- Service Discovery
- Abstracts platform specific SD mechanisms 

# Data Plane

- Composed of a set of intelligent proxies (Envoy) deployed as sidecars that mediate and control network communication between microservices

# Control Plane

- Responsible for managing and configuring proxies to route traffic and enforcing policies at runtime

# Envoy

- Mediates all inbound and outbound traffic for all services in the service mesh
- Dynamic service discovery
- load balancing
- tls termination
- http/2 & grpc proxying
- circuit 
- health checks
- staged rollouts w/ % based traffic split
- fault injection
- rich metrics
- extracts signals about traffic behavior (requests, etc) that istio calls "attributes"
    - Used in "mixer" to 
        - enforce policy decisions
        - send to monitoring systems to provide information about the behavior of 
          the mesh

# Istio-Auth

- Provides strong S2S and E2E auth
- Uses mutual TLS
- Built in identity and credential management
- Can be used to upgrade unencrypted traffic in the mesh
- Enables enforcement of policy based on service identity rather than network controls
- Future releases will add fine grained access control and auditing to control and monitor who accesses:
    - a service
    - api
    - resource
- access control:
    - attributes
    - RBAC
    - Auth hooks

# Attributes

- Important notion
- A central mechanism for how policies and control are applied to services within the mesh
