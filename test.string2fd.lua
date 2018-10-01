
local modname = ((...) and (...).."." or "").."string2fd"
print("load ", modname)
local string2fd = require(modname)

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

	--print("string2fd: selftest ok")
end
