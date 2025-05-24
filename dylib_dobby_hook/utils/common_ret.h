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
#include <sys/ptrace.h>
#import <objc/message.h>
#import "common_ret.h"
#include <sys/xattr.h>
#import <CommonCrypto/CommonCrypto.h>
#import "EncryptionUtils.h"
#import <sys/ptrace.h>
#import <sys/sysctl.h>
#include <dlfcn.h>
#include <libproc.h>
#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#include <sys/ioctl.h>
#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/mach_types.h>
#include <mach/i386/thread_status.h>

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

int ret2 (void);
int ret1 (void);
int ret0 (void);
void ret(void);

/**
 * Hook function and backup original.
 */
int tiny_hook_ex(void* func, void* dest, void** orig);

/**
 * Removes hook from a function, restoring original code.
 */
int tiny_unhook_ex(void* func);

void unload_self(void);

void printStackTrace(void);
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

NSString *love69(NSString *input);

int destory_inject_thread(void);

#endif /* common_ret_h */
