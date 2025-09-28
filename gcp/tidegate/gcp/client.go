package gcp

import (
	"context"
	"net/http"

	compute "cloud.google.com/go/compute/apiv1"
	"cloud.google.com/go/compute/apiv1/computepb"
	"github.com/googleapis/gax-go/v2"
	"google.golang.org/api/option"
)

// ProjectGetter interface for getting project info
type ProjectGetter interface {
	Get(ctx context.Context, req *computepb.GetProjectRequest, opts ...gax.CallOption) (*computepb.Project, error)
	Close() error
}

// NetworkLister interface for listing networks
type NetworkLister interface {
	List(ctx context.Context, req *computepb.ListNetworksRequest, opts ...gax.CallOption) NetworkIterator
	Close() error
}

// NetworkIterator type alias for concrete iterator
type NetworkIterator = *compute.NetworkIterator

// SubnetworkLister interface for listing subnetworks
type SubnetworkLister interface {
	List(ctx context.Context, req *computepb.ListSubnetworksRequest, opts ...gax.CallOption) SubnetworkIterator
	Close() error
}

// SubnetworkIterator type alias for concrete iterator
type SubnetworkIterator = *compute.SubnetworkIterator

// RouterManager interface for managing routers
type RouterManager interface {
	List(ctx context.Context, req *computepb.ListRoutersRequest, opts ...gax.CallOption) RouterIterator
	Insert(ctx context.Context, req *computepb.InsertRouterRequest, opts ...gax.CallOption) (*compute.Operation, error)
	Delete(ctx context.Context, req *computepb.DeleteRouterRequest, opts ...gax.CallOption) (*compute.Operation, error)
	Close() error
}

// RouterIterator type alias for concrete iterator
type RouterIterator = *compute.RouterIterator

// IpAddressManager interface for managing IP addresses
type IpAddressManager interface {
	List(ctx context.Context, req *computepb.ListAddressesRequest, opts ...gax.CallOption) IpAddressIterator
	Insert(ctx context.Context, req *computepb.InsertAddressRequest, opts ...gax.CallOption) (*compute.Operation, error)
	Delete(ctx context.Context, req *computepb.DeleteAddressRequest, opts ...gax.CallOption) (*compute.Operation, error)
	Close() error
}

// IpAddressIterator type alias for concrete iterator
type IpAddressIterator = *compute.AddressIterator

// Client holds all GCP clients
type Client struct {
	Projects    ProjectGetter
	Networks    NetworkLister
	Subnetworks SubnetworkLister
	Routers     RouterManager
	Addresses   IpAddressManager
}

// NewClient creates a new Client with optional HTTP client and endpoint for testing
func NewClient(ctx context.Context, httpClient *http.Client, endpoint string) (*Client, error) {
	opts := []option.ClientOption{}
	if httpClient != nil {
		opts = append(opts, option.WithHTTPClient(httpClient))
	}
	if endpoint != "" {
		opts = append(opts, option.WithEndpoint(endpoint))
	}

	projectsClient, clientErr := compute.NewProjectsRESTClient(ctx, opts...)
	if clientErr != nil {
		return nil, clientErr
	}

	networksClient, clientErr := compute.NewNetworksRESTClient(ctx, opts...)
	if clientErr != nil {
		_ = projectsClient.Close()
		return nil, clientErr
	}

	subnetworksClient, clientErr := compute.NewSubnetworksRESTClient(ctx, opts...)
	if clientErr != nil {
		_ = projectsClient.Close()
		_ = networksClient.Close()
		return nil, clientErr
	}

	routersClient, clientErr := compute.NewRoutersRESTClient(ctx, opts...)
	if clientErr != nil {
		_ = projectsClient.Close()
		_ = networksClient.Close()
		_ = subnetworksClient.Close()
		return nil, clientErr
	}

	addressesClient, clientErr := compute.NewAddressesRESTClient(ctx, opts...)
	if clientErr != nil {
		_ = projectsClient.Close()
		_ = networksClient.Close()
		_ = subnetworksClient.Close()
		_ = routersClient.Close()
		return nil, clientErr
	}

	return &Client{
		Projects:    projectsClient,
		Networks:    networksClient,
		Subnetworks: subnetworksClient,
		Routers:     routersClient,
		Addresses:   addressesClient,
	}, nil
}

// Close closes all clients
func (c *Client) Close() error {
	errs := []error{}
	if closeErr := c.Projects.Close(); closeErr != nil {
		errs = append(errs, closeErr)
	}
	if closeErr := c.Networks.Close(); closeErr != nil {
		errs = append(errs, closeErr)
	}
	if closeErr := c.Subnetworks.Close(); closeErr != nil {
		errs = append(errs, closeErr)
	}
	if closeErr := c.Routers.Close(); closeErr != nil {
		errs = append(errs, closeErr)
	}
	if closeErr := c.Addresses.Close(); closeErr != nil {
		errs = append(errs, closeErr)
	}
	if len(errs) > 0 {
		return errs[0] // Return first error for simplicity
	}
	return nil
}
