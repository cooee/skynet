
require("LuaKit._load");

local TableLib = table;

local CMD = require("proto.cmd");

local CardUtil = require("util.CardUtil");

local tasklet  = require("tasklet");

local oldPrint  = print;
local tid = nil;
print = function( ... )
    if tid then
        oldPrint("桌子id " .. tid, ...)
    else
        oldPrint(...)
    end
   
end


local GameLogic = {}

GameLogic.CMDFuncMap =  {
    [CMD.outCard]           = "onUserOutCard",
    [CMD.selectCardType]    = "selectCardType",
}

function GameLogic:ctor(delegate)
    self.delegate = delegate;

    self.delayTime = 1;

    tid = delegate.tid;
    -- self.send = delegate.send;

    -- self.broadcast = delegate.broadcast
    -- setmetatable(self, {__index = delegate});
end

function GameLogic:startGame(players)

    local mete = getmetatable(self);
    setmetatable(mete.__index, {__index = self.delegate});

    self.players = players or self.delegate.players;
    local seed = (tostring(os.time()):reverse():sub(1, 7))
    print(seed,"seed")
    math.randomseed(seed)--"8905465"
    math.random();
    math.random()

    self:dealCards();
    self:startGound();
    -- 8905465
end

function GameLogic:gameOver()
    print("游戏结束");
    self.cardList = {};
    self:broadcast(CMD.broadcastGameOver,{msg = "游戏结束"})

    local mete = getmetatable(self);
    setmetatable(mete.__index, {});

    if self.delegate.onGameOver then
        self.delegate:onGameOver();
    end
end


--[[
    检查出牌
    @tparam    outCard    table 用户出的牌
    @tparam    myCard     table 自己出的牌
    @usage 
]]
function GameLogic:check(outCard,myCard)
    if myCard.cardValue == 15 then
        return true;
    elseif outCard.cardValue == myCard.cardValue  then
        return true;
    else
        if outCard.cardValue == 11 or outCard.cardValue == 15 then  --加2 或者加4
            return false;
        elseif outCard.cardType == myCard.cardType then -- 同花色
            return true;
        elseif myCard.cardType == 4 then -- 变色牌
            return true;
        end
    end
    return false;
end

function GameLogic:getOffset(card,offset)
    if math.abs(offset) >= 2 then
        offset = math.ceil(offset / 2)
    end
    if card.cardValue == 12 and card.flag == nil then --转向
        card.flag = true;
        return offset * -1;
    elseif card.cardValue == 13 and card.flag == nil then -- 禁牌
        card.flag = true;
        return offset * 2;
    else
        return offset;
    end
end


function GameLogic:dealCards()
    local cardList = CardUtil.getAllCards();
    for i = 1,#cardList do
       table.insert(cardList,clone(cardList[i]));
    end
    cardList = TableLib.random(cardList);
    
    self.cardList = cardList;
    
    for k,v in ipairs(self.players) do
        for i=1,8 do
            local card = table.remove(cardList,1);
            table.insert(v.cards,card);
        end
    end
    
    for k,v in ipairs(self.players) do
        if v.isAI == false then
            local cards = {};
            for k,v in ipairs(v.cards) do
                table.insert(cards,v.cardByte);
            end
            self:send(CMD.dealCard,{cards = cards},v);
        end
    end
end

function GameLogic:dealOutCard(outCard,record,index,task)
    
    local player = self.players[index];

    if outCard.cardValue == 11 then --加 2 
        record.addCards = record.addCards + 2;
    elseif outCard.cardValue == 15 then
        record.addCards = record.addCards + 4;
        if player.isAI == false then
            outCard.cardType = tasklet.yield()
        else
            outCard.cardType  = math.random(0, 3);
        end 
        self:broadcast(CMD.broadcastAISelectColor,{seat = index,cardType = outCard.cardType})
    elseif outCard.cardValue == 14 then --变牌
        outCard.cardValue = -1;
        if player.isAI == false then
            outCard.cardType = tasklet.yield()
        else
            outCard.cardType  = math.random(0, 3);
        end
        self:broadcast(CMD.broadcastAISelectColor,{seat = index,cardType = outCard.cardType})
    end
    
end

function GameLogic:selectCardType(fd,cmd,data)
    local player = self:getPlayerByID(fd);
    tasklet.resume(self.task,data.cardType);
end


function GameLogic:onUserDisconnect(fd)
    local player = self:getPlayerByID(fd);
    player.isAI = true; -- 托管
    print("用户 托管")
    if player.seat == self.index then
        print("恢复协程")
        tasklet.resume(self.task,nil)
    end
end




function GameLogic:onUserOutCard(fd,cmd,data)
    local id = fd;
    local player = self:getPlayerByID(id);
    
    if player.seat ~= self.index then
        return; -- 不到自己出牌
    end

    local cardIndex = nil;
    for k,v in ipairs(player.cards) do
        if v.cardByte == data.card then
            cardIndex = k;
            break;
        end
    end
    if self.outCard == nil and cardIndex then
        tasklet.resume(self.task,cardIndex);
    else
        local card  = player.cards[cardIndex];
        if card then
            local ret  = self:check(self.outCard,card)
            if ret == true then
                tasklet.resume(self.task,cardIndex); 
            end
        else
            tasklet.resume(self.task,nil);
        end
    end
end

function GameLogic:startGound()
    Players = self.players;
    cardList = self.cardList;
    local offset  = 1;
    self.index =  1;
    local outCard = nil;
    local record = {addCards = 0;}
    local allOutCards = {};
    
    self.index = math.random(1,8)
    self.outCard = nil;
    
    local task = tasklet.spawn(function(...)
        while true do
            for i,v in ipairs(Players) do
                if #v.cards <=0 then
                    self:gameOver();
                    return;
                end
            end
            
            if outCard == nil then
                print("游戏开始");
                local player = Players[self.index];
                local outCardIndex = nil
                self:broadcast(CMD.isUserTurn,{seat = self.index,id = player.id})
                if player.isAI == false then
                    self:send(CMD.isUserTurn,{seat = self.index,id = player.id},player);
                    outCardIndex = tasklet.yield();
                    outCard = table.remove(player.cards,outCardIndex);
                else
                    outCard = table.remove(player.cards,1);
                end
                self.outCard = outCard;         
                self:broadcast(CMD.broadcastOutCard,{seat = self.index,card = outCard.cardByte})
                table.insert(allOutCards,clone(outCard));
                self:dealOutCard(outCard,record,self.index,self.task)
                print(string.format("首轮 %s 号玩家出牌 %s",self.index,outCard.res))
                
            else            
                --- 求出当前是谁操作
                offset = self:getOffset(outCard,offset)
                self.index = self.index + offset;
                if self.index > #Players then
                    self.index = self.index - #Players;
                elseif self.index < 1 then
                    self.index = #Players + self.index;
                end
                
                print(string.format("轮到%s号玩家出牌",self.index))

                local player = Players[self.index]; --获取当前操作玩家
                local nextOutCard = nil

                self:broadcast(CMD.isUserTurn,{seat = self.index,id = player.id})
                if player.isAI == false then --非机器人 阻塞
                    local outCardIndex = self:outCardByAI(player,outCard)
                    print("轮到用户出牌",outCardIndex)
                    if outCardIndex  then
                        self:send(CMD.isUserTurn,{seat = self.index,id = player.id},player);
                        outCardIndex = tasklet.yield();
                        if outCardIndex then
                            nextOutCard = table.remove(player.cards,outCardIndex);
                        end 
                    end
                else -- 机器人 进行AI出牌
                    tasklet.sleep(math.random(1,3));
                    -- tasklet.sleep(0.1);
                    local outCardIndex = self:outCardByAI(player,outCard)
                    if outCardIndex then
                        nextOutCard = table.remove(player.cards,outCardIndex);
                    end
                end
                
                if nextOutCard == nil then --不能出牌，抓牌
                    if outCard.cardValue == 15 or outCard.cardValue == 11 then --重置牌值 处理加4 加 2情况
                        outCard.cardValue = -1; -- 没有值
                    end
                    self:onPlayerPass(record,allOutCards) --玩家不出牌
                else
                    outCard = nextOutCard
                    self:broadcast(CMD.broadcastOutCard,{seat = self.index,card = outCard.cardByte})
                    self.outCard = outCard;
                    table.insert(allOutCards,clone(outCard));
                    self:dealOutCard(outCard,record,self.index,self.task)
                    print(string.format("%s号玩家出牌 %s",self.index,outCard.res))
                end
            end     
        end
    end)
    
    self.task = task;
end

--[[
]]
function GameLogic:onPlayerPass(record,allOutCards)
    local cardList = self.cardList;
    local player = self.players[self.index];
    
    if record.addCards > 0 then
        local addCards = {};
        for i=1,record.addCards do
            if #cardList == 0 then
                allOutCards = TableLib.random(allOutCards)
                for i,v in ipairs(allOutCards) do
                    table.insert(cardList,v)
                end
                allOutCards = {};
            end
            local card = table.remove(cardList,1);
            if card == nil then
                error("没牌了")
            end
            table.insert(player.cards,card);
            table.insert(addCards,card.cardByte)    
        end
        self:broadcast(CMD.broadcastAddCard,{seat = self.index,card = addCards})
        -- print(self.index .."号玩家没有牌可以出，被加 "  .. record.addCards .. " 张牌 当前牌数 "  .. #player.cards)
        record.addCards = 0;

    else
        record.addCards = 0;
        if #cardList == 0 then
            allOutCards = TableLib.random(allOutCards)
            for i,v in ipairs(allOutCards) do
                table.insert(cardList,v)
            end
            allOutCards = {};
        end
        local card = table.remove(cardList,1);
        if card == nil then
            error("没牌了")
        end
        table.insert(player.cards,card);
        self:broadcast(CMD.broadcastAddCard,{seat = self.index,card = {card.cardByte}})
    end
end

function GameLogic:outCardByAI(player,outCard)

    if #player.cards ==1 then
        --todo
        local v = player.cards[1];
        if v.cardValue > 10 then -- 最好一张不能出功能牌
            return;
        end
    end

    if outCard.cardValue == -1 then --变色牌。没有值，只能出相同的类型
        for i,v in ipairs(player.cards) do
            if v.cardType == outCard.cardType then
                return i;
            elseif v.cardType == 4 then
                return i;
            end
        end
    elseif outCard.cardValue == 11 or outCard.cardValue == 15 then --加 2 --加4
        for i,v in ipairs(player.cards) do
            if v.cardValue == outCard.cardValue then
                return i;
            elseif v.cardValue == 15 then
                return i;
            end
        end
    else 
        for i,v in ipairs(player.cards) do
            if v.cardType == outCard.cardType then
                return i;
            elseif v.cardValue == outCard.cardValue then
                return i;
            elseif v.cardType == 4 then
                return i;
            end
        end
    end
end


return GameLogic;