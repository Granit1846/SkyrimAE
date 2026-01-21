#include "TDL_MenuHook.h"
#include <REL/Relocation.h>
#include <RE/T/TESQuest.h>
#include <SKSE/SKSE.h>
#include <spdlog/sinks/basic_file_sink.h>

using namespace std::literals;

namespace TDL
{
    // Указатель на оригинальную функцию
    static std::uint16_t(*_original_SetStage)(RE::TESQuest*, std::uint16_t) = nullptr;

    std::uint16_t Hooked_SetStage(RE::TESQuest* a_this, std::uint16_t a_stage)
    {
        if (a_this && a_stage == 999) {
            auto editorID = a_this->GetFormEditorID();
            if (editorID && std::strcmp(editorID, "TDL_MainControllerQuest") == 0) {
                SKSE::log::info("TDL: stage 999 detected → open custom menu");
                OpenCustomMenu();
                return a_stage; // не вызываем оригинальный SetStage
            }
        }

        return _original_SetStage(a_this, a_stage);
    }

    void InstallStageHook()
    {
        // Получаем VTable для TESQuest
        REL::Relocation<std::uintptr_t> vtbl{ RE::TESQuest::VTABLE[0] };

        // Сохраняем оригинал через reinterpret_cast
        _original_SetStage = reinterpret_cast<decltype(_original_SetStage)>(
            vtbl.write_vfunc(0x2D, reinterpret_cast<std::uintptr_t>(Hooked_SetStage))
            );

        SKSE::log::info("TDL: SetStage hook installed");
    }

    void OpenCustomMenu()
    {
        SKSE::log::info("TDL: OpenCustomMenu() called");
    }
}