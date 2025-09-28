package config

import (
	"errors"
	"os"
)

type Config struct {
	ProjectID string
	Region    string
	Stack     string
	Operation string
}

func Load() (Config, error) {
	cfg := Config{
		ProjectID: os.Getenv("GOOGLE_CLOUD_PROJECT_ID"),
		Region:    os.Getenv("GOOGLE_CLOUD_REGION"),
		Stack:     os.Getenv("PULUMI_STACK_NAME"),
		Operation: os.Getenv("OPERATION"),
	}

	if cfg.ProjectID == "" {
		return Config{}, errors.New("GOOGLE_CLOUD_PROJECT_ID is required")
	}
	if cfg.Region == "" {
		return Config{}, errors.New("GOOGLE_CLOUD_REGION is required")
	}
	if cfg.Stack == "" {
		return Config{}, errors.New("PULUMI_STACK_NAME is required")
	}

	return cfg, nil
}
