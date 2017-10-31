--- Energy system API module
--
-- This module provides a common cross-compatible energy system among mods that
-- use its functions.
--
-- @module tech_api.energy

-- Declare the subsystem module table
tech_api.energy = {}

-- Load the subfiles/submodules
dofile(tech_api.modpath .. "/energy/classes.lua")
dofile(tech_api.modpath .. "/energy/definitions.lua")
dofile(tech_api.modpath .. "/energy/networks.lua")
dofile(tech_api.modpath .. "/energy/distribution.lua")
dofile(tech_api.modpath .. "/energy/api.lua")

-- Register on_shutdown event to save the nodestore
minetest.register_on_shutdown(function()
    tech_api.utils.nodestore.save()
end)

-- Load the nodestore on server start
tech_api.utils.nodestore.load()

-- for k, v in pairs(tech_api.utils.nodestore.data) do
--   minetest.chat_send_all(v)
-- end

-- Register globalstep handler for the distribution algorithm and to rebuild
-- networks on server start
local network_rebuilt_at_start = false
minetest.register_globalstep(function(delta_time)
  if network_rebuilt_at_start == false then
    -- rebuild the networks
    tech_api.energy.rediscover_networks()
    network_rebuilt_at_start = true
  end

  tech_api.energy.distribution_cycle(delta_time)
end)
