--[[--ldoc 框架加载入口
@module _load
@author YuchengMo

Date   2017-12-20 11:47:08
Last Modified by   YuchengMo
Last Modified time 2018-12-21 17:00:37
]]
local startMem = collectgarbage("count")
LuaKit = {}
local __g = _G

local exports = {}
LuaKit.globals = {}
LuaKit.exports = exports;

---禁用全局变量
function LuaKit:disableGobal()
    setmetatable(__g, {
        __newindex = function(_, name, value)
            if exports[name] then ---引擎导入的全局变量
               rawset(LuaKit.globals, name, value)
               return;
            end
            local str = debug.traceback();
            dump(str)
            error(str .. "n" .. string.format("USE \" LuaKit.globals.%s = value \" INSTEAD OF SET GLOBAL VARIABLE", name))

            rawset(LuaKit.globals, name, value)

        end,
        __index = function(_,name)
            return rawget(LuaKit.globals, name)
        end
    })
end


function LuaKit:enableGlobal()
    setmetatable(__g, {
            __index = function(_, name)
                return rawget(LuaKit.globals, name)
            end
        })
end

function LuaKit:freeGlobal()
    setmetatable(__g, {})
    LuaKit = {};
    LuaKit.globals = {}

end

function LuaKit:getCurModulePath()
    local _,path = debug.getlocal(2,1);
    return path;
end

local root = ""

local framework = require("framework._load")
framework:load(root);

-- LuaKit:disableGobal()


local endMem = collectgarbage("count")