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

--- Returns the transporter definition for a node name.
-- This function returns the *only* transporter definition for the node name
-- provided (if it has any, otherwise it returns nil). I wrote *only* because
-- a node must not have more than one transporter definition (it may have none,
-- but no more than 1) otherwise something went wrong.
-- @function get_transporter_definition
-- @tparam string node_name The node name you want to get the transporter
-- definition
-- @treturn table The definition table
function tech_api.energy.get_transporter_definition(node_name)
  if tech_api.energy.definitions[node_name] then
    for def_name, config in pairs(tech_api.energy.definitions[node_name]) do
      if config.group == 'transporter' then
        return config
      end
    end
  end
  return nil
end
