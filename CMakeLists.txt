cmake_minimum_required(VERSION 3.5)

project(dylib_dobby_hook)

enable_language(ASM)
enable_language(C)
enable_language(CXX)
enable_language(OBJC)
enable_language(OBJCXX)
#enable_language(Swift)


set(CMAKE_C_STANDARD 17)
#set(CMAKE_C_EXTENSIONS ON)
#set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu17")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -x objective-c")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++20")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -x objective-c++")

# Enable ARC
set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fobjc-arc")
set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fobjc-arc")

#关闭编译器优化
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
#set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -O0")
#set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -O0")


set(COMPILE_OPTION
        -Wno-int-conversion
        -Wno-nullability-completeness
        -Wno-incompatible-pointer-types
        -Wno-int-to-void-pointer-cast
        -Wno-unguarded-availability-new # is only available on macOS 10.15 or newer
        -ftrivial-auto-var-init=zero
)

set(LINK_OPTION
        -Xlinker
        -x
)

# x86_64;arm64;arm64e
set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
set(CMAKE_OSX_DEPLOYMENT_TARGET "14.2")

file(GLOB Main ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/*.m)
file(GLOB MainHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/*.h)

file(GLOB Utils
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.m
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.c
)
file(GLOB UtilsHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.h)

file(GLOB Apps ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps/*.m)
file(GLOB AppsHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps/*.h)

file(GLOB Helpers ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers/*.m)
file(GLOB HelpersHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers/*.h)

file(GLOB StaticLibs ${CMAKE_SOURCE_DIR}/libs/*.a)

include_directories(
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils
)

add_library(${PROJECT_NAME} SHARED
        ${Main}
        ${MainHeader}
        ${UtilsHeader}
        ${AppsHeader}
        ${HelpersHeader}
        ${Utils}
        ${Apps}
        ${Helpers}
)
set_target_properties(${PROJECT_NAME} PROPERTIES
        
        EXECUTABLE_PREFIX "lib"
        EXECUTABLE_EXTENSION "dylib"

        # FRAMEWORK TRUE
        # FRAMEWORK_VERSION A
        # Mark which headers should public
        # PUBLIC_HEADER "/usr/local/include"

        ## ----------------------------------
        ## Architecture
        ## ----------------------------------
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH[variant=Debug] "NO"
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH[variant=Release] "NO"
        ## ----------------------------------
        ## Build Option
        ## ----------------------------------
        
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug] "dwarf"
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] "dwarf-with-dsym"

        ## ----------------------------------
        ## Deployment
        ## ----------------------------------
        XCODE_ATTRIBUTE_SKIP_INSTALL "YES"
        # XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_LIBRARY_DIR)/Frameworks"

        ## ----------------------------------
        ## Link
        ## ----------------------------------
        # /usr/local/lib
        XCODE_ATTRIBUTE_DYLIB_INSTALL_NAME_BASE "$(INSTALL_PATH)"
        XCODE_ATTRIBUTE_LD_DYLIB_INSTALL_NAME "$(DYLIB_INSTALL_NAME_BASE:standardizepath)/$(EXECUTABLE_PATH)"
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/"
        XCODE_ATTRIBUTE_DYLIB_COMPATIBILITY_VERSION "1"
        XCODE_ATTRIBUTE_DYLIB_CURRENT_VERSION "1"

        ## ----------------------------------
        ## Apple Clang - Language - C/C++
        ## ----------------------------------
        XCODE_ATTRIBUTE_CLANG_GCC_C_LANGUAGE_STANDARD "gnu17"
        XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "gnu++20"
        XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++"
        ## ----------------------------------
        ## Apple Clang - Language - Modules
        ## ----------------------------------
        XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES "YES"
        ## ----------------------------------
        ## Apple Clang - Language - Objective-C
        ## ----------------------------------
        # Enable ARC, cmake default is MRC
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_WEAK "YES"
        ## ----------------------------------
        ## Apple Clang - Language - Code Generation
        ## ----------------------------------
        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS "YES"
        
        # Xcode 的Run 指令会自动 link 已经 dependency 的 target，不需要 CMake 的指令再 link 一遍，如果不是 Xcode Generate 则需要 CMake 进行 Link

)


# 去掉lib前缀
#set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_compile_options(${PROJECT_NAME} PRIVATE ${COMPILE_OPTION})

target_link_options(${PROJECT_NAME} PRIVATE ${LINK_OPTION})

# Xcode 在引入这些库的头文件时会自动加入编译，但是CLion不会，所以需要手动设置一下这个库。
target_link_libraries(${PROJECT_NAME} PUBLIC
        "-framework Foundation"
        "-framework CoreFoundation"
        "-framework AppKit"
        "-framework Cocoa"
        "-framework IOKit"
        "-framework CloudKit"
        "-framework Security"
        "-framework CoreWLAN"

        # 加入额外的库
        # ld: warning: ignoring duplicate libraries: '-lobjc'
        # objc
        c++
        c
        ${StaticLibs}
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-DDEBUG)
elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
else ()
endif ()

# 如果想 DEBUG Live 调试, 得先执行 cmake_debugger.sh 脚本;
# 将 install 后的 dylib link 到 app;
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_SOURCE_DIR}/release)
