local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local players;
local reason;
local dkp;
local formdate = date;
local date;
local year;
local month;
local day;
local time;
local player_table = {};
local classSearch;
local playerString = "";
local filter;
local c;
local maxDisplayed = 5
local currentLength = 10;
local currentRow = 0;
local btnText = 10;
local curDate;
local history = {};
local menuFrame = CreateFrame("Frame", "MonDKPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate")

function MonDKP:SortDKPHistoryTable()             -- sorts the DKP History Table by date/time
  table.sort(MonDKP_DKPHistory, function(a, b)
    return a["date"] > b["date"]
  end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #MonDKP_DKPTable do
		local playerSearch = MonDKP:Table_Search(PlayerList, MonDKP_DKPTable[i].player)
		if not playerSearch then
			tinsert(PlayerList, MonDKP_DKPTable[i].player)
		end
	end
	table.sort(PlayerList, function(a, b)
		return a < b
	end)
	return PlayerList;
end

function MonDKP:DKPHistory_Reset()
	currentRow = 0
	currentLength = maxDisplayed;
	curDate = nil;
	btnText = maxDisplayed;
	if MonDKP.ConfigTab6.loadMoreBtn then
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
	end

	for i=1, #MonDKP.ConfigTab6.history do
		if MonDKP.ConfigTab6.history[i] then
			MonDKP.ConfigTab6.history[i].h:SetText("")
			MonDKP.ConfigTab6.history[i].h:Hide()
			MonDKP.ConfigTab6.history[i].d:SetText("")
			MonDKP.ConfigTab6.history[i].d:Hide()
			MonDKP.ConfigTab6.history[i].s:SetText("")
			MonDKP.ConfigTab6.history[i].s:Hide()
			MonDKP.ConfigTab6.history[i]:SetHeight(10)
			MonDKP.ConfigTab6.history[i]:Hide()
		end
	end
end

function DKPHistoryFilterBox_Create()
	local PlayerList = GetSortOptions();
	local curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not filterDropdown then
		filterDropdown = CreateFrame("FRAME", "MonDKPDKPHistoryFilterNameDropDown", MonDKP.ConfigTab6, "MonolithDKPUIDropDownMenuTemplate")
		filterDropdown:SetPoint("TOPRIGHT", MonDKP.ConfigTab6, "TOPRIGHT", -13, -11)
	end
	UIDropDownMenu_SetWidth(filterDropdown, 150)
	UIDropDownMenu_SetText(filterDropdown, curfilterName or "No Filter")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(filterDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #PlayerList do
			table.insert(ranges, ranges[#ranges]+20)
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#PlayerList/20)
			filterName.func = self.FilterSetValue
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "No Filter", "No Filter", "No Filter", "No Filter" == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = "Players "..((i*20)-19).."-"..max, curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end
			
		else
			filterName.func = self.FilterSetValue
			for i=ranges[menuList], ranges[menuList]+19 do
				if PlayerList[i] then
					local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, PlayerList[i])
				    local c;

				    if classSearch then
				     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
				    else
				     	c = { hex="444444" }
				    end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i], "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i] == curfilterName, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)
	
  -- Dropdown Menu Function
  function filterDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(filterDropdown, arg2)
    
    if newValue == "No Filter" then
    	filter = nil;
    	maxDisplayed = 5; 				-- limits to 5 entries if full history, 30 if individual history (less info to print)
    	curSelected = 0
    else
	    filter = newValue;
	    maxDisplayed = 30;
	    local search = MonDKP:Table_Search(PlayerList, newValue)
	    curSelected = search[1]
    end

    MonDKP:DKPHistory_Update(true)
    CloseDropDownMenus()
  end
end

local function MonDKPDeleteDKPEntry(item, timestamp)
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
	-- pop confirmation. If yes, cycles through MonDKP_DKPHistory.players and every name it finds, it refunds them (or strips them of) dkp.
	-- if deleted is the weekly decay,     curdkp * (100 / (100 - decayvalue))
	local reason_header = MonDKP.ConfigTab6.history[item].d:GetText();
	if strfind(reason_header, "%%") then
		reason_header = gsub(reason_header, "%%", "%%%%")
	end
	local confirm_string = L["CONFIRMDELETEENTRY1"]..":\n\n"..reason_header.."\n\n|CFFFF0000"..L["WARNING"].."|r: "..L["DELETEENTRYREFUNDCONF"];

	StaticPopupDialogs["CONFIRM_DELETE"] = {

		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()
			local dkp_value;
			local ModType;
			local search = MonDKP:Table_Search(MonDKP_DKPHistory, timestamp)

			if search then
				if strfind(MonDKP_DKPHistory[search[1][1]].dkp, "%%") then
					dkp_value = gsub(MonDKP_DKPHistory[search[1][1]].dkp, "%%", "")
					ModType = "perc"
				else
					dkp_value = MonDKP_DKPHistory[search[1][1]].dkp
					ModType = "whole"
				end
				for i=1, #MonDKP_DKPTable do
					local search = strfind(string.upper(tostring(MonDKP_DKPHistory[search[1][1]].players)), string.upper(MonDKP_DKPTable[i].player)..",")
					
					if search then
						if ModType == "perc" then
							MonDKP_DKPTable[i].dkp = MonDKP_round(tonumber(MonDKP_DKPTable[i].dkp * (100 / (100 + dkp_value))), MonDKP_DB.modes.rounding)
						elseif ModType == "whole" then
							MonDKP_DKPTable[i].dkp = MonDKP_DKPTable[i].dkp - dkp_value;
							MonDKP_DKPTable[i].lifetime_gained = MonDKP_DKPTable[i].lifetime_gained - dkp_value;
						end
					end
				end

				table.remove(MonDKP_DKPHistory, search[1][1])
				if MonDKP.ConfigTab6.history then
					MonDKP:DKPHistory_Reset()
				end
				MonDKP:DKPHistory_Update()
				MonDKP:SeedVerify_Update()
				DKPTable_Update()
				if core.UpToDate and core.IsOfficer then -- updates seeds only if table is currently up to date.
					MonDKP:UpdateSeeds()
				end
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
				MonDKP.Sync:SendData("MonDKPDKPDelSync", { seed = MonDKP_DKPHistory.seed, item, timestamp })
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE")
end

local function RightClickDKPMenu(self, item, timestamp)
	menu = {
	{ text = MonDKP_DKPHistory[item]["dkp"].." "..L["DKP"].." - "..MonDKP_DKPHistory[item]["reason"].." @ "..formdate("%m/%d/%y %H:%M:%S", MonDKP_DKPHistory[item]["date"]), isTitle = true},
	{ text = L["DELETEDKPENTRY"], func = function()
		MonDKPDeleteDKPEntry(item, timestamp)
	end },
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
end

function MonDKP:DKPHistory_Update(reset)
	local DKPHistory = {}

	if not MonDKP.UIConfig:IsShown() then 			-- prevents history update from firing if the DKP window is not opened (eliminate lag). Update run when opened
		return;
	end

	if reset then
		MonDKP:DKPHistory_Reset()
	end

	if filter then
		for i=1, #MonDKP_DKPHistory do
			if strfind(MonDKP_DKPHistory[i].players, filter..",") then
				table.insert(DKPHistory, MonDKP_DKPHistory[i])
			end
		end
	else
		DKPHistory = MonDKP_DKPHistory
	end
	
	MonDKP.ConfigTab6.history = history;
	MonDKP:SortDKPHistoryTable()

	if currentLength > #DKPHistory then currentLength = #DKPHistory end

	for i=currentRow+1, currentLength do
		if not MonDKP.ConfigTab6.history[i] then
			if i==1 then
				MonDKP.ConfigTab6.history[i] = CreateFrame("Frame", "MonDKP_DKPHistoryTab", MonDKP.ConfigTab6);
				MonDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab6, "TOPLEFT", 0, -45)
				MonDKP.ConfigTab6.history[i]:SetWidth(400)
			else
				MonDKP.ConfigTab6.history[i] = CreateFrame("Frame", "MonDKP_DKPHistoryTab", MonDKP.ConfigTab6);
				MonDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, 0)
				MonDKP.ConfigTab6.history[i]:SetWidth(400)
			end

			MonDKP.ConfigTab6.history[i].h = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab6.history[i].h:SetFontObject("MonDKPNormalLeft");
			MonDKP.ConfigTab6.history[i].h:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i], "TOPLEFT", 15, 0);
			MonDKP.ConfigTab6.history[i].h:SetWidth(400)

			MonDKP.ConfigTab6.history[i].d = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab6.history[i].d:SetFontObject("MonDKPSmallLeft");
			MonDKP.ConfigTab6.history[i].d:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i].h, "BOTTOMLEFT", 5, -2);
			MonDKP.ConfigTab6.history[i].d:SetWidth(400)

			MonDKP.ConfigTab6.history[i].s = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab6.history[i].s:SetFontObject("MonDKPTinyLeft");
			MonDKP.ConfigTab6.history[i].s:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i].d, "BOTTOMLEFT", 15, -4);
			MonDKP.ConfigTab6.history[i].s:SetWidth(400)

			MonDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" then
	   				if core.IsOfficer == true then
	   					RightClickDKPMenu(self, i, DKPHistory[i].date)
	   				end
	   			end
		    end)
		end

		
		players = DKPHistory[i].players;
		reason = DKPHistory[i].reason;
		dkp = DKPHistory[i].dkp;
		date = MonDKP:FormatTime(DKPHistory[i].date);
		
		if not filter then
			player_table = { strsplit(",", players) } or players
			if player_table[1] ~= nil and #player_table > 1 then	-- removes last entry in table which ends up being nil, which creates an additional comma at the end of the string
				tremove(player_table, #player_table)
			end

			for j=1, #player_table do
				classSearch = MonDKP:Table_Search(MonDKP_DKPTable, player_table[j])

				if classSearch then
					c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
					if j < #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[j].."|r, "
					elseif j == #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[j].."|r"
					end
				end
			end

			MonDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" then
	   				if core.IsOfficer == true then
	   					RightClickDKPMenu(self, i, DKPHistory[i].date)
	   				end
	   			end
		    end)
		    MonDKP.ConfigTab6.inst:Show();
		else
			MonDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", nil)
			MonDKP.ConfigTab6.inst:Hide();
		end

		day = strsub(date, 1, 8)
		time = strsub(date, 10)
		year, month, day = strsplit("/", day)

		if day ~= curDate then
			if i~=1 then
				MonDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, -20)
			end
			MonDKP.ConfigTab6.history[i].h:SetText(month.."/"..day.."/"..year);
			MonDKP.ConfigTab6.history[i].h:Show()
			curDate = day;
		else
			if i~=1 then
				MonDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, 0)
			end
			MonDKP.ConfigTab6.history[i].h:Hide()
		end
		
		if not strfind(dkp, "-") then
			MonDKP.ConfigTab6.history[i].d:SetText("|cff00ff00"..dkp.." "..L["DKP"].."|r - "..reason.." @ "..time);
		else
			MonDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..dkp.." "..L["DKP"].."|r - "..reason.." @ "..time);
		end

		MonDKP.ConfigTab6.history[i].d:Show()

		if not filter then
			MonDKP.ConfigTab6.history[i].s:SetText(playerString);
			MonDKP.ConfigTab6.history[i].s:Show()
		else
			MonDKP.ConfigTab6.history[i].s:Hide()
		end

		if filter then
			MonDKP.ConfigTab6.history[i]:SetHeight(MonDKP.ConfigTab6.history[i].s:GetHeight() + MonDKP.ConfigTab6.history[i].h:GetHeight() + MonDKP.ConfigTab6.history[i].d:GetHeight())
		else
			MonDKP.ConfigTab6.history[i]:SetHeight(MonDKP.ConfigTab6.history[i].s:GetHeight() + MonDKP.ConfigTab6.history[i].h:GetHeight() + MonDKP.ConfigTab6.history[i].d:GetHeight() + 20)
		end

		playerString = ""
		table.wipe(player_table)

		MonDKP.ConfigTab6.history[i]:Show()

		currentRow = currentRow + 1;
	end

	if (#DKPHistory - currentLength) < maxDisplayed then btnText = #DKPHistory - currentLength end

	if not MonDKP.ConfigTab6.loadMoreBtn then
		MonDKP.ConfigTab6.loadMoreBtn = CreateFrame("Button", nil, MonDKP.ConfigTab6, "MonolithDKPButtonTemplate")
		MonDKP.ConfigTab6.loadMoreBtn:SetSize(100, 30);
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...");
		MonDKP.ConfigTab6.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab6.loadMoreBtn:SetNormalFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetHighlightFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
		MonDKP.ConfigTab6.loadMoreBtn:SetScript("OnClick", function()
			currentLength = currentLength + maxDisplayed;
			MonDKP:DKPHistory_Update();
			MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
			MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10)
		end)
	end

	if MonDKP.ConfigTab6.loadMoreBtn and currentRow == #DKPHistory then 
		MonDKP.ConfigTab6.loadMoreBtn:Hide();
	elseif MonDKP.ConfigTab6.loadMoreBtn and currentRow < #DKPHistory then
		MonDKP.ConfigTab6.loadMoreBtn:Show();
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
	end
end