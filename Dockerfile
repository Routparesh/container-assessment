# Stage 1: Build

FROM golang:1.25-alpine AS builder

# Install required packages
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy dependency files first (cache optimization)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o backend-api ./cmd/api


# Stage 2: Runtime

FROM gcr.io/distroless/base-debian12

# Create non-root user
USER nonroot:nonroot

WORKDIR /app

# Copy binary
COPY --from=builder /app/backend-api .

# Expose application port
EXPOSE 8080

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD ["wget", "-qO-", "http://localhost:8080/health"]

# Start application
ENTRYPOINT ["/app/backend-api"]
