--[[--ldoc desc
@module CardUtil
@author YuchengMo

Date   2018-12-6
Last Modified by   YuchengMo
Last Modified time 2018-12-18 17:01:19
]]
local CardUtil = class();





local bit = require("bit32");

function CardUtil.getAllCards()
	local cards = {}
	for i = 0, 3 do
		for j = 1, 13 do
			local x = bit.lshift(i, 4);
			local value = bit.bor(x, j);
			table.insert(cards, value);
		end
	end

	for i=1,4 do
		table.insert(cards, 0x4e);
		table.insert(cards, 0x4f);
	end


	local cardInfos = {};

	for i, cardByte in ipairs(cards) do
		local temp = CardUtil.getCardInfo(cardByte);
		cardInfos[i] = temp;
	end


	return cardInfos;
end

local cardTypes = {[0] = "b",[1] = "g",[2] =  "r",[3] = "y",[4] = ""}

function CardUtil.getCardInfo(cardByte)

	local cardTypeValue = cardByte;
	local cardType = bit.rshift(cardTypeValue, 4);
	local cardNoTypeValue = bit.band(cardTypeValue, 0x0f);

	local cardInfo = {};
	cardInfo.cardByte = cardTypeValue;
	cardInfo.cardType = cardType;
	cardInfo.cardValue = cardNoTypeValue;

	cardInfo.res = cardTypes[cardType] .. cardNoTypeValue

	if cardByte == 0x4e then
		cardInfo.res = "bian"
	elseif cardByte == 0x4f then
		cardInfo.res = "jia4"
	end
	
	-- local Log = import("bos.framework.logt")
	return cardInfo;
end


return CardUtil;
