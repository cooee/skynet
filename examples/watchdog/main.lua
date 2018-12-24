local skynet = require "skynet"
local max_client = 64
require("LuaKit._load");
skynet.start(function()

	print("main start2")
	-- skynet.error("Server start")
	-- skynet.uniqueservice("protoloader")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 9700,
		maxclient = max_client,
		nodelay = true,
	})
	

	local TableManager = skynet.newservice("TableManager")
	skynet.call(TableManager, "lua", "start", {
		maxTableNum = 100,
	})

	dumpToFile("myc_test", {a = 2})

	skynet.exit()
	print("main exit")
end)
