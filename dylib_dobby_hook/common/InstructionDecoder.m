//
//  InstructionDecoder.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/9/20.
//

#include "InstructionDecoder.h"
#import <Foundation/Foundation.h>
#import "Logger.h"

static BOOL read_bytes(const void *addr, void *buf, size_t len) {
    if (!addr || !buf) return NO;
    memcpy(buf, addr, len);
    return YES;
}

#if __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
# define LE32(x) __builtin_bswap32(x)
#else
# define LE32(x) (x)
#endif

#pragma mark - ARM64 decoder

// Decode unconditional branch with link (BL) (top6 == 0x25) && unconditional B (opcode 0b000101, top6 == 0x05) - kept for completeness
uint64_t decode_bl_b_target_arm64(const void *instr_addr) {
    uint32_t insn = 0;
    if (!read_bytes(instr_addr, &insn, sizeof(insn))) return 0;
    insn = LE32(insn);

    uint32_t top6 = (insn >> 26) & 0x3F;
    if (top6 != 0x25 && top6 != 0x05) return 0;
    uint32_t imm26 = insn & 0x03FFFFFF;
    int64_t simm26 = ((int64_t)(imm26 << 6)) >> 6;
    int64_t offset = simm26 << 2;
    uint64_t pc = (uint64_t)instr_addr;
    return pc + offset;
}

// Decode conditional branch (B.cond) top8 == 0b01010100 (0x54)
uint64_t decode_cond_branch_target_arm64(const void *instr_addr) {
    uint32_t insn = 0;
    if (!read_bytes(instr_addr, &insn, sizeof(insn))) return 0;
    insn = LE32(insn);

    uint32_t top8 = (insn >> 24) & 0xFF;
    if (top8 != 0x54) return 0; // 0b01010100 (conditional branch)
    int32_t imm19 = (insn >> 5) & 0x7FFFF; // 19-bit immediate
    // sign-extend 19 bits
    int32_t simm19 = (imm19 << 13) >> 13;
    int64_t offset = (int64_t)simm19 << 2;
    uint64_t pc = (uint64_t)instr_addr;
    return pc + offset;
}

#pragma mark - x86_64 decoder
static uint32_t read_u32(const void *addr) {
    uint32_t v = 0;
    read_bytes(addr, &v, sizeof(v));
    return v;
}
static uint64_t read_u64(const void *addr) {
    uint64_t v = 0;
    read_bytes(addr, &v, sizeof(v));
    return v;
}

uint64_t decode_call_target_x86_64(const uint8_t *instr_addr) {
    uint8_t op = 0;
    if (!read_bytes(instr_addr, &op, 1)) return 0;

    // direct CALL rel32: E8 imm32 -> target = rip (instr+5) + imm32
    if (op == 0xE8) {
        uint32_t imm32 = read_u32(instr_addr + 1);
        int64_t disp = (int32_t)imm32;
        uint64_t rip = (uint64_t)(instr_addr + 5);
        return rip + disp;
    }

    // JMP rel32 (E9) - treat similarly
    if (op == 0xE9) {
        uint32_t imm32 = read_u32(instr_addr + 1);
        int64_t disp = (int32_t)imm32;
        uint64_t rip = (uint64_t)(instr_addr + 5);
        return rip + disp;
    }

    // FF 15 disp32 -> CALL [RIP+disp32]
    if (op == 0xFF) {
        uint8_t modrm = 0;
        if (!read_bytes(instr_addr + 1, &modrm, 1)) return 0;
        if ((modrm & 0x07) == 0x05) { // r/m == 101 -> RIP-relative disp32
            uint32_t disp32 = read_u32(instr_addr + 2);
            uint64_t mem_addr = (uint64_t)(instr_addr + 6) + (int32_t)disp32;
            uint64_t target = read_u64((void *)mem_addr);
            return target;
        }
    }

    // mov rax, imm64; jmp/call rax patterns
    uint8_t buf[12];
    if (!read_bytes(instr_addr, buf, sizeof(buf))) return 0;
    if (buf[0] == 0x48 && buf[1] == 0xB8) {
        uint64_t imm64 = read_u64(instr_addr + 2);
        if (buf[10] == 0xFF && buf[11] == 0xE0) return imm64; // jmp rax
        if (buf[10] == 0xFF && buf[11] == 0xD0) return imm64; // call rax
    }

    return 0;
}