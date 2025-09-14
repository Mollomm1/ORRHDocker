local Players = game.Players

local this = {}

function SerializeToJSON(value)
    local valueType = type(value)

    if valueType == "string" then
        return '"' .. value:gsub('"', '\\"') .. '"'
    elseif valueType == "number" or valueType == "boolean" then
        return tostring(value)
    elseif valueType == "table" then
        -- Check if it's a list (all keys are numeric and consecutive)
        local isArray = true
        local count = 0
        for k, v in pairs(value) do
            count = count + 1
            if type(k) ~= "number" then
                isArray = false
                break
            end
        end

        local result = {}
        if isArray then
            for i = 1, #value do
                table.insert(result, SerializeToJSON(value[i]))
            end
            return "[" .. table.concat(result, ",") .. "]"
        else
            for k, v in pairs(value) do
                table.insert(result, '"' .. tostring(k) .. '":' .. SerializeToJSON(v))
            end
            return "{" .. table.concat(result, ",") .. "}"
        end
    else
        return 'null'
    end
end

local function base64Encode(input)
	local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local function toBinaryString(byte)
		local bin = ""
		for i = 7, 0, -1 do
			local bit = math.floor(byte / (2 ^ i)) % 2
			bin = bin .. bit
		end
		return bin
	end

	local binary = ""

	-- Convert each byte to 8-bit binary
	for i = 1, #input do
		local byte = string.byte(input, i)
		binary = binary .. toBinaryString(byte)
	end

	-- Pad to a multiple of 6 bits
	while #binary % 6 ~= 0 do
		binary = binary .. "0"
	end

	local encoded = ""

	for i = 1, #binary, 6 do
		local chunk = string.sub(binary, i, i + 5)
		local index = tonumber(chunk, 2)
		if index then
			encoded = encoded .. string.sub(base64Chars, index + 1, index + 1)
		else
			error("Failed to parse binary chunk: " .. tostring(chunk))
		end
	end

	-- Add '=' padding
	while #encoded % 4 ~= 0 do
		encoded = encoded .. "="
	end

	return encoded
end

function this:Name()
	return "ORRHUtils"
end

this.Client = "?"

function this:IsEnabled(Script, Client)
	if Client == "2007E-FakeFeb" then
		this.Client = "2007E"
	else
		this.Client = Client
	end
	if this.Client == "2007E" then
		local part = Instance.new("Part")
		part.Name = "a_"
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = workspace
		local decal = Instance.new("Decal")
		decal.Name = "a_"
		decal.Parent = part
		this.decal = decal
	end
	return true
end

-- executes before the game starts (server, solo, studio)
-- arguments: Script - returns the script type name (Server, Solo, Studio), Client - returns the Client name, NovetusVersion - returns the launcher version
function this:PreInit(Script, Client)
end

-- executes after the game starts (server, solo, studio)
-- arguments: none
function this:PostInit()
end

this._lastUpdateTick = 0
this._updateInterval = 5

function this:Update()
	local now = tick()  -- Roblox's UNIX timestamp (float)

	if now - self._lastUpdateTick < self._updateInterval then
		return  -- Too soon, skip this update
	end

	self._lastUpdateTick = now  -- Update timestamp
	
	local playerList = {}

	if this.Client == "2007E" then
		playerList = {
			{
				PlayerName = "Player List Unsupported On 2007E",
				PlayerId = "0",
			},
		}
	else
		for _, player in ipairs(Players:GetPlayers()) do
				table.insert(playerList, {
					PlayerName = player.Name,
					PlayerId = tostring(player.userId),
				})
		end
	end

	jsonList = SerializeToJSON(playerList)
	if this.Client == "2007E" then
		this.decal.Texture = "http://localhost:3000/" .. base64Encode(jsonList)
		this.decal.Texture = "http://localhost:3000/server/info/" .. base64Encode(jsonList)
	else
		game:HttpGet("http://localhost:3000/server/info/" .. base64Encode(jsonList))
	end
end

-- executes after a character loads (server, solo, studio)
-- arguments: Player - Player getting a character loaded, Appearance - The object containing the appearance values 
-- notes: in play solo, you may have to respawn once to see any print outputs.
function this:OnLoadCharacter(Player, Appearance)
end

-- executes after a player joins (server)
-- arguments: Player - the Player joining
function this:OnPlayerAdded(Player)
end

-- executes after a player leaves (server)
-- arguments: Player - the Player leaving
function this:OnPlayerRemoved(Player)
end

-- this:OnPlayerKicked and this:OnPrePlayerKicked are unsupported

return(this)