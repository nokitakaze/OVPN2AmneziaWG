# OpenVPN to AmneziaWG Docker Server

This is a Docker image for two OpenVPN servers (with and without TLS) that redirect their traffic to an integrated client for
AmneziaWG. It enables you to establish an OpenVPN connection even in locations where, for some reason, the OpenVPN protocol does
not work, but your devices are not configured for other protocols.

**Amnezia VPN (along with the kernel module) must be installed on the Docker host machine**. Moreover, to use `install.sh`, you
must have Ubuntu. Fortunately, **the Docker host can be a virtual machine**, such as VirtualBox.

I also suggest reviewing [my repository](https://github.com/nokitakaze/AmneziaVPNDockerServer), where the Amnezia VPN Server is
deployed using Docker.

The image uses the latest Ubuntu LTS at the moment — 24.04.

## Installation

1. Download the [Amnezia VPN client](https://amnezia.org/downloads), which will install all the necessary packages on the prepared
   server. This will be needed later.
2. Generate AmneziaWG file configuration (described below)
3. Create the future container with git (described below)
4. Run `install.sh` on your host machine
5. Fix `docker-compose.yml` (described below)
6. Start your container (described below)
7. Generate OVPN-files (described below)

### Generate AmneziaWG file configuration

Described for the Android version of the application.

1. In your Amnezia application ( https://amnezia.org/downloads ), click the "Share" button (three
   hollow dots connected by two lines forming a triangle). Naturally, you must already have root access to the server with
   AmneziaWG.
2. Select the "Connection" tab (selected by default).
3. Enter the desired username, choose your server, set Protocol = AmneziaWG. Connection format: "**AmneziaWG native format**".
4. Click "Share" and wait 5–10 seconds.
5. On the page with the large complex QR code, click "Share connection settings" and you will receive a text similar to the one
   below.

```
[Interface]
Address = 10.0.13.37/32
DNS = 1.1.1.1, 1.0.0.1
PrivateKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
Jc = 1234
Jmin = 1234
Jmax = 1234
S1 = 1234
S2 = 1234
H1 = 1234
H2 = 1234
H3 = 1234
H4 = 1234

[Peer]
PublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=
PresharedKey = CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = example.com:12345
PersistentKeepalive = 25
```

All fields in the "Interface" section will have different values. However, in the Peer section, the AllowedIPs and
PersistentKeepalive fields are unlikely to change.

Copy it into the `amneziawg-client.conf` file.

### Clean docker image build

Clone this git

```sh
git clone https://github.com/nokitakaze/OVPN2AmneziaWG
cd OVPN2AmneziaWG
docker-compose build
```

### Fix docker-compose.yml

You need to replace 192.168.1.2 in both instances in the docker-compose.yml file with the IP address through which your clients
will connect to this server.

Since I am running the container in a VirtualBox machine with the network adapter set to "Bridged Adapter" mode, the main IP
address of my virtual machine is in the 192.168.1.0/24 network, along with all my devices, including the router, computers,
phones, Oculus Rift headset, and others.

In my case, the IP address in Docker indeed belongs to the 192.168.1.0/24 network.

### Starting up your container

Run `start.sh` or run this:

```sh
sudo modprobe amneziawg
sudo sysctl -q net.ipv4.ip_forward=1
sudo sysctl -q net.ipv4.conf.all.src_valid_mark=1
docker-compose up -d
```

Your container will automatically generate new keys for the OpenVPN server. If you delete the files from the
openvpn-server-no-tls.conf/openvpn-server-with-tls.conf folders, it will create new ones when the container restarts.

### Generate OVPN-files

After your container started, execute this

```sh
docker exec openvpn_server_no_tls ./genclient.sh o > tls-no.ovpn
docker exec openvpn_server_with_tls ./genclient.sh o > tls-yes.ovpn
```

And use it on your standard OpenVPN client.

## License

Licensed under the Apache License.

The author of this repository is not affiliated with or endorsed by the developers of Amnezia VPN. The software provided here
includes Amnezia VPN, which operates independently of this Docker image. The author has no control over the source code or
behavior of Amnezia VPN and is not responsible for any actions or outcomes resulting from its use.

The OpenVPN server image is based on the image alekslitvinenk/openvpn ( https://github.com/dockovpn/dockovpn ) created by
Alexander Litvinenko aka [alekslitvinenk](https://github.com/alekslitvinenk).
The author of this repository is not affiliated with or endorsed by Alexander Litvinenko.

**Disclaimer of Liability**: This repository is provided "AS IS" without any warranties, express or implied, and is intended for
use at the user's own risk. Users are strongly encouraged to perform their own security and functionality review of Amnezia VPN
before deployment. By using this software, you agree that the author of this repository shall not be held liable for any damages,
loss of data, or other harm arising from the use of Amnezia VPN or any other components contained within this image.

The author of this repository uses all the included code on a separate VirtualBox guest machine, created specifically for a local
OpenVPN server, which can be accessed by devices on my home network, including my OpenWRT router and my Oculus Rift headset.
