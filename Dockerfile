# The binary is cross-compiled on the build platform, so only the runtime
# stage runs emulated when building for another architecture.
FROM --platform=$BUILDPLATFORM golang:1.27 AS build

ARG TARGETOS
ARG TARGETARCH
ARG VERSION

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
	go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/gophish .


# Runtime container
FROM debian:stable-slim

RUN useradd -m -d /opt/gophish -s /bin/bash app

RUN apt-get update && \
	apt-get install --no-install-recommends -y jq libcap2-bin ca-certificates && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/gophish
COPY --from=build /out/gophish ./
COPY templates/ ./templates/
COPY static/css/dist/ ./static/css/dist/
COPY static/js/dist/ ./static/js/dist/
COPY static/js/src/vendor/ckeditor/ ./static/js/src/vendor/ckeditor/
COPY static/images/ ./static/images/
COPY static/font/ ./static/font/
COPY static/db/ ./static/db/
COPY docker/run.sh ./docker/
COPY VERSION ./
COPY --chown=app config.json ./
RUN mkdir -p static/endpoint

RUN setcap 'cap_net_bind_service=+ep' /opt/gophish/gophish

USER app
RUN sed -i 's/127.0.0.1/0.0.0.0/g' config.json
RUN touch config.json.tmp

EXPOSE 3333 8080 8443 80

CMD ["./docker/run.sh"]
