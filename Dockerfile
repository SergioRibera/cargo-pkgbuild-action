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
FROM alpine AS runtime
WORKDIR /app
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/cargo-aur /app/
COPY entrypoint.sh .
ENTRYPOINT ["/usr/src/entrypoint.sh"]
