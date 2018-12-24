local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
require("LuaKit._load");
local TableManager = {}

local CMD = require("proto.cmd");

local tabelList = {};
local maxTableNum  = 10;

function TableManager:start(conf)
    print("service1 TableManager.start")
    if conf and conf.maxTableNum then
        maxTableNum = maxTableNum
    end
end

function TableManager:disconnect(self)
    -- todo: do something before exit
    print("service1 TableManager.disconnect")
    skynet.exit()
end

function TableManager:user_disconnect(fd)
    for i,t in ipairs(tabelList) do
        local user_disconnect = skynet.call(t, "lua", "user_disconnect", fd)
        if user_disconnect == true then
            return;
        end
    end
end

function TableManager:onRecv(fd,cmd,data)
    print("TableManager onRecv",fd,cmd,data)
    if cmd == CMD.enterRoom then -- 请求进桌
        -- skynet.call("TableManager", "lua", "allocTable", {fd = fd,data = data})
        print("请求进桌",fd)
        self:allocTable(fd)
    else
        for i,v in ipairs(tabelList) do
            local ret = skynet.call(v, "lua", "onRecv", fd,cmd,data)
            if ret == true then
                return;
            end
        end
    end
end

---分配桌子
function TableManager:allocTable(fd,uid)
    local fd = fd;
    if #tabelList > maxTableNum then
        return false;
    end

    local flag = false;
    for i,t in ipairs(tabelList) do
        local status = skynet.call(t, "lua", "getTableStatus", fd)
        if status == 1 then -- 没人 
            skynet.call(t, "lua", "addUser", fd)
            dump(fd,"addUser")
            flag = true;
            break;
        elseif status == 2 then --在桌子里
            skynet.call(t, "lua", "reEnter", fd)
            flag = true;
            break;
        end
    end
    --- 桌子不够
    if flag == false then
        local t = TableManager.newTable()
        if t then
            skynet.call(t, "lua", "addUser", fd,uid)
        end   
    end
    return true;
end

function TableManager:newTable()
    if #tabelList >= maxTableNum then --超过最大桌子数
        return;
    end
    local TableService = skynet.newservice("TableService")
    skynet.call(TableService, "lua", "start", {maxPlayer = 8,tid = TableService})
    table.insert(tabelList,TableService)

    return TableService;
end
---回收桌子
function TableManager:freeTable(tid)
    local index = 0;
    for i,v in ipairs(tabelList) do
        if v == tid then
            index = i;
            break;
        end
    end
    if index > 0 then
        local t = table.remove(tabelList,index)
        if t then
            skynet.send(t, "lua", "disconnect", {}) --关闭需要send 不能 call
        end
    end
end



skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = TableManager[cmd]
        dump({...})
        if f then
            skynet.ret(skynet.pack(f(TableManager,...)))
        end
    end)
    skynet.register("TableManager")
end)