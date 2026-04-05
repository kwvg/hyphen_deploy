# Disk layout for legacy BIOS using GPT partitioning
#
# - MBR is duplicated between both disks
# - /boot is mirrored using mdadm
# - The rest of the filesystem is a striped ZFS pool

{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            bios_boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            boot = {
              size = "1G";
              priority = 2;
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            bios_boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            boot = {
              size = "1G";
              priority = 2;
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
    };
    zpool = {
      # RAID0 pool
      tank = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd-4";
          checksum = "blake3";
          dedup = "blake3";
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          canmount = "off";
          mountpoint = "none";
        };
        datasets = {
          "ROOT" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "ROOT/default" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "noauto";
              mountpoint = "/";
            };
          };
          "data" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "data/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "/home";
          };
        };
      };
    };
  };
}
