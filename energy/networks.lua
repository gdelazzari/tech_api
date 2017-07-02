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
-- @tparam table entry_point The entry point for the network (a position vector).
-- It may be nil.
-- @treturn number The new network id
function tech_api.energy.create_network(entry_point)
  local id = #tech_api.energy.networks + 1
  tech_api.energy.networks[id] = {}
  tech_api.energy.networks[id].devices = {}
  tech_api.energy.networks[id].entry_point = entry_point
  return id
end

--- Add a device to a network.
-- This function adds a device to a specific network id
-- @function add_device_to_network
-- @tparam number The network id
-- @tparam table The table that represents the device
function tech_api.energy.add_device_to_network(id, device)
  -- no checks on the validity of the id, so if something goes wrong it throws
  -- an error and we'll know that
  tech_api.energy.networks[id].devices[device.pos] = device
end

--- Recursive function to discover a network.
-- The function is called when rebuilding the networks graph from scratch, and
-- will start from a given position to discover an entire network. The function
-- will also add the devices it finds to the network id it's traversing through.
-- @function discover_network
-- @tparam table pos The starting position
-- @tparam number current_network_id The current network_id (used for recursion).
-- If you're calling this function to rebuild the network graph, you'll probably
-- have this value equal to -1 for the first call, since you're starting the
-- discovery from a transporter that doesn't belong to any network yet.
function tech_api.energy.discover_network(pos, current_network_id)
  -- set the network id for the current transporter node
  local network_id = current_network_id
  if network_id == -1 then
    -- we need to create a new network, since this is the first node
    network_id = tech_api.energy.create_network(starting_pos)
  end
  local pos_hash = tech_api.utils.misc.hash_vector(pos)
  tech_api.utils.nodestore.data[pos_hash].network_id = network_id

  -- also flag it as visited
  tech_api.utils.nodestore.data[pos_hash].visited = true

  -- search for connected devices AND go recursive on connected transporters
  local connected_positions = tech_api.utils.misc.get_connected_positions(pos)
  for p = 1, #connected_positions do
    -- the position we're currently looking at
    local search_pos = connected_positions[p]
    local search_pos_hash = tech_api.utils.misc.hash_vector(search_pos)

    -- let's bring the nodestore data local, because of performance (global
    -- variables access is slower)
    local search_pos_nodestore = tech_api.utils.nodestore.data[search_pos_hash]

    -- if there's something in the current serach position...
    if search_pos_nodestore then
      -- behave differently if the node is a transporter or not
      if search_pos_nodestore.is_transporter == true then
        -- this is a transporter, do recursive search if still not visited

        -- TODO check transporter class is the same!
        if search_pos_nodestore.visited == false then
          tech_api.energy.discover_network(search_pos, network_id)
        end

      else
        -- this is a device, connect it to the network

        -- TODO check linkable_faces and class! (also needed to determine which
        -- definition for the node will "connect" to the network). Also we need
        -- to check if a device definition is already connected or not (since) a
        -- definition may have multiple linkable faces thus may already be
        -- connected to another network (depending on how the transporters are
        -- placed around)

        -- TODO absolutely wrong, but for testing we assume only one def named 'default'
        local definition = tech_api.energy.definitions[search_pos_nodestore.node_name]['default']
        tech_api.energy.add_device_to_network(network_id, {
          pos = search_pos,
          node_name = search_pos_nodestore.node_name,
          def_name = 'default',
          type = definition.type,
          max_rate = definition.max_rate,
          current_rate = 0,
          callback = definition.callback,
          -- maybe randomize this a bit to avoid tons of callbacks at the same
          -- time after networks rediscovery?
          callback_countdown = 1,
          content = 0,
          capacity = 0
        })
      end
    end
  end
end

--- Reset and rebuild the entire network graph.
-- This function clears the current network graph and rediscovers all the
-- networks in the world from scratch, using @{tech_api.energy.discover_network}.
-- @function rediscover_networks
function tech_api.energy.rediscover_networks()
  -- reset the network graph, we'll start from scratch
  tech_api.energy.reset_networks()

  -- remove any leftover flag (from previous traversals)
  tech_api.energy.reset_discovery_flags()

  -- while there are still unvisited nodes
  while true do
    -- get the first unvisited transporter node we find
    local unvisited_pos = nil
    for pos_hash, content in pairs(tech_api.utils.nodestore.data) do
      if tech_api.utils.nodestore.data[pos_hash].visited == false then
        unvisited_pos = tech_api.utils.misc.dehash_vector(pos_hash)
        break
      end
    end

    -- if we didn't find any, everything is visited and we're done
    if not unvisited_pos then
      break
    end

    -- otherwise, start a recursive discovery from this node
    tech_api.energy.discover_network(unvisited_pos, -1)
  end

  -- NOTE only for debug, will be removed
  tech_api.energy.log_networks()
end

--- Reset the traversal algorithm flags in the nodestore.
-- This function sets the 'visited' field back to false for every transporter
-- node in the nodestore. Only nodes that have a transporter definition are
-- affected, device-only nodes are skipped. It also resets the network id field
-- to -1 (no network) - again only for transporter nodes.
-- Last but not least, it adds a field 'is_transporter' that
-- indicates whether or not the node has at least a transporter definition for
-- its node name. This allows for faster execution of the network discovery
-- recursive function, because it doesn't need anymore to check the definitions
-- table (which is slower) to figure out this aspect.
-- @function reset_discovery_flags
function tech_api.energy.reset_discovery_flags()
  for pos_hash, content in pairs(tech_api.utils.nodestore.data) do
    if tech_api.energy.has_definition_for_group(tech_api.utils.nodestore.data[pos_hash].node_name, 'transporter') then
      tech_api.utils.nodestore.data[pos_hash].visited = false
      tech_api.utils.nodestore.data[pos_hash].is_transporter = true
      tech_api.utils.nodestore.data[pos_hash].network_id = -1
    else
      tech_api.utils.nodestore.data[pos_hash].is_transporter = false
    end
  end
end

-- debug (temporary function, will be removed)
function tech_api.energy.log_networks()
  tech_api.utils.log.print('info', "------------------------------------------")
  for id = 1, #tech_api.energy.networks do
    local devices_count = 0
    for pos, device in pairs(tech_api.energy.networks[id].devices) do
      devices_count = devices_count + 1
    end
    tech_api.utils.log.print('info', "Network #" .. id .. " has " .. devices_count .. " devices")
  end
end
