package gcp

import (
	"context"

	"tidegate/config"

	"cloud.google.com/go/compute/apiv1/computepb"
)

// TestAuth tests authentication by getting project info and returns the project name
func TestAuth(ctx context.Context, cfg config.Config, getter ProjectGetter) (string, error) {
	projectReq := &computepb.GetProjectRequest{
		Project: cfg.ProjectID,
	}
	project, getErr := getter.Get(ctx, projectReq)
	if getErr != nil {
		return "", getErr
	}
	return project.GetName(), nil
}
