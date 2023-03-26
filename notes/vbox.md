# Install VBox guest Additions

## Install dependencies
```
dnf install dkms kernel-devel gcc bzip2 make curl
```
## check kernel version
```
uname -r
rpm -qa kernel-devel
```

## mount cd

```
mkdir /mnt/cdrom
mount /dev/sr0 /mnt/cdrom
```