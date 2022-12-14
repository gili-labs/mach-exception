//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach_fp_exceptions.c
// Created by Patrick Gili on 5/18/22.
//

#include <fenv.h>
#include "mach_fp_exceptions.h"

#if defined(__APPLE__) && defined(__MACH__)

#if defined(__arm) || defined(__arm64) || defined(__aarch64__)
#define DEFINED_ARM 1
#define FE_EXCEPT_SHIFT 8
#endif

//***
__uint64_t feenableexception(unsigned int excepts) {
    fenv_t fenv;
    __uint64_t new_excepts = excepts & FE_ALL_EXCEPT;
    __uint64_t old_excepts;
    
    if (fegetenv(&fenv)) {
        return -1;
    }
    
#if (DEFINED_ARM==1)
    old_excepts = fenv.__fpcr;
    fenv.__fpcr |= new_excepts << FE_EXCEPT_SHIFT;
#else
    old_excepts = fenv.__control & FE_ALL_EXCEPT;
    fenv.__control &= ~new_excepts;
    fenv.__mxcsr &= ~(new_excepts << 7);
#endif
    return fesetenv(&fenv) ? -1 : old_excepts;
}

__uint64_t fedisableexception(unsigned int excepts) {
    fenv_t fenv;
    __uint64_t new_excepts = excepts & FE_ALL_EXCEPT;
    __uint64_t old_excepts;
    
    if (fegetenv(&fenv)) {
        return -1;
    }
    
#if (DEFINED_ARM==1)
    old_excepts = fenv.__fpcr;
    fenv.__fpcr &= !(new_excepts << FE_EXCEPT_SHIFT);
#else
    old_excepts = fenv.__control & FE_ALL_EXCEPT;
    fenv.__control |= new_excepts;
    fenv.__mxcsr |= new_excepts << 7;
#endif
    return fesetenv(&fenv) ? -1 : old_excepts;
}

#endif
