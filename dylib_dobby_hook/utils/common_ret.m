//
//  common_ret.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/9.
//

#include "common_ret.h"
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "MemoryUtils.h"
#import "MockKeychain.h"
#include <mach-o/dyld.h>
#include <sys/ptrace.h>
#import <sys/sysctl.h>
#include <mach/mach_types.h>
#import <pthread.h>
#import "Logger.h"
#import <Security/Security.h>
#import <execinfo.h>

#define MAX_PATCH_SIZE 14
#define MAX_BACKUP_SIZE 128

typedef struct {
    void* func;
    size_t size;
    uint8_t* backup;
} HookBackup;

typedef struct {
    void* func;
    HookBackup* backup;
} HookEntry;

static HookEntry hook_entries[MAX_BACKUP_SIZE];
static int hook_count = 0;

int ret2 (void){
    NSLogger("ret2");
    return 2;
}
int ret1 (void){
//    uint8_t ret1Hex[6] = {0xB8, 0x01, 0x00, 0x00, 0x00, 0xC3}; // mov eax, 1; ret
//    uint8_t ret1HexARM[8] = {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; // mov x0, #1; ret
    NSLogger("ret1");
    return 1;
}
int ret0 (void){
//    uint8_t ret0Hex[3] = {0x31, 0xC0, 0xC3}; // xor eax, eax; ret
//    uint8_t ret0HexARM[8] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; // mov x0, #0; ret
    NSLogger("ret0");
    return 0;
}

void ret(void){
//    uint8_t retHex[1] = {0xC3}; // ret
//    uint8_t retHexARM[4] = {0xC0, 0x03, 0x5F, 0xD6}; // ret
    NSLogger("ret");
}

// void nop(void){
//     uint8_t nopHex[1] = {0x90}; // nop
//     uint8_t nopHexARM[4] = {0x1f,0x20,0x03,0xd5}; // nop
// }

#define MB (1ll << 20)
#define GB (1ll << 30)
int get_jump_size(void* address, void* destination)
{
    long long distance = destination > address ? destination - address : address - destination;
#ifdef __aarch64__
    return distance < 128 * MB ? 4 : 12;
#elif __x86_64__
    return distance < 2 * GB ? 5 : 14;
#endif
}

int tiny_hook_ex(void* func, void* dest, void** orig)
{
    NSLogger(@"called with func: %p, dest: %p, orig: %p", func, dest, orig);

    for (int i = 0; i < hook_count; i++)
        if (hook_entries[i].func == func) {
            NSLogger(@"Function already hooked: %p", func);
            return -1;
        }
    if (hook_count >= MAX_BACKUP_SIZE) {
        NSLogger(@"Hook backup size exceeded: %d", MAX_BACKUP_SIZE);
        return -1;
    }
    size_t size = get_jump_size(func, dest);
    if (size == 0 || size > MAX_PATCH_SIZE) {
        NSLogger(@"Invalid jmp size: %zu", size);
        return -1;
    }
    HookBackup* backup = malloc(sizeof(HookBackup));
    backup->backup = malloc(size);
    read_mem(backup->backup, func, size);
    backup->func = func;
    backup->size = size;
    if (tiny_hook(func, dest, orig) != 0) {
        NSLogger(@"Failed to hook function: %p", func);
        free(backup->backup);
        free(backup);
        return -1;
    }
    hook_entries[hook_count++] = (HookEntry) { func, backup };
    return 0;
}

int tiny_unhook_ex(void* func)
{
    NSLogger(@"called with func: %p", func);
    for (int i = 0; i < hook_count; i++) {
        if (hook_entries[i].func == func) {
            HookBackup* backup = hook_entries[i].backup;
            int ret = write_mem(func, backup->backup, backup->size);
            free(backup->backup);
            free(backup);
            --hook_count;
            if (i != hook_count) {
                hook_entries[i] = hook_entries[hook_count];
            }
            memset(&hook_entries[hook_count], 0, sizeof(HookEntry));
            return ret;
        }
    }
    NSLogger("Function not found: %p", func);
    return -1;
}


void unload_self(void)
{
    Dl_info info;
    if (dladdr((const void*)&unload_self, &info)) {
        void* handle = dlopen(info.dli_fname, RTLD_NOLOAD);
        if (handle) {
            NSLogger(@"Unloading dylib: %s", info.dli_fname);
            dlclose(handle);
        } else {
            NSLogger(@"dlopen RTLD_NOLOAD failed: %s", dlerror());
        }
    } else {
        NSLogger(@"dladdr failed");
    }
}
void printStackTrace(void) {
    void *buffer[100];
    int size = backtrace(buffer, 100);
    char** symbols = backtrace_symbols(buffer, size);
    const struct mach_header* mainHeader = _dyld_get_image_header(0);
    intptr_t mainSlide = _dyld_get_image_vmaddr_slide(0);
    uintptr_t mainBase = (uintptr_t)mainHeader + mainSlide;

    NSMutableString *stackTrace = [NSMutableString string];
    if (symbols != NULL) {
        for (int i = 0; i < size; i++) {
            [stackTrace appendFormat:@"%s\n", symbols[i]];
        }
        free(symbols);
    }
    NSLogger(@"mainBase: 0x%lx , mainSlide: 0x%lx\n%@", mainBase, mainSlide, stackTrace);
}

// hook ptrace
// 通过 ptrace 来检测当前进程是否被调试，通过检查 PT_DENY_ATTACH 标记是否被设置来判断。如果检测到该标记，说明当前进程正在被调试，可以采取相应的反调试措施。
PtraceFuncPtr orig_ptrace = NULL;
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if(_request != 31){
        // 如果请求不是 PT_DENY_ATTACH，则调用原始的 ptrace 函数
        return orig_ptrace(_request,_pid,_addr,_data);
    }
    NSLogger("[AntiAntiDebug] - ptrace request is PT_DENY_ATTACH");
    // 拒绝调试
    return 0;
}

// hook sysctl
// 通过 sysctl 去查看当前进程的信息，看有没有这个标记位即可检查当前调试状态。
SysctlFuncPtr orig_sysctl = NULL;
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize){
    int ret = orig_sysctl(name,namelen,info,infosize,newinfo,newinfosize);
    if(namelen == 4 && name[0] == 1 && name[1] == 14 && name[2] == 1){
        struct kinfo_proc *info_ptr = (struct kinfo_proc *)info;
        if(info_ptr && (info_ptr->kp_proc.p_flag & P_TRACED) != 0){
            NSLogger(@"[AntiAntiDebug] - sysctl query trace status.");
            info_ptr->kp_proc.p_flag ^= P_TRACED;
            if((info_ptr->kp_proc.p_flag & P_TRACED) == 0){
                NSLogger(@"[AntiAntiDebug] - trace status reomve success!");
            }
        }
    }
    return ret;
}

// hook task_get_exception_ports
// 通过 task_get_exception_ports 来检查当前任务的异常端口设置，以检测调试器的存在或者检查调试器是否修改了异常端口设置。如果发现异常端口被修改，可能表明调试器介入了目标进程的执行。
// some app will crash with _dyld_debugger_notification
TaskGetExceptionPortsFuncPtr orig_task_get_exception_ports = NULL;
kern_return_t my_task_get_exception_ports
(
 task_inspect_t task,
 exception_mask_t exception_mask,
 exception_mask_array_t masks,
 mach_msg_type_number_t *masksCnt,
 exception_handler_array_t old_handlers,
 exception_behavior_array_t old_behaviors,
 exception_flavor_array_t old_flavors
 ){
    kern_return_t r = orig_task_get_exception_ports(task, exception_mask, masks, masksCnt, old_handlers, old_behaviors, old_flavors);
    for (int i = 0; i < *masksCnt; i++)
    {
        if (old_handlers[i] != 0) {
            old_handlers[i] = 0;
        }
        if (old_flavors[i]  == THREAD_STATE_NONE) {
//             x86_EXCEPTION_STATE
//             x86_EXCEPTION_STATE64
//             ARM_EXCEPTION_STATE
//            #if defined(__arm64__) || defined(__aarch64__)
//            #elif defined(__x86_64__)
//            #endif
            old_flavors[i] = 9;
            NSLogger(@"[AntiAntiDebug] - my_task_get_exception_ports reset old_flavors[i]=9");
        }
    }
    return r;
}

// hook task_swap_exception_ports
// 通过 task_swap_exception_ports 来动态修改异常处理端口设置，以防止调试器对异常消息进行拦截或修改。例如，恶意软件可以将异常端口设置为自定义的端口，从而阻止调试器捕获异常消息，使调试器无法获取目标进程的状态信息。
TaskSwapExceptionPortsFuncPtr orig_task_swap_exception_ports = NULL;
kern_return_t my_task_swap_exception_ports(
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
) {
    
    // 在这里实现反反调试逻辑，例如阻止特定的异常掩码或端口
   if (exception_mask & EXC_MASK_BREAKPOINT) {
       NSLogger(@"[AntiAntiDebug] - my_task_swap_exception_ports Breakpoint exception detected, blocking task_swap_exception_ports");
       return KERN_FAILURE; // 返回错误码阻止调用
   }
   return orig_task_swap_exception_ports(task, exception_mask, new_port, new_behavior, new_flavor, old_masks, old_masks_count, old_ports, old_behaviors, old_flavors);
}



void logSecRequirement(SecRequirementRef requirement, SecCSFlags flags) {
    CFStringRef requirementString = NULL;
    if (requirement != NULL) {
        OSStatus status = SecRequirementCopyString(requirement, kSecCSDefaultFlags, &requirementString);
        if (status == errSecSuccess && requirementString != NULL) {
            NSLogger(@"flags = %d, requirement = %@", flags, requirementString);
        } else {
            NSLogger(@"Failed to copy requirement string. Error code: %d", (int)status);
        }
    } else {
        NSLogger(@"flags = %d, requirement = (null)", flags);
    }
    if (requirementString != NULL) {
        CFRelease(requirementString);
    }
}

//static void logCodePath(SecStaticCodeRef code) {
//    CFURLRef path = NULL;
//    if (SecCodeCopyPath(code, kSecCSDefaultFlags, &path) == errSecSuccess && path) {
//        CFStringRef str = CFURLGetString(path);
//        NSLogger(@"[hook] code path: %@", (__bridge NSString *)str);
//        CFRelease(path);
//    } else {
//        NSLogger(@"[hook] code path: (failed to get path)");
//    }
//}

SecCodeCheckValidityFuncPtr SecCodeCheckValidity_ori = NULL;
OSStatus hk_SecCodeCheckValidity(SecCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement) {
    NSLogger(@"flags = %d",flags);
    logSecRequirement(requirement, flags);
    return errSecSuccess;
}


SecStaticCodeCheckValidityFuncPtr SecStaticCodeCheckValidity_ori = NULL;
OSStatus hk_SecStaticCodeCheckValidity(SecStaticCodeRef staticCode, SecCSFlags flags, SecRequirementRef requirement) {
    NSLogger(@"flags = %d",flags);
    logSecRequirement(requirement, flags);
    return errSecSuccess;
}

SecCodeCheckValidityWithErrorsFuncPtr SecCodeCheckValidityWithErrors_ori = NULL;
OSStatus hk_SecCodeCheckValidityWithErrors(SecCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors) {
    OSStatus result = SecCodeCheckValidityWithErrors_ori(code, flags, requirement, errors);
    NSLogger(@"Params: code=%p, flags=0x%llx, requirement=%p, errors_ptr=%p, ori_result=%d",
             code, (uint64_t)flags, requirement, errors,result);
    // logCodePath(code);
    // logSecRequirement(requirement, flags);
    if (errors && *errors) {
        CFRelease(*errors);
        *errors = NULL;
    }
    return errSecSuccess;
}

SecStaticCodeCheckValidityWithErrorsFuncPtr SecStaticCodeCheckValidityWithErrors_ori = NULL;
OSStatus hk_SecStaticCodeCheckValidityWithErrors(SecStaticCodeRef code, SecCSFlags flags, SecRequirementRef requirement, CFErrorRef *errors) {
    OSStatus result = SecStaticCodeCheckValidityWithErrors_ori(code, flags, requirement, errors);
    NSLogger(@"Params: code=%p, flags=0x%llx, requirement=%p, errors_ptr=%p, ori_result=%d",
        code, (uint64_t)flags, requirement, errors, result);
    // logCodePath(code);
    // logSecRequirement(requirement, flags);
    if (errors && *errors) {
        CFRelease(*errors);
        *errors = NULL;
    }
    return errSecSuccess;
}

const char* G_TEAM_IDENTITY_ORI = "TBD"; // Need to define before calling
SecCodeCopySigningInformationFuncPtr SecCodeCopySigningInformation_ori = NULL;
OSStatus hk_SecCodeCopySigningInformation(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo) {

    OSStatus status = SecCodeCopySigningInformation_ori(codeRef, flags, signingInfo);
    NSLogger(@"ori status = %d",  status);
    if (status != errSecSuccess || *signingInfo == NULL) {
        NSLogger(@"[Warning] ori failed or signingInfo is NULL");
        return errSecSuccess;
    }
    CFMutableDictionaryRef fakeDict = CFDictionaryCreateMutableCopy(NULL, 0, *signingInfo);
    // NSLogger("signingInfo is %@",fakeDict);
    SInt32 number = (SInt32) 65536;
    CFNumberRef flagsVal = CFNumberCreate(NULL, kCFNumberSInt32Type, &number);
    if (flagsVal) {
        CFDictionarySetValue(fakeDict,  kSecCodeInfoFlags, flagsVal);
        CFRelease(flagsVal);
    }
    CFStringRef teamId = CFStringCreateWithCString(NULL, G_TEAM_IDENTITY_ORI, kCFStringEncodingUTF8);
    if (teamId) {
        CFDictionarySetValue(fakeDict,  kSecCodeInfoTeamIdentifier, teamId);
        CFRelease(teamId);
    }
    NSDictionary *entitlementsDict = @{
        @"com.apple.security.cs.allow-dyld-environment-variables": @0,
        @"com.apple.security.cs.allow-jit": @1,
        @"com.apple.security.cs.allow-unsigned-executable-memory": @1,
        @"com.apple.security.cs.disable-executable-page-protection": @1,
        @"com.apple.security.cs.disable-library-validation": @0,
        @"com.apple.security.get-task-allow": @1
    };
    CFDictionarySetValue(fakeDict,  kSecCodeInfoEntitlementsDict, (__bridge const void *)(entitlementsDict));

    CFRelease(*signingInfo);
    *signingInfo = fakeDict;
    
    NSLogger(@"kSecCodeInfoFlags = %@", (CFNumberRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoFlags));
    NSLogger(@"entitlementsDict = %@", (CFDictionaryRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoEntitlementsDict));
    NSLogger(@"kSecCodeInfoTeamIdentifier = %@", (CFDictionaryRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoTeamIdentifier));
    return errSecSuccess;
}



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
SecItemAddFuncPtr SecItemAdd_ori = NULL;
OSStatus hk_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    NSDictionary *attrs = (__bridge NSDictionary *)attributes;
    BOOL returnPersistentRef = [attrs[@"r_PersistentRef"] boolValue];
    NSData *persistentRef = nil;
    SecKeychainItemRef ref = NULL;
    OSStatus status = [[MockKeychain sharedStore] addItem:attrs
                                           returningRef:returnPersistentRef ? NULL : &ref
                                         persistentRef:returnPersistentRef ? &persistentRef : NULL];
    
    if (status == errSecSuccess && result) {
        if (returnPersistentRef) {
            *result = CFBridgingRetain(persistentRef);
        } else if (ref) {
            *result = ref;
        }
    } else if (ref) {
        CFRelease(ref);
    }
    
    NSLogger(@"status=%d, attrs=%@, result=%@",
             status, attrs, result ? (__bridge id)*result : nil);
    return status;
}

SecItemUpdateFuncPtr SecItemUpdate_ori = NULL;
OSStatus hk_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attrsToUpdate) {
    NSDictionary *q = (__bridge NSDictionary *)query;
    NSDictionary *upd = (__bridge NSDictionary *)attrsToUpdate;
    OSStatus status = [[MockKeychain sharedStore] updateItems:q withAttributes:upd];
    NSLogger(@"status = %d, query = %@, attrsToUpdate = %@",status, q, upd);
    return status;
}

SecItemDeleteFuncPtr SecItemDelete_ori = NULL;
OSStatus hk_SecItemDelete(CFDictionaryRef query) {
    NSDictionary *q = (__bridge NSDictionary *)query;
    OSStatus status = [[MockKeychain sharedStore] deleteItems:q];
    NSLogger(@"status = %d, query = %@",status, q);
    return status;
}


SecItemCopyMatchingFuncPtr SecItemCopyMatching_ori = NULL;

OSStatus hk_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    NSDictionary *q = (__bridge NSDictionary *)query;
    OSStatus status;
    
    // 1. 解析返回控制标志
    BOOL wantRef   = [q[(__bridge id)kSecReturnPersistentRef] boolValue];
    BOOL wantAttrs = [q[(__bridge id)kSecReturnAttributes]    boolValue];
    BOOL wantData  = [q[(__bridge id)kSecReturnData]          boolValue];
    BOOL matchAll  = [q[(__bridge id)kSecMatchLimit] isEqual:(__bridge id)kSecMatchLimitAll];
    BOOL needPack  = wantRef || wantAttrs || wantData;

    // 2. 构造匹配条件
    static NSSet *controlKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controlKeys = [NSSet setWithArray:@[
            (__bridge id)kSecReturnAttributes,
            (__bridge id)kSecReturnData,
            (__bridge id)kSecReturnRef,
            (__bridge id)kSecReturnPersistentRef,
            (__bridge id)kSecMatchLimit,
            (__bridge id)kSecMatchLimitAll
        ]];
    });
    NSMutableDictionary *searchQuery = [NSMutableDictionary dictionary];
    [q enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![controlKeys containsObject:key]) {
            searchQuery[key] = obj;
        }
    }];

    // 3. 执行匹配
    NSArray<NSDictionary *> *matches = [[MockKeychain sharedStore] itemsMatching:searchQuery];
    if (matches.count == 0) {
        status = errSecItemNotFound;
        NSLogger(@"status=%d, query=%@, result=nil", status, q);
        return status;
    }
    NSArray *candidates = matchAll ? matches : @[matches.firstObject];
    // 特殊处理：只请求 kSecReturnData 时，直接返回 NSData（避免后续打包 NSDictionary）
    if (wantData && !wantAttrs && !wantRef && !matchAll) {
        NSData *data = candidates.firstObject[(__bridge id)kSecValueData];
        if (result && data) {
            *result = (__bridge_retained CFTypeRef)data;
        }
        status = data ? errSecSuccess : errSecItemNotFound;
//        if (data) {
//            NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
//            const unsigned char *bytes = data.bytes;
//            for (NSUInteger i = 0; i < data.length; i++) {
//                [hex appendFormat:@"%02x", bytes[i]];
//            }
//            NSLogger(@"[r_Data] hex = %@", hex);
//            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
///            Class cls = NSClassFromString(@"RDSignedDataContainer");
///            obj = class_createInstance(cls, 0);
///            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
//            if (obj) {
//                // Parsed object: <FIRInstallationsStoredItem: 0x60000076c540>
//                NSLogger(@"Parsed object: %@", obj);
//            }
//        }
        NSLogger(@"[r_Data] status=%d, query=%@, result=%@", status, q, data);
        return status;
    }

    // 继续处理其他组合返回类型
    NSMutableArray *packed = needPack ? [NSMutableArray arrayWithCapacity:candidates.count] : nil;
    for (NSDictionary *item in candidates) {
        // 仅请求 persistent ref，直接返回
        if (wantRef && !wantAttrs && !wantData) {
            [packed addObject:item[(__bridge id)kSecValuePersistentRef]];
            continue;
        }

        // 组合打包
        if (needPack) {
            NSMutableDictionary *e = [NSMutableDictionary dictionary];
            // 添加属性（去除 v_Data）
            if (wantAttrs) {
                [item enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *s){
                    if (![k isEqual:(__bridge id)kSecValueData]) {
                        e[k] = v;
                    }
                }];
            }
            // 添加 v_Data
            if (wantData) {
                id d = item[(__bridge id)kSecValueData];
                if (d) e[(__bridge id)kSecValueData] = d;
            }
            // 添加 persistentRef
            if (wantRef) {
                id r = item[(__bridge id)kSecValuePersistentRef];
                if (r) e[(__bridge id)kSecValuePersistentRef] = r;
            }
            [packed addObject:e];
        }
    }
    // 打包结果
    id outObj = needPack
                ? (matchAll ? (id)packed : packed.firstObject)
                : (id)candidates.firstObject;
    if (result) {
        *result = (__bridge_retained CFTypeRef)outObj;
    }
    status = errSecSuccess;

    // 5. 最终日志：只输出 status, query, result
    NSLogger(@"status=%d, query=%@, result=%@",
             status,
             q,
             outObj);
    return status;
}



#pragma clang diagnostic pop

// Why do you want to see here ???
NSString *love69(NSString *input) {
    NSMutableString *output = [NSMutableString stringWithCapacity:input.length];
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar ch = [input characterAtIndex:i];

        if (ch >= 'A' && ch <= 'Z') {
            ch = 'A' + (ch - 'A' + 13) % 26;
        } else if (ch >= 'a' && ch <= 'z') {
            ch = 'a' + (ch - 'a' + 13) % 26;
        }
        [output appendFormat:@"%C", ch];
    }
    return output;
}

// @Deprecated
int destory_inject_thread(void){
    NSLogger(@"destory_inject_thread");
    task_t task = mach_task_self();
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount;

    if (task_threads(task, &threads, &threadCount) != KERN_SUCCESS) {
        NSLogger(@"Failed to get threads.");
        return -1;
    }

    thread_act_t threadsToTerminate[threadCount];
    int terminateCount = 0;
    
    for (mach_msg_type_number_t i = 0; i < threadCount; i++) {
        thread_t thread = threads[i];

        thread_basic_info_data_t info;
        mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
        kern_return_t kr = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&info, &count);
        if (kr == KERN_SUCCESS) {
            pthread_t pthread = pthread_from_mach_thread_np(thread);
            // On success, `pthread_getname_np` functions return 0; on error, they return a nonzero error number.
            char name[256];
            int nameFlag =pthread_getname_np(pthread, name, sizeof(name));
            NSLogger(@"Thread-[%d] Information: Name: %s, NameFlag: %d, User Time: %d seconds, System Time: %d seconds, CPU Usage: %d%%, Scheduling Policy: %d, Run State: %d, Flags: %d, Suspend Count: %d, Sleep Time: %d seconds",
                  thread,
                  name,
                  nameFlag,
                  info.user_time.seconds,
                  info.system_time.seconds,
                  info.cpu_usage,
                  info.policy,
                  info.run_state,
                  info.flags,
                  info.suspend_count,
                  info.sleep_time);
        }
    }
    
    for (int i = 0; i < terminateCount; i++) {
        NSLogger(@"Need to kill the injected thread %d", threadsToTerminate[i]);
        if (thread_suspend(threadsToTerminate[i]) != KERN_SUCCESS) {
            NSLogger(@"Failed to suspend thread.");
        }
        if (thread_terminate(threadsToTerminate[i]) != KERN_SUCCESS) {
            NSLogger(@"Failed to terminate thread.");
        }
    }
       
    if (threads) {
        vm_deallocate(task, (vm_address_t)threads, sizeof(thread_t) * threadCount);
    }
    return 0;
}
