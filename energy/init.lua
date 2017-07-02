--- Energy system API module
--
-- This module provides a common cross-compatible energy system among mods that
-- use its functions.
--
-- @module tech_api.energy

-- Declare the subsystem module table
tech_api.energy = {}

-- Load the subfiles/submodules
dofile(tech_api.modpath .. "/energy/definitions.lua")
dofile(tech_api.modpath .. "/energy/networks.lua")
dofile(tech_api.modpath .. "/energy/distribution.lua")
dofile(tech_api.modpath .. "/energy/api.lua")
