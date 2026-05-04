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
#
# Named stages allow caching intermediate builds independently:
#   docker build --target newlib-build ...   # cache base layers
#   docker build ...                         # full image, reuses base cache
# =============================================================================

# ---------------------------------------------------------------------------
# deps: base image with all build dependencies
# ---------------------------------------------------------------------------
FROM ubuntu:24.04 AS deps

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

ENV PREFIX=/opt/nanvix/toolchain-clang
ENV TARGET=i686-nanvix
ENV PATH="${PREFIX}/bin:${PATH}"

WORKDIR /build

# ---------------------------------------------------------------------------
# binutils-build: Binutils for the target
# ---------------------------------------------------------------------------
FROM deps AS binutils-build

# Pinned commits for each component.
# NOTE: These point to feature branches with staged build support.
# Update to dev/main branch commits after upstream PRs merge.
ARG BINUTILS_COMMIT=6e8a153968cbfb47f8a3d52851bffa01b205cdb5

RUN git clone https://github.com/nanvix/binutils /build/binutils && \
    cd /build/binutils && git checkout ${BINUTILS_COMMIT}

RUN cd /build/binutils && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# ---------------------------------------------------------------------------
# llvm-stage0-build: Clang + LLD cross-compiler (no runtimes)
# ---------------------------------------------------------------------------
FROM binutils-build AS llvm-stage0-build

ARG LLVM_COMMIT=f97b1b7f56811accb963c076e59231eb29bc6761

RUN git clone https://github.com/nanvix/llvm-project /build/llvm-project && \
    cd /build/llvm-project && git checkout ${LLVM_COMMIT}

RUN cd /build/llvm-project && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# ---------------------------------------------------------------------------
# newlib-build: C library for the target (auto-detects Clang)
# ---------------------------------------------------------------------------
FROM llvm-stage0-build AS newlib-build

ARG NEWLIB_COMMIT=fee0541f8643d7172b67aa968fbf4d8f7f1178a4

RUN git clone https://github.com/nanvix/newlib /build/newlib && \
    cd /build/newlib && git checkout ${NEWLIB_COMMIT}

RUN cd /build/newlib && \
    ./z configure --install-location="${PREFIX}" --stage=0 --sysroot-location="${PREFIX}" && \
    ./z build && \
    ./z install

# ---------------------------------------------------------------------------
# llvm-stage1-build: compiler-rt builtins
# ---------------------------------------------------------------------------
FROM newlib-build AS llvm-stage1-build

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

COPY --from=llvm-stage1-build /opt/nanvix/toolchain-clang /opt/nanvix/toolchain-clang

ENV PATH="/opt/nanvix/toolchain-clang/bin:${PATH}"

# Smoke test.
RUN clang --version && \
    i686-nanvix-as --version && \
    i686-nanvix-ld --version

LABEL org.opencontainers.image.source="https://github.com/nanvix/toolchain-clang" \
      org.opencontainers.image.description="Nanvix LLVM/Clang cross-compilation toolchain (Binutils + Clang + Newlib) for i686-nanvix"
