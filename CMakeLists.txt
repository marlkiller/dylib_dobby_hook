cmake_minimum_required(VERSION 3.5)

project(dylib_dobby_hook)

enable_language(ASM)
enable_language(C)
enable_language(CXX)
enable_language(OBJC)
enable_language(OBJCXX)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++20")

set(COMPILE_OPTION
        -Wno-int-conversion
        -Wno-nullability-completeness
        -Wno-incompatible-pointer-types
        -Wno-int-to-void-pointer-cast
        -Wno-unguarded-availability-new # is only available on macOS 10.15 or newer
)

set(LINK_OPTION
        -Xlinker
        -x
)

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


file(GLOB StaticLibs ${CMAKE_SOURCE_DIR}/libs/*.dylib)

include_directories(
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils
)

add_library(${PROJECT_NAME} SHARED
        ${Main}
        ${MainHeader}
        ${UtilsHeader}
        ${AppsHeader}
        ${Utils}
        ${Apps}
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
        "-framework AppKit"
        "-framework Security"
        "-framework CoreWLAN"

        # 加入额外的库
        objc
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
