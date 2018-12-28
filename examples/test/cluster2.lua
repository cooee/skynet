local skynet = require "skynet"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"


local getProxy = function( ... )
	cluster.reload {
		ClusterCenter = "127.0.0.1:1989",
	}
	local proxy = cluster.proxy "ClusterCenter@ClusterCenter"	-- cluster.proxy("db", "@sdb")
	return proxy
end


local CMD = {};


local r_source 
function CMD.GET( ... )
	-- test
	skynet.send(r_source, "lua", "test", "a");
	return "456"
end

skynet.start(function()
	proxy = getProxy()

	local port = skynet.call(proxy, "lua", "getPort", {db = "127.0.0.1:2528"});

	local address = "127.0.0.1:" .. port
	print(address)

	cluster.reload {
		db = address,
	}

	cluster.open "db"

	skynet.send(proxy, "lua", "register", {key = "db",value = address});

	cluster.register("db", skynet.self())
	
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		r_source = source;
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
		
	end)
end)
