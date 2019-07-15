local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

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

function CreateSortBox()
	local PlayerList = GetSortOptions();
	local curfilterName = "No Filter";

	-- Create the dropdown, and configure its appearance
	sortDropdown = CreateFrame("FRAME", "MonDKPConfigFilterNameDropDown", MonDKP.ConfigTab5, "MonolithDKPUIDropDownMenuTemplate")
	sortDropdown:SetPoint("TOP", MonDKP.ConfigTab5, "TOP", -30, -6)
	UIDropDownMenu_SetWidth(sortDropdown, 150)
	UIDropDownMenu_SetText(sortDropdown, "Filter Name")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(sortDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
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

			filterName.text, filterName.arg1, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i], PlayerList[i] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		end
	end);

  -- Dropdown Menu Function
  function sortDropdown:FilterSetValue(newValue)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(sortDropdown, curfilterName)
    MonDKP:LootHistory_Update(newValue)
    CloseDropDownMenus()
  end
end


local tooltip = CreateFrame('GameTooltip', "nil", UIParent, 'GameTooltipTemplate')
local CurrentPosition = 0
local CurrentLimit = 50;
local lineHeight = -30;
local ButtonText = 50;
local curDate = 1;
local curZone;
local curBoss;

function MonDKP:LootHistory_Reset()
	CurrentPosition = 0
	CurrentLimit = 50;
	lineHeight = -30;
	ButtonText = 50;
	curDate = 1;
	curZone = nil;
	curBoss = nil;

	for i=1, #MonDKP_Loot do
		if MonDKP.ConfigTab5.looter[i] then
			MonDKP.ConfigTab5.looter[i]:SetText("")
			MonDKP.ConfigTab5.lootFrame[i]:Hide()
		end
	end
end

function MonDKP:LootHistory_Update(filter)

	local linesToUse = 1;
	--local historyLength
	MonDKP:SortLootTable()
	


	--[[for i=1, #MonDKP.ConfigTab5.looter do
		MonDKP.ConfigTab5.looter[i]:SetText("")
		MonDKP.ConfigTab5.lootFrame[i]:Hide()
	end--]]

	--[[if #MonDKP_Loot < 1000 then 
		historyLength = #MonDKP_Loot
	else
		historyLength = 1000
	end--]]
	if filter then
		MonDKP:LootHistory_Reset()
	end

	if CurrentLimit > #MonDKP_Loot then CurrentLimit = #MonDKP_Loot end;

	if filter and filter ~= "No Filter" then
		CurrentLimit = #MonDKP_Loot
	end

	for i=CurrentPosition+1, CurrentLimit do
	  	if (filter and filter == MonDKP_Loot[i].player and filter ~= "No Filter") or (filter and filter == MonDKP_Loot[i].loot and filter ~= "No Filter") then
		    local itemToLink = MonDKP_Loot[i]["loot"]

		    if strsub(MonDKP_Loot[i]["date"], 1, 8) ~= curDate then
		      linesToUse = 3
		    elseif strsub(MonDKP_Loot[i]["date"], 1, 8) == curDate and MonDKP_Loot[i]["boss"] ~= curBoss and MonDKP_Loot[i]["zone"] ~= curZone then
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
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 28)
				lineHeight = lineHeight-25;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 42)
				lineHeight = lineHeight-37;
			end;

			MonDKP.ConfigTab5.looter[i] = MonDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab5.looter[i]:SetFontObject("MonDKPSmallLeft");
			MonDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);
		   

		    -- print string to history
		    local date1, date2, date3 = strsplit("/", strsub(MonDKP_Loot[i]["date"], 1, 8))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[i]["player"])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if strsub(MonDKP_Loot[i]["date"], 1, 8) ~= curDate or MonDKP_Loot[i]["zone"] ~= curZone then
				feedString = date2.."/"..date3.."/"..date1.." - "..MonDKP_Loot[i]["zone"].."\n  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(MonDKP_Loot[i]["date"], 10), " ")..")|r".."\n"
				feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
				        
				MonDKP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ")
				curZone = MonDKP_Loot[i]["zone"];
				curBoss = MonDKP_Loot[i]["boss"];
		    elseif MonDKP_Loot[i]["boss"] ~= curBoss then
		    	feedString = "  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(MonDKP_Loot[i]["date"], 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ")
		    	curBoss = MonDKP_Loot[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = MonDKP_Loot[i]["zone"];
		    end

		    -- Set script for tooltip/linking
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function()
		    	tooltip:SetOwner(MonDKP.UIConfig, "ANCHOR_RIGHT", 0, -425)
		    	tooltip:SetHyperlink(itemToLink)
		    	tooltip:Show();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function()
		    	if IsShiftKeyDown() then
		    		ChatFrame1EditBox:Show();
		    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
		    		ChatFrame1EditBox:SetFocus();
		    	elseif IsAltKeyDown() then
		    		ChatFrame1EditBox:Show();
		    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..MonDKP_Loot[i]["player"].." won "..select(2,GetItemInfo(itemToLink)).." off "..MonDKP_Loot[i]["boss"].." in "..MonDKP_Loot[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") for "..MonDKP_Loot[i]["cost"].." DKP")
		    		ChatFrame1EditBox:SetFocus();		    		
		    	end
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:Show();
		    CurrentPosition = CurrentPosition + 1;
		elseif not filter or filter == "No Filter" then
			local itemToLink = MonDKP_Loot[i]["loot"]

		    if strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ") ~= curDate then
		      linesToUse = 3
		    elseif strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ") == curDate and MonDKP_Loot[i]["boss"] ~= curBoss and MonDKP_Loot[i]["zone"] ~= curZone then
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
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 28)
				lineHeight = lineHeight-25;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 42)
				lineHeight = lineHeight-37;
			end;

			MonDKP.ConfigTab5.looter[i] = MonDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab5.looter[i]:SetFontObject("MonDKPSmallLeft");
			MonDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);
		   

		    -- print string to history
		    local date1, date2, date3 = strsplit("/", strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " "))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Loot[i]["player"])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ") ~= curDate or MonDKP_Loot[i]["zone"] ~= curZone then
				feedString = date2.."/"..date3.."/"..date1.." - "..MonDKP_Loot[i]["zone"].."\n  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(MonDKP_Loot[i]["date"], 10), " ")..")|r".."\n"
				feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
				        
				MonDKP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ")
				curZone = MonDKP_Loot[i]["zone"];
				curBoss = MonDKP_Loot[i]["boss"];
		    elseif MonDKP_Loot[i]["boss"] ~= curBoss then
		    	feedString = "  |cffff0000"..MonDKP_Loot[i]["boss"].."|r |cff555555("..strtrim(strsub(MonDKP_Loot[i]["date"], 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
		    	 
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(MonDKP_Loot[i]["date"], 1, 8), " ")
		    	curBoss = MonDKP_Loot[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." won by |cff"..c.hex..MonDKP_Loot[i]["player"].."|r |cff555555("..MonDKP_Loot[i]["cost"].." DKP)|r"
		    	
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = MonDKP_Loot[i]["zone"];
		    end

		    -- Set script for tooltip/linking
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function()
		    	tooltip:SetOwner(MonDKP.UIConfig, "ANCHOR_RIGHT", 0, -425)
		    	tooltip:SetHyperlink(itemToLink)
		    	tooltip:Show();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function()
		    	if IsShiftKeyDown() then
		    		ChatFrame1EditBox:Show();
		    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
		    		ChatFrame1EditBox:SetFocus();
		    	elseif IsAltKeyDown() then
		    		ChatFrame1EditBox:Show();
		    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..MonDKP_Loot[i]["player"].." won "..select(2,GetItemInfo(itemToLink)).." off "..MonDKP_Loot[i]["boss"].." in "..MonDKP_Loot[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") for "..MonDKP_Loot[i]["cost"].." DKP")
		    		ChatFrame1EditBox:SetFocus();
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
		MonDKP.ConfigTab5.LoadHistory = self:CreateButton("TOPLEFT", MonDKP.ConfigTab5.lootFrame[CurrentLimit], "BOTTOMLEFT", 0, 0, "Load 50 More...");
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
		MonDKP.ConfigTab5.LoadHistory:SetText("Load "..ButtonText.." more...")
		if CurrentLimit == #MonDKP_Loot then
			MonDKP.ConfigTab5.LoadHistory:Hide();
		else
			MonDKP.ConfigTab5.LoadHistory:Show();
		end
	end
end