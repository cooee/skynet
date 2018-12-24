--[[
代理服务器
]]
local skynet = require "skynet"
local socket = require "skynet.socket"
local cjson = require("cjson");
require("LuaKit._load");

local WATCHDOG
local host
local send_request

local CMD = {}

local client_fd


local function send_package(cmd,data)
	local struct = string;
	local body = cjson.encode(data)
	local len  = 6 + #body;
	local head = struct.pack('>I2I4',len,cmd);
	local package = head .. body;
	socket.write(client_fd, package)
end


local MSG = {}
function MSG:onRecv(fd,cmd,data)
	print(fd,data,cmd)
	skynet.send("TableManager", "lua", "onRecv",fd,cmd,data)
end

---主动关闭连接
-- function REQUEST:quit()
-- 	skynet.call(WATCHDOG, "lua", "close", client_fd)
-- end




skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		local buf = skynet.tostring(msg,sz)
        local struct = string;
        local len,cmd,position
        position = 1
        cmd,position = struct.unpack('>I4',buf,position) --获取命令字 cmd
        local bodyBuf = string.sub(buf,5,sz)
        local data = cjson.decode(bodyBuf);
		return cmd,data
	end,
	dispatch = function (fd, _, cmd, ...)
		assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		-- skynet.trace()
		MSG:onRecv(fd,cmd, ...)
		return fd, _, cmd, ...
	end
}

function CMD.start(conf)
	--- watchdog 调用过来
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog


	---发送心跳
	-- skynet.fork(function()
	-- 	while true do
	-- 		send_package("heartbeat")
	-- 		skynet.sleep(500)
	-- 	end
	-- end)
	client_fd = fd

	--调用网关 gate forward 向前 打开 fd socket
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect(fd)
	-- todo: do something before exit
	print("agent.lua disconnect")
	skynet.call("TableManager", "lua", "user_disconnect", client_fd)
	print("用户断开连接",client_fd);
	client_fd = nil;
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)