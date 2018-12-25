-- client.lua
package.path = package.path .. ";../gameServer/proto/?.lua"

local host = "47.106.87.33"
local port = 9700

require("pbc.protobuf")
require("Luakit._load");
local json  = require("json")


local GameWriter = {}

function GameWriter:writePacket(cmd,data)
	if self:checkCmd(cmd) == true then
		-- local out = new(OutLuaPacket)
		-- out:writeBinary(json.encode(data))
		return json.encode(data);
	end
end

function GameWriter:checkCmd(cmd)
	return true;
end



local GameReader = {}
function GameReader:readPacket(cmd,bodyBuf)
	if self:checkCmd(cmd) == true then
		-- local inPack = new(InLuaPacket,bodyBuf);
		-- local ret = inPack:readBinary()
		return json.decode(bodyBuf);
	end
	
end
function GameReader:checkCmd(cmd)
	return true;
end




local BaseSocket = require("BaseSocket");

-- local host = "127.0.0.1"
-- local port = 8888


require "alien"
require "alien.struct"
local struct = alien.struct

local CMD = require("cmd");

local GameSocket = new(BaseSocket)

--[[--
	设置包头处理
]]
function GameSocket:onWriteHead(cmd,bodyLen)
	-- error("需要自行实现读包头接口")
	local len  = 4 + bodyLen;
	local head = struct.pack('>I2I4',len,cmd);
	return head;
end


function GameSocket:onReadHead(sock)
	local headBuf, receive_status = sock:receive(6)
    if receive_status == "closed" or headBuf == nil then
        return receive_status;
    end
    local len,cmd,type,position
    position = 1
    len,cmd,position = struct.unpack('>I2I4',headBuf,position)
    local bodyLen = len - 6;
	return receive_status,cmd,bodyLen;
end


function GameSocket:onRecv(cmd,data)
	dump(data,cmd)
	if CMD.loginSuccess == cmd then
		self:sendMsg(CMD.enterRoom,{uid = data.uid});
		
		self:sendMsg(CMD.userRequestStartGame,{uid = data.uid});
	end
end

GameSocket:addBodyReader(GameReader);

GameSocket:addBodyWriter(GameWriter)




GameSocket:connect(host, port,function(sock)
	sock:sendMsg(CMD.login,{token = "myc"});
	dump("连接成功")
end)
