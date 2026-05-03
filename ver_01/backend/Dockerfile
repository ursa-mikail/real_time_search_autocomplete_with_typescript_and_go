FROM golang:1.22-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git ca-certificates
COPY . .
RUN GONOSUMDB='*' GOFLAGS='-mod=mod' go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /searchpulse-api ./cmd/server

FROM alpine:3.19
RUN apk add --no-cache ca-certificates wget
COPY --from=builder /searchpulse-api /searchpulse-api
EXPOSE 8080
ENTRYPOINT ["/searchpulse-api"]
