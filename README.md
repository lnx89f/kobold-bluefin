# Kobold

**Kobold is a curated, image-based Linux workstation built on Bluefin Standard stable.**

The project exists to answer a practical question: how far can a Linux workstation be improved without turning its maintenance into a second operating-system project?

Kobold deliberately starts from a mature, hardware-aware, bootc-native upstream and keeps its own delta small. Bluefin and Fedora continue to own the difficult platform work — kernel, hardware integration, bootc, update plumbing, power management and the wider desktop base — while Kobold concentrates on policy: a restrained GNOME desktop, optional Niri session, rootless container workflow, a deliberately split virtualization model, conservative host exposure, clear branding and a read-only system health command.

This is not an attempt to create a distribution from scratch. It is an exercise in **curation, reduction and validation**.

> **Status — v0.1 development:** OCI and QCOW2 runtime validation gates have passed. Physical-hardware validation and release automation remain separate follow-up stages. Custom ISO/installer work is outside the initial v0.1 scope.

## What Kobold is trying to optimize

A workstation is useful when it remains predictable under real work. Kobold therefore prioritizes:

- **Upstream leverage instead of downstream reinvention.** Bluefin Standard stable is the real base image.
- **A small, auditable delta.** Every host-level customization should have a clear operational reason.
- **Image-based reproducibility.** The system is produced as an OCI/bootc image rather than assembled manually after installation.
- **Security without ceremonial complexity.** SELinux stays Enforcing, firewalld is kept active with a restrictive default zone, rootful Podman activation is masked, and unnecessary host services are reduced or disabled.
- **Minimal mutable host state.** Development belongs primarily in rootless containers; personal configuration belongs in the user layer.
- **Useful defaults without locking the user in.** GNOME is the primary desktop, Niri is available as an additional session, and `chezmoi` is the preferred bridge for user-managed dotfiles.
- **Different trust levels for different VMs.** GNOME Boxes is the convenient path for ordinary workloads; virt-manager with `qemu:///system` and SELinux/sVirt is the deliberately stricter Quarantine path.
- **Upstream-compatible maintenance.** Kobold does not replace Bluefin's kernel, DNS, ZRAM or power stack with local inventions.

## Architecture

```text
Bluefin Standard stable
        │
        │  Fedora + bootc + hardware/update integration
        ▼
Kobold curated delta
        ├── GNOME as the primary desktop
        ├── Niri as an optional session
        ├── Kobold branding and identity
        ├── SELinux/firewalld-oriented host policy
        ├── Podman rootless + Distrobox
        ├── chezmoi for mutable user configuration
        ├── GNOME Boxes for common VMs
        ├── virt-manager + qemu:///system + sVirt for Quarantine
        └── divination read-only health/security inspection
```

The repository itself is built on the official [`ublue-os/image-template`](https://github.com/ublue-os/image-template) scaffold. The upstream template revision and resolved Bluefin parent used by a build are recorded so that the relationship between Kobold and its parent remains explicit.

## Curated host policy

### Desktop

GNOME remains the main session and retains the core components required for a complete desktop. Kobold removes or avoids a number of non-essential leaf applications and Bluefin-added immutable GNOME Shell extensions rather than replacing the desktop stack itself.

Niri is installed as an additional session, but its personal configuration is intentionally **not** baked into the immutable image. Niri, shell, Waybar/Fuzzel/Mako, personal GNOME extensions and similar preferences belong in user-managed configuration, preferably through `chezmoi` + Git.

### Applications

The system keeps Bluefin's Bazaar integration and adds Firefox as the only Kobold-specific Flatpak preinstall in v0.1. Additional applications are user-selected rather than treated as permanent operating-system state.

Host-native tooling is intentionally selective. Kobold keeps the tools that define the workstation and avoids turning the base image into a generic development toolbox.

### Containers

The supported container workflow is:

- Podman rootless;
- Distrobox for development environments;
- no Docker compatibility layer as a host requirement;
- no Podman Compose requirement;
- Trivy and other heavier specialist tools can be used on demand from a container/Distrobox instead of living permanently on the host.

The rootful `podman.socket` is masked by policy.

### Services

Some useful upstream payloads remain installed for compatibility but are not allowed to become background policy by accident. Examples include Tailscale, printing and Input Remapper, which are present but inactive by default. Recurring Homebrew update/upgrade timers are masked while the upstream Homebrew setup is retained for `ujust` compatibility.

Kobold also avoids maintaining its own DNS, kernel, ZRAM, power-management or USB-autosuspend stack. Those responsibilities stay with the upstream platform unless measured evidence justifies a future exception.

## Virtualization: Common and Quarantine

Kobold intentionally exposes two different virtualization paths because convenience and isolation are different goals.

### Common VMs

Use **GNOME Boxes** for normal development, distro evaluation and workloads that do not require the stricter Quarantine profile. It is the convenience-oriented path.

### Quarantine VMs

Use **virt-manager** connected to:

```text
qemu:///system
```

The system libvirt policy requires SELinux confinement:

```text
security_driver = "selinux"
security_default_confined = 1
security_require_confined = 1
```

For Quarantine guests, the intended operational profile is conservative: no shared folders, no unnecessary clipboard or drag-and-drop integration, no USB/PCI passthrough, no bridge networking by default, and no nested virtualization unless the workload actually requires it.

`divination` inspects running Quarantine guests for visible sVirt labels and flags integration devices that deserve review. It is an auditing tool, not a substitute for understanding the VM's threat model.

## Divination

Kobold includes:

```bash
divination
```

`divination` is deliberately **read-only**. It does not call `sudo`, does not invoke `pkexec`, does not silently repair configuration and does not weaken permissions in order to make its own checks easier.

It reports useful state including:

- bootc deployment visibility;
- Kobold OS identity;
- SELinux state;
- Secure Boot visibility;
- firewalld/default zone;
- non-loopback listeners;
- failed systemd units;
- rootful Podman socket policy;
- selected service/timer state;
- Bluetooth visibility;
- KVM/libvirt availability;
- Quarantine VM/sVirt observations;
- readable SELinux AVCs;
- memory, PSI and thermal summaries when available.

A warning is not automatically a vulnerability. The command distinguishes hard policy failures from conditions that require context — especially inside virtual machines where hardware, Secure Boot, Bluetooth and thermal sensors may not be visible.

## Current validation state

The current v0.1 candidate has been exercised through the official image-template migration and a fresh QCOW2 runtime test.

Validated gates include:

- static checks: **PASS**;
- Kobold image invariants: **PASS**;
- `bootc container lint --fatal-warnings`: **PASS**;
- OCI build: **PASS**;
- QCOW2 boot: **PASS**;
- GDM/GNOME: **PASS**;
- Niri session: **PASS**;
- effective hostname `kobold`: **PASS**;
- SELinux Enforcing: **PASS**;
- zero failed systemd units in the tested VM: **PASS**;
- `divination`: **0 critical findings**;
- Podman rootless: **PASS**;
- Distrobox: **PASS**;
- `chezmoi`: **PASS**;
- Flatpak policy (Bazaar + Firefox): **PASS**;
- rootful `podman.socket` masked: **PASS**;
- Tailscale/Input Remapper/CUPS inactive: **PASS**;
- `/dev/kvm` and `qemu:///system`: **PASS**;
- Quarantine SELinux confinement configuration: **PASS**.

Secure Boot, fingerprint, physical Wi-Fi/Bluetooth, battery behavior, suspension, T495 thermals and the physical AMD GPU path are hardware-validation concerns and are intentionally not inferred from a VM test.

---

# Using Kobold

## 1. Understand the release state

The installation command below uses the release image published from the canonical `main` branch to GHCR. Verify that the corresponding publication workflow completed successfully before switching.

Do not treat a development branch or an unvalidated local build as a release image.

## 2. Start from a bootc-capable system

Before switching images, inspect the system you are currently running:

```bash
sudo bootc status
```

Keep a known recovery path and your important data backed up. An image-based operating system makes rollback and reproducibility easier, but it does not replace backups.

## 3. Switch to the published Kobold image

Once a validated release is published:

```bash
sudo bootc switch ghcr.io/lnx89f/kobold-bluefin:latest
```

Reboot after the operation completes.

## 4. Verify the deployment

After booting Kobold:

```bash
hostname
getenforce
divination
sudo bootc status
```

The expected baseline is:

```text
hostname: kobold
SELinux: Enforcing
divination: no critical finding detected
bootc: Kobold image is the booted deployment
```

Warnings from `divination` should be reviewed in context rather than mechanically suppressed.

## 5. Choose your desktop session

Use **GNOME** as the default, integrated workstation session.

Niri is also installed. Select it from the GDM session chooser when you want the tiling workflow. Kobold does not impose a personal Niri configuration from `/usr`; keep that configuration in your user environment and version it with `chezmoi` if desired.

## 6. Install desktop applications

Use **Bazaar/Flatpak** for mutable desktop applications. Firefox is preinstalled by Kobold.

Inspect the current application set with:

```bash
flatpak list --app
```

Keeping optional applications outside the immutable host makes experimentation cheap and the base image easier to reason about.

## 7. Use rootless containers for development

Verify rootless Podman:

```bash
podman info --format '{{.Host.Security.Rootless}}'
```

A simple runtime test:

```bash
podman run --rm quay.io/podman/hello
```

Use Distrobox when you need a mutable development environment without turning the host into one:

```bash
distrobox create --name dev
distrobox enter dev
```

Language toolchains, experimental CLIs, scanners and project-specific dependencies should generally live there unless they are genuine workstation-level requirements.

## 8. Manage personal configuration with chezmoi

`chezmoi` is installed as the preferred user-state layer. Use it for shell configuration, Niri preferences, terminal settings and other dotfiles that should survive image changes without becoming part of the operating-system build.

This separation is intentional:

```text
bootc image   -> system policy
Flatpak       -> desktop applications
Distrobox     -> development environments
chezmoi/Git   -> personal configuration
```

Each layer has a distinct responsibility and can evolve without unnecessarily destabilizing the others.

## 9. Choose the correct virtualization path

For ordinary VMs, open **GNOME Boxes**.

For an untrusted or deliberately isolated workload, open **virt-manager**, use the `qemu:///system` connection and create a Quarantine VM without convenience integrations that cross the guest/host boundary unless they are explicitly needed.

After defining or starting Quarantine workloads, run:

```bash
divination
```

Review any VM integration warnings instead of suppressing them globally.

## 10. Let upstream handle platform updates

Kobold intentionally preserves Bluefin/Universal Blue's update integration rather than introducing an independent host updater. `ujust` remains available for upstream-supported operational recipes.

A Kobold release cycle resolves the current Bluefin `stable` parent, records the resulting digest for that candidate, builds the image, runs its gates and only then promotes the result. The recorded digest is a provenance point for a build — not a permanent freeze of Bluefin.

The intended project cadence is approximately every 15 days, or sooner when a relevant security fix, CVE or important upstream correction justifies a new candidate.

---

# Building and validating from source

Kobold uses the official Universal Blue image-template workflow rather than a custom build framework.

Clone the repository and enter it:

```bash
git clone https://github.com/lnx89f/kobold-bluefin.git
cd kobold-bluefin
```

Inspect the active branch and project decisions before changing the image:

```bash
git status
cat DECISIONS.md
cat UPSTREAM.md
```

Useful image-template commands include:

```bash
just check
just lint
just build
just build-qcow2
```

Kobold also treats its project-specific static checks, image invariants and fatal bootc lint as release gates. A successful container build alone is not considered sufficient evidence for promotion.

When testing a QCOW2, use a **copy** of the generated artifact for disposable VMs rather than attaching the canonical output artifact directly to virt-manager. This prevents VM deletion workflows from deleting the only build artifact.

---

# Engineering philosophy

Kobold is built around a simple rule: **a workstation should be boring where predictability matters and powerful where the user needs leverage**.

Bluefin is the primary technical inspiration because it demonstrates what a modern Linux workstation can look like when Fedora, bootc, container workflows, hardware enablement and desktop integration are treated as a coherent product instead of a collection of post-install scripts. Kobold respects that work by staying downstream and keeping its changes narrow.

The project's operating philosophy is also informed by lessons from **NixOS** and **Arch Linux**, without pretending to inherit their implementation models.

From NixOS comes the value of declarative thinking: state should have an owner, system configuration should be reproducible, and rebuilding should be preferable to accumulating undocumented mutations.

From Arch comes another useful discipline: know what is installed, know why it is installed, avoid unnecessary abstraction, and keep the operator close enough to the system to understand its behavior.

Kobold applies those lessons to a different foundation. Instead of maintaining an independent package universe or a bespoke distribution, it uses a curated upstream image and asks a narrower set of questions:

- Does this belong in the immutable host?
- Is upstream already solving this better?
- Can this live in Flatpak, Distrobox or user configuration instead?
- Does the security control reduce meaningful risk without creating fragile maintenance?
- Can the behavior be validated automatically?
- Is the delta small enough that another engineer can audit it later?

That is the point of the project: not maximum customization, but **controlled customization**; not novelty for its own sake, but a modern Linux workstation whose choices can be explained, reproduced and defended.

Kobold is therefore less about building another Linux distribution and more about building a disciplined Linux system: curated upstream technology, explicit policy, reproducible delivery, measured hardening and enough restraint to remain maintainable.

## Upstream and provenance

Kobold is based on [Bluefin](https://projectbluefin.io/) and uses the [Universal Blue image-template](https://github.com/ublue-os/image-template). Fedora, bootc, Universal Blue and their respective upstream projects do the foundational work that makes this project possible.

See [`DECISIONS.md`](./DECISIONS.md) for architectural decisions and [`UPSTREAM.md`](./UPSTREAM.md) for recorded upstream provenance.
