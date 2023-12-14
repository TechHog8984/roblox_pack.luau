local roblox_pack = require(script.roblox_pack);

local total = 0;
local failed_count = 0;
local succeeded_count = 0;
-- checkEqual exists because numbers suck and Color3 == Color3 will return false when they are the same color if the r/g/b is off by 0.000001
local function test(data_type, value, checkEqual)
    total += 1;
	local data = {value};
	local packed = roblox_pack.pack(data);
	local unpacked = roblox_pack.unpack(packed);

	if (data[1] == unpacked[1]) or (checkEqual and checkEqual(data[1], unpacked[1])) then
        succeeded_count += 1;
        -- print(`{data_type} succeeded!`)
        return;
    end;
    failed_count += 1;
    print(`{data_type} failed!`);
end;
local tests = {};local tests_length = 0;
local function add(...)
    tests_length += 1;
    tests[tests_length] = {...}
end;
local function start(iterations)
    total = 0;
    failed_count = 0;
    succeeded_count = 0;
    if iterations then
        for _, args in next, tests do
            for _ = 1, iterations do
                test(table.unpack(args));
            end;
        end;
    else
        for _, args in next, tests do
            test(table.unpack(args));
        end;
    end;
    print(`\nDone! {failed_count}/{total} failed and {succeeded_count}/{total} succeeded.`);
end;

add("Axes", Axes.new(Enum.Axis.X, Enum.NormalId.Front));
add("BrickColor", BrickColor.random());
local catalog_search_params = CatalogSearchParams.new();
catalog_search_params.SearchKeyword = "Test";
catalog_search_params.MinPrice = 5000;
catalog_search_params.MaxPrice = 10000;
catalog_search_params.BundleTypes = {Enum.BundleType.Animations, Enum.BundleType.BodyParts};
add("CatalogSearchParams", catalog_search_params);
add("CFrame", CFrame.new(1000, 0, -1000));
local color_sequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 190, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 0, 255))
};
add("ColorSequence", color_sequence);
add("ColorSequenceKeypoint", color_sequence.Keypoints[2]);
add("DateTime", DateTime.now());
add("Enum", Enum.KeyCode);
add("EnumItem", Enum.KeyCode.LeftShift);
add("Faces", Faces.new(Enum.NormalId.Front, Enum.NormalId.Left));
add("FloatCurveKey", FloatCurveKey.new(0, 100, Enum.KeyInterpolationMode.Cubic));
add("Font fromEnum", Font.fromEnum(Enum.Font.Gotham));
add("Font fromId", Font.fromId(8836875837));
local temp_part = Instance.new("Part", workspace);
temp_part.Name = "Temp";
Instance.new("Part", temp_part).Name = "1hello";
add("Instance", temp_part);
add("NumberRange", NumberRange.new(-100, 10));
local number_sequence = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 1),
    NumberSequenceKeypoint.new(1, 0)
};
add("NumberSequence", number_sequence);
add("NumberSequenceKeypoint", number_sequence.Keypoints[2]);
local overlap_params = OverlapParams.new();
overlap_params.FilterDescendantsInstances = {workspace};
overlap_params.MaxParts = 10;
overlap_params.BruteForceAllSlow = true;
add("OverlapParams", overlap_params);
add("PathWaypoint", PathWaypoint.new(Vector3.new(10,10,10), Enum.PathWaypointAction.Walk));
add("Ray", Ray.new(Vector3.zero, Vector3.new(0, 0, 10)));
local raycast_params = RaycastParams.new();
raycast_params.FilterDescendantsInstances = {workspace.Baseplate};
raycast_params.FilterType = Enum.RaycastFilterType.Include;
raycast_params.BruteForceAllSlow = true;
add("RaycastParams", raycast_params);
add("Rect", Rect.new(1, 2, 3, 4));
add("TweenInfo", TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 2, true, 0.5));
add("UDim", UDim.new(-10, 10));
add("UDim2", UDim2.new(1, -10, 0, 10));
add("Vector2", Vector2.new(0, 1));
add("Vector2int16", Vector2int16.new(0, 1));
add("Vector3", Vector3.new(0, 1));
add("Vector3int16", Vector3int16.new(0, 1));

start();

if failed_count < 1 then
    print("Bulk testing...");
    start(1_000);
end;

temp_part:Destroy();
