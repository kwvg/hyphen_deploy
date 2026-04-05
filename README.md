> [!WARNING]
> Snapshot of configuration used in production. For review purposes only. No support or warranty is
> made available for the contents therein nor are there guarantees of correctness.

## Deployment files for Hyphen

These files are `scp`'ed/pushed to the running instance to deploy the Hyphen knowledge explorer and
make rather explicit assumptions. We made some decisions that might age poorly (RAID0 zpool for the
OS and data) so don't use these files unless you've read them at least twice.

Things you should know:

* Hetzner doesn't support UEFI booting, we are using GPT partitions with a 1MB partition for storing
  MBR with `/boot` as an ext4 partition mirrored using mdadm (RAID1). This is the only thing that's mirrored.
  The MBR is just duplicated and must be done manually if it is updated.

* We assume that the drives are located at `/dev/nvme0n1` and `/dev/nvme1n1`, SMT has been disabled
  so you only get 4 addressable threads instead of 8. Adjust your scripts accordingly.

* To apply the Nix configuration, boot into the Hetzner recovery image (use Hetzner Robot to do that)
  and run `nix run github:nix-community/nixos-anywhere -- --flake ./nix#salmon root@[ip-addr-here]`.
  Yes, you will need to install Nix on your local system for this to work. macOS users should use
  Determinate Systems' Nix ([source](https://docs.determinate.systems/determinate-nix/)).

* When restoring this NixOS image, make sure you `passwd` `smolt` (the non-root user) because we
  **DON'T** enable the root user (no single-user mode for you) and without `passwd`, you are locked
  out of KVM and must chroot into the env using the rescue image.

* `/tmp` is not executable, this causes problems when building packages with `cargo`, make a tmpdir
  in `${HOME}` and then use `TMPDIR=/home/smolt/.tmp` (as an example) for writing calls to cargo.

* The default shell is `fish`. I like fish. 🐟

### Tunnels

We use Cloudflare Zero Trust to protect SSH. During initial setup, make sure you _don't_ close the
direct port 22 access without first confirming the portal works. You do _not_ need WARP,
`cloudflared` on the client-side is sufficient with an entry like this in `~/.ssh/config`

> [!NOTE]
> Adjust `ProxyCommand` to your install path, use `whereis cloudflared`, the path below is for Apple
> Silicon Macs.

```
Host salmon
  HostName ssh.example.com
  User username
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand /opt/homebrew/opt/cloudflared/bin/cloudflared access ssh --hostname %h
```

* Make sure the following are true
  * Your email is **allowlisted** for connecting to this application
  * If using inclusion mode, the following domains are allowlisted

    ```
    *.cloudflareaccess.com
    [ssh subdomain].[your domain name].tld
    ```

  * Bot Fight Mode is **disabled** for the associated zone (i.e. domain)
  * WebSockets is **enabled** for the associated zone
  * Browser rendering for SSH is **enabled** for the Cloudflare Zero Trust application

### PostgreSQL

* As we are using PostgreSQL 18, the expected datadir is `postgresql/18/docker`, make sure the files
  are located there. You may need to also run `ALTER DATABASE hyphen REFRESH COLLATION VERSION;` if
  moving from a host with a different `glibc` version than the container (this also affects the
  `postgres` and `template1` databases). 

### Directories

* `docker`: Stores `Dockerfile`s based on [LinuxServer.io](https://docs.linuxserver.io/general/container-customization/)
  images to ensure that we maintain proper permissions with the default user (`smolt` with PID and
  UID 1000). We use this for all images except PostgreSQL, which uses the official image ([source](https://hub.docker.com/_/postgres))
  and has the PID and UID 999, so remember to `chown -R 999:999 data/postgresql`.

* `nix`: Should be symlinked to `/etc/nixos`, NixOS configuration for Hetzner instance used for
   deployment. Assumes Intel chip without architectural mitigations for Spectre/Meltdown, 64GB RAM
   and ~900GB of _usable_ storage.

* `src`: Hosts the Hyphen monorepo with portioned copied by the containers to build binaries/dist
  needed for deploying `webui` and `hyphend`.
