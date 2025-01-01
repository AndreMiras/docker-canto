ARG VERSION=8.1.3
ARG GO_VERSION=1.21
FROM golang:${GO_VERSION}-alpine AS buildenv

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

RUN git clone --depth 1 --branch v$VERSION https://github.com/Canto-Network/Canto.git Canto-$VERSION && \
    cd Canto-$VERSION && \
    make && \
    cd /app

FROM alpine:3

ARG VERSION
ENV VERSION=$VERSION

COPY --from=buildenv /app/Canto-${VERSION}/build/cantod /tmp/cantod

RUN install -m 0755 -o root -g root -t /usr/local/bin /tmp/cantod && \
    rm /tmp/cantod

ENTRYPOINT ["cantod"]
CMD ["start"]
