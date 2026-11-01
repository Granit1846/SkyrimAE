// src/TDL_Overlay.cpp
// Local HTTP server for the OBS Browser Source overlay: "/" serves TDL_Overlay.html, "/state" the queue JSON.
// Bound to 127.0.0.1 only; one tiny request at a time is plenty for a 1 s poll.
#include "TDL_Overlay.h"
#include "TDL_PipeServer.h"

#include <winsock2.h>
#include <ws2tcpip.h>

#include <spdlog/spdlog.h>
#include <nlohmann/json.hpp>

#include <atomic>
#include <charconv>
#include <algorithm>
#include <cctype>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>

namespace
{
	std::filesystem::path PluginDir()
	{
		return std::filesystem::current_path() / "Data" / "SKSE" / "Plugins";
	}

	std::string ReadFile(const std::filesystem::path& p)
	{
		std::ifstream f(p, std::ios::binary);
		std::ostringstream ss;
		ss << f.rdbuf();
		return ss.str();
	}

	std::string SoundFile()
	{
		const auto state = nlohmann::json::parse(TDL_GetStateJson(), nullptr, false);
		if (!state.is_object() || !state.value("sound", false)) return {};
		const auto name = state.value("soundFile", std::string{});
		// ASVS 2.2.1: allow one local media filename only; never accept directory traversal or URL syntax.
		if (name.empty() || name.size() > 128 || !std::all_of(name.begin(), name.end(), [](unsigned char c) {
			return std::isalnum(c) || c == '_' || c == '-' || c == '.';
		})) return {};
		const auto ext = std::filesystem::path(name).extension().string();
		return ext == ".mp3" || ext == ".wav" || ext == ".ogg" ? name : std::string{};
	}

	void SendAll(SOCKET s, const std::string& data)
	{
		for (size_t sent = 0; sent < data.size();) {
			const int n = send(s, data.data() + sent, static_cast<int>(data.size() - sent), 0);
			if (n <= 0) {
				return;
			}
			sent += static_cast<size_t>(n);
		}
	}

	void Respond(SOCKET s, const char* status, const char* type, const std::string& body)
	{
		SendAll(s, std::string("HTTP/1.1 ") + status + "\r\nContent-Type: " + type +
					   "\r\nCache-Control: no-store\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: " + std::to_string(body.size()) +
					   "\r\n\r\n" + body);
	}

	void Handle(SOCKET c)
	{
		// Short limits: requests are served one at a time, so a stuck client must not stall the overlay
		DWORD timeout = 1000;
		setsockopt(c, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&timeout), sizeof(timeout));
		setsockopt(c, SOL_SOCKET, SO_SNDTIMEO, reinterpret_cast<const char*>(&timeout), sizeof(timeout));

		char buf[2048];
		const int n = recv(c, buf, sizeof(buf) - 1, 0);
		if (n <= 0) {
			return;
		}
		const std::string req(buf, static_cast<size_t>(n));
		// "GET /state?x=1 HTTP/1.1"
		const auto sp1 = req.find(' ');
		const auto sp2 = sp1 == std::string::npos ? std::string::npos : req.find(' ', sp1 + 1);
		if (req.rfind("GET ", 0) != 0 || sp2 == std::string::npos) {
			Respond(c, "405 Method Not Allowed", "text/plain", "GET only");
			return;
		}
		auto path = req.substr(sp1 + 1, sp2 - sp1 - 1);
		path = path.substr(0, path.find('?'));

		if (path == "/state") {
			Respond(c, "200 OK", "application/json; charset=utf-8", TDL_GetStateJson());
		} else if (path == "/sound") {
			const auto name = SoundFile();
			if (name.empty()) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "sound not configured"); return; }
			const auto file = PluginDir() / name;
			std::error_code ec;
			const auto size = std::filesystem::file_size(file, ec);
			// ASVS 1.4.2: bound file size before loading it or passing it to send().
			if (ec || size > 10 * 1024 * 1024) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "sound unavailable"); return; }
			const auto body = ReadFile(file);
			if (body.empty()) { Respond(c, "404 Not Found", "text/plain; charset=utf-8", "sound unavailable"); return; }
			const auto ext = std::filesystem::path(name).extension().string();
			Respond(c, "200 OK", ext == ".mp3" ? "audio/mpeg" : ext == ".wav" ? "audio/wav" : "audio/ogg", body);
		} else if (path == "/" || path == "/overlay") {
			const auto html = ReadFile(PluginDir() / "TDL_Overlay.html");  // re-read: edits apply without restarting the game
			if (html.empty()) {
				Respond(c, "404 Not Found", "text/plain", "TDL_Overlay.html not found");
			} else {
				Respond(c, "200 OK", "text/html; charset=utf-8", html);
			}
		} else {
			Respond(c, "404 Not Found", "text/plain", "not found");
		}
	}

	void ServerThread(int port)
	{
		WSADATA wsa{};
		if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
			spdlog::error("Overlay: WSAStartup failed");
			return;
		}
		SOCKET ls = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
		sockaddr_in addr{};
		addr.sin_family = AF_INET;
		addr.sin_port = htons(static_cast<u_short>(port));
		addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);  // never reachable from the network
		if (ls == INVALID_SOCKET || bind(ls, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || listen(ls, 8) != 0) {
			spdlog::error("Overlay: cannot listen on 127.0.0.1:{} (port busy?), error {}", port, WSAGetLastError());
			if (ls != INVALID_SOCKET) {
				closesocket(ls);
			}
			return;
		}
		spdlog::info("Overlay: http://127.0.0.1:{}/ (add as OBS Browser Source)", port);
		for (;;) {
			SOCKET c = accept(ls, nullptr, nullptr);
			if (c == INVALID_SOCKET) {
				continue;
			}
			Handle(c);
			closesocket(c);
		}
	}

	std::atomic_bool g_started{ false };
}

void TDL_StartOverlay()
{
	const auto ini = TDL_LoadIni(PluginDir() / "TDL_Twitch.ini");
	const auto section = ini.find("overlay");
	auto get = [&](const char* key, const char* def) -> std::string {
		if (section == ini.end()) {
			return def;
		}
		const auto it = section->second.find(key);
		return it == section->second.end() ? def : it->second;
	};
	if (get("enabled", "1") == "0" || g_started.exchange(true)) {
		return;
	}
	int port = 8645;
	const auto p = get("port", "8645");
	if (std::from_chars(p.data(), p.data() + p.size(), port).ec != std::errc{} || port <= 0 || port > 65535) {
		port = 8645;
	}
	std::thread(ServerThread, port).detach();  // detached like the other workers: no shutdown hook in SKSE
}
