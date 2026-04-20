# nanvix/toolchain-clang

LLVM/Clang cross-compilation toolchain for Nanvix targeting `i686-nanvix`.

## Overview

This repository builds and publishes a Docker image containing the LLVM/Clang toolchain for Nanvix. The toolchain is installed under `/opt/nanvix/toolchain-clang/` and includes:

- `clang`, `clang++` — C/C++ compilers
- `llc` — LLVM static compiler
- `llvm-ar`, `llvm-objcopy`, `llvm-objdump` — LLVM binary utilities
- `lld` — LLVM linker

## Dependencies

This toolchain depends on `nanvix/toolchain-gcc` for the newlib sysroot (headers and libraries). The Dockerfile uses a multi-stage build to pull the GCC sysroot at build time.

## Usage

```bash
# Pull the image.
docker pull ghcr.io/nanvix/toolchain-clang:1.0.0

# Check version.
docker run --rm ghcr.io/nanvix/toolchain-clang:1.0.0 clang --version
```

## Building Locally

```bash
docker build -t ghcr.io/nanvix/toolchain-clang:local .
```

## Versioning

Independent semantic versioning starting at `1.0.0`. Version bumps here do **not** require a version bump in the main `nanvix/nanvix` repository.

## Pinned Upstream Commits

| Component | Repository | Commit |
|-----------|-----------|--------|
| LLVM | [nanvix/llvm-project](https://github.com/nanvix/llvm-project) | `cc6cdbf` |

## License

MIT — see [LICENSE.txt](LICENSE.txt).
