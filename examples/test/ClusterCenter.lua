local skynet = require "skynet"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"

require("LuaKit._load");

local CMD = {};

port = 3001;

function CMD.test( ... )
	dump({ ...})
end

function CMD.getPort( ... )
	port = port + 1;
	return port;
end


local clusterMap = {}
function CMD.register(data)
	clusterMap[data.key] = data.value
	dump(clusterMap);
end

function CMD.getClusterNode(name)
	local data = {};
	if clusterMap[name] then
		data[name] = clusterMap[name]
		return data;
	end
	return nil;
end



skynet.start(function()
	cluster.reload {
		ClusterCenter = "127.0.0.1:1989",
	}
	skynet.dispatch("lua", function(session, source, cmd,...)
		local f = assert(CMD[cmd])
		if f then
			skynet.ret(skynet.pack(f(...)))
		end	
	end)

	cluster.register("ClusterCenter", skynet.self());

	cluster.open "ClusterCenter"

	print("ClusterCenter")

end)
