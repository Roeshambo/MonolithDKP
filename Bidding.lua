local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

local Bids_Submitted = {};
local upper = string.upper
local width, height, numrows = 370, 18, 13
local CurrItemForBid;
local CurrItemIcon;
local SelectedBidder = {}
local CurZone;

local function UpdateBidWindow()
	core.BiddingWindow.item:SetText(CurrItemForBid)
	core.BiddingWindow.itemIcon:SetTexture(CurrItemIcon)
end

local function BidCmd(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	end

	return cmd;
end

function MonDKP_CHAT_MSG_WHISPER(text, ...)
	local name = ...;
	local cmd;
	local dkp;
	local response;

	if string.find(text, "!bid") == 1 then
		if core.BidInProgress then
			cmd = BidCmd(text)
			if string.find(name, "-") then					-- finds and removes server name from name if exists
				local dashPos = string.find(name, "-")
				name = strsub(name, 1, dashPos-1)
				print(name)
			end
			if tonumber(cmd) then
				dkp = tonumber(MonDKP:GetPlayerDKP(name))
				if dkp then
					if cmd <= dkp then
						if tonumber(core.BiddingWindow.minBid:GetNumber()) <= cmd then
							for i=1, #Bids_Submitted do 					-- checks if a bid was submitted, removes last bid if it was
								if Bids_Submitted[i] and Bids_Submitted[i].player == name then
									table.remove(Bids_Submitted, i)
								end
							end

							table.insert(Bids_Submitted, {player=name, bid=cmd})
							response = "Your bid of "..cmd.." DKP was Accepted."
							BidScrollFrame_Update()
						else
							response = "Bid Denied! Below minimum bid!"
						end
					else
						response = "Bid Denied! You only have "..dkp.." DKP"
					end
				end
			elseif not cmd then
				response = "Bid Denied! No value given for bid."
				print(cmd)
			else
				response = "Bid Denied! Invalid Bid Received."
			end
			SendChatMessage(response, "WHISPER", nil, name)
		else
			SendChatMessage("No Bids in Progress", "WHISPER", nil, name)
		end	
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)			-- suppresses outgoing whisper responses to limit spam
		if strfind(msg, "Bid Accepted!") then
			return true
		elseif strfind(msg, "Your bid of") then
			return true
		elseif strfind(msg, "Bid Denied!") then
			return true
		end
	end)
end

local function GetMinBid(itemName)
	local minbid
	for i=1, #MonDKP_MinBids do
		if MonDKP_MinBids[i].item == itemName then
			minbid = MonDKP_MinBids[i].minbid

			return minbid;
		end
	end
	return false;
end

function MonDKP:ToggleBidWindow(loot, lootIcon, itemName)
	local minBid;
	core.BiddingWindow = core.BiddingWindow or MonDKP:CreateBidWindow();
 	core.BiddingWindow:SetShown(true)
	
 	if loot then
 		CurrItemForBid = loot;
 		CurrItemIcon = lootIcon
 		CurZone = GetRealZoneText()
 		core.BossKilled = GetUnitName("target")
 		minBid = GetMinBid(itemName) or 70
 		core.BiddingWindow.minBid:SetText(minBid)
 		core.BiddingWindow.itemName:SetText(itemName)
 		core.BiddingWindow.bidTimer:SetText(core.settings["DKPBonus"]["BidTimer"])
 		core.BiddingWindow.cost:SetText(minBid)
 		core.BiddingWindow.boss:SetText(core.BossKilled.." in "..CurZone)
 	end
 	UpdateBidWindow()
 	BidScrollFrame_Update()
end

local function StartBidding()
	if not core.BiddingWindow.item:GetText() or core.BiddingWindow.minBid:GetText() == "" then return false end	-- stops the function if either an item or minBid is not selected

	MonDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), "Bidding on "..core.BiddingWindow.item:GetText().." |cff00ff00Min Bid: "..core.BiddingWindow.minBid:GetText().."|r")
	local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
	if not search then
		tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.minBid:GetText()})
	else
		MonDKP_MinBids[search[1][1]].minbid = core.BiddingWindow.minBid:GetText();
	end
	core.BidInProgress = true;
end

local function ClearBidWindow()
	CurrItemForBid = "";
	CurrItemIcon = "";
	Bids_Submitted = {}
	SelectedBidder = {}
	BidScrollFrame_Update()
	UpdateBidWindow()
	core.BiddingWindow.minBid:SetText("")
	for i=1, numrows do
		core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	end
end

local function AwardItem()
	local cost;
	local winner;
	local date;

	if SelectedBidder["player"] then
		cost = core.BiddingWindow.cost:GetNumber();
		winner = SelectedBidder["player"];
		date = MonDKP:CurrentTime()
		
		MonDKP:DKPTable_Set(winner, "dkp", -cost)
		tinsert(MonDKP_Loot, {player=winner, loot=CurrItemForBid, zone=CurZone, date=date, boss=core.BossKilled, cost=cost})
		local temp_table = {}
		tinsert(temp_table, {player=winner, loot=CurrItemForBid, zone=CurZone, date=date, boss=core.BossKilled, cost=cost})
		ClearBidWindow();
		MonDKP:LootHistory_Reset();
		MonDKP:LootHistory_Update("No Filter")
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
		MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])
		table.wipe(temp_table)
	end
end

function MonDKP:BroadcastBidTimer(seconds, ...)       -- broadcasts timer and starts it natively
	local title = ...;
	MonDKP:StartBidTimer(seconds, ...)
	MonDKP.Sync:SendData("MonDKPNotify", "StartBidTimer,"..seconds..","..title)
end

function MonDKP_Register_ShiftClickLootWindowHook()			-- hook function into LootFrame window (BREAKS if more than 4 loot slots shown at a time)
	for i = 1, 4 do 
		getglobal("LootButton"..i):HookScript("OnClick", function()
	        if ( IsShiftKeyDown() and IsAltKeyDown() ) then
        		lootIcon, itemName, _, _, _ = GetLootSlotInfo(i)
        		itemLink = GetLootSlotLink(i)
	            MonDKP:ToggleBidWindow(itemLink, lootIcon, itemName)
	        end
		end)
	end
end

-- if GetNumLootItems() > 4 run a separate function with numloot if interface allows more than 4 to be shown?

function MonDKP:StartBidTimer(seconds, ...)
	local duration = tonumber(seconds)
	local title = ...;
	local alpha = 1;

	MonDKP.BidTimer = MonDKP.BidTimer or MonDKP:CreateTimer();		-- recycles bid timer frame so multiple instances aren't created
	MonDKP.BidTimer:SetShown(not MonDKP.BidTimer:IsShown())					-- shows if not shown
	MonDKP.BidTimer:SetMinMaxValues(0, duration or 20)
	MonDKP.BidTimer.timerTitle:SetText(...)
	PlaySound(8959)

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
	local audioPlayed = false;

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
			if audioPlayed == false then
	        	PlaySound(23639);
	        end
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
			core.BidInProgress = false;
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

	return f;
end

local function BidRowOnClick(self)
	for i=1, numrows do
		core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
		core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
	end
    self:SetNormalTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
    self:GetNormalTexture():SetAlpha(1)

    SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 11, -3), bid=tonumber(self.Strings[2]:GetText())}			-- strsub required to strip class color |cff000000 |r text
end

function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.Strings = {}
    f:SetSize(width, height)
    f:SetHighlightTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    f:SetScript("OnClick", BidRowOnClick)
    for i=1, 3 do
        f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
        f.Strings[i]:SetFontObject("GameFontHighlight");
        f.Strings[i]:SetTextColor(1, 1, 1, 1);
    end
    f.Strings[1]:SetPoint("LEFT", 30, 0)
    f.Strings[2]:SetPoint("CENTER")
    f.Strings[3]:SetPoint("RIGHT", -50, 0)
    return f
end

local function SortBidTable()             -- sorts the Loot History Table by date
  table.sort(Bids_Submitted, function(a, b)
    return a["bid"] > b["bid"]
  end)
end

function BidScrollFrame_Update()
	local numOptions = #Bids_Submitted;
	local index, row
    local offset = FauxScrollFrame_GetOffset(core.BiddingWindow.bidTable) or 0
    SortBidTable()
    for i=1, numrows do
    	row = core.BiddingWindow.bidTable.Rows[i]
    	row:Hide()
    end
    for i=1, #Bids_Submitted do
        row = core.BiddingWindow.bidTable.Rows[i]
        index = offset + i
        local dkp_total = MonDKP:Table_Search(MonDKP_DKPTable, Bids_Submitted[i].player)
        local c = MonDKP:GetCColors(MonDKP_DKPTable[dkp_total[1][1]].class)
        if Bids_Submitted[index] then
            row:Show()
            row.index = index
            row.Strings[1]:SetText("|cff"..c.hex..Bids_Submitted[i].player.."|r")
            row.Strings[2]:SetText(Bids_Submitted[i].bid)
            row.Strings[3]:SetText(MonDKP_DKPTable[dkp_total[1][1]].dkp)
        else
            row:Hide()
        end
    end
    if Bids_Submitted[2] then
    	core.BiddingWindow.cost:SetText(Bids_Submitted[2].bid)
    end
    FauxScrollFrame_Update(core.BiddingWindow.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function MonDKP:CreateBidWindow()
	local f = CreateFrame("Frame", "MonDKP_BiddingWindow", UIParent, "ShadowOverlaySmallTemplate");
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(400, 500);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:SetScript("OnHide", function ()
		MonDKP:Print("Bid Window Closed. Type /dkp bid to reopen to current bid instance.")		-- change this to only trigger if bid in progress!
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	  -- Close Button
	f.closeContainer = CreateFrame("Frame", "MonDKPTitle", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
	

	f.bossHeader = f:CreateFontString(nil, "OVERLAY")
	f.bossHeader:SetFontObject("MonDKPLargeRight");
	f.bossHeader:SetScale(0.7)
	f.bossHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 85, -25);
	f.bossHeader:SetText("Boss:")

	f.boss = f:CreateFontString(nil, "OVERLAY")
	f.boss:SetFontObject("MonDKPSmallLeft");
	f.boss:SetPoint("LEFT", f.bossHeader, "RIGHT", 5, 0);
	f.boss:SetSize(300, 28)


	f.itemHeader = f:CreateFontString(nil, "OVERLAY")
	f.itemHeader:SetFontObject("MonDKPLargeRight");
	f.itemHeader:SetScale(0.7)
	f.itemHeader:SetPoint("TOP", f.bossHeader, "BOTTOM", 0, -25);
	f.itemHeader:SetText("Item:")

	f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	f.itemIcon:SetPoint("LEFT", f.itemHeader, "RIGHT", 8, 0);
	f.itemIcon:SetColorTexture(0, 0, 0, 1)
	f.itemIcon:SetSize(28, 28);

	f.item = f:CreateFontString(nil, "OVERLAY")
	f.item:SetFontObject("MonDKPSmallLeft");
	f.item:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 2);
	f.item:SetSize(200, 28)

	f.itemName = f:CreateFontString(nil, "OVERLAY") 			-- hidden itemName field
	f.itemName:SetFontObject("MonDKPSmallLeft");

	f.minBidHeader = f:CreateFontString(nil, "OVERLAY")
	f.minBidHeader:SetFontObject("MonDKPLargeRight");
	f.minBidHeader:SetScale(0.7)
	f.minBidHeader:SetPoint("TOP", f.itemHeader, "BOTTOM", -30, -25);
	f.minBidHeader:SetText("Minimum Bid: ")
	
	f.minBid = CreateFrame("EditBox", nil, f)
	f.minBid:SetPoint("LEFT", f.minBidHeader, "RIGHT", 8, 0)   
    f.minBid:SetAutoFocus(false)
    f.minBid:SetMultiLine(false)
    f.minBid:SetSize(70, 28)
    f.minBid:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.minBid:SetBackdropColor(0,0,0,0.9)
    f.minBid:SetBackdropBorderColor(1,1,1,0.4)
    f.minBid:SetMaxLetters(4)
    f.minBid:SetTextColor(1, 1, 1, 1)
    f.minBid:SetFontObject("GameFontNormalRight")
    f.minBid:SetTextInsets(10, 10, 5, 5)
    f.minBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)

    f.bidTimerHeader = f:CreateFontString(nil, "OVERLAY")
	f.bidTimerHeader:SetFontObject("MonDKPLargeRight");
	f.bidTimerHeader:SetScale(0.7)
	f.bidTimerHeader:SetPoint("TOP", f.minBidHeader, "BOTTOM", 13, -25);
	f.bidTimerHeader:SetText("Bid Timer: ")

	f.bidTimer = CreateFrame("EditBox", nil, f)
	f.bidTimer:SetPoint("LEFT", f.bidTimerHeader, "RIGHT", 8, 0)   
    f.bidTimer:SetAutoFocus(false)
    f.bidTimer:SetMultiLine(false)
    f.bidTimer:SetSize(70, 28)
    f.bidTimer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.bidTimer:SetBackdropColor(0,0,0,0.9)
    f.bidTimer:SetBackdropBorderColor(1,1,1,0.4)
    f.bidTimer:SetMaxLetters(4)
    f.bidTimer:SetTextColor(1, 1, 1, 1)
    f.bidTimer:SetFontObject("GameFontNormalRight")
    f.bidTimer:SetTextInsets(10, 10, 5, 5)
    f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)

	f.bidTimerSuffix = f:CreateFontString(nil, "OVERLAY")
	f.bidTimerSuffix:SetFontObject("MonDKPLargeLeft");
	f.bidTimerSuffix:SetScale(0.7)
	f.bidTimerSuffix:SetPoint("LEFT", f.bidTimer, "RIGHT", 10, 0);
	f.bidTimerSuffix:SetText("Seconds")

	f.StartBidding = MonDKP:CreateButton("LEFT", f.minBid, "RIGHT", 80, 2, "Start Bidding");
	f.StartBidding:SetSize(90,25)
	f.StartBidding:SetScript("OnClick", StartBidding)

	f.ClearBidWindow = MonDKP:CreateButton("TOP", f.StartBidding, "BOTTOM", 0, -10, "Clear Window");
	f.ClearBidWindow:SetSize(90,25)
	f.ClearBidWindow:SetScript("OnClick", ClearBidWindow)


	--------------------------------------------------
	-- Bid Table
	--------------------------------------------------
    f.bidTable = CreateFrame("ScrollFrame", "MonDKP_BidWindowTable", f, "FauxScrollFrameTemplate")
    f.bidTable:SetSize(width, height*numrows+3)
	f.bidTable:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	f.bidTable:SetBackdropColor(0,0,0,0.2)
	f.bidTable:SetBackdropBorderColor(1,1,1,0.4)
    f.bidTable.ScrollBar = FauxScrollFrame_GetChildFrames(f.bidTable)
    f.bidTable.ScrollBar:Hide()
    f.bidTable.Rows = {}
    for i=1, numrows do
        f.bidTable.Rows[i] = BidWindowCreateRow(f.bidTable, i)
        if i==1 then
        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable, "TOPLEFT", 0, -3)
        else	
        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable.Rows[i-1], "BOTTOMLEFT")
        end
    end
    f.bidTable:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, height, BidScrollFrame_Update)
    end)

	---------------------------------------
	-- Header Buttons
	--------------------------------------- 
	local headerButtons = {}
	f.BidTable_Headers = CreateFrame("Frame", "MonDKPDKPTableHeaders", f)
	f.BidTable_Headers:SetSize(370, 22)
	f.BidTable_Headers:SetPoint("BOTTOMLEFT", f.bidTable, "TOPLEFT", 0, 1)
	f.BidTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	f.BidTable_Headers:SetBackdropColor(0,0,0,0.8);
	f.BidTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	f.bidTable:SetPoint("TOP", f, "TOP", 0, -200)
	f.BidTable_Headers:Show()

	headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers)
	headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers)
	headerButtons.dkp = CreateFrame("Button", "$ParentSuttonDkp", f.BidTable_Headers)

	headerButtons.bid:SetPoint("BOTTOM", f.BidTable_Headers, "BOTTOM", 0, 2)
	headerButtons.player:SetPoint("RIGHT", headerButtons.bid, "LEFT")
	headerButtons.dkp:SetPoint("LEFT", headerButtons.bid, "RIGHT")

	for k, v in pairs(headerButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((width/3)-1, height)
	end

	headerButtons.player.t = headerButtons.player:CreateFontString(nil, "OVERLAY")
	headerButtons.player.t:SetFontObject("MonDKPSmall")
	headerButtons.player.t:SetTextColor(1, 1, 1, 1);
	headerButtons.player.t:SetPoint("CENTER", headerButtons.player, "CENTER", 0, 0);
	headerButtons.player.t:SetText("Player"); 

	headerButtons.bid.t = headerButtons.bid:CreateFontString(nil, "OVERLAY")
	headerButtons.bid.t:SetFontObject("MonDKPSmall");
	headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
	headerButtons.bid.t:SetPoint("CENTER", headerButtons.bid, "CENTER", 0, 0);
	headerButtons.bid.t:SetText("Class"); 

	headerButtons.dkp.t = headerButtons.dkp:CreateFontString(nil, "OVERLAY")
	headerButtons.dkp.t:SetFontObject("MonDKPSmall")
	headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	headerButtons.dkp.t:SetPoint("CENTER", headerButtons.dkp, "CENTER", 0, 0);
	headerButtons.dkp.t:SetText("Total DKP");
    
    ------------------------------------
    --	AWARD ITEM
    ------------------------------------

    f.cost = CreateFrame("EditBox", nil, f)
	f.cost:SetPoint("TOPLEFT", f.bidTable, "BOTTOMLEFT", 70, -15)   
    f.cost:SetAutoFocus(false)
    f.cost:SetMultiLine(false)
    f.cost:SetSize(70, 28)
    f.cost:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
    });
    f.cost:SetBackdropColor(0,0,0,0.9)
    f.cost:SetBackdropBorderColor(1,1,1,0.4)
    f.cost:SetMaxLetters(4)
    f.cost:SetTextColor(1, 1, 1, 1)
    f.cost:SetFontObject("GameFontNormalRight")
    f.cost:SetTextInsets(10, 10, 5, 5)
    f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)

	f.costHeader = f:CreateFontString(nil, "OVERLAY")
	f.costHeader:SetFontObject("MonDKPLargeRight");
	f.costHeader:SetScale(0.7)
	f.costHeader:SetPoint("RIGHT", f.cost, "LEFT", -7, 0);
	f.costHeader:SetText("Item Cost: ")

	f.StartBidding = MonDKP:CreateButton("LEFT", f.cost, "RIGHT", 30, 0, "Award Item");
	f.StartBidding:SetSize(90,25)
	f.StartBidding:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if SelectedBidder["player"] then
			local selected = "Award item to "..SelectedBidder["player"].."?";

			StaticPopupDialogs["CONFIRM_AWARD"] = {
			  text = selected,
			  button1 = "Yes",
			  button2 = "No",
			  OnAccept = function()
			      AwardItem()
			  end,
			  timeout = 0,
			  whileDead = true,
			  hideOnEscape = true,
			  preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_AWARD")
		else
			local selected = "No Player Selected";

			StaticPopupDialogs["CONFIRM_AWARD"] = {
			  text = selected,
			  button1 = "Ok",
			  timeout = 5,
			  whileDead = true,
			  hideOnEscape = true,
			  preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_AWARD")
		end
	end);

	return f;
end