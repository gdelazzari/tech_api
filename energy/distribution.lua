---
-- @module tech_api.energy

--- Power distribution functions.
-- These functions are used internally to manage the power distribution inside
-- a network of devices
-- @section distribution

--- Energy distribution cycle.
-- This function is called internally every "time unit" of the energy system
-- and is in charge of moving the energy around inside a network, as the devices
-- require.
-- @function distribution_cycle
-- @tparam float delta_time Time since the last call - obtained from the
-- globalstep callback
function tech_api.energy.distribution_cycle(delta_time)

end
