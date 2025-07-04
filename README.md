# coolify-on-podman
Installation script and utilities to run Coolify on Podman

## Usage

1. cd to project directory and run `./setup-coolify-podman.sh`
2. After registration, Skip onboarding.
3. Generate a new private key in coolify dashboard and 
4. append that public key to `./ssh/authorized_keys` file.
5. In coolify dashboard, add new server, use `systemd-vm` as hostname/ip address of the server.
6. Add and validate the server
