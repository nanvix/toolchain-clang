# Copyright(c) The Maintainers of Nanvix.
# Licensed under the MIT License.

# =============================================================================
# nanvix/toolchain-clang
#
# LLVM/Clang cross-compilation infrastructure for Nanvix.
#
# Build:
#   docker build -t ghcr.io/nanvix/toolchain-clang:1.0.0 .
#
# Verify:
#   docker run --rm ghcr.io/nanvix/toolchain-clang:1.0.0 clang --version
# =============================================================================

ARG GCC_IMAGE=ghcr.io/nanvix/toolchain-gcc:latest
FROM ${GCC_IMAGE} AS gcc-sysroot

FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        ninja-build \
        python3 \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy GCC sysroot (newlib headers/libs) needed by LLVM build.
COPY --from=gcc-sysroot /opt/nanvix/toolchain-gcc /opt/nanvix/toolchain-gcc
ENV PATH="/opt/nanvix/toolchain-gcc/bin:${PATH}"

# Pinned LLVM commit.
ARG LLVM_COMMIT=cc6cdbfb0294fcddf19e0cdcf1550898783c82ba

ENV PREFIX=/opt/nanvix/toolchain-clang

WORKDIR /build

# Clone LLVM.
RUN git clone https://github.com/nanvix/llvm-project /build/llvm-project && \
    cd /build/llvm-project && git checkout ${LLVM_COMMIT}

# Build LLVM/Clang.
RUN cd /build/llvm-project && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="/opt/nanvix/toolchain-gcc" && \
    ./z build && \
    ./z install

# =============================================================================
# Runtime stage — only the installed LLVM/Clang prefix.
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/nanvix/toolchain-clang /opt/nanvix/toolchain-clang

ENV PATH="/opt/nanvix/toolchain-clang/bin:${PATH}"

# Smoke test.
RUN clang --version

LABEL org.opencontainers.image.source="https://github.com/nanvix/toolchain-clang" \
      org.opencontainers.image.description="Nanvix LLVM/Clang cross-compilation toolchain for i686-nanvix"
