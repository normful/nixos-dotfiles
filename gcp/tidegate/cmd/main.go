package main

import (
	"context"
	"log"
	"log/slog"
	"os"

	"tidegate/config"
	"tidegate/gcp"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{})))

	cfg, loadErr := config.Load()
	if loadErr != nil {
		log.Fatalf("Failed to load config: %v", loadErr)
	}

	slog.Info("Environment variables",
		"projectID", cfg.ProjectID,
		"region", cfg.Region,
		"stack", cfg.Stack,
		"operation", cfg.Operation,
	)

	ctx := context.Background()

	client, clientErr := gcp.NewClient(ctx, nil, "")
	if clientErr != nil {
		log.Fatalf("Failed to create GCP client: %v", clientErr)
	}
	defer func() {
		if closeErr := client.Close(); closeErr != nil {
			slog.Error("Error closing GCP client", "error", closeErr)
		}
	}()

	switch cfg.Operation {
	case "CREATE":
		createErr := gcp.CreateNATInfrastructure(ctx, cfg, client)
		if createErr != nil {
			log.Fatalf("Failed to create NAT infrastructure: %v", createErr)
		}
		slog.Info("NAT infrastructure ensured successfully")
	case "DELETE":
		deleteErr := gcp.DeleteNATInfrastructure(ctx, cfg, client)
		if deleteErr != nil {
			log.Fatalf("Failed to delete NAT infrastructure: %v", deleteErr)
		}
		slog.Info("NAT infrastructure deleted successfully")
	default:
		log.Fatal("Unrecognized operation")
	}
}
