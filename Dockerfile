# Module Cached image
FROM docker-upgrade.artifactory.build.upgrade.com/go-builder:2.0.20200406.0-205.1.14.3-205 AS build_base

WORKDIR /go/src/github.com/moriyoshi/s3-sftp-proxy

# Add go.mod and go.sum first to maximize caching
COPY ./go.mod ./go.sum ./

RUN go mod download

# Tool builder image
FROM build_base AS tool_builder

COPY . .

RUN echo "Testing" \
    && go test ./...  -short \
    && echo


#Disabling linter since this project is a fork
#RUN echo "Inspecting code" \
#    && GOGC=10 golangci-lint run ./... \
#         --timeout 5m \
#    && echo

RUN echo "Building" \
    && go install \
    && echo

# Definitive image
FROM docker-upgrade.artifactory.build.upgrade.com/container-base:2.0.20200406.0-205

# We know it's bad but this is for docker socket to be accessible when mounted used with twistcli actually
# ticket open for that issue: https://credify.atlassian.net/browse/TOP-9238
USER root

WORKDIR /

COPY --from=tool_builder /go/bin/s3-sftp-proxy  /usr/bin/s3-sftp-proxy

CMD ["/usr/bin/s3-sftp-proxy", "-debug"]
