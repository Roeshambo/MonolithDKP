local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local curReason;

function CommDKP:AdjustDKP(value)
	local adjustReason = curReason;
	local curTime = time()
	local c;
	local curOfficer = UnitName("player")
	value = CommDKP_round(value, core.DB.modes.rounding);

	if not IsInRaid() then
		c = CommDKP:GetCColors();
	end

	if (curReason == L["OTHER"]) then adjustReason = L["OTHER"].." - "..CommDKP.ConfigTab2.otherReason:GetText(); end
	if curReason == L["BOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss; end
	if curReason == L["NEWBOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["FIRSTKILL"]..")" end
	if (#core.SelectedData > 0 and adjustReason and adjustReason ~= L["OTHER"].." - "..L["ENTEROTHERREASONHERE"]) then
		if core.IsOfficer then
			local tempString = "";       -- stores list of changes
			local dkpHistoryString = ""   -- stores list for CommDKP:GetTable(CommDKP_DKPHistory, true)
			for i=1, #core.SelectedData do
				local current;
				local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), core.SelectedData[i]["player"])
				if search then
					if not IsInRaid() then
						if i < #core.SelectedData then
							tempString = tempString.."|c"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r, ";
						else
							tempString = tempString.."|c"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r";
						end
					end
					dkpHistoryString = dkpHistoryString..core.SelectedData[i]["player"]..","
					current = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp
					CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp = CommDKP_round(tonumber(current + value), core.DB.modes.rounding)
					if value > 0 then
						CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]]["lifetime_gained"] = CommDKP_round(tonumber(CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]]["lifetime_gained"] + value), core.DB.modes.rounding)
					end
				end
			end
			local newIndex = curOfficer.."-"..curTime
			tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=dkpHistoryString, dkp=value, reason=adjustReason, date=curTime, index=newIndex})
			CommDKP.Sync:SendData("CommDKPDKPDist", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])

			if CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
				CommDKP:DKPHistory_Update(true)
			end
			CommDKP:DKPTable_Update()
			if IsInRaid() then
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..value.." "..L["FORREASON"]..": "..adjustReason)
			else
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["DKPADJUSTBY"].." "..value.." "..L["FORPLAYERS"]..": ")
				CommDKP.Sync:SendData("CommDKPBCastMsg", tempString)
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["REASON"]..": "..adjustReason)
			end
		end
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = L["PLAYERREASONVALIDATE"]
		elseif #core.SelectedData == 0 then
			validation = L["PLAYERVALIDATE"]
		elseif not adjustReason or CommDKP.ConfigTab2.otherReason:GetText() == "" or CommDKP.ConfigTab2.otherReason:GetText() == L["ENTEROTHERREASONHERE"] then
			validation = L["OTHERREASONVALIDATE"]
		end

		StaticPopupDialogs["VALIDATION_PROMPT"] = {
			text = validation,
			button1 = L["OK"],
			timeout = 5,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("VALIDATION_PROMPT")
	end
end

local function DecayDKP(amount, deductionType, GetSelections)
	local playerString = "";
	local dkpString = "";
	local curTime = time()
	local curOfficer = UnitName("player")

	for key, value in ipairs(CommDKP:GetTable(CommDKP_DKPTable, true)) do
		local dkp = tonumber(value["dkp"])
		local player = value["player"]
		local amount = amount;
		amount = tonumber(amount) / 100		-- converts percentage to a decimal
		if amount < 0 then
			amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
		end
		local deducted;

		if (GetSelections and CommDKP:Table_Search(core.SelectedData, player)) or GetSelections == false then
			if dkp > 0 then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = dkp - deducted
					value["dkp"] = CommDKP_round(tonumber(dkp), core.DB.modes.rounding);
					dkpString = dkpString.."-"..CommDKP_round(deducted, core.DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end
			elseif dkp < 0 and CommDKP.ConfigTab2.AddNegative:GetChecked() then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = (deducted - dkp) * -1
					value["dkp"] = CommDKP_round(tonumber(dkp), core.DB.modes.rounding)
					dkpString = dkpString..CommDKP_round(-deducted, core.DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end	
			end
		end
	end
	dkpString = dkpString.."-"..amount.."%";

	if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

	local newIndex = curOfficer.."-"..curTime
	tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=playerString, dkp=dkpString, reason=L["WEEKLYDECAY"], date=curTime, index=newIndex})
	CommDKP.Sync:SendData("CommDKPDecay", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])
	if CommDKP.ConfigTab6.history then
		CommDKP:DKPHistory_Update(true)
	end
	CommDKP:DKPTable_Update()
end

local function RaidTimerPopout_Create()
	if not CommDKP.RaidTimerPopout then
		CommDKP.RaidTimerPopout = CreateFrame("Frame", "CommDKP_RaidTimerPopout", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);

	    CommDKP.RaidTimerPopout:SetPoint("RIGHT", UIParent, "RIGHT", -300, 100);
	    CommDKP.RaidTimerPopout:SetSize(100, 50);
	    CommDKP.RaidTimerPopout:SetBackdrop( {
	      bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
	      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
	      insets = { left = 0, right = 0, top = 0, bottom = 0 }
	    });
	    CommDKP.RaidTimerPopout:SetBackdropColor(0,0,0,0.9);
	    CommDKP.RaidTimerPopout:SetBackdropBorderColor(1,1,1,1)
	    CommDKP.RaidTimerPopout:SetFrameStrata("DIALOG")
	    CommDKP.RaidTimerPopout:SetFrameLevel(15)
	    CommDKP.RaidTimerPopout:SetMovable(true);
	    CommDKP.RaidTimerPopout:EnableMouse(true);
	    CommDKP.RaidTimerPopout:RegisterForDrag("LeftButton");
	    CommDKP.RaidTimerPopout:SetScript("OnDragStart", CommDKP.RaidTimerPopout.StartMoving);
	    CommDKP.RaidTimerPopout:SetScript("OnDragStop", CommDKP.RaidTimerPopout.StopMovingOrSizing);

	    -- Popout Close Button
	    CommDKP.RaidTimerPopout.closeContainer = CreateFrame("Frame", "CommDKPChangeLogClose", CommDKP.RaidTimerPopout, BackdropTemplateMixin and "BackdropTemplate" or nil)
	    CommDKP.RaidTimerPopout.closeContainer:SetPoint("CENTER", CommDKP.RaidTimerPopout, "TOPRIGHT", -8, -4)
	    CommDKP.RaidTimerPopout.closeContainer:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	    });
	    CommDKP.RaidTimerPopout.closeContainer:SetBackdropColor(0,0,0,0.9)
	    CommDKP.RaidTimerPopout.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	    CommDKP.RaidTimerPopout.closeContainer:SetScale(0.7)
	    CommDKP.RaidTimerPopout.closeContainer:SetSize(28, 28)

	    CommDKP.RaidTimerPopout.closeBtn = CreateFrame("Button", nil, CommDKP.RaidTimerPopout, "UIPanelCloseButton")
	    CommDKP.RaidTimerPopout.closeBtn:SetPoint("CENTER", CommDKP.RaidTimerPopout.closeContainer, "TOPRIGHT", -14, -14)
	    CommDKP.RaidTimerPopout.closeBtn:SetScale(0.7)
	    CommDKP.RaidTimerPopout.closeBtn:HookScript("OnClick", function()
	    	CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">");
	    end)

	    -- Raid Timer Output
	    CommDKP.RaidTimerPopout.Output = CommDKP.RaidTimerPopout:CreateFontString(nil, "OVERLAY")
	    CommDKP.RaidTimerPopout.Output:SetFontObject("CommDKPLargeLeft");
	    CommDKP.RaidTimerPopout.Output:SetScale(0.8)
	    CommDKP.RaidTimerPopout.Output:SetPoint("CENTER", CommDKP.RaidTimerPopout, "CENTER", 0, 0);
	    CommDKP.RaidTimerPopout.Output:SetText("|cff00ff0000:00:00|r")
	    CommDKP.RaidTimerPopout:Hide();
	else
		CommDKP.RaidTimerPopout:Show()
	end
end

function CommDKP:AdjustDKPTab_Create()
	CommDKP.ConfigTab2.header = CommDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.header:SetPoint("TOPLEFT", CommDKP.ConfigTab2, "TOPLEFT", 15, -10);
	CommDKP.ConfigTab2.header:SetFontObject("CommDKPLargeCenter")
	CommDKP.ConfigTab2.header:SetText(L["ADJUSTDKP"]);
	CommDKP.ConfigTab2.header:SetScale(1.2)

	CommDKP.ConfigTab2.description = CommDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.description:SetPoint("TOPLEFT", CommDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	CommDKP.ConfigTab2.description:SetWidth(400)
	CommDKP.ConfigTab2.description:SetFontObject("CommDKPNormalLeft")
	CommDKP.ConfigTab2.description:SetText(L["ADJUSTDESC"]); 

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	CommDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "CommDKPConfigReasonDropDown", CommDKP.ConfigTab2, "CommunityDKPUIDropDownMenuTemplate")
	CommDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", CommDKP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	UIDropDownMenu_SetWidth(CommDKP.ConfigTab2.reasonDropDown, 150)
	UIDropDownMenu_SetText(CommDKP.ConfigTab2.reasonDropDown, L["SELECTREASON"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(CommDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "CommDKPSmallCenter"
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["ONTIMEBONUS"], L["ONTIMEBONUS"], L["ONTIMEBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["BOSSKILLBONUS"], L["BOSSKILLBONUS"], L["BOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["CORRECTINGERROR"], L["CORRECTINGERROR"], L["CORRECTINGERROR"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["DKPADJUST"], L["DKPADJUST"], L["DKPADJUST"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["OTHER"], L["OTHER"], L["OTHER"] == curReason, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function CommDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		UIDropDownMenu_SetText(CommDKP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == L["ONTIMEBONUS"]) then CommDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.OnTimeBonus); CommDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["BOSSKILLBONUS"]) then
			CommDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.BossKillBonus);
			CommDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(CommDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["RAIDCOMPLETIONBONUS"]) then CommDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.CompletionBonus); CommDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["NEWBOSSKILLBONUS"]) then
			CommDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.NewBossKillBonus);
			CommDKP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(CommDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["UNEXCUSEDABSENCE"]) then CommDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.UnexcusedAbsence); CommDKP.ConfigTab2.BossKilledDropdown:Hide()
		else CommDKP.ConfigTab2.addDKP:SetText(""); CommDKP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == L["OTHER"]) then
			CommDKP.ConfigTab2.otherReason:Show();
			CommDKP.ConfigTab2.BossKilledDropdown:Hide()
		else
			CommDKP.ConfigTab2.otherReason:Hide();
		end

		CloseDropDownMenus()
	end

	CommDKP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REASON"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REASONTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REASONTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CommDKP.ConfigTab2.reasonHeader = CommDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	CommDKP.ConfigTab2.reasonHeader:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.reasonHeader:SetText(L["REASONFORADJUSTMENT"]..":")

	-- Other Reason Editbox. Hidden unless "Other" is selected in dropdown
	CommDKP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, CommDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	CommDKP.ConfigTab2.otherReason:SetPoint("TOPLEFT", CommDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 19, 2)     
	CommDKP.ConfigTab2.otherReason:SetAutoFocus(false)
	CommDKP.ConfigTab2.otherReason:SetMultiLine(false)
	CommDKP.ConfigTab2.otherReason:SetSize(225, 24)
	CommDKP.ConfigTab2.otherReason:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CommDKP.ConfigTab2.otherReason:SetBackdropColor(0,0,0,0.9)
	CommDKP.ConfigTab2.otherReason:SetBackdropBorderColor(1,1,1,0.6)
	CommDKP.ConfigTab2.otherReason:SetMaxLetters(50)
	CommDKP.ConfigTab2.otherReason:SetTextColor(0.4, 0.4, 0.4, 1)
	CommDKP.ConfigTab2.otherReason:SetFontObject("CommDKPNormalLeft")
	CommDKP.ConfigTab2.otherReason:SetTextInsets(10, 10, 5, 5)
	CommDKP.ConfigTab2.otherReason:SetText(L["ENTEROTHERREASONHERE"])
	CommDKP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:ClearFocus()
	end)
	CommDKP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == L["ENTEROTHERREASONHERE"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	CommDKP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["ENTEROTHERREASONHERE"])
			self:SetTextColor(0.4, 0.4, 0.4, 1)
		end
	end)
	CommDKP.ConfigTab2.otherReason:Hide();

	-- Boss Killed Dropdown - Hidden unless "Boss Kill Bonus" or "New Boss Kill Bonus" is selected
	-- Killing a boss on the list will auto select that boss
	CommDKP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "CommDKPBossKilledDropdown", CommDKP.ConfigTab2, "CommunityDKPUIDropDownMenuTemplate")
	CommDKP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", CommDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	CommDKP.ConfigTab2.BossKilledDropdown:Hide()
	UIDropDownMenu_SetWidth(CommDKP.ConfigTab2.BossKilledDropdown, 210)
	UIDropDownMenu_SetText(CommDKP.ConfigTab2.BossKilledDropdown, L["SELECTBOSS"])

	UIDropDownMenu_Initialize(CommDKP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = UIDropDownMenu_CreateInfo()
		boss.fontObject = "CommDKPSmallCenter"
		if (level or 1) == 1 then
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[1], core.CurrentRaidZone == core.ZoneList[1], "MC", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[2], core.CurrentRaidZone == core.ZoneList[2], "BWL", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[3], core.CurrentRaidZone == core.ZoneList[3], "AQ", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[4], core.CurrentRaidZone == core.ZoneList[4], "NAXX", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[7], core.CurrentRaidZone == core.ZoneList[7], "ONYXIA", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[5], core.CurrentRaidZone == core.ZoneList[5], "ZG", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[6], core.CurrentRaidZone == core.ZoneList[6], "AQ20", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[8], core.CurrentRaidZone == core.ZoneList[8], "WORLD", true
			UIDropDownMenu_AddButton(boss)
		else
			boss.func = self.SetValue
			for i=1, #core.BossList[menuList] do
				boss.text, boss.arg1, boss.checked = core.BossList[menuList][i], core.EncounterList[menuList][i], core.BossList[menuList][i] == core.LastKilledBoss
				UIDropDownMenu_AddButton(boss, level)
			end
		end
	end)

	function CommDKP.ConfigTab2.BossKilledDropdown:SetValue(newValue)
		local search = CommDKP:Table_Search(core.EncounterList, newValue);
		
		if CommDKP:Table_Search(core.EncounterList.MC, newValue) then
			core.CurrentRaidZone = core.ZoneList[1]
		elseif CommDKP:Table_Search(core.EncounterList.BWL, newValue) then
			core.CurrentRaidZone = core.ZoneList[2]
		elseif CommDKP:Table_Search(core.EncounterList.AQ, newValue) then
			core.CurrentRaidZone = core.ZoneList[3]
		elseif CommDKP:Table_Search(core.EncounterList.NAXX, newValue) then
			core.CurrentRaidZone = core.ZoneList[4]
		elseif CommDKP:Table_Search(core.EncounterList.ZG, newValue) then
			core.CurrentRaidZone = core.ZoneList[5]
		elseif CommDKP:Table_Search(core.EncounterList.AQ20, newValue) then
			core.CurrentRaidZone = core.ZoneList[6]
		elseif CommDKP:Table_Search(core.EncounterList.ONYXIA, newValue) then
			core.CurrentRaidZone = core.ZoneList[7]
		--elseif CommDKP:Table_Search(core.EncounterList.WORLD, newValue) then 		-- encounter IDs not known yet
			--core.CurrentRaidZone = core.ZoneList[8]
		end

		if search then
			core.LastKilledBoss = core.BossList[search[1][1]][search[1][2]]
		else
			return;
		end

		core.DB.bossargs["LastKilledBoss"] = core.LastKilledBoss;
		core.DB.bossargs["CurrentRaidZone"] = core.CurrentRaidZone;

		if curReason ~= L["BOSSKILLBONUS"] and curReason ~= L["NEWBOSSKILLBONUS"] then
			CommDKP.ConfigTab2.reasonDropDown:SetValue(L["BOSSKILLBONUS"])
		end
		UIDropDownMenu_SetText(CommDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		CloseDropDownMenus()
	end

	-- Add DKP Edit Box
	CommDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, CommDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	CommDKP.ConfigTab2.addDKP:SetPoint("TOPLEFT", CommDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -44)     
	CommDKP.ConfigTab2.addDKP:SetAutoFocus(false)
	CommDKP.ConfigTab2.addDKP:SetMultiLine(false)
	CommDKP.ConfigTab2.addDKP:SetSize(100, 24)
	CommDKP.ConfigTab2.addDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	CommDKP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
	CommDKP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
	CommDKP.ConfigTab2.addDKP:SetMaxLetters(10)
	CommDKP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
	CommDKP.ConfigTab2.addDKP:SetFontObject("CommDKPNormalRight")
	CommDKP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
	CommDKP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText("")
		self:ClearFocus()
	end)
	CommDKP.ConfigTab2.addDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["POINTS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["POINTSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["POINTSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CommDKP.ConfigTab2.pointsHeader = CommDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	CommDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	CommDKP.ConfigTab2.pointsHeader:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.pointsHeader:SetText(L["POINTS"]..":")

	-- Raid Only Checkbox
	CommDKP.ConfigTab2.RaidOnlyCheck = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2, "UICheckButtonTemplate");
	CommDKP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
	CommDKP.ConfigTab2.RaidOnlyCheck:SetScale(0.6);
	CommDKP.ConfigTab2.RaidOnlyCheck.text:SetText("  |cff5151deShow Raid Only|r");
	CommDKP.ConfigTab2.RaidOnlyCheck.text:SetScale(1.5);
	CommDKP.ConfigTab2.RaidOnlyCheck.text:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.RaidOnlyCheck:SetPoint("LEFT", CommDKP.ConfigTab2.addDKP, "RIGHT", 15, 13);
	CommDKP.ConfigTab2.RaidOnlyCheck:Hide()
	

	-- Select All Checkbox
	CommDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2, "UICheckButtonTemplate");
	CommDKP.ConfigTab2.selectAll:SetChecked(false)
	CommDKP.ConfigTab2.selectAll:SetScale(0.6);
	CommDKP.ConfigTab2.selectAll.text:SetText("  |cff5151de"..L["SELECTALLVISIBLE"].."|r");
	CommDKP.ConfigTab2.selectAll.text:SetScale(1.5);
	CommDKP.ConfigTab2.selectAll.text:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.selectAll:SetPoint("LEFT", CommDKP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	CommDKP.ConfigTab2.selectAll:Hide();
	

		-- Adjust DKP Button
	CommDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", CommDKP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, L["ADJUSTDKP"]);
	CommDKP.ConfigTab2.adjustButton:SetSize(90,25)
	CommDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and CommDKP.ConfigTab2.otherReason:GetText() then
			local selected = L["AREYOUSURE"].." "..CommDKP_round(CommDKP.ConfigTab2.addDKP:GetNumber(), core.DB.modes.rounding).." "..L["DKPTOFOLLOWING"]..": \n\n";

			for i=1, #core.SelectedData do
				local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), core.SelectedData[i].player)

				if classSearch then
					c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)
				else
					c = { hex="ffffffff" }
				end
				if i == 1 then
					selected = selected.."|c"..c.hex..core.SelectedData[i].player.."|r"
				else
					selected = selected..", |c"..c.hex..core.SelectedData[i].player.."|r"
				end
			end
			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					CommDKP:AdjustDKP(CommDKP.ConfigTab2.addDKP:GetNumber())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
		else
			CommDKP:AdjustDKP(CommDKP.ConfigTab2.addDKP:GetNumber());
		end
	end)
	CommDKP.ConfigTab2.adjustButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADJUSTDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.adjustButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- weekly decay Editbox
	CommDKP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, CommDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	CommDKP.ConfigTab2.decayDKP:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2, "BOTTOMLEFT", 21, 70)     
	CommDKP.ConfigTab2.decayDKP:SetAutoFocus(false)
	CommDKP.ConfigTab2.decayDKP:SetMultiLine(false)
	CommDKP.ConfigTab2.decayDKP:SetSize(100, 24)
	CommDKP.ConfigTab2.decayDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	CommDKP.ConfigTab2.decayDKP:SetBackdropColor(0,0,0,0.9)
	CommDKP.ConfigTab2.decayDKP:SetBackdropBorderColor(1,1,1,0.6)
	CommDKP.ConfigTab2.decayDKP:SetMaxLetters(4)
	CommDKP.ConfigTab2.decayDKP:SetTextColor(1, 1, 1, 1)
	CommDKP.ConfigTab2.decayDKP:SetFontObject("CommDKPNormalRight")
	CommDKP.ConfigTab2.decayDKP:SetTextInsets(10, 15, 5, 5)
	CommDKP.ConfigTab2.decayDKP:SetNumber(tonumber(core.DB.DKPBonus.DecayPercentage))
	CommDKP.ConfigTab2.decayDKP:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)

	CommDKP.ConfigTab2.decayDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CommDKP.ConfigTab2.decayDKPHeader = CommDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	CommDKP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	CommDKP.ConfigTab2.decayDKPHeader:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.decayDKPHeader:SetText(L["WEEKLYDKPDECAY"]..":")

	CommDKP.ConfigTab2.decayDKPFooter = CommDKP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	CommDKP.ConfigTab2.decayDKPFooter:SetFontObject("CommDKPNormalLeft");
	CommDKP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", CommDKP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	CommDKP.ConfigTab2.decayDKPFooter:SetText("%")

	-- selected players only checkbox
	CommDKP.ConfigTab2.SelectedOnlyCheck = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2, "UICheckButtonTemplate");
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetChecked(false)
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetScale(0.6);
	CommDKP.ConfigTab2.SelectedOnlyCheck.text:SetText("  |cff5151de"..L["SELPLAYERSONLY"].."|r");
	CommDKP.ConfigTab2.SelectedOnlyCheck.text:SetScale(1.5);
	CommDKP.ConfigTab2.SelectedOnlyCheck.text:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetPoint("TOP", CommDKP.ConfigTab2.decayDKP, "BOTTOMLEFT", 15, -13);
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnClick", function(self)
		PlaySound(808)
	end)
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SELPLAYERSONLY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SELPLAYERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SELPLAYERSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- add to negative dkp checkbox
	CommDKP.ConfigTab2.AddNegative = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2, "UICheckButtonTemplate");
	CommDKP.ConfigTab2.AddNegative:SetChecked(core.DB.modes.AddToNegative)
	CommDKP.ConfigTab2.AddNegative:SetScale(0.6);
	CommDKP.ConfigTab2.AddNegative.text:SetText("  |cff5151de"..L["ADDNEGVALUES"].."|r");
	CommDKP.ConfigTab2.AddNegative.text:SetScale(1.5);
	CommDKP.ConfigTab2.AddNegative.text:SetFontObject("CommDKPSmallLeft")
	CommDKP.ConfigTab2.AddNegative:SetPoint("TOP", CommDKP.ConfigTab2.SelectedOnlyCheck, "BOTTOM", 0, 0);
	CommDKP.ConfigTab2.AddNegative:SetScript("OnClick", function(self)
		core.DB.modes.AddToNegative = self:GetChecked();
		PlaySound(808)
	end)
	CommDKP.ConfigTab2.AddNegative:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDNEGVALUES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDNEGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADDNEGTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.AddNegative:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CommDKP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", CommDKP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, L["APPLYDECAY"]);
	CommDKP.ConfigTab2.decayButton:SetSize(90,25)
	CommDKP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local SelectedToggle;
		local selected;

		if CommDKP.ConfigTab2.SelectedOnlyCheck:GetChecked() then SelectedToggle = "|cffff0000"..L["SELECTED"].."|r" else SelectedToggle = "|cffff0000"..L["ALL"].."|r" end
		selected = L["CONFIRMDECAY"].." "..SelectedToggle.." "..L["DKPENTRIESBY"].." "..CommDKP.ConfigTab2.decayDKP:GetNumber().."%%";

			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DecayDKP(CommDKP.ConfigTab2.decayDKP:GetNumber(), "percent", CommDKP.ConfigTab2.SelectedOnlyCheck:GetChecked())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
	end)
	CommDKP.ConfigTab2.decayButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["APPDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["APPDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CommDKP.ConfigTab2.decayButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Raid Timer Container
	CommDKP.ConfigTab2.RaidTimerContainer = CreateFrame("Frame", nil, CommDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil);
	CommDKP.ConfigTab2.RaidTimerContainer:SetSize(200, 360);
	CommDKP.ConfigTab2.RaidTimerContainer:SetPoint("RIGHT", CommDKP.ConfigTab2, "RIGHT", -25, -60)
	CommDKP.ConfigTab2.RaidTimerContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2, 
    });
	CommDKP.ConfigTab2.RaidTimerContainer:SetBackdropColor(0,0,0,0.9)
	CommDKP.ConfigTab2.RaidTimerContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)

		-- Pop out button
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut = CreateFrame("Button", nil, CommDKP.ConfigTab2, "UIMenuButtonStretchTemplate")
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetPoint("TOPRIGHT", CommDKP.ConfigTab2.RaidTimerContainer, "TOPRIGHT", -5, -5)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHeight(22)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetWidth(18)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetNormalFontObject("CommDKPLargeCenter")
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHighlightFontObject("CommDKPLargeCenter")
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:GetFontString():SetTextColor(0, 0.3, 0.7, 1)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScale(1.2)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameStrata("DIALOG")
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameLevel(15)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">")
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["POPOUTTIMER"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["POPOUTTIMERDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnClick", function(self)
			if self:GetText() == ">" then
				self:SetText("<");
				RaidTimerPopout_Create()
			else
				self:SetText(">");
				CommDKP.RaidTimerPopout:Hide();
			end
		end)

		-- Raid Timer Header
	    CommDKP.ConfigTab2.RaidTimerContainer.Header = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.Header:SetFontObject("CommDKPLargeLeft");
	    CommDKP.ConfigTab2.RaidTimerContainer.Header:SetScale(0.6)
	    CommDKP.ConfigTab2.RaidTimerContainer.Header:SetPoint("TOPLEFT", CommDKP.ConfigTab2.RaidTimerContainer, "TOPLEFT", 15, -15);
	    CommDKP.ConfigTab2.RaidTimerContainer.Header:SetText(L["RAIDTIMER"])

	    -- Raid Timer Output Header
	    CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetFontObject("CommDKPNormalRight");
	    CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetPoint("TOP", CommDKP.ConfigTab2.RaidTimerContainer, "TOP", -20, -40);
	    CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
	    CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Hide();

	    -- Raid Timer Output
	    CommDKP.ConfigTab2.RaidTimerContainer.Output = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.Output:SetFontObject("CommDKPLargeLeft");
	    CommDKP.ConfigTab2.RaidTimerContainer.Output:SetScale(0.8)
	    CommDKP.ConfigTab2.RaidTimerContainer.Output:SetPoint("LEFT", CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader, "RIGHT", 5, 0);

	    -- Bonus Awarded Header
	    CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetFontObject("CommDKPNormalRight");
	    CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetPoint("TOP", CommDKP.ConfigTab2.RaidTimerContainer, "TOP", -15, -60);
	    CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
	    CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Hide();

	    -- Bonus Awarded Output
	    CommDKP.ConfigTab2.RaidTimerContainer.Bonus = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetFontObject("CommDKPLargeLeft");
	    CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetScale(0.8)
	    CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetPoint("LEFT", CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader, "RIGHT", 5, 0);

	    -- Start Raid Timer Button
	    CommDKP.ConfigTab2.RaidTimerContainer.StartTimer = self:CreateButton("BOTTOMLEFT", CommDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 135, L["INITRAID"]);
		CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetSize(90,25)
		CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnClick", function(self)
			if not IsInRaid() then
				StaticPopupDialogs["NO_RAID_TIMER"] = {
					text = L["NOTINRAID"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("NO_RAID_TIMER")
				return;
			end
			if not core.RaidInProgress then				
				if core.DB.DKPBonus.GiveRaidStart and self:GetText() ~= L["CONTINUERAID"] then
					StaticPopupDialogs["START_RAID_BONUS"] = {
						text = L["RAIDTIMERBONUSCONFIRM"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()						
							local setInterval = CommDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
							local setBonus = CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
							local setOnTime = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
							local setGiveEnd = tostring(CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
							local setStandby = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
							CommDKP.Sync:SendData("CommDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
							if CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
								CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDRESUME"])
							else
								CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDSTART"])
								CommDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
							end
							CommDKP:StartRaidTimer(false)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("START_RAID_BONUS")
				else
					local setInterval = CommDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
					local setBonus = CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
					local setOnTime = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
					local setGiveEnd = tostring(CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
					local setStandby = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
					CommDKP.Sync:SendData("CommDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
					if CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
						CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDRESUME"])
					else
						CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDSTART"])
						CommDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
					end
					CommDKP:StartRaidTimer(false)
				end
			else
				StaticPopupDialogs["END_RAID"] = {
					text = L["ENDCURRAIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDTIMERCONCLUDE"].." "..CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
						CommDKP.Sync:SendData("CommDKPRaidTime", "stop")
						CommDKP:StopRaidTimer()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("END_RAID")
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INITRAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INITRAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INITRAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Pause Raid Timer Button
	    CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer = self:CreateButton("BOTTOMRIGHT", CommDKP.ConfigTab2.RaidTimerContainer, "BOTTOMRIGHT", -10, 135, L["PAUSERAID"]);
		CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetSize(90,25)
		CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnClick", function(self)
			if core.RaidInProgress then
				local setInterval = CommDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
				local setBonus = CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
				local setOnTime = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
				local setGiveEnd = tostring(CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
				local setStandby = tostring(CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());

				CommDKP.Sync:SendData("CommDKPRaidTime", "start,true "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDPAUSE"].." "..CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
				CommDKP:StartRaidTimer(true)
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["PAUSERAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["PAUSERAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["PAUSERAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Award Interval Editbox
		if not core.DB.modes.increment then core.DB.modes.increment = 60 end
		CommDKP.ConfigTab2.RaidTimerContainer.interval = CreateFrame("EditBox", nil, CommDKP.ConfigTab2.RaidTimerContainer, BackdropTemplateMixin and "BackdropTemplate" or nil)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 35, 225)     
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetAutoFocus(false)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetMultiLine(false)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetSize(60, 24)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropColor(0,0,0,0.9)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropBorderColor(1,1,1,0.6)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetMaxLetters(5)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetTextColor(1, 1, 1, 1)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetFontObject("CommDKPSmallRight")
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetTextInsets(10, 15, 5, 5)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(core.DB.modes.increment))
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				core.DB.modes.increment = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFocus()
			CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:HighlightText()
		end)

		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDINTERVAL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CommDKP.ConfigTab2.RaidTimerContainer.intervalHeader = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetFontObject("CommDKPTinyRight");
	    CommDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.RaidTimerContainer.interval, "TOPLEFT", 0, 2);
	    CommDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetText(L["INTERVAL"]..":")

	    -- Award Value Editbox
	    if not core.DB.DKPBonus.IntervalBonus then core.DB.DKPBonus.IntervalBonus = 15 end
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue = CreateFrame("EditBox", nil, CommDKP.ConfigTab2.RaidTimerContainer, BackdropTemplateMixin and "BackdropTemplate" or nil)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetPoint("LEFT", CommDKP.ConfigTab2.RaidTimerContainer.interval, "RIGHT", 10, 0)     
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetAutoFocus(false)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMultiLine(false)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetSize(60, 24)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropColor(0,0,0,0.9)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropBorderColor(1,1,1,0.6)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMaxLetters(5)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextColor(1, 1, 1, 1)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFontObject("CommDKPSmallRight")
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextInsets(10, 15, 5, 5)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(core.DB.DKPBonus.IntervalBonus))
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				core.DB.DKPBonus.IntervalBonus = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			CommDKP.ConfigTab2.RaidTimerContainer.interval:SetFocus()
			CommDKP.ConfigTab2.RaidTimerContainer.interval:HighlightText()
		end)

		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CommDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetFontObject("CommDKPTinyRight");
	    CommDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.RaidTimerContainer.bonusvalue, "TOPLEFT", 0, 2);
	    CommDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetText(L["BONUS"]..":")
    	
    	-- Give On Time Bonus Checkbox
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(core.DB.DKPBonus.GiveRaidStart)
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScale(0.6);
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetText("  |cff5151de"..L["GIVEONTIMEBONUS"].."|r");
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetScale(1.5);
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetFontObject("CommDKPSmallLeft")
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetPoint("TOPLEFT", CommDKP.ConfigTab2.RaidTimerContainer.interval, "BOTTOMLEFT", 0, -10);
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.GiveRaidStart = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.GiveRaidStart = false;
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEONTIMEBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEONTIMETTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Give Raid End Bonus Checkbox
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(core.DB.DKPBonus.GiveRaidEnd)
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScale(0.6);
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetText("  |cff5151de"..L["GIVEENDBONUS"].."|r");
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetScale(1.5);
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetFontObject("CommDKPSmallLeft")
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetPoint("TOP", CommDKP.ConfigTab2.RaidTimerContainer.StartBonus, "BOTTOM", 0, 2);
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.GiveRaidEnd = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.GiveRaidEnd = false;
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEENDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEENDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude = CreateFrame("CheckButton", nil, CommDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(core.DB.DKPBonus.IncStandby)
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScale(0.6);
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetScale(1.5);
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetFontObject("CommDKPSmallLeft")
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetPoint("TOP", CommDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus, "BOTTOM", 0, 2);
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.IncStandby = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.IncStandby = false;
			end
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CommDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CommDKP.ConfigTab2.RaidTimerContainer.TimerWarning = CommDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CommDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetFontObject("CommDKPTinyLeft");
	    CommDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetWidth(180)
	    CommDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetPoint("BOTTOMLEFT", CommDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 10);
	    CommDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetText("|CFFFF0000"..L["TIMERWARNING"].."|r")
	    RaidTimerPopout_Create()
end
