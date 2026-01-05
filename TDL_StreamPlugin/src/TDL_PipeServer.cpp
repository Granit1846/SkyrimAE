#include <SKSE/SKSE.h>
#include <SKSE/API.h>
#include <SKSE/Events.h>
#include <SKSE/Interfaces.h>

#include <Windows.h>
#include <string>
#include <thread>
#include <atomic>
#include <vector>

static std::atomic_bool g_pipeRunning{ false };
static std::thread g_pipeThread;

static void SendTDLSubmitAction_OnGameThread(std::string actionID, int sourceType)
{
    auto* src = SKSE::GetModCallbackEventSource();
    if (!src) {
        return;
    }

    SKSE::ModCallbackEvent ev{};
    ev.eventName = "TDL_SubmitAction";
    ev.strArg = actionID.c_str();
    ev.numArg = static_cast<float>(sourceType);
    ev.sender = nullptr;

    src->SendEvent(&ev);
}

static bool TryParseLine(const std::string& line, std::string& outAction, int& outSource)
{
    auto pos = line.find('|');
    if (pos == std::string::npos) {
        return false;
    }
    outAction = line.substr(0, pos);

    try {
        outSource = std::stoi(line.substr(pos + 1));
    } catch (...) {
        return false;
    }

    return !outAction.empty();
}

static void PipeServerThread()
{
    g_pipeRunning.store(true);

    const wchar_t* pipeName = L"\\\\.\\pipe\\TDL_Stream";
    std::string carry;

    while (g_pipeRunning.load()) {
        HANDLE hPipe = CreateNamedPipeW(
            pipeName,
            PIPE_ACCESS_INBOUND,
            PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
            1,
            0,
            4096,
            0,
            nullptr
        );

        if (hPipe == INVALID_HANDLE_VALUE) {
            // Не спамим: просто пробуем позже
            Sleep(500);
            continue;
        }

        BOOL connected = ConnectNamedPipe(hPipe, nullptr) ? TRUE : (GetLastError() == ERROR_PIPE_CONNECTED);
        if (!connected) {
            CloseHandle(hPipe);
            continue;
        }

        char buf[512];
        DWORD read = 0;

        while (g_pipeRunning.load() && ReadFile(hPipe, buf, sizeof(buf), &read, nullptr) && read > 0) {
            carry.append(buf, buf + read);

            // Разбираем по строкам \n
            size_t start = 0;
            while (true) {
                size_t nl = carry.find('\n', start);
                if (nl == std::string::npos) {
                    carry.erase(0, start);
                    break;
                }

                std::string line = carry.substr(start, nl - start);
                if (!line.empty() && line.back() == '\r') {
                    line.pop_back();
                }
                start = nl + 1;

                std::string action;
                int source = 0;
                if (TryParseLine(line, action, source)) {
                    // ВАЖНО: отправку ModEvent делаем задачей в игровом потоке
                    if (auto* tasks = SKSE::GetTaskInterface(); tasks) {
                        tasks->AddTask([a = std::move(action), s = source]() mutable {
                            SendTDLSubmitAction_OnGameThread(std::move(a), s);
                        });
                    }
                }
            }
        }

        DisconnectNamedPipe(hPipe);
        CloseHandle(hPipe);
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    SKSE::Init(skse);

    // Стартуем pipe-сервер после загрузки данных
    if (auto* msg = SKSE::GetMessagingInterface(); msg) {
        msg->RegisterListener([](SKSE::MessagingInterface::Message* m) {
            if (m->type == SKSE::MessagingInterface::kDataLoaded) {
                if (!g_pipeThread.joinable()) {
                    g_pipeThread = std::thread(PipeServerThread);
                    g_pipeThread.detach();
                }
            }
        });
    }

    return true;
}

void TDL_StartPipeServer()
{
    // TODO: сюда позже вставим Named Pipe server
}
