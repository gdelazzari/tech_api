-- Declare the module table
tech_api = {}

-- Store the mod path in the mod table so it's accessible anywhere
tech_api.modpath = minetest.get_modpath("tech_api")

-- Call the various subsystems initialization files
dofile(tech_api.modpath .. "/" .. energy .. "/init.lua")
