# Twitch Dragonborn Legacy (TDL)

Skyrim SE/AE mod: Twitch viewers trigger in-game scenarios through channel point rewards, bits,
chat commands and polls. Since 1.1 the SKSE plugin connects to Twitch directly - no Streamer.bot,
no executables.

- Nexus Mods: https://www.nexusmods.com/skyrimspecialedition/mods/170091
- Releases (packaged mod): see the GitHub Releases of this repository
- User documentation: `Data/TDL/README.txt`, `Data/TDL/Documentation/`

## Layout

| Path | Content |
|---|---|
| `Data/` | Mod content: ESP, Papyrus sources (`Data/Source/Scripts`), MCM translations, INI files, docs |
| `TDL_StreamPlugin/` | SKSE C++ plugin: Twitch EventSub client, action queue, named pipe |
| `TDL_StreamPlugin/extern/CommonLibSSE-NG` | Git submodule, CommonLibSSE-NG v13.1.0 |

## Building the plugin

Requirements: Visual Studio 2022+ with "Desktop development with C++", CMake, vcpkg (`VCPKG_ROOT`).

```
git clone --recurse-submodules https://github.com/Granit1846/SkyrimAE
cmake -S TDL_StreamPlugin -B build -G Ninja -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-md -DTDL_GAME_DIR="<Skyrim folder>"
cmake --build build
```

Use a build directory without non-ASCII characters in the path (MSVC error D8050 otherwise).
Papyrus scripts compile with the Creation Kit compiler; imports: `Data/Source/Scripts`, SKSE sources,
SkyUI SDK sources, vanilla sources.

## License

The SKSE plugin is licensed under GPL-3.0-or-later (it links CommonLibSSE-NG, which requires it).
See `LICENSE`.
