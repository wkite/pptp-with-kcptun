#!/bin/sh
EXTERNAL_IP=$(wget -q -t 5 -T 1 -O- ipv4.icanhazip.com || echo 'ADD_SERVER_IP')
DNS=${DNS:-8.8.4.4, 8.8.8.8}
PORT=${PORT:-51820}

CLIENT_UP="ip route | grep '^default' | awk '{print \$3}' | while read GW; do ip route add ${EXTERNAL_IP} via \$GW; done"
CLIENT_DOWN="ip route | grep '^default' | awk '{print \$3}' | while read GW; do ip route del ${EXTERNAL_IP} via \$GW; done"

cd /etc/wireguard
if [[ -d /mnt/wgkey ]]; then
  ls /mnt/wgkey | while read key; do \cp /mnt/wgkey/$key .; done
fi

if [[ ! -f server.pub ]]; then
  wg genkey | tee server.key | wg pubkey > server.pub
fi

cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat server.key)
Address = 10.192.168.254/24
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
MTU = 1420
EOF

for ID in $(seq 1 $NUM); do 
  if [[ ! -f client${ID}.pub ]]; then
    wg genkey | tee client${ID}.key | wg pubkey > client${ID}.pub
  fi
  cat << EOF >> /etc/wireguard/wg0.conf
[Peer]
PublicKey = $(cat client${ID}.pub)
AllowedIPs = 10.192.168.${ID}/32$(if [[ ${ID} = 1 ]]; then echo ', 192.168.168.0/24'; fi)
EOF

  echo "───────────────────────── WireGuard Linux Client${ID} with UDPspeeder Configure File ────────────────────────"
  cat << EOF | tee /etc/wireguard/linux.client${ID}.wg0.conf
[Interface]
PrivateKey = $(cat client${ID}.key)
Address = 10.192.168.${ID}/24
PostUp = ${CLIENT_UP}
PostUp = ip route add 0/1 dev wg0; ip route add 128/1 dev wg0
PostUp = echo "Started!"
PostDown = ${CLIENT_DOWN}
PostDown = echo "Stopped!"
DNS = ${DNS}
MTU = 1420
Table = off
[Peer]
PublicKey = $(cat server.pub)
Endpoint = ${EXTERNAL_IP}:${PORT}
AllowedIPs = 0.0.0.0/0
EOF
  echo "─────────────────────────── WireGuard Windows Client${ID} Configure File and QRCode ──────────────────────────"
  cat << EOF | tee  /etc/wireguard/mobile.client${ID}.wg0.conf
[Interface]
PrivateKey = $(cat client${ID}.key)
Address = 10.192.168.${ID}/24
DNS = ${DNS}
MTU = 1420
[Peer]
PublicKey = $(cat server.pub)
Endpoint = ${EXTERNAL_IP}:${PORT}
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1
EOF
  if [[ $EXTERNAL_IP != ADD_SERVER_IP ]]; then cat /etc/wireguard/mobile.client${ID}.wg0.conf | qrencode -o- -t UTF8; fi
done

echo "────────────────────────── WireGuard Server Configure File ────────────────────────"
cat /etc/wireguard/wg0.conf

echo "───────────────────────── Start WireGuard Server Service ──────────────────────────"
wg-quick up wg0

echo "────────────────────────────── UDPspeeder Server Log ──────────────────────────────"
while true; do
  sleep 3600
done