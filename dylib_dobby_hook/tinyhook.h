#ifndef tinyhook_h
#define tinyhook_h

#include <objc/objc-runtime.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CLASS_METHOD    0
#define INSTANCE_METHOD 1

/* inline hook */
int tiny_hook(void *function, void *destnation, void **origin);

int tiny_insert(void *address, void *destnation, bool link);

int tiny_insert_far(void *address, void *destnation, bool link);

/* objective-c runtime */
int ocrt_swap(const char *cls1, const char *sel1, const char *cls2, const char *sel2);

void *ocrt_impl(const char *cls, const char *sel, bool type);

Method ocrt_method(const char *cls, const char *sel, bool type);

/* memory access */
int read_mem(void *destnation, const void *source, size_t len);

int write_mem(void *destnation, const void *source, size_t len);

/* solve symbol */
void *sym_solve(uint32_t image_index, const char *symbol_name);

/* find in memory */
// int find_code(uint32_t image_index, const unsigned char *code, size_t len, int count, void **out);

// int find_data(void *start, void *end, const unsigned char *data, size_t len, int count, void **out);

#ifdef __cplusplus
}
#endif

#endif
