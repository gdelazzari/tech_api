---
-- @module tech_api.energy

--- Power distribution functions.
-- These functions are used internally to manage the power distribution inside
-- a network of devices
-- @section distribution

tech_api.energy.timer = 0.0
tech_api.energy.time_unit = 0.25

--- Energy distribution cycle.
-- This function is called internally every "time unit" of the energy system
-- and is in charge of moving the energy around inside a network, as the devices
-- require.
-- @function distribution_cycle
-- @tparam float delta_time Time since the last call - obtained from the
-- globalstep callback
function tech_api.energy.distribution_cycle(delta_time)
  -- keep track of time
  tech_api.energy.timer = tech_api.energy.timer + delta_time

  -- if a time unit has passed since the last cycle, then do another one
  if tech_api.energy.timer >= tech_api.energy.time_unit then
    -- and decrement our timer in order to keep track for the next cycle
    tech_api.energy.timer = tech_api.energy.timer - tech_api.energy.time_unit

    -- for each network
    for id, network in ipairs(tech_api.energy.networks) do
      -- prepare a table to keep the current rates for the storage devices (this
      -- is being done just to provide the storage devices a value that
      -- represents their current I/O rate - usually for display purposes).
      -- Also exploit this loop to increment the dtime value for each device.
      local storage_rates = {}
      for hashed_pos, device in pairs(network.devices) do
        device.dtime = device.dtime + delta_time
        if device.type == 'storage' then
          if not storage_rates[hashed_pos] then
            storage_rates[hashed_pos] = {}
          end
          storage_rates[hashed_pos][device.def_name] = 0
        end
      end

      -- pre-calculate energy request, also managing user callbacks
      local request = 0
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'user' then
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 then
            -- tell the user that its max rate is available, even if it may not
            -- be true (callback(pos, dtime, -> device.max_rate <-))
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local new_rate, next_callback = device.callback(pos, device.dtime, device.max_rate)
            device.dtime = 0.0
            device.current_rate = new_rate
            device.callback_countdown = next_callback
          end
          request = request + device.current_rate
        elseif device.type == 'storage' then
          -- get the device nodestore data (since the content of the storage is here)
          local nd_dev = tech_api.utils.nodestore.data[hashed_pos]
          -- get the device connected definition table
          local nd_def = nd_dev.definitions[device.def_name]
          -- update request with the max rate the storage can receive (to
          -- possibly allow it to "charge" at full speed if enough power is
          -- available)
          request = request + math.min(device.max_rate, (device.capacity - nd_def.content))
        end
      end

      -- manage provider callbacks and compute available energy
      local available = 0
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'provider' then
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 then
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local new_rate, next_callback = device.callback(pos, device.dtime, request)
            device.dtime = 0.0
            device.current_rate = new_rate
            device.callback_countdown = next_callback
          end
          request = request - device.current_rate
          available = available + device.current_rate
        end
      end

      -- if we don't have enough energy available, try to fecth some from the
      -- storage devices in the network
      if request > available then
        for hashed_pos, device in pairs(network.devices) do
          if device.type == 'storage' then
            -- get the device nodestore data (since the content of the storage is here)
            local nd_dev = tech_api.utils.nodestore.data[hashed_pos]
            -- get the device connected definition table
            local nd_def = nd_dev.definitions[device.def_name]
            -- update storage content
            local ask_from_storage = math.min(math.min((request - available), device.max_rate), nd_def.content)
            nd_def.content = nd_def.content - ask_from_storage
            available = available + ask_from_storage
            -- also keep track that we asked the storage that amount in the
            -- storage_rates table we prepared before
            storage_rates[hashed_pos][device.def_name] = storage_rates[hashed_pos][device.def_name] - ask_from_storage
          end
        end
      end

      -- manage users
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'user' then
          -- check if we have enough power for the device
          if available < device.current_rate then
            -- if not, fire another callback with the available power to let the
            -- device adjust its rate
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local new_rate, next_callback = device.callback(pos, device.dtime, math.min(available, device.max_rate))
            device.dtime = 0.0
            device.current_rate = new_rate
            device.callback_countdown = next_callback
          end
          -- then decrement the energy available
          available = available - device.current_rate
        end
      end

      -- now 'available' contains the power left that we can put into storages
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'storage' then
          -- get the device nodestore data (since the content of the storage is here)
          local nd_dev = tech_api.utils.nodestore.data[hashed_pos]
          -- get the device connected definition table
          local nd_def = nd_dev.definitions[device.def_name]
          -- update storage content
          local put_in_storage = math.min(math.min(available, device.max_rate), (device.capacity - nd_def.content))
          nd_def.content = nd_def.content + put_in_storage
          available = available - put_in_storage
          -- also keep track that we put in the storage that amount in the
          -- storage_rates table we prepared before
          storage_rates[hashed_pos][device.def_name] = storage_rates[hashed_pos][device.def_name] + put_in_storage

          -- handle callbacks (for storages is only used to report content and
          -- capacity)
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 then
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local next_callback = device.callback(pos, device.dtime, nd_def.content, device.capacity, storage_rates[hashed_pos][device.def_name])
            device.dtime = 0.0
            device.callback_countdown = next_callback
          end
        end
      end

      -- final checks
      if available < 0 then
        -- this should NEVER happen
        tech_api.utils.log.print('warning', "network #" .. id .. " gained " + (-available) .. " for free")
      end
    end
  end
end
