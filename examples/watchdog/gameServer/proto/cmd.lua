-- @Author: 莫玉成
-- @Date:   2018-12-18 11:35:50
-- @Last Modified by   YuchengMo
-- @Last Modified time 2018-12-19 15:38:39


local CMD = {}



CMD.login = 101;
CMD.loginSuccess = 102;


CMD.chat = 1001;

CMD.enterRoom = 10001;
CMD.enterRoomSuccess = 10002; --自己进入房间成功

CMD.dealCard = 10010;        --  发牌

CMD.outCard = 10012;        --  出牌

CMD.selectCardType = 10014 --玩家选择变色

CMD.isUserTurn = 10016 --轮到玩家，玩家回合

CMD.userRequestStartGame = 10018 --玩家请求开始游戏，人数不够就加入AI


CMD.broadcastEnterRoomSuccess = 20002; --广播用户进入房间成功

CMD.broadcastOutCard = 20202; --广播用户出牌

CMD.broadcastAISelectColor = 20204; --广播用户出牌

CMD.broadcastAddCard = 20206; --广播用户被加牌

CMD.broadcastSelectCardType = 20210 --玩家选择变色

CMD.broadcastGameOver = 20208; --广播用户被加牌



return CMD