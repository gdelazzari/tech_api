--- Provides various generic methods used in other parts of the package.
--
-- @module tech_api.utils.misc

-- Module table
tech_api.utils.misc = {}

--- Hashes a position vector as a 6-byte string.
-- Allows to use a position as a table index along with @{dehash_vector}
-- @function hash_vector
-- @param v The position vector to hash as a table with x, y, z values
-- @treturn string The resulting string
function tech_api.utils.misc.hash_vector(v)
	local x = v.x + 32768
	local y = v.y + 32768
	local z = v.z + 32768
	return string.char(math.floor(x / 256)) .. string.char(x % 256) ..
		string.char(math.floor(y / 256)) .. string.char(y % 256) ..
		string.char(math.floor(z / 256)) .. string.char(z % 256)
end

--- De-hashes a 6-byte position string into a position vector.
-- Allows to use a position as a table index along with @{hash_vector}
-- @function dehash_vector
-- @tparam string s The hashed position vector as a 6-byte string
-- @return The de-hashed position vector
function tech_api.utils.misc.dehash_vector(s)
	return {
		x = 256 * string.byte(s, 1) + string.byte(s, 2) - 32768,
		y = 256 * string.byte(s, 3) + string.byte(s, 4) - 32768,
		z = 256 * string.byte(s, 5) + string.byte(s, 6) - 32768,
	}
end

--- Returns a list of positions connected to the one given.
-- Used to get search positions for connected wires when discovering a network.
-- @function get_connected_positions
-- @tparam table pos The starting position
-- @treturn table A Lua array (integer indexed table) with the 6 positions
-- connected to the one given.
function tech_api.utils.misc.get_connected_positions(pos)
	local result = {}
	table.insert(result, {x = pos.x + 1, y = pos.y, z = pos.z})
	table.insert(result, {x = pos.x - 1, y = pos.y, z = pos.z})
	table.insert(result, {x = pos.x, y = pos.y + 1, z = pos.z})
	table.insert(result, {x = pos.x, y = pos.y - 1, z = pos.z})
	table.insert(result, {x = pos.x, y = pos.y, z = pos.z + 1})
	table.insert(result, {x = pos.x, y = pos.y, z = pos.z - 1})
	return result
end

--- Checks the equality of two positions
-- @function positions_equal
-- @tparam table a First position to compare
-- @tparam table b Second position to compare
-- @treturn boolean Compare result
function tech_api.utils.misc.positions_equal(a, b)
	if a.x == b.x and a.y == b.y and a.z == b.z then
		return true
	else
		return false
	end
end
