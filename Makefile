# Thanks goes to mitchellh for https://github.com/mitchellh/nixos-config/blob/main/Makefile where most of this is copied from

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

NIXOS_VM_IP := 192.168.174.130 # Change this to the IP of `ip a`
NIXOS_VM_SSH_PORT := 22

SWAP_PARTITION_SIZE_GIB := 16
NIX_PACKAGE := nixVersions.nix_2_9 # https://search.nixos.org/packages?from=0&size=50&sort=relevance&type=packages&query=nixVersions

SSH_OPTIONS := -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# Build ISO CD installer for NixOS.
build_installer_iso:
	cd installer_iso; ./build.sh

# Partition disk, format partitions, generate NixOS configuration, and install NixOS.
initial_install:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		lsblk --paths; \
		parted /dev/nvme0n1 -- mklabel gpt; \
		parted /dev/nvme0n1 -- mkpart primary 512MiB -$(SWAP_SIZE_GIB)GiB; \
		parted /dev/nvme0n1 -- mkpart primary linux-swap -$(SWAP_SIZE_GIB)GiB 100\%; \
		parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB; \
		parted /dev/nvme0n1 -- set 3 esp on; \
		lsblk --paths; \
		mkfs.ext4 -L      nixos /dev/nvme0n1p1; \
		mkswap    -L      swap  /dev/nvme0n1p2; \
		mkfs.fat -F 32 -n boot  /dev/nvme0n1p3; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = $(NIX_PACKAGE);\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			services.openssh.enable = true;\n \
			services.openssh.passwordAuthentication = true;\n \
			services.openssh.permitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --verbose --no-root-passwd; \
		reboot; \
	"

configure_and_reboot:
	NIXUSER=root $(MAKE) copy_config
	NIXUSER=root $(MAKE) switch
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) $(NIXUSER)@$(NIXOS_VM_IP) " \
		sudo reboot; \
	"

copy_config:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='.git/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXOS_VM_IP):/nixos-dotfiles

test:
	NIXUSER=root REBUILD_OPERATION=test $(MAKE) nixos_rebuild

switch:
	NIXUSER=root REBUILD_OPERATION=switch $(MAKE) nixos_rebuild

nixos_rebuild:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) $(NIXUSER)@$(NIXOS_VM_IP) " \
		sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild $(REBUILD_OPERATION) --flake \"/nixos-dotfiles#aarch64-in-vmware\" \
	"
