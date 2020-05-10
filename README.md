# UniFi Controller in Docker

Run [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller, with MongoDB, in Docker.

## Description

This is an opinionated and easy setup of a Unifi Controller, with its database, in Docker.
This project uses host networking to make it easier to discover new devices on the local network.

## Getting started 

All you need to get started is Docker and Docker Compose. Once those are installed, you can start up the controller.

```sh
docker-compose up -d
```

You now have a Unifi Controller running! You can start configuring your network by heading over to the controller at `https://<controller_host_ip>:8443`.

> If you are running this on your laptop or desktop, then the controller is at https://localhost:8443.

## Adopting devices

Once you have followed the first initial steps, you can start adopting Ubiquiti devices on your local network. This is done in the controller's web UI and is completed by clicking the "Adopt" button.

### Troubleshooting device adoption

If "http://ubnt.something" does not resolve to the IP address of your controller, then device adopting might fail, as the device you are trying to adopt cannot reply back to your controller.
To fix this, you need to help point your new Ubiquiti devices to the right IP.

This is done by SSH-ing in to the new device and changing its config.

```sh
ssh ubnt@<device_IP>
```

Type in `ubnt` when asked for a password, unless you or the controller changed it already.
Once you have a shell inside your new device, change the inform URL so that the device can reach your controller.

```sh
mca-cli
set-inform http://<controller_host_ip>:8080/inform
```

The adoption process should now complete in the controller's web UI. If adoption still fails, then check `/var/log/messages` on your device for any hints as to why.

## Different versions of the Unifi Controller

Pass in `PKGURL` as a build-arg to Docker to change what version is setup in the 
Docker image. This works for older and newer versions, such as beta releases.

```sh
docker-compose build --build-arg PKGURL=https://dl.ubnt.com/unifi/5.6.40/unifi_sysvinit_all.deb controller
```

## Docker volumes

Below is the folder structure of `/unifi` inside the `controller` container:

- `/unifi/data` contains your UniFi configuration data.
- `/unifi/log` contains UniFi log files. Useful for debugging.
- `/unifi/cert` for any custom TLS certificates.
- `/unifi/backup` contains controller backup, if any is taken.

This volume is, by default in `docker-compose.yml`, set to be `./unifi` and will be created by Docker if it does not exist. If the folder is empty on startup, then any missing folders will be created by the startup script.

## Init scripts

You can add your own startup script inside `/init.d`. These will be run as part of the container startup script, but before the controller has started.

## Running ad-hoc scripts

If you start the `controller` image with any command, then that will be run instead of the UniFi controller. This is to help troubleshooting and debugging.

## Exposed ports

The `controller` container exposes the following ports

- `8080/tcp` for device command/control
- `8443/tcp` for web interface and API
- `8843/tcp` for HTTPS portal
- `8880/tcp` for HTTP portal
- `3478/udp` for STUN service
- `6789/tcp` for speed test (Unifi5 only)
- `10001/udp` for UBNT Discovery

See [UniFi's own documentation about which ports it uses](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used)

The `mongo` container exposes `27017` and should be blocked by a firewall to prevent other devices from accessing it.

## Cons of Docker host networking

Host networking was setup to make the UniFi Controller's web UI easier to use, but it has downsides, such as:

- MongoDB is exposed on `27017` on the host, which makes it accessible to the network. Recommended to block this with a host firewall.
- Docker Compose DNS does not work in host mode, so `mongo:127.0.0.1` is added as an `extra_hosts` directive on the `controller` service.
