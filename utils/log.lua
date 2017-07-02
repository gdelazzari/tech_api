--- Provides methods to log what's going on in the code.
--
-- This module is an abstraction layer over the minetest.log function, that
-- allows to print the log strings in other places along the default server log.
-- This is useful for debugging because it allows, for example, to print the log
-- in the server chat while testing on a single player world.
--
-- @module tech_api.utils.log

-- Module table
tech_api.utils.log = {}

-- Local configuration parameters
local print_to_chat = true

--- Function to print a log string on the configured streams
-- @function print
-- @tparam string level The logging level (deprecated, error, action, info, verbose)
-- @tparam string text The text to log
function tech_api.utils.log.print(level, text)
  minetest.log(level, "[tech_api] " .. text)
  if print_to_chat == true then
    minetest.chat_send_all("[tech_api] [" .. level .. "] " .. text)
  end
end
