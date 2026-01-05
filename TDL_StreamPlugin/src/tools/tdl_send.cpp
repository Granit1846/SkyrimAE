// src/tools/tdl_send.cpp
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <shellapi.h>

#include <string>
#include <cwchar>

static std::string WideToUtf8(const std::wstring& w)
{
	if (w.empty()) {
		return {};
	}
	int len = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
	std::string out(len, '\0');
	WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), out.data(), len, nullptr, nullptr);
	return out;
}

static int ClampSource(int s)
{
	if (s < 1) return 1;
	if (s > 3) return 3;
	return s;
}

static bool EqualsNoCase(const std::wstring& a, const wchar_t* b)
{
	return _wcsicmp(a.c_str(), b) == 0;
}

static int SendLineToPipeUtf8(const std::string& lineUtf8)
{
	const wchar_t* kPipeName = L"\\\\.\\pipe\\TDL_Stream";

	HANDLE h = CreateFileW(kPipeName, GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr);
	if (h == INVALID_HANDLE_VALUE) {
		DWORD err = GetLastError();
		if (err == ERROR_PIPE_BUSY) {
			if (WaitNamedPipeW(kPipeName, 1000)) {
				h = CreateFileW(kPipeName, GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0, nullptr);
			}
		}
	}
	if (h == INVALID_HANDLE_VALUE) {
		return 3;  // open/connect failed
	}

	std::string payload = lineUtf8;
	if (payload.empty() || payload.back() != '\n') {
		payload.push_back('\n');
	}

	DWORD written = 0;
	BOOL ok = WriteFile(h, payload.data(), (DWORD)payload.size(), &written, nullptr);
	CloseHandle(h);

	if (!ok || written != payload.size()) {
		return 4;  // write failed
	}
	return 0;
}

// Windows subsystem entry point => no console window
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
	int argc = 0;
	LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	if (!argv || argc < 2) {
		if (argv) LocalFree(argv);
		return 2;  // usage
	}

	std::wstring mode = argv[1];

	std::string line;

	// tdl_send.exe NORMAL ACTION [SOURCE]
	if (EqualsNoCase(mode, L"NORMAL")) {
		if (argc < 3) {
			LocalFree(argv);
			return 2;
		}

		std::string action = WideToUtf8(argv[2]);

		int source = 2;
		if (argc >= 4) {
			source = (int)wcstol(argv[3], nullptr, 10);
		}
		source = ClampSource(source);

		line = action + "|" + std::to_string(source);
		LocalFree(argv);
		return SendLineToPipeUtf8(line);
	}

	// tdl_send.exe FORCE1 ACTION
	if (EqualsNoCase(mode, L"FORCE1")) {
		if (argc < 3) {
			LocalFree(argv);
			return 2;
		}

		std::string action = WideToUtf8(argv[2]);
		line = "FORCE1|" + action;

		LocalFree(argv);
		return SendLineToPipeUtf8(line);
	}

	// tdl_send.exe FORCE ACTION COUNT [INTERVAL]
	if (EqualsNoCase(mode, L"FORCE")) {
		if (argc < 4) {
			LocalFree(argv);
			return 2;
		}

		std::string action = WideToUtf8(argv[2]);
		int count = (int)wcstol(argv[3], nullptr, 10);

		if (argc >= 5) {
			// interval provided
			double interval = wcstod(argv[4], nullptr);
			// Форматируем без лишней экзотики: как есть
			line = "FORCE|" + action + "|" + std::to_string(count) + "|" + std::to_string(interval);
		}
		else {
			line = "FORCE|" + action + "|" + std::to_string(count);
		}

		LocalFree(argv);
		return SendLineToPipeUtf8(line);
	}

	// Unknown mode
	LocalFree(argv);
	return 2;
}
