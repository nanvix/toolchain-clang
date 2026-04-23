# nanvix/toolchain-clang

LLVM/Clang cross-compilation toolchain for Nanvix targeting `i686-nanvix`.

## Overview

This repository builds and publishes a Docker image containing a self-contained LLVM/Clang cross-compilation toolchain for Nanvix. The toolchain is built from source in four stages — Binutils → Clang (stage 0) → Newlib → LLVM runtimes (stage 1) — and is installed under `/opt/nanvix/toolchain-clang/`.

The image includes:

- `clang`, `clang++` — C/C++ cross-compilers (default target: `i686-unknown-nanvix`)
- `lld` — LLVM linker
- `i686-nanvix-as`, `i686-nanvix-ld`, `i686-nanvix-ar`, ... — GNU Binutils
- Newlib C library (`libc.a`, `libm.a`, headers)
- LLVM runtimes (`compiler-rt`, `libunwind`, `libcxx`, `libcxxabi`)

## Usage

```bash
# Pull the image.
docker pull ghcr.io/nanvix/toolchain-clang:latest

# Check version.
docker run --rm ghcr.io/nanvix/toolchain-clang:latest clang --version

# Cross-compile a C program.
docker run --rm -v "$PWD:/src" ghcr.io/nanvix/toolchain-clang:latest \
    clang --target=i686-unknown-nanvix -o /tmp/hello /src/hello.c
```

## Building Locally

```bash
docker build -t ghcr.io/nanvix/toolchain-clang:local .
```

## Automated Release Chain

Releases are triggered by a cascading dispatch chain across repositories:

```
binutils ──(binutils-release)──→ llvm-project
  llvm-project(stage 0) ──(llvm-stage0-release)──→ newlib
    newlib ──(newlib-clang-release)──→ llvm-project
      llvm-project(stage 1) ──(llvm-stage1-release)──→ toolchain-clang
```

Each step builds, publishes a release tarball and Docker image, then dispatches downstream.

## Versioning

Independent semantic versioning starting at `1.0.0`. Version bumps here do **not** require a version bump in the main `nanvix/nanvix` repository.

## Pinned Upstream Commits

| Component | Repository | Commit |
|-----------|-----------|--------|
| Binutils  | [nanvix/binutils](https://github.com/nanvix/binutils) | `cce4ffc` |
| LLVM      | [nanvix/llvm-project](https://github.com/nanvix/llvm-project) | `cc6cdbf` |
| Newlib    | [nanvix/newlib](https://github.com/nanvix/newlib) | `e12d84a` |

## License

MIT — see [LICENSE.txt](LICENSE.txt).
