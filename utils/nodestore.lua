--- Provides methods to store metadata-like fields for Minetest nodes.
--
-- It does that by using a Lua table which is indexed
-- by the position.
-- It also provides methods to dump and retrieve the table from the disk in
-- efficient ways.
--
-- @module tech_api.utils.nodestore

-- Libraries/includes
FlatDB = dofile(tech_api.modpath .. "/libs/flatdb.lua")

-- Module table
tech_api.utils.nodestore = {}

--- This table stores the metadata-like information about the nodes.
-- It is indexed by an hashed position vector
-- (using @{tech_api.utils.misc.hash_vector}). Access to this table happens
-- directly by referencing it from other modules of the package
-- @table data
tech_api.utils.nodestore.data = {}

--- This function loads the nodestore data with the FlatDB library.
-- The data is loaded into the global table @{tech_api.utils.nodestore.data}
-- @function load
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.load()
	tech_api.utils.log.print('verbose', "Loading nodestore DB")

	-- Open a FlatDB object on the user's world root directory
	tech_api.utils.nodestore.db = FlatDB(minetest.get_worldpath())

	-- If there's not a "nodes" page in the DB, create an empty one
	if not tech_api.utils.nodestore.db['nodes'] then
		tech_api.utils.log.print('verbose', "No existing DB page found, initializing a new one")
		tech_api.utils.nodestore.db['nodes'] = {}
	end

	-- Bind the page object to tech_api.utils.nodestore.data
	tech_api.utils.nodestore.data = tech_api.utils.nodestore.db['nodes']

	-- Success
	return true
end

--- This function saves the nodestore data with the FlatDB library.
-- The global table @{tech_api.utils.nodestore.data} contains the data that will
-- be saved
-- @function save
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.save()
	tech_api.utils.log.print('verbose', "Saving nodestore DB")

	-- Ensure we're writing the right data
	tech_api.utils.nodestore.db['nodes'] = tech_api.utils.nodestore.data

	-- Save data to disk through FlatDB
  tech_api.utils.nodestore.db:save()

	-- Success
  return true
end

--- This function handles a discrepancy detected in the nodestore.
-- The function must be called every time something in the nodestore doesn't
-- match what we expected with respect to the real Minetest world.
-- Currently it simply prints a message to warn the user by telling that manual
-- intervention is probably required, but it will hopefully do more complex
-- stuff in the future to partially fix the problem
-- @function on_discrepancy_detected
function tech_api.utils.nodestore.on_discrepancy_detected()
	tech_api.utils.log.print('error', "The nodestore may be getting out of sync with respect to the real Minetest world.")
	tech_api.utils.log.print('error', "Please fix the nodestore as soon as possible to prevent bad behaviors.")
end
