cmake_minimum_required(VERSION 3.23)

project(TDL_StreamPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CommonLibSSE CONFIG REQUIRED)

add_commonlibsse_plugin(${PROJECT_NAME}
target_precompile_headers(${PROJECT_NAME} PRIVATE PCH.h)
target_compile_options(${PROJECT_NAME} PRIVATE /FI${CMAKE_CURRENT_SOURCE_DIR}/PCH.h)
target_compile_options(${PROJECT_NAME} PRIVATE "/FI${CMAKE_CURRENT_SOURCE_DIR}/PCH.h")
target_precompile_headers(${PROJECT_NAME} PRIVATE <SKSE/Impl/PCH.h>)
target_precompile_headers(${PROJECT_NAME} PRIVATE <SKSE/Impl/PCH.h>)
target_compile_options(${PROJECT_NAME} PRIVATE "/FI\"SKSE/Impl/PCH.h\"")
    NAME "TDL_StreamPlugin"
    AUTHOR "Skeorz"
    VERSION ${PROJECT_VERSION}
    SOURCES
        src/main.cpp
		src/TDL_PipeServer.cpp
)
target_compile_features(TDL_StreamPlugin PRIVATE cxx_std_20)
target_compile_options(TDL_StreamPlugin PRIVATE "/FI\"SKSE/Impl/PCH.h\"")
target_compile_features(TDL_StreamPlugin PRIVATE cxx_std_20)
target_compile_options(TDL_StreamPlugin PRIVATE "/FI\"${CMAKE_CURRENT_SOURCE_DIR}/PCH.h\"")

# Куда копировать DLL после сборки (можно переопределить при конфигурации)
set(TDL_GAME_DIR "F:/SteamLibrary/steamapps/common/Skyrim Special Edition" CACHE PATH "Skyrim game root")

add_custom_command(TARGET TDL_StreamPlugin POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${TDL_GAME_DIR}/Data/SKSE/Plugins"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:TDL_StreamPlugin>"
        "${TDL_GAME_DIR}/Data/SKSE/Plugins/TDL_StreamPlugin.dll"
)

