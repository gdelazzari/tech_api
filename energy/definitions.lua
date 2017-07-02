---
-- @module tech_api.energy

--- Definitions management.
-- These elements are used internally to manage the registered devices
-- definitions.
-- @section definitions

--- Nodes definitions table.
-- This table will store the definitions for each node name that has registered
-- to the API. A definition is just a copy of the Lua table that was passed as
-- the config parameter when calling @{tech_api.energy.register_transporter} or
-- @{tech_api.energy.register_device}.
-- @table definitions
tech_api.energy.definitions = {}

--- Add a definition to the internal table.
-- @function add_definition
-- @tparam string node_name Node name
-- @tparam string def_name Definition name
-- @tparam string group Is the definition group (i.e. "transporter" or "device")
-- @tparam table config Definition table
function tech_api.energy.add_definition(node_name, def_name, group, config)
  if not tech_api.energy.definitions[node_name] then
    tech_api.energy.definitions[node_name] = {}
  end
  tech_api.energy.definitions[node_name][def_name] = config
  tech_api.energy.definitions[node_name][def_name].group = group
end

--- Checks whether or not a node type has a definition for a group.
-- By group we mean "device" or "transporter". If the specified
-- node name has at least one definition for that group, the function returns
-- true.
-- @function has_definition_for_group
-- @tparam string node_name The name the node registered with
-- @tparam string group The definition group you're looking for
-- @treturn boolean True if the node has *at least* one definition of that group,
-- otherwise false
function tech_api.energy.has_definition_for_group(node_name, group)
  if tech_api.energy.definitions[node_name] then
    for def_name, config in pairs(tech_api.energy.definitions[node_name]) do
      if config.group == group then
        return true
      end
    end
  end
  return false
end
