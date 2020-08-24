FROM golang:1.14-alpine

RUN apk add --update --no-cache git build-base

ARG GOPROXY

WORKDIR /app
COPY ./lsonnet.go .
COPY ./go.mod  .
COPY ./go.sum  .

ARG VERSION="not-set"
RUN GOPROXY=${GOPROXY} go build -ldflags "-X main.version=${VERSION}" -o ./bin/lsonnet .

FROM alpine:latest

RUN apk add --update --no-cache git ca-certificates

COPY --from=0 /app/bin/lsonnet /usr/local/bin/lsonnet

ENTRYPOINT ["/usr/local/bin/lsonnet"]
