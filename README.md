# 🔪 Butcher from Hell

A Dockerized boot-to-root CTF lab. Web command injection → SSH foothold →
shadow-backup looting → hash cracking → `sudo` misconfiguration → **root**.

---

## ⚙️ Requirements

- Docker Engine 20.10+
- Docker Compose v2 (`docker compose`)

## 🚀 How to host

```bash
git clone https://github.com/<your-user>/butcher-from-hell.git
cd butcher-from-hell
docker build -t butcher .
docker run -d --name butcher_1 -p 80:80 -p 22:22 -p 21:21 butcher
```

Verify it's live:

```bash
curl -s "http://localhost/site/connection.php?cmd=id"
# uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

Stop / remove the lab (flags reset on next `up`):

```bash
docker compose down
```

## 🌐 Ports / entry points

The box runs on standard service ports:

| Port | Service | Access |
|------|---------|--------|
| 80 | HTTP | http://localhost/site/ |
| 22 | SSH | `ssh ------1@localhost` |
| 21 | FTP | `ftp localhost` |

## ⚠️ Disclaimer

This lab is **intentionally vulnerable** and intended for isolated, closed
training environments only. Do not expose it to the public internet.
