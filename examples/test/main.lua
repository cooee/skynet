local skynet = require "skynet"
local max_client = 64
require("LuaKit._load");
skynet.start(function()


	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 9701,
		maxclient = max_client,
		nodelay = true,
	})
	

	local TableManager = skynet.newservice("test_cluster")
	skynet.call(TableManager, "lua", "start", {
		maxTableNum = 100,
	})

	skynet.exit()
	print("main exit")
end)
