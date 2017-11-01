---
-- @module tech_api.energy

--- Public API functions.
-- These functions are the ones that other mods will use to interact with
-- the energy system.
-- @section public_api

--- Register a device definition.
-- This function registers a device definition for a specific node name.
-- @function register_device
-- @tparam string node_name The name of the node the definition belongs to,
-- in the usual Minetest style "modname:nodename". This MUST be the same name
-- the node registered with on the Minetest API (using minetest.register_node).
-- @tparam string def_name The name of the definition, since a node may have
-- multiple ones
-- @tparam table config The parameters for the definition being registered
-- @usage
--  -- in yourmachine.lua
--
--  tech_api.energy.register_device("yourmod:yourmachine", "default", {
--    class = {'default'},
--    type = 'user',
--    max_rate = 20,
--    linkable_faces = {'rear', 'top', 'left', 'right', 'bottom'},
--    callback = function(...)
--      -- main callback from the API which allows a device to exchange the
--      -- power it needs/generates/stores
--      return ...
--    end
--  })
function tech_api.energy.register_device(node_name, def_name, config)
  -- fall back to default class if not specified
  if not config.class then
    config.class = {'default'}
  end
  if #config.class == 0 then
    table.insert(config.class, 'default')
  end

  -- preprocess classes (i.e. translate to class ids)
  config.class = tech_api.energy.translate_class_aliases(config.class)

  -- register the definition
  tech_api.energy.add_definition(node_name, def_name, 'device', config)
end

--- Register a transporter definition.
-- This function registers a transporter definition for a specific node name.
-- In this case you won't have to provide a name for the definition, since
-- a node can have just one transporter definition. The definition will be
-- internally named "transporter_default", so if you also declare device
-- definitions for this node you must not use that same name (you'll probably
-- never call a device definition "transporter_default", but it's just to warn
-- you).
-- @function register_transporter
-- @tparam string node_name The name of the node the definition belongs to,
-- in the usual Minetest style "modname:nodename". This MUST be the same name
-- the node registered with on the Minetest API (using minetest.register_node).
-- @tparam table config The parameters for the definition being registered
-- @usage
--  -- in yourcable.lua
--
--  tech_api.energy.register_transporter("yourmod:yourcable", {
--    class = 'default'
--  })
function tech_api.energy.register_transporter(node_name, config)
  -- fall back to default class if not specified
  if not config.class then
    config.class = 'default'
  end

  -- preprocess class (i.e. translate to class id)
  config.class = tech_api.energy.classes[config.class]

  -- register the definition
  tech_api.energy.add_definition(node_name, 'transporter_default', 'transporter', config)
end

--- Notify that a registered node has been placed.
-- This function must be called whenever a node you registered definitions of,
-- is placed in the world (on_construct Minetest callback). The position of the
-- node is the only parameter required. The API will call minetest.get_node with
-- the position provided to figure out the node name (allowing the system to
-- fetch the node definitions you registered) and the direction of the node.
-- This function goes along with @{tech_api.energy.on_destruct}.
-- @function on_construct(pos)
-- @tparam table pos The position of the node
-- @usage
--  -- in yourmachine.lua
--
--  minetest.register_node("yourmod:yourmachine", {
--    -- Minetest node definition here
--
--    on_construct = function(pos)
--      tech_api.energy.on_construct(pos)
--    end,
--    on_destruct = function(pos)
--      tech_api.energy.on_destruct(pos)
--    end
--  })
function tech_api.energy.on_construct(pos)
  -- get the node table
  local node = minetest.get_node(pos)

  -- prepare the nodestore data table to assign
  local nodedata = {
    node_name = node.name,
    facedir = node.param2
  }

  -- figure out if this node has at least one transporter definition and/or one
  -- device definition
  local is_transporter = tech_api.energy.has_definition_for_group(node.name, 'transporter')
  local is_device = tech_api.energy.has_definition_for_group(node.name, 'device')

  -- pre-calculate the valid direction vectors for each definition to speed
  -- up any further network discovery (only if this has at least one device
  -- definition)
  if is_device then
    nodedata.definitions = {}
    for def_name, definition in pairs(tech_api.energy.definitions[node.name]) do
      if definition.group == 'device' then -- only if a device definition
        nodedata.definitions[def_name] = {}
        nodedata.definitions[def_name].linkable_faces = {}
        for lf = 1, #definition.linkable_faces do
          table.insert(
            nodedata.definitions[def_name].linkable_faces,
            tech_api.utils.misc.facename_to_vector(node.param2, definition.linkable_faces[lf])
          )
        end

        -- if this device is a storage, let's prepare the 'content' field
        if definition.type == 'storage' then
          nodedata.definitions[def_name].content = 0
        end

        -- also prepare the network_id field for each definition
        nodedata.definitions[def_name].network_id = -1
      end
    end
  end

  -- if this node has a transporter definition, also keep the transporter class
  -- in the nodestore so the network discovery can be performed faster without
  -- accessing multiple tables
  if is_transporter then
    nodedata.class = tech_api.energy.get_transporter_definition(node.name).class
  end

  -- also add to the nodedata the flags is_transporter and is_device
  nodedata.is_transporter = is_transporter
  nodedata.is_device = is_device

  -- assign the data we generated to the node (referenced by position) in the
  -- nodestore. 'nodestore' is now a reference of the content in the nodestore,
  -- so we can safely modify it without rewriting in the global table
  tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)] = nodedata

  -- if this node is a transporter, search for connected networks and behave
  -- according to the number of them
  if is_transporter then
    local connected_networks = tech_api.energy.search_connected_networks(pos, false)
    if #connected_networks == 0 then
      -- we need to create a new network with this node as the entry point
      local network_id = tech_api.energy.create_network(pos)
      -- and then flag this node belongs to this new network
      nodedata.network_id = network_id
    elseif #connected_networks == 1 then
      -- we can simply flag this node as belonging to the only connected network
      nodedata.network_id = connected_networks[1]
    elseif #connected_networks >= 2 then
      -- we have multiple networks, we need to launch a network traversal to
      -- join them together
      -- let's pass the network ids we found to the function, so it traverses
      -- just the two networks (instead of all of them)
      nodedata.network_id = -1 -- but first reset the network_id in the nodestore
      tech_api.energy.rediscover_networks(connected_networks)
    end

    -- if we manually configured the transporter node (not using rediscover_networks)
    -- then call discover_network to connect the devices around the node (if any).
    -- this is actually a bit of a trick, because discover_network was not meant
    -- to do this, but it turns out it will work just fine
    if #connected_networks <= 1 then
      tech_api.energy.discover_network({}, pos, nodedata.network_id)
    end
  end

  -- if this node is (also) a device, then try to connect it
  if is_device then
    tech_api.energy.connect_device(pos, nil)
  end

  -- after we successfully updated the network graph and the nodestore, dump the
  -- nodestore to disk immediately to prevent it getting out of sync
  tech_api.utils.nodestore.save()

  tech_api.energy.log_networks()
end

--- Notify that a registered node has been removed.
-- This function must be called whenever a node you registered definitions of,
-- is removed from the world (on_destruct Minetest callback). The position of
-- the node is the only parameter required. See also @{tech_api.energy.on_construct}
-- for an usage example.
-- @function on_destruct(pos)
-- @tparam table pos The position of the node
function tech_api.energy.on_destruct(pos)
  -- get the nodestore object for the node that was removed
  local nd_def = tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)]

  -- check if we actually got something from the nodestore
  if not nd_def then
    -- if we didn't, we're may be in trouble:
    -- the nodestore is probably getting out of sync
    tech_api.utils.log.print('info', "A node was removed from the world but was not in the nodestore.")
    tech_api.utils.nodestore.on_discrepancy_detected()

    -- there's nothing left to do here, since we can't remove something that
    -- doesn't exist
    return
  end

  -- fetch some data about the node that was removed
  local is_transporter = tech_api.energy.has_definition_for_group(nd_def.node_name, 'transporter')
  local is_device = tech_api.energy.has_definition_for_group(nd_def.node_name, 'device')

  -- if this node has device definitions, then remove the devices from the
  -- network graph
  if is_device then
    -- get the hashed position (used as index in the network graph)
    local hashed_pos = tech_api.utils.misc.hash_vector(pos)
    -- iterate through all the definitions
    for _, definition in pairs(nd_def.definitions) do
      -- get the network id this definition is connected to
      local network_id = definition.network_id
      -- if this definition is connected to a network
      if network_id ~= -1 then
        -- remove the device from that network
        tech_api.energy.networks[network_id].devices[hashed_pos] = nil
      end
    end
  end

  -- if this node is (also) a transporter
  if is_transporter then
    -- keep track of the affected network id
    local network_id = nd_def.network_id
    -- and the devices we need to unlink
    local to_unlink = {}
    -- get the number of connected transporters
    local connected_n = #tech_api.energy.search_connected_networks(pos, true)

    -- then behave differently based on the number of connected transporters
    if connected_n == 0 then
      -- if no other connected transporters are found (thus this is the only
      -- transporter node left in the network) then unlink all the devices in
      -- the network and then delete the network completely
      to_unlink = tech_api.energy.networks[network_id].devices
      tech_api.energy.networks[network_id] = nil
    elseif connected_n == 1 then
      -- if just one transporter node is found, then remove all the connected
      -- devices definitions from the network
      to_unlink = tech_api.energy.search_connected_devices_definitions(pos, network_id)
    elseif connected_n >= 2 then
      -- if we are connected to more than one transporter node, we'll need to do
      -- a complete network traversal since this means that the network is
      -- probably going to be splitted in two parts, but first we need to remove
      -- the node from the nodestore so the traversal algorithm knows we're no
      -- more here
      tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)] = nil

      -- then launch the traversal only on the affected network id
      tech_api.energy.rediscover_networks({network_id})
    end

    -- finally process our 'to_unlink' list and remove all the devices definitions
    -- from the network with the saved id, and also flag the definitions in the
    -- nodestore with the network_id "-1" (not connected)
    for _, device in pairs(to_unlink) do
      -- get the hashed position
      local hashed_pos = tech_api.utils.misc.hash_vector(device.pos)
      -- get the nodestore object for the device we're trying to unlink
      local nd = tech_api.utils.nodestore.data[hashed_pos]
      -- if this device is also a transporter, we are not going to remove it,
      -- since it can't be disconnected from "itself"
      -- if it's not a transporter, then we do our job
      if nd.is_transporter == false then
        -- if the network id still exists, remove the device from the network tree
        if tech_api.energy.networks[network_id] then
          tech_api.energy.networks[network_id].devices[hashed_pos] = nil
        end
        -- update the nodestore and flag the devices with the network_id "-1"
        nd.definitions[device.def_name].network_id = -1
      end
    end
  end

  -- ensure this node is no more in the nodestore (just one of the conditions
  -- above will remove it, so let's fix that here)
  tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)] = nil

  -- after we successfully updated the network graph and the nodestore, dump the
  -- nodestore to disk immediately to prevent it getting out of sync
  tech_api.utils.nodestore.save()

  tech_api.energy.log_networks()
end

--- Manually ask for a callback for a device.
-- This function can be called by a device to request its callback to be fired
-- again, no matter what the internal countdown says. This is useful to avoid
-- any callback while a machine is idle: this function allows the machine to
-- resume and start interacting with the API again once it leaves the idle
-- state. The device definition name must be given as a parameter, since a node
-- can be multiple devices at the same time and you may want to request a manual
-- callback only for one device type.
-- @function request_callback
-- @tparam table pos The position of the node
-- @tparam string def_name The name of the device definition
function tech_api.energy.request_callback(pos, def_name)
  -- TODO do checks (or maybe not?)

  local hashed_pos = tech_api.utils.misc.hash_vector(pos)

  -- obtain the device definition network id
  local network_id = tech_api.utils.nodestore.data[hashed_pos].definitions[def_name].network_id

  -- set the callback_countdown parameter in the network tree
  tech_api.energy.networks[network_id].devices[hashed_pos].callback_countdown = 1
end

--- Register a new energy class.
-- This function adds a new class alias that can be used when registering
-- devices or transporter definitions. Please note that, unless you're working
-- with the Technic mod, you shouldn't use this function at all (nor specify)
-- classes for your definitions.
-- @function register_class
-- @tparam string alias The class alias
-- @tparam number id The class id. If you're registering a new class you must
-- ensure to use an id that is different from the ids other mods are using. If
-- you choose a numeric id that is equal to another mod registered id, you'll
-- end up with devices and transporters connecting together while they shouldn't.
function tech_api.energy.register_class(alias, id)
  tech_api.energy.add_class(alias, id)
end
