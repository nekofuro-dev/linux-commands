
# Config static ip

## Show current network settings
```
nmcli
```

## config static ip
```
nmcli con modify [network name] ifname [ifname] ipv4.method manual ipv4.addresses [ip address][CIDR]
```