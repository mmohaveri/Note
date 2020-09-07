# Notes on setting up a Virtual Private Network

## WireGuard

`WireGuard` is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography.
It's mission is to stablish a safe channel of communication between two parties.

- [Chained setup for WireGuard](https://www.ckn.io/blog/2017/12/28/wireguard-vpn-chained-setup/)
  - [Main Setup](https://kb.wgo.sesajad.me/server/server/)
  - [Middleman Setup](https://kb.wgo.sesajad.me/server/setup-middleware/)
- [A set of Ansible scripts that simplify the setup of a personal WireGuard and IPsec VPN](https://github.com/trailofbits/algo)

## OpenConnect

- Remember to use a valid SSL Certificate
- Use 443 port
- On iPhone you'll need to use anyconnect client, remember to acitvate `anyconnect compatibility`
- Route trafic on TCP (no-udp = true)
- Set DPD so it reconnects after detecting a bad connection (dpd = 3 & mobile-dpd = 3)
- Set DNS tunneling (tunnel-all-dns = true)
- Set dhp-param

## Shadowsucks

- shadowsocks + v2ray plugin
- shadowsocks + simple obfs
- shadowsocks + kcptun
- shadowsocksR


