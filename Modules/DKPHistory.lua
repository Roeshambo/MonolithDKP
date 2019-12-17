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
local timeofday;
local player_table = {};
local classSearch;
local playerString = "";
local filter;
local c;
local maxDisplayed = 10
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
	if not MonDKP.ConfigTab6 then return end
	currentRow = 0
	currentLength = maxDisplayed;
	curDate = nil;
	btnText = maxDisplayed;
	if MonDKP.ConfigTab6.loadMoreBtn then
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
	end

	if MonDKP.ConfigTab6.history then
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
end

function DKPHistoryFilterBox_Create()
	local PlayerList = GetSortOptions();
	local curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not filterDropdown then
		filterDropdown = CreateFrame("FRAME", "MonDKPDKPHistoryFilterNameDropDown", MonDKP.ConfigTab6, "MonolithDKPUIDropDownMenuTemplate")
	end

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
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["NOFILTER"], L["NOFILTER"], L["NOFILTER"], L["NOFILTER"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = strsub(PlayerList[((i*20)-19)], 1, 1).."-"..strsub(PlayerList[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
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

	filterDropdown:SetPoint("TOPRIGHT", MonDKP.ConfigTab6, "TOPRIGHT", -13, -11)

	UIDropDownMenu_SetWidth(filterDropdown, 150)
	UIDropDownMenu_SetText(filterDropdown, curfilterName or L["NOFILTER"])
	
  -- Dropdown Menu Function
  function filterDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(filterDropdown, arg2)
    
    if newValue == L["NOFILTER"] then
    	filter = nil;
    	maxDisplayed = 10; 				
    	curSelected = 0
    elseif newValue == L["DELETEDENTRY"] then
    	filter = newValue;
    	maxDisplayed = 10; 				
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

local function MonDKPDeleteDKPEntry(index, timestamp, item)  -- index = entry index (Roeshambo-1), item = # of the entry on DKP History tab; may be different than the key of DKPHistory if hidden fields exist
	-- pop confirmation. If yes, cycles through MonDKP_DKPHistory.players and every name it finds, it refunds them (or strips them of) dkp.
	-- if deleted is the weekly decay,     curdkp * (100 / (100 - decayvalue))
	local reason_header = MonDKP.ConfigTab6.history[item].d:GetText();
	if strfind(reason_header, L["OTHER"].."- ") then reason_header = reason_header:gsub(L["OTHER"].." -- ", "") end
	if strfind(reason_header, "%%") then
		reason_header = gsub(reason_header, "%%", "%%%%")
	end
	local confirm_string = L["CONFIRMDELETEENTRY1"]..":\n\n"..reason_header.."\n\n|CFFFF0000"..L["WARNING"].."|r: "..L["DELETEENTRYREFUNDCONF"];

	StaticPopupDialogs["CONFIRM_DELETE"] = {

		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()

		-- add new entry and add "delted_by" field to entry being "deleted". make new entry exact opposite of "deleted" entry
		-- new entry gets "deletes", old entry gets "deleted_by", deletes = deleted_by index. and vice versa
			local search = MonDKP:Table_Search(MonDKP_DKPHistory, index, "index")

			if search then
				local players = {strsplit(",", strsub(MonDKP_DKPHistory[search[1][1]].players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
				local dkp, mod;
				local dkpString = "";
				local curOfficer = UnitName("player")
				local curTime = time()
				local newIndex = curOfficer.."-"..curTime

				if strfind(MonDKP_DKPHistory[search[1][1]].dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
					dkp = {strsplit(",", MonDKP_DKPHistory[search[1][1]].dkp)}
					mod = "perc";
				else
					dkp = MonDKP_DKPHistory[search[1][1]].dkp
					mod = "whole"
				end

				for i=1, #players do
					if mod == "perc" then
						local search = MonDKP:Table_Search(MonDKP_DKPTable, players[i])

						if search then
							local inverted = tonumber(dkp[i]) * -1
							MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + inverted
							dkpString = dkpString..inverted..",";

							if i == #players then
								dkpString = dkpString..dkp[#dkp]
							end
						end
					else
						local search = MonDKP:Table_Search(MonDKP_DKPTable, players[i])

						if search then
							local inverted = tonumber(dkp) * -1

							MonDKP_DKPTable[search[1][1]].dkp = MonDKP_DKPTable[search[1][1]].dkp + inverted

							if tonumber(dkp) > 0 then
								MonDKP_DKPTable[search[1][1]].lifetime_gained = MonDKP_DKPTable[search[1][1]].lifetime_gained + inverted
							end
							
							dkpString = inverted;
						end
					end
				end
				
				MonDKP_DKPHistory[search[1][1]].deletedby = newIndex
				table.insert(MonDKP_DKPHistory, 1, { players=MonDKP_DKPHistory[search[1][1]].players, dkp=dkpString, date=curTime, reason="Delete Entry", index=newIndex, deletes=index })
				MonDKP.Sync:SendData("MonDKPDelSync", MonDKP_DKPHistory[1])

				if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
					MonDKP:DKPHistory_Update(true)
				end

				MonDKP:StatusVerify_Update()
				DKPTable_Update()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE")
end

local function RightClickDKPMenu(self, index, timestamp, item)
	local header
	local search = MonDKP:Table_Search(MonDKP_DKPHistory, index, "index")

	if search then
		menu = {
		{ text = MonDKP.ConfigTab6.history[item].d:GetText():gsub(L["OTHER"].." -- ", ""), isTitle = true},
		{ text = L["DELETEDKPENTRY"], func = function()
			MonDKPDeleteDKPEntry(index, timestamp, item)
		end },
		}
		EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
	end
end

function MonDKP:DKPHistory_Update(reset)
	if not core.Migrated then return end
	local DKPHistory = {}
	MonDKP:SortDKPHistoryTable()

	if not MonDKP.UIConfig:IsShown() then 			-- prevents history update from firing if the DKP window is not opened (eliminate lag). Update run when opened
		return;
	end

	if reset then
		MonDKP:DKPHistory_Reset()
	end

	if filter and filter ~= L["DELETEDENTRY"] then
		for i=1, #MonDKP_DKPHistory do
			if not MonDKP_DKPHistory[i].deletes and not MonDKP_DKPHistory[i].deletedby and (strfind(MonDKP_DKPHistory[i].players, ","..filter..",") or strfind(MonDKP_DKPHistory[i].players, filter..",") == 1) then
				table.insert(DKPHistory, MonDKP_DKPHistory[i])
			end
		end
	elseif filter and filter == L["DELETEDENTRY"] then
		for i=1, #MonDKP_DKPHistory do
			if MonDKP_DKPHistory[i].deletes then
				table.insert(DKPHistory, MonDKP_DKPHistory[i])
			end
		end
	elseif not filter then
		for i=1, #MonDKP_DKPHistory do
			if not MonDKP_DKPHistory[i].deletes and not MonDKP_DKPHistory[i].hidden and not MonDKP_DKPHistory[i].deletedby then
				table.insert(DKPHistory, MonDKP_DKPHistory[i])
			end
		end
	end
	
	MonDKP.ConfigTab6.history = history;

	if currentLength > #DKPHistory then currentLength = #DKPHistory end

	local j=currentRow+1
	local HistTimer = 0
	local processing = false
	local DKPHistTimer = DKPHistTimer or CreateFrame("StatusBar", nil, UIParent)
	DKPHistTimer:SetScript("OnUpdate", function(self, elapsed)
		HistTimer = HistTimer + elapsed
		if HistTimer > 0.001 and j <= currentLength and not processing then
			local i = j
			processing = true

			if MonDKP.ConfigTab6.loadMoreBtn then
				MonDKP.ConfigTab6.loadMoreBtn:Hide()
			end

			local curOfficer, curIndex = strsplit("-", DKPHistory[i].index)

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

				MonDKP.ConfigTab6.history[i].h = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY") 		-- entry header
				MonDKP.ConfigTab6.history[i].h:SetFontObject("MonDKPNormalLeft");
				MonDKP.ConfigTab6.history[i].h:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i], "TOPLEFT", 15, 0);
				MonDKP.ConfigTab6.history[i].h:SetWidth(400)

				MonDKP.ConfigTab6.history[i].d = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY") 		-- entry description
				MonDKP.ConfigTab6.history[i].d:SetFontObject("MonDKPSmallLeft");
				MonDKP.ConfigTab6.history[i].d:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i].h, "BOTTOMLEFT", 5, -2);
				MonDKP.ConfigTab6.history[i].d:SetWidth(400)

				MonDKP.ConfigTab6.history[i].s = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")			-- entry player string
				MonDKP.ConfigTab6.history[i].s:SetFontObject("MonDKPTinyLeft");
				MonDKP.ConfigTab6.history[i].s:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i].d, "BOTTOMLEFT", 15, -4);
				MonDKP.ConfigTab6.history[i].s:SetWidth(400)

				MonDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
			    	if button == "RightButton" then
		   				if core.IsOfficer == true then
		   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
		   				end
		   			end
			    end)
			end

			local delete_on_date, delete_day, delete_timeofday, delete_year, delete_month, delete_day, delOfficer;

			if filter == L["DELETEDENTRY"] then
				local search = MonDKP:Table_Search(MonDKP_DKPHistory, DKPHistory[i].deletes, "index")

				if search then
					delOfficer,_ = strsplit("-", MonDKP_DKPHistory[search[1][1]].deletedby)
					players = MonDKP_DKPHistory[search[1][1]].players;
					if strfind(MonDKP_DKPHistory[search[1][1]].reason, L["OTHER"].." - ") == 1 then
						reason = MonDKP_DKPHistory[search[1][1]].reason:gsub(L["OTHER"].." -- ", "");
					else
						reason = MonDKP_DKPHistory[search[1][1]].reason
					end
					dkp = MonDKP_DKPHistory[search[1][1]].dkp;
					date = MonDKP:FormatTime(MonDKP_DKPHistory[search[1][1]].date);
					delete_on_date = MonDKP:FormatTime(DKPHistory[i].date)
					delete_day = strsub(delete_on_date, 1, 8)
					delete_timeofday = strsub(delete_on_date, 10)
					delete_year, delete_month, delete_day = strsplit("/", delete_day)
				end
			else
				players = DKPHistory[i].players;
				if strfind(DKPHistory[i].reason, L["OTHER"].." - ") == 1 then
					reason = DKPHistory[i].reason:gsub(L["OTHER"].." -- ", "");
				else
					reason = DKPHistory[i].reason
				end
				dkp = DKPHistory[i].dkp;
				date = MonDKP:FormatTime(DKPHistory[i].date);

				if MonDKP.ConfigTab6.history[i].b then
					MonDKP.ConfigTab6.history[i].b:Hide()
				end
			end
			
			
			player_table = { strsplit(",", players) } or players
			if player_table[1] ~= nil and #player_table > 1 then	-- removes last entry in table which ends up being nil, which creates an additional comma at the end of the string
				tremove(player_table, #player_table)
			end

			for k=1, #player_table do
				classSearch = MonDKP:Table_Search(MonDKP_DKPTable, player_table[k])

				if classSearch then
					c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
					if k < #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[k].."|r, "
					elseif k == #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[k].."|r"
					end
				end
			end

			MonDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" and filter ~= L["DELETEDENTRY"] then
	   				if core.IsOfficer == true then
	   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
	   				end
	   			end
		    end)
		    MonDKP.ConfigTab6.inst:Show();

			day = strsub(date, 1, 8)
			timeofday = strsub(date, 10)
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

			local officer_search = MonDKP:Table_Search(MonDKP_DKPTable, curOfficer, "player")
	    	if officer_search then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[officer_search[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end
			
			if not strfind(dkp, "-") then
				MonDKP.ConfigTab6.history[i].d:SetText("|cff00ff00"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
			else
				if strfind(reason, L["WEEKLYDECAY"]) or strfind(reason, "Migration Correction") then
					local decay = {strsplit(",", dkp)}
					MonDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..decay[#decay].." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
				else
					MonDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
				end
			end

			MonDKP.ConfigTab6.history[i].d:Show()

			if not filter or (filter and filter == L["DELETEDENTRY"]) then
				MonDKP.ConfigTab6.history[i].s:SetText(playerString);
				MonDKP.ConfigTab6.history[i].s:Show()
			else
				MonDKP.ConfigTab6.history[i].s:Hide()
			end

			if filter and filter ~= L["DELETEDENTRY"] then
				MonDKP.ConfigTab6.history[i]:SetHeight(MonDKP.ConfigTab6.history[i].s:GetHeight() + MonDKP.ConfigTab6.history[i].h:GetHeight() + MonDKP.ConfigTab6.history[i].d:GetHeight())
			else
				MonDKP.ConfigTab6.history[i]:SetHeight(MonDKP.ConfigTab6.history[i].s:GetHeight() + MonDKP.ConfigTab6.history[i].h:GetHeight() + MonDKP.ConfigTab6.history[i].d:GetHeight() + 10)
				if filter == L["DELETEDENTRY"] then
					if not MonDKP.ConfigTab6.history[i].b then
						MonDKP.ConfigTab6.history[i].b = CreateFrame("Button", "RightClickButtonDKPHistory"..i, MonDKP.ConfigTab6.history[i]);
					end
					MonDKP.ConfigTab6.history[i].b:Show()
					MonDKP.ConfigTab6.history[i].b:SetPoint("TOPLEFT", MonDKP.ConfigTab6.history[i], "TOPLEFT", 0, 0)
					MonDKP.ConfigTab6.history[i].b:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab6.history[i], "BOTTOMRIGHT", 0, 0)
					MonDKP.ConfigTab6.history[i].b:SetScript("OnEnter", function(self)
				    	local col
				    	local s = MonDKP:Table_Search(MonDKP_DKPTable, delOfficer, "player")
				    	if s then
				    		col = MonDKP:GetCColors(MonDKP_DKPTable[s[1][1]].class)
				    	else
				    		col = { hex="444444"}
				    	end
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0);
						GameTooltip:SetText(L["DELETEDBY"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddDoubleLine("|cff"..col.hex..delOfficer.."|r", delete_month.."/"..delete_day.."/"..delete_year.." @ "..delete_timeofday, 1,0,0,1,1,1)
						GameTooltip:Show()
					end);
					MonDKP.ConfigTab6.history[i].b:SetScript("OnLeave", function(self)
						GameTooltip:Hide();
					end)
				end
			end

			playerString = ""
			table.wipe(player_table)

			MonDKP.ConfigTab6.history[i]:Show()

			currentRow = currentRow + 1;
			processing = false
		    j=i+1
		    HistTimer = 0
		elseif j > currentLength then
			DKPHistTimer:SetScript("OnUpdate", nil)
			HistTimer = 0

			if not MonDKP.ConfigTab6.loadMoreBtn then
				MonDKP.ConfigTab6.loadMoreBtn = CreateFrame("Button", nil, MonDKP.ConfigTab6, "MonolithDKPButtonTemplate")
				MonDKP.ConfigTab6.loadMoreBtn:SetSize(100, 30);
				MonDKP.ConfigTab6.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...");
				MonDKP.ConfigTab6.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
				MonDKP.ConfigTab6.loadMoreBtn:SetNormalFontObject("MonDKPSmallCenter");
				MonDKP.ConfigTab6.loadMoreBtn:SetHighlightFontObject("MonDKPSmallCenter");
				MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
				MonDKP.ConfigTab6.loadMoreBtn:SetScript("OnClick", function(self)
					currentLength = currentLength + maxDisplayed;
					MonDKP:DKPHistory_Update()
					MonDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
					MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10)
				end)
			end

			if MonDKP.ConfigTab6.loadMoreBtn and currentRow == #DKPHistory then 
				MonDKP.ConfigTab6.loadMoreBtn:Hide();
			elseif MonDKP.ConfigTab6.loadMoreBtn and currentRow < #DKPHistory then
				if (#DKPHistory - currentRow) < btnText then btnText = (#DKPHistory - currentRow) end
				MonDKP.ConfigTab6.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...")
				MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
				MonDKP.ConfigTab6.loadMoreBtn:Show()
			end
		end
	end)
end