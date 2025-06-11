# OpenVPN to AmneziaWG Docker Server

This is a Docker image for three OpenVPN servers (with TLS, without TLS, and without TLS with password-only authentication) that
redirect their traffic to a built-in client for AmneziaWG or XRay. This allows you to establish an OpenVPN connection even in
locations where the OpenVPN protocol does not work for some reason, but your devices are not configured to use other protocols.

**Amnezia VPN (along with the kernel module) must be installed on the Docker host machine**. Moreover, to use `install.sh`, you
must have Ubuntu. Fortunately, **the Docker host can be a virtual machine**, such as VirtualBox.

I also suggest reviewing [my repository](https://github.com/nokitakaze/AmneziaVPNDockerServer), where the Amnezia VPN Server is
deployed using Docker.

The image uses the latest Ubuntu LTS at the moment — 24.04.

## Installation

1. Download the [Amnezia VPN client](https://amnezia.org/downloads), which will install all the necessary packages on the prepared
   server. This will be needed later.
2. Generate AmneziaWG or XRay file configuration (described below)
3. Create the future container with git (described below)
4. Run `install.sh` on your host machine
5. Edit `docker-compose.yml` (described below)
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

### Generate XRay file configuration

Described for the Android version of the application.

1. In your Amnezia application ( https://amnezia.org/downloads ), click the "Share" button (three
   hollow dots connected by two lines forming a triangle). Naturally, you must already have root access to the server with
   AmneziaWG.
2. Select the "Connection" tab (selected by default).
3. Enter the desired username, choose your server, set Protocol = XRay. Connection format: "**XRay native format**".
4. Click "Share" and wait 5–10 seconds.
5. On the page "Connection to XXXX", click "Share connection settings" and you will receive a text similar to the one below.

```json
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "log": {
    "loglevel": "error"
  },
  .
  .
  .
}
```

Copy it into the `xray-client.conf` file.

### Clean docker image build

Clone this git

```sh
git clone https://github.com/nokitakaze/OVPN2AmneziaWG
cd OVPN2AmneziaWG
docker-compose build
```

### Edit docker-compose.yml

You need to replace 192.168.1.2 in all client instances in the docker-compose.yml file with the IP address through which your
clients will connect to this server.

Since I am running the container in a VirtualBox machine with the network adapter set to "Bridged Adapter" mode, the main IP
address of my virtual machine is in the 192.168.1.0/24 network, along with all my devices, including the router, computers,
smartphones, Nintendo Switch, Oculus Quest headset, and others.

In my case, the IP address in Docker indeed belongs to the 192.168.1.0/24 network.

#### XRay client

If you intend to use XRay as the intermediate layer instead of AmneziaWG, additional actions are required. Comment out the first
`amneziawg_client` block, which builds from the `amneziawg-client` directory, and remove the comment from the second
`amneziawg_client` block, which builds from the `sing-box-client` directory.

Ignore the fact that you are inserting an XRay configuration while the application is Sing-Box and their formats differ. The code
inside the container will automatically generate a new configuration for Sing-Box using your file as a template.

When switching the intermediate layer between AmneziaWG and XRay, remember to execute `docker-compose build` again.

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

## OpenVPN clients with only passwords
Some OpenVPN clients support only password-based login without certificates. For example, Mikrotik routers. To allow such clients to connect to your server:

1. Uncomment the `openvpn_server_no_tls_pass` block in `docker-compose.yml`
2. Add usernames and passwords to the `psw-file` in the format `YOUR_LOGIN:YOUR_PASSWORD`

Settings for Mikrotik
PPP → "Interface" tab → Add New → OVPN Client

```
Connect To: 192.168.1.2 (Your server's IP, same as in docker-compose.yml)
Port: 1196 (Change if you modified it in docker-compose.yml)
Mode: IP
Protocol: tcp
User: mikrotik (Replace with the value from your psw-file)
Password: mikrotik
Certificate: none
Verify Server Certificate: [unchecked]
TLS Version: any
Auth: null
Cipher: aes 256 gcm
Use Peer DNS: yes
Add Default Route: [unchecked]
Don't Add Pushed Routes (route-nopull): [checked]
```

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
