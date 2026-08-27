# Example - VNC / Screen Sharing

This example demonstrates the PC-hosted VNC workflow added by USB Army Knife - modded.

The optional Windows companion agent provides the communication path between the device and the authorized test computer. `VncDirect` hosts the noVNC web interface directly on the PC, so the complete screen stream does not need to be relayed through the dongle.

> **For authorized testing only.** Use screen viewing and remote input exclusively on a computer you own or are explicitly authorized to administer.

## Requirements

- A supported USB Army Knife device
- A Windows test computer
- The companion agent and VncDirect installed from [`tools/README.md`](../../tools/)
- A browser connected to the same trusted network, or an authorized private VPN connection

## Setup

1. Install the companion tools on the authorized Windows test computer.
2. Review the installer, scheduled tasks and firewall configuration before running them.
3. Configure a VNC password when possible.
4. Start the agent and the VNC service.
5. Connect the device and wait for the agent to become available.

## Usage

1. Open `http://<PC-IP>:7002` in a browser.
2. Enter the configured VNC password if authentication is enabled.
3. Wait for the interface to report that the connection is ready.
4. Adjust frame rate, image quality, output resolution and scaling as needed.
5. Keep remote mouse and keyboard control disabled unless the test requires it.
6. Stop the VNC service and remove the agent when the test is complete.

## Troubleshooting

- If the page does not connect, verify that the agent and VncDirect are running.
- Confirm that TCP port `7002` is reachable from the authorized browser.
- Refresh the page once after startup if the browser has not loaded all noVNC assets.
- Reduce frame rate or image quality if the screen updates slowly.
- Confirm that the device is using the expected USB VID/PID and that the agent command-line parameters match the device.

## Network and security notes

- Do not expose port `7002` directly to the public internet.
- Use a trusted local network or an authenticated private VPN such as Tailscale for remote access.
- Treat screen data, keyboard input and mouse input as sensitive information.
- Disable autostart and uninstall the companion tools after a temporary test.
