# AGENTS.md — Kobold project guardrails

These rules are mandatory for automated coding agents working in this repository.

## Mission

Maintain Kobold as a **small, testable downstream policy layer on Bluefin Standard**. Prefer deleting local complexity over creating a parallel distro framework.

## Hard constraints

1. Do not replace Bluefin with Silverblue, Universal Blue common, Finpilot common stages or another base unless the user explicitly changes the architecture.
2. Do not copy `projectbluefin/common` or Bluefin internal build scripts into this repository. The parent image has already composed them.
3. Do not add a custom kernel, kernel COPR, RPM Fusion, Docker, Docker Compose, `podman-docker`, Podman Compose or DX image.
4. Do not add VS Code or Trivy to the host unless the user explicitly reverses those decisions.
5. Do not add custom DNS resolvers, forced Cloudflare/Quad9, DNS-over-TLS policy, NetworkManager resolver rewrites or a custom energy/ZRAM stack.
6. Do not remove language/accessibility packages merely for image-size reduction. Past Akatsuki pruning in this area is not precedent.
7. Do not remove CUPS, Input Remapper or Tailscale packages in v0.1. Disable their runtime activation as specified instead.
8. Do not remove `containerd` merely because its name resembles Docker. Keep it installed/inactive until a build+runtime proof shows removal is safe.
9. Do not alter or reimplement `ujust`. Upstream recipe names may still mention Bluefin.
10. Do not change Plymouth branding in v0.1.
11. Do not add Niri/Waybar/Fuzzel/Mako user dotfiles to this repository. Those belong to chezmoi.
12. Do not create an ISO, Anaconda customization, Titanoboa pipeline or installer wrapper until the OCI/QCOW2 Definition of Done is complete.
13. Do not use `rpm --nodeps` for package pruning. If a removal transaction requires core desktop/system damage, fail the build and revisit the removal.
14. Do not silently repair runtime security state from `divination`; it is read-only.

## Build rules

- Resolve `ghcr.io/ublue-os/bluefin:stable` to an immutable digest before building.
- Use `dnf5` for local RPM operations.
- Avoid partial upgrade of the inherited Bluefin package set.
- Run shell syntax/static checks and final image invariants.
- Run `bootc container lint --fatal-warnings` in the final image build.
- Treat new upstream Bluefin changes as inputs to re-evaluate, not as reasons to vendor Bluefin code.

## Security rules

- SELinux Enforcing is non-negotiable.
- System-QEMU/Quarantine must use libvirt SELinux security labeling; `security_require_confined=1` is intentional.
- Rootful Podman API socket remains masked.
- Firewalld stays enabled with a restrictive default host zone.
- Do not claim Quarantine isolation is proven solely because QEMU/KVM runs: validate the SELinux label and inspect risky XML devices.

## Review philosophy

Every local delta should be answerable in one sentence: what user requirement does it satisfy, and why is Bluefin's default insufficient for that requirement? If that answer is weak, prefer the upstream behavior.
