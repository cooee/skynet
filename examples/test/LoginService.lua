-- @Author: 莫玉成
-- @Date:   2018-12-25 09:36:03
-- @Last Modified by   YuchengMo
-- @Last Modified time 2018-12-27 15:20:53


local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
require("LuaKit._load");

local LoginService = {}

local SocketUtil = require("gameServer.SocketUtil");

local CMD = require("gameServer.proto.cmd");


function LoginService:start(conf)
	self.id = 10000;
	self.users = {};

end

function LoginService:disconnect(self)
    -- todo: do something before exit
    print("service1 LoginService.disconnect")
    skynet.exit()
end

function LoginService:login(fd,cmd,data)
	local token = data.token;
	local user = self:getUserByToken(token);
	if user == nil then
		local id = self:allocID();
		local u = {
			token = token,
			uid   = id;
		}
		self.users[token] = u;
		user  = u;
	end
	SocketUtil.sendMsg(CMD.loginSuccess,user,fd);

	dump(self.users,"userMap2")

end
---分配提个ID
function LoginService:allocID()
	self.id = self.id + 1;
	return self.id;
end


function LoginService:getUserByToken(token)
	for i,v in pairs(self.users) do
		if v.token == token then
			return v;
		end
	end
end


skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = LoginService[cmd]
        if f then
            skynet.ret(skynet.pack(f(LoginService,...)))
        end
    end)
    skynet.register("LoginService")
end)

