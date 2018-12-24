local skynet = require "skynet"
local max_client = 64

skynet.start(function()

	print("main start")
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

	skynet.exit()
	print("main exit")
end)
