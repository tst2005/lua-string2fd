
local class = require "mini.class.pico"

local fd_class = class()

local math_floor = assert(math.floor)
local string_sub, string_find = assert(string.sub), assert(string.find)

local internal = "_"
--local internal = {}
-- [0] = data
-- [1] = cursor

local function usable(self)
	local _ = self[internal]
	if not _.opened then
		error( "attempt to use a closed file", 2) -- FIXME: 3 ?
	end
	return _
end

function fd_class:read(n)
	local _ = usable(self)
	local data = _[0]
	local cursor = _[1]
	assert(n=="*a" or n=="*l" or n=="*L" or type(n)=="number", "only read(number) implemented")
	if cursor > #data then return nil end
	if n=="*a" then
		local cursor2 = cursor
		_[1] = #data+1
		return data:sub(cursor2, -1)
	end
	if n=="*l" or n=="*L" then
		local e = string_find(data, "\n", cursor, true)
		local s = cursor
		_[1] = (e or #data)+1
		if n=="*l" then
			return string_sub(data, s, (e and (e-1) or -1))
		else
			return string_sub(data, s, (e and e or -1))
		end
	end
	assert(n>=0, "read(n): n must be positive")
	if cursor > #data then return nil end
	n=math_floor(n) -- integer (else cursor will grow more than expected : 0.9 + 0.9 + 0.9 becomes more than 0)
	local v = string_sub(data, cursor, cursor+n-1)
	_[1] = cursor+n
	return v
end

function fd_class:close()
	local _ = usable(self)
	_.opened = false
	_[2] = "closed"
	return true
end

--function fd_class:seek() end

function fd_class:init(data)
	local zerox = tostring(self):match(": (0x.*)$")
	self[internal] = {
		[0]=data,	-- data
		[1]=1,		-- cursor
		[2]=zerox,	-- 0xffffffff
		opened = true,
	}
	local mt = getmetatable(self)
	if not mt then mt = {} end
	function mt.__tostring()
		local _ = self[internal]
		return "file ("..tostring(_[2])..")"
	end
	return self
end

local function string2fd(data)
	return fd_class.init(fd_class(), data)
end

do
	local data = "abcde\nz"
	local x = string2fd(data)

	local tmp = os.tmpname()
	local y = io.open(tmp, "w")
	y:write(data)
	y:close()
	y = io.open(tmp, "r")
	os.remove(tmp)

	--local fd = io.stdin
	for _, fd in ipairs{y, x} do
--print("test with fd", fd)
		assert(fd:read(1)=="a")
		assert(fd:read(2)=="bc")
		assert(fd:read(0)=="")
		assert(fd:read(3)=="de\n")
		assert(fd:read(3)=="z")
		assert(fd:read(1)==nil)
--print("pass")
	end

	local z = string2fd("aaa\nbbb\n\nccc")
	assert(z:read("*l")=="aaa")
	assert(z:read("*l")=="bbb")
	assert(z:read("*l")=="")
	assert(z:read("*l")=="ccc")
	local z = string2fd("aaa\nbBb\n\nccc")
	assert(z:read("*L")=="aaa\n")
	assert(z:read(1)=="b")
	assert(z:read("*L")=="Bb\n")
	assert(z:read("*L")=="\n")
	assert(z:read("*L")=="ccc")

	if z.close then
		assert(tostring(z):find("^file %(0x[0-9a-fA-F]+%)$"))
		assert(pcall(function() z:close() end))
		assert(tostring(z):find("^file %(closed%)$"))
		assert(not pcall(function() z:close() end))
	end

	if not (...) then
		print("string2fd: selftest ok")
	end
end
return string2fd
