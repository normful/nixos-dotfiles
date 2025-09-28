package main

import (
	"os"
	"testing"

	"tidegate/config"

	"github.com/stretchr/testify/assert"
)

func TestConfigLoad(t *testing.T) {
	if setErr := os.Setenv("GOOGLE_CLOUD_PROJECT_ID", "test"); setErr != nil {
		t.Fatalf("Failed to set env var: %v", setErr)
	}
	if setErr := os.Setenv("GOOGLE_CLOUD_REGION", "us-central1"); setErr != nil {
		t.Fatalf("Failed to set env var: %v", setErr)
	}
	if setErr := os.Setenv("PULUMI_STACK_NAME", "test-stack"); setErr != nil {
		t.Fatalf("Failed to set env var: %v", setErr)
	}
	if setErr := os.Setenv("OPERATION", "CREATE"); setErr != nil {
		t.Fatalf("Failed to set env var: %v", setErr)
	}
	defer func() {
		if unsetErr := os.Unsetenv("GOOGLE_CLOUD_PROJECT_ID"); unsetErr != nil {
			t.Errorf("Failed to unset env var: %v", unsetErr)
		}
		if unsetErr := os.Unsetenv("GOOGLE_CLOUD_REGION"); unsetErr != nil {
			t.Errorf("Failed to unset env var: %v", unsetErr)
		}
		if unsetErr := os.Unsetenv("PULUMI_STACK_NAME"); unsetErr != nil {
			t.Errorf("Failed to unset env var: %v", unsetErr)
		}
		if unsetErr := os.Unsetenv("OPERATION"); unsetErr != nil {
			t.Errorf("Failed to unset env var: %v", unsetErr)
		}
	}()

	cfg, loadErr := config.Load()
	assert.NoError(t, loadErr)
	assert.Equal(t, "test", cfg.ProjectID)
	assert.Equal(t, "us-central1", cfg.Region)
	assert.Equal(t, "test-stack", cfg.Stack)
	assert.Equal(t, "CREATE", cfg.Operation)
}
