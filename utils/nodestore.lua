--- Provides methods to store metadata-like fields for Minetest nodes.
--
-- It does that by using a Lua table which is indexed
-- by the position.
-- It also provides methods to dump and retrieve the table from the disk in
-- efficient ways.
--
-- @module tech_api.utils.nodestore

-- Module table
tech_api.utils.nodestore = {}

--- This table stores the metadata-like information about the nodes.
-- It is indexed by an hashed position vector
-- (using @{tech_api.utils.misc.hash_vector}). Access to this table happens
-- directly by referencing it from other modules of the package
-- @table data
tech_api.utils.nodestore.data = {}

--- This function loads the table from the tech_api ModStorage object.
-- The table is loaded into the global table @{tech_api.utils.nodestore.data} by
-- deserializing the string saved in the ModStorage
-- @function load
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.load()
  local nodestore_string = tech_api.modstorage:get_string('nodestore')
  if nodestore_string then
    tech_api.utils.nodestore.data = minetest.deserialize(nodestore_string)
    if tech_api.utils.nodestore.data then
      return true
    else
      tech_api.utils.nodestore.data = {}
      return false
    end
  else
    return false
  end
end

--- This function saves the table to the tech_api ModStorage object.
-- The global table @{tech_api.utils.nodestore.data} is serialized and saved
-- as a string in the ModStorage
-- @function save
-- @treturn boolean Whether the operation was successful or not
function tech_api.utils.nodestore.save()
  tech_api.modstorage:set_string('nodestore', minetest.serialize(tech_api.utils.nodestore.data))
  return true
end
