**tech_api** specifications sheet (WIP)
---------------------------------------

This document defines everything about the API. It will be used as a reference
for the implementation/coding phase, but will also stay here as an in-depth
documentation of the system working principles.

The document is subdivided into various sections, representing various aspects
of the API.

_**(waiting to collect enough ideas, proposals, suggestions and requirements to
fill up this specs sheet)**_

## System architecture and basic concepts
This sections defines some basic concepts and conventions that the API takes for
granted

### Naming conventions
Important things to know:
+ A __network__ is a collection of devices connected together by transporters.
+ A __device__ an be a user, a provider or a storage. "Concretely" is usually
  a Minetest node.
+ A __user__ is a device that uses (consumes) power available in a network.
  An example is an electric furnace.
+ A __provider__ is a device that provides (gives) power to a network.
  An example is a solar panel.
+ A __storage__ is a device that stores power and exchanges it with a network
  it is connected to. An example is a battery.
+ A __transporter__ is just a generic way of describing a wire/cable.
  A transporter is simply something that can move energy around. Because it's a generic concept and is not tied to a specific node type, we can for instance
  declare a generator node (like a coal generator) as a transporter (besides
  being a provider), so that it can be placed in the middle of a long wire and
  take part of the wire (being also a "wire" itself).

### Classes
Every node that belongs to a network will have a "power class" (aka "tier").
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
*[what functions are available, how callbacks are used, what information we pass
between the nodes and the system, etc...]*

## Network graph management
*[how the a network is internally represented and managed]*

## Power distribution algorithm
*[how we collect/distribute/store/move power given an energy network]*

## Performance notes
*[ideas, must-do s, tricks, notes, etc... for the performance of the implementation]*

For now we know for sure that:

+ No metadata has to be used. If it really has to, it must be used as little as
  possible and in such a way that access to it happens with the lowest frequency
  we can obtain.
+ As a consequence of the point above, all the networks and their structure
  must be defined in a Lua table (which means that everything is kept in RAM)
+ Networks must be represented so that they possibly don't need long computations
  when adding or removing a device to a big network.
+ No ABMs have to be used. Otherwise unloaded parts of the network will not work.
+ Callbacks must be used as little as possible, especially on devices that are
  idle, to avoid pointless CPU usage on the server. @Ekdohibs made a proposal
  [here](https://github.com/minetest-mods/technic/issues/380). As soon as I can
  I'll report it here along with a good description.
+ Implement a way to limit the frequency of the network management cycles (i.e.
  the function that goes through all the devices and moves the energy around as
  needed). Find a way to possibly tie this to a specific interval so we can
  define a unit of measurement for power (like "*energy unit*"/"*time interval*").
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
