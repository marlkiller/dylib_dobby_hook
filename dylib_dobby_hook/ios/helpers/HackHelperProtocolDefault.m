#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// Dobby kütüphanesi (Hooking için)
#include "dobby.h"

// --- Ofset Tanımlamaları (Analiz.txt dosyasından) ---
[span_0](start_span)// Not: 0x23398 ofseti veri raporlama ve SDK kontrolleri için kritiktir[span_0](end_span).
#define OFFSET_REPORT_DATA 0x23398 
#define OFFSET_IOCTL_OLD   0x2342C

// --- Hook Fonksiyonları ---

// Raporlama fonksiyonunu devre dışı bırakmak veya manipüle etmek için
void (*orig_AnoSDKDelReportData)(void *a1, void *a2);
void hook_AnoSDKDelReportData(void *a1, void *a2) {
    // Fonksiyonun çalışmasını engelleyerek veri gönderimini durdurur
    return; 
}

// ASLR Taban Adresini Bulan Fonksiyon
uintptr_t get_anogs_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            // Bellekteki gerçek yükleme adresini döndürür
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// Tweak yüklendiğinde çalışacak ana bölüm
__attribute__((constructor))
static void initialize_patch() {
    uintptr_t base_address = get_anogs_base();
    
    if (base_address != 0) {
        printf("[Bypass] anogs taban adresi bulundu: 0x%lx\n", base_address);

        // ASLR Hesaplaması: Taban Adres + Statik Ofset
        void *target_report = (void *)(base_address + OFFSET_REPORT_DATA);
        
        // Dobby ile Hook işlemini uygula
        DobbyHook(target_report, (void *)hook_AnoSDKDelReportData, (void **)&orig_AnoSDKDelReportData);
        
        printf("[Bypass] 0x%x adresine kanca atıldı.\n", OFFSET_REPORT_DATA);
    } else {
        printf("[Bypass] anogs dosyası bellekte bulunamadı!\n");
    }
}
