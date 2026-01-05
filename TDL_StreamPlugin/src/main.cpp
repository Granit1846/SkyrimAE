// src/main.cpp
#include "TDL_PipeServer.h"

#include <SKSE/SKSE.h>

#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/spdlog.h>

#include <memory>

static void SetupLog()
{
	auto path = SKSE::log::log_directory();
	if (!path) {
		return;
	}

	*path /= "TDL_StreamPlugin.log";

	auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(path->string(), true);
	auto logger = std::make_shared<spdlog::logger>("TDL_StreamPlugin", std::move(sink));

	spdlog::set_default_logger(std::move(logger));
	spdlog::set_level(spdlog::level::info);
	spdlog::flush_on(spdlog::level::info);

	spdlog::info("TDL_StreamPlugin: logger initialized");
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
	SKSE::Init(skse);
	SetupLog();

	spdlog::info("TDL_StreamPlugin: SKSEPluginLoad OK");

	if (auto* msg = SKSE::GetMessagingInterface(); msg) {
		msg->RegisterListener([](SKSE::MessagingInterface::Message* m) {
			if (!m) {
				return;
			}
			if (m->type == SKSE::MessagingInterface::kDataLoaded) {
				spdlog::info("TDL_StreamPlugin: kDataLoaded -> start pipe server");
				TDL_StartPipeServer();
			}
			});
	}

	return true;
}
