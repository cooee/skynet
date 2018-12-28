
root = "./"
thread = 8
logger = nil
harbor = 0

start = "ClusterCenter"

bootstrap = "snlua bootstrap"	-- The service for bootstrap
luaservice = "./service/?.lua;./test/?.lua;./examples/test/?.lua;./examples/?.lua;"
lualoader = "lualib/loader.lua"
cpath = "./cservice/?.so"

snax = "./test/?.lua"
lua_path = root.."lualib/?.lua;"..root.."lualib/?/init.lua;"..root.."lualib/LuaKit/?.lua;"