local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local f = {}
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
	MonDKP.ConfigTab6.history.btn:SetText("Load "..btnText.." more...")

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
	MonDKP:SortDKPHistoryTable()

	if currentLength > #MonDKP_DKPHistory then currentLength = #MonDKP_DKPHistory end

	for i=currentRow+1, currentLength do
		if not f[i] then
			if i==1 then
				f[i] = CreateFrame("Frame", "MonDKP_DKPHistoryTab", MonDKP.ConfigTab6);
				f[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab6, "TOPLEFT", 0, -45)
				f[i]:SetWidth(477)
			else
				f[i] = CreateFrame("Frame", "MonDKP_DKPHistoryTab", MonDKP.ConfigTab6);
				f[i]:SetPoint("TOPLEFT", f[i-1], "BOTTOMLEFT", 0, 0)
				f[i]:SetWidth(477)
			end

			f[i].h = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			f[i].h:SetFontObject("MonDKPNormalLeft");
			f[i].h:SetPoint("TOPLEFT", f[i], "TOPLEFT", 15, 0);
			f[i].h:SetWidth(400)

			f[i].d = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			f[i].d:SetFontObject("MonDKPSmallLeft");
			f[i].d:SetPoint("TOPLEFT", f[i].h, "BOTTOMLEFT", 5, -2);
			f[i].d:SetWidth(400)

			f[i].s = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
			f[i].s:SetFontObject("MonDKPTinyLeft");
			f[i].s:SetPoint("TOPLEFT", f[i].d, "BOTTOMLEFT", 15, -4);
			f[i].s:SetWidth(400)
		end

		players = MonDKP_DKPHistory[i].players;
		reason = MonDKP_DKPHistory[i].reason;
		dkp = MonDKP_DKPHistory[i].dkp;
		date = MonDKP_DKPHistory[i].date;
		
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
			f[i].h:SetText(month.."/"..day.."/"..year);
			f[i].h:Show()
			curDate = day;
		else
			f[i].h:Hide()
		end
		
		if dkp > 0 then
			f[i].d:SetText("|cff00ff00"..dkp.." DKP|r ("..reason..") @ "..time);
		else
			f[i].d:SetText("|cffff0000"..dkp.." DKP|r ("..reason..") @ "..time);
		end

		f[i].d:Show()

		f[i].s:SetText(playerString);
		f[i].s:Show()

		f[i]:SetHeight(f[i].s:GetHeight() + f[i].h:GetHeight() + f[i].d:GetHeight() + 20)

		playerString = ""
		table.wipe(player_table)

		f[i]:Show()

		currentRow = currentRow + 1;
	end

	if (#MonDKP_DKPHistory - currentLength) < 50 then btnText = #MonDKP_DKPHistory - currentLength end

	if not MonDKP.ConfigTab6.history then
		f.btn = CreateFrame("Button", nil, MonDKP.ConfigTab6, "MonolithDKPButtonTemplate")
		f.btn:SetSize(100, 30);
		f.btn:SetText("Load "..btnText.." more...");
		f.btn:GetFontString():SetTextColor(1, 1, 1, 1)
		f.btn:SetNormalFontObject("MonDKPSmallCenter");
		f.btn:SetHighlightFontObject("MonDKPSmallCenter");
		f.btn:SetPoint("TOPLEFT", f[currentRow], "BOTTOMLEFT", 40, 0);
		f.btn:SetScript("OnClick", function()
			currentLength = currentLength + 50;
			MonDKP:DKPHistory_Update();
			MonDKP.ConfigTab6.history.btn:SetText("Load "..btnText.." more...")
			MonDKP.ConfigTab6.history.btn:SetPoint("TOPLEFT", f[currentRow], "BOTTOMLEFT", 40, 0)
		end)
	end

	if f.btn and currentRow == #MonDKP_DKPHistory then 
		f.btn:Hide();
	elseif f.btn and currentRow < #MonDKP_DKPHistory then
		f.btn:Show();
		f.btn:SetPoint("TOPLEFT", f[currentRow], "BOTTOMLEFT", 40, 0);
	end

	return f;
end