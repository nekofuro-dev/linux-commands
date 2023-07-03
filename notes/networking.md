
<h1 style="text-align: center;">
  Config static ip
</h1>

# Show current network settings

```
nmcli
```

# config static ip

```
nmcli con modify [network name] ifname [ifname] ipv4.method manual ipv4.addresses [ip address][CIDR]
```
---

<h1 style="text-align: center;">
  change nameservers
</h1>

get interface name

```
nmcli con
```

config nameservers

```
nmcli con mod $connectionName ipv4.dns "8.8.8.8 8.8.4.4"
```

restart NetworkManager
```
systemctl restart NetworkManager.service
```

verify config
```
cat /etc/resolv.conf
```

---