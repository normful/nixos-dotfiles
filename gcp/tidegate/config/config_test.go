package config

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoad(t *testing.T) {
	tests := []struct {
		name        string
		env         map[string]string
		expectError bool
		expected    Config
	}{
		{
			name: "valid config",
			env: map[string]string{
				"GOOGLE_CLOUD_PROJECT_ID": "test-project",
				"GOOGLE_CLOUD_REGION":     "us-central1",
				"PULUMI_STACK_NAME":       "test-stack",
				"OPERATION":               "test-op",
			},
			expectError: false,
			expected: Config{
				ProjectID: "test-project",
				Region:    "us-central1",
				Stack:     "test-stack",
				Operation: "test-op",
			},
		},
		{
			name: "missing project ID",
			env: map[string]string{
				"GOOGLE_CLOUD_REGION": "us-central1",
			},
			expectError: true,
		},
		{
			name: "missing region",
			env: map[string]string{
				"GOOGLE_CLOUD_PROJECT_ID": "test-project",
			},
			expectError: true,
		},
		{
			name: "missing stack",
			env: map[string]string{
				"GOOGLE_CLOUD_PROJECT_ID": "test-project",
				"GOOGLE_CLOUD_REGION":     "us-central1",
				"OPERATION":               "test-op",
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Set env vars
			for k, v := range tt.env {
				if setErr := os.Setenv(k, v); setErr != nil {
					t.Fatalf("Failed to set env var %s: %v", k, setErr)
				}
				defer func(key string) {
					if unsetErr := os.Unsetenv(key); unsetErr != nil {
						t.Errorf("Failed to unset env var %s: %v", key, unsetErr)
					}
				}(k)
			}

			// Clear others
			if unsetErr := os.Unsetenv("GOOGLE_CLOUD_PROJECT_ID"); unsetErr != nil {
				t.Fatalf("Failed to unset env var: %v", unsetErr)
			}
			if unsetErr := os.Unsetenv("GOOGLE_CLOUD_REGION"); unsetErr != nil {
				t.Fatalf("Failed to unset env var: %v", unsetErr)
			}
			if unsetErr := os.Unsetenv("PULUMI_STACK_NAME"); unsetErr != nil {
				t.Fatalf("Failed to unset env var: %v", unsetErr)
			}
			if unsetErr := os.Unsetenv("OPERATION"); unsetErr != nil {
				t.Fatalf("Failed to unset env var: %v", unsetErr)
			}

			for k, v := range tt.env {
				if setErr := os.Setenv(k, v); setErr != nil {
					t.Fatalf("Failed to set env var %s: %v", k, setErr)
				}
			}

			cfg, loadErr := Load()
			if tt.expectError {
				assert.Error(t, loadErr)
			} else {
				assert.NoError(t, loadErr)
				assert.Equal(t, tt.expected, cfg)
			}
		})
	}
}
