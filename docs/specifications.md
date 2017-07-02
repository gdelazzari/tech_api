**tech_api** *energy subsystem* specifications (WIP)
----------------------------------------------------

This document defines everything about the API. It will be used as a reference
for the implementation/coding phase, but will also stay here as an in-depth
documentation of the system working principles.

The document is subdivided into various sections, representing various aspects
of the energy subsystem.

_**(waiting to collect enough ideas, proposals, suggestions and requirements to
fill up this specs sheet)**_

## System architecture and basic concepts
This sections defines some basic concepts and conventions that the API takes for
granted

### Naming conventions
Important things to know:
+ A __network__ is a collection of devices connected together by transporters.
+ A __device__ can be a user, a provider, a storage or a monitor. "Concretely" it
  probably is a Minetest node. But a Minetest node can actually be multiple
  devices at the same time (or even be a transporter). Keep reading to better
  understand this aspect.
+ A __user__ is a device that uses (consumes) power available in a network.
  An example is an electric furnace.
+ A __provider__ is a device that provides (gives) power to a network.
  An example is a solar panel.
+ A __storage__ is a device that stores power and exchanges it with a network
  it is connected to. An example is a battery.
+ A __monitor__ is a device that can get information, stats and data about the
  network (such as the power stored, the current input/output rate, etc...)
+ A __transporter__ is just a generic way of describing a wire/cable.
  A transporter is simply something that can move energy around. Because it's a generic concept and is not tied to a specific node type, we can for instance
  declare a generator node (like a coal generator) as a transporter (besides
  being a provider), so that it can be placed in the middle of a long wire and
  take part of the wire (being also a "wire" itself).

### Modules and file structure
The energy API will stay in its own module name which is `tech_api.energy`.
Other modules may be implemented, such as `tech_api.utils` to group generic
functions not strictly related to the energy subsystem. Each module will have
its own subdirectory so, for sure, the following folders will exists:
+ __energy__
+ __utils__

As for the energy subsystem, the API implementation will be spread across
multiple files inside the "energy" subdirectory:
+ __networks.lua__ will deal with the energy network graph(s), providing methods
  to add, remove, change nodes and to join or split networks. Also, the network
  traverse recursive function will take place here.
+ __api.lua__ will contain the publicly available methods that the other mods
  will use.
+ __distribution.lua__ is dedicated to the energy distribution algorithm, which
  is in charge of moving the power around in a network of devices.

The utils module will contain the following submodules (each inside its own
file inside the "utils" subdirectory):
+ __nodestore__ (*nodestore.lua*) which allows to store information about the
  nodes in a pos-indexed Lua table. It will also provide methods to store and
  retrieve the table on the disk in efficient ways, considering the need of
  frequent dumps to a permanent storage to not lose the data about the network
  structure and the nodes that use the API.
+ __misc__ (*misc.lua*) will contain various methods used frequently in other
  modules, like functions to hash an (x, y, z) position to a string.
+ __log__ (*log.lua*) will provide a layer of abstraction over the minetest log
  function to allow more flexibility and multiple output streams for the log
  (this is useful in the debugging phase because it allows, for instance, to
  print the log strings also on the server chat).

### Classes
Every device or transporter that belongs to a network will have a "power class"
(aka "tier").
This has to be implemented to ensure compatibility with the Technic mod that
differentiates between LV, MV and HV power. However any other mod that will use
the API shouldn't care about this aspect, nor it should be aware of power
classes at all. When registering a device to the API, you shouldn't specify
a class so that the API will fall-back to the default one. A class will
internally be represented with a number (starting with __class 1__) for
performance reasons but can be aliased with a string. The default class will
have the number 1 and the alias "default". The Technic mod, for example, will
add another alias "LV" to the default class, besides registering the two other
classes "MV" and "HV" (aliases of probably classes number 2 and 3, though the
class number doesn't really matter as long as it's consistent). Any other mod
that will adopt the API should simply use the "default" class as already pointed
out.

Two transporters of different classes will not connect together, nor a device of
class **x** will be able to connect to a transporter of class **y**.
There may be special devices that can connect to two different networks with two
different classes (like *Supply converters* in Technic).

## API interface with nodes
A node that wants to register to the energy API as a transporter or a device (or
multiple things), will need to call an appropriate method to accomplish the task.
This must happen every time the server starts to provide the API the node
definitions again. A node definition is identified through the name of the node,
in the usual Minetest fashion ("mod:name"). Note: you can use whatever name you
want, not strictly following the Minetest nodes naming scheme, but it's
recommended to keeps things consistent for the sake of simplicity.
When a node (that has already registered a definition) is placed, it has to call
a specific method of the API to inform the system of its presence. A placed
"energy-capable" node (a node that deals with this API) is uniquely identified
through its position in the world. As expected, when a node is removed it will
also have to inform the system of the event.
The methods are quickly described below but will have a more in-depth
description in the API code documentation (generated thanks to
[LDoc](https://github.com/stevedonovan/LDoc)).

+ `tech_api.energy.register_transporter(name, config)` will allow a transporter
  node (i.e. a wire/cable) to register to the API through its name.
  The first parameter is the name of the node while the former is a Lua table
  with fields specifying parameters. An example usage is:

  ```lua
  -- in yourcable.lua

  tech_api.energy.register_transporter("yourmod:yourcable", {
    class = 'default',
    callback = function(...)
      -- the callback that fires whenever the transporter changes its connected
      -- sides, useful to update the node visuals
    end
  })
  ```

  Please note that the class parameter in the example above is not required at
  all and, unless you're writing a mod that uses multiple classes (which you
  shouldn't), you should just skip specifying it. The API will assume your
  transporter belongs to the 'default' class automatically.

+ `tech_api.energy.register_device(name, config)` allows a device to be
  registered as such to the API through its name as an identifier for the
  definition. The `config` parameter is always a Lua table containing various
  fields. The main ones are shown in the example below.

  ```lua
  -- in yourmachine.lua

  tech_api.energy.register_device("yourmod:yourmachine", {
    class = 'default',
    type = 'user',
    max_rate = 20,
    linkable_faces = {'rear', 'top', 'left', 'right', 'bottom'},
    callback = function(...)
      -- main callback from the API which allows a device to exchange the
      -- power it needs/generates/stores
      return ...
    end
  })
  ```

  As one can tell, the `type` parameter represents the type of the device
  (user/provider/storage/monitor) while the `max_rate` is the maximum amount of
  energy units the device can exchange every time unit.
  This allows to limit, for instance, the maximum input/output rate of a battery.
  Again, the `class` field is optional and *ideally* a mod shouldn't care about
  it, since its value (if not specified) will automatically fallback to 'default'.
  The `linkable_faces` field lets you specify which faces of the device can
  connect to a transporter.

  This also allows to define multiple devices for the same Minetest node, acting
  differently (since they're seen as different devices by the API) based on the
  side they're connected to. For example a node may be both a device that
  connects only at the top, and both another device that connects only on the
  bottom face, at the same time (even to two networks of different classes).
  This allows the implementation of nodes such as the *Supply converters* of the
  Technic mod. If multiple definitions have to be specified, they must use the
  same name, as the API will store all of them under the same node identifier.

+ `tech_api.energy.on_construct(name, pos)` must be called every time a node you
  registered to the API is constructed (placed). You'll also need to call
  `tech_api.energy.on_destruct(pos)` whenever a node is destructed (removed).
  Example usage:

  ```lua
  -- in yourcable.lua

  minetest.register_node("yourmod:yourcable", {
    -- Minetest node definition here

    on_construct = function(pos)
      tech_api.energy.on_construct("yourmod:yourcable", pos)
    end,
    on_destruct = function(pos)
      tech_api.energy.on_destruct(pos)
    end
  })

  -- in yourmachine.lua

  minetest.register_node("yourmod:yourmachine", {
    -- Minetest node definition here

    on_construct = function(pos)
      tech_api.energy.on_construct("yourmod:yourmachine", pos)
    end,
    on_destruct = function(pos)
      tech_api.energy.on_destruct(pos)
    end
  })
  ```

As for the way devices exchange power with the network, a callback is used like
seen above. The callback is different for each device type.

+ __Users__ *[description here]*
+ __Providers__ *[description here]*
+ __Storages__ *[description here]*

## Network graph management
Since there are multiple networks, they will all be grouped in a table which is
`tech_api.energy.networks` and they will be indexed with their id (a number).
Each network entry in the root table will be a table itself, representing the
network structure and attached nodes (devices). To access a specific network
table, given its `id`, the code will be `tech_api.energy.networks[id]`.

A network table will have the following fields:
+ `devices` which is a table that contains the list of all the devices connected
  to a network, indexed by their position.
+ `entry_point` which is the position of a random transporter node in the
  network. It doesn't matter which transporter this field points to, it could be
  any. This field is used whenever the energy subsystem needs to traverse all
  the network to update the graph as the starting point for the recursive
  function.

Regarding the various operations that may be done on a network, the first
(basic) implementation will launch a network traversal every time a device is
added or removed from the network. Also, a traversal will occur every time a
network merge or split happens. This has obviously the worst possible
performance, but will ensure that the graph never goes out of sync (as long as
the __nodestore__ module is consistent storing the registered nodes in the
Minetest world). This will provide a starting point for further
optimizations probably applying
[dynamic connectivity](https://en.wikipedia.org/wiki/Dynamic_connectivity)
solutions.

A device entry in the `devices` table (inside each network) will contain the
following fields:

+ `pos` which is the position in the world, used to identify the device. Since a
  node, as mentioned before, may actually register as *multiple* devices, the
  field that follows is also required.
+ `definition_id` which represents what device definition (of the possibly
  multiple available) actually represents the device connected to this network
+ `type` (user/provider/storage/monitor)
+ `max_rate`
+ `current_rate` which is the current energy consumed/produced (in the case of
  users and providers) and will stay the same until the next callback to the
  device reports that the rate has changed. Not used for __storage__ and
  __monitor__ device types.
+ `callback` which stores the callback function.
+ `callback_countdown` which keeps a countdown that, once reaches 0, will lead
  to the device's callback being called again. Its value will then be set to
  whatever the device asks to. This field is decremented every time unit of the
  system.
+ `content` (only for __storage__ devices) will keep the amount of energy
  contained in the device
+ `capacity` (only for __storage__ devices) will keep the maximum energy
  capacity of the device

The __nodestore__ module will keep information about the position of each node
name in the world. It will link a position (the index of the table) to a node
name (the one the devices registered with). This is used by the traversal
algorithm.

A table with all the node definitions will also be declared. This table will be
indexed by the name of the node and will lead to the definition(s) for that node.
Requesting a node name from the table will return a list of definitions which,
actually, are simply a copy of the table that was passed as a parameter to the
`tech_api.energy.register_device`/`tech_api.energy.register_transporter` methods.

The traversal algorithm, thus, will have to access all these three tables since:
+ It will need to put the result (the network structure it figured out) in the
  global networks table/graph.
+ It will have to know the position of the nodes in the world to check for
  adjacent ones (connected ones)
+ It will have to look at the definition the node registered with to figure out
  if it can really connect to the wire (`linkable_faces` and `class` parameters)

## Power distribution algorithm
*[how we collect/distribute/store/move power given an energy network]*

This is the part of the code that will be called every time unit. The algorithm,
every cycle, will iterate through all the networks in the world and manage their
energy.

The algorithm is yet to be defined.

Things we know for sure:
+ The algorithm will take in consideration the device `.current_rate` field to
  know how much it's producing/consuming
+ The algorithm will decrement the `callback_countdown` field for every device
  in the network, and fire callbacks accordingly. If a devices specifies an
  interval for the next callback which is equal to -1, we assume that we won't
  need to call the callback of the device until the device will inform us it's
  read to operate again (by calling the function
  `tech_api.energy.request_callback(pos)`)

## Performance notes
*[ideas, must-do s, tricks, notes, etc... for the performance of the implementation]*

Optimization of the network graph management will happen in steps. First we need
to ensure that, with no optimizations and just a basic 'dumb' implementation,
this API is working. Various changes are already planned to boost the performance
of the subsystem.

Currently we know for sure that:

+ No metadata has to be used. If it really has to, it must be used as little as
  possible and in such a way that access to it happens with the lowest frequency
  we can obtain.
+ As a consequence of the point above, all the networks and their structure
  must be defined in a Lua table (which means that everything is kept in RAM)
+ Networks must be represented so that they possibly don't need long
  computations when adding or removing a device to a big network.
+ No ABMs have to be used. Otherwise unloaded parts of the network will not work
+ Callbacks must be used as little as possible, especially on devices that are
  idle, to avoid pointless CPU usage on the server. @Ekdohibs made a proposal
  [here](https://github.com/minetest-mods/technic/issues/380). As soon as I can
  I'll report it here along with a good description.
+ Implement a way to limit the frequency of the network management cycles (i.e.
  the function that goes through all the devices and moves the energy around as
  needed). Find a way to possibly tie this to a specific interval so we can
  define a unit of measurement for power (like "energy unit"/"time interval").
  Also having this interval adjustable without compromising the network delivery
  would be nice since this would allow to limit the load on a server.
  Another idea, proposed by @raymoo in the same issue above, is to place each
  registered network in a different "container" (along with, eventually) other
  networks. Then we can execute a "container" in each globalstep, and do that in
  sequence for each container. This would balance the load. Not sure about the
  consistency of the interval between globalsteps (which affects the interval
  between network cycles).
+ Use a position indexed table instead of fetching metadata should be feasible
  and way faster, even for insanely big tables

## More...
*[more sections]*
