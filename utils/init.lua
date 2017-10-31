--- Entry point for the utils module.
--
-- This script will load all the files and submodules that together make up the
-- utils module
--
-- @module tech_api.utils

-- Module table
tech_api.utils = {}

-- load the subfiles/submodules
dofile(tech_api.modpath .. "/utils/misc.lua")
dofile(tech_api.modpath .. "/utils/log.lua")
dofile(tech_api.modpath .. "/utils/nodestore.lua")
