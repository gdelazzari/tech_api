---
-- @module tech_api.energy

--- Class management.
-- These elements are used internally to manage the classes the devices and
-- transporters belong to. Actually, only the class aliases are stored (that
-- translate a string to a class id).
-- @section definitions

--- Class aliases table.
-- This table will store the class aliases. The key for the table is the class
-- alias (as a string) and the value of each pair is the class id the alias
-- translates to.
-- @table classes
tech_api.energy.classes = {}

--- Add a class alias
-- @function add_class_alias
-- @tparam string alias Class alias
-- @tparam number id Class id
function tech_api.energy.add_class(alias, id)
  tech_api.energy.classes[alias] = id
end

--- Translate a list of class aliases.
-- This function takes a list of class aliases (as strings) and returns a list
-- with the real class ids.
-- @function translate_class_aliases
-- @tparam table list The list containing the class aliases
-- @treturn table The list with the real class ids
function tech_api.energy.translate_class_aliases(list)
  local result = {}
  -- NOTE maybe remove duplicates?
  for i = 1, #list do
    table.insert(result, tech_api.energy.classes[list[i]])
  end
  return result
end

--- Check if a class list has a specific id.
-- This function returns true if the specified class ids list contains the
-- provided id. Useful during network discovery to check if a transporter can
-- connect to a device (or vice-versa).
-- @function class_list_has
-- @tparam table list The list of class ids
-- @tparam number id The id to look for
-- @treturn boolean Whether the id is in the list or not
function tech_api.energy.class_list_has(list, id)
  for i = 1, #list do
    if list[i] == id then
      return true
    end
  end
  return false
end

-- Add the default class
tech_api.energy.add_class('default', 1)
