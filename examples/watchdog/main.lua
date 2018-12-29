local skynet = require "skynet"
local max_client = 64
require("LuaKit._load");
skynet.start(function()


	--启动一个服务
	local watchdog = skynet.newservice("watchdog")
	--调用watchdog start 命令
	skynet.call(watchdog, "lua", "start", {
		port = 9700,
		maxclient = max_client,
		nodelay = true,
	})
	
	---启动桌子管理器
	local TableManager = skynet.newservice("TableManager")
	skynet.call(TableManager, "lua", "start", {
		maxTableNum = 100,
	})

	--启动假登陆服务
	local LoginService = skynet.newservice("LoginService")
	skynet.call(LoginService, "lua", "start", {
	})
	
	skynet.exit()
	
	print("main exit")
end)
