# Thanks goes to mitchellh for https://github.com/mitchellh/nixos-config/blob/main/Makefile where most of this is copied from

MAKEFILE_DIR:=$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Change this to the IP of `ip a`
NIXOS_VM_IP:=10.211.55.4
NIXOS_VM_SSH_PORT:=22

SWAP_PARTITION_SIZE_GIB:=16

NIXOS_CONFIG_NAME:=myConfig

NIXOS_USER:=norman

SSH_OPTIONS:=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# --------------------------------------------------------------------------------------
# initial/* make targets are used only in the initial one-time setup of the NixOS VM.
# --------------------------------------------------------------------------------------

# Build ISO CD installer for NixOS.
initial/build_iso:
	cd installer_iso; ./build.sh

# Partition disk, format partitions, generate NixOS configuration, and install NixOS.
initial/install:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		lsblk --paths; \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MiB -$(SWAP_PARTITION_SIZE_GIB)GiB; \
		parted /dev/sda -- mkpart primary linux-swap -$(SWAP_PARTITION_SIZE_GIB)GiB 100\%; \
		parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB; \
		parted /dev/sda -- set 3 esp on; \
		lsblk --paths; \
		mkfs.ext4 -L      nixos /dev/sda1; \
		mkswap    -L      swap  /dev/sda2; \
		mkfs.fat -F 32 -n boot  /dev/sda3; \
		sleep 5; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixFlakes;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			services.openssh.enable = true;\n \
			services.openssh.passwordAuthentication = true;\n \
			services.openssh.permitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd; \
		reboot; \
	"

# Run this after the first reboot.
initial/after_install:
	$(MAKE) initial/copy_config
	$(MAKE) initial/rebuild
	$(MAKE) initial/copy_secrets
	$(MAKE) initial/reboot

initial/copy_config:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='iso/.*iso' \
		--exclude='.git' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ root@$(NIXOS_VM_IP):/nixos-dotfiles

initial/rebuild:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		nixos-rebuild switch --flake \"/nixos-dotfiles#$(NIXOS_CONFIG_NAME)\"; \
	"

initial/copy_secrets:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXOS_USER)@$(NIXOS_VM_IP):~/.ssh

	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='.#*/' \
		--exclude='S*/' \
		--exclude='*.conf/' \
		$(HOME)/.gnupg/ $(NIXOS_USER)@$(NIXOS_VM_IP):~/.gnupg


initial/reboot:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		reboot; \
	"

# --------------------------------------------------------------------------------------
# These make targets below are used inside the NixOS, in a new git clone
# of this repo, when logged in as the $NIXOS_USER user.
# --------------------------------------------------------------------------------------

test:
	sudo nixos-rebuild test --flake ".#$(NIXOS_CONFIG_NAME)"

switch:
	sudo nixos-rebuild switch --flake ".#$(NIXOS_CONFIG_NAME)"

stow:
	xstow --verbose --target=$(HOME) --restow */

unstow:
	xstow --verbose --target=$(HOME) --delete */

# --------------------------------------------------------------------------------------
# Temporary target for iterating
# --------------------------------------------------------------------------------------

temp:
	$(MAKE) initial/copy_config
	$(MAKE) initial/rebuild
	$(MAKE) initial/reboot
