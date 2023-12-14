# roblox_pack.luau
### a library for converting Roblox data types to and from text

### NOTE: Instances are converted to and from paths.
# Usage:
### Call `pack` to convert data into a string. `pack` will wrap the passed value into a table, if it isn't one itself.
```lua
roblox_pack.pack(data: any) -> string
```
### Call `unpack` to convert a packed string back into the original data passed. Since `pack` ensures that the value is a table, `unpack` will return a table.
```lua
roblox_pack.unpack(packed: string) -> {any}
```

# Example:
```lua
local roblox_pack = require(game.ReplicatedStorage:WaitForChild("roblox_pack"))
local data = {Vector2.zero, Vector3.zero, Vector2.new(0, 10)}
local packed = roblox_pack.pack(data)
print(packed)
local unpacked = roblox_pack.unpack(packed)
print(unpacked)
```
### Output:
![example output](assets/example_output.png)