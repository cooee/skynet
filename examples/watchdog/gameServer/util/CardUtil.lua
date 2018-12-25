--[[--ldoc desc
@module CardUtil
@author YuchengMo

Date   2018-12-6
Last Modified by   YuchengMo
Last Modified time 2018-12-25 15:01:30
]]

-- require("LuaKit._load")
local CardUtil = {};



-- cards =
-- {
-- 79,78,11,4,5,6,7,8,
-- 9,10,3,12,13,17,18,19,
-- 20,21,22,23,24,25,26,27,28,
-- 29,33,34,35,36, 37,38,39,40,
-- 41, 42, 43,44,45,49,50,51,52,53,54,
-- 55,56,57,58,59,60,61,78,79,
-- 78,79,78,79,1,2,
-- }

local bit = require("bit32");

-- local bit = require("bit");

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

	dumpToFile("cards", cards)
	local cardInfos = {};

	for i, cardByte in ipairs(cards) do
		local temp = CardUtil.getCardInfo(cardByte);
		cardInfos[i] = temp;
	end

	dumpToFile("cardInfos",cardInfos)
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
	return cardInfo;
end

return CardUtil;
