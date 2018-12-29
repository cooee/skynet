local skynet = require "skynet"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"


local getProxy = function( ... )
	cluster.reload {
		ClusterCenter = "47.106.87.33:9720",
	}
	local proxy = cluster.proxy "ClusterCenter@ClusterCenter"	-- cluster.proxy("db", "@sdb")
	return proxy
end


local CMD = {};

function CMD.GET( ... )
	return "123"
end

skynet.start(function()
	proxy = getProxy()

	local port = skynet.call(proxy, "lua", "getPort", {db = "127.0.0.1:2528"});

	local address = "0.0.0.0:" .. port
	print(address)

	cluster.reload {
		db = address,
	}

	cluster.open "db"

	skynet.send(proxy, "lua", "register", {key = "db",value = address});

	cluster.register("db", skynet.self())
	
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
		
	end)
end)
