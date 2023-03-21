# Thanks goes to mitchellh for https://github.com/mitchellh/nixos-config/blob/main/Makefile where most of this is copied from

MAKEFILE_DIR:=$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Build NixOS installer .iso file
build_iso:
	cd installer_iso; ./build.sh

# --------------------------------------------------------------------------------------
# prl/init/* targets are for initial one-time setup of a Parallels VM
# --------------------------------------------------------------------------------------

# Change this to the IP of `ip a`
NIXOS_VM_IP:=10.211.55.6
NIXOS_VM_SSH_PORT:=22
SWAP_PARTITION_SIZE_GIB:=16
NIXOS_USER:=norman
SSH_OPTIONS:=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# Partition disk, format partitions, generate NixOS configuration, and install NixOS.
prl/init/install:
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
			users.users.root.prl/initPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd; \
		reboot; \
	"

# Run this after the first reboot.
prl/init/after_install:
	$(MAKE) prl/init/copy_config
	$(MAKE) prl/init/rebuild
	$(MAKE) prl/init/copy_secrets
	$(MAKE) prl/init/reboot

prl/init/copy_config:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='.git' \
		--exclude='*.iso' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ root@$(NIXOS_VM_IP):/nixos-dotfiles

prl/init/rebuild:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		nixos-rebuild switch --flake \"/nixos-dotfiles#$(NIXOS_CONFIG_NAME)\"; \
	"

prl/init/copy_secrets:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--include='id_*' \
		--exclude='*' \
		$(HOME)/.ssh/ $(NIXOS_USER)@$(NIXOS_VM_IP):~/.ssh

	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT)' \
		--exclude='.#*/' \
		--exclude='S*/' \
		--exclude='*.conf/' \
		$(HOME)/.gnupg/ $(NIXOS_USER)@$(NIXOS_VM_IP):~/.gnupg


prl/init/reboot:
	ssh $(SSH_OPTIONS) -p$(NIXOS_VM_SSH_PORT) root@$(NIXOS_VM_IP) " \
		set -o xtrace; \
		reboot; \
	"

# --------------------------------------------------------------------------------------
# These can be used after initial setup, when logged in as $NIXOS_USER
# --------------------------------------------------------------------------------------

stow:
	stow -t $(HOME) -S git fish kitty karabiner htop scripts

unstow:
	stow -t $(HOME) -D git fish kitty karabiner htop scripts

prl:
	sudo nixos-rebuild switch --flake ".#$(NIXOS_CONFIG_NAME)"

mac:
	darwin-rebuild switch --flake ~/code/nixos-dotfiles#macbook-pro-18-3

update-flake:
	nix flake update
