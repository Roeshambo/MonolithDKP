local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

--------------------------------------
-- Slash Command
--------------------------------------
MonDKP.Commands = {
	["config"] = MonDKP.Toggle,
	["reset"] = MonDKP.ResetPosition,
	["bid"] = function(...)
		local item = strjoin(" ", ...)
		if ... == nil then
			MonDKP.ToggleBidWindow()
		else
			MonDKP:Print("Opening Bid Window for: ".. item)
			MonDKP:ToggleBidWindow(item)
		end
	end,
	["timer"] = function(time, ...)
		if time == nil then
			MonDKP:BroadcastTimer(1, "...")
		else
			local title = strjoin(" ", ...)
			MonDKP:BroadcastTimer(tonumber(time), title)
		end
	end,
	["test"] = function(time, ...)
		MonDKP:BroadcastBidTimer(20, "Don't worry about it")
	end,
	["help"] = function()
		print(" ");
		MonDKP:Print("List of slash commands:")
		MonDKP:Print("|cff00cc66/dkp|r - Launches DKP Window");
		MonDKP:Print("|cff00cc66/dkp ?|r - Shows Help Info");
		MonDKP:Print("|cff00cc66/dkp reset|r - Resets DKP Window Position/Size");
		MonDKP:Print("|cff00cc66/dkp timer|r - Creates Raid Timer (Raid Assists Only) (eg. /dkp timer 120 Pizza Break!");
		print(" ");
	end,
};

local function HandleSlashCommands(str)
	if (#str == 0) then
		MonDKP.Commands.config();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = MonDKP.Commands;
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg];
				end
			else
				MonDKP.Commands.help();
				return;
			end
		end
	end
end

function MonDKP_OnEvent(self, event, arg1, ...)
	if event == "ADDON_LOADED" then
		MonDKP:OnInitialize(event, arg1)
	elseif event == "CHAT_MSG_WHISPER" then
		MonDKP_CHAT_MSG_WHISPER(arg1, ...)
	end
end

function MonDKP:OnInitialize(event, name)		-- This is the FIRST function to run on load triggered by last 3 lines of this file
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

    MonDKP:Print("Welcome back, "..UnitName("player").."!");

    if(event == "ADDON_LOADED") then
    	core.loaded = 1;
		if (MonDKP_DKPTable == nil) then MonDKP_DKPTable = {} end;
		if (MonDKP_Loot == nil) then MonDKP_Loot = {} end;
		if (MonDKP_MinBids == nil) then MonDKP_MinBids = {} end;
	    if (MonDKP_DB == nil) then 
	    	MonDKP_DB = {
	    		DKPBonus = { OnTimeBonus = 15, BossKillBonus = 5, CompletionBonus = 10, NewBossKillBonus = 10, UnexcusedAbsence = -25, BidTimer = 30, HistoryLimit = 5000},
	    	} 
	    end;

	    ------------------------------------
	    --	Import SavedVariables
	    ------------------------------------
	    core.settings = MonDKP_DB
	    core.WorkingTable = MonDKP_DKPTable;

		-- Populates SavedVariable MonDKP_DKPTable with fake values for testing purposes if they don't already exist
		-- Delete this section and \WTF\AccountACCOUNT_NAME\SavedVariables\MonolithDKP.lua prior to actual use.
		--[[local player_names = {"Qulyolalima", "Cadhangwong", "Gilingerth", "Emondeatt", "Puthuguth", "Eminin", "Mormiannis", "Hemilionter", "Malcologan", "Alerahm", "Cricordinus", "Arommoth", "Barnamnon", "Eughtor", "Aldreavus", "Loylencel", "Barredgar", "Gerneheav", "Julivente", "Barlannel", "Audeacell", "Derneth", "Fredeond", "Gutrichas", "Wiliannel", "Siertlan", "Simitram", "Ronettius", "Livendley", "Mordannichas", "Tevistavus", "Jaspian"}
		local classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
		local items = { 
			"|cffa335ee|Hitem:169058::::::::120::::1:4778:|h[Salvaged Incendiary Tool]|h|r",
			"|cff0070dd|Hitem:166483::::::::120::::2:5126:1517:|h[Sentinel's Tomahawk]|h|r",
			"|cffa335ee|Hitem:168902::::::::120::::2:4798:1487:|h[Dream's End]|h|r",
			"|cffa335ee|Hitem:168901::::::::120::::2:4799:1502:|h[Royal Scaleguard's Battleaxe]|h|r",
			"|cffa335ee|Hitem:165601::::::::120::::2:4798:1507:|h[Storm-Toothed Kasuyu]|h|r"
		}
		local day = { "05/15", "05/20", "05/25", "05/30"}
		
		for i=1, 3000 do
			local d = day[math.random(1,4)];
			local m = i;
			if i<10 then
				m = "0"..i
			end
			tinsert(MonDKP_Loot, {
				player=player_names[math.random(1, #player_names)],
				loot=items[math.random(1, #items)],
				date="19/"..d.." "..date("%H:")..m..date(":%S"),
				zone="Molten Core",
				boss="Ragnaros",
				cost=math.random(35, 100)
			})
		end--]]
		--[[for i=1, #player_names do
			local p = player_names[i]
			if (MonDKP:Table_Search(MonDKP_DKPTable, p) == false) then 		--
				tinsert(MonDKP_DKPTable, {
					player=p,
					class=classes[math.random(1, #classes)],
					previous_dkp=math.random(1000),
					dkp=math.random(0, 1000)
				})
			end
		end--]]
		-- End testing DB

		MonDKP:Print("Loaded "..#MonDKP_DKPTable.." player records and "..#MonDKP_Loot.." loot history records.");
		core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();
		MonDKP:StartBidTimer(seconds, nil)
		MonDKP_Register_ShiftClickLootWindowHook()
		MonDKP:PurgeLootHistory()
	end
end

----------------------------------
-- Register Events and Initiallize AddOn
----------------------------------

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("CHAT_MSG_WHISPER");
events:SetScript("OnEvent", MonDKP_OnEvent); -- calls the above core:init function after addon_loaded event fires identifying the addon and SavedVariables are completely loaded
