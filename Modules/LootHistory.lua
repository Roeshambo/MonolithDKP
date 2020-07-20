local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local menu = {}
local curDropDownMenuFilterCategory = L["NOFILTER"];
local curfilterValue = nil;

local menuFrame = CreateFrame("Frame", "CommDKPDeleteLootMenuFrame", UIParent, "UIDropDownMenuTemplate")



function CommDKP:SortLootTable()             -- sorts the Loot History Table by date
  table.sort(CommDKP:GetTable(CommDKP_Loot, true), function(a, b)
    return a["date"] > b["date"]
  end)
end

local function SortPlayerTable(arg)             -- sorts player list alphabetically
  table.sort(arg, function(a, b)
    return a < b
  end)
end

-- |cffa335ee|Hitem:19138::::::::60:::::::|h[Band of Sulfuras]|h|r
local function SortItemTable(arg)
	table.sort(arg, function(a,b)
		-- sort table by itemName of each itemLink
		return strsub(tostring(a), strfind(tostring(a), "%[") + 1, strfind(tostring(a), "%]") - 1) < strsub(tostring(b), strfind(tostring(b), "%[") + 1, strfind(tostring(b), "%]") - 1) 
	end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
		local playerSearch = CommDKP:Table_Search(PlayerList, CommDKP:GetTable(CommDKP_Loot, true)[i].player)
		if not playerSearch and not CommDKP:GetTable(CommDKP_Loot, true)[i].de then
			tinsert(PlayerList, CommDKP:GetTable(CommDKP_Loot, true)[i].player)
		end
	end
	SortPlayerTable(PlayerList)
	return PlayerList;
end

local function GetItemHistoryList() 
	_ItemList = {}
	-- we look at saved variable and find every unique item looted?
	for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
		
		--Validate that the value is ACTUALLY an item link.
		local itemString = string.match(CommDKP:GetTable(CommDKP_Loot, true)[i].loot, "item[%-?%d:]+")

		if itemString then

			local itemSearch = CommDKP:Table_Search(_ItemList, CommDKP:GetTable(CommDKP_Loot, true)[i].loot)

			if not itemSearch then
				tinsert(_ItemList, CommDKP:GetTable(CommDKP_Loot, true)[i].loot)
			end
		end
	end
	SortItemTable(_ItemList)
	return _ItemList;
end

local function DeleteLootHistoryEntry(index)
	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), index, "index");
	local search_player = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].player);
	local curTime = time()
	local curOfficer = UnitName("player")
	local newIndex = curOfficer.."-"..curTime

	
	CommDKP:StatusVerify_Update()
	CommDKP:LootHistory_Reset()

	local tempTable = {
		player = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].player,
		loot =  CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].loot,
		zone = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].zone,
		date = time(),
		boss = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].boss,
		cost = -CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].cost,
		index = newIndex,
		deletes = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].index
	}

	if search_player then
		CommDKP:GetTable(CommDKP_DKPTable, true)[search_player[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true)[search_player[1][1]].dkp + tempTable.cost 							-- refund previous looter
		CommDKP:GetTable(CommDKP_DKPTable, true)[search_player[1][1]].lifetime_spent = CommDKP:GetTable(CommDKP_DKPTable, true)[search_player[1][1]].lifetime_spent + tempTable.cost 		-- remove from lifetime_spent
	end

	CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].deletedby = newIndex

	table.insert(CommDKP:GetTable(CommDKP_Loot, true), 1, tempTable)
	CommDKP.Sync:SendData("CommDKPDelLoot", tempTable)
	CommDKP:SortLootTable()
	CommDKP:DKPTable_Update()
	CommDKP:LootHistory_Update(L["NOFILTER"]);
end

local function CommDKPDeleteMenu(index)
	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), index, "index")
	local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["player"])
	local c, deleteString;
	if search2 then
		c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[search2[1][1]].class)
		deleteString = L["CONFIRMDELETEENTRY1"]..": |c"..c.hex..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["player"].."|r "..L["WON"].." "..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["loot"].." "..L["FOR"].." "..-CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |c"..c.hex..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].player.."|r "..-CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["cost"].." "..L["DKP"]..")";
	else
		deleteString = L["CONFIRMDELETEENTRY1"]..": |cff444444"..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["player"].."|r "..L["WON"].." "..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["loot"].." "..L["FOR"].." "..-CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |cff444444"..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].player.."|r "..-DKP_Loot[search[1][1]]["cost"].." "..L["DKP"]..")";
	end

	StaticPopupDialogs["DELETE_LOOT_ENTRY"] = {
	  text = deleteString,
	  button1 = L["YES"],
	  button2 = L["NO"],
	  OnAccept = function()
	    DeleteLootHistoryEntry(index)
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,
	}
	StaticPopup_Show ("DELETE_LOOT_ENTRY")
end

local function RightClickLootMenu(self, index)  -- called by right click function on ~201 row:SetScript
	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), index, "index")
	menu = {
		{ text = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["loot"].." "..L["FOR"].." "..CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]["cost"].." "..L["DKP"], isTitle = true},
		{ text = "Delete Entry", func = function()
			CommDKPDeleteMenu(index)
		end },
		{ text = L["REASSIGNSELECTED"], func = function()
			local path = CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]]

			if #core.SelectedData == 1 then
				CommDKP:AwardConfirm(core.SelectedData[1].player, -path.cost, path.boss, path.zone, path.loot, index)
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
				CommDKP:AwardConfirm(path.player, -path.cost, path.boss, path.zone, path.loot, index)
			end
		end }
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
end

function CommDKP:ClearLootHistoryFrames() 
	for i=1, #CommDKP.ConfigTab5.looter do
		CommDKP.ConfigTab5.looter[i]:SetText("")
	end

	for i=1, #CommDKP.ConfigTab5.lootFrame do
		CommDKP.ConfigTab5.lootFrame[i]:Hide()
	end
end


function CommDKP:CreateSortBox()
	local PlayerList = GetSortOptions();
	local ItemList = GetItemHistoryList();
	curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not sortDropdown then
		sortDropdown = CreateFrame("FRAME", "CommDKPConfigFilterNameDropDown", CommDKP.ConfigTab5, "CommunityDKPUIDropDownMenuTemplate")
	end

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(sortDropdown, function(self, level, menuList)
		local dropDownMenuItem = UIDropDownMenu_CreateInfo()
		local displayLimit = 20 -- control how many items will be created in Levels 2 and 3

		if (level or 1) == 1 then
			
			-- made it a bit more clear to read for now
			-- add no filter button
			dropDownMenuItem.func = self.FilterSetValue
			dropDownMenuItem.text = L["NOFILTER"]
			dropDownMenuItem.value = L["NOFILTER"]
			dropDownMenuItem.arg1 = L["NOFILTER"]
			dropDownMenuItem.arg2 = L["NOFILTER"]
			dropDownMenuItem.checked = (L["NOFILTER"] == curDropDownMenuFilterCategory)
			dropDownMenuItem.isNotRadio = true
			UIDropDownMenu_AddButton(dropDownMenuItem, level)

			-- add deleted entries button
			dropDownMenuItem.text = L["DELETEDENTRY"] 
			dropDownMenuItem.value = L["DELETEDENTRY"] 
			dropDownMenuItem.arg1 = L["DELETEDENTRY"] 
			dropDownMenuItem.arg2 = L["DELETEDENTRY"]
			dropDownMenuItem.checked = L["DELETEDENTRY"] == curDropDownMenuFilterCategory
			dropDownMenuItem.hasArrow = false -- should probably check if players table holds any values
			dropDownMenuItem.isNotRadio = true
			UIDropDownMenu_AddButton(dropDownMenuItem, level)

			-- add separator
			--wipe(dropDownMenuItem)
			dropDownMenuItem.text = ""
			dropDownMenuItem.disabled = 1
			dropDownMenuItem.isNotRadio = true
			UIDropDownMenu_AddButton(dropDownMenuItem, level)
			dropDownMenuItem.disabled = nil
		
			-- add players section
			dropDownMenuItem.text =  L["PLAYERS"] 
			dropDownMenuItem.value =  L["PLAYERS"] 
			dropDownMenuItem.arg1 = L["PLAYERS"] 
			dropDownMenuItem.arg2 = L["PLAYERS"]
			dropDownMenuItem.value = L["PLAYERS"] -- for submenu handling in level 2
			dropDownMenuItem.checked = L["PLAYERS"] == curDropDownMenuFilterCategory
			dropDownMenuItem.isNotRadio = true
			dropDownMenuItem.hasArrow = true -- should probably check if items table holds any values
			UIDropDownMenu_AddButton(dropDownMenuItem, level)

			-- add items section
			dropDownMenuItem.text =  L["ITEMS"] 
			dropDownMenuItem.value =  L["ITEMS"] 
			dropDownMenuItem.arg1 = L["ITEMS"] 
			dropDownMenuItem.arg2 = L["ITEMS"]
			dropDownMenuItem.value = L["ITEMS"] -- for submenu handling in level 2
			dropDownMenuItem.checked = L["ITEMS"] == curDropDownMenuFilterCategory
			dropDownMenuItem.isNotRadio = true
			UIDropDownMenu_AddButton(dropDownMenuItem, level)

		-- level 2 to handle players and items
		elseif (level or 2) == 2 then

			if UIDROPDOWNMENU_MENU_VALUE == L["PLAYERS"] then

				for i=1, ceil(#PlayerList/displayLimit) do 
					local max = i*displayLimit;
					if max > #PlayerList then max = #PlayerList end
					dropDownMenuItem.text = strsub(PlayerList[((i*displayLimit)-(displayLimit-1))], 1, 1).."-"..strsub(PlayerList[max], 1, 1) 
					dropDownMenuItem.checked = curSelected >= (i*displayLimit)-(displayLimit-1) and curSelected <= i*displayLimit
					dropDownMenuItem.menuList = i -- to know which subLevel of players we are on
					dropDownMenuItem.value = L["PLAYERS"] -- for submenu handling in level 3
					dropDownMenuItem.hasArrow = true
					dropDownMenuItem.isNotRadio = true
					dropDownMenuItem.checked = (curDropDownMenuFilterCategory == L["PLAYERS"] and (curSelected >= (1+(i-1)*displayLimit) and curSelected <= 1+(i-1)*displayLimit+(displayLimit-1)))
					UIDropDownMenu_AddButton(dropDownMenuItem, level)
				end

			elseif UIDROPDOWNMENU_MENU_VALUE == L["ITEMS"] then

				for i=1, ceil(#ItemList/displayLimit) do 
					local max = i*displayLimit;
					if max > #ItemList then max = #ItemList end
					dropDownMenuItem.text = ItemList[((i*displayLimit)-(displayLimit-1))]
					dropDownMenuItem.text = strsub(ItemList[((i*displayLimit)-(displayLimit-1))], strfind(ItemList[((i*displayLimit)-(displayLimit-1))], "%[", 1) + 1, strfind(ItemList[((i*displayLimit)-(displayLimit-1))], "%[", 1) + 1).."-"..strsub(ItemList[max], strfind(ItemList[max], "%[", 1) + 1, strfind(ItemList[max], "%[", 1) + 1)
					dropDownMenuItem.menuList = i -- to know which subLevel of items we are on
					dropDownMenuItem.value = L["ITEMS"] -- for submenu handling in level 3
					dropDownMenuItem.hasArrow = true
					dropDownMenuItem.isNotRadio = true
					dropDownMenuItem.checked = (curDropDownMenuFilterCategory == L["ITEMS"] and (curSelected >= (1+(i-1)*displayLimit) and curSelected <= 1+(i-1)*displayLimit+(displayLimit-1)))
					UIDropDownMenu_AddButton(dropDownMenuItem, level)
				end

			end
		else -- level 3

			dropDownMenuItem.func = self.FilterSetValue
			if UIDROPDOWNMENU_MENU_VALUE == L["PLAYERS"] then

				--for i=playersRange[menuList], playersRange[menuList]+(displayLimit-1) do
				-- depending on menuList value from higher level this should give
				-- for i.e menuList = 3
				-- for i = 1+(3-1)*20 = 41 ,  1+(3-1)*20+(20-1) = 60 do
				for i=1+(menuList-1)*displayLimit, 1+(menuList-1)*displayLimit+(displayLimit-1) do
					if PlayerList[i] then
						
						local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), PlayerList[i])
						local c;

						if classSearch then
							-- CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)

							c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)
						else
							c = { hex="ff444444" }
						end
						dropDownMenuItem.text = "|c"..c.hex..PlayerList[i].."|r" 
						dropDownMenuItem.value = "|c"..c.hex..PlayerList[i].."|r" 
						dropDownMenuItem.arg1 = PlayerList[i]
						dropDownMenuItem.arg2 = L["PLAYERS"]
						dropDownMenuItem.isNotRadio = true
						dropDownMenuItem.checked =  PlayerList[i] == curfilterValue
						dropDownMenuItem.menuList = i
						UIDropDownMenu_AddButton(dropDownMenuItem, level)
					end
				end
				
			elseif UIDROPDOWNMENU_MENU_VALUE == L["ITEMS"] then

				for  i=1+(menuList-1)*displayLimit, 1+(menuList-1)*displayLimit+(displayLimit-1) do
					if ItemList[i] then
						dropDownMenuItem.text = ItemList[i]
						dropDownMenuItem.value = ItemList[i]
						dropDownMenuItem.arg1 = ItemList[i]
						dropDownMenuItem.arg2 = L["ITEMS"]
						dropDownMenuItem.isNotRadio = true
						dropDownMenuItem.checked =  ItemList[i] == curfilterValue
						dropDownMenuItem.menuList = i
						UIDropDownMenu_AddButton(dropDownMenuItem, level)
					end
				end
			end
		end
	end)

	sortDropdown:SetPoint("TOPRIGHT", CommDKP.ConfigTab5, "TOPRIGHT", -13, -11)

	UIDropDownMenu_SetWidth(sortDropdown, 150)
	UIDropDownMenu_SetText(sortDropdown, curDropDownMenuFilterCategory or "Filter Name")

  -- Dropdown Menu Function
  function sortDropdown:FilterSetValue(newValue, arg2)
 
	-- text  - display string
	-- value - formatted string for player class color
	-- arg1  - actual value which we filter by
	-- arg2  - decode which filtering is going on
	 	-- L["NOFILTER"]
		-- L["DELETEDENTRY"] 
		-- L["PLAYERS"]
		-- L["ITEMS"]

	if curDropDownMenuFilterCategory ~= arg2 then 
		curDropDownMenuFilterCategory = arg2 
		if curfilterValue == nil or curfilterValue ~= newValue then
			curfilterValue = newValue
		end
	elseif curDropDownMenuFilterCategory == arg2 then
		if curfilterValue == nil or curfilterValue ~= newValue then
			curfilterValue = newValue
		elseif curfilterValue == newValue then
			curDropDownMenuFilterCategory = nil
			curfilterValue = nil
		end
	end
	
	if curDropDownMenuFilterCategory == nil and curfilterValue == nil then
		curSelected = 0
		UIDropDownMenu_SetText(sortDropdown, L["NOFILTER"])
	elseif arg2 == L["NOFILTER"] or arg2 == L["DELETEDENTRY"] then
		curSelected = 0
		UIDropDownMenu_SetText(sortDropdown, newValue)
	elseif arg2 == L["ITEMS"] then
		curSelected = self.menuList
		UIDropDownMenu_SetText(sortDropdown, newValue)
	elseif arg2 == L["PLAYERS"] then
		curSelected = self.menuList
		UIDropDownMenu_SetText(sortDropdown, self.value)
	end

	if curDropDownMenuFilterCategory == nil and curfilterValue == nil then
		CommDKP:LootHistory_Update(L["NOFILTER"])
	else
		CommDKP:LootHistory_Update(newValue)
	end
    
    CloseDropDownMenus()
  end

end

local tooltip = CreateFrame('GameTooltip', "nil", UIParent, 'GameTooltipTemplate')
local CurrentPosition = 0
local CurrentLimit = 25;
local lineHeight = -65;
local ButtonText = 25;
local curDate = 1;
local curZone;
local curBoss;

function CommDKP:LootHistory_Reset()
	CurrentPosition = 0
	CurrentLimit = 25;
	lineHeight = -65;
	ButtonText = 25;
	curDate = 1;
	curZone = nil;
	curBoss = nil;

	CommDKP:ClearLootHistoryFrames();

	if CommDKP.ConfigTab5.LoadHistory then
		CommDKP.ConfigTab5.LoadHistory:Show();
	end

	if CommDKP.DKPTable then
		for i=1, #CommDKP:GetTable(CommDKP_Loot, true)+1 do
			if CommDKP.ConfigTab5.looter[i] then
				CommDKP.ConfigTab5.looter[i]:SetText("")
				CommDKP.ConfigTab5.lootFrame[i]:Hide()
			end
		end
	end
end

local LootHistTimer = LootHistTimer or CreateFrame("StatusBar", nil, UIParent)
function CommDKP:LootHistory_Update(filter)				-- if "filter" is included in call, runs set assigned for when a filter is selected in dropdown.
	if not CommDKP.UIConfig:IsShown() then 
		return 
	end
	local thedate;
	local linesToUse = 1;
	local LootTable = {}
	CommDKP:SortLootTable()
	if LootHistTimer then LootHistTimer:SetScript("OnUpdate", nil) end

	if filter and filter == L["NOFILTER"] then
		curDropDownMenuFilterCategory = L["NOFILTER"]
		CommDKP:CreateSortBox()
	end
	if filter then
		CommDKP:LootHistory_Reset()
	end
	if filter and filter ~= L["NOFILTER"] and filter ~= L["DELETEDENTRY"] then
		-- items or players
		for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
			if curDropDownMenuFilterCategory == L["PLAYERS"] then
				if not CommDKP:GetTable(CommDKP_Loot, true)[i].deletes and not CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby and not CommDKP:GetTable(CommDKP_Loot, true)[i].hidden and CommDKP:GetTable(CommDKP_Loot, true)[i].player == filter then
					table.insert(LootTable, CommDKP:GetTable(CommDKP_Loot, true)[i])
				end
			elseif curDropDownMenuFilterCategory == L["ITEMS"] then
				if not CommDKP:GetTable(CommDKP_Loot, true)[i].deletes and not CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby and not CommDKP:GetTable(CommDKP_Loot, true)[i].hidden and CommDKP:GetTable(CommDKP_Loot, true)[i].loot == filter then
					table.insert(LootTable, CommDKP:GetTable(CommDKP_Loot, true)[i])
				end
			end
		end
	elseif filter and filter == L["DELETEDENTRY"] then
		for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
			if CommDKP:GetTable(CommDKP_Loot, true)[i].deletes then
				table.insert(LootTable, CommDKP:GetTable(CommDKP_Loot, true)[i])
			end
		end
	else -- no filter
		for i=1, #CommDKP:GetTable(CommDKP_Loot, true) do
			if not CommDKP:GetTable(CommDKP_Loot, true)[i].deletes and not CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby and not CommDKP:GetTable(CommDKP_Loot, true)[i].hidden then
				table.insert(LootTable, CommDKP:GetTable(CommDKP_Loot, true)[i])
			end
		end
	end
	CommDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);
	if core.IsOfficer == true then
		CommDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"].."\n"..L["LOOTHISTINST2"].."\n"..L["LOOTHISTINST3"])
	end
	if CurrentLimit > #LootTable then CurrentLimit = #LootTable end;
	if filter and filter ~= L["NOFILTER"] then
		CurrentLimit = #LootTable
	end

	local j=CurrentPosition+1
	local LootTimer = 0
	local processing = false
	LootHistTimer:SetScript("OnUpdate", function(self, elapsed)
		LootTimer = LootTimer + elapsed
		if LootTimer > 0.001 and j <= CurrentLimit and not processing then
			local i = j
			processing = true
		  	local itemToLink = LootTable[i]["loot"]
			local del_search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), LootTable[i].deletes, "index")

		  	if filter == L["DELETEDENTRY"] then
		  		thedate = CommDKP:FormatTime(CommDKP:GetTable(CommDKP_Loot, true)[del_search[1][1]].date)
		  	else
				thedate = CommDKP:FormatTime(LootTable[i]["date"])
			end

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate then
		      linesToUse = 4
		    elseif strtrim(strsub(thedate, 1, 8), " ") == curDate and ((LootTable[i]["boss"] ~= curBoss and LootTable[i]["zone"] ~= curZone) or (LootTable[i]["boss"] == curBoss and LootTable[i]["zone"] ~= curZone)) then
		      linesToUse = 3
		    elseif LootTable[i]["zone"] ~= curZone or LootTable[i]["boss"] ~= curBoss then
		      linesToUse = 2
		    else
		      linesToUse = 1
		    end

		    if (type(CommDKP.ConfigTab5.lootFrame[i]) ~= "table") then
		    	CommDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "CommDKPLootHistoryFrame"..i, CommDKP.ConfigTab5);	-- creates line if it doesn't exist yet
		    end
		    -- determine line height 
	    	if linesToUse == 1 then
				CommDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab5, "TOPLEFT", 10, lineHeight-2);
				CommDKP.ConfigTab5.lootFrame[i]:SetSize(200, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				CommDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				CommDKP.ConfigTab5.lootFrame[i]:SetSize(200, 28)
				lineHeight = lineHeight-24;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				CommDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				CommDKP.ConfigTab5.lootFrame[i]:SetSize(200, 38)
				lineHeight = lineHeight-36;
			elseif linesToUse == 4 then
				lineHeight = lineHeight-14;
				CommDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				CommDKP.ConfigTab5.lootFrame[i]:SetSize(200, 50)
				lineHeight = lineHeight-48;
			end;

			CommDKP.ConfigTab5.looter[i] = CommDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			CommDKP.ConfigTab5.looter[i]:SetFontObject("CommDKPSmallLeft");
			CommDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", CommDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);

			local date1, date2, date3 = strsplit("/", strtrim(strsub(thedate, 1, 8), " "))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), LootTable[i]["player"])
		    local c, lootCost;

		    if classSearch then
		     	c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)
		    else
		     	c = { hex="ff444444" }
		    end

		    if tonumber(LootTable[i].cost) < 0 then lootCost = tonumber(LootTable[i].cost) * -1 else lootCost = tonumber(LootTable[i].cost) end

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate or LootTable[i]["zone"] ~= curZone then
		    	if strtrim(strsub(thedate, 1, 8), " ") ~= curDate then
					feedString = date2.."/"..date3.."/"..date1.."\n  |cff616ccf"..LootTable[i]["zone"].."|r\n   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
					feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |c"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
				else
					feedString = "  |cff616ccf"..LootTable[i]["zone"].."|r\n   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
					feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |c"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
				end
				        
				CommDKP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(thedate, 1, 8), " ")
				curZone = LootTable[i]["zone"];
				curBoss = LootTable[i]["boss"];
		    elseif LootTable[i]["boss"] ~= curBoss then
		    	feedString = "   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |c"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
		    	 
		    	CommDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(thedate, 1, 8), " ")
		    	curBoss = LootTable[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." "..L["WONBY"].." |c"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
		    	
		    	CommDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = LootTable[i]["zone"];
		    end

		    if LootTable[i].reassigned then
		    	CommDKP.ConfigTab5.looter[i]:SetText(CommDKP.ConfigTab5.looter[i]:GetText(feedString).." |cff555555("..L["REASSIGNED"]..")|r")
		    end
		    -- Set script for tooltip/linking
		    CommDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function(self)
		    	local history = 0;
		    	tooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
		    	tooltip:SetHyperlink(itemToLink)
		    	tooltip:AddLine(" ")

		    	local awardOfficer

		    	if filter == L["DELETEDENTRY"] then
		    		awardOfficer = strsplit("-", LootTable[i].deletes)
		    	else
		    		awardOfficer = strsplit("-", LootTable[i].index)
		    	end

		    	local awarded_by_search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), awardOfficer, "player")
		    	if awarded_by_search then
			     	c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[awarded_by_search[1][1]].class)
			    else
			     	c = { hex="ff444444" }
			    end

		    	if LootTable[i].bids or LootTable[i].dkp or LootTable[i].rolls then  		-- displays bids/rolls/dkp values if "Log Bids" checked in modes
		    		local path;

		    		tooltip:AddLine(" ")
		    		if LootTable[i].bids then
		    			tooltip:AddLine(L["BIDS"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].bids, function(a, b)
							return a["bid"] > b["bid"]
						end)
						path = LootTable[i].bids
		    		elseif LootTable[i].dkp then
		    			tooltip:AddLine(L["DKPVALUES"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].dkp, function(a, b)
							return a["dkp"] > b["dkp"]
						end)
						path = LootTable[i].dkp
		    		elseif LootTable[i].rolls then
		    			tooltip:AddLine(L["ROLLS"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].rolls, function(a, b)
							return a["roll"] > b["roll"]
						end)
						path = LootTable[i].rolls
		    		end
		    		for j=1, #path do
		    			local col;
		    			local bidder = path[j].bidder
		    			local s = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), bidder)
		    			local path2 = path[j].bid or path[j].dkp or path[j].roll

		    			if s then
		    				col = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[s[1][1]].class)
		    			else
		    				col = { hex="ff444444" }
		    			end
		    			if bidder == LootTable[i].player then
		    				tooltip:AddLine("|c"..col.hex..bidder.."|r: |cff00ff00"..path2.."|r")
		    			else
		    				tooltip:AddLine("|c"..col.hex..bidder.."|r: |cffff0000"..path2.."|r")
		    			end
		    		end
		    	end
		    	for j=1, #CommDKP:GetTable(CommDKP_Loot, true) do
		    		if CommDKP:GetTable(CommDKP_Loot, true)[j]["loot"] == itemToLink and LootTable[i].date ~= CommDKP:GetTable(CommDKP_Loot, true)[j].date and not CommDKP:GetTable(CommDKP_Loot, true)[j].deletedby and not CommDKP:GetTable(CommDKP_Loot, true)[j].deletes then
		    			local col;
		    			local s = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), CommDKP:GetTable(CommDKP_Loot, true)[j].player)
		    			if s then
		    				col = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[s[1][1]].class)
		    			else
		    				col = { hex="ff444444" }
		    			end
		    			if history == 0 then
		    				tooltip:AddLine(" ");
		    				tooltip:AddLine(L["ALSOWONBY"]..":", 0.25, 0.75, 0.90, 1, true);
		    				history = 1;
		    			end
		    			tooltip:AddDoubleLine("|c"..col.hex..CommDKP:GetTable(CommDKP_Loot, true)[j].player.."|r |cffffffff("..date("%m/%d/%y", CommDKP:GetTable(CommDKP_Loot, true)[j].date)..")|r", "|cffff0000"..-CommDKP:GetTable(CommDKP_Loot, true)[j].cost.." "..L["DKP"].."|r", 1.0, 0, 0)
		    		end
		    	end
			    if filter == L["DELETEDENTRY"] then
			    	local delOfficer,_ = strsplit("-", CommDKP:GetTable(CommDKP_Loot, true)[del_search[1][1]].deletedby)
			    	local col
			    	local del_date = CommDKP:FormatTime(LootTable[i].date)
				    local del_date1, del_date2, del_date3 = strsplit("/", strtrim(strsub(del_date, 1, 8), " "))
			    	local s = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), delOfficer, "player")
			    	if s then
			    		col = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[s[1][1]].class)
			    	else
			    		col = { hex="ff444444"}
			    	end
			    	tooltip:AddLine(" ")
			    	tooltip:AddLine(L["DELETEDBY"], 0.25, 0.75, 0.90, 1, true)
			    	tooltip:AddDoubleLine("|c"..col.hex..delOfficer.."|r", del_date2.."/"..del_date3.."/"..del_date1.." @ "..strtrim(strsub(del_date, 10), " "),1,0,0,1,1,1)
			    end
			    tooltip:AddLine(" ")
			    tooltip:AddDoubleLine(L["AWARDEDBY"], "|c"..c.hex..awardOfficer.."|r", 0.25, 0.75, 0.90)
		    	tooltip:Show();
		    end)
		    CommDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function(self, button)
	   			if button == "RightButton" and filter ~= L["DELETEDENTRY"] then
	   				if core.IsOfficer == true then
	   					RightClickLootMenu(self, LootTable[i].index)
	   				end
	   			elseif button == "LeftButton" then
	   				if IsShiftKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
			    		ChatFrame1EditBox:SetFocus();
			    	elseif IsAltKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..LootTable[i]["player"].." "..L["WON"].." "..select(2,GetItemInfo(itemToLink)).." "..L["OFF"].." "..LootTable[i]["boss"].." "..L["IN"].." "..LootTable[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") "..L["FOR"].." "..-LootTable[i]["cost"].." "..L["DKP"])
			    		ChatFrame1EditBox:SetFocus();
			    	end
	   			end		    	
		    end)
		    CommDKP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide()
		    end)
			if CommDKP.ConfigTab5.LoadHistory then
				CommDKP.ConfigTab5.LoadHistory:SetPoint("TOP", CommDKP.ConfigTab5.lootFrame[i], "BOTTOM", 110, -15)
			end
		    CurrentPosition = CurrentPosition + 1;
		    CommDKP.ConfigTab5.lootFrame[i]:Show();
		    processing = false
		    j=i+1
		    LootTimer = 0
		elseif j > CurrentLimit then
			LootHistTimer:SetScript("OnUpdate", nil)
			LootTimer = 0
			if CommDKP.ConfigTab5.LoadHistory then
				CommDKP.ConfigTab5.LoadHistory:ClearAllPoints();
				CommDKP.ConfigTab5.LoadHistory:SetPoint("TOP", CommDKP.ConfigTab5.lootFrame[CurrentLimit], "BOTTOM", 110, -15)
				if (#LootTable - CurrentPosition) < 25 then
					ButtonText = #LootTable - CurrentPosition;
				end
				CommDKP.ConfigTab5.LoadHistory:SetText(string.format(L["LOAD50MORE"], ButtonText).."...")

				if CurrentLimit >= #LootTable then
					CommDKP.ConfigTab5.LoadHistory:Hide();
				end
			end
		end
	 end)
	if CurrentLimit < #LootTable and not CommDKP.ConfigTab5.LoadHistory then
	 	-- Load More History Button
		CommDKP.ConfigTab5.LoadHistory = self:CreateButton("TOP", CommDKP.ConfigTab5, "BOTTOM", 110, 0, string.format(L["LOAD50MORE"].."...", ButtonText));
		CommDKP.ConfigTab5.LoadHistory:SetSize(110,25)
		CommDKP.ConfigTab5.LoadHistory:SetScript("OnClick", function(self)
			CurrentLimit = CurrentLimit + 25
			if CurrentLimit > #LootTable then
				CurrentLimit = #LootTable
			end
			CommDKP:LootHistory_Update()
		end)
	end
end
