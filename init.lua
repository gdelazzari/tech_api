--- Entry point for tech_api.
--
-- Minetest will load this file first, which will then load all the submodules
-- and their files. This script will also define some constants in the tech_api
-- module table, such as @{modpath}
--
-- @module tech_api

tech_api = {}

--- This field stores the mod path inside the tech_api module
tech_api.modpath = minetest.get_modpath("tech_api")

--- This field is the tech_api ModStorage object
tech_api.modstorage = minetest.get_mod_storage()

-- Call the various submodules initialization files
dofile(tech_api.modpath .. "/utils/init.lua")
dofile(tech_api.modpath .. "/energy/init.lua")
