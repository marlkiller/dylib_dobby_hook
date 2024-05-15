//
//  common_ret.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/9.
//

#include "common_ret.h"
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


char *global_email_address = "K'ed by: marlkller@voidm.com";
