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
