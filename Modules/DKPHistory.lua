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
local c;
local currentLength = 50;
local currentRow = 0;
local btnText = 50;
local curDate;
local history = {};
local menuFrame = CreateFrame("Frame", "MonDKPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate")

function MonDKP:SortDKPHistoryTable()             -- sorts the DKP History Table by date/time
  table.sort(MonDKP_DKPHistory, function(a, b)
    return a["date"] > b["date"]
  end)
end

function MonDKP:DKPHistory_Reset()
	currentRow = 0
	currentLength = 50;
	curDate = nil;
	btnText = 50;
	if MonDKP.ConfigTab6.loadMoreBtn then
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["Load"].." "..btnText.." "..L["More"].."...")
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

local function MonDKPDeleteDKPEntry(item, timestamp)
	if core.CurrentlySyncing then
		StaticPopupDialogs["CURRENTLY_SYNC"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CurrentlySyncing"],
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
	local confirm_string = L["ConfirmDeleteEntry1"]..":\n\n"..reason_header.."\n\n|CFFFF0000"..L["WARNING"].."|r: "..L["DeleteEntryRefundConf"];

	StaticPopupDialogs["CONFIRM_DELETE"] = {

		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()
			local dkp_value;
			local ModType;

			if strfind(MonDKP_DKPHistory[item].dkp, "%%") then
				dkp_value = gsub(MonDKP_DKPHistory[item].dkp, "%%", "")
				ModType = "perc"
			else
				dkp_value = MonDKP_DKPHistory[item].dkp
				ModType = "whole"
			end
			for i=1, #MonDKP_DKPTable do
				local search = strfind(string.upper(tostring(MonDKP_DKPHistory[item].players)), string.upper(MonDKP_DKPTable[i].player)..",")
				
				if search then
					if ModType == "perc" then
						MonDKP_DKPTable[i].dkp = MonDKP_round(tonumber(MonDKP_DKPTable[i].dkp * (100 / (100 + dkp_value))), MonDKP_DB.modes.rounding)
					elseif ModType == "whole" then
						MonDKP_DKPTable[i].dkp = MonDKP_DKPTable[i].dkp - dkp_value;
						MonDKP_DKPTable[i].lifetime_gained = MonDKP_DKPTable[i].lifetime_gained - dkp_value;
					end
				end
			end

			table.remove(MonDKP_DKPHistory, item)
			if MonDKP.ConfigTab6.history then
				MonDKP:DKPHistory_Reset()
			end
			if MonDKP.ConfigTab6.history and #MonDKP_DKPHistory == 0 then
				MonDKP:DKPHistory_Reset()
			end
			MonDKP:DKPHistory_Update()
			DKPTable_Update()
			MonDKP:SeedVerify_Update()
			if core.UpToDate and core.IsOfficer then -- updates seeds only if table is currently up to date.
				MonDKP:UpdateSeeds()
			end
			MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
			MonDKP.Sync:SendData("MonDKPDKPDelSync", { seed = MonDKP_DKPHistory.seed, item, timestamp })
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
	{ text = L["DeleteDKPEntry"], func = function()
		MonDKPDeleteDKPEntry(item, timestamp)
	end },
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
end

function MonDKP:DKPHistory_Update()
	MonDKP.ConfigTab6.history = history;
	MonDKP:SortDKPHistoryTable()

	if currentLength > #MonDKP_DKPHistory then currentLength = #MonDKP_DKPHistory end

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
	   					RightClickDKPMenu(self, i, MonDKP_DKPHistory[i].date)
	   				end
	   			end
		    end)
		end

		players = MonDKP_DKPHistory[i].players;
		reason = MonDKP_DKPHistory[i].reason;
		dkp = MonDKP_DKPHistory[i].dkp;
		date = MonDKP:FormatTime(MonDKP_DKPHistory[i].date);
		
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

		day = strsub(date, 1, 8)
		time = strsub(date, 10)
		year, month, day = strsplit("/", day)

		if day ~= curDate then
			MonDKP.ConfigTab6.history[i].h:SetText(month.."/"..day.."/"..year);
			MonDKP.ConfigTab6.history[i].h:Show()
			curDate = day;
		else
			MonDKP.ConfigTab6.history[i].h:Hide()
		end
		
		if not strfind(dkp, "-") then
			MonDKP.ConfigTab6.history[i].d:SetText("|cff00ff00"..dkp.." "..L["DKP"].."|r - "..reason.." @ "..time);
		else
			MonDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..dkp.." "..L["DKP"].."|r - "..reason.." @ "..time);
		end

		MonDKP.ConfigTab6.history[i].d:Show()

		MonDKP.ConfigTab6.history[i].s:SetText(playerString);
		MonDKP.ConfigTab6.history[i].s:Show()

		MonDKP.ConfigTab6.history[i]:SetHeight(MonDKP.ConfigTab6.history[i].s:GetHeight() + MonDKP.ConfigTab6.history[i].h:GetHeight() + MonDKP.ConfigTab6.history[i].d:GetHeight() + 20)

		playerString = ""
		table.wipe(player_table)

		MonDKP.ConfigTab6.history[i]:Show()

		currentRow = currentRow + 1;
	end

	if (#MonDKP_DKPHistory - currentLength) < 50 then btnText = #MonDKP_DKPHistory - currentLength end

	if not MonDKP.ConfigTab6.loadMoreBtn then
		MonDKP.ConfigTab6.loadMoreBtn = CreateFrame("Button", nil, MonDKP.ConfigTab6, "MonolithDKPButtonTemplate")
		MonDKP.ConfigTab6.loadMoreBtn:SetSize(100, 30);
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["Load"].." "..btnText.." "..L["More"].."...");
		MonDKP.ConfigTab6.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab6.loadMoreBtn:SetNormalFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetHighlightFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
		MonDKP.ConfigTab6.loadMoreBtn:SetScript("OnClick", function()
			currentLength = currentLength + 50;
			MonDKP:DKPHistory_Update();
			MonDKP.ConfigTab6.loadMoreBtn:SetText(L["Load"].." "..btnText.." "..L["More"].."...")
			MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10)
		end)
	end

	if MonDKP.ConfigTab6.loadMoreBtn and currentRow == #MonDKP_DKPHistory then 
		MonDKP.ConfigTab6.loadMoreBtn:Hide();
	elseif MonDKP.ConfigTab6.loadMoreBtn and currentRow < #MonDKP_DKPHistory then
		MonDKP.ConfigTab6.loadMoreBtn:Show();
		MonDKP.ConfigTab6.loadMoreBtn:SetText(L["Load"].." "..btnText.." "..L["More"].."...")
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
	end
end