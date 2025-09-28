package gcp

import (
	"context"
	"fmt"
	"log/slog"
	"strings"

	"tidegate/config"

	compute "cloud.google.com/go/compute/apiv1"
	"cloud.google.com/go/compute/apiv1/computepb"
	"google.golang.org/api/iterator"
)

const (
	AddressTypeExternal = "EXTERNAL"
	NatIpDescription    = "Static public IP address for Cloud NAT"
)

func RouterName(stack string) string {
	return fmt.Sprintf("%s-router", stack)
}

func NatName(stack string) string {
	return fmt.Sprintf("%s-nat", stack)
}

func NatIpName(stack string) string {
	return fmt.Sprintf("%s-nat-ip-1", stack)
}

// ListVPCs lists VPC networks and returns their names
func ListVPCs(ctx context.Context, cfg config.Config, lister NetworkLister) ([]string, error) {
	networksReq := &computepb.ListNetworksRequest{
		Project: cfg.ProjectID,
	}
	networksIt := lister.List(ctx, networksReq)
	var names []string
	for {
		network, iterErr := networksIt.Next()
		if iterErr == iterator.Done {
			break
		}
		if iterErr != nil {
			return nil, iterErr
		}
		names = append(names, network.GetName())
	}
	return names, nil
}

// ListSubnetworks lists subnetworks in the region and returns their names
func ListSubnetworks(ctx context.Context, cfg config.Config, lister SubnetworkLister) ([]string, error) {
	subnetworksReq := &computepb.ListSubnetworksRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
	}
	subnetworksIt := lister.List(ctx, subnetworksReq)
	var names []string
	for {
		subnetwork, iterErr := subnetworksIt.Next()
		if iterErr == iterator.Done {
			break
		}
		if iterErr != nil {
			return nil, iterErr
		}
		names = append(names, subnetwork.GetName())
	}
	return names, nil
}

// ListNATGateways lists NAT gateways and returns them
func ListNATGateways(ctx context.Context, cfg config.Config, lister RouterManager) ([]*computepb.RouterNat, error) {
	routersReq := &computepb.ListRoutersRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
	}
	routersIt := lister.List(ctx, routersReq)
	var nats []*computepb.RouterNat
	for {
		router, iterErr := routersIt.Next()
		if iterErr == iterator.Done {
			break
		}
		if iterErr != nil {
			return nil, iterErr
		}
		nats = append(nats, router.GetNats()...)
	}
	return nats, nil
}

// ListRouters lists routers in the region and returns them
func ListRouters(ctx context.Context, cfg config.Config, lister RouterManager) ([]*computepb.Router, error) {
	routersReq := &computepb.ListRoutersRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
	}
	routersIt := lister.List(ctx, routersReq)
	var routers []*computepb.Router
	for {
		router, iterErr := routersIt.Next()
		if iterErr == iterator.Done {
			break
		}
		if iterErr != nil {
			return nil, iterErr
		}
		routers = append(routers, router)
	}
	return routers, nil
}

// ListExternalIPs lists external IP addresses and returns them
func ListExternalIPs(ctx context.Context, cfg config.Config, lister IpAddressManager) ([]*computepb.Address, error) {
	addressesReq := &computepb.ListAddressesRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
	}
	addressesIt := lister.List(ctx, addressesReq)
	var addresses []*computepb.Address
	for {
		address, iterErr := addressesIt.Next()
		if iterErr == iterator.Done {
			break
		}
		if iterErr != nil {
			return nil, iterErr
		}
		if address.GetAddressType() == AddressTypeExternal {
			addresses = append(addresses, address)
		}
	}
	return addresses, nil
}

// GetNetworkSelfLink gets the self-link of the VPC whose name contains the stack name
func GetNetworkSelfLink(ctx context.Context, cfg config.Config, lister NetworkLister) (string, error) {
	networksReq := &computepb.ListNetworksRequest{
		Project: cfg.ProjectID,
	}
	networksIt := lister.List(ctx, networksReq)
	for {
		network, iterErr := networksIt.Next()
		if iterErr == iterator.Done {
			return "", fmt.Errorf("no network found with stack name '%s' in the name", cfg.Stack)
		}
		if iterErr != nil {
			return "", iterErr
		}
		if strings.Contains(network.GetName(), cfg.Stack) {
			return network.GetSelfLink(), nil
		}
	}
}

// GetSubnetworkSelfLink gets the self-link of the first subnetwork in the specified network and region
func GetSubnetworkSelfLink(ctx context.Context, cfg config.Config, networkSelfLink string, lister SubnetworkLister) (string, error) {
	subnetworksReq := &computepb.ListSubnetworksRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
	}
	subnetworksIt := lister.List(ctx, subnetworksReq)
	for {
		subnetwork, iterErr := subnetworksIt.Next()
		if iterErr == iterator.Done {
			return "", fmt.Errorf("no subnetwork found in network %s", networkSelfLink)
		}
		if iterErr != nil {
			return "", iterErr
		}
		if subnetwork.GetNetwork() == networkSelfLink {
			return subnetwork.GetSelfLink(), nil
		}
	}
}

// CreateNATInfrastructure creates NAT infrastructure if it doesn't exist
func CreateNATInfrastructure(ctx context.Context, cfg config.Config, client *Client) error {
	var op *compute.Operation
	var insertErr error

	nats, listErr := ListNATGateways(ctx, cfg, client.Routers)
	if listErr != nil {
		return listErr
	}

	slog.Info("Found NATs", "count", len(nats))

	for _, nat := range nats {
		slog.Info("NAT", "name", nat.GetName())
		if nat.GetName() == NatName(cfg.Stack) {
			// Find and log the associated IP
			addresses, listErr := ListExternalIPs(ctx, cfg, client.Addresses)
			if listErr != nil {
				return listErr
			}
			addressName := NatIpName(cfg.Stack)
			for _, addr := range addresses {
				if addr.GetName() == addressName {
					slog.Info("NAT already exists, skipping creation", "publicIpv4", addr.GetAddress())
					break
				}
			}
			return nil
		}
	}

	// Get network and subnetwork self-links
	networkSelfLink, getErr := GetNetworkSelfLink(ctx, cfg, client.Networks)
	if getErr != nil {
		return getErr
	}
	slog.Info("Selected network", "network", networkSelfLink)
	subnetworkSelfLink, getErr := GetSubnetworkSelfLink(ctx, cfg, networkSelfLink, client.Subnetworks)
	if getErr != nil {
		return getErr
	}
	slog.Info("Selected subnetwork", "subnetwork", subnetworkSelfLink)

	// Check for existing address
	addresses, listErr := ListExternalIPs(ctx, cfg, client.Addresses)
	if listErr != nil {
		return listErr
	}

	addressName := NatIpName(cfg.Stack)
	var addressSelfLink string
	var existingAddr *computepb.Address
	for _, addr := range addresses {
		if addr.GetName() == addressName {
			addressSelfLink = addr.GetSelfLink()
			existingAddr = addr
			break
		}
	}

	if addressSelfLink == "" {
		// Create external IP address
		addressReq := &computepb.InsertAddressRequest{
			Project: cfg.ProjectID,
			Region:  cfg.Region,
			AddressResource: &computepb.Address{
				Name:        stringPtr(addressName),
				AddressType: stringPtr(AddressTypeExternal),
				Description: stringPtr(NatIpDescription),
			},
		}

		op, insertErr = client.Addresses.Insert(ctx, addressReq)
		if insertErr != nil {
			return insertErr
		}

		if waitErr := op.Wait(ctx); waitErr != nil {
			return waitErr
		}

		addressSelfLink = fmt.Sprintf("https://www.googleapis.com/compute/v1/projects/%s/regions/%s/addresses/%s", cfg.ProjectID, cfg.Region, addressName)
	} else {
		slog.Info("Using existing address", "address", addressSelfLink, "publicIpv4", existingAddr.GetAddress())
	}

	// Create router with NAT
	routerReq := &computepb.InsertRouterRequest{
		Project: cfg.ProjectID,
		Region:  cfg.Region,
		RouterResource: &computepb.Router{
			Name:    stringPtr(RouterName(cfg.Stack)),
			Network: stringPtr(networkSelfLink),
			Nats: []*computepb.RouterNat{
				{
					Name:                          stringPtr(NatName(cfg.Stack)),
					NatIpAllocateOption:           stringPtr("MANUAL_ONLY"),
					NatIps:                        []string{addressSelfLink},
					SourceSubnetworkIpRangesToNat: stringPtr("LIST_OF_SUBNETWORKS"),
					Subnetworks: []*computepb.RouterNatSubnetworkToNat{
						{
							Name:                stringPtr(subnetworkSelfLink),
							SourceIpRangesToNat: []string{"ALL_IP_RANGES"},
						},
					},
					MinPortsPerVm:                    int32Ptr(2048),
					EnableEndpointIndependentMapping: boolPtr(true),
				},
			},
		},
	}

	op, insertErr = client.Routers.Insert(ctx, routerReq)
	if insertErr != nil {
		return insertErr
	}

	return op.Wait(ctx)
}

// DeleteNATInfrastructure deletes NAT infrastructure if it exists
func DeleteNATInfrastructure(ctx context.Context, cfg config.Config, client *Client) error {
	// 1. List routers in the region
	routers, listErr := ListRouters(ctx, cfg, client.Routers)
	if listErr != nil {
		return listErr
	}

	// 2. Find router with name "{stack}-router"
	var routerToDelete *computepb.Router
	for _, router := range routers {
		if router.GetName() == RouterName(cfg.Stack) {
			routerToDelete = router
			break
		}
	}

	// 3. Check if router was found
	if routerToDelete == nil {
		slog.Info("Router not found, skipping deletion", "router", RouterName(cfg.Stack))
	} else {
		// Delete router (this should also delete associated NATs)
		deleteRouterReq := &computepb.DeleteRouterRequest{
			Project: cfg.ProjectID,
			Region:  cfg.Region,
			Router:  RouterName(cfg.Stack),
		}
		op, deleteErr := client.Routers.Delete(ctx, deleteRouterReq)
		if deleteErr != nil {
			return deleteErr
		}
		if waitErr := op.Wait(ctx); waitErr != nil {
			return waitErr
		}
		slog.Info("Router deleted", "router", RouterName(cfg.Stack))
	}

	// 4. List external IPs in the region
	addresses, listErr := ListExternalIPs(ctx, cfg, client.Addresses)
	if listErr != nil {
		return listErr
	}

	// 5. Find external IP with name "{stack}-nat-ip-1"
	var addressToDelete *computepb.Address
	for _, address := range addresses {
		if address.GetName() == NatIpName(cfg.Stack) {
			addressToDelete = address
			break
		}
	}

	// 6. Check if address was found
	if addressToDelete == nil {
		slog.Info("External IP not found, skipping deletion")
	} else {
		// Delete external IP
		deleteAddressReq := &computepb.DeleteAddressRequest{
			Project: cfg.ProjectID,
			Region:  cfg.Region,
			Address: NatIpName(cfg.Stack),
		}
		op, deleteErr := client.Addresses.Delete(ctx, deleteAddressReq)
		if deleteErr != nil {
			return deleteErr
		}
		if waitErr := op.Wait(ctx); waitErr != nil {
			return waitErr
		}
		slog.Info("External IP deleted", "address", NatIpName(cfg.Stack), "publicIpv4", addressToDelete.GetAddress())
	}

	return nil
}

func stringPtr(s string) *string {
	return &s
}

func int32Ptr(i int32) *int32 {
	return &i
}

func boolPtr(b bool) *bool {
	return &b
}
