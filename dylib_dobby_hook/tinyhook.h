#ifndef tinyhook_h
#define tinyhook_h

#include <objc/runtime.h>
#include <stdint.h>

#ifdef NO_EXPORT
#define TH_VIS __attribute__((visibility("hidden")))
#else
#define TH_VIS __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    void *address;
    int jump_size;
    uint8_t head_bak[16];
} th_bak_t;

/* inline hook */
TH_VIS int tiny_hook(void *function, void *destination, void **origin);

TH_VIS int tiny_hook_ex(th_bak_t *bak, void *function, void *destination, void **origin);

TH_VIS int tiny_unhook_ex(const th_bak_t *bak);

TH_VIS int tiny_insert(void *address, void *destination);

/* interpose */
TH_VIS int tiny_interpose(uint32_t image_index, const char *symbol_name, void *replacement, void **origin);

/* objective-c runtime */
TH_VIS int ocrt_hook(const char *cls, const char *sel, void *destination, void **origin);

TH_VIS int ocrt_swap(const char *cls1, const char *sel1, const char *cls2, const char *sel2);

TH_VIS void *ocrt_impl(char type, const char *cls, const char *sel);

TH_VIS Method ocrt_method(char type, const char *cls, const char *sel);

/* memory access */
TH_VIS int read_mem(void *destination, const void *source, size_t len);

TH_VIS int write_mem(void *destination, const void *source, size_t len);

/* symbol resolve */
TH_VIS void *symtbl_solve(uint32_t image_index, const char *symbol_name);

TH_VIS void *symexp_solve(uint32_t image_index, const char *symbol_name);

#ifdef __cplusplus
}
#endif

#endif
