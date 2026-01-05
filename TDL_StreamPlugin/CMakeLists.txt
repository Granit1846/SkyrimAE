cmake_minimum_required(VERSION 3.23)

project(TDL_StreamPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CommonLibSSE CONFIG REQUIRED)

add_commonlibsse_plugin(${PROJECT_NAME}
    SOURCES
        src/main.cpp
        src/TDL_PipeServer.cpp
)

# Принудительно подключаем твой PCH.h ко всем единицам трансляции
target_compile_options(${PROJECT_NAME} PRIVATE "/FI${CMAKE_CURRENT_SOURCE_DIR}/PCH.h")
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

# Куда копировать DLL после сборки
set(TDL_GAME_DIR "F:/SteamLibrary/steamapps/common/Skyrim Special Edition" CACHE PATH "Skyrim game root")
# --- TDL data root inside Skyrim\Data ---
set(TDL_DATA_DIR "${TDL_GAME_DIR}/Data/TDL" CACHE PATH "TDL root folder under Skyrim Data")
set(TDL_TOOLS_DIR "${TDL_DATA_DIR}/Tools" CACHE PATH "TDL tools folder")
set(TDL_CONFIG_DIR "${TDL_DATA_DIR}/Config" CACHE PATH "TDL config folder")

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${TDL_GAME_DIR}/Data/SKSE/Plugins"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:${PROJECT_NAME}>"
        "${TDL_GAME_DIR}/Data/SKSE/Plugins/${PROJECT_NAME}.dll"
)
# ---- Silent pipe sender (no console) ----
add_executable(tdl_send WIN32
    src/tools/tdl_send.cpp
)

target_compile_features(tdl_send PRIVATE cxx_std_20)
target_compile_definitions(tdl_send PRIVATE UNICODE _UNICODE NOMINMAX)

# Copy to game: Data\TDL_Tools\tdl_send.exe
add_custom_command(TARGET tdl_send POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${TDL_TOOLS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:tdl_send>"
        "${TDL_TOOLS_DIR}/tdl_send.exe"
)
# Make tdl_send.exe portable (no VC++ Redist needed)
if (MSVC)
  set_property(TARGET tdl_send PROPERTY MSVC_RUNTIME_LIBRARY
    "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

