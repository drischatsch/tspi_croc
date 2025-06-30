// Generated register defines for soc_ctrl

// Copyright information found in source file:
// Copyright 2024 ETH Zurich and University of Bologna

// Licensing information found in source file:
// 
// SPDX-License-Identifier: SHL-0.51

#ifndef _SOC_CTRL_REG_DEFS_
#define _SOC_CTRL_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define SOC_CTRL_PARAM_REG_WIDTH 32

// Core Boot Address
#define SOC_CTRL_BOOTADDR_REG_OFFSET 0x0

// Core Fetch Enable
#define SOC_CTRL_FETCHEN_REG_OFFSET 0x4
#define SOC_CTRL_FETCHEN_FETCHEN_BIT 0

// Core Return Status (return value, EOC)
#define SOC_CTRL_CORESTATUS_REG_OFFSET 0x8

// Core Boot Mode
#define SOC_CTRL_BOOTMODE_REG_OFFSET 0xc
#define SOC_CTRL_BOOTMODE_BOOTMODE_BIT 0

// SRAM A_DLY value
#define SOC_CTRL_SRAM_DLY_REG_OFFSET 0x10
#define SOC_CTRL_SRAM_DLY_SRAM_DLY_BIT 0

// Bootrom restarts counter
#define SOC_CTRL_RESTART_COUNTER_REG_OFFSET 0x14

// Core Boot Address After Bootrom
#define SOC_CTRL_BOOTADDR_AFTER_REG_OFFSET 0x18

// Core Boot Address After Bootrom if SD Card is attached
#define SOC_CTRL_BOOTADDR_AFTER_SD_REG_OFFSET 0x1c

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _SOC_CTRL_REG_DEFS_
// End generated register defines for soc_ctrl