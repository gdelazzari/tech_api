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

--- Nodestore FlatDB path
-- This variable stores the path to the tech_api nodestore FlatDB directory
tech_api.utils.nodestore.db_path = minetest.get_worldpath() .. "/tech_api"

-- Ensure the DB directory exists
minetest.mkdir(tech_api.utils.nodestore.db_path)

-- Temporary helper function to print a formatted table
function tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end

--- This function loads the nodestore data with the FlatDB library.
-- The data is loaded into the global table @{tech_api.utils.nodestore.data}
-- @function load
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.load()
	tech_api.utils.log.print('verbose', "Loading nodestore DB")

	-- Create the FlatDB object
	tech_api.utils.nodestore.db = FlatDB(tech_api.utils.nodestore.db_path)

	-- If there's not a "nodes" page in the DB, create an empty one
	if not tech_api.utils.nodestore.db['nodes'] then
		tech_api.utils.log.print('verbose', "No existing DB 'nodes' page found, initializing a new one")
		tech_api.utils.nodestore.db['nodes'] = {}
	end

	-- If there's not a "sync" page in the DB, create an empty one
	if not tech_api.utils.nodestore.db['sync'] then
		tech_api.utils.log.print('verbose', "No existing DB 'sync' page found, initializing a new one")
		tech_api.utils.nodestore.db['sync'] = {}
	end

	print("[nodes]")
	tprint(tech_api.utils.nodestore.db['nodes'], 2)

	print("[sync]")
	tprint(tech_api.utils.nodestore.db['sync'], 2)

	-- Bind the page object to tech_api.utils.nodestore.data
	tech_api.utils.nodestore.data = tech_api.utils.nodestore.db['nodes']

	-- Merge the partial data (that should be, in any case, more recent than the
	-- base one) into the main table
	for pos_hash, node in pairs(tech_api.utils.nodestore.db['sync']) do
		for def_name, def_data in pairs(node) do
			for field, value in pairs(def_data) do
				tech_api.utils.nodestore.data[pos_hash].definitions[def_name][field] = value
			end
		end
	end

	-- Success
	return true
end

--- This function saves all the nodestore data with the FlatDB library.
-- The global table @{tech_api.utils.nodestore.data} contains the data that will
-- be saved. The function will also call @{tech_api.utils.nodestore.partial_save}
-- @function save
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.save()
	tech_api.utils.log.print('verbose', "Saving nodestore DB")

	-- First save the partial data
	tech_api.utils.nodestore.partial_save()

	-- Then, as for the node table, ensure we're writing the right data
	tech_api.utils.nodestore.db['nodes'] = tech_api.utils.nodestore.data

	-- And then save the data to disk through FlatDB
  tech_api.utils.nodestore.db:save("nodes")

	-- Success
  return true
end

--- This function saves the nodestore partial data with the FlatDB library.
-- The data to save is generated on-the-fly and consists of only the fields
-- that change often (such as storage devices content)
-- @function partial_save
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.partial_save()
	tech_api.utils.log.print('verbose', "Saving partial nodestore sync data")

	-- Build up the data we need to write
	local data = {}

	-- For each node in the nodestore
	for pos_hash, node in pairs(tech_api.utils.nodestore.data) do
		-- If the node has device definitions
		if node.is_device and node.is_device == true then
			-- For each device definition
			for def_name, nd_def in pairs(node.definitions) do
				-- If the definition has a "content" field, then add the node to the
				-- data we're about to write, since that's the kind of fields we want
				-- to keep synced
				if nd_def.content then
					if not data[pos_hash] then
						data[pos_hash] = {}
					end
					data[pos_hash][def_name] = {
						content = nd_def.content
					}
				end
			end
		end
	end

	-- Assign the data we generated to the FlatDB "sync" page
	tech_api.utils.nodestore.db["sync"] = data

	-- Save the partial data through FlatDB
	-- (calling FlatDB's :save method with the page name to save only that)
  tech_api.utils.nodestore.db:save("sync")

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

-- Register a Minetest globalstep handler to dump the nodestore partial data
-- regularly
local nodestore_partial_dump_countdown = 200

minetest.register_globalstep(function(delta_time)
  nodestore_partial_dump_countdown = nodestore_partial_dump_countdown - 1

	if nodestore_partial_dump_countdown <= 0 then
		tech_api.utils.nodestore.partial_save()
		nodestore_partial_dump_countdown = 200
	end
end)
