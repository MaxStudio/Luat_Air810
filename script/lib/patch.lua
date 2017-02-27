-- patch some function

local oldostime = os.time

function safeostime(t)
	return oldostime(t) or 0
end

os.time = safeostime
