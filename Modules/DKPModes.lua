local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP:ToggleDKPModesWindow()
	if core.IsOfficer == true then
		if not core.ModesWindow then
			core.ModesWindow =  MonDKP:DKPModesFrame_Create();

			-- Populate Tabs
			MonDKP:DKPModes_Main()
			MonDKP:DKPModes_Misc()
		end
	 	core.ModesWindow:SetShown(not core.ModesWindow:IsShown())
	 	core.ModesWindow:SetFrameLevel(10)
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
		if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end
	else
		MonDKP:Print(L["NOPERMISSION"])
	end
end

function MonDKP:DKPModesFrame_Create()
	local f = CreateFrame("Frame", "MonDKP_DKPModesFrame", UIParent);
	local ActiveMode = MonDKP_DB.modes.mode;
	local ActiveCostType = MonDKP_DB.modes.costvalue;

	if not core.IsOfficer then
		MonDKP:Print(L["NOPERMISSION"])
		return
	end

	f:SetClampedToScreen(true)
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(473, 598);
	f:SetBackdrop( {
	edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
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
	if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	f.BG = f:CreateTexture(nil, "OVERLAY", nil);
	f.BG:SetColorTexture(0, 0, 0, 1)
	f.BG:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2);
	f.BG:SetSize(475, 600);
	f.BG:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\menu-bg");

	-- TabMenu ScrollFrame and ScrollBar
	f.ScrollFrame = CreateFrame("ScrollFrame", nil, f);
	f.ScrollFrame:ClearAllPoints();
	f.ScrollFrame:SetPoint("TOPLEFT",  f, "TOPLEFT", 4, -8);
	f.ScrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 4);
	f.ScrollFrame:SetClipsChildren(false);
	f.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);

	f.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, f.ScrollFrame, "UIPanelScrollBarTrimTemplate")
	f.ScrollFrame.ScrollBar:ClearAllPoints();
	f.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", f.ScrollFrame, "TOPRIGHT", -20, -12);
	f.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", f.ScrollFrame, "BOTTOMRIGHT", -2, 15);

	f.DKPModesMain, f.DKPModesMisc = MonDKP:SetTabs(f, 2, 475, 600, "Modes", "Misc");
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	-- Close Button
	f.closeContainer = CreateFrame("Frame", "MonDKModesWindowCloseButtonContainer", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
	f:Hide()

	f:SetScript("OnHide", function()
		MonDKP_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
		MonDKP_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
		MonDKP_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()

		if (MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max and MonDKP_DB.modes.rolls.max ~= 0 and MonDKP_DB.modes.rolls.UserPerc == false) or (MonDKP_DB.modes.rolls.UsePerc and (MonDKP_DB.modes.rolls.min < 0 or MonDKP_DB.modes.rolls.max > 100 or MonDKP_DB.modes.rolls.min > MonDKP_DB.modes.rolls.max)) then
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