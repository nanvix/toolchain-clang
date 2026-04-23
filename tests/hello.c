// Copyright(c) The Maintainers of Nanvix.
// Licensed under the MIT License.

// Minimal hello-world smoke test for the Clang cross-compilation toolchain.
// This file must compile successfully with:
//   clang --target=i686-unknown-nanvix -o hello hello.c

#include <stddef.h>

int main(void) {
    // Verify stddef.h is findable (from Newlib sysroot).
    size_t x = 0;
    (void)x;
    return 0;
}
