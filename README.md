# Maison Kuhn

The following components are used to implement Maison Kuhn:
- [Raspberry PI 3 Model B+](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/)
- [home assistant container](https://www.home-assistant.io/installation/odroid#install-home-assistant-container)
- [docker-swag](https://github.com/linuxserver/docker-swag)

## Installation

* Install ``RASPBERRY PI OS LIGHT (32-Bit)`` on the sdcard using [Raspberry PI imager](https://www.raspberrypi.org/software/)
* [Enable SSH connection](https://www.raspberrypi.org/documentation/remote-access/ssh/)
* Get Raspberry PI IP
  
```sh
ping raspberrypi.local
```

If you cannot ping the raspberry, you need to [disable IPv6](https://www.howtoraspberry.com/2020/04/disable-ipv6-on-raspberry-pi/)
on the raspberry. To perform this operation, you need to connect a keyboard and
a screen on you raspberry and execute the following commands:

```sh
echo "
# Disable IPv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv6.conf.eth0.disable_ipv6=1
"
reboot
```

* Connect to the Raspberry using default password(``raspberry``)

```sh
ssh pi@raspberrypi.local
```

* (optional)[Setup Wifi](https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-networking31)

```sh
cat > /etc/wpa_supplicant/wpa_supplicant.conf <<-END
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=FR

network={
        ssid="ocealize_5GHZ"
        psk=9f230eefee32a4a59c61921d0a60e4951644e749fe394b3edc8297980e0618cd
}
END
wpa_cli -i wlan0 reconfigure
```

Optional: Encrypt password using `wpa_passphrase`

* Install docker-compose

```sh
apt-get update
apt-get -y install docker-compose
```

* Setup environment variable

```bash
export DUCKDNS_TOKEN=your-duckdns-token
export DUCKDNS_DOMAIN=maison-kuhn
export HA_LATITUDE=your-latitude
export HA_LONGITUDE=your-longitude
export HA_ELEVATION=your-elevation
```

* (optional) Setup dev environment variable

```bash
export DUCKDNS_DOMAIN=maison-kuhn-dev
```

* Run docker-compose

```bash
git clone https://github.com/terrydervaux/maison-kuhn.git
cd maison-kuhn
docker-compose up 
```

* Setup static IP on the Router (eg: SFR BOX)

* Create a NAT rules on the Routeur to forward the internet trafic(External Port) 
  on internal services

| Service | External port | Internal port | Usage              |
| :------ | :------------ | :------------ | :----------------- |
| HTTPS   | 8123          | 8123          | HA incoming trafic |
| HTTPS   | 443           | 443           | SWAG trafic        |

## Troubleshooting

### Wake on LAN

Verify that the magic packet is broadcasted on the LAN

```bash
tcpdump -UlnXi eth0 ether proto 0x0842 or udp port 9 2>/dev/null |
sed -nE 's/^.*20:  (ffff|.... ....) (..)(..) (..)(..) (..)(..).*$/\2:\3:\4:\5:\6:\7/p'
```
