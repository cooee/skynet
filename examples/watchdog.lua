local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

-- require("LuaKit._load");

local coroutine = require "skynet.coroutine"


function cancelable_timeout(ti, func)
    local function cb()
        if func then
            func()
        end
    end
    local function cancel()
        func = nil
    end
    skynet.timeout(ti, cb)
    return cancel
end

local M = {}

local function resume_task(task, ...)
    if task == nil then
        return;
    end
    local success
    success, task.action = coroutine.resume(task.coroutine, ...)
    if not success then
        local msg = debug.traceback(task.coroutine, task.action)
        print("task error",msg)
    elseif task.action then
        task.action(function(...)
            resume_task(task, ...)
        end)
        return
    end
end

---
-- 启动微线程。
-- @function [parent=#tasklet] spawn
-- @param #function fn
-- @param ... 传给fn的参数。
-- @usage
-- tasklet.spawn(function(arg1, arg2)
--     while true do
--         local dt = tasklet.sleep(0.1)
--         sprite.x = sprite.x + dt * 10
--     end
-- end, arg1, arg2)
function M.spawn(fn, ...)
    local co = coroutine.create(fn)
    local task = {
        coroutine = co,
    }
    resume_task(task, ...)
    return task
end


---
-- 恢复微线程。
-- @function [parent=#tasklet] resume
function M.resume(task,...)
    if task.action and  task.action.cancel and task.action.__sleep__ then
        task.action:cancel()
    end
    resume_task(task, ...)
end

function M.yield(...)
    return coroutine.yield(...)
end


require("LuaKit._load");

---
-- 在微线程中执行，暂停 n 秒
-- @function [parent=#tasklet] sleep
-- @param #number n
function M.sleep(n,tag)
    local action = {
        cancel = function(self)
            if self._handler then
                self.__sleep__ = nil;
                self._handler()
            end
        end,
        tag = tag,
    }
    setmetatable(action, {
        __call = function(self, callback)
            self.__sleep__ = n;
            self._handler = cancelable_timeout(n*100,callback);
        end
    })
    return coroutine.yield(action)
end

local tasklet = M;

function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr)
    agent[fd] = skynet.newservice("agent")
    skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
end

function SOCKET.close(fd)
    print("socket close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    print("socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end


function cancelable_timeout(ti, func)
    local function cb()
        if func then
            func()
        end
    end
    local function cancel()
        func = nil
    end
    skynet.timeout(ti, cb)
    return cancel
end

-- local cancel = cancelable_timeout(ti, dosomething)

-- cancel()  -- canel dosomething


local task = nil
function CMD.start(conf)
    skynet.call(gate, "lua", "open" , conf)

    cancelable_timeout(100,function( ... )
        print("myc")
        if task and task.action then
            dump(task)
            tasklet.resume(task,"222222sss")
        end
    end)

    task = tasklet.spawn(function( ... )
        tasklet.sleep(4,"tag myc");
        print("2222222222222")
    end)




end

function CMD.close(fd)
    close_agent(fd)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            f(...)
            -- socket api don't need return
        else
            local f = assert(CMD[cmd])
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    gate = skynet.newservice("gate")
end)
