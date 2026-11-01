cmake_minimum_required(VERSION 3.23)

project(TDL_StreamPlugin VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# CommonLibSSE-NG (alandtse) as a submodule: the old vcpkg port (3.7.1) cannot read the Skyrim 1.7.x Address Library
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "" FORCE)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG EXCLUDE_FROM_ALL)
include(${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)  # add_commonlibsse_plugin()
find_package(nlohmann_json CONFIG REQUIRED)

add_commonlibsse_plugin(${PROJECT_NAME}
    SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/TDL_PipeServer.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/TDL_Twitch.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/TDL_Overlay.cpp
)

target_link_libraries(${PROJECT_NAME} PRIVATE nlohmann_json::nlohmann_json winhttp crypt32 shell32 ole32 ws2_32)

# Force-include PCH.h into every translation unit
target_compile_options(${PROJECT_NAME} PRIVATE "/FI${CMAKE_CURRENT_SOURCE_DIR}/PCH.h")
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_23)

# Where to copy the DLL after build (override with -DTDL_GAME_DIR=...)
set(TDL_GAME_DIR "F:/SteamLibrary/steamapps/common/Skyrim Special Edition" CACHE PATH "Skyrim game root")

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${TDL_GAME_DIR}/Data/SKSE/Plugins"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:${PROJECT_NAME}>"
        "${TDL_GAME_DIR}/Data/SKSE/Plugins/${PROJECT_NAME}.dll"
)
