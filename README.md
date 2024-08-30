# Linux Setup Tools 

I am releasing on GitHub my Install Script set of Tools which I used to install several Operating Systems, such as:
- Debian GNU/Linux
- Proxmox VE
- Ubuntu GNU/Linux
- Linux Mint GNU/Linux
- ...

I am doing a heavy refactoring of the code, so there will be a lot of breakages and things not working (yet).

Currently my tool only support 1 or 2 disks and a fixed partition layout.

Please be patient :)

# Troubleshooting
Show what **might** be keeping your Device busy so you cannot export ZFS Pool or Reformat MDADM Devices:
```
dstat -tdD /dev/sda --zfs-zil --zfs-ar --top-io --top-io-adv
```

# Repair MDADM Boot / EFI Devices
In case a Device is "Stuck" and you end up with a Message similar to:
```
mdadm: failed to add /dev/disk/by-id/ata-CT500MX500SSD1_XXXXXXXXXXX-part2 to /dev/md2: Invalid argument
```

Follow [These Instructions](https://serverfault.com/questions/927759/rebuilding-raid-array) in order to Repair the Array.

Remove the Stuck/Stubborn Device:
```
mdadm --manage /dev/md2 -r /dev/disk/by-id/ata-CT500MX500SSD1_XXXXXXXXXXX-part2
```

Re-add the Stuck/Stubborn Device:
```
mdadm --manage /dev/md2 -a /dev/disk/by-id/ata-CT500MX500SSD1_XXXXXXXXXXX-part2
```

Watch the Resync/Resilver:
```
watch 'cat /proc/mdstat'
```
