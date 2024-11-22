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

int ret2 (void);
int ret1 (void);
int ret0 (void);
void ret(void);


// AntiAntiDebug 反反调试相关
typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);
extern ptrace_ptr_t orig_ptrace;


typedef int (*sysctl_ptr_t)(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize);
extern sysctl_ptr_t orig_sysctl;

typedef kern_return_t (*task_get_exception_ports_ptr_t)(
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
extern task_get_exception_ports_ptr_t orig_task_get_exception_ports;


typedef kern_return_t (*task_swap_exception_ports_ptr_t)(
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
extern task_swap_exception_ports_ptr_t orig_task_swap_exception_ports;



/// Apple Sec..
typedef OSStatus (*SecCodeCheckValidity_ptr_t)(SecCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
OSStatus hk_SecCodeCheckValidity(SecCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
extern SecCodeCheckValidity_ptr_t SecCodeCheckValidity_ori;


typedef OSStatus (*SecStaticCodeCheckValidity_ptr_t)(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
OSStatus hk_SecStaticCodeCheckValidity(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement);
extern SecStaticCodeCheckValidity_ptr_t SecStaticCodeCheckValidity_ori;

typedef OSStatus (*SecCodeCheckValidityWithErrors_ptr_t)(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
OSStatus hk_SecCodeCheckValidityWithErrors(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
extern SecCodeCheckValidityWithErrors_ptr_t SecCodeCheckValidityWithErrors_ori;

typedef OSStatus (*SecStaticCodeCheckValidityWithErrors_ptr_t)(SecStaticCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
OSStatus hk_SecStaticCodeCheckValidityWithErrors(SecStaticCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors);
extern SecStaticCodeCheckValidityWithErrors_ptr_t SecStaticCodeCheckValidityWithErrors_ori;


extern const char* teamIdentifier_ori;
typedef OSStatus (*SecCodeCopySigningInformation_ptr_t)(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo);
OSStatus hk_SecCodeCopySigningInformation(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo);
extern SecCodeCopySigningInformation_ptr_t SecCodeCopySigningInformation_ori;


/// KeyChain
/**
 * Fallbacks for SecItem APIs using SecKeychain due to code signature issues.
 * - hk_SecItemAdd: Adds a password.
 * - hk_SecItemUpdate: Updates a password.
 * - hk_SecItemDelete: Deletes an item.
 * - hk_SecItemCopyMatching: Retrieves an item.
 */
OSStatus hk_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result);
OSStatus hk_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
OSStatus hk_SecItemDelete(CFDictionaryRef query);
OSStatus hk_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);

NSString *love69(NSString *input);

//// 声明全局的邮件地址
//extern char *global_dylib_name;
//int inject_dylib(pid_t pid, const char *lib);

int destory_inject_thread(void);

#endif /* common_ret_h */
