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
