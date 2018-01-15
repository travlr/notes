[docs v1.5](https://www.envoyproxy.io/docs/envoy/v1.5.0/)

# What is Envoy

- L7 proxy
- com bus designed for large modern SOAs
- belief:
  - network should be transparent to apps
  - when problems occur, it should be easy to determine source


## Out of Process Architecture (OOPA)

- a self-contained process designed to run alongside every app server
- all envoys form a transparent com mesh
  - ea app
    - sends/recvs messages to and from localhost
    - is unaware of network topology

- OOPA has two substantial benefits over traditional library approach to
  service to service (s2s) coms
  - works with any app lang to seamlessly form polyglot mesh
  - lib approach is painful when upgrading


## Modern C++11

- native code provides generally excellent latency properties
- better than a C native impl... developer productive and low latency


## L3/L4 Filter Architecture

- is L3/L4 proxy at its core
- has pluggable filter chain
  - allows filters be written to perform various TCP proxy tasks and inserted
    into the main server
  - filter already written:
    - raw TCP proxy
    - HTTP proxy
    - TLS CA
    - etc


## HTTP L7 Filter Architecture

- filters can be plugged into the HTTP connection mgmt subsystem
  - buffering
  - rate limiting
  - routing/forwarding
  - sniffing
  - Amazon's dynamoDB
  - etc


## First Class HTTP/2 Support

- transparent http/1 to http/2 proxy in both directions
  - clients/target servers can be bridged in any combination

- S2S config recommends http/2
  - req/rep multiplexing


## HTTP L7 Routing

- in http mode, supports a routing subsystem to:
  - route/redirect reqs
    - based on:
      - path
      - authority
      - content
      - type
      - runtime values
      - etc

    - most useful for edge proxy
    - also leveraged for S2S proxying

## gRPC Support

- built on top of http/2
- envoy routes and load balances substrate (http/2) for gRPC req/rep


## MongoDB L7 Support

- sniffing
- stats production
- logging


## DynamoDB L7 Support

- amazon's nosql key/value store
- L7 support for
  - sniffing
  - stats production


## Service Discovery (SD)

- supports multiple methods
  - asynchronous DNS resolution
  - REST based lookup via a SD service


## Health Checking (HC)

- recommended to build an envoy mesh is to treat SD as an 'eventually
  consitent process'
- optionally perform active HC of upstream service clusters
  - uses the union of the SD and HC info for LB targets

- also supports passive HC via an 'outlier detection' system


## Advanced Load Balancing (LB)

- advantageous over lib based proxy
  - configure in single location.. available to any app

- current support for:
  - automatic retries
  - circuit breaking
  - global rate limiting via external service
  - req shadowing
  - outlier detection
  - req racing (in future, supported)


## Front/Edge Proxy Support

- Envoy is mostly designed for S2S, but...
- beneficial to use same software at edge too
  - observability
  - mgmt
  - identical SD
  - LB algos
  - etc

- support for..
  - tls termination
  - http/1.1
  - http/2
  - http L7 routing


## Best in Class Observability

- envoy's primary goal is to make the network transparent
- includes robust stats support for all subsystems
- the current stats sink is 'statsd' (and compatible providers)
- other plugins are not difficult
- stats are viewable via the admin port
- also supported is distributed tracing via third-party providers


## Dynamic Configuration

- optional consumption of layered set of dynamic config apis
- use apis to build complex, centrally managed deployments if desired
