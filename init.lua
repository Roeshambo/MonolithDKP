local _, core = ...;
local _G = _G;

--------------------------------------
-- Custom Slash Command
--------------------------------------
core.commands = {
	["config"] = core.MonDKP.Toggle,
	["reset"] = core.MonDKP.ResetPosition,
	["help"] = function()
		print(" ");
		core:Print("List of slash commands:")
		core:Print("|cff00cc66/dkp|r - Launches DKP Window");
		core:Print("|cff00cc66/dkp ?|r - Shows Help Info");
		core:Print("|cff00cc66/dkp reset|r - Resets DKP Window Position/Size");
		print(" ");
	end,
	["bid"] = {
		["start"] = function() print("bidding started") end,	-- place holders to launch bidding windows 

		["stop"] = function() print("bidding stopped") end,

	},
};

local function HandleSlashCommands(str)	
	if (#str == 0) then	
		core.commands.config();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = core.commands; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				core.commands.help();
				return;
			end
		end
	end
end

function core:Print(...)				--print function to add "MonolithDKP:" to the beginning of print() outputs.
    local hex = self.MonDKP:GetThemeColor().hex;
    local prefix = string.format("|cff%s%s|r", hex:upper(), "MonolithDKP:");
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

function core:init(event, name)
	if (name ~= "MonolithDKP") then return end 

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands!
	----------------------------------
	SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
	SlashCmdList.RELOADUI = ReloadUI;

	SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools");
		FrameStackTooltip_Toggle();
	end

	SLASH_MonolithDKP1 = "/dkp";
	SlashCmdList.MonolithDKP = HandleSlashCommands;
	
    core:Print("Welcome back", UnitName("player").."!");
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);
