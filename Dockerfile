ARG VERSION=8.1.3
ARG GO_VERSION=1.21
FROM golang:${GO_VERSION}-alpine AS buildenv

ARG BRANCH
ARG VERSION

# Set up dependencies
RUN apk add --update --no-cache \
    binutils-gold \
    eudev-dev \
    gcc \
    git \
    libc-dev \
    linux-headers \
    make

# Set working directory for the build
WORKDIR /app

# When BRANCH is set (e.g. thomas/archive-patch), clone by branch without
# shallow depth. Otherwise clone the version tag with --depth 1.
RUN if [ -n "$BRANCH" ]; then \
        git clone --branch "$BRANCH" https://github.com/Canto-Network/Canto.git Canto-$VERSION; \
    else \
        git clone --depth 1 --branch v$VERSION https://github.com/Canto-Network/Canto.git Canto-$VERSION; \
    fi && \
    cd Canto-$VERSION && \
    make

# Download envsubst for runtime config templating (used by managed target)
FROM alpine:3 AS tools

RUN wget -q https://github.com/a8m/envsubst/releases/download/v1.4.2/envsubst-$(uname -s)-$(if [ "$(uname -m)" = "aarch64" ]; then echo "arm64"; else uname -m; fi) -O /tmp/envsubst

# --- Stock image: just the cantod binary on Alpine ---
FROM alpine:3 AS stock

ARG VERSION
ENV VERSION=$VERSION

COPY --from=buildenv /app/Canto-${VERSION}/build/cantod /tmp/cantod

RUN install -m 0755 -o root -g root -t /usr/local/bin /tmp/cantod && \
    rm /tmp/cantod

ENV CANTOD_HOME=/root/.cantod
WORKDIR /root

STOPSIGNAL SIGINT

ENTRYPOINT ["cantod"]
CMD ["start", "--home", "/root/.cantod"]

# --- Managed image: config templating, auto-init, env-var driven ---
FROM stock AS managed

RUN apk add --update --no-cache jq

COPY --from=tools /tmp/envsubst /tmp/envsubst

RUN install -m 0755 -o root -g root -t /usr/local/bin /tmp/envsubst && \
    rm /tmp/envsubst

COPY config/docker-entrypoint.sh /
COPY config/docker-entrypoint.d/ /docker-entrypoint.d/
COPY config/root/ /root/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["cantod", "start", "--home", "/root/.cantod", "--x-crisis-skip-assert-invariants"]
