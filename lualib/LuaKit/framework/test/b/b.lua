

local currentModuleName = ...

dump(currentModuleName,"d")
-- local c = import(".c")

local b = {}


function b:test( ... )
	local c = import(".c", currentModuleName)
	dump(c)
end

return b;