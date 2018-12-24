-- @Author: 莫玉成
-- @Date:   2018-12-03 17:41:18
-- @Last Modified by   YuchengMo
-- @Last Modified time 2018-12-20 18:11:22

local skynet = require "skynet"

local coroutine = require "skynet.coroutine"


local Clock = skynet;

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
    resume_task(task, ...)
end

function M.yield(...)
    return coroutine.yield(...)
end


---
-- 在微线程中执行，暂停 n 秒
-- @function [parent=#tasklet] sleep
-- @param #number n
function M.sleep(n)
    return coroutine.yield(setmetatable({
        }, {
            __call = function(self, callback)
                Clock.sleep(n*100) -- 1/100
                callback();
            end
        }))
end

return M