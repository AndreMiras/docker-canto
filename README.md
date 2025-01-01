# Docker Canto

[![Docker](https://github.com/AndreMiras/docker-canto/actions/workflows/build.yml/badge.svg)](https://github.com/AndreMiras/docker-canto/actions/workflows/build.yml)

Canto images for all versions.

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
docker run --volume $(pwd)/data:/root/.cantod/data andremiras/canto
```

Or build from it:

```dockerfile
FROM andremiras/canto
RUN apk add vim
```
