local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
require("LuaKit._load");
local CMD = require("proto.cmd");
local SocketUtil = require("SocketUtil");

local Player = class();
function Player:ctor()
    self.id = -1;
    self.isAI = true;
    self.cards = {};
end

local tasklet = require("tasklet");



local TableService = {}



local tableConfig = {maxPlayer = 8};

local GameLogic = require("GameLogic");

function TableService:start(conf)
    print("TableService CMD.start")
    if conf then
        tableConfig.maxPlayer = conf.maxPlayer
        self.tid = conf.tid
    end

    self.players = {};
    self.isPlaying = false; -- 是否在游戏中
    self:reset();

    self.gameLogic = new(GameLogic,self);
end

function TableService:getTableStatus(uid)
    for i,v in ipairs(self.players) do
        if v.uid == uid then
            return 2; -- 已经在房间
        end
    end
    if #self.players >= tableConfig.maxPlayer then
        return 0; -- 满人
    else
        return 1; --没满人
    end
end

function TableService:addUser(fd,uid)

    local mySeat = #self.players + 1;
    local player = new(Player);
    player.isAI  = false;
    player.id    = fd;
    player.uid   = uid;
    player.seat  = mySeat;
    table.insert(self.players,player)

    self:send(CMD.enterRoomSuccess,{seat = mySeat,id = player.id,tid = self.tid,uid = uid},player);

    if #self.players == tableConfig.maxPlayer then
        self:startGame();
    end

end

function TableService:reset()
    self.players = {};
    self.isPlaying = false;
end

function TableService:send(cmd,data,player)
    local fd = nil;
    if player.id and player.id ~= -1 and player.isAI == false then
        fd = player.id;
        SocketUtil.sendMsg(cmd,data,fd);
    end
end

function TableService:broadcast(cmd,data)
    for k,v in ipairs(self.players) do
        if v.isAI == false and v.id ~= -1 then
            self:send(cmd,data,v);
        end
    end
end

function TableService:startGame()

    if #self.players < 1 then
        return;
    end
    if self.isPlaying == true then
        return;
    end
    self.isPlaying = true;

    self:addAI()

    dump(self.tid,"桌子ID");

    self.gameLogic:startGame(self.players);
end

function TableService:onGameOver()
    ---游戏结束 判断是否有玩家在桌子 没有就回收
    local free = true
    for i,v in ipairs(self.players) do
        if v.isAI == false then
            free = false
        end
    end
    if free == true then
        skynet.send("TableManager", "lua", "freeTable", self.tid)
    else
       self:reset();
    end
end


---添加机器人
function TableService:addAI()
    local pos = #self.players + 1;
    for i = pos,8 do
        local player = new(Player);
        player.isAI  = true;
        player.id    = -1;
        player.uid   = -1;
        player.seat  =  i;
        table.insert(self.players,player)
    end
end

---从进
function TableService:reEnter(fd,uid)
    for i,v in ipairs(self.players) do
        if v.uid == uid then
            v.id = fd;
        end
    end
    if self.isPlaying == true then 
       self.gameLogic:onUserReconnect(fd);
    end
end

function TableService:disconnect()
    -- todo: do something before exit
    print("TableService CMD.disconnect")
    skynet.exit()
end

function TableService:user_disconnect(fd)
    for i,v in ipairs(self.players) do
        if v.id == fd then
            self:onUserDisconnect(i,fd)
            return true;
        end
    end
    return false;
end

function TableService:onUserDisconnect(index,fd)
    if self.isPlaying == true then
        self.gameLogic:onUserDisconnect(fd);
    else
        print("用户离开桌子")
        table.remove(self.players,index);
    end
end

function TableService:getPlayerByID(id)
    local player = nil;
    for k,v in ipairs(self.players) do
        if v.id == id then
            return v;
        end
    end
end

function TableService:onRecv(fd,cmd,data)
    for i,v in ipairs(self.players) do
        if v.id == fd then
            self:onRecvMsg(fd,cmd,data);
            return true;
        end
    end
    return false;
end

function TableService:onRecvMsg(fd,cmd,data)
    local func = self.gameLogic.CMDFuncMap[cmd];
    if func  then
        if self.gameLogic[func] then
            self.gameLogic[func](self.gameLogic,fd,cmd,data)
        end
    else
        if cmd == CMD.userRequestStartGame then
           self:startGame()
        end
    end
end

skynet.start(function()
    print("==========TableService=========")
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = TableService[cmd]
        skynet.ret(skynet.pack(f(TableService,...)))
    end)
end)