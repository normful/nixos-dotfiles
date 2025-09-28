FROM golang:1.24 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o tidegate ./cmd

FROM gcr.io/distroless/base-debian12:latest
COPY --from=builder /app/tidegate /tidegate
CMD ["/tidegate"]
