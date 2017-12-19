# [Martin Fowler ~ Youtube](https://youtu.be/STKCRSUsyP0)
# [Martin Fowler ~ Original Article](https://martinfowler.com/articles/201701-event-driven.html)

- four patterns comprise event-driven
- events or commands ??
  - protocol types
    - events: pubsub
    - commands: rpc
  - a proper system does require both
    1. customer changes address
      - address manager fires off event
    2. insurance quoting manager is subscribed and re-quotes insurance
      - pubsub
    3. quote manager sends command to email manager
      - rpc

- "Event" is a first class object, so to speak

1. Event Notification
  - pubsub in nature
  - reverses dependencies
  - an event is a record (struct) that gets passed around and recorded
    - e.g. address change

  - pros:
    - decouples receiver from sender

  - cons:
    - no statement of overall behavior
      - requires observing event stream to figure out what the hell is
        going on across the whole system
    - may require additional traffic if only the simple event is
      published

2. Event-carried State Transfer
  - each component has a local copy of all the data it needs
    - reduces burden on network and other component databases
  - requires event publisher to provide all the info required by other
    components
  - pros:
    - decoupling
    - reduced load on supplier
    - high availability

  - cons:
    - replicated data
    - eventual consistency

3. Event Sourcing
  - provides to representations of the world (state)
    1. current state
    2. log of change of state (events)

  - current state can be rebuilt by applying "log" of all the state
    changes from the past from the "event horizon" (first state)
  - VCS is an event sourced system
  - use "snapshots" to optimize performance of rebuilding to current
    state
  - accounting ledgers is an event sourced system
  - pros:
    - audit-able
    - debugging
    - historic state
    - alternative state (branching)
    - memory image
      - no db necessarily
      - (LMAX)
        - single threaded
        - overnight snapshots
        - good hot backups
          - events provide data to multiple systems simultaneously

  - cons:
    - unfamiliar
    - external systems
      - requires saving all external call results as events
    - event schema
    - identifiers
    - asynchrony can be troublesome
    - versioning can be troublesome
      - solution is confusing see https://youtu.be/STKCRSUsyP0?t=2329

4. CQRS (command query responsibility segregation)
  - separate components that read and write to permanent store
    - query model (component)
    - command model (component)
  - be careful when to use this
  -
