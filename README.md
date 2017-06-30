Minetest **tech_api** repository
----------------------------

This repository contains the **tech_api** mod, which makes energy delivery and
distribution uniform throughout all the mods that use it. This means that if you
are creating a [Minetest](http://www.minetest.net/) mod that will
use/produce/store/carry energy, this API will give you all the tools you need to
simplify your life and make your creation compatible with all the other mods
that use it.

It is also an excuse to rewrite the energy subsystem of the
[Technic](https://github.com/minetest-mods/technic) mod, which will probably be
the first one to use the API.

Also, in the future, it may be extended to provide useful methods to deal with
items and fluids (i.e. pipes and tubes compatible between different mods), but
the focus is currently on power distribution.

Currently it has no implementation, but a [specification sheet](/docs/specifications.md)
is being written. Go check it out and feel free to contribute with your ideas,
requirements or wishes, so that we can build something we all agree upon and
we'll all be using in our mods.

## Contributing

You can contribute by creating an issue (or participating to the already open
ones). If you want to help directly with the specs, just fork the repository
and make a pull request.

You can also join the IRC channel #minetest-technic to talk with us

Thank you!
