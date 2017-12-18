# Installation

- Is a docker image
  - `docker pull drone/drone:0.8`

- Using docker-compose to install
  - Use environment variables to configure various VCS providers
  - the manifest below can be used to start the drone server on a single agent
        ```YAML
        version: '2'

        services:
          drone-server:
            image: drone/drone:0.8

            ports:
              - 80:8000
              - 9000
            volumes:
              - /var/lib/drone:/var/lib/drone/
            restart: always
            environment:
              - DRONE_OPEN=true
              - DRONE_HOST=${DRONE_HOST}
              - DRONE_GITHUB=true
              - DRONE_GITHUB_CLIENT=${DRONE_GITHUB_CLIENT}
              - DRONE_GITHUB_SECRET=${DRONE_GITHUB_SECRET}
              - DRONE_SECRET=${DRONE_SECRET}

          drone-agent:
            image: drone/agent:0.8

            command: agent
            restart: always
            depends_on:
              - drone-server
            volumes:
              - /var/run/docker.sock:/var/run/docker.sock
            environment:
              - DRONE_SERVER=drone-server:9000
              - DRONE_SECRET=${DRONE_SECRET}
        ```