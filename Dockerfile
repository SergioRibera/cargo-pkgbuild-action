# Using the `rust-musl-builder` as base image, instead of 
# the official Rust toolchain
#* ================== Stage 1: 🦀 Recipe =======================
FROM clux/muslrust:stable AS chef
USER root
RUN cargo install cargo-chef
WORKDIR /app

#* ===================== Stage 2: 🔨 Cache =============
FROM chef AS planner
RUN git clone --depth 1 https://github.com/SergioRibera/cargo-pkgbuild -b dev /app && \
    cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Notice that we are specifying the --target flag!
RUN cargo chef cook --release --target x86_64-unknown-linux-musl --recipe-path recipe.json

#* ===================== Stage 3: 🏗️ Build =============
COPY . .
RUN cargo build --release --target x86_64-unknown-linux-musl

#* ===================== Stage 4: ✅ Runtime =====================
FROM archlinux:latest AS runtime
# copy binary
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/cargo-aur /

# Install dependencies
RUN pacman --needed --noconfirm -Syu \
    base \
    base-devel \
    git \
    pacman-contrib \
    openssh

# Create non-root user
RUN useradd -m builder && \
    echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G wheel builder

# Make ssh directory for non-root user and add known_hosts
RUN mkdir -p /home/builder/.ssh && \
    touch /home/builder/.ssh/known_hosts

# Copy ssh_config
COPY ssh_config /home/builder/.ssh/config

# Set permissions
RUN chown -R builder:builder /home/builder/.ssh && \
    chmod 600 /home/builder/.ssh/* -R

COPY entrypoint.sh cred-helper.sh utils.sh /

# Switch to non-root user and set workdir
USER builder
WORKDIR /home/builder

ENTRYPOINT ["/entrypoint.sh"]
