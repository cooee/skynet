local skynet = require "skynet"
local cluster = require "skynet.cluster"


require("LuaKit._load");

local proxy
local getProxy = function( ... )
	cluster.reload {
		ClusterCenter = "47.106.87.33:9720",
	}
	local proxy = cluster.proxy "ClusterCenter@ClusterCenter"	-- cluster.proxy("db", "@sdb")
	return proxy
end

local CMD = {};
---由main调用触发过来 
function CMD.start(conf)
	print("watchdog.lua CMD.start")
	-- print("watchdog.lua CMD.start")

	-- print(cluster.call("ClusterCenter", "@ClusterCenter", "get", "a"))

	-- skynet.trace("cluster")
	local proxy = getProxy();
	local data = skynet.call(proxy, "lua", "getClusterNode", "db")
	if data then
		dump(data);
		cluster.reload(data);
		local proxy = cluster.proxy "db@db"	-- cluster.proxy("db", "@sdb")
		local v = skynet.call(proxy, "lua", "GET", "a");
		dump(v)
		dump(proxy,"proxy")
	end
end


function CMD.test(conf)
	print("watchdog.lua CMD.test")

end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)

end)