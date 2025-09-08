# One-time initial setup

1. Install `nix` on your machine (the package manager only, not NixOS). <https://nixos.org/download/>
1. Install [`mise`](https://github.com/jdx/mise).
1. Set up your shell do to [automatic `mise` activation](https://mise.jdx.dev/installing-mise.html#shells).
1. Run `mise trust` in this directory.
1. If you haven't already, create a project in Google Cloud Platform with `gcloud projects create your-project-id`
1. If you haven't already, create an SSH keypair with `ssh-keygen`.
1. Setup `age` and `sops`.
    1. Create at least one `age` keypair by running `age-keygen`.
    1. This keypair encrypts and decrypts `./secrets/gcp_*.yaml` files.
    1. Copy the public key of your new keypair into the top `keys` section in `.sops.yaml`.

# To launch a new VM with NixOS

Each time you want to launch a new Google Compute Engine VM machine and install NixOS on it:

1. Edit in `mise.toml`
    - `GCP_VM_HOSTNAME`. The new GCP VM's desired hostname.
1. If you are not Norman, make these additional edits to `mise.toml`:
    - `GCP_VM_USERNAME`. Name of non-root user that you want created on the VM
    - `SSH_PUBLIC_KEY_PATH`. Path to your local SSH public key `*.pub`
    - `GCE_PRIVATE_KEY_PATH`. Path to the Google Compute Engine key for using `gcloud compute ssh`. Usually ~/.ssh/google_compute_engine
    - `IAP_USER_EMAIL`. Google account email to use with Identity Aware Proxy for tunneled SSH access to the new virtual machine.
1. `mise run new` to create new copies of config Pulumi and Nix files for the new VM.
1. Create a new Tailscale auth key:
    1. Log into Tailscale admin console
    1. Create a Non-reusable, Pre-approved, Tagged auth key. It'll produce `tskey-auth-...`
1. Create a hash your desired sudo password for the new non-root user on the VM.
    - Run `mkpasswd -m sha-512`. It'll produce `$...`
1. `mise run secrets` to edit `secrets/gcp_<hostname>.yaml` with `sops`.
    - Paste in your recently created secrets:
        ```yaml
        hashedUserPassword: $...
        tailscaleAuthKey: tskey-auth-...
        ```
    - Save and close the file.
1. Add the new hostname to `flake.nix`, under `linuxHostnames`.
1. If you are not Norman, you probably also want to change:
    - `Pulumi.<hostname>.yaml`
        - `gcp:project`
        - `gcp:zone`
        - `nixos-gce:machineType`
        - `nixos-gce:region`
        - `nixos-gce:alertEmail`
    - `gcp/<hostname>/configuration.nix`
    - `gcp/<hostname>/my-config.nix`
    - If you want to customize the GCP infrastructure for the new VM, you can also edit the TypeScript Pulumi files under the `gcp` folder.
1. (Optional) Commit the new files.
1. `mise run up` to launch the GCP resources with Pulumi.
    You may encounter such errors:
    ```sh
    Error creating AlertPolicy: ...
    If a metric was created recently, it could take up to 10 minutes to become available. Please try again soon.
    ```
    These are normal. To resolve them, wait a bit and `mise run up` a second or third time until everything is created.
1. `mise run logkey`. It will update `secrets/gcp_<hostname>.yaml` with a newly created GCP Service Account key to allow the new instance to send log records to Google Cloud Logging.
1. `mise run i` install NixOS on the new VM.
    1. You will be prompted to paste in your `age` private key. It will be copied to the new VM.
        ```sh
        Please enter the 'age' private key that was used to encrypt secrets/gcp_cork.yaml:
        The key should start with 'AGE-SECRET-KEY-' and be on a single line.
        'age' private key:
        ```
    1. If you added a passphrase to your SSH private key at `GCE_PRIVATE_KEY_PATH`, you will be prompted for its passphase. But it be asking for the passphrase "/tmp/tmp.XXXXXXXXXX/nixos-anywhere", because `nixos-anywhere` copies your `GCE_PRIVATE_KEY_PATH` key to a `/tmp` subdirectory.
        ```sh
        Warning: Identity file /tmp/tmp.V0q68MsW8t/nixos-anywhere not accessible: No such file or directory.
        Enter passphrase for "/tmp/tmp.V0q68MsW8t/nixos-anywhere":
        ```
        You can ignore the `Warning: Identity file /tmp/tmp.V0q68MsW8t/nixos-anywhere not accessible: No such file or directory.`
