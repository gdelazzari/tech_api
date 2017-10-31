--[[
LUA FlatDB from https://github.com/uleelx/FlatDB
by @uleelx on GitHub

The MIT License (MIT)

Copyright (c) 2015 Peer Zeng

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local mp = dofile(tech_api.modpath .. "/libs/mp.lua")

local function isFile(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function isDir(path)
	path = string.gsub(path.."/", "//", "/")
	local ok, err, code = os.rename(path, path)
	if ok or code == 13 then
		return true
	end
	return false
end

local function load_page(path)
	local ret
	local f = io.open(path, "rb")
	if f then
		ret = mp.unpack(f:read("*a"))
		f:close()
	end
	return ret
end

local function store_page(path, page)
	if type(page) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write(mp.pack(page))
			f:close()
			return true
		end
	end
	return false
end

local pool = {}

local db_funcs = {
	save = function(db, p)
		if p then
			if type(p) == "string" and type(db[p]) == "table" then
				return store_page(pool[db].."/"..p, db[p])
			else
				return false
			end
		end
		for p, page in pairs(db) do
			if not store_page(pool[db].."/"..p, page) then
				return false
			end
		end
		return true
	end
}

local mt = {
	__index = function(db, k)
		if db_funcs[k] then return db_funcs[k] end
		if isFile(pool[db].."/"..k) then
			db[k] = load_page(pool[db].."/"..k)
		end
		return rawget(db, k)
	end
}

pool.hack = db_funcs

return setmetatable(pool, {
	__mode = "kv",
	__call = function(pool, path)
		assert(isDir(path), path.." is not a directory.")
		if pool[path] then return pool[path] end
		local db = {}
		setmetatable(db, mt)
		pool[path] = db
		pool[db] = path
		return db
	end
})
