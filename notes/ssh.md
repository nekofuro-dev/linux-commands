# Install ssh

## Method 1: Manually
```
mkdir -p ~/.ssh
echo [public_key_string] >> ~/.ssh/authorized_keys
```

## Method 2: ssh-copy-id
```
ssh-copy-id -i ~/.ssh/id_rsa.pub [username]@[host]
```
---

# ssh port forwarding tunnel

```
ssh -L [local_port]:[remote_host][remote_port] [username]@[ssh_host]
```

e.g.
```
ssh -L 8001:vm7:8001 root@vm7
```

# Disable ssh password login

edit `/etc/ssh/sshd_config`
```
PasswordAuthentication no
```