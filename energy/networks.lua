---
-- @module tech_api.energy

--- Network graph management.
-- These elements are used internally to manage the network graphs.
-- @section networks

--- Networks graph table.
-- This table will store the structure and the "content" of each network.
-- Each network has a numeric id which is also its index in the table.
-- @table networks
tech_api.energy.networks = {}

--- Reset the network graph.
-- This function resets the networks graph to a clean state.
-- @function reset_networks
function tech_api.energy.reset_networks()
  tech_api.energy.networks = {}
end

--- Create a network.
-- This function creates a new network of devices in the graph.
-- @function create_network
-- @treturn number The new network id
function tech_api.energy.create_network()
  local id = #tech_api.energy.networks + 1
  tech_api.energy.networks[id] = {}
  tech_api.energy.networks[id].devices = {}
  return id
end

--- Add a device to a network.
-- This function adds a device to a specific network id
-- @function add_device_to_network
-- @tparam number
-- @treturn number The new network id
function tech_api.energy.add_device_to_network()
  
end

function tech_api.energy.traverse_network(starting_pos)

end

function tech_api.energy.rebuild_networks()

end
