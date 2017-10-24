---
-- @module tech_api.energy

--- Power distribution functions.
-- These functions are used internally to manage the power distribution inside
-- a network of devices
-- @section distribution

tech_api.energy.timer = 0.0
tech_api.energy.time_unit = 0.20

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
    for id, network in pairs(tech_api.energy.networks) do
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

      -- prepare a table to hold some network information that will be passed
      -- to any monitor device requiring this
      local network_info = {}

      -- pre-calculate energy request
      local request = 0
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'user' then
          request = request + device.current_request
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

      -- save the network request in the network_info table
      network_info.request = request

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

      -- save the provider generated power in the network_info table
      network_info.provider_available = available

      -- if we don't have enough energy available, try to fetch some from the
      -- storage devices in the network (i.e. if there's still some request left)
      if request > 0 then
        for hashed_pos, device in pairs(network.devices) do
          if device.type == 'storage' then
            -- get the device nodestore data (since the content of the storage is here)
            local nd_dev = tech_api.utils.nodestore.data[hashed_pos]
            -- get the device connected definition table
            local nd_def = nd_dev.definitions[device.def_name]
            -- update storage content
            local ask_from_storage = math.min(request, device.max_rate, nd_def.content)
            nd_def.content = nd_def.content - ask_from_storage
            available = available + ask_from_storage
            request = request - ask_from_storage
            -- also keep track that we asked the storage that amount in the
            -- storage_rates table we prepared before
            storage_rates[hashed_pos][device.def_name] = storage_rates[hashed_pos][device.def_name] - ask_from_storage
          end
        end
      end

      -- save the total available power in the network_info table
      network_info.total_available = available

      -- start computing the storage rates in the network_info table
      network_info.storages_rate = -(available - network_info.provider_available)

      -- manage users
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'user' then
          -- manage the callback for the user
          local can_consume = math.min(device.current_request, device.max_rate, available)
          -- fire the callback either if the countdown is 0 or if we can't supply
          -- what the device is trying to consume, to notify it of the fact
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 or can_consume < device.current_rate then
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local new_request, new_rate, next_callback = device.callback(pos, device.dtime, can_consume)
            device.dtime = 0.0
            device.current_request = new_request
            device.current_rate = new_rate
            device.callback_countdown = next_callback
          end

          -- then decrement the energy available
          available = available - device.current_rate
        end
      end

      -- store the power usage in the network_info table
      network_info.usage = network_info.total_available - available

      -- prepare a variable to keep track of how much energy we have put into
      -- storages
      local previous_available = available

      -- now 'available' contains the power left that we can put into storages

      -- before cycling through the storages to put power in them, let's prepare
      -- a couple of variables to keep track of the total network capacity and
      -- stored energy (for monitor devices)
      local total_capacity = 0
      local total_content = 0

      -- now cycle through the storages
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'storage' then
          -- get the device nodestore data (since the content of the storage is here)
          local nd_dev = tech_api.utils.nodestore.data[hashed_pos]
          -- get the device connected definition table
          local nd_def = nd_dev.definitions[device.def_name]
          -- update storage content
          local put_in_storage = math.min(available, device.max_rate, (device.capacity - nd_def.content))
          nd_def.content = nd_def.content + put_in_storage
          available = available - put_in_storage
          -- also keep track that we put in the storage that amount in the
          -- storage_rates table we prepared before
          storage_rates[hashed_pos][device.def_name] = storage_rates[hashed_pos][device.def_name] + put_in_storage
          -- and keep track of the total capacity/content
          total_capacity = total_capacity + device.capacity
          total_content = total_content + nd_def.content

          -- handle callbacks (for storages is only used to report content and
          -- capacity)
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 then
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local storage_info = {
              content = nd_def.content,
              capacity = device.capacity,
              current_rate = storage_rates[hashed_pos][device.def_name]
            }
            local content_change, next_callback = device.callback(pos, device.dtime, storage_info)
            device.dtime = 0.0
            device.callback_countdown = next_callback
            -- change the content as the device asked (useful for batteries that
            -- can charge/discharge items)
            nd_def.content = nd_def.content + content_change
          end
        end
      end

      -- update the storage rates in the network_info table
      network_info.storages_rate = network_info.storages_rate + (previous_available - available)
      -- and also the total capacity/content
      network_info.total_capacity = total_capacity
      network_info.total_content = total_content

      -- now handle all the power monitor devices passing them the network_info table
      for hashed_pos, device in pairs(network.devices) do
        if device.type == 'monitor' then
          device.callback_countdown = device.callback_countdown - 1
          if device.callback_countdown == 0 then
            local pos = tech_api.utils.misc.dehash_vector(hashed_pos)
            local next_callback = device.callback(pos, device.dtime, network_info)
            device.dtime = 0.0
            device.callback_countdown = next_callback
          end
        end
      end

      -- final checks
      if available < 0 then
        -- this should NEVER happen
        tech_api.utils.log.print('warning', "network #" .. id .. " gained " .. (-available) .. " for free")
      end
    end
  end
end
