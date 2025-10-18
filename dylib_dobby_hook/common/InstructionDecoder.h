//
//  InstructionDecoder.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/9/20.
//

#ifndef InstructionDecoder_h
#define InstructionDecoder_h

#import <Foundation/Foundation.h>

#pragma mark - ARM64 decoder

// Decode unconditional branch with link (BL) (top6 == 0x25) && unconditional B (opcode 0b000101, top6 == 0x05) - kept for completeness
uint64_t decode_bl_b_target_arm64(const void *instr_addr);

// Decode conditional branch (B.cond) top8 == 0b01010100 (0x54)
uint64_t decode_cond_branch_target_arm64(const void *instr_addr);

#pragma mark - x86_64 decoder

uint64_t decode_call_target_x86_64(const uint8_t *instr_addr);

#endif