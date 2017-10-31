Minetest **tech_api** repository
----------------------------

This repository contains the **tech_api** mod, which makes energy delivery and
distribution uniform throughout all the mods that use it. This means that if you
are creating a [Minetest](http://www.minetest.net/) mod that will
use/produce/store/carry energy, this API will give you all the tools you need to
simplify your life and make your creation compatible with all the other mods
that use it.

It has been written with the [Technic](https://github.com/minetest-mods/technic)
mod in mind since it needed a more performant energy system. This means that the
API fully supports energy tiers, devices connected to more than one network, etc...

Also, in the future, it may be extended to provide useful methods to deal with
items and fluids (i.e. pipes and tubes compatible between different mods), but
the focus is currently on power distribution.

The API is not yet complete, but it can already be used to play around and should
provide all the planned features without any problem. Actually, playing around
with it is really encouraged so bugs can be found and fixed and the development
can continue.

The API methods and working principles, however, shouldn't change in the near
future, so you may already start developing something with it. The main things
left to do are just to ensure better stability and reliability.

## Demo/example mod
You can check out the [tech_api_demo](https://github.com/gdelazzari/tech_api_demo)
mod to play around with the API and see how to actually implement something.
This may be your best way to learn how to use it until a tutorial is ready.

## Current state (TODO list)
+ [x] API skeleton and basic structure
+ [x] Documentation setup (LDoc)
+ [x] Definitions management
+ [x] Nodestore module
+ [x] Base API functions (on_construct/destruct, etc...)
+ [x] Network traversal/discovery algorithm
+ [x] Manage energy classes
+ [x] Manage linkable faces
+ [x] Manage multiple definitions for a node
+ [x] Manage a node being both a device and a transporter
+ [x] Energy distribution algorithm
  + [x] User devices
  + [x] Provider devices
  + [x] Storage devices
  + [x] Monitor devices
+ [ ] Clean up code
+ [ ] Generic performance optimizations
+ [x] Network management optimizations (when adding/removing devices/transporters)
+ [ ] Nodestore automatic backup every *x* time
  + [ ] Find a way to dump updates to disk faster (incremental backups?
    different DBs for each network? different DBs for different types of data?)
  + [ ] Algorithm to dynamically understand when to dump data to disk to
    optimize performace
+ [x] Better way of storing the nodestore (modstorage fails for a big one)
+ [ ] Investigate possible API-related swap_node issues
+ [ ] Write some tutorials
  + [ ] Basic stuff
  + [ ] Advanced stuff
  + [ ] Best way to swap nodes (e.g. to have different textures for node on/off)

## Documentation

The code is well documented using LDoc. To have in-depth documentation of the
Lua code, you can run the script `generate-doc.sh`, which will generate HTML
pages for the various modules. Then you can open `ldoc/index.html`.
Obviously you must have LDoc installed along with its requirements. Follow the
[instructions here](https://github.com/stevedonovan/LDoc).

If you don't care about pretty docs then you can just go through the code and
follow the comments.

## Contributing

You can contribute by creating an issue (or participating to the already open
ones). If you want to help directly with the code, just fork the repository
and make a pull request.

Thank you!
