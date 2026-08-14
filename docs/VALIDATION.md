# Validation

## OCI gates

The image must build successfully and pass:

```bash
bootc container lint --fatal-warnings
```

`tests/image-invariants.sh` also checks package policy, extension removal, branding, Flatpak declarations, systemd enablement and Quarantine libvirt configuration.

## QCOW2 acceptance

Boot a fresh QCOW2 with UEFI/KVM and validate the actual system rather than the build container.

### Boot/security

```bash
getenforce
divination
bootc status
systemctl --failed
```

Expected: SELinux Enforcing, no critical `divination` findings, bootc deployment visible and no unexplained failed units.

### Desktop

At GDM, verify GNOME and Niri both appear and both start. Niri is expected to be nearly unconfigured until user dotfiles are restored.

No Bluefin-added immutable GNOME extensions should appear. User-installed extensions after first login are outside this invariant.

### Hardware/network

Test Wi-Fi, suspend/resume, audio, brightness, fingerprint when exposed by hardware and Bluetooth. Bluetooth should begin off but enable normally through GNOME.

Kobold does not ship resolver overrides: DNS should behave like the Bluefin base.

### Containers

```bash
podman info --format '{{.Host.Security.Rootless}}'
distrobox --version
systemctl is-enabled podman.socket
```

Expected: rootless Podman works; rootful `podman.socket` is masked.

### Flatpaks

On a **fresh** installation, confirm Bazaar and Firefox after the upstream preinstall service has completed. A `bootc switch` on an existing installation is not a clean Flatpak test because `/var`/Flatpak state persists across deployments.

### Common VM

Open Boxes, create a disposable Linux VM and test display resize/clipboard only as a usability test. This VM is not the hostile-workload security profile.

### Quarantine VM

Open **Quarantine Virtual Machines**, create a test guest under `qemu:///system`, boot it and rerun:

```bash
divination
```

The running VM must expose an SELinux/sVirt security label. If the VM uses host filesystem sharing, host-device passthrough, USB redirection or SPICE clipboard integration, `divination` should warn.

### Runtime comparison

Compare unmodified Bluefin and Kobold on the same T495/hardware, same power mode and similar session state. Record:

- idle RAM;
- sustained idle CPU;
- temperature after a fixed idle period;
- battery discharge/power draw;
- enabled/running services, timers and sockets.

Do not claim package removal alone improved performance.
