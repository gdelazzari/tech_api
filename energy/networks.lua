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
-- @tparam number id The network id
-- @tparam table device The table that represents the device
function tech_api.energy.add_device_to_network(id, device)
  -- no checks on the validity of the id, so if something goes wrong it throws
  -- an error and we'll know that
  tech_api.energy.networks[id].devices[tech_api.utils.misc.hash_vector(device.pos)] = device
end

--- Connect a device to nearby networks.
-- This function will try to connect a device to the networks the attached
-- transporters belong to. If you already know where the transporter you want
-- to connect to is, you may pass its position as the second parameter. This is
-- useful during a network discovery (@{tech_api.energy.discover_network}) to
-- increase performance. The function doesn't return anything, but will update
-- the networks graph and the nodestore fields with the network ids each
-- definition is connected to.
-- @function connect_device
-- @tparam table pos The position of the device to connect
-- @tparam table transporter_pos The position of the transporter you want the
-- device to connect to. It may be nil (or unspecified). In that case the
-- function will search around the device and connect all the definitions that
-- apply to the wire position (linkable_faces config field, see
-- @{tech_api.energy.register_device}).
function tech_api.energy.connect_device(pos, transporter_pos)
  -- here we will put the positions we'll try to search for a transporter
  local search_positions
  if transporter_pos then
    -- if a transporter position was given then search just there
    search_positions = { [1] = transporter_pos }
  else
    -- otherwise get the list of connected positions
    search_positions = tech_api.utils.misc.get_connected_positions(pos)
  end

  -- bring local our nodestore data
  local pos_hash = tech_api.utils.misc.hash_vector(pos)
  local pos_nodestore = tech_api.utils.nodestore.data[pos_hash]

  -- for each position in the list
  for p = 1, #search_positions do
    -- the position we're currently looking at
    local search_pos = search_positions[p]
    local search_pos_hash = tech_api.utils.misc.hash_vector(search_pos)

    -- if there's something there
    local search_pos_nodestore = tech_api.utils.nodestore.data[search_pos_hash]
    if search_pos_nodestore then
      -- and the node is a transporter (with a valid network id)
      if search_pos_nodestore.is_transporter == true and search_pos_nodestore.network_id ~= -1 then
        -- save the network id we *may* connect to
        local network_id = search_pos_nodestore.network_id

        -- iterate through each definition for the device
        for def_name, definition in pairs(pos_nodestore.definitions) do
          -- checking for a non-connected one
          if definition.network_id == -1 then
            -- also bring the full definition local
            local full_definition = tech_api.energy.definitions[pos_nodestore.node_name][def_name]

            -- and if the definition is compatible (i.e. the face can connect
            -- and the class(es) is(/are) compatible)
            local can_connect = false
            for lf = 1, #definition.linkable_faces do
              if tech_api.utils.misc.positions_equal(
                search_pos,
                vector.add(pos, definition.linkable_faces[lf])
              ) == true then
                can_connect = true
                break
              end
            end
            if can_connect == true then
              local transporter_def = tech_api.energy.get_transporter_definition(search_pos_nodestore.node_name)
              if tech_api.energy.class_list_has(full_definition.class, transporter_def.class) == false then
                can_connect = false
              end
            end

            if can_connect == true then
              -- we can add the device
              tech_api.energy.add_device_to_network(network_id, {
                pos = pos,
                node_name = pos_nodestore.node_name,
                def_name = def_name,
                type = full_definition.type,
                max_rate = full_definition.max_rate,
                current_request = 0, -- only for users
                current_rate = 0,
                callback = full_definition.callback,
                -- maybe randomize this a bit to avoid tons of callbacks at the same
                -- time after networks rediscovery?
                callback_countdown = 1,
                dtime = 0.0,
                capacity = full_definition.capacity -- only for storages
              })

              -- also flag this definition connected in the nodestore
              tech_api.utils.nodestore.data[pos_hash].definitions[def_name].network_id = network_id

              -- then stop searching for valid definitions since this face has
              -- been connected
              break -- (breaks the for that iterates through definitions, so
                    --  moving on to the next position to search)
            end
          end
        end
      end
    end
  end
end

--- Function to discover a network node by node.
-- The function is called when rebuilding the networks graph from scratch, and
-- will start from a given position to discover an entire network. It will be
-- called on a starting position, and it will add to the discovery stack the
-- transporter nodes it finds attached and that must be explored. The function
-- will also add the devices it finds to the network id it's traversing through.
-- @function discover_network
-- @tparam table pos The starting position
-- @tparam number current_network_id The current network_id (used for recursion).
-- If you're calling this function to rebuild the network graph, you'll probably
-- have this value equal to -1 for the first call, since you're starting the
-- discovery from a transporter that doesn't belong to any network yet.
function tech_api.energy.discover_network(stack, pos, current_network_id)
  -- set the network id for the current transporter node
  local network_id = current_network_id
  if network_id == -1 then
    -- we need to create a new network, since this is the first node
    network_id = tech_api.energy.create_network(starting_pos)
  end
  local pos_hash = tech_api.utils.misc.hash_vector(pos)
  tech_api.utils.nodestore.data[pos_hash].network_id = network_id

  -- declare a local variable with our class id for faster access
  local own_class = tech_api.utils.nodestore.data[pos_hash].class

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
      -- behave differently if the node is a transporter or a device
      if search_pos_nodestore.is_transporter == true then
        -- this is a (also) transporter, add to the stack if still not visited
        -- and of the same class
        if search_pos_nodestore.network_id == -1 then
          if search_pos_nodestore.class == own_class then
            table.insert(stack, {pos = search_pos, network_id = network_id})
          end
        end
      end
      if search_pos_nodestore.is_device == true then
        -- this is (also) a device, connect it to the network if possible (this
        -- will do all the necessary checks)
        tech_api.energy.connect_device(search_pos, pos)
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
      if tech_api.utils.nodestore.data[pos_hash].is_transporter == true then
        if tech_api.utils.nodestore.data[pos_hash].network_id == -1 then
          unvisited_pos = tech_api.utils.misc.dehash_vector(pos_hash)
          break
        end
      end
    end

    -- if we didn't find any, everything is visited and we're done
    if not unvisited_pos then
      break
    end

    -- otherwise, start a discovery from this node (which will result in a new
    -- separate network)

    -- discovery stack
    local discovery_stack = {}
    table.insert(discovery_stack, {pos = unvisited_pos, network_id = -1})

    while #discovery_stack > 0 do
      -- pop an element
      local element = discovery_stack[#discovery_stack]
      table.remove(discovery_stack)

      -- search through this
      tech_api.energy.discover_network(discovery_stack, element.pos, element.network_id)
    end
  end

  -- NOTE only for debug, will be removed
  tech_api.energy.log_networks()
end

--- Reset the traversal algorithm flags in the nodestore.
-- This function sets the network id field back to -1 (no network) for each
-- transporter node.
-- Instead, if a device node is found, it will reset the network id each
-- each definition is connected to.
-- Last but not least, it adds a field 'is_transporter' that
-- indicates whether or not the node has at least a transporter definition for
-- its node name and 'is_device' that indicates if the node as at least one
-- device definition. This allows for faster execution of the network discovery
-- recursive function, because it doesn't need anymore to check the definitions
-- table (which is slower) to figure out this aspect.
-- @function reset_discovery_flags
function tech_api.energy.reset_discovery_flags()
  for pos_hash, content in pairs(tech_api.utils.nodestore.data) do
    if tech_api.energy.has_definition_for_group(tech_api.utils.nodestore.data[pos_hash].node_name, 'transporter') == true then
      tech_api.utils.nodestore.data[pos_hash].is_transporter = true
      tech_api.utils.nodestore.data[pos_hash].network_id = -1
    else
      tech_api.utils.nodestore.data[pos_hash].is_transporter = false
    end

    if tech_api.energy.has_definition_for_group(tech_api.utils.nodestore.data[pos_hash].node_name, 'device') == true then
      tech_api.utils.nodestore.data[pos_hash].is_device = true
      for def_name, _ in pairs(tech_api.utils.nodestore.data[pos_hash].definitions) do
        tech_api.utils.nodestore.data[pos_hash].definitions[def_name].network_id = -1
      end
    else
      tech_api.utils.nodestore.data[pos_hash].is_device = false
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
