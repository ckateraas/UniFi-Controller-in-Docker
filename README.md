# UniFi Controller in Docker

Script to setup [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller, with MongoDB, on Ubuntu 20.10.

## Description

Run the `on-host.sh` script on the host you want to setup Unifi on.

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
