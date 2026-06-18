//
//  common_ret.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/9.
//

#ifndef common_ret_h
#define common_ret_h
#include <sys/types.h>
#include <stdio.h>

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#if TARGET_OS_OSX
#include <sys/ptrace.h>
#include <libproc.h>
#include <mach/i386/thread_status.h>

#endif
#import <objc/message.h>
#import "common_ret.h"
#include <sys/xattr.h>
#import <CommonCrypto/CommonCrypto.h>
#import "EncryptionUtils.h"
#import <sys/sysctl.h>
#include <dlfcn.h>
#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#include <sys/ioctl.h>
#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/mach_types.h>

#if !defined(_DYLD_INTERPOSING_H_)
#define _DYLD_INTERPOSING_H_

/*
 *  Example:
 *  static int hk_open(const char* path, int flags, mode_t mode)
 *  {
 *    int value;
 *    // do stuff before open (including changing the arguments)
 *    value = open(path, flags, mode);
 *    // do stuff after open (including changing the return value(s))
 *    return value;
 *  }
 *  DYLD_INTERPOSE(hk_open, open)
 */

#define DYLD_INTERPOSE(_replacement, _replacee)        \
    __attribute__((used)) static struct {              \
        const void* replacement;                       \
        const void* replacee;                          \
    } _interpose_##_replacee                           \
        __attribute__((section("__DATA,__interpose"))) \
        = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };

#endif


//#ifdef __arm64__
//    #define SAVE_SWIFT_CONTEXT uint64_t swift_context; \
//                         asm volatile ("mov %0, x8":"=r"(swift_context));
//    #define LOAD_SWIFT_CONTEXT asm volatile ("mov x8, %0"::"r"(swift_context):"x8");
//#elif __x86_64__
//    #define SAVE_SWIFT_CONTEXT uint64_t swift_context; \
//                         asm volatile ("mov %%rax, %0":"=r"(swift_context));
//    #define LOAD_SWIFT_CONTEXT asm volatile ("mov %0, %%rax"::"r"(swift_context):"%rax");
//#endif

#pragma mark - Swift Interop Calling Convention Attributes

// swift_cc.h
// Swift Calling Convention Attributes (ARM64)
//
// 官方文档:
//   [1] swiftlang/swift — docs/ABI/CallingConventionSummary.rst
//       https://github.com/swiftlang/swift/blob/main/docs/ABI/CallingConventionSummary.rst
//   [2] Clang Attribute Reference — swiftcall / swift_indirect_result / swift_error_result
//       https://clang.llvm.org/docs/AttributeReference.html#swiftcall
//   [3] LLVM AArch64CallingConvention.td（后端寄存器分配实现）
//       https://github.com/llvm/llvm-project/blob/main/llvm/lib/Target/AArch64/AArch64CallingConvention.td
//       CCIfSRet   → X8   (indirect result)
//       CCIfSwiftSelf  → X20  (self/context)
//       CCIfSwiftError → X21  (error)
//   [4] swiftlang/swift — docs/ABI/CallingConvention.rst（完整规范）
//       https://github.com/swiftlang/swift/blob/main/docs/ABI/CallingConvention.rst

// ============================================================================
// SWIFTCALL
// ============================================================================
// Swift 标准同步调用约定（对应 Swift 普通函数/方法）。
//
// ARM64 寄存器分配 [1][2]:
//   X0–X7   整数/指针参数（最多 8 个）及整数返回值
//   V0–V7   浮点/SIMD 参数及浮点返回值
//   X8      indirect result 指针（见 SWIFT_INDIRECT_RESULT）
//   X20     self / closure context（见 SWIFT_CONTEXT）
//   X21     error 返回（见 SWIFT_ERROR_RESULT）
//
// Swift 源码示例（正向）:
//   func add(_ a: Int, _ b: Int) -> Int { a + b }
//   // 编译后：X0 = a, X1 = b, 返回值写入 X0
//
// 逆向识别（ARM64 汇编特征）:
//   - 函数以 "ret" 结尾（区别于 async 的 "br x0"）
//   - X0–X7 承载入参，X0 承载返回值
//   - X20 被直接解引用但从未在函数内赋值 → 说明它是 swiftself（self）
//
// Clang 文档 [2]:
//   "The swiftcall attribute indicates that a function should be called
//    using the Swift calling convention. Lowering occurs in two phases:
//    high-level (classify direct/indirect, assign context/error) and
//    low-level (assign registers/stack). This attribute handles only
//    the low-level phase."
#define SWIFTCALL __attribute__((swiftcall))


// ============================================================================
// SWIFTASYNCCALL
// ============================================================================
// Swift 异步调用约定（对应 Swift async 函数）。
//
// ARM64 寄存器分配 [1]:
//   X22     AsyncContext* —— 贯穿整个异步调用链的上下文指针，
//           由调用方写入，callee-saved（callee 不得破坏）
//   X20     actor self（isolated async 方法，见 SWIFT_CONTEXT）
//
// 两条关键规则 [1][4]:
//   1. 返回类型必须为 void。
//      async 函数不通过 X0 返回结果，而是将结果写入 AsyncContext，
//      再尾调用（musttail）continuation 函数。
//   2. Suspend point 处执行 musttail call（ARM64 为 "br x0"，非 "bl"），
//      实现协作式调度，避免栈增长。
//      注意：这不是"整个函数保证 TCO"，而是 suspend point 处的跳转保证。
//
// Swift 源码示例（正向）:
//   func fetchData() async -> Data { ... await URLSession... }
//   // 编译器将函数拆成多段 partial function，每段以 musttail 结尾
//
// 逆向识别（ARM64 汇编特征）:
//   - 函数体内出现 "ldr x0, [x22]; br x0"（读 resumeFn 并跳转）
//     而不是普通 "ret"
//   - X22 被频繁读写（存储/恢复局部变量到 AsyncContext）
//   - 符号 demangle 后含 "YaF" 或 "YaKF"（async / async throws）
//
// Frida hook 示例（逆向）:
//   Interceptor.attach(asyncFuncAddr, {
//     onEnter(args) {
//       // x22 = AsyncContext*，通过 this.context.x22 访问
//       // x20 = actor self（如果是 actor 方法）
//       const ctx = this.context.x22;
//       const resumeFn = ctx.readPointer();  // AsyncContext 首字段
//       console.log('async ctx:', ctx, 'resumeFn:', resumeFn);
//     }
//   });
#define SWIFTASYNCCALL __attribute__((swiftasynccall))


// ============================================================================
// SWIFT_INDIRECT_RESULT
// ============================================================================
// 标记一个参数为"间接返回缓冲区指针"（large struct / tuple 输出）。
//
// ARM64 寄存器分配 [2][3]:
//   X8   —— AArch64 AAPCS sret 寄存器，callee 直接写入 [X8+...]
//           来源: AArch64CallingConvention.td:
//             CCIfSRet<CCIfType<[i64], CCAssignToRegWithShadow<[X8], [W8]>>>
//
// 触发条件（高层降级规则）[2][4]:
//   结构体/元组无法被分解到 ≤4 个整数寄存器 + ≤4 个浮点寄存器时，走 indirect。
//   ⚠️ 不是简单的"大于 16 字节"：
//      struct { Int; Int }   = 16 B → 直接返回（X0, X1）
//      struct { Int×5 }      = 40 B → indirect（X8）
//
// 约束 [2]:
//   - 参数类型必须是 T* 或 T&
//   - 必须是第一个参数，或紧跟在另一个 SWIFT_INDIRECT_RESULT 参数之后
//   - 若低层降级强制某直接返回值走 indirect，优先级高于本属性
//
// Swift 源码示例（正向）:
//   struct BigPoint { var x, y, z, w, v: Double }  // 40 bytes
//   func origin() -> BigPoint { BigPoint(x:0,y:0,z:0,w:0,v:0) }
//   // 编译后: X8 = 调用方预留的 40 字节缓冲地址，callee 写入后 ret
//
// 等价 C 签名（体现属性）:
//   void origin(BigPoint * __attribute__((swift_indirect_result)) out);
//
// 逆向识别（ARM64 汇编特征）:
//   - 函数开头 X8 立即被用作写目标（stp/str 到 [x8]/[x8+N]）
//   - 函数返回类型在 IR 层为 void（结果已通过 X8 传出）
//   - LLDB: "register read x8" 在 onEnter 时值为调用方栈/堆地址
#define SWIFT_INDIRECT_RESULT __attribute__((swift_indirect_result))


// ============================================================================
// SWIFT_CONTEXT
// ============================================================================
// 标记"self / closure capture list"参数，使用 callee-saved 寄存器传递。
//
// ARM64 寄存器分配 [1][3]:
//   X20   —— swiftself，callee-saved（整个调用链中 self 指针稳定）
//            来源: AArch64CallingConvention.td:
//              CCIfSwiftSelf<CCIfType<[i64], CCAssignToRegWithShadow<[X20],[W20]>>>
//
// 用途 [2]:
//   1. 实例方法的 self（类/结构体/枚举）
//   2. 闭包的 capture context 指针
//   3. async 方法的 actor self（与 SWIFT_ASYNC_CONTEXT 同时出现时：
//      X20 = actor self，X22 = AsyncContext）
//
// Swift 源码示例（正向）:
//   class Foo {
//     var value = 42
//     func bar() -> Int { value }   // self -> X20
//   }
//
// 等价 C 签名（体现属性）:
//   int bar(Foo * __attribute__((swift_context)) self);
//
// 逆向识别（ARM64 汇编特征）:
//   - X20 在函数 prologue 被存入栈帧（stp ...x20...），
//     在 epilogue 恢复（ldp ...x20...）→ callee-saved 行为
//   - X20 直接解引用加载成员字段，无需事先移动到其他寄存器
//   - Ghidra/IDA 若不识别 swiftself，会把 X20 误标为"未使用的 callee-saved"
//
// LLDB 验证:
//   (lldb) register read x20
//   x20 = 0x0000600003f04180  ; Foo* self
//   (lldb) memory read --size 8 --format d --count 1 0x600003f04180+<field_offset>
//   42                         ; self.value
#define SWIFT_CONTEXT __attribute__((swift_context))


// ============================================================================
// SWIFT_ASYNC_CONTEXT
// ============================================================================
// 标记 async 函数的"续体上下文"参数（AsyncContext*）。
//
// ARM64 寄存器分配 [1]:
//   X22   —— async context，callee-saved
//            ARM64 寄存器表（CallingConventionSummary.rst）:
//              Register X22 | Purpose: Async context | Swift: ✓
//
// AsyncContext 内存布局（简化）[4]:
//   offset 0:  void* resumeFn        // 下一个 continuation 函数指针
//   offset 8:  AsyncContext* parent  // 父任务上下文（用于 await 链）
//   offset 16: ... 局部变量存储区 ...  // 编译器按需分配
//
// 约束 [2]:
//   - 仅在 SWIFTASYNCCALL 函数上有效
//   - 参数类型为 AsyncContext*（或其子类型指针）
//
// Swift 源码示例（正向）:
//   func doWork() async { ... }
//   // 编译器生成伪签名:
//   //   __attribute__((swiftasynccall))
//   //   void doWork(AsyncContext * __attribute__((swift_async_context)) ctx);
//
// 逆向识别（ARM64 汇编特征）:
//   - X22 在 suspend point 前将局部变量存入 [x22 + N]（保存到 heap task）
//   - X22 在 resume 入口处从 [x22 + N] 恢复局部变量
//   - 函数结束时: "ldr x0, [x22]; br x0"（读 resumeFn，尾跳）
//
// LLDB 验证（async 函数断点）:
//   (lldb) register read x22
//   x22 = 0x00006000027c4080   ; AsyncContext*
//   (lldb) memory read --size 8 --format x --count 4 0x6000027c4080
//   0x6000027c4080: 0x0001a3f8c00  ; resumeFn（下一段 partial function 地址）
//   0x6000027c4088: 0x0001a3f8d00  ; parent context
//   ...
#define SWIFT_ASYNC_CONTEXT __attribute__((swift_async_context))


// ============================================================================
// SWIFT_ERROR_RESULT
// ============================================================================
// 标记 Swift throws 函数的隐式错误输出参数。
//
// ARM64 寄存器分配 [1][3]:
//   X21   —— swift error，callee-saved
//            来源: AArch64CallingConvention.td:
//              CCIfSwiftError<CCIfType<[i64], CCAssignToRegWithShadow<[X21],[W21]>>>
//
// ABI 语义（"假装是可寻址内存"）[2]:
//   调用方（caller）:
//     在栈上开一个 Error? 槽位（8 字节），初始化为 0（nil）。
//     将槽位地址写入 X21，然后 bl 目标函数。
//     函数返回后读 X21 所指内存：非零 → 有错误。
//   被调方（callee）:
//     函数入口时 X21 实际指向 callee 自己栈上的一个隐藏槽位，
//     该槽位已被初始化为 X21 入参的值（即 caller 传来的错误指针）。
//     throw 路径：把 Error* 写入 [X21]，然后 ret。
//     正常路径：不修改 [X21]，ret。
//
// 约束 [2]:
//   - 必须是参数列表中的最后一个参数
//   - 前面必须紧接一个 SWIFT_CONTEXT 参数
//   - 参数类型必须是 T** 或 T*&
//
// Swift 源码示例（正向）:
//   enum Err: Error { case bad }
//   func risky() throws -> Int {
//     throw Err.bad       // → 写 Error* 到 [X21]，ret
//     // return 1         // → 不动 [X21]，X0 = 1，ret
//   }
//
// 等价 C 签名（体现属性）:
//   int risky(
//     void * __attribute__((swift_context))      ctx,   // X20（哪怕是自由函数也需占位）
//     swift_error ** __attribute__((swift_error_result)) err  // X21
//   );
//
// 逆向识别（ARM64 汇编特征）:
//   - throw 路径：出现 "str xN, [x21]"（把 Error* 写入 X21 所指槽位）
//   - 正常路径：X21 所指内存保持 0，结果在 X0 返回
//   - 符号 demangle 后含 "KF"（throws）→ 必然有 X21
//   - 调用方在 bl 之后通常有：
//       ldr  x8, [sp, #err_slot_offset]
//       cbnz x8, .throw_handler          ; 检查 error
//
// LLDB 验证（throws 函数）:
//   (lldb) register read x21
//   x21 = 0x000000016fdfe8e0   ; &Error? slot（调用方栈地址）
//   ; 执行完毕后：
//   (lldb) memory read --size 8 --format x --count 1 0x16fdfe8e0
//   0x16fdfe8e0: 0x0000000000000000   ; nil → 无错误
//   ; 或：
//   0x16fdfe8e0: 0x0000600001a04100   ; 非零 → Error 对象地址
//
// Frida hook 示例（逆向）:
//   Interceptor.attach(riskyAddr, {
//     onEnter(args) {
//       this.errSlot = this.context.x21;  // 保存 X21（Error** 地址）
//     },
//     onLeave(retval) {
//       const errPtr = this.errSlot.readPointer();
//       if (!errPtr.isNull())
//         console.log('threw:', errPtr);  // errPtr 即 Swift Error 对象
//       else
//         console.log('ok, ret =', retval.toInt32());
//     }
//   });
#define SWIFT_ERROR_RESULT __attribute__((swift_error_result))



int ret2 (void);
int ret1 (void);
int ret0 (void);
void ret(void);

void unload_self(void);

void printStackTrace(void);

void dumpReg(void);

// AntiAntiDebug 反反调试相关
typedef int (*PtraceFuncPtr)(int _request, pid_t _pid, caddr_t _addr, int _data);
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);
extern PtraceFuncPtr orig_ptrace;


typedef int (*SysctlFuncPtr)(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
extern SysctlFuncPtr orig_sysctl;

typedef kern_return_t (*TaskGetExceptionPortsFuncPtr)(
    task_inspect_t task,
    exception_mask_t exception_mask,
    exception_mask_array_t masks,
    mach_msg_type_number_t *masksCnt,
    exception_handler_array_t old_handlers,
    exception_behavior_array_t old_behaviors,
    exception_flavor_array_t old_flavors
    );
kern_return_t my_task_get_exception_ports
(
     task_inspect_t task,
     exception_mask_t exception_mask,
     exception_mask_array_t masks,
     mach_msg_type_number_t *masksCnt,
     exception_handler_array_t old_handlers,
     exception_behavior_array_t old_behaviors,
     exception_flavor_array_t old_flavors
 );
extern TaskGetExceptionPortsFuncPtr orig_task_get_exception_ports;


typedef kern_return_t (*TaskSwapExceptionPortsFuncPtr)(
    task_t task,
    exception_mask_t exception_mask,
    mach_port_t new_port,
    exception_behavior_t new_behavior,
    thread_state_flavor_t new_flavor,
    exception_mask_array_t old_masks,
    mach_msg_type_number_t *old_masks_count,
    exception_port_array_t old_ports,
    exception_behavior_array_t old_behaviors,
    thread_state_flavor_array_t old_flavors
    );
kern_return_t my_task_swap_exception_ports
(
     task_t task,
     exception_mask_t exception_mask,
     mach_port_t new_port,
     exception_behavior_t new_behavior,
     thread_state_flavor_t new_flavor,
     exception_mask_array_t old_masks,
     mach_msg_type_number_t *old_masks_count,
     exception_port_array_t old_ports,
     exception_behavior_array_t old_behaviors,
     thread_state_flavor_array_t old_flavors
 );
extern TaskSwapExceptionPortsFuncPtr orig_task_swap_exception_ports;

#if TARGET_OS_OSX
/// Apple Sec..
typedef OSStatus (*SecCodeCheckValidityFuncPtr)(SecCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
OSStatus hk_SecCodeCheckValidity(SecCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
extern SecCodeCheckValidityFuncPtr SecCodeCheckValidity_ori;


typedef OSStatus (*SecStaticCodeCheckValidityFuncPtr)(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
OSStatus hk_SecStaticCodeCheckValidity(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
extern SecStaticCodeCheckValidityFuncPtr SecStaticCodeCheckValidity_ori;

typedef OSStatus (*SecCodeCheckValidityWithErrorsFuncPtr)(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
OSStatus hk_SecCodeCheckValidityWithErrors(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
extern SecCodeCheckValidityWithErrorsFuncPtr SecCodeCheckValidityWithErrors_ori;

typedef OSStatus (*SecStaticCodeCheckValidityWithErrorsFuncPtr)(SecStaticCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
OSStatus hk_SecStaticCodeCheckValidityWithErrors(SecStaticCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
extern SecStaticCodeCheckValidityWithErrorsFuncPtr SecStaticCodeCheckValidityWithErrors_ori;


extern const char* G_TEAM_IDENTITY_ORI;
typedef OSStatus (*SecCodeCopySigningInformationFuncPtr)(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo);
OSStatus hk_SecCodeCopySigningInformation(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo);
extern SecCodeCopySigningInformationFuncPtr SecCodeCopySigningInformation_ori;



/// KeyChain
/**
 * Fallbacks for SecItem APIs using SecKeychain due to code signature issues.
 * - hk_SecItemAdd: Adds a password.
 * - hk_SecItemUpdate: Updates a password.
 * - hk_SecItemDelete: Deletes an item.
 * - hk_SecItemCopyMatching: Retrieves an item.
 */
typedef OSStatus (*SecItemAddFuncPtr)(CFDictionaryRef attributes, CFTypeRef *result);
extern SecItemAddFuncPtr SecItemAdd_ori;
OSStatus hk_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result);
typedef OSStatus (*SecItemUpdateFuncPtr)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
extern SecItemUpdateFuncPtr SecItemUpdate_ori;
OSStatus hk_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
typedef OSStatus (*SecItemDeleteFuncPtr)(CFDictionaryRef query);
extern SecItemDeleteFuncPtr SecItemDelete_ori;
OSStatus hk_SecItemDelete(CFDictionaryRef query);
typedef OSStatus (*SecItemCopyMatchingFuncPtr)(CFDictionaryRef query, CFTypeRef *result);
extern SecItemCopyMatchingFuncPtr SecItemCopyMatching_ori;
OSStatus hk_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);
#endif




NSString *love69(NSString *input);


#endif /* common_ret_h */
