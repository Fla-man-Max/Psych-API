# Psych Lua compatibility adapter

API conventions and callback behavior reference Psych Engine 1.0.4, commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`, by Shadow Mario, RiverOaken, and contributors, under Apache License 2.0.

The files in `source/funkin/modding/psychlua` are a new/modified integration for official FNF v0.8.7, not the original Psych PlayState or a LuaSlice port. The host, object mapping, native event bridge, lifecycle ownership, and mod discovery are adapted to V-Slice.

The full Apache-2.0 license is included in `Psych-Engine-Apache-2.0.txt`. FNF's own license remains at the project root. LuaJIT/linc_luajit and hscript-iris are separate dependencies retaining their own licenses.
