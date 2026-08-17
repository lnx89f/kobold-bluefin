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
sudo bootc status
systemctl --failed
```

Expected: SELinux Enforcing, no critical `divination` findings, bootc deployment visible and no unexplained failed units.

### Desktop

At GDM, verify GNOME and Niri both appear and both start. Niri is expected to be nearly unconfigured until user dotfiles are restored.

No Bluefin-added immutable GNOME extensions should appear. User-installed extensions after first login are outside this invariant.

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

### Base virtualization gate

Confirm virt-manager is present, `qemu:///system` is reachable and the Quarantine libvirt policy requires SELinux confinement:

```text
security_driver = "selinux"
security_default_confined = 1
security_require_confined = 1
```

A defined or running Quarantine VM is not required to accept the base image/QCOW2 gate.

## Separate Quarantine runtime validation

This functional validation is required before claiming that the Quarantine workflow has been fully exercised, but it is not a blocker for the base image gate.

Open **Quarantine Virtual Machines**, create a disposable test guest under `qemu:///system`, boot it and rerun:

```bash
divination
```

The running VM must expose an SELinux/sVirt security label. If the VM uses host filesystem sharing, host-device passthrough, USB redirection or SPICE clipboard integration, `divination` should warn.

## Separate physical hardware validation

Validate the following on physical hardware rather than inferring them from QCOW2:

- Secure Boot;
- Wi-Fi hardware;
- physical Bluetooth, including its default-off state and GNOME toggle;
- fingerprint;
- audio;
- brightness;
- battery behavior;
- suspend/resume;
- physical AMD GPU path;
- T495 temperature;
- idle power.

Kobold does not ship resolver overrides: DNS should behave like the Bluefin base.

## Separate performance comparison

Compare unmodified Bluefin and Kobold on the same T495/hardware, same power mode and similar session state. Record:

- idle RAM;
- sustained idle CPU;
- temperature after a fixed idle period;
- battery discharge/power draw;
- enabled/running services, timers and sockets.

Do not claim package removal alone improved performance.
