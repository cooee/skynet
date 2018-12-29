local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	print("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	---执行 agent start
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect",fd)

		print("socket close2",fd)
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

---由main调用触发过来 
function CMD.start(conf)
	print("watchdog.lua CMD.start")
	-- print("watchdog.lua CMD.start")
	skynet.call(gate, "lua", "open" , conf)
	-- dump(fonf)
end

function CMD.close(fd)
	close_agent(fd)
end


---入口 start 
skynet.start(function()
	---注册事件 source 来源
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		print("watchdog cmd",cmd,subcmd)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	-- skynet.trace()
	print("watchdog 启动 mygate")
	print("watchdog ",skynet.self());
	gate = skynet.newservice("mygate")
end)
