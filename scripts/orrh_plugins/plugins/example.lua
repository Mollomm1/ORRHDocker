local this = {}

function this:Name()
	return "Example Plugin"
end

-- checks if the script is enabled based on Script, Client, or some other reason
-- arguments: Script - returns the script type name (Server, Solo, Studio), Client - returns the Client name
function this:IsEnabled(Script, Client)
	return false
end

-- executes before the game starts (server, solo, studio)
-- arguments: Script - returns the script type name (Server, Solo, Studio), Client - returns the Client name, NovetusVersion - returns the launcher version
function this:PreInit(Script, Client)
end

-- executes after the game starts (server, solo, studio)
-- arguments: none
function this:PostInit()
end

-- executes every 0.1 seconds. (server, solo, studio)
-- arguments: none
function this:Update()
end

-- executes after a character loads (server, solo, studio)
-- arguments: Player - Player getting a character loaded, Appearance - The object containing the appearance values 
-- notes: in play solo, you may have to respawn once to see any print outputs.
function this:OnLoadCharacter(Player, Appearance)
end

-- executes after a player joins (server)
-- arguments: Player - the Player joining
function this:OnPlayerAdded(Player)
    print("hello player")
end

-- executes after a player leaves (server)
-- arguments: Player - the Player leaving
function this:OnPlayerRemoved(Player)
    print("bye player")
end

-- this:OnPlayerKicked and this:OnPrePlayerKicked are unsupported

return(this)