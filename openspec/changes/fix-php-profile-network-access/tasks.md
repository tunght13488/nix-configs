# Tasks

## 1. Correct PHP template network policy

- [ ] 1.1 Remove `network.connect_port` from both PHP82 and PHP83 template profiles while retaining `DB_HOST=127.0.0.1`; verify both profiles pass `nono profile validate`.
- [ ] 1.2 Extend `home-manager/pi-box-check.sh` to assert both PHP templates omit `network.connect_port` and retain `DB_HOST=127.0.0.1`; verify with `bash home-manager/pi-box-check.sh`.
