local skynet = require "skynet"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"

require("LuaKit._load");

local CMD = {};

port = 9720;

function CMD.test( ... )
	dump({ ...})
end

function CMD.getPort( ... )
	port = port + 1;
	if port > 9800 then
		port = 9721;
	end
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
		ClusterCenter = "0.0.0.0:9720",
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
