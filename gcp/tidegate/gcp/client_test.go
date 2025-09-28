package gcp

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"tidegate/config"

	"github.com/stretchr/testify/assert"
)

func newMockClient(responses map[string]string) (*http.Client, string) {
	mux := http.NewServeMux()
	for path, response := range responses {
		mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(response))
		})
	}
	server := httptest.NewTLSServer(mux)
	return server.Client(), server.URL
}

func TestTestAuth(t *testing.T) {
	responses := map[string]string{
		"/compute/v1/projects/test-project": `{"name": "test-project-name"}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project"}
	name, authErr := TestAuth(context.Background(), cfg, client.Projects)
	assert.NoError(t, authErr)
	assert.Equal(t, "test-project-name", name)

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}

func TestListVPCs(t *testing.T) {
	responses := map[string]string{
		"/compute/v1/projects/test-project/global/networks": `{"items": [{"name": "vpc1"}, {"name": "vpc2"}]}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project"}
	names, listErr := ListVPCs(context.Background(), cfg, client.Networks)
	assert.NoError(t, listErr)
	assert.Equal(t, []string{"vpc1", "vpc2"}, names)

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}

func TestListSubnetworks(t *testing.T) {
	responses := map[string]string{
		"/compute/v1/projects/test-project/regions/us-central1/subnetworks": `{"items": [{"name": "subnet1"}, {"name": "subnet2"}]}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project", Region: "us-central1"}
	names, listErr := ListSubnetworks(context.Background(), cfg, client.Subnetworks)
	assert.NoError(t, listErr)
	assert.Equal(t, []string{"subnet1", "subnet2"}, names)

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}

func TestListNATGateways(t *testing.T) {
	responses := map[string]string{
		"/compute/v1/projects/test-project/regions/us-central1/routers": `{"items": [{"name": "router1", "nats": [{"name": "nat1"}, {"name": "nat2"}]}]}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project", Region: "us-central1"}
	nats, listErr := ListNATGateways(context.Background(), cfg, client.Routers)
	assert.NoError(t, listErr)
	assert.Len(t, nats, 2)
	assert.Equal(t, "nat1", nats[0].GetName())
	assert.Equal(t, "nat2", nats[1].GetName())

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}

func TestListExternalIPs(t *testing.T) {
	responses := map[string]string{
		"/compute/v1/projects/test-project/regions/us-central1/addresses": `{"items": [{"name": "ip1", "addressType": "EXTERNAL"}, {"name": "ip2", "addressType": "INTERNAL"}]}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project", Region: "us-central1"}
	ips, listErr := ListExternalIPs(context.Background(), cfg, client.Addresses)
	assert.NoError(t, listErr)
	assert.Len(t, ips, 1)
	assert.Equal(t, "ip1", ips[0].GetName())

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}

func TestDeleteNATInfrastructure(t *testing.T) {
	// Test case where resources don't exist, so no deletion attempted
	responses := map[string]string{
		"/compute/v1/projects/test-project/regions/us-central1/routers":   `{"items": []}`,
		"/compute/v1/projects/test-project/regions/us-central1/addresses": `{"items": []}`,
	}
	httpClient, endpoint := newMockClient(responses)
	client, clientErr := NewClient(context.Background(), httpClient, endpoint)
	assert.NoError(t, clientErr)

	cfg := config.Config{ProjectID: "test-project", Region: "us-central1", Stack: "test-stack"}
	deleteErr := DeleteNATInfrastructure(context.Background(), cfg, client)
	assert.NoError(t, deleteErr)

	if closeErr := client.Close(); closeErr != nil {
		t.Errorf("Failed to close client: %v", closeErr)
	}
}
