# Using the `rust-musl-builder` as base image, instead of 
# the official Rust toolchain
#* ================== Stage 1: 🦀 Recipe =======================
FROM clux/muslrust:1.75.0-stable AS builder
WORKDIR /app

#* ===================== Stage 2: 🏗️ Build =============
RUN git clone https://github.com/SergioRibera/cargo-pkgbuild -b dev /app && \
    cargo build --release --target x86_64-unknown-linux-musl

#* ===================== Stage 3: ✅ Runtime =====================
FROM archlinux:base-devel-20240101.0.204074 AS runtime
# copy binary
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/cargo-aur /

# Install dependencies
RUN pacman --needed --noconfirm -Syu \
    cargo \
    git \
    openssh

# Make ssh directory for non-root user and add known_hosts
RUN mkdir -p /root/.ssh && \
    touch /root/.ssh/known_hosts

# Copy ssh_config
COPY ssh_config /root/.ssh/config

COPY entrypoint.sh cred-helper.sh utils.sh /

ENTRYPOINT ["/entrypoint.sh"]
