--[=[
	File: roblox_pack.luau
	Creation Date: December 12, 2023
	Repo: https://github.com/TechHog8984/roblox_pack.luau
	Description:
	a library for converting Roblox data types to and from text
	For licensing info, see LICENSE
	Feel free to contribute! see https://create.roblox.com/docs/reference/engine/datatypes
]=]

-- NOTE: Instances are converted to and from paths

local function isDigit(byte)
	return (byte > 47) and (byte < 58);
end;
local function iscDigit(char)
	return isDigit(char:byte());
end;

local characters_metatable = {
	__index = function(self, key)
		if key < 0 then
			return rawget(self, self.negative_offset + key);
		end;
	end
};

local String = {};
function String:__tostring()
	return self.raw;
end;
function String:__index(key)
	if type(key) == "number" then
		return self.characters[key];
	end;
	return String[key];
end;

function String.new(str)
	local characters, bytes = setmetatable({}, characters_metatable), {};
	local length = 0;

	table.clear(characters);
	table.clear(bytes);

	str:gsub('.', function(char)
		length += 1;
		characters[length] = char;
		bytes[length] = char:byte();
	end);
	characters.negative_offset = length + 1;

	return setmetatable({
		raw = str,
		length = length,
		is_empty = length < 1,

		characters = characters,
		bytes = bytes
	}, String);
end;

function String:startsWith(query)
	if self.length < #query then
		return false;
	end;
	if self.raw == query then
		return true;
	end;
	local buffer = '';
	for i = 1, #query do
		buffer ..= self[i];
	end;
	return buffer == query;
end;

function String:remove(index)
	if self.length < 1 then
		error("attempted to remove a character from an empty string");
	end;
	if index < 1 then
		error("invalid index for remove. expected a value above 0; got " .. index);
	end;
	if index > self.length then
		error("invalid index for remove. expected a value no higher than the length; got " .. index);
	end;

	self.raw = self.raw:sub(1, index - 1) .. self.raw:sub(index + 1, -1);
	self.characters.negative_offset = self.length;
	table.remove(self.bytes, index);
	self.length -= 1;
	self.is_empty = self.length < 1;

	return table.remove(self.characters, index);
end;
function String:removeRange(from, to)
	if self.length < 1 then
		error("attempted to remove a character from an empty string");
	end;
    if from > to then
        error("from is bigger than to for removeRange. to should be bigger than from");
    end;
	if from < 1 then
		error("invalid from for removeRange. expected a value above 0; got " .. index);
	end;
	if to > self.length then
		error("invalid to for removeRange. expected a value no higher than the length; got " .. index);
	end;

    self.raw = self.raw:sub(1, from - 1) .. self.raw:sub(to + 1, -1);
    for _ = from, to do
        table.remove(self.bytes, from);
    end;
    self.length -= (to - from) + 1;
    self.characters.negative_offset = self.length + 1;
    self.is_empty = self.length < 1;

    local characters_removed = '';
    for _ = from, to do
        characters_removed ..= table.remove(self.characters, from);
    end;
    return characters_removed;
end;

function String:readNumberString(index)
	index = index or 1;
	if not isDigit(self.bytes[index]) and self[index] ~= '-' and self[index] ~= '.' then
		error("Failed to read number: the byte at index " .. index .. " isn't a number, negative symbol, or period: " .. self[index]);
	end;

	local found_period = false;
	local number_str = '';
	local char = self:remove(index);
	if char == '-' or char == '.' then
		found_period = char == '.';
		number_str ..= char;
		char = self:remove(index);
	end;
	if not iscDigit(char) then
		error("Failed to read number: expected a digit; got " .. char);
	end;
	number_str ..= char;

	while not self.is_empty do
		char = self[index];
		if char == '.' then
			found_period = true;
		elseif not isDigit(self.bytes[index]) then
			break;
		end;
		number_str ..= char;
		self:remove(index);
	end;

	return number_str;
end;
function String:readNumber(index)
	return tonumber(self:readNumberString(index));
end;
function String:readNumberThenRemove(char, index)
    index = index or 1;
	local num = self:readNumber(index);
	if self.is_empty then
		error("Failed to read number then remove: string is empty after read");
	end;
	if self[index] ~= char then
		error(`Failed to read number then remove: expected character '{char}'; got '{self[1]}'`);
	end;
	self:remove(index);
	return num;
end;
function String:readNumberThenRemoveOptional(char, index)
    index = index or 1;
	local num = self:readNumber(index);
	if self[index] == char then
        if self.is_empty then
            error("Failed to read number then remove: string is empty after read");
        end;
        self:remove(index);
	end;
	return num;
end;

function String:readDigit(index)
	index = index or 1;
	local char = self[index];
	if not isDigit(self.bytes[index]) then
		error(`Failed to read digit: the char at index {index} isn't a number: '{char}'`);
	end;
	self:remove(index);
	return tonumber(char);
end;

function String:readUntil(query, index, optional)
    if type(optional) == nil then optional = false; end;
    index = index or 1;
	local char = self[index];
    if char == query then
        return char;
    end;
    self:remove(index);
    local str = char;

    local found = false;
    while not self.is_empty do
		char = self:remove(index);
        if char == query then
            found = true;
            break;
        end;
		str ..= char;
	end;

    if not optional and not found then
        error(`Failed to read until: never reached character '{query}'`);
    end;

    return str;
end;
function String:readUntilOptional(query, index)
    return self:readUntil(query, index, true);
end;

function String:readUntilPattern(pattern, index, optional)
    if type(optional) == nil then optional = false; end;
    index = index or 1;
    local char = self[index];
    if char:match(pattern) then
        return char;
    end;
    self:remove(index);
    local str = char;

    local found = false;
    while not self.is_empty do
        char = self[index];
        if char:match(pattern) then
            found = true;
            break;
        end;
        self:remove(index);
        str ..= char;
    end;

    if not optional and not found then
        error(`Failed to read until: never reached character '{query}'`);
    end;

    return str;
end;
function String:readUntilPatternOptional(query, index)
    return self:readUntilPattern(query, index, true);
end;

local quote = '"';
local hyphen = '-';

local backslash_escape_map = {
	['\a'] = "\\a", ['\b'] = "\\b", ['\f'] = "\\f",
	['\n'] = "\\n", ['\r'] = "\\r", ['\t'] = "\\t",
	['\v'] = "\\v", ['\\'] = "\\\\",[quote] = "\\\"",
};
local reverse_backslash_escape_map = {
	a = '\a', b = '\b', f = '\f', n = '\n',
	r = '\r', t = '\t', v = '\v', ['\\'] = '\\', 
	[quote] = quote
};

local function serialize(str)
	str = String.new(str);
	if str.is_empty then
		return quote .. quote;
	end;

	local result = quote;

	local index = 1;
	local char;
	repeat
		char = str[index];
		if backslash_escape_map[char] then
			char = backslash_escape_map[char];
		end;
		result ..= char;
		index += 1;
	until index > str.length;

	result ..= quote;
	return result;
end;

function String:readString()
	local result = '';
	if self.is_empty then
		error("Error when deserializing string: string is empty");
	end;

	local char = self:remove(1);
    if char ~= quote then
        error(`Error when deserializing string: expected '"'; got '{char}'`);
    end;

    if self[1] == quote then
		self:remove(1);
        return result;
    end;

	local found_exiting_quote = false;
	repeat
		char = self:remove(1);
		if char == '\\' then
			if self.is_empty then
                error("Error when deserializing string: unfinished backslash escape");
			end;
			char = self:remove(1);
			if reverse_backslash_escape_map[char] then
				char = reverse_backslash_escape_map[char];
			else
				if isDigit(self.bytes[1]) then
					local number_str = char;
					for _ = 1,2 do
						if not isDigit(self.bytes[1]) then
							break;
						end;
						char = self:remove(1);
						number_str ..= char;
						if self.is_empty then
							break;
						end;
					end;
					char = string.char(tonumber(number_str));
				else
                    error(`Error when deserializing string: unknown backslash escape character: '{char}'`);
				end;
			end;
        elseif char == quote then
			found_exiting_quote = true;
            break;
		end;
		result ..= char;
	until self.is_empty;

	if not found_exiting_quote then
		error("Error when deserializing string: never found exiting quote");
	end;

	return result;
end;

local encode, decode, pack, unpack;

local AXIS = Enum.Axis;
local AXIS_X = AXIS.X;
local AXIS_Y = AXIS.Y;
local AXIS_Z = AXIS.Z;

local NORMALID = Enum.NormalId;
local NORMALID_TOP = NORMALID.Top;
local NORMALID_BOTTOM = NORMALID.Bottom;
local NORMALID_LEFT = NORMALID.Left;
local NORMALID_RIGHT = NORMALID.Right;
local NORMALID_BACK = NORMALID.Back;
local NORMALID_FRONT = NORMALID.Front;

local KEY_INTERPOLATION_MODE = Enum.KeyInterpolationMode:GetEnumItems();
local FONT_STYLE = Enum.FontStyle:GetEnumItems();
local FONT_WEIGHT = Enum.FontWeight:GetEnumItems();
local CATALOG_SORT_TYPE = Enum.CatalogSortType:GetEnumItems();
local CATALOG_SORT_AGGREGATION = Enum.CatalogSortAggregation:GetEnumItems();
local CATALOG_CATEGORY_FILTER = Enum.CatalogCategoryFilter:GetEnumItems();
local SALES_TYPE_FILTER = Enum.SalesTypeFilter:GetEnumItems();
local RAYCAST_FILTER_TYPE = Enum.RaycastFilterType:GetEnumItems();
local PATH_WAYPOINT_ACTION = Enum.PathWaypointAction:GetEnumItems();
local EASING_DIRECTION = Enum.EasingDirection:GetEnumItems();
local EASING_STYLE = Enum.EasingStyle:GetEnumItems();

local function boolToBit(bool)
	if type(bool) ~= "boolean" then
		error(`Expected type bool for boolToBit; got {typeof(bool)}`);
	end;
	return if bool then 1 else 0;
end;
local function bitToBool(bit)
	return bit == 1;
end;

local constructor_encoders = {};do
	local function add(data_type, order, encode, decode)
		local defaults = {};

		local object = data_type.new();
		for _, name in next, order do
			defaults[name] = object[name];
		end;

		constructor_encoders[data_type] = {
			order = order,
			encode = encode,
			decode = decode,
			defaults = defaults
		};
	end;

	local function _serialize(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else serialize(value);
	end;
	local function number(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else value .. '_';
	end;
	local function enum(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else value.Value;
	end;
	local function enum_minus1(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else value.Value - 1;
	end;
	local function list(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else pack(value);
	end;
	local function bool(value, default)
		local is_default = value == default;
		return boolToBit(is_default) .. if is_default then '' else boolToBit(value);
	end;

	local function readNumberThenRemove_(input)
		return input:readNumberThenRemove("_");
	end;
	local function readBool(input)
		return bitToBool(input:readDigit());
	end;

	add(CatalogSearchParams,
		{
			"SearchKeyword",
			"MinPrice",
			"MaxPrice",
			"SortType",
			"SortAggregation",
			"CategoryFilter",
			"SalesTypeFilter",
			"BundleTypes",
			"AssetTypes",
			"IncludeOffSale",
			"CreatorName"
		},
		{
			SearchKeyword = _serialize,
			MinPrice = number,
			MaxPrice = number,
			SortType = enum,
			SortAggregation = enum_minus1,
			CategoryFilter = enum_minus1,
			SalesTypeFilter = enum_minus1,
			BundleTypes = list,
			AssetTypes = list,
			IncludeOffSale = bool,
			CreatorName = _serialize
		},
		{
			SearchKeyword = String.readString,
			MinPrice = readNumberThenRemove_,
			MaxPrice = readNumberThenRemove_,
			SortType = function(input)
				local sort_type = input:readDigit();
				return CATALOG_SORT_TYPE[(if sort_type > 3 then sort_type - 1 else sort_type)];
			end,
			SortAggregation = function(input)return CATALOG_SORT_AGGREGATION[input:readDigit()];end,
			CategoryFilter = function(input)return CATALOG_CATEGORY_FILTER[input:readDigit()];end,
			SalesTypeFilter = function(input)return SALES_TYPE_FILTER[input:readDigit()];end,
			BundleTypes = "unpack", -- later, after unpack is declared, we loop through each decode table and replace "unpack" with unpack
			AssetTypes = "unpack",
			IncludeOffSale = readBool,
			CreatorName = String.readString
		}
	);

	local function readRaycastFilterType(input)
		return RAYCAST_FILTER_TYPE[input:readDigit()];
	end;
	add(OverlapParams,
		{
			"RespectCanCollide",
			"BruteForceAllSlow",
			"FilterType",
			"MaxParts",
			"CollisionGroup",
			"FilterDescendantsInstances"
		},
		{
			RespectCanCollide = bool,
			BruteForceAllSlow = bool,
			FilterType = enum,
			MaxParts = number,
			CollisionGroup = _serialize,
			FilterDescendantsInstances = list
		},
		{
			RespectCanCollide = readBool,
			BruteForceAllSlow = readBool,
			FilterType = readRaycastFilterType,
			MaxParts = readNumberThenRemove_,
			CollisionGroup = String.readString,
			FilterDescendantsInstances = "unpack"
		}
	);
	add(RaycastParams,
		{
			"RespectCanCollide",
			"BruteForceAllSlow",
			"IgnoreWater",
			"FilterType",
			"CollisionGroup",
			"FilterDescendantsInstances"
		},
		{
			RespectCanCollide = bool,
			BruteForceAllSlow = bool,
			IgnoreWater = bool,
			FilterType = enum,
			CollisionGroup = _serialize,
			FilterDescendantsInstances = list
		},
		{
			RespectCanCollide = readBool,
			BruteForceAllSlow = readBool,
			IgnoreWater = readBool,
			FilterType = readRaycastFilterType,
			CollisionGroup = String.readString,
			FilterDescendantsInstances = "unpack"
		}
	);
end;
local function constructorEncoder(base, data_type)
	local encoder = constructor_encoders[data_type];
	return function(value)
		local result = '';

		for _, name in next, encoder.order do
			result ..= encoder.encode[name](value[name], encoder.defaults[name]);
		end;

		return base .. result;
	end;
end;

local function snipEncoded(encoded)
	encoded = String.new(encoded);
	encoded:readUntilPattern('_');
	encoded:remove(1);

	return encoded.raw;
end;
local function encodeAndSnip(obj)
	return snipEncoded(encode(obj));
end;

local encode_table; encode_table = {
	["nil"] = function() return 'n'; end,
	boolean = function(value) return 'b' .. boolToBit(value); end,
	number = function(n)
		return 'i' .. string.pack('n', n) .. '_';
	end,
	string = serialize,
	table = pack,

	Axes = function(value)
		local faces = {
			[AXIS_X] = boolToBit(value.X and value.Left and value.Right),
			[AXIS_Y] = boolToBit(value.Y and value.Top and value.Bottom),
			[AXIS_Z] = boolToBit(value.Z and value.Back and value.Front)
		};

		return "ra_" .. faces[AXIS_X] ..faces[AXIS_Y] .. faces[AXIS_Z];
	end,
	BrickColor = function(value)
		return "rb_" .. encode(value.Number);
	end,
	CatalogSearchParams = constructorEncoder("rcsp_", CatalogSearchParams),
	CFrame = function(value)
		local components = {value:GetComponents()};

		local all_zero = true;
		for _, v in next, components do
			if v ~= 0 then
				all_zero = false;
				break;
			end;
		end;

		if all_zero then
			return "rcf_1";
		end;

		local x, y, z,
		R00, R01, R02,
		R10, R11, R12,
		R20, R21, R22 = table.unpack(components);

		local xyz_all_zero = (x == 0) and (y == 0) and (z == 0);
		local xyz = boolToBit(xyz_all_zero);
		if not xyz_all_zero then
			xyz ..= encode(x) .. encode(y) .. encode(z);
		end;

		local rotation_all_zero = (R00 == 0) and (R01 == 0) and (R02 == 0) and (R10 == 0) and (R11 == 0) and (R12 == 0) and (R20 == 0) and (R21 == 0) and (R22 == 0);
		local rotation = boolToBit(rotation_all_zero);
		if not rotation_all_zero then
			rotation ..= encode(R00) .. encode(R01) .. encode(R02) .. encode(R10) .. encode(R11) .. encode(R12) .. encode(R20) .. encode(R21) .. encode(R22);
		end;

		return "rcf_0" .. xyz .. rotation;
	end,
	Color3 = function(value)
		return "rc_" .. value:ToHex();
	end,
	ColorSequence = function(value)
		local length = #value.Keypoints;
		local points = '';
		for _, point in next, value.Keypoints do
			points ..= snipEncoded(encode(point));
		end;
		return "rcs_" .. encode(length) .. points;
	end,
	ColorSequenceKeypoint = function(value)
		return "rcsk_" .. encode(value.Time) .. value.Value:ToHex();
	end,
    DateTime = function(value)
        return "rd_" .. encode(value.UnixTimestampMillis);
    end,
    Enum = function(value)
        return "re_" .. tostring(value);
    end,
    EnumItem = function(value)
        return "rei_" .. tostring(value.EnumType) .. '_' .. value.Name;
    end,
    Faces = function(value)
        return "rf_" .. boolToBit(value.Top) .. boolToBit(value.Bottom) .. boolToBit(value.Left) .. boolToBit(value.Right) .. boolToBit(value.Back) .. boolToBit(value.Front);
    end,
    FloatCurveKey = function(value)
        return "rfc_" .. value.Interpolation.Value .. encode(value.Time) .. encode(value.Value);
    end,
    Font = function(value)
        return "rft_" .. value.Style.Value .. value.Weight.Value/100 .. serialize(value.Family);
    end,
	Instance = function(value)
		if value == game then return "ri_game;"; end;
		local path = '';
		local name = value.Name;
	
		while value.Parent do
			if iscDigit(name:sub(1,1)) or name:match("[^%w_]") then
				name = `[{serialize(name)}]`;
			else
				name = '.' .. name;
			end;
			path = name .. path;
			value = value.Parent;
			name = value.Name;
		end;
	
		return "ri_game" .. path .. ';';
	end,
    NumberRange = function(value)
        return "rn_" .. encode(value.Min) .. (if value.Min == value.Max then '1' else ('0' .. encode(value.Max)));
    end,
    NumberSequence = function(value)
        local length = #value.Keypoints;
        local points = '';
        for _, point in next, value.Keypoints do
            points ..= snipEncoded(encode(point)) .. ',';
        end;
        return "rns_" .. encode(length) .. points:sub(1, -2);
    end,
    NumberSequenceKeypoint = function(value)
        return "rnsk_" .. encode(value.Time) .. encode(value.Value) .. (if value.Envelope == 0 then '0' else ('1' .. encode(value.Envelope)));
    end,
	OverlapParams = constructorEncoder("ro_", OverlapParams),
	PathWaypoint = function(value)
		local position = encodeAndSnip(value.Position);
		return "rp_" .. (value.Action.Value + 1) .. position .. '_' .. serialize(value.Label);
	end,
	PhysicalProperties = function(value)
		return "rpp_" .. encode(value.Density) .. encode(value.Friction) .. encode(value.Elasticity) .. encode(value.FrictionWeight) .. encode(value.ElasticityWeight);
	end,
	Ray = function(value)
		return "rr_" .. encodeAndSnip(value.Origin) .. '_' .. encodeAndSnip(value.Direction);
	end,
	RaycastParams = constructorEncoder("rrp_", RaycastParams),
	Rect = function(value)
		return "rrc_" .. encodeAndSnip(value.Min) .. '_' .. encodeAndSnip(value.Max);
	end,
	TweenInfo = function(value)
		return "rt_" .. boolToBit(value.Reverses) .. (value.EasingDirection.Value + 1) .. encode(value.EasingStyle.Value + 1) .. encode(value.Time) .. encode(value.DelayTime) .. encode(value.RepeatCount);
	end,
	UDim = function(value)
		return "ru_" .. encode(value.Scale) .. encode(value.Offset);
	end,
	UDim2 = function(value)
		return "ru2_" .. encodeAndSnip(value.X) .. '_' .. encodeAndSnip(value.Y);
	end,
	Vector2 = function(value)
		local x = value.X;
		local y = value.Y;

		local x_is_zero = x == 0;
		local y_is_zero = y == 0;

		local both_zero = x_is_zero and y_is_zero;

		if both_zero then
			x, y = '','';
		else
			x = if x_is_zero then '1' else ('0' .. encode(x));
			y = if y_is_zero then '1' else ('0' .. encode(y));
		end;

		return "rv2_" .. boolToBit(both_zero) .. x .. y;
	end,
	Vector2int16 = function(value)
		return "rv2i_" .. snipEncoded(encode_table.Vector2(value));
	end,
	Vector3 = function(value)
		local x = value.X;
		local y = value.Y;
		local z = value.Z;

		local x_is_zero = x == 0;
		local y_is_zero = y == 0;
		local z_is_zero = z == 0;

		local all_zero = x_is_zero and y_is_zero and z_is_zero;

		if all_zero then
			x, y, z = '','','';
		else
			x = if x_is_zero then '1' else ('0' .. encode(x));
			y = if y_is_zero then '1' else ('0' .. encode(y));
			z = if z_is_zero then '1' else ('0' .. encode(z));
		end;

		return "rv3_" .. boolToBit(all_zero) .. x .. y .. z;
	end,
	Vector3int16 = function(value)
		return "rv3i_" .. snipEncoded(encode_table.Vector3(value));
	end
};

local function constructorDecoder(data_type)
	return function(input)
		local result = data_type.new();

		for _, name in next, constructor_encoders[data_type].order do
			if not bitToBool(input:readDigit()) then
				result[name] = constructor_encoders[data_type].decode[name](input);
			end;
		end;

		return result;
	end;
end;

local VECTOR2_ZERO = Vector2.zero;
local VECTOR3_ZERO = Vector3.zero;

local function decodeVector2(input)
	local x, y = 0,0;

	local both_zero = bitToBool(input:readDigit());
	if both_zero then
		return x,y;
	end;

	if not bitToBool(input:readDigit()) then
		x = decode(input);
	end;
	if not bitToBool(input:readDigit()) then
		y = decode(input);
	end;

	return x,y;
end;
local function decodeVector3(input)
	local x, y, z = 0,0,0;

	local all_zero = bitToBool(input:readDigit());
	if all_zero then
		return x,y,z;
	end;

	if not bitToBool(input:readDigit()) then
		x = decode(input);
	end;
	if not bitToBool(input:readDigit()) then
		y = decode(input);
	end;
	if not bitToBool(input:readDigit()) then
		z = decode(input);
	end;

	return x,y,z;
end;
local roblox_decode_table;roblox_decode_table = {
	a = function(input) -- Axes
		local faces = {
			if bitToBool(input:readDigit()) then AXIS_X else nil,
			if bitToBool(input:readDigit()) then AXIS_Y else nil,
			if bitToBool(input:readDigit()) then AXIS_Z else nil,
		};

		return Axes.new(table.unpack(faces));
	end,
	b = function(input) -- BrickColor
		return BrickColor.new(decode(input));
	end,
    csp = constructorDecoder(CatalogSearchParams),
	cf = function(input) -- CFrame
		local all_zero = bitToBool(input:readDigit());
		local x, y, z,
		R00, R01, R02,
		R10, R11, R12,
		R20, R21, R22 = 0,0,0,0,0,0,0,0,0,0,0,0;
		if not all_zero then
			local xyz_all_zero = bitToBool(input:readDigit());
			if not xyz_all_zero then
				x, y, z = decode(input), decode(input), decode(input);
			end;
			local rotation_all_zero = bitToBool(input:readDigit());
			if not rotation_all_zero then
				R00, R01, R02,
				R10, R11, R12,
				R20, R21, R22 = decode(input), decode(input), decode(input),
				decode(input), decode(input), decode(input),
				decode(input), decode(input), decode(input);
			end;
		end;

		return CFrame.new(x, y, z,
			R00, R01, R02,
			R10, R11, R12,
			R20, R21, R22
		);
	end,
	c = function(input) -- Color3
		return Color3.fromHex(input:removeRange(1, 6));
	end,
	cs = function(input) -- ColorSequence
		local keypoints = {};
		local length = decode(input);
		for index = 1, length do
			keypoints[index] = roblox_decode_table.csk(input);
		end;
		return ColorSequence.new(keypoints);
	end,
	csk = function(input) -- ColorSequenceKeypoint
		return ColorSequenceKeypoint.new(decode(input), Color3.fromHex(input:removeRange(1, 6)));
	end,
    d = function(input) -- DateTime
        return DateTime.fromUnixTimestampMillis(decode(input));
    end,
    e = function(input) -- Enum
        return Enum[input:readUntilPatternOptional('[^%w]')];
    end,
    ei = function(input) -- EnumItem
        return Enum[input:readUntil('_')][input:readUntilPatternOptional('[^%w]')];
    end,
    f = function(input) -- Faces
        local faces = {
			if bitToBool(input:readDigit()) then NORMALID_TOP else nil,
			if bitToBool(input:readDigit()) then NORMALID_BOTTOM else nil,
			if bitToBool(input:readDigit()) then NORMALID_LEFT else nil,
			if bitToBool(input:readDigit()) then NORMALID_RIGHT else nil,
            if bitToBool(input:readDigit()) then NORMALID_BACK else nil,
            if bitToBool(input:readDigit()) then NORMALID_FRONT else nil,
		};

		return Faces.new(table.unpack(faces));
    end,
    fc = function(input) -- FloatCurveKey
        local interpolation = KEY_INTERPOLATION_MODE[input:readDigit() + 1];

        return FloatCurveKey.new(decode(input), decode(input), interpolation);
    end,
    ft = function(input) -- Font
        local style = FONT_STYLE[input:readDigit() + 1];
        local weight = FONT_WEIGHT[input:readDigit()];

		local family = input:readString();
        return Font.new(family, weight, style);
    end,
	i = function(input) -- Instance
		local raw = input.raw;
		if not input:startsWith("game") then
			error("Failed to read instance path: expected string starting with 'game': " .. raw);
		end;
		raw = raw:sub(1, -2); -- get rid of artificial semicolon at the end
		input:removeRange(1, 4);

		local value = game;
		local char;
		repeat
			char = input:remove(1);
			if char == ';' then
				break;
			elseif char == '.' then
				value = value:FindFirstChild(input:readUntilPattern("[^%w_]"));
				if not value then
					error(`Failed to find object at path: '{raw}'`);
				end;
			elseif char == '[' then
				local name = input:readString();
				char = input:remove(1);
				if char ~= ']' then
					error(`Failed to read instance path: expected ']' after string; got '{char}'`);
				end;
				value = value:FindFirstChild(name);
				if not value then
					error(`Failed to find object at path: '{raw}'`);
				end;
			else
				error(`Failed to read instance path: expected ';', '.', or '['; got '{char}'`);
			end;
		until input.is_empty;

		return value;
	end,
    n = function(input) -- NumberRange
        local min = decode(input);
		local max = if bitToBool(input:readDigit()) then min else decode(input);

        return NumberRange.new(min, max);
    end,
    ns = function(input) -- NumberSequence
        local keypoints = {};
        local length = decode(input);
        for index = 1, length do
            keypoints[index] = roblox_decode_table.nsk(input);
			if input[1] == ',' then
				input:remove(1);
			end;
        end;
        return NumberSequence.new(keypoints);
    end,
    nsk = function(input) -- NumberSequenceKeypoint
        local time = decode(input);
        local value = decode(input);
		local envelope;
        if bitToBool(input:readDigit()) then
			envelope = decode(input);
		end;

        return NumberSequenceKeypoint.new(time, value, envelope);
    end,
	o = constructorDecoder(OverlapParams),
	p = function(input) -- PathWaypoint
		local action = PATH_WAYPOINT_ACTION[input:readDigit()];
		local position = roblox_decode_table.v3(input);
		input:remove(1); -- remove underscore
		local label = input:readString();

		return PathWaypoint.new(position, action, label);
	end,
	pp = function(input) -- PhysicalProperties
		return PhysicalProperties.new(
			decode(input),
			decode(input),
			decode(input),
			decode(input),
			decode(input)
		);
	end,
	r = function(input) -- Ray
		local origin = roblox_decode_table.v3(input);
		input:remove(1); -- remove underscore
		return Ray.new(origin, roblox_decode_table.v3(input));
	end,
	rp = constructorDecoder(RaycastParams),
	rc = function(input) -- Rect
		local min = roblox_decode_table.v2(input);
		input:remove(1); -- remove underscore
		return Rect.new(min, roblox_decode_table.v2(input));
	end,
	t = function(input) -- TweenInfo
		local reverses = bitToBool(input:readDigit());
		local direction = EASING_DIRECTION[input:readDigit()];
		local style = EASING_STYLE[decode(input)];
		local time, delay, repeat_count = decode(input), decode(input), decode(input);
		return TweenInfo.new(time, style, direction, repeat_count, reverses, delay);
	end,
	u = function(input) -- UDim
		return UDim.new(decode(input), decode(input));
	end,
	u2 = function(input) -- UDim2
		local x = roblox_decode_table.u(input);
		input:remove(1); -- remove underscore
		return UDim2.new(x, roblox_decode_table.u(input));
	end,
	v2 = function(input) -- Vector2
		return Vector2.new(decodeVector2(input));
	end,
	v2i = function(input) -- Vector2int16
		return Vector2int16.new(decodeVector2(input));
	end,
	v3 = function(input) -- Vector3
		return Vector3.new(decodeVector3(input));
	end,
	v3i = function(input) -- Vector3int16
		return Vector3int16.new(decodeVector3(input));
	end
};

encode = function(value)
	if encode_table[typeof(value)] then
		return encode_table[typeof(value)](value);
	end;
	error(`Type {typeof(value)} is not supported for encoding.`);
end;
decode = function(input)
    if type(input) == "string" then input = String.new(input); end;
	if input.is_empty then
		error("Error when decoding: got empty value");
	end;

    local raw = input.raw;
    local char = input[1];
    if raw == 'n' then
		input:remove(1);
        return nil;
    elseif char == 'b' then
		input:remove(1);
        return bitToBool(input:remove(1));
	elseif char == 'i' then
		input:remove(1);
		return (string.unpack('n', input:readUntil('_')));
    elseif char == quote then
        return input:readString();
    elseif char == '{' then
        return unpack(input);
    elseif char == 'r' then
        input:remove(1);
        local index = input:readUntil('_');

		if not roblox_decode_table[index] then
			error(`Error when decoding: invalid index for decode table "{index}"`);
		end;
		return roblox_decode_table[index](input);
	end;
	error("Error when decoding: failed to decode (invalid value): " .. input.raw);
end;

pack = function(data)
	if type(data) ~= "table" then
		data = {data};
	end;

	-- no data; return empty table string
	if (next(data)) == nil then
		return '{}';
	end;

    local packed = '{';

	for key, value in next, data do
		packed ..= `[{encode(key)}]={encode(value)},`;
	end;

	-- remove trailing comma if present
	if packed:sub(-1,-1) == "," then
		packed = packed:sub(1, -2);
	end;

	packed = packed .. '}';

	return packed;
end;

local UNPACK_STATE = {
    START = 0,
    KEY = 1,
    VALUE = 2
};
unpack = function(input)
    if type(input) == "string" then input = String.new(input); end;
	local data = {};

	-- no data; return empty table
	if input.is_empty then
		return data;
	end;

    local char = input:remove(1);
    if char ~= '{' then
        error(`Failed to unpack: expected '\{'; got '{char}'`);
    end;
    if input.is_empty then
        error("Failed to unpack: expected '}' or start of key; got nothing (string is empty after '{')");
    end;
    if input[1] == '}' then
        input:remove(1);
        return data;
    end;

    local state = UNPACK_STATE.START;
    local key;
    local value;
    while not input.is_empty do
        if state == UNPACK_STATE.START then
            key = '';
            value = '';
            char = input:remove(1);
            if char ~= '[' then
                error(`Failed to unpack: expected '['; got '{char}'`);
            end;
            state = UNPACK_STATE.KEY;
        elseif state == UNPACK_STATE.KEY then
            key = decode(input);
            char = input:remove(1);
            if char ~= ']' then
                error(`Failed to unpack: expected ']'; got '{char}'`);
            end;
            char = input:remove(1);
            if char ~= '=' then
                error(`Failed to unpack: expected '='; got '{char}'`);
            end;
            state = UNPACK_STATE.VALUE;
        elseif state == UNPACK_STATE.VALUE then
            value = decode(input);
            char = if input.is_empty then 'nil' else input:remove(1);
            if char == ',' then
                state = UNPACK_STATE.START;
                data[key] = value;
            elseif char == '}' then
                data[key] = value;
                break;
            else
                error(`Failed to unpack: expected '}' or ','; got '{char}'`);
            end;
        end;
	end;

	return data;
end;
for _, encoder in next, constructor_encoders do
	for k,v in next, encoder.decode do
		if type(v) == "string" and v == "unpack" then
			encoder.decode[k] = unpack;
		end;
	end;
end;

return {
	pack = pack,
	unpack = unpack,
};