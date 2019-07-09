local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

function MonDKP:ToggleBidWindow()
	core.BiddingWindow = core.BiddingWindow or MonDKP:CreateBidWindow();
 	core.BiddingWindow:SetShown(not core.BiddingWindow:IsShown())
end

function MonDKP:StartBidTimer(seconds, ...)
	local duration = seconds
	local title = ...;
	local alpha = 1;

	MonDKP.BidTimer = MonDKP.BidTimer or MonDKP:CreateTimer();		-- recycles bid timer frame so multiple instances aren't created
	MonDKP.BidTimer:SetShown(not MonDKP.BidTimer:IsShown())					-- shows if not shown
	MonDKP.BidTimer:SetMinMaxValues(0, duration)
	MonDKP.BidTimer.timerTitle:SetText(...)


	if MonDKP_DB.timerpos then
		local a = MonDKP_DB["timerpos"]										-- retrieves timer's saved position from SavedVariables
		MonDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		MonDKP.BidTimer:SetPoint("CENTER")											-- sets to center if no position has been saved
	end

	local timer = 0
	local timerText;
	local modulo
	local timerMinute
	local messageSent = { false, false, false, false, false, false }
	local expiring;

	MonDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		timerText = round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			MonDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			MonDKP.BidTimer.timertext:SetText(timerText)
		end
		if duration >= 120 then
			expiring = 30;
		else
			expiring = 10;
		end
		if tonumber(timerText) < expiring then
			MonDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			MonDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end
		
		if tonumber(timerText) == 10 and messageSent[1] == false then
			MonDKP:Print("10 Seconds left to bid!")
			messageSent[1] = true;
		end
		if tonumber(timerText) == 5 and messageSent[2] == false then
			MonDKP:Print("5")
			messageSent[2] = true;
		end
		if tonumber(timerText) == 4 and messageSent[3] == false then
			MonDKP:Print("4")
			messageSent[3] = true;
		end
		if tonumber(timerText) == 3 and messageSent[4] == false then
			MonDKP:Print("3")
			messageSent[4] = true;
		end
		if tonumber(timerText) == 2 and messageSent[5] == false then
			MonDKP:Print("2")
			messageSent[5] = true;
		end
		if tonumber(timerText) == 1 and messageSent[6] == false then
			MonDKP:Print("1")
			messageSent[6] = true;
		end
		self:SetValue(timer)
		if timer >= duration then
			MonDKP.BidTimer:Hide();
			MonDKP:Print("Bidding closed!")
		end
	end)
end

function MonDKP:CreateTimer()

	local f = CreateFrame("StatusBar", nil, UIParent)
	f:SetSize(250, 20)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(18)
	f:SetBackdrop({
	    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground", tile = true,
	  });
	f:SetBackdropColor(0, 0, 0, 0.7)
	f:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing();
		local point, _, relativePoint ,xOff,yOff = f:GetPoint(1)
		if not MonDKP_DB.timerpos then
			MonDKP_DB.timerpos = {}
		end
		MonDKP_DB.timerpos["point"] = point;
		MonDKP_DB.timerpos["relativePoint"] = relativePoint;
		MonDKP_DB.timerpos["x"] = xOff;
		MonDKP_DB.timerpos["y"] = yOff;
	end);

	f.border = CreateFrame("Frame", nil, f);
	f.border:SetPoint("CENTER", f, "CENTER");
	f.border:SetFrameStrata("DIALOG")
	f.border:SetFrameLevel(19)
	f.border:SetSize(250, 20);
	f.border:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.border:SetBackdropColor(0,0,0,0);
	f.border:SetBackdropBorderColor(1,1,1,1)

	f.timerTitle = f:CreateFontString(nil, "OVERLAY")
	f.timerTitle:SetFontObject("MonDKPTinyRight")
	f.timerTitle:SetTextColor(1, 1, 1, 1);
	f.timerTitle:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2);
	f.timerTitle:SetText(nil);
		
	f.timertext = f:CreateFontString(nil, "OVERLAY")
	f.timertext:SetFontObject("MonDKPTinyRight")
	f.timertext:SetTextColor(1, 1, 1, 1);
	f.timertext:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -2);
	f.timertext:SetText(nil);
	f:Hide()

	return f;
end

function MonDKP:CreateBidWindow()
	local f = CreateFrame("Frame", "MonDKP_BiddingWindow", UIParent);
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(400, 500);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"
	f:Hide()

	return f;
end