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
#include <mach-o/dyld.h>
#include <sys/ptrace.h>
#import <sys/sysctl.h>
#include <mach/mach_types.h>
#include <mach/i386/thread_status.h>

int ret2 (void){
    printf(">>>>>> ret2\n");
    return 2;
}
int ret1 (void){
    printf(">>>>>> ret1\n");
    return 1;
}
int ret0 (void){
    printf(">>>>>> ret0\n");
    return 0;
}

void ret(void){
    printf(">>>>>> ret\n");
}


// hook ptrace
// 通过 ptrace 来检测当前进程是否被调试，通过检查 PT_DENY_ATTACH 标记是否被设置来判断。如果检测到该标记，说明当前进程正在被调试，可以采取相应的反调试措施。
ptrace_ptr_t orig_ptrace = NULL;
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if(_request != 31){
        // 如果请求不是 PT_DENY_ATTACH，则调用原始的 ptrace 函数
        return orig_ptrace(_request,_pid,_addr,_data);
    }
    printf(">>>>>> [AntiAntiDebug] - ptrace request is PT_DENY_ATTACH\n");
    // 拒绝调试
    return 0;
}

// hook sysctl
// 通过 sysctl 去查看当前进程的信息，看有没有这个标记位即可检查当前调试状态。
sysctl_ptr_t orig_sysctl = NULL;
int my_sysctl(int * name, u_int namelen, void * info, size_t * infosize, void * newinfo, size_t newinfosize){
    int ret = orig_sysctl(name,namelen,info,infosize,newinfo,newinfosize);
    if(namelen == 4 && name[0] == 1 && name[1] == 14 && name[2] == 1){
        struct kinfo_proc *info_ptr = (struct kinfo_proc *)info;
        if(info_ptr && (info_ptr->kp_proc.p_flag & P_TRACED) != 0){
            NSLog(@">>>>>> [AntiAntiDebug] - sysctl query trace status.");
            info_ptr->kp_proc.p_flag ^= P_TRACED;
            if((info_ptr->kp_proc.p_flag & P_TRACED) == 0){
                NSLog(@">>>>>> [AntiAntiDebug] - trace status reomve success!");
            }
        }
    }
    return ret;
}

// hook task_get_exception_ports
// 通过 task_get_exception_ports 来检查当前任务的异常端口设置，以检测调试器的存在或者检查调试器是否修改了异常端口设置。如果发现异常端口被修改，可能表明调试器介入了目标进程的执行。
// some app will crash with _dyld_debugger_notification
task_get_exception_ports_ptr_t orig_task_get_exception_ports = NULL;
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
            NSLog(@">>>>>> [AntiAntiDebug] - my_task_get_exception_ports reset old_flavors[i]=9");
        }
    }
    return r;
}

// hook task_swap_exception_ports
// 通过 task_swap_exception_ports 来动态修改异常处理端口设置，以防止调试器对异常消息进行拦截或修改。例如，恶意软件可以将异常端口设置为自定义的端口，从而阻止调试器捕获异常消息，使调试器无法获取目标进程的状态信息。
task_swap_exception_ports_ptr_t orig_task_swap_exception_ports = NULL;
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
       NSLog(@">>>>>> [AntiAntiDebug] - my_task_swap_exception_ports Breakpoint exception detected, blocking task_swap_exception_ports");
       return KERN_FAILURE; // 返回错误码阻止调用
   }
   return orig_task_swap_exception_ports(task, exception_mask, new_port, new_behavior, new_flavor, old_masks, old_masks_count, old_ports, old_behaviors, old_flavors);
}



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
//char *global_dylib_name = "libdylib_dobby_hook.dylib";
