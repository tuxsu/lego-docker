FROM alpine AS s6-overlay-builder

ARG TARGETARCH
WORKDIR /tmp

RUN apk add --no-cache curl tar xz

RUN set -eux; \
    case "$TARGETARCH" in \
      amd64)    S6_ARCH=x86_64 ;; \
      arm64)    S6_ARCH=aarch64 ;; \
      arm)      S6_ARCH=armhf ;; \
	  ppc64le)  S6_ARCH=powerpc64le ;; \
	  s390x)    S6_ARCH=s390x ;; \
      *)        S6_ARCH="$TARGETARCH" ;; \
    esac; \
	URL=https://github.com/just-containers/s6-overlay/releases/latest/download; \
    mkdir /s6-install; \
    for pkg in noarch ${S6_ARCH} symlinks-noarch symlinks-arch; do \
        curl -fsSL -O "$URL/s6-overlay-${pkg}.tar.xz"; \
        tar -xJf s6-overlay-${pkg}.tar.xz -C /s6-install; \
    done

FROM --platform=$BUILDPLATFORM golang:alpine AS lego-builder

ARG TARGETARCH
WORKDIR /app

RUN apk add --no-cache git

RUN set -eux; \
    export GOOS=linux GOARCH=$TARGETARCH CGO_ENABLED=0 GO111MODULE=on; \
    if [ "$TARGETARCH" = "arm" ]; then export GOARM=7; fi; \
    go install -trimpath -ldflags="-s -w" github.com/go-acme/lego/v4/cmd/lego@latest; \
    BIN_PATH=$(go env GOPATH)/bin/${GOOS}_${GOARCH}/lego; \
    if [ -f "$BIN_PATH" ]; then mv "$BIN_PATH" /app/lego; else mv $(go env GOPATH)/bin/lego /app/lego; fi

FROM alpine

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    busybox \
	grep

COPY --from=s6-overlay-builder /s6-install/ /
COPY --from=lego-builder /app/lego /usr/bin/lego

COPY rootfs/ /
COPY docker/ /docker
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /etc/s6-overlay/s6-rc.d/init/up \
             /etc/s6-overlay/s6-rc.d/lego/run \
			 /docker-entrypoint.sh \
			 docker/shell/*.sh

# ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV cron="0 3 * * *"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
