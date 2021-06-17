local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local function ZeroSumDistribution()
	if IsInRaid() and core.IsOfficer then
		local curTime = time();
		local distribution, balance;
		local reason = core.DB.bossargs.CurrentRaidZone..": "..core.DB.bossargs.LastKilledBoss
		local players = "";
		local VerifyTable = {};
		local curOfficer = UnitName("player")

		if core.DB.modes.ZeroSumStandby then
			for i=1, #CommDKP:GetTable(CommDKP_Standby, true) do
				tinsert(VerifyTable, CommDKP:GetTable(CommDKP_Standby, true)[i].player)
			end
		end		

		for i=1, 40 do
			local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
			local search = CommDKP:Table_Search(VerifyTable, tempName)
			local search2 = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), tempName)
			local OnlineOnly = core.DB.modes.OnlineOnly
			local limitToZone = core.DB.modes.SameZoneOnly
			local isSameZone = zone == GetRealZoneText()

			if not search and search2 and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
				tinsert(VerifyTable, tempName)
			end
		end

		balance = tonumber(core.ZeroSumBank.Balance:GetText())
		distribution = CommDKP_round(balance / #VerifyTable, core.DB.modes.rounding) + core.DB.modes.Inflation

		for i=1, #VerifyTable do
			local name = VerifyTable[i]
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name)

			if search then
				CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp + distribution
				players = players..name..","
			end
		end
		
		local newIndex = curOfficer.."-"..curTime
		tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=players, dkp=distribution, reason=reason, date=curTime, index=newIndex})
		if CommDKP.ConfigTab6.history then
			CommDKP:DKPHistory_Update(true)
		end

		CommDKP.Sync:SendData("CommDKPDKPDist", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])
		CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..distribution.." "..L["AMONG"].." "..#VerifyTable.." "..L["PLAYERSFORREASON"]..": "..reason)
		CommDKP:Print("Raid DKP Adjusted by "..distribution.." "..L["AMONG"].." "..#VerifyTable.." "..L["PLAYERSFORREASON"]..": "..reason)
		
		table.wipe(VerifyTable)
		table.wipe(core.DB.modes.ZeroSumBank)
		core.DB.modes.ZeroSumBank.balance = 0
		core.ZeroSumBank.LootFrame.LootList:SetText("")
		CommDKP:DKPTable_Update()
		CommDKP.Sync:SendData("CommDKPZSumBank", core.DB.modes.ZeroSumBank)
		CommDKP:ZeroSumBank_Update()
		core.ZeroSumBank:Hide();
	else
		CommDKP:Print(L["NOTINRAIDPARTY"])
	end
end

function CommDKP:ZeroSumBank_Update()
	core.ZeroSumBank.Boss:SetText(core.DB.bossargs.LastKilledBoss.." in "..core.DB.bossargs.CurrentRaidZone)
	core.ZeroSumBank.Balance:SetText(core.DB.modes.ZeroSumBank.balance)

	for i=1, #core.DB.modes.ZeroSumBank do
 		if i==1 then
 			core.ZeroSumBank.LootFrame.LootList:SetText(core.DB.modes.ZeroSumBank[i].loot.." "..L["FOR"].." "..core.DB.modes.ZeroSumBank[i].cost.." "..L["DKP"].."\n")
 		else
 			core.ZeroSumBank.LootFrame.LootList:SetText(core.ZeroSumBank.LootFrame.LootList:GetText()..core.DB.modes.ZeroSumBank[i].loot.." "..L["FOR"].." "..core.DB.modes.ZeroSumBank[i].cost.." "..L["DKP"].."\n")
 		end
 	end
 	
 	if core.ZeroSumBank.LootFrame.LootList:GetHeight() > 180 then
 		core.ZeroSumBank.LootFrame:SetHeight(core.ZeroSumBank.LootFrame.LootList:GetHeight() + 18)
 		core.ZeroSumBank:SetHeight(350 + core.ZeroSumBank.LootFrame.LootList:GetHeight() - 170)
 	end
end

function CommDKP:ZeroSumBank_Create()

	local f;

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f = CreateFrame("Frame", "CommDKP_DKPZeroSumBankFrame", UIParent, "ShadowOverlaySmallTemplate");
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f = CreateFrame("Frame", "CommDKP_DKPZeroSumBankFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end
	
	if not core.DB.modes.ZeroSumBank then core.DB.modes.ZeroSumBank = 0 end

	f:SetPoint("TOP", UIParent, "TOP", 400, -50);
	f:SetSize(325, 350);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("FULLSCREEN")
	f:SetFrameLevel(20)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:Hide()

	-- Close Button

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.closeContainer = CreateFrame("Frame", "CommDKPZeroSumBankWindowCloseButtonContainer", f)
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.closeContainer = CreateFrame("Frame", "CommDKPZeroSumBankWindowCloseButtonContainer", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton", BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

	f.BankHeader = f:CreateFontString(nil, "OVERLAY")
	f.BankHeader:SetFontObject("CommDKPLargeLeft");
	f.BankHeader:SetScale(1)
	f.BankHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10);
	f.BankHeader:SetText(L["ZEROSUMBANK"])

	f.Boss = f:CreateFontString(nil, "OVERLAY")
	f.Boss:SetFontObject("CommDKPSmallLeft");
	f.Boss:SetPoint("TOPLEFT", f, "TOPLEFT", 60, -45);

	f.Boss.Header = f:CreateFontString(nil, "OVERLAY")
	f.Boss.Header:SetFontObject("CommDKPLargeRight");
	f.Boss.Header:SetScale(0.7)
	f.Boss.Header:SetPoint("RIGHT", f.Boss, "LEFT", -7, 0);
	f.Boss.Header:SetText(L["BOSS"]..": ")

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.Balance = CreateFrame("EditBox", nil, f)
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.Balance = CreateFrame("EditBox", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.Balance:SetPoint("TOPLEFT", f, "TOPLEFT", 70, -65)   
    f.Balance:SetAutoFocus(false)
    f.Balance:SetMultiLine(false)
    f.Balance:SetSize(85, 28)
    f.Balance:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.Balance:SetBackdropColor(0,0,0,0.9)
    f.Balance:SetBackdropBorderColor(1,1,1,0.4)
    f.Balance:SetMaxLetters(10)
    f.Balance:SetTextColor(1, 1, 1, 1)
    f.Balance:SetFontObject("CommDKPSmallLeft")
    f.Balance:SetTextInsets(10, 10, 5, 5)
    f.Balance:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    f.Balance:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ZEROSUMBALANCE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ZEROSUMBALANCETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.Balance:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.Balance.Header = f:CreateFontString(nil, "OVERLAY")
	f.Balance.Header:SetFontObject("CommDKPLargeRight");
	f.Balance.Header:SetScale(0.7)
	f.Balance.Header:SetPoint("RIGHT", f.Balance, "LEFT", -7, 0);
	f.Balance.Header:SetText(L["BALANCE"]..": ")

	f.Distribute = CreateFrame("Button", "CommDKPBiddingDistributeButton", f, "CommunityDKPButtonTemplate")
	f.Distribute:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -95);
	f.Distribute:SetSize(90, 25);
	f.Distribute:SetText(L["DISTRIBUTEDKP"]);
	f.Distribute:GetFontString():SetTextColor(1, 1, 1, 1)
	f.Distribute:SetNormalFontObject("CommDKPSmallCenter");
	f.Distribute:SetHighlightFontObject("CommDKPSmallCenter");
	f.Distribute:SetScript("OnClick", function (self)
		if core.DB.modes.ZeroSumBank.balance > 0 or tonumber(f.Balance:GetText()) > 0 then
			StaticPopupDialogs["CONFIRM_ADJUST1"] = {
				text = L["DISTRIBUTEALLDKPCONF"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					ZeroSumDistribution()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_ADJUST1")
		else
			CommDKP:Print(L["NOPOINTSTODISTRIBUTE"])
		end
	end)
	f.Distribute:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DISTRIBUTEDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DISTRUBUTEBANKED"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.Distribute:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Include Standby Checkbox
	f.IncludeStandby = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.IncludeStandby:SetChecked(core.DB.modes.ZeroSumStandby)
	f.IncludeStandby:SetScale(0.6);
	f.IncludeStandby.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
	f.IncludeStandby.text:SetScale(1.5);
	f.IncludeStandby.text:SetFontObject("CommDKPSmallLeft")
	f.IncludeStandby:SetPoint("TOPLEFT", f.Distribute, "BOTTOMLEFT", -15, -10);
	f.IncludeStandby:SetScript("OnClick", function(self)
		core.DB.modes.ZeroSumStandby = self:GetChecked();
		PlaySound(808)
	end)
	f.IncludeStandby:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["INCLUDESTANDBYLIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["INCSTANDBYLISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["INCSTANDBYLISTTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.IncludeStandby:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Loot List Frame

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.LootFrame = CreateFrame("Frame", "CommDKPZeroSumBankLootListContainer", f, "ShadowOverlaySmallTemplate")
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.LootFrame = CreateFrame("Frame", "CommDKPZeroSumBankLootListContainer", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.LootFrame:SetPoint("TOPRIGHT", f.IncludeStandby, "BOTTOM", 95, -5)
	f.LootFrame:SetSize(305, 190)
	f.LootFrame:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.LootFrame:SetBackdropColor(0,0,0,0.9)
	f.LootFrame:SetBackdropBorderColor(1,1,1,1)

	f.LootFrame.Header = f.LootFrame:CreateFontString(nil, "OVERLAY")
	f.LootFrame.Header:SetFontObject("CommDKPLargeLeft");
	f.LootFrame.Header:SetScale(0.7)
	f.LootFrame.Header:SetPoint("TOPLEFT", f.LootFrame, "TOPLEFT", 8, -8);
	f.LootFrame.Header:SetText(L["LOOTBANKED"])

	f.LootFrame.LootList = f.LootFrame:CreateFontString(nil, "OVERLAY")
	f.LootFrame.LootList:SetFontObject("CommDKPNormalLeft");
	f.LootFrame.LootList:SetPoint("TOPLEFT", f.LootFrame, "TOPLEFT", 8, -18);
	f.LootFrame.LootList:SetText("")

	return f
end
