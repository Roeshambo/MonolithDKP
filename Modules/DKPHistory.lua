local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local players;
local reason;
local dkp;
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
		MonDKP.ConfigTab6.loadMoreBtn:SetText("Load "..btnText.." more...")
	end

	for i=1, #MonDKP_DKPHistory do
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
		end

		players = MonDKP_DKPHistory[i].players;
		reason = MonDKP_DKPHistory[i].reason;
		dkp = MonDKP_DKPHistory[i].dkp;
		date = MonDKP:FormatTime(MonDKP_DKPHistory[i].date);
		
		player_table = { strsplit(",", players) } or players
		if player_table[1] ~= nil and #player_table > 1 then
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
			MonDKP.ConfigTab6.history[i].d:SetText("|cff00ff00"..dkp.." DKP|r - "..reason.." @ "..time);
		else
			MonDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..dkp.." DKP|r - "..reason.." @ "..time);
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
		MonDKP.ConfigTab6.loadMoreBtn:SetText("Load "..btnText.." more...");
		MonDKP.ConfigTab6.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
		MonDKP.ConfigTab6.loadMoreBtn:SetNormalFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetHighlightFontObject("MonDKPSmallCenter");
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
		MonDKP.ConfigTab6.loadMoreBtn:SetScript("OnClick", function()
			currentLength = currentLength + 50;
			MonDKP:DKPHistory_Update();
			MonDKP.ConfigTab6.loadMoreBtn:SetText("Load "..btnText.." more...")
			MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10)
		end)
	end

	if MonDKP.ConfigTab6.loadMoreBtn and currentRow == #MonDKP_DKPHistory then 
		MonDKP.ConfigTab6.loadMoreBtn:Hide();
	elseif MonDKP.ConfigTab6.loadMoreBtn and currentRow < #MonDKP_DKPHistory then
		MonDKP.ConfigTab6.loadMoreBtn:Show();
		MonDKP.ConfigTab6.loadMoreBtn:SetText("Load "..btnText.." more...")
		MonDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", MonDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
	end
end