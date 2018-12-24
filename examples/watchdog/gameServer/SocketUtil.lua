-- @Author: 莫玉成
-- @Date:   2018-12-18 11:57:50
-- @Last Modified by   YuchengMo
-- @Last Modified time 2018-12-24 14:53:34

require("LuaKit._load");

local socketdriver = require "skynet.socketdriver"


local cjson = require("cjson");

local OutLuaPacket = require("proto.OutLuaPacket");
local InLuaPacket = require("proto.InLuaPacket");

local pack = function(cmd,data)
	local struct = string;
	local bodyLen = 0;
	local body
	if type(data) == "table" then
		body = cjson.encode(data);
	else
		error("data not json")
	end
	-- local out = new(OutLuaPacket)
	-- out:writeBinary(body)
	-- local bodyBuf = out:packetToBuf();

	bodyBuf = body
	bodyLen = #bodyBuf;

	local len  = 6 + bodyLen;
	local head = struct.pack('>I2I4',len,cmd);
	local buf = head .. bodyBuf
	-- dump(bodyLen,#head)
	return buf;
end

local sendMsg = function(cmd,data,fdList)
    if fdList == nil then
        return
    end
    local buf = pack(cmd,data);
    if type(fdList)  == "table" then
    	for i,v in ipairs(fdList) do
    		socketdriver.send(v, buf)
    	end
    else
    	socketdriver.send(fdList, buf)
    end
end



local SocketUtil = {};

SocketUtil.sendMsg = sendMsg;

return SocketUtil;