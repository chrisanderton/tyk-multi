# Tyk multi-binary multi-arch image

Includes binaries for [gateway](https://github.com/TykTechnologies/tyk), [pump](https://github.com/TykTechnologies/tyk-pump), [identity broker](https://github.com/TykTechnologies/tyk-identity-broker) and [sync](https://github.com/TykTechnologies/tyk-sync).

Runs gateway by default, can run other services by overriding `entrypoint` and `command`. Example `docker-compose.yml` below. 

Probably not recommended for production use, for testing of cross-compiled binaries only. Might not include all plugin capabilities.

```version: "3.8"

services:
  tyk:
    hostname: "tyk"
    image: chrisanderton/tyk-multi:latest
    volumes: 
      - ./tyk.conf:/opt/tyk-gateway/tyk.conf
    command: ["--conf", "/opt/tyk-gateway/tyk.conf"]
    ports:
      - 8080:8080
    networks:
      - gateway
  
  tyk-redis:
    hostname: "tyk-redis"
    image: redis:6.0.4
    expose:
      - "6379"
    volumes:
      - tyk-redis-data:/data
    networks:
      - gateway

  tyk-pump:
    hostname: "tyk-pump"
    image: chrisanderton/tyk-multi:latest
    volumes:
      - ./pump.conf:/opt/tyk-pump/pump.conf
    entrypoint: /opt/tyk-pump/tyk-pump
    command: ["--conf", "/opt/tyk-pump/pump.conf"]
    ports:
      - 8083:8083
    networks:
      - gateway

volumes:
  tyk-redis-data:

networks:
  gateway:
```

## Binaries

* Gateway: `/opt/tyk-gateway/tyk`
* Pump: `/opt/tyk-pump/tyk-pump`
* Sync: `/opt/tyk-sync/tyk-sync`
* Identity broker: `/opt/tyk-identity-broker/tyk-identity-broker`
