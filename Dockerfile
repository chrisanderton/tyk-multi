FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM --platform=$BUILDPLATFORM golang:1.16.15-alpine AS builder

ARG TARGETPLATFORM
ARG CGO_ENABLED=1

ARG TYK_GW_VERSION=4.3.3
ARG TYK_PUMP_VERSION=1.7.0
ARG TYK_SYNC_VERSION=1.2.4
ARG TYK_TIB_VERSION=1.3.1

COPY --from=xx / /

RUN apk add --no-cache clang git file lld llvm pkgconfig
RUN xx-apk add --no-cache gcc musl-dev
RUN xx-go --wrap

# XX_CC_PREFER_STATIC_LINKER prefers ld to lld in ppc64le and 386.
ENV XX_CC_PREFER_STATIC_LINKER=1

RUN git clone --depth 1 --branch v${TYK_GW_VERSION} https://github.com/TykTechnologies/tyk.git /opt/tyk-gateway
WORKDIR /opt/tyk-gateway/

RUN cd /opt/tyk-gateway/ \
    && go mod download -x \
    && go mod verify \  
    && go build -tags "coprocess grpc goplugin" -o tyk -v . \
    && go clean -modcache
    
RUN git clone --depth 1 --branch v${TYK_PUMP_VERSION} https://github.com/TykTechnologies/tyk-pump.git /opt/tyk-pump
WORKDIR /opt/tyk-pump/

RUN cd /opt/tyk-pump/ \
    && go mod download -x \
    && go mod verify \  
    && go build -o tyk-pump -v . \
    && go clean -modcache
    
RUN git clone --depth 1 --branch v${TYK_SYNC_VERSION} https://github.com/TykTechnologies/tyk-sync.git /opt/tyk-sync
WORKDIR /opt/tyk-sync/

RUN cd /opt/tyk-sync/ \
    && go mod download -x \
    && go mod verify \  
    && go build -o tyk-sync -v . \
    && go clean -modcache
    
RUN git clone --depth 1 --branch v${TYK_TIB_VERSION} https://github.com/TykTechnologies/tyk-identity-broker.git /opt/tyk-identity-broker
WORKDIR /opt/tyk-identity-broker/

RUN cd /opt/tyk-identity-broker/ \
    && go mod download -x \
    && go mod verify \  
    && go build -o tyk-identity-broker -v . \
    && go clean -modcache

FROM golang:1.16.15-alpine

COPY --from=builder /opt/tyk-gateway/ /opt/tyk-gateway/
COPY --from=builder /opt/tyk-gateway/tyk.conf.example /opt/tyk-gateway/tyk.conf

COPY --from=builder /opt/tyk-pump/ /opt/tyk-pump/
COPY --from=builder /opt/tyk-pump/pump.example.conf /opt/tyk-pump/pump.conf

COPY --from=builder /opt/tyk-sync/ /opt/tyk-sync/

COPY --from=builder /opt/tyk-identity-broker/ /opt/tyk-identity-broker/
COPY --from=builder /opt/tyk-identity-broker/tib_sample.conf /opt/tyk-identity-broker/tib.conf

ENTRYPOINT ["/opt/tyk-gateway/tyk"]%     
