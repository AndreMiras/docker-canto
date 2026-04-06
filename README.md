# Docker Canto

[![Build](https://github.com/AndreMiras/docker-canto/actions/workflows/build.yml/badge.svg)](https://github.com/AndreMiras/docker-canto/actions/workflows/build.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/andremiras/canto)](https://hub.docker.com/r/andremiras/canto)

Canto images for all versions.

The image is published to both Docker Hub and GitHub Container Registry and can
be pulled from both:

```bash
docker pull andremiras/canto:latest
docker pull ghcr.io/andremiras/canto:latest
```

## Usage

Pull and use the image directly:

```sh
docker run andremiras/canto
```

Or a specific version:

```sh
docker run andremiras/canto:8.1.3
```

Persisting chain data using volumes:

```sh
docker run --env-file .env --volume $(pwd)/data:/root/.cantod/data andremiras/canto
```

Or build from it:

```dockerfile
FROM andremiras/canto
# any executable within /docker-entrypoint.d/ will get loaded
COPY ./20-extra-init.sh /docker-entrypoint.d/
RUN chmod u+x /docker-entrypoint.d/20-extra-init.sh
RUN apk add vim
```

## Runtime configuration

Most settings from the `~/.cantod/config/*.toml` files can be updated at
runtime using environment variables.
Each environment variable follows a pattern of:
`<FILENAME>_<SECTION>_<SETTING>` e.g. `CONFIG_STATESYNC_ENABLE`

For instance to state sync a node:

```
CHAIN_ID=canto_7700-1
CONFIG_STATESYNC_ENABLE=true
CONFIG_STATESYNC_RPC_SERVERS=https://canto-rpc.polkachu.com:443,https://canto-rpc.polkachu.com:443
CONFIG_P2P_SEEDS=8542cd7e6bf9d260fef543bc49e59be5a3fa9074@seed.publicnode.com:26656
```

Or to sync an archive node from scratch:

```
APP_PRUNING=nothing
CHAIN_ID=canto_7700-1
CONFIG_STATESYNC_ENABLE=false
CONFIG_STATESYNC_TRUST_HEIGHT=0
VERSION=1.0.0
```

### Docker Compose

Copy the example environment file and adjust as needed:

```sh
cp .env.example .env
```

Start the Canto node:

```sh
docker compose up
```

#### Ports and services

The default `docker compose up` exposes the following ports from the Canto node:

| Port  | Service            | Protocol |
| ----- | ------------------ | -------- |
| 1317  | Cosmos REST API    | HTTP     |
| 8545  | Ethereum JSON-RPC  | HTTP     |
| 8546  | Ethereum WebSocket | WS       |
| 9090  | Cosmos gRPC        | gRPC     |
| 9091  | Cosmos gRPC-web    | HTTP     |
| 26656 | Tendermint P2P     | TCP      |
| 26657 | Tendermint RPC     | HTTP     |

#### Traefik reverse proxy

Start with the `proxy` profile to front all RPC services behind a Traefik
reverse proxy with per-IP rate limiting (60 req/min, burst of 20):

```sh
docker compose --profile proxy up
```

Traefik listens on different host ports to avoid conflicts with the direct
Canto ports:

| Host port | Upstream    | Service                      |
| --------- | ----------- | ---------------------------- |
| 11317     | canto:1317  | Cosmos REST API              |
| 18545     | canto:8545  | Ethereum JSON-RPC            |
| 18546     | canto:8546  | Ethereum WebSocket           |
| 19091     | canto:9090  | Cosmos gRPC                  |
| 19092     | canto:9091  | Cosmos gRPC-web              |
| 36657     | canto:26657 | Tendermint RPC               |
| 8899      | —           | Traefik metrics (Prometheus) |

All Traefik host ports are configurable via environment variables
(e.g. `TRAEFIK_EVM_RPC_PORT`, `TRAEFIK_COSMOS_REST_PORT`).
The dynamic routing configuration lives in `config/etc/traefik/dynamic.yml`.

#### Monitoring

Optionally start with Prometheus and Grafana monitoring:

```sh
docker compose --profile monitoring up
```

| Port  | Service    |
| ----- | ---------- |
| 19090 | Prometheus |
| 3000  | Grafana    |

This starts Prometheus scraping Tendermint metrics from the node,
and Grafana with a pre-configured Tendermint dashboard.
The monitoring configuration lives under `config/etc/`.

Profiles can be combined:

```sh
docker compose --profile proxy --profile monitoring up
```
