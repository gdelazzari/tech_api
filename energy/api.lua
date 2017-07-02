---
-- @module tech_api.energy

--- Public API functions.
-- These functions are the ones that other mods will use to interact with
-- the energy system.
-- @section public_api

--- Register a transporter definition.
-- This function registers a transporter definition for a specific node name
-- @function register_transporter
-- @tparam string node_name The name of the node the definition belongs to,
-- in the usual Minetest style "modname:nodename"
-- @tparam string def_name The name of the definition, since a node may have
-- multiple ones
-- @tparam table config The parameters for the definition being registered
-- @usage
--  -- in yourcable.lua
--
--  tech_api.energy.register_transporter("yourmod:yourcable", "default", {
--    class = 'default',
--    callback = function(...)
--      -- the callback that fires whenever the transporter changes its connected
--      -- sides, useful to update the node visuals
--    end
--  })
function tech_api.energy.register_transporter(node_name, def_name, config)
  -- fall back to default class if not specified
  if not config.class then
    config.class = 'default'
  end

  -- register the definition
  tech_api.energy.add_definition(node_name, def_name, 'transporter', config)
end

--- Register a device definition.
-- This function registers a device definition for a specific node name.
-- @function register_device
-- @tparam string node_name The name of the node the definition belongs to,
-- in the usual Minetest style "modname:nodename"
-- @tparam string def_name The name of the definition, since a node may have
-- multiple ones
-- @tparam table config The parameters for the definition being registered
-- @usage
--  -- in yourmachine.lua
--
--  tech_api.energy.register_device("yourmod:yourmachine", "default", {
--    class = 'default',
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
    config.class = 'default'
  end

  -- register the definition
  tech_api.energy.add_definition(node_name, def_name, 'device', config)
end

--- Notify that a registered node has been placed.
-- This function must be called whenever a node you registered definitions of,
-- is placed in the world (on_construct Minetest callback). The name of the node
-- (so the system can look up its definitions) and its position are enough as
-- parameters to pass to the function. This function goes along with
-- @{tech_api.energy.on_destruct}.
-- @function on_construct(node_name, pos)
-- @tparam string node_name The name of the node (it must be the same you used
-- to register its definitions, ideally it's the same name you registered the
-- node with to Minetest)
-- @tparam table pos The position of the node
-- @usage
--  -- in yourmachine.lua
--
--  minetest.register_node("yourmod:yourmachine", {
--    -- Minetest node definition here
--
--    on_construct = function(pos)
--      tech_api.energy.on_construct("yourmod:yourmachine", pos)
--    end,
--    on_destruct = function(pos)
--      tech_api.energy.on_destruct(pos)
--    end
--  })
function tech_api.energy.on_construct(node_name, pos)
  -- update the nodestore
  tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)] = {
    node_name = node_name
  }

  -- rebuild the networks graphs
  tech_api.energy.rediscover_networks()
end

--- Notify that a registered node has been removed.
-- This function must be called whenever a node you registered definitions of,
-- is removed from the world (on_destruct Minetest callback). The position of
-- the node is the only parameter required. See @{tech_api.energy.on_construct}
-- for an usage example.
-- @function on_destruct(pos)
-- @tparam table pos The position of the node
function tech_api.energy.on_destruct(pos)
  -- update the nodestore
  tech_api.utils.nodestore.data[tech_api.utils.misc.hash_vector(pos)] = nil

  -- rebuild the networks graphs
  tech_api.energy.rediscover_networks()
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

end
