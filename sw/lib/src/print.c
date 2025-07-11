// Copyright 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Philippe Sauter <phsauter@iis.ee.ethz.ch>
// Cedric Hirschi <cehirschi@student.ethz.ch>

#include "print.h"
#include "util.h"
#include "config.h"


void printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    while (*fmt) {
        if (*fmt == '%') {
            fmt++;
            if (*fmt == 'x') { // hex
                unsigned int hex = va_arg(args, unsigned int);
                char buffer[11];  // holds string while assembling
                unsigned int i = 0;
                
                if (hex == 0) {
                    putchar('0');
                } else {
                    while (hex > 0) {
                        buffer[i++] = (hex & 0xF) + (((hex & 0xF) <= 9) ? '0' : ('A' - 10));
                        hex >>= 4;
                    }
                    // print from stack
                    for (int j = i - 1; j >= 0; j--) {
                        putchar(buffer[j]);
                    }
                }
            } else if (*fmt == 'c') { // char
                char chr = (char) va_arg(args, int);
                putchar(chr);
            } else if (*fmt == 's') { // string
                char *str = va_arg(args, char *);
                while(*str) {
                    putchar(*str++);
                }
            }
        } else {
            putchar(*fmt);
        }
        fmt++;
    }

    va_end(args);
}