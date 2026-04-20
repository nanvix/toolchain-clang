// Copyright(c) The Maintainers of Nanvix.
// Licensed under the MIT License.

// Minimal hello-world smoke test for the Clang cross-compilation toolchain.
// This file must compile successfully with:
//   clang --target=i686-nanvix --sysroot=/opt/nanvix/toolchain-gcc/i686-nanvix -o hello hello.c

int main(void) {
    return 0;
}
