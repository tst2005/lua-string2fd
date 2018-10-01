local function string2fd(data)
	local fd = {}
	local cursor = 1
	function fd:read(n)
		assert(n=="*a" or n=="*l" or n=="*L" or type(n)=="number", "only read(number) implemented")
		if cursor > #data then return nil end
		if n=="*a" then
			local cursor2 = cursor
			cursor = #data+1
			return data:sub(cursor2, -1)
		end
		if n=="*l" or n=="*L" then
			local e = data:find("\n", cursor, true)
			local s = cursor
			cursor = (e or #data)+1
			if n=="*l" then
				return data:sub(s,(e and (e-1) or -1))
			else
				return data:sub(s,(e and e or -1))
			end
		end
		assert(n>=0, "read(n): n must be positive") 
		if cursor > #data then return nil end
		n=math.floor(n) -- integer (else cursor will grow more than expected : 0.9 + 0.9 + 0.9 becomes more than 0)
		local v = data:sub(cursor, cursor+n-1)
		cursor = cursor+n
		return v
	end
	--function fd:close() return true end
	return fd
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

--	print("string2fd: selftest ok")
end
return string2fd
