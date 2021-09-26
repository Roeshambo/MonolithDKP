local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

function CommDKP:ToggleDKPModesWindow()
	if core.IsOfficer == true then
		if not core.ModesWindow then
			core.ModesWindow =  CommDKP:DKPModesFrame_Create();

			-- Populate Tabs
			CommDKP:DKPModes_Main()
			CommDKP:DKPModes_Misc()
		end
	 	core.ModesWindow:SetShown(not core.ModesWindow:IsShown())
	 	core.ModesWindow:SetFrameLevel(10)
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
		if CommDKP.UIConfig then CommDKP.UIConfig:SetFrameLevel(2) end
	else
		CommDKP:Print(L["NOPERMISSION"])
	end
end

function CommDKP:DKPModesFrame_Create()

	local f;

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f = CreateFrame("Frame", "CommDKP_DKPModesFrame", UIParent);
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f = CreateFrame("Frame", "CommDKP_DKPModesFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end
	
	local ActiveMode = core.DB.modes.mode;
	local ActiveCostType = core.DB.modes.costvalue;

	if not core.IsOfficer then
		CommDKP:Print(L["NOPERMISSION"])
		return
	end

	f:SetClampedToScreen(true)
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(473, 598);
	f:SetBackdrop( {
	edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:SetScript("OnMouseDown", function(self)
	self:SetFrameLevel(10)
	if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
	if CommDKP.UIConfig then CommDKP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	f.BG = f:CreateTexture(nil, "OVERLAY", nil);
	f.BG:SetColorTexture(0, 0, 0, 1)
	f.BG:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2);
	f.BG:SetSize(475, 600);
	f.BG:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\menu-bg");

	-- TabMenu ScrollFrame and ScrollBar

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.ScrollFrame = CreateFrame("ScrollFrame", nil, f);
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.ScrollFrame = CreateFrame("ScrollFrame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end
	
	f.ScrollFrame:ClearAllPoints();
	f.ScrollFrame:SetPoint("TOPLEFT",  f, "TOPLEFT", 4, -8);
	f.ScrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 4);
	f.ScrollFrame:SetClipsChildren(false);
	f.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);

	f.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, f.ScrollFrame, "UIPanelScrollBarTrimTemplate")
	f.ScrollFrame.ScrollBar:ClearAllPoints();
	f.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", f.ScrollFrame, "TOPRIGHT", -20, -12);
	f.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", f.ScrollFrame, "BOTTOMRIGHT", -2, 15);

	f.DKPModesMain, f.DKPModesMisc = CommDKP:SetTabs(f, 2, 475, 600, "Modes", "Misc");
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	-- Close Button
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.closeContainer = CreateFrame("Frame", "MonDKModesWindowCloseButtonContainer", f)
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		f.closeContainer = CreateFrame("Frame", "MonDKModesWindowCloseButtonContainer", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
	f:Hide()

	f:SetScript("OnHide", function()
		core.DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
		core.DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
		core.DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()

		if (core.DB.modes.rolls.min > core.DB.modes.rolls.max and core.DB.modes.rolls.max ~= 0 and core.DB.modes.rolls.UserPerc == false) or (core.DB.modes.rolls.UsePerc and (core.DB.modes.rolls.min < 0 or core.DB.modes.rolls.max > 100 or core.DB.modes.rolls.min > core.DB.modes.rolls.max)) then
			StaticPopupDialogs["NOTIFY_ROLLS"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["INVALIDROLLPARAM"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("NOTIFY_ROLLS")
			f:Show()
			return;
		end
	end)
	return f;
end
