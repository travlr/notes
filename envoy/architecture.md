# Design Goals

- code is modular.. slightly does hinder performance though


# Terminology

**Host:**
- an entity capable of network com
  - app on mobile phone
  - server
  - etc

- is a logical network app
- a physical hardware could have multiple hosts on it
  - but, ea must be independently addressed


**Downstream (DS)**
- req/rep centric
- sends req receives rep


**Upstream (US)**
- req/rep centric
- receives connections and reqs from envoy and returns reps


**Listener**
- a named network location
  - port
  - unix domain socket
  - etc

- can be connected to by DS clients
- envoy exposes these for DS hosts to connect to


**Cluster**
- a group of logically similar upstream hosts that envoy connects to
- US services are discovered via SD
- optionally uses HC on these group members
- LB req routing is determined by the LB policy


**Mesh**
- a group of hosts that coordinate to provide a consistent network topology
- a group of envoy proxies that form a msg passing substrate for a
  distributed system comprised of many different services and app platforms


**Runtime Configuration**
- out-of-band, real-time config system deployed alongside envoy
- config settings affect ops w/out needing to
  - restart envoy
  - affect primary config


# Threading Model
- envoy uses single process with multiple threads
- a single 'master' thread controls various sporadic coordination tasks
- a number of 'worker' threads perform:
  - listening
  - filtering
  - forwarding

- after listener accepts connection it is then bound to a single worker
  thread for the rest of its lifetime
  - allows the majority of envoy to be largely single threaded
    (embarrassingly parallel)
  - small amount of complex code handling coord between worker threads

- envoy is written to generally be 100% non-blocking
  - for most workloads, config num worker threads to equal num hardware
    threads

# Listeners

- envoy supports any number of listeners within a single process
- one envoy per machine
  - easier operation
  - single source for stats
- currently, envoy only supports TCP listeners
- ea is configured independently
  - with some num of network level (L3/L4) filters

- new listener connections trigger the 'configured connection local filter
  stack' to..
  - be init'd
  - begin processing subsequent events
- this generic listener arch is used to perform the vast majority of
  different proxy tasks the envoy is used for:
  - rate limiting
  - TLS client auth
  - http connection mgmt
  - MongoDB sniffing
  - raw TCP proxy
  - etc

- listeners can also be fetched dynamically via the 'listener discovery
  service (LDS)'


# Network (L3/L4) Filters

- form the core of envoy connection handling
- filter API allows
  - different sets of filters to be mixed and matched
  - attached to a given listener

- three types of network filters:
  - **Read:**
    - invoked when envoy receives data from a downstream connection

  - **Write:**
    - invoked when envoy is about to send data to a downstream connection

  - **Read/Write:**
    - invoked both when
      - envoy receives data from a downstream connection
      - envoy is about to send data to a downstream connection

- the API is relatively simple since the filters operate on
  - raw bytes
  - a small number of connection events
    - TLS handshake
    - connection disconnect either locally or remotely
    - etc

- filters in the chain can stop and subsequently continue iteration to
  further filters
  - allows for more complex scenarios
    - calling a 'rate limiting' service

- see below and 'configuration reference' for already implemented filters


# HTTP Connection Management (HCM)

- network level filter called 'HTTP Connection Manager'
  - translates raw bytes into:
    - http level messages
    - events
      - headers received
      - body data received
      - trailers received
      - etc

  - also handles
    - access logging
    - req ID
      - generation
      - tracing

    - req/rep header manipulation
    - route table mgmt
    - statistics

- See HCM configuration


# HTTP Protocols

- 'http connection manager' native support for:
  - http/1.1
  - http/2
  - websockets

- envoy designed first and foremost for http/2
- internally envoy describes system components with http/2 terminology
  - e.g.. http req/rep take place on a stream
    - a codec API is used to translate wire protocols to protocol agnostic
      forms for:
      - streams
      - req
      - rep
      - etc
    - http/1.1 codec translates the serial/pipelining capabilities into
      something that looks like http/2 to higher layers
  - the majority of code does not need to understand whether a stream
    originated on an http/1.1 or http/2 connection


# HTTP Header Sanitizing

- the HCM performs various header sanitizing actions for security purposes


# Route Table Configuration

- ea HCM filter has an associated route table (RT)
- the RT can be specified either..
  - statically
  - dynamically via the 'RDS API'


# HTTP Filters

- envoy has an http filter stack like it has a network level filter stack
- supported in the HCM
- filters can be written that operate on http level messages
  - underlying protocol is abstracted away
    - http/1.1
    - http/2

  - multiplexing character abstracted away

- three types
  - **Decoder:**
    - invoked when the HCM is decoding parts of the req stream
      - headers
      - body
      - trailers

  - **Encoder:**
    - invoked when the HCM is about to encode parts of the rep stream
      - headers
      - body
      - trailers

  - **Decoder/Encoder:**
    - invoked both when HCM is..
      - decoding parts of the req stream
      - about to encode parts of the rep stream

- the API does not require knowledge of the underlying protocol
- like network filters, http filters can stop and continue iteration to
  subsequent filters
  - allows for more complex scenarios
    - health checking
    - calling a rate limiting service
    - buffering
    - routing
    - generating stats for app traffic
      - DynamoDB
      - etc

- see already implemented filters below and in the config reference


# HTTP Routing

- HTTP routing filter
  - can be installed to perform advanced routing tasks
  - useful for:
    - edge traffic
    - building a s2s envoy mesh (istio)
      - typically via routing on the host/authority HTTP header to reach
        a particular upstream service cluster

- envoy also can be a forwarding proxy
  - mesh clients can participate by appropriately configuring their http
    proxy to be an envoy
  - at a higher level, the router takes the http req..
    - matches it to an upstream cluster
    - acquires a 'connection pool'
    - forwards the req

- the router filter supports the following:
  - virtual hosts that map domains/authorities to a set of routing rules
  - prefix and exact path matching rules both case sensitive/insensitive
    - regex/slug matching currently not supported
      - makes it difficult to determine conflicts
      - not recommended at the reverse proxy level
      - may be supported eventually depending on demand

  - tls redirection at the virtual host level
  - path/host redirection at the route level
  - explicit host rewriting
  - automatic host rewriting
    - based on dns name of selected upstream host
  - prefix rewriting
  - websocket upgrades at route level
  - request retries specified either via..
    - http header
    - route config

  - req timeout via..
    - http header
    - route config

  - traffic shifting from one upstream cluster to another via 'runtime
    values' (see 'traffic shifting/splitting')
  - arbitrary header matching routing rules
  - virtual cluster specs
    - specified at the virt host level
    - used by envoy to generate additional stats ontop of std cluster level
      ones
    - virt clusters can use regex matching

  - priority based routing
  - hash policy based routing
  - absolute urls for not-tls forward proxies


## Route Table (RT)

- the config for the HCM owns the RT that is used by all config'd http  
  filters
- the RT's main consumer is the RT filter, but is also used by other filters
  - e.g.
    - the rate limit filter consults the RT to determine if the 'global rate
      limit service' should be called based on the route

***TO BE CONTINUED***
