local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
core.loaded = 0;
core.WorkingTable = {};
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

function core:MonDKP_Search(tar, val)  --recursively searches tar (table) for val (string) as far as three nests deep
	local value = tostring(val);
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			for k,v in pairs(v) do
				if(type(v) == "table") then
					for k,v in pairs(v) do
						if v == value then return true end;
					end
				end
				if v == value then return true end;
			end
		end
		if v == value then return true end;
	end

	return false;
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

    if(event == "ADDON_LOADED") then
    	core.loaded = 1;
	    if (MonDKP_DB == nil) then MonDKP_DB = {} end;
		if (MonDKP_Log == nil) then MonDKP_Log = {} end;
		if (MonDKP_DKPTable == nil) then MonDKP_DKPTable = {} end;
		if (MonDKP_Tables == nil) then MonDKP_Tables = {} end;
		if (MonDKP_Loot == nil) then MonDKP_Loot = {} end;

		core:Print("Loaded "..#MonDKP_DKPTable.." records.");
		core.WorkingTable = MonDKP_DKPTable;
		
		-- Populates SavedVariable MonDKP_DKPTable with fake values for testing purposes if they don't already exist
		-- Delete this section and \WTF\AccountACCOUNT_NAME\SavedVariables\MonolithDKP.lua prior to actual use.
		local player_names = {"Qulyolalima", "Cadhangwong", "Gilingerth", "Emondeatt", "Puthuguth", "Eminin", "Mormiannis", "Hemilionter", "Malcologan", "Alerahm", "Cricordinus", "Arommoth", "Barnamnon", "Eughtor", "Aldreavus", "Loylencel", "Barredgar", "Gerneheav", "Julivente", "Barlannel", "Audeacell", "Derneth", "Fredeond", "Gutrichas", "Wiliannel", "Siertlan", "Simitram", "Ronettius", "Livendley", "Mordannichas", "Tevistavus", "Jaspian"}
		local classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }

		for i=1, #player_names do
			local p = player_names[i]
			if (core:MonDKP_Search(MonDKP_DKPTable, p) == false) then 		--
				tinsert(MonDKP_DKPTable, {
					player=p,
					class=classes[math.random(1, #classes)],
					previous_dkp=math.random(1000),
					dkp=math.random(0, 1000)
				})
			end
		end
		-- End testing DB
	end
end

----------------------------------
-- Initiallize Addon/SavedVariables
----------------------------------

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init); -- calls the above core:init function after addon_loaded event fires identifying the addon and SavedVariables are completely loaded
