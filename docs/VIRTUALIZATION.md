# Virtualization profiles

Kobold intentionally exposes two different interfaces so the trust boundary is visible before a VM starts.

## Common — GNOME Boxes

Use Boxes for:

- distro testing;
- disposable development environments;
- organizational isolation;
- VMs whose guest software is trusted enough that convenience integration is acceptable.

Common VMs may use clipboard sharing, SPICE guest tools, file sharing, USB redirection, display auto-resize and snapshots. Their configuration is per-user/mutable and is not a Kobold security boundary.

## Quarantine — virt-manager / qemu:///system

The desktop entry **Quarantine Virtual Machines** executes:

```bash
virt-manager --connect qemu:///system
```

System QEMU is configured with:

```text
security_driver = "selinux"
security_default_confined = 1
security_require_confined = 1
```

The goal is to require libvirt SELinux/sVirt confinement for system-managed QEMU guests. This is materially different from relying on a per-user session alone: system libvirt can apply per-VM SELinux security labels and deny an explicitly unconfined domain.

### Quarantine policy

For an untrusted autonomous agent or unknown code, the intended default is:

- no `<filesystem>` host share;
- no `<hostdev>` PCI/USB passthrough;
- no `<redirdev>` USB redirection;
- no SPICE clipboard channel unless explicitly accepted for that VM;
- no automatic VM autostart;
- dedicated QCOW2 storage rather than a host directory share;
- NAT or isolated networking chosen deliberately for the workload;
- snapshots/checkpoints before risky runs when useful.

`divination` enumerates all `qemu:///system` domains, checks the visible SELinux label on running domains and warns about the risky XML device classes above.

### Important limitation

Kobold v0.1 does **not** claim network containment beyond normal libvirt/firewalld behavior. Strong egress filtering, host-address blocking, disposable overlay disks or per-agent network policies should be added only as a separately tested Quarantine v2 feature. This avoids pretending an unvalidated firewall recipe is stronger than it is.

## Why not Bluefin `ujust setup-vms`?

Current Bluefin's convenience recipe installs virt-manager + a QEMU Flatpak extension and configures a session URI. That is appropriate for convenient desktop virtualization, but Kobold needs system-libvirt/sVirt for the hostile-workload profile. Boxes covers the convenient side; native libvirt covers Quarantine.

## References

- libvirt QEMU driver: https://libvirt.org/drvqemu
- libvirt QEMU passthrough/security: https://libvirt.org/kbase/qemu-passthrough-security.html
- libvirt firewall/networking: https://libvirt.org/firewall.html
- GNOME Boxes help: https://gnome.pages.gitlab.gnome.org/gnome-boxes/
