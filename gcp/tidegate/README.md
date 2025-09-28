# Tidegate

A Go utility for managing Google Cloud Platform resources.

## Environment Variables

- `GOOGLE_CLOUD_PROJECT_ID`: GCP project ID (required)
- `GOOGLE_CLOUD_REGION`: GCP region (required)
- `PULUMI_STACK_NAME`: Stack name for resource naming (required)
- `OPERATION`: Operation to perform - `CREATE` or `DELETE` (required)

## Operations

### CREATE
Creates NAT infrastructure if it doesn't exist:
- External IP address
- Cloud Router with NAT gateway

### DELETE
Deletes NAT infrastructure if it exists:
- Cloud Router with NAT gateway
- External IP address

## Usage

```bash
export GOOGLE_CLOUD_PROJECT_ID=your-project
export GOOGLE_CLOUD_REGION=us-central1
export PULUMI_STACK_NAME=your-stack
export OPERATION=CREATE

go run cmd/main.go
```

## Building

```bash
go build ./cmd
```

## Scripts

The project includes several convenience scripts for common development and deployment tasks:

### `lint-and-test.sh`
Runs code linting and unit tests:
```bash
./lint-and-test.sh
```

### `run.sh`
Interactively builds and runs the application, allowing you to choose between CREATE and DELETE operations with predefined environment variables for development:
```bash
./run.sh
```

### `docker-auth.sh`
Configures Docker authentication for Google Cloud Artifact Registry using service account credentials from the current Pulumi stack:
```bash
./docker-auth.sh
```

### `build-and-push.sh`
Builds a Docker image, runs linting, configures authentication, and pushes the image to Google Cloud Artifact Registry:
```bash
./build-and-push.sh
```