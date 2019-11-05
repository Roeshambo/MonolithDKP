local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local menu = {}
local curfilterName = "No Filter";

local menuFrame = CreateFrame("Frame", "MonDKPDeleteLootMenuFrame", UIParent, "UIDropDownMenuTemplate")

function MonDKP:SortLootTable()             -- sorts the Loot History Table by date
  table.sort(MonDKP_Loot, function(a, b)
    return a["date"] > b["date"]
  end)
end

local function SortPlayerTable(arg)             -- sorts player list alphabetically
  table.sort(arg, function(a, b)
    return a < b
  end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #MonDKP_Loot do
		local playerSearch = MonDKP:Table_Search(PlayerList, MonDKP_Loot[i].player)
		if not playerSearch and not MonDKP_Loot[i].de then
			tinsert(PlayerList, MonDKP_Loot[i].player)
		end
	end
	SortPlayerTable(PlayerList)
	return PlayerList;
end

local function DeleteLootHistoryEntry(target)
	if core.CurrentlySyncing then
		StaticPopupDialogs["CURRENTLY_SYNC"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CURRENTLYSYNCING"],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CURRENTLY_SYNC")
		return;
	end
	local search = MonDKP:Table_Search(MonDKP_Loot, target["date"]);
	local search_player = MonDKP:Table_Search(MonDKP_DKPTable, target["player"]);
	local itemDate = target["date"];
	
	MonDKP:SeedVerify_Update()
	if core.UpToDate == false and core.IsOfficer == true then
		StaticPopupDialogs["CONFIRM_DELETE"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OUTDATEMODIFYWARN"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				MonDKP:LootHistory_Reset()
				MonDKP_DKPTable[search_player[1][1]].dkp = MonDKP_DKPTable[search_player[1][1]].dkp + target.cost 							-- refund previous looter
				MonDKP_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_DKPTable[search_player[1][1]].lifetime_spent - target.cost 	-- remove from lifetime_spent

				if search then
					table.remove(MonDKP_Loot, search[1][1])
				end

				MonDKP.Sync:SendData("MonDKPDeleteLoot", {seed = MonDKP_Loot.seed, search[1][1], itemDate})
				MonDKP:SortLootTable()
				DKPTable_Update()
				MonDKP:LootHistory_Update("No Filter");
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_DELETE")
	else
		MonDKP:LootHistory_Reset()

		if search_player then
			MonDKP_DKPTable[search_player[1][1]].dkp = MonDKP_DKPTable[search_player[1][1]].dkp + target.cost 							-- refund previous looter
			MonDKP_DKPTable[search_player[1][1]].lifetime_spent = MonDKP_DKPTable[search_player[1][1]].lifetime_spent + target.cost 	-- remove from lifetime_spent
		end

		if search then
			table.remove(MonDKP_Loot, search[1][1])
		end

		if core.UpToDate and core.IsOfficer then -- updates seeds only if table is currently up to date.
			MonDKP:UpdateSeeds()
		end
		MonDKP.Sync:SendData("MonDKPDeleteLoot", {seed = MonDKP_Loot.seed, search[1][1], itemDate})
		MonDKP:SortLootTable()
		DKPTable_Update()
		MonDKP:LootHistory_Update("No Filter");
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
	end
end

local function ReassignLootEntry(entry)
	if core.CurrentlySyncing then
		StaticPopupDialogs["CURRENTLY_SYNC"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CURRENTLYSYNCING"],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CURRENTLY_SYNC")
		return;
	end
	if entry.player ~= core.SelectedData[1].player then
		MonDKP:SeedVerify_Update()
		if core.UpToDate == false and core.IsOfficer == true then
			StaticPopupDialogs["CONFIRM_ADJUST2"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OUTDATEMODIFYWARN"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					local search_before = MonDKP:Table_Search(MonDKP_DKPTable, entry.player);
					local search_after = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[1].player)

					MonDKP:LootHistory_Reset()

					entry.player = core.SelectedData[1].player
					if search_before then
						MonDKP_DKPTable[search_before[1][1]].dkp = MonDKP_DKPTable[search_before[1][1]].dkp + entry.cost 							-- refund previous looter
						MonDKP_DKPTable[search_before[1][1]].lifetime_spent = MonDKP_DKPTable[search_before[1][1]].lifetime_spent - entry.cost 		-- remove from lifetime_spent
					end
					if search_after then
						MonDKP_DKPTable[search_after[1][1]].dkp = MonDKP_DKPTable[search_after[1][1]].dkp - entry.cost 								-- charge new looter
						MonDKP_DKPTable[search_after[1][1]].lifetime_spent = MonDKP_DKPTable[search_after[1][1]].lifetime_spent + entry.cost 		-- charge to lifetime_spent
					end

					MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)

					local search = MonDKP:Table_Search(MonDKP_Loot, entry.date)
					local temp_table = { seed = MonDKP_Loot.seed, { entry = MonDKP_Loot[search[1][1]].date, newplayer = core.SelectedData[1].player }}

					MonDKP:SortLootTable()
					MonDKP.Sync:SendData("MonDKPEditLoot", temp_table)
					MonDKP:LootHistory_Update("No Filter");
					DKPTable_Update()
					table.wipe(temp_table);
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_ADJUST2")
		else
			local search_before = MonDKP:Table_Search(MonDKP_DKPTable, entry.player);
			local search_after = MonDKP:Table_Search(MonDKP_DKPTable, core.SelectedData[1].player)

			MonDKP:LootHistory_Reset()

			entry.player = core.SelectedData[1].player
			if search_before then
				MonDKP_DKPTable[search_before[1][1]].dkp = MonDKP_DKPTable[search_before[1][1]].dkp + entry.cost 							-- refund previous looter
				MonDKP_DKPTable[search_before[1][1]].lifetime_spent = MonDKP_DKPTable[search_before[1][1]].lifetime_spent - entry.cost 		-- remove from lifetime_spent
			end
			if search_after then
				MonDKP_DKPTable[search_after[1][1]].dkp = MonDKP_DKPTable[search_after[1][1]].dkp - entry.cost 								-- charge new looter
				MonDKP_DKPTable[search_after[1][1]].lifetime_spent = MonDKP_DKPTable[search_after[1][1]].lifetime_spent + entry.cost 		-- charge to lifetime_spent
			end

			MonDKP:UpdateSeeds()
			MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)

			local search = MonDKP:Table_Search(MonDKP_Loot, entry.date)
			local temp_table = { seed = MonDKP_Loot.seed, { entry = MonDKP_Loot[search[1][1]].date, newplayer = core.SelectedData[1].player }}

			MonDKP:SortLootTable()
			MonDKP.Sync:SendData("MonDKPEditLoot", temp_table)
			MonDKP:LootHistory_Update("No Filter");
			DKPTable_Update()
			table.wipe(temp_table);
		end
	else
		StaticPopupDialogs["REASSIGN_LOOT_ENTRY_FAIL"] = {
			text = L["ALREADYASSIGNED"],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("REASSIGN_LOOT_ENTRY_FAIL")
	end
end

local function ReassignLootEntryConfirmation(entry)
	if core.CurrentlySyncing then
		StaticPopupDialogs["CURRENTLY_SYNC"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CURRENTLYSYNCING"],
			button1 = L["OK"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CURRENTLY_SYNC")
		return;
	end
	local cl
	local c = MonDKP:GetCColors(core.SelectedData[1].class);
	local search = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[entry]["player"])
	if search then
		cl = MonDKP:GetCColors(MonDKP_DKPTable[search[1][1]].class)
	else
		cl = { hex="444444" }
	end
	local deleteString = L["AREYOUSUREREASSIGN"].." "..MonDKP_Loot[entry]["loot"].." ("..MonDKP_Loot[entry]["cost"].." "..L["DKP"]..") "..L["TO"].." |cff"..c.hex..core.SelectedData[1].player.."|r?\n\n("..L["THISWILLREFUND"].." "..MonDKP_Loot[entry]["cost"].." "..L["DKP"].." "..L["TO"].." |cff"..cl.hex..MonDKP_Loot[entry]["player"].."|r "..L["ANDCHARGEITTO"].." |cff"..c.hex..core.SelectedData[1].player.."|r)";

	StaticPopupDialogs["REASSIGN_LOOT_ENTRY"] = {
	  text = deleteString,
	  button1 = "Yes",
	  button2 = "No",
	  OnAccept = function()
	    ReassignLootEntry(MonDKP_Loot[entry])
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,
	}
	StaticPopup_Show ("REASSIGN_LOOT_ENTRY")
end

local function MonDKPDeleteMenu(item)
	local search = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[item]["player"])
	local c, deleteString;
	if search then
		c = MonDKP:GetCColors(MonDKP_DKPTable[search[1][1]].class)
		deleteString = L["CONFIRMDELETEENTRY1"]..": |cff"..c.hex..MonDKP_Loot[item]["player"].."|r "..L["WON"].." "..MonDKP_Loot[item]["loot"].." "..L["FOR"].." "..MonDKP_Loot[item]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |cff"..c.hex..MonDKP_Loot[item].player.."|r "..MonDKP_Loot[item]["cost"].." "..L["DKP"]..")";
	else
		deleteString = L["CONFIRMDELETEENTRY1"]..": |cff444444"..MonDKP_Loot[item]["player"].."|r "..L["WON"].." "..MonDKP_Loot[item]["loot"].." "..L["FOR"].." "..MonDKP_Loot[item]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |cff444444"..MonDKP_Loot[item].player.."|r "..MonDKP_Loot[item]["cost"].." "..L["DKP"]..")";
	end

	StaticPopupDialogs["DELETE_LOOT_ENTRY"] = {
	  text = deleteString,
	  button1 = L["YES"],
	  button2 = L["NO"],
	  OnAccept = function()
	    DeleteLootHistoryEntry(MonDKP_Loot[item])
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,
	}
	StaticPopup_Show ("DELETE_LOOT_ENTRY")
end

local function RightClickLootMenu(self, item)  -- called by right click function on ~201 row:SetScript
  menu = {
      { text = MonDKP_Loot[item]["loot"].." "..L["FOR"].." "..MonDKP_Loot[item]["cost"].." "..L["DKP"], isTitle = true},
      { text = "Delete Entry", func = function()
        MonDKPDeleteMenu(item)
      end },
      { text = L["REASSIGNSELECTED"], func = function()
      	if #core.SelectedData == 1 then
      		ReassignLootEntryConfirmation(item)
      	elseif #core.SelectedData > 1 then
      		StaticPopupDialogs["TOO_MANY_SELECTED_LOOT"] = {
				text = L["TOOMANYPLAYERSSELECT"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("TOO_MANY_SELECTED_LOOT")
      	else
			StaticPopupDialogs["PLAYER_NOT_SELECTED_LOOT"] = {
				text = L["NOPLAYERSSELECTED"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("PLAYER_NOT_SELECTED_LOOT")
      	end
      end }
  }
  EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
end

function CreateSortBox()
	local PlayerList = GetSortOptions();

	-- Create the dropdown, and configure its appearance
	if not sortDropdown then
		sortDropdown = CreateFrame("FRAME", "MonDKPConfigFilterNameDropDown", MonDKP.ConfigTab5, "MonolithDKPUIDropDownMenuTemplate")
		sortDropdown:SetPoint("TOPRIGHT", MonDKP.ConfigTab5, "TOPRIGHT", -13, -11)
	end
	UIDropDownMenu_SetWidth(sortDropdown, 150)
	UIDropDownMenu_SetText(sortDropdown, curfilterName or "Filter Name")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(sortDropdown, function(self, level, menuList)
		if not filterName then
			filterName = UIDropDownMenu_CreateInfo()
		end
		filterName.func = self.FilterSetValue
		filterName.fontObject = "MonDKPSmallCenter"
		filterName.text, filterName.arg1, filterName.checked, filterName.isNotRadio = "No Filter", "No Filter", "No Filter" == curfilterName, true
		UIDropDownMenu_AddButton(filterName)
		for i=1, #PlayerList do

			local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, PlayerList[i])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i], "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		end
	end);

  -- Dropdown Menu Function
  function sortDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(sortDropdown, arg2)
    MonDKP:LootHistory_Update(newValue)
    CloseDropDownMenus()
  end
end


local tooltip = CreateFrame('GameTooltip', "nil", UIParent, 'GameTooltipTemplate')
local CurrentPosition = 0
local CurrentLimit = 50;
local lineHeight = -65;
local ButtonText = 50;
local curDate = 1;
local curZone;
local curBoss;

function MonDKP:LootHistory_Reset()
	CurrentPosition = 0
	CurrentLimit = 50;
	lineHeight = -65;
	ButtonText = 50;
	curDate = 1;
	curZone = nil;
	curBoss = nil;

	for i=1, #MonDKP_Loot+1 do
		if MonDKP.ConfigTab5.looter[i] then
			MonDKP.ConfigTab5.looter[i]:SetText("")
			MonDKP.ConfigTab5.lootFrame[i]:Hide()
		end
	end
end

function MonDKP:LootHistory_Update(filter)				-- if "filter" is included in call, runs set assigned for when a filter is selected in dropdown.
	if not MonDKP.UIConfig:IsShown() then 			-- prevents history update from firing if the DKP window is not opened (eliminate lag). Update run when opened
		return;
	end

	local thedate;
	local linesToUse = 1;
	MonDKP:SortLootTable()

	if filter and filter == "No Filter" then
		curfilterName = "No Filter"
		CreateSortBox()
	end
	
	if filter then
		MonDKP:LootHistory_Reset()
	end

	MonDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);
	if core.IsOfficer == true then
		MonDKP.ConfigTab5.inst:SetText(MonDKP.ConfigTab5.inst:GetText().."\n"..L["LOOTHISTINST2"])
		MonDKP.ConfigTab6.inst:SetText(L["LOOTHISTINST3"])
	end

	if CurrentLimit > #MonDKP_Loot then CurrentLimit = #MonDKP_Loot end;

	if filter and filter ~= "No Filter" then
		CurrentLimit = #MonDKP_Loot
	end

	for i=CurrentPosition+1, CurrentLimit do
	  	if (filter and filter == MonDKP_Loot[i].player and filter ~= "No Filter") or (filter and filter == MonDKP_Loot[i].loot and filter ~= "No Filter") then
		    local itemToLink = MonDKP_Loot[i]["loot"]
		    thedate = MonDKP:FormatTime(MonDKP_Loot[i]["date"])

		    if strsub(thedate, 1, 8) ~= curDate then
		      linesToUse = 3
		    elseif strsub(thedate, 1, 8) == curDate and MonDKP_Loot[i]["boss"] ~= curBoss and MonDKP_Loot[i]["zone"] ~= curZone then
		      linesToUse = 3
		    elseif MonDKP_Loot[i]["zone"] ~= curZone or MonDKP_Loot[i]["boss"] ~= curBoss then
		      linesToUse = 2
		    else
		      linesToUse = 1
		    end

		    if (type(MonDKP.ConfigTab5.lootFrame[i]) ~= "table") then
		    	MonDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "MonDKPLootHistoryFrame"..i, MonDKP.ConfigTab5);	-- creates line if it doesn't exist yet
		    end
		    -- determine line height 
	    	if linesToUse == 1 then
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight-2);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 28)
				lineHeight = lineHeight-24;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 38)
				lineHeight = lineHeight-36;
			end;

			MonDKP.ConfigTab5.looter[i] = MonDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab5.looter[i]:SetFontObject("MonDKPSmallLeft");
			MonDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);

		    -- print string to history
		    local date1, date2, date3 = strsplit("/", strsub(thedate, 1, 8))

		    local feedString;

		    local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[i]["player"])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if strsub(thedate, 1, 8) ~= curDate or MonDKP_Loot[i]["zone"] ~= curZone then
				feedString = date2.."/"..date3.."/"..date1.." - "..MonDKP_Loot[i]["zone"].."\n  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
				feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
				        
				MonDKP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(thedate, 1, 8), " ")
				curZone = MonDKP_Loot[i]["zone"];
				curBoss = MonDKP_Loot[i]["boss"];
		    elseif MonDKP_Loot[i]["boss"] ~= curBoss then
		    	feedString = "  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(thedate, 1, 8), " ")
		    	curBoss = MonDKP_Loot[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = MonDKP_Loot[i]["zone"];
		    end

		    -- Set script for tooltip/linking
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function()
		    	local history = 0;
		    	tooltip:SetOwner(MonDKP.ConfigTab5.looter[i], "ANCHOR_RIGHT", -50, 0)
		    	tooltip:SetHyperlink(itemToLink)
		    	if MonDKP_Loot[i].bids or MonDKP_Loot[i].dkp or MonDKP_Loot[i].rolls then  		-- displays bids/rolls/dkp values if "Log Bids" checked in modes
		    		local path;

		    		tooltip:AddLine(" ")
		    		if MonDKP_Loot[i].bids then
		    			tooltip:AddLine(L["BIDS"]..":")
		    			table.sort(MonDKP_Loot[i].bids, function(a, b)
							return a["bid"] > b["bid"]
						end)
						path = MonDKP_Loot[i].bids
		    		elseif MonDKP_Loot[i].dkp then
		    			tooltip:AddLine(L["DKPVALUES"]..":")
		    			table.sort(MonDKP_Loot[i].dkp, function(a, b)
							return a["dkp"] > b["dkp"]
						end)
						path = MonDKP_Loot[i].dkp
		    		elseif MonDKP_Loot[i].rolls then
		    			tooltip:AddLine(L["ROLLS"]..":")
		    			table.sort(MonDKP_Loot[i].rolls, function(a, b)
							return a["roll"] > b["roll"]
						end)
						path = MonDKP_Loot[i].rolls
		    		end
		    		for i=1, #path do
		    			local col;
		    			local s = MonDKP:Table_Search(MonDKP_DKPTable, path[i].player)
		    			local path2 = path[i].bid or path[i].dkp or path[i].roll

		    			if s then
		    				col = MonDKP:GetCColors(MonDKP_DKPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			tooltip:AddLine("|cff"..col.hex..path[i].player.."|r: "..path2)
		    		end
		    	end
		    	for j=1, #MonDKP_Loot do
		    		if MonDKP_Loot[j]["loot"] == itemToLink and MonDKP_Loot[i].date ~= MonDKP_Loot[j].date then
		    			local col;
		    			local s = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[j].player)
		    			if s then
		    				col = MonDKP:GetCColors(MonDKP_DKPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			if history == 0 then
		    				tooltip:AddLine(" ");
		    				tooltip:AddLine(L["ALSOWONBY"]..":");
		    				history = 1;
		    			end
		    			tooltip:AddDoubleLine("|cff"..col.hex..MonDKP_Loot[j].player.."|r |cffffffff("..date("%m/%d/%y", MonDKP_Loot[j].date)..")|r", "|cffff0000"..MonDKP_Loot[j].cost.." DKP|r", 1.0, 0, 0)
		    		end
		    	end
		    	tooltip:Show();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" then
	   				if core.IsOfficer == true then
	   					RightClickLootMenu(self, i)
	   				end
	   			elseif button == "LeftButton" then
	   				if IsShiftKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
			    		ChatFrame1EditBox:SetFocus();
			    	elseif IsAltKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..MonDKP_Loot[i]["player"].." "..L["WON"].." "..select(2,GetItemInfo(itemToLink)).." "..L["OFF"].." "..MonDKP_Loot[i]["boss"].." "..L["IN"].." "..MonDKP_Loot[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") "..L["FOR"].." "..MonDKP_Loot[i]["cost"].." "..L["DKP"])
			    		ChatFrame1EditBox:SetFocus();		    		
			    	end
	   			end
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:Show();
		    CurrentPosition = CurrentPosition + 1;
		elseif not filter or filter == "No Filter" then
			local itemToLink = MonDKP_Loot[i]["loot"]
			thedate = MonDKP:FormatTime(MonDKP_Loot[i]["date"])

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate then
		      linesToUse = 3
		    elseif strtrim(strsub(thedate, 1, 8), " ") == curDate and MonDKP_Loot[i]["boss"] ~= curBoss and MonDKP_Loot[i]["zone"] ~= curZone then
		      linesToUse = 3
		    elseif MonDKP_Loot[i]["zone"] ~= curZone or MonDKP_Loot[i]["boss"] ~= curBoss then
		      linesToUse = 2
		    else
		      linesToUse = 1
		    end

		    if (type(MonDKP.ConfigTab5.lootFrame[i]) ~= "table") then
		    	MonDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "MonDKPLootHistoryFrame"..i, MonDKP.ConfigTab5);	-- creates line if it doesn't exist yet
		    end
		    -- determine line height 
	    	if linesToUse == 1 then
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight-2);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 28)
				lineHeight = lineHeight-24;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(200, 38)
				lineHeight = lineHeight-36;
			end;

			MonDKP.ConfigTab5.looter[i] = MonDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab5.looter[i]:SetFontObject("MonDKPSmallLeft");
			MonDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);

		    -- print string to history
		    local date1, date2, date3 = strsplit("/", strtrim(strsub(thedate, 1, 8), " "))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[i]["player"])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate or MonDKP_Loot[i]["zone"] ~= curZone then
				feedString = date2.."/"..date3.."/"..date1.." - "..MonDKP_Loot[i]["zone"].."\n  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
				feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
				        
				MonDKP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(thedate, 1, 8), " ")
				curZone = MonDKP_Loot[i]["zone"];
				curBoss = MonDKP_Loot[i]["boss"];
		    elseif MonDKP_Loot[i]["boss"] ~= curBoss then
		    	feedString = "  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
		    	 
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(thedate, 1, 8), " ")
		    	curBoss = MonDKP_Loot[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." "..L["DKP"]..")|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = MonDKP_Loot[i]["zone"];
		    end

		    -- Set script for tooltip/linking
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function()
		    	local history = 0;
		    	tooltip:SetOwner(MonDKP.ConfigTab5.looter[i], "ANCHOR_RIGHT", -50, 0)
		    	tooltip:SetHyperlink(itemToLink)
		    	if MonDKP_Loot[i].bids or MonDKP_Loot[i].dkp or MonDKP_Loot[i].rolls then  		-- displays bids/rolls/dkp values if "Log Bids" checked in modes
		    		local path;

		    		tooltip:AddLine(" ")
		    		if MonDKP_Loot[i].bids then
		    			tooltip:AddLine(L["BIDS"]..":")
		    			table.sort(MonDKP_Loot[i].bids, function(a, b)
							return a["bid"] > b["bid"]
						end)
						path = MonDKP_Loot[i].bids
		    		elseif MonDKP_Loot[i].dkp then
		    			tooltip:AddLine(L["DKPVALUES"]..":")
		    			table.sort(MonDKP_Loot[i].dkp, function(a, b)
							return a["dkp"] > b["dkp"]
						end)
						path = MonDKP_Loot[i].dkp
		    		elseif MonDKP_Loot[i].rolls then
		    			tooltip:AddLine(L["ROLLS"]..":")
		    			table.sort(MonDKP_Loot[i].rolls, function(a, b)
							return a["roll"] > b["roll"]
						end)
						path = MonDKP_Loot[i].rolls
		    		end
		    		for i=1, #path do
		    			local col;
		    			local s = MonDKP:Table_Search(MonDKP_DKPTable, path[i].player)
		    			local path2 = path[i].bid or path[i].dkp or path[i].roll

		    			if s then
		    				col = MonDKP:GetCColors(MonDKP_DKPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			tooltip:AddLine("|cff"..col.hex..path[i].player.."|r: "..path2)
		    		end
		    	end
		    	for j=1, #MonDKP_Loot do
		    		if MonDKP_Loot[j]["loot"] == itemToLink and MonDKP_Loot[i].date ~= MonDKP_Loot[j].date then
		    			local col;
		    			local s = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[j].player)
		    			if s then
		    				col = MonDKP:GetCColors(MonDKP_DKPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			if history == 0 then
		    				tooltip:AddLine(" ");
		    				tooltip:AddLine(L["ALSOWONBY"]..":");
		    				history = 1;
		    			end
		    			tooltip:AddDoubleLine("|cff"..col.hex..MonDKP_Loot[j].player.."|r |cffffffff("..date("%m/%d/%y", MonDKP_Loot[j].date)..")|r", "|cffff0000"..MonDKP_Loot[j].cost.." "..L["DKP"].."|r", 1.0, 0, 0)
		    		end
		    	end
		    	tooltip:Show();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function(self, button)
	   			if button == "RightButton" then
	   				if core.IsOfficer == true then
	   					RightClickLootMenu(self, i)
	   				end
	   			elseif button == "LeftButton" then
	   				if IsShiftKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
			    		ChatFrame1EditBox:SetFocus();
			    	elseif IsAltKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..MonDKP_Loot[i]["player"].." "..L["WON"].." "..select(2,GetItemInfo(itemToLink)).." "..L["OFF"].." "..MonDKP_Loot[i]["boss"].." "..L["IN"].." "..MonDKP_Loot[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") "..L["FOR"].." "..MonDKP_Loot[i]["cost"].." "..L["DKP"])
			    		ChatFrame1EditBox:SetFocus();
			    	end
	   			end		    	
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide();
		    end)
		    CurrentPosition = CurrentPosition + 1;
		    MonDKP.ConfigTab5.lootFrame[i]:Show();
		end
 	end
 	if CurrentLimit < #MonDKP_Loot and not MonDKP.ConfigTab5.LoadHistory then
	 	-- Load More History Button
		MonDKP.ConfigTab5.LoadHistory = self:CreateButton("TOP", MonDKP.ConfigTab5.lootFrame[CurrentLimit], "BOTTOM", 0, 0, L["LOAD50MORE"]);
		MonDKP.ConfigTab5.LoadHistory:SetSize(110,25)
		MonDKP.ConfigTab5.LoadHistory:SetScript("OnClick", function()
			CurrentLimit = CurrentLimit + 50
			if CurrentLimit > #MonDKP_Loot then
				CurrentLimit = #MonDKP_Loot
			end
			MonDKP:LootHistory_Update()
		end)
	end
	if MonDKP.ConfigTab5.LoadHistory then
		MonDKP.ConfigTab5.LoadHistory:ClearAllPoints();
		MonDKP.ConfigTab5.LoadHistory:SetPoint("TOP", MonDKP.ConfigTab5.lootFrame[CurrentLimit], "BOTTOM", -10, -15)
		if (#MonDKP_Loot - CurrentPosition) < 50 then
			ButtonText = #MonDKP_Loot - CurrentPosition;
		end
		MonDKP.ConfigTab5.LoadHistory:SetText(L["LOAD"].." "..ButtonText.." "..L["MORE"].."...")
		if CurrentLimit == #MonDKP_Loot then
			MonDKP.ConfigTab5.LoadHistory:Hide();
		else
			MonDKP.ConfigTab5.LoadHistory:Show();
		end
	end
end