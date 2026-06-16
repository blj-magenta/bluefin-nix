FROM ghcr.io/ublue-os/bluefin-dx:stable

# Create /nix as an empty mount point directory.
# Fedora 42+ composefs makes / immutable at runtime so the installer cannot
# create /nix via the old chattr -i workaround; it must exist in the image.
RUN mkdir -p /nix

# Pre-embed the Determinate Nix installer binary so first-boot Nix setup
# does not need to download the installer itself (Nix store packages are
# still fetched from the internet on first boot).
RUN ARCH=$(uname -m) && \
    curl --proto '=https' --tlsv1.2 -sSf -L \
        "https://install.determinate.systems/nix/nix-installer-${ARCH}-linux" \
        -o /usr/libexec/nix-installer && \
    chmod +x /usr/libexec/nix-installer

# Enable the first-boot installation service
COPY nix-installer-first-boot.service /etc/systemd/system/nix-installer-first-boot.service
RUN systemctl enable nix-installer-first-boot.service

