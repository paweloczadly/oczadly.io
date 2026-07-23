FROM alpine:3.24 AS hugo

ARG HUGO_VERSION=0.147.0
ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64|arm64) ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    apk add --no-cache ca-certificates curl; \
    curl --fail --location \
        --output /tmp/hugo.tar.gz \
        "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz"; \
    tar --extract --gzip \
        --file /tmp/hugo.tar.gz \
        --directory /usr/local/bin \
        hugo

FROM gcr.io/distroless/cc-debian13:nonroot

COPY --from=hugo /usr/local/bin/hugo /usr/local/bin/hugo

WORKDIR /src

EXPOSE 1313

ENTRYPOINT ["/usr/local/bin/hugo"]
