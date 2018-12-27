-- @Author: 莫玉成
-- @Date:   2018-12-03 17:41:18
-- @Last Modified by   YuchengMo
-- @Last Modified time 2018-12-27 11:43:02

local skynet = require "skynet"

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
        print(msg)
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

return M