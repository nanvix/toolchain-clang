# Copyright(c) The Maintainers of Nanvix.
# Licensed under the MIT License.

# =============================================================================
# nanvix/toolchain-clang
#
# Cross-compilation toolchain: Binutils + LLVM/Clang (2-stage) + Newlib
# for i686-nanvix.
#
# Build:
#   docker build -t ghcr.io/nanvix/toolchain-clang:1.0.0 .
#
# Verify:
#   docker run --rm ghcr.io/nanvix/toolchain-clang:1.0.0 clang --version
# =============================================================================

FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        file \
        flex \
        gawk \
        git \
        libgmp-dev \
        libisl-dev \
        libmpc-dev \
        libmpfr-dev \
        m4 \
        make \
        ninja-build \
        patch \
        python3 \
        texinfo \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Pinned commits for each component.
# NOTE: These point to feature branches with staged build support.
# Update to dev/main branch commits after upstream PRs merge:
#   - nanvix/binutils#28
#   - nanvix/llvm-project#6
#   - nanvix/newlib#6
ARG BINUTILS_COMMIT=6e8a153968cbfb47f8a3d52851bffa01b205cdb5
ARG LLVM_COMMIT=bbe41f956cdfc5b1a2e8d54fc7bedf30924b7d00
ARG NEWLIB_COMMIT=fee0541f8643d7172b67aa968fbf4d8f7f1178a4

ENV PREFIX=/opt/nanvix/toolchain-clang
ENV TARGET=i686-nanvix
ENV PATH="${PREFIX}/bin:${PATH}"

WORKDIR /build

# Clone Binutils.
RUN git clone https://github.com/nanvix/binutils /build/binutils && \
    cd /build/binutils && git checkout ${BINUTILS_COMMIT}

# Clone LLVM.
RUN git clone https://github.com/nanvix/llvm-project /build/llvm-project && \
    cd /build/llvm-project && git checkout ${LLVM_COMMIT}

# Clone Newlib.
RUN git clone https://github.com/nanvix/newlib /build/newlib && \
    cd /build/newlib && git checkout ${NEWLIB_COMMIT}

# Build Binutils.
RUN cd /build/binutils && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build LLVM/Clang stage 0 (compiler + linker, no runtimes).
RUN cd /build/llvm-project && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build Newlib (C library for target, auto-detects Clang as cross-compiler).
RUN cd /build/newlib && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# Build LLVM runtimes stage 1 (compiler-rt, libunwind, libcxx, libcxxabi).
RUN cd /build/llvm-project && \
    ./z configure --install-location="${PREFIX}" --stage=1 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# =============================================================================
# Runtime stage — only the installed toolchain prefix.
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal runtime dependencies for cross-compilation.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/nanvix/toolchain-clang /opt/nanvix/toolchain-clang

ENV PATH="/opt/nanvix/toolchain-clang/bin:${PATH}"

# Smoke test.
RUN clang --version && \
    i686-nanvix-as --version && \
    i686-nanvix-ld --version

LABEL org.opencontainers.image.source="https://github.com/nanvix/toolchain-clang" \
      org.opencontainers.image.description="Nanvix LLVM/Clang cross-compilation toolchain (Binutils + Clang + Newlib) for i686-nanvix"
