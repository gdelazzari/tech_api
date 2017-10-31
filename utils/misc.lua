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

--- Vector cross product.
-- @function vector_cross_product
-- @tparam table a Vector A
-- @tparam table b Vector B
-- @treturn table Resulting vector
function tech_api.utils.misc.vector_cross_product(a, b)
	return {x = a.y * b.z - b.y * a.z,
					y = a.z * b.x - b.z * a.x,
					z = a.x * b.y - b.x * a.y}
end

--- Gets the vector pointing top.
-- This function returns the vector that points out of the top of a node,
-- given its facedir parameter.
-- @function facedir_to_top_dir
-- @tparam table facedir The facedir parameter (node's param2 field)
-- @treturn table The vector pointing out from the top of the node
function tech_api.utils.misc.facedir_to_top_dir(facedir)
	return 	({[0] = {x =  0, y =  1, z =  0},
	                {x =  0, y =  0, z =  1},
	                {x =  0, y =  0, z = -1},
	                {x =  1, y =  0, z =  0},
	                {x = -1, y =  0, z =  0},
	                {x =  0, y = -1, z =  0}})
		[math.floor(facedir / 4)]
end

--- Convert a face name to a vector.
-- This function converts a facedir parameter (a node's param2)
-- and a "facename" (front/back/left/top/...) to a vector pointing out of the
-- face specified.
-- @function facename_to_vector
-- @tparam table facedir The facedir parameter (param2 field from a node object)
-- @tparam string facename The name of the face you want the returned vector to
-- point out of.
-- @treturn table The vector pointing out of the face specified, considering the
-- orientation of the node
function tech_api.utils.misc.facename_to_vector(facedir, facename)
	local top = tech_api.utils.misc.facedir_to_top_dir(facedir)
	local bottom = vector.multiply(top, -1)
	local back = minetest.facedir_to_dir(facedir)
	if facename == 'back' then
		return back
	elseif facename == 'front' then
		return vector.multiply(back, -1)
	elseif facename == 'right' then
		return tech_api.utils.misc.vector_cross_product(top, back)
	elseif facename == 'left' then
		return tech_api.utils.misc.vector_cross_product(bottom, back)
	elseif facename == 'top' then
		return top
	elseif facename == 'bottom' then
		return bottom
	else
		return nil
	end
end
