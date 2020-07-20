local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;


function CommDKP:DKPModes_Misc()
    local f = core.ModesWindow.DKPModesMisc;

    f.AutoAwardContainer = CommDKP:CreateContainer(f, "AutoAwardContainer", L["AUTOAWARD"])
    f.AutoAwardContainer:SetPoint("TOPLEFT", f, "TOPLEFT", 40, -40)
    f.AutoAwardContainer:SetSize(175, 50)

	    -- AutoAward DKP Checkbox
		f.AutoAwardContainer.AutoAward = CreateFrame("CheckButton", nil, f.AutoAwardContainer, "UICheckButtonTemplate");
		f.AutoAwardContainer.AutoAward:SetChecked(core.DB.modes.AutoAward)
		f.AutoAwardContainer.AutoAward:SetScale(0.6);
		f.AutoAwardContainer.AutoAward.text:SetText("  |cff5151de"..L["AUTOAWARD"].."|r");
		f.AutoAwardContainer.AutoAward.text:SetScale(1.5);
		f.AutoAwardContainer.AutoAward.text:SetFontObject("CommDKPSmallLeft")
		f.AutoAwardContainer.AutoAward:SetPoint("TOPLEFT", f.AutoAwardContainer, "TOPLEFT", 10, -10);
		f.AutoAwardContainer.AutoAward:SetScript("OnClick", function(self)
			core.DB.modes.AutoAward = self:GetChecked();
			if self:GetChecked() == false then
				f.AutoAwardContainer.IncStandby:SetChecked(false)
				core.DB.DKPBonus.AutoIncStandby = false;
			end
			PlaySound(808);
		end)
		f.AutoAwardContainer.AutoAward:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AUTOAWARD"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AUTOAWARDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.AutoAwardContainer.AutoAward:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		f.AutoAwardContainer.IncStandby = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.AutoAwardContainer.IncStandby:SetChecked(core.DB.DKPBonus.AutoIncStandby)
		f.AutoAwardContainer.IncStandby:SetScale(0.6);
		f.AutoAwardContainer.IncStandby.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
		f.AutoAwardContainer.IncStandby.text:SetScale(1.5);
		f.AutoAwardContainer.IncStandby.text:SetFontObject("CommDKPSmallLeft")
		f.AutoAwardContainer.IncStandby:SetPoint("TOP", f.AutoAwardContainer.AutoAward, "BOTTOM", 0, 0);
		f.AutoAwardContainer.IncStandby:SetScript("OnClick", function(self)
			core.DB.DKPBonus.AutoIncStandby = self:GetChecked();
			if self:GetChecked() == true then
				f.AutoAwardContainer.AutoAward:SetChecked(true)
				core.DB.modes.AutoAward = true;
			end
			PlaySound(808);
		end)
		f.AutoAwardContainer.IncStandby:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDESBYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INCLUDESBYTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.AutoAwardContainer.IncStandby:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

	-- Announce Highest Bidder Container
	f.AnnounceBidContainer = CommDKP:CreateContainer(f, "AnnounceBidContainer", L["HIGHESTBID"])
    f.AnnounceBidContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -50, -40)
    f.AnnounceBidContainer:SetSize(175, 90)

		-- Announce Highest Bid
		f.AnnounceBidContainer.AnnounceBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.AnnounceBidContainer.AnnounceBid:SetChecked(core.DB.modes.AnnounceBid)
		f.AnnounceBidContainer.AnnounceBid:SetScale(0.6);
		f.AnnounceBidContainer.AnnounceBid.text:SetText("  |cff5151de"..L["ANNOUNCEBID"].."|r");
		f.AnnounceBidContainer.AnnounceBid.text:SetScale(1.5);
		f.AnnounceBidContainer.AnnounceBid.text:SetFontObject("CommDKPSmallLeft")
		f.AnnounceBidContainer.AnnounceBid:SetPoint("TOPLEFT", f.AnnounceBidContainer, "TOPLEFT", 10, -10);
		f.AnnounceBidContainer.AnnounceBid:SetScript("OnClick", function(self)
			core.DB.modes.AnnounceBid = self:GetChecked();
			if self:GetChecked() == false then
				f.AnnounceBidContainer.AnnounceBidName:SetChecked(false)
				core.DB.modes.AnnounceBidName = false;
			end
			PlaySound(808);
		end)
		f.AnnounceBidContainer.AnnounceBid:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ANNOUNCEBID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ANNOUNCEBIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.AnnounceBidContainer.AnnounceBid:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Name Announce Highest Bid
		f.AnnounceBidContainer.AnnounceBidName = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.AnnounceBidContainer.AnnounceBidName:SetChecked(core.DB.modes.AnnounceBidName)
		f.AnnounceBidContainer.AnnounceBidName:SetScale(0.6);
		f.AnnounceBidContainer.AnnounceBidName.text:SetText("  |cff5151de"..L["INCLUDENAME"].."|r");
		f.AnnounceBidContainer.AnnounceBidName.text:SetScale(1.5);
		f.AnnounceBidContainer.AnnounceBidName.text:SetFontObject("CommDKPSmallLeft")
		f.AnnounceBidContainer.AnnounceBidName:SetPoint("TOP", f.AnnounceBidContainer.AnnounceBid, "BOTTOM", 0, 0);
		f.AnnounceBidContainer.AnnounceBidName:SetScript("OnClick", function(self)
			core.DB.modes.AnnounceBidName = self:GetChecked();
			if self:GetChecked() == true then
				f.AnnounceBidContainer.AnnounceBid:SetChecked(true)
				core.DB.modes.AnnounceBid = true;
			end
			PlaySound(808);
		end)
		f.AnnounceBidContainer.AnnounceBidName:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDENAME"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDENAMETTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.AnnounceBidContainer.AnnounceBidName:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Use Raid Warning for Announcements
		f.AnnounceBidContainer.AnnounceRaidWarning = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.AnnounceBidContainer.AnnounceRaidWarning:SetChecked(core.DB.modes.AnnounceRaidWarning)
		f.AnnounceBidContainer.AnnounceRaidWarning:SetScale(0.6);
		f.AnnounceBidContainer.AnnounceRaidWarning.text:SetText("  |cff5151de"..L["ANNOUNCEINRAIDWARNING"].."|r");  -- Translate/Localize
		f.AnnounceBidContainer.AnnounceRaidWarning.text:SetScale(1.5);
		f.AnnounceBidContainer.AnnounceRaidWarning.text:SetFontObject("CommDKPSmallLeft")
		f.AnnounceBidContainer.AnnounceRaidWarning:SetPoint("TOP", f.AnnounceBidContainer.AnnounceBidName, "BOTTOM", 0, 0);
		f.AnnounceBidContainer.AnnounceRaidWarning:SetScript("OnClick", function(self)
			core.DB.modes.AnnounceRaidWarning = self:GetChecked();
			PlaySound(808);
		end)
		f.AnnounceBidContainer.AnnounceRaidWarning:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ANNOUNCEINRAIDWARNING"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ANNOUNCEINRAIDWARNINGDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.AnnounceBidContainer.AnnounceRaidWarning:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Decline lower bids
		f.AnnounceBidContainer.DeclineLowerBids = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.AnnounceBidContainer.DeclineLowerBids:SetChecked(core.DB.modes.DeclineLowerBids)
		f.AnnounceBidContainer.DeclineLowerBids:SetScale(0.6);
		f.AnnounceBidContainer.DeclineLowerBids.text:SetText("  |cff5151de"..L["DECLINELOWBIDS"].."|r");
		f.AnnounceBidContainer.DeclineLowerBids.text:SetScale(1.5);
		f.AnnounceBidContainer.DeclineLowerBids.text:SetFontObject("CommDKPSmallLeft")
		f.AnnounceBidContainer.DeclineLowerBids:SetPoint("TOP", f.AnnounceBidContainer.AnnounceRaidWarning, "BOTTOM", 0, 0);
		f.AnnounceBidContainer.DeclineLowerBids:SetScript("OnClick", function(self)
			core.DB.modes.DeclineLowerBids = self:GetChecked();
		end)
		f.AnnounceBidContainer.DeclineLowerBids:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["DECLINELOWBIDS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["DECLINELOWBIDSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.AnnounceBidContainer.DeclineLowerBids:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

	--Misc Options Container
	f.MiscContainer = CommDKP:CreateContainer(f, "MiscContainer", L["MISCSETTINGS"])
    f.MiscContainer:SetPoint("TOPLEFT", f.AutoAwardContainer, "BOTTOMLEFT", 0, -20)
    f.MiscContainer:SetSize(175, 90)

		-- Standby On Boss Kill Checkbox
		f.MiscContainer.Standby = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.MiscContainer.Standby:SetChecked(core.DB.modes.StandbyOptIn)
		f.MiscContainer.Standby:SetScale(0.6);
		f.MiscContainer.Standby.text:SetText("  |cff5151de"..L["STANDBYOPTIN"].."|r");
		f.MiscContainer.Standby.text:SetScale(1.5);
		f.MiscContainer.Standby.text:SetFontObject("CommDKPSmallLeft")
		f.MiscContainer.Standby:SetPoint("TOPLEFT", f.MiscContainer, "TOPLEFT", 10, -10);
		f.MiscContainer.Standby:SetScript("OnClick", function(self)
			core.DB.modes.StandbyOptIn = self:GetChecked();
			PlaySound(808);
		end)
		f.MiscContainer.Standby:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["STANDBYOPTIN"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["STANDBYOPTINTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["STANDBYOPTINTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.MiscContainer.Standby:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Announce Award to Guild
		f.MiscContainer.AnnounceAward = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.MiscContainer.AnnounceAward:SetChecked(core.DB.modes.AnnounceAward)
		f.MiscContainer.AnnounceAward:SetScale(0.6);
		f.MiscContainer.AnnounceAward.text:SetText("  |cff5151de"..L["ANNOUNCEAWARD"].."|r");
		f.MiscContainer.AnnounceAward.text:SetScale(1.5);
		f.MiscContainer.AnnounceAward.text:SetFontObject("CommDKPSmallLeft")
		f.MiscContainer.AnnounceAward:SetPoint("TOP", f.MiscContainer.Standby, "BOTTOM", 0, 0);
		f.MiscContainer.AnnounceAward:SetScript("OnClick", function(self)
			core.DB.modes.AnnounceAward = self:GetChecked();
			PlaySound(808);
		end)
		f.MiscContainer.AnnounceAward:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ANNOUNCEAWARD"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ANNOUNCEAWARDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.MiscContainer.AnnounceAward:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Broadcast Bid Table to Raid
		f.MiscContainer.BroadcastBids = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.MiscContainer.BroadcastBids:SetChecked(core.DB.modes.BroadcastBids)
		f.MiscContainer.BroadcastBids:SetScale(0.6);
		f.MiscContainer.BroadcastBids.text:SetText("  |cff5151de"..L["BROADCASTBIDS"].."|r");
		f.MiscContainer.BroadcastBids.text:SetScale(1.5);
		f.MiscContainer.BroadcastBids.text:SetFontObject("CommDKPSmallLeft")
		f.MiscContainer.BroadcastBids:SetPoint("TOP", f.MiscContainer.AnnounceAward, "BOTTOM", 0, 0);
		f.MiscContainer.BroadcastBids:SetScript("OnClick", function(self)
			core.DB.modes.BroadcastBids = self:GetChecked();
			PlaySound(808);
		end)
		f.MiscContainer.BroadcastBids:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["BROADCASTBIDS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["BROADCASTBIDSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.MiscContainer.BroadcastBids:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Log Bids/Rolls
		f.MiscContainer.StoreBids = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.MiscContainer.StoreBids:SetChecked(core.DB.modes.StoreBids)
		f.MiscContainer.StoreBids:SetScale(0.6);
		f.MiscContainer.StoreBids.text:SetText("  |cff5151de"..L["LOGBIDS"].."|r");
		f.MiscContainer.StoreBids.text:SetScale(1.5);
		f.MiscContainer.StoreBids.text:SetFontObject("CommDKPSmallLeft")
		f.MiscContainer.StoreBids:SetPoint("TOP", f.MiscContainer.BroadcastBids, "BOTTOM", 0, 0);
		f.MiscContainer.StoreBids:SetScript("OnClick", function(self)
			core.DB.modes.StoreBids = self:GetChecked();
			PlaySound(808);
		end)
		f.MiscContainer.StoreBids:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["LOGBIDS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["LOGBIDSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.MiscContainer.StoreBids:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

	--DKP Award Options Container
	f.DKPAwardContainer = CommDKP:CreateContainer(f, "DKPAwardContainer", L["DKPSETTINGS"])
    f.DKPAwardContainer:SetPoint("TOPLEFT", f.AnnounceBidContainer, "BOTTOMLEFT", 0, -20)
    f.DKPAwardContainer:SetSize(175, 50)

    	-- Online Only Checkbox
	    if core.DB.modes.OnlineOnly == nil then core.DB.modes.OnlineOnly = false end
		f.DKPAwardContainer.OnlineOnly = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.DKPAwardContainer.OnlineOnly:SetChecked(core.DB.modes.OnlineOnly)
		f.DKPAwardContainer.OnlineOnly:SetScale(0.6);
		f.DKPAwardContainer.OnlineOnly.text:SetText("  |cff5151de"..L["ONLINEONLY"].."|r");
		f.DKPAwardContainer.OnlineOnly.text:SetScale(1.5);
		f.DKPAwardContainer.OnlineOnly.text:SetFontObject("CommDKPSmallLeft")
		f.DKPAwardContainer.OnlineOnly:SetPoint("TOPLEFT", f.DKPAwardContainer, "TOPLEFT", 10, -10);
		f.DKPAwardContainer.OnlineOnly:SetScript("OnClick", function(self)
			core.DB.modes.OnlineOnly = self:GetChecked();
			PlaySound(808);
		end)
		f.DKPAwardContainer.OnlineOnly:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ONLINEONLY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ONLINEONLYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.DKPAwardContainer.OnlineOnly:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Same Zone Only Checkbox
	    if core.DB.modes.SameZoneOnly == nil then core.DB.modes.SameZoneOnly = false end
		f.DKPAwardContainer.SameZoneOnly = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.DKPAwardContainer.SameZoneOnly:SetChecked(core.DB.modes.SameZoneOnly)
		f.DKPAwardContainer.SameZoneOnly:SetScale(0.6);
		f.DKPAwardContainer.SameZoneOnly.text:SetText("  |cff5151de"..L["INZONEONLY"].."|r");
		f.DKPAwardContainer.SameZoneOnly.text:SetScale(1.5);
		f.DKPAwardContainer.SameZoneOnly.text:SetFontObject("CommDKPSmallLeft")
		f.DKPAwardContainer.SameZoneOnly:SetPoint("TOP", f.DKPAwardContainer.OnlineOnly, "BOTTOM", 0, 0);
		f.DKPAwardContainer.SameZoneOnly:SetScript("OnClick", function(self)
			core.DB.modes.SameZoneOnly = self:GetChecked();
			PlaySound(808);
		end)
		f.DKPAwardContainer.SameZoneOnly:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INZONEONLY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INZONEONLYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.DKPAwardContainer.SameZoneOnly:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
end
