local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local function SetItemPrice(cost, loot)
	local itemName,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
	local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(loot,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	local cost = cost;

	if itemName == nil and Name ~= nil then
		itemName = Name;
	end

	local search = CommDKP:GetTable(CommDKP_MinBids, true)[itemID];
	local newItem = {item=itemName, minbid=cost, link=itemLink, icon=itemIcon, disenchants=0, lastbid=cost, itemID = itemID}

	if not search then
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID] = newItem;
	elseif search then
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid = CommDKP_round(cost, core.DB.modes.rounding);
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].lastbid = CommDKP_round(cost, core.DB.modes.rounding);
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].link = itemLink;
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].icon = itemIcon;
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].item = itemName;
		CommDKP:GetTable(CommDKP_MinBids, true)[itemID].itemID = itemID;
		if cost == 0 then
			CommDKP:GetTable(CommDKP_MinBids, true)[itemID].disenchants = 0;
		end
		newItem = CommDKP:GetTable(CommDKP_MinBids, true)[itemID];
	end
	core.PriceTable = CommDKP:FormatPriceTable();
	CommDKP:PriceTable_Update(0);
	CommDKP.Sync:SendData("CommDKPSetPrice", newItem);

end

local function AwardItem(player, cost, boss, zone, loot, reassign)
	local cost = cost;
	local winner = player;
	local curTime = time();
	local curZone = zone;
	local curBoss = boss;
	local loot = loot;
	local BidsEntry = {};
	local mode = core.DB.modes.mode;
	local curOfficer = UnitName("player")
	local bids;
	local search_reassign;
	local itemName,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)

	CommDKP:StatusVerify_Update()
	if core.IsOfficer then
		if core.DB.modes.costvalue == "Percent" then
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), winner);

			if core.DB.modes.mode == "Roll Based Bidding" then
				if search then
					cost = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp * (cost / 100)
					cost = CommDKP_round(cost, core.DB.modes.rounding);
				else
					print(L["ERROR"])
				end
			else
				cost = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].dkp * (cost / 100)
				cost = CommDKP_round(cost, core.DB.modes.rounding);
			end
		else
			cost = CommDKP_round(cost, core.DB.modes.rounding)
		end

		if cost > 0 then
			cost = cost * -1
		end

		if reassign then
			search_reassign = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), reassign, "index")

			if search_reassign then
				local deleted = CopyTable(CommDKP:GetTable(CommDKP_Loot, true)[search_reassign[1][1]])
				local reimburse = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), deleted.player, "player")
				local newIndex = curOfficer.."-"..curTime-2
				deleted.cost = deleted.cost * -1
				deleted.deletes = reassign
				deleted.index = newIndex
				deleted.date = curTime-2
				if deleted.bids then
					bids = CopyTable(deleted.bids);
					deleted.bids = nil;
				end
				CommDKP:GetTable(CommDKP_Loot, true)[search_reassign[1][1]].deletedby = newIndex
				CommDKP:GetTable(CommDKP_DKPTable, true)[reimburse[1][1]].dkp = CommDKP:GetTable(CommDKP_DKPTable, true)[reimburse[1][1]].dkp + deleted.cost
				CommDKP:GetTable(CommDKP_DKPTable, true)[reimburse[1][1]].lifetime_spent = CommDKP:GetTable(CommDKP_DKPTable, true)[reimburse[1][1]].lifetime_spent + deleted.cost
				table.insert(CommDKP:GetTable(CommDKP_Loot, true), 1, deleted)
				CommDKP.Sync:SendData("CommDKPDelLoot", CommDKP:GetTable(CommDKP_Loot, true)[1])
			end
		end

		if core.DB.modes.StoreBids and not reassign then
			local Bids_Submitted = CommDKP:BidsSubmitted_Get();
			local newIndex = curOfficer.."-"..curTime

			for i=1, #Bids_Submitted do
				if Bids_Submitted[i].bid then
					BidsEntry[Bids_Submitted[i].player] = Bids_Submitted[i].bid;
				elseif Bids_Submitted[i].dkp then
					BidsEntry[Bids_Submitted[i].player] = Bids_Submitted[i].dkp;
				elseif Bids_Submitted[i].roll then
					BidsEntry[Bids_Submitted[i].player] = Bids_Submitted[i].roll..Bids_Submitted[i].range;
				end
			end
			if Bids_Submitted[1] then
				if Bids_Submitted[1].bid then
					tinsert(CommDKP:GetTable(CommDKP_Loot, true), 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, bids={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(CommDKP:GetTable(CommDKP_Loot, true)[1].bids, {bidder=k, bid=v});
					end
				elseif Bids_Submitted[1].dkp then
					tinsert(CommDKP:GetTable(CommDKP_Loot, true), 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, dkp={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(CommDKP:GetTable(CommDKP_Loot, true)[1].dkp, {bidder=k, dkp=v});
					end
				elseif Bids_Submitted[1].roll then
					tinsert(CommDKP:GetTable(CommDKP_Loot, true), 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, rolls={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(CommDKP:GetTable(CommDKP_Loot, true)[1].rolls, {bidder=k, roll=v});
					end
				end
			else
				tinsert(CommDKP:GetTable(CommDKP_Loot, true), 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex})
			end
		else
			local newIndex = curOfficer.."-"..curTime
			tinsert(CommDKP:GetTable(CommDKP_Loot, true), 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex})
			if reassign then
				local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), reassign, "index")

				if search and CommDKP:GetTable(CommDKP_Loot, true)[search[1][1]].player ~= winner then
					CommDKP:GetTable(CommDKP_Loot, true)[1].reassigned = true
				end
			end 
			if type(bids) == "table" then
				CommDKP:GetTable(CommDKP_Loot, true)[1].bids = bids
			end
		end
		CommDKP:BidsSubmitted_Clear()
		CommDKP.Sync:SendData("CommDKPLootDist", CommDKP:GetTable(CommDKP_Loot, true)[1])
		CommDKP:DKPTable_Set(winner, "dkp", CommDKP_round(cost, core.DB.modes.rounding), true)
		CommDKP:LootHistory_Reset();
		CommDKP:LootHistory_Update(L["NOFILTER"])

		if core.BiddingWindow and core.BiddingWindow:IsShown() then  -- runs below if award is through bidding window (update minbids and zerosum bank)
			if _G["CommDKPBiddingStartBiddingButton"] then
				_G["CommDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
				_G["CommDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
					ToggleTimerBtn(self)
				end)
				timerToggle = 0;
			end

			core.BidInProgress = false;
			CommDKP:BroadcastStopBidTimer()
			
			SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..-cost.." "..L["DKP"], "RAID_WARNING")
			if core.DB.modes.AnnounceAward then
				SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..-cost.." "..L["DKP"], "GUILD")
        	end

			local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(loot,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

			if itemName == nil and Name ~= nil then
				itemName = Name;
			end
		
			local search = CommDKP:GetTable(CommDKP_MinBids, true)[itemID]
			local minBidAmount = CommDKP_round(CommDKP:GetMinBid(loot), core.DB.modes.rounding);
			local lastBidAmount = CommDKP_round(core.BiddingWindow.cost:GetNumber(), core.DB.modes.rounding);

			if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
				if core.BiddingWindow.CustomMinBid:GetChecked() == false then
					minBidAmount = CommDKP_round(minBidAmount, core.DB.modes.rounding);
				else
					if core.BiddingWindow.cost:GetNumber() ~= tonumber(minBidAmount) then
						minBidAmount = CommDKP_round(core.BiddingWindow.cost:GetNumber(), core.DB.modes.rounding);
					end
				end
			else
				if core.BiddingWindow.CustomMinBid:GetChecked() == true then
					minBidAmount = CommDKP_round(core.BiddingWindow.minBid:GetNumber(), core.DB.modes.rounding);
				end
			end

			--set table here
			local minBidEntry = {item=itemName, minbid=minBidAmount, link=itemLink, icon=itemIcon, lastbid=lastBidAmount, itemID=itemID};

			if not search then
				--not found
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID] = minBidEntry;
				if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
					core.BiddingWindow.CustomMinBid:SetShown(true);
					core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid);
				end
				CommDKP.Sync:SendData("CommDKPSetPrice", minBidEntry);
			else
				--found
				if CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid ~= minBidAmount then
					if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
						core.BiddingWindow.CustomMinBid:SetShown(true);
						core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid);
					end
				end

				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].minbid = minBidEntry.minbid;
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].lastbid = minBidEntry.lastbid;
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].link = minBidEntry.link;
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].icon = minBidEntry.icon;
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].item = minBidEntry.itemName;
				CommDKP:GetTable(CommDKP_MinBids, true)[itemID].itemID = minBidEntry.itemID;

				CommDKP.Sync:SendData("CommDKPSetPrice", CommDKP:GetTable(CommDKP_MinBids, true)[itemID]);
			end
			
			core.PriceTable = CommDKP:FormatPriceTable();
			CommDKP:PriceTable_Update(0);

			if mode == "Zero Sum" and not reassign then
				core.DB.modes.ZeroSumBank.balance = core.DB.modes.ZeroSumBank.balance + -tonumber(cost)
				table.insert(core.DB.modes.ZeroSumBank, { loot = loot, cost = -tonumber(cost) })
				CommDKP:ZeroSumBank_Update()
				CommDKP.Sync:SendData("CommDKPZSumBank", core.DB.modes.ZeroSumBank)
			end
			core.BiddingWindow:Hide()
			CommDKP:ClearBidWindow()
		end
	end
end

local function AwardConfirm_Create()
	local f = CreateFrame("Frame", "CommDKP_AwardWindowConfirm", UIParent, "ShadowOverlaySmallTemplate");

	f:SetPoint("TOP", UIParent, "TOP", 0, -200);
	f:SetSize(400, 270); -- + 40
	f:SetClampedToScreen(true)
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\CommunityDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(15)
	f:Hide()

	f.confirmHeader = f:CreateFontString(nil, "OVERLAY")
	f.confirmHeader:SetFontObject("CommDKPLargeRight");
	f.confirmHeader:SetScale(0.9)
	f.confirmHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -15);
	f.confirmHeader:SetText(L["CONFAWARD"])

	----------------------------------
	-- Team row
	----------------------------------

		f.teamHeader = f:CreateFontString(nil, "OVERLAY")
		f.teamHeader:SetFontObject("CommDKPLargeRight");
		f.teamHeader:SetScale(0.7)
		f.teamHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 120, -60);
		f.teamHeader:SetText(L["TEAM"]..":")

		f.team = CreateFrame("FRAME", "CommDKPAwardConfirmPlayerDropDown", f, "CommunityDKPUIDropDownMenuTemplate")
		f.team:SetPoint("LEFT", f.teamHeader, "RIGHT", -15, 0)
		UIDropDownMenu_SetWidth(f.team, 150)
		UIDropDownMenu_JustifyText(f.team, "LEFT")

	----------------------------------
	-- Player row
	----------------------------------	

		f.playerHeader = f:CreateFontString(nil, "OVERLAY")
		f.playerHeader:SetFontObject("CommDKPLargeRight");
		f.playerHeader:SetScale(0.7)
		f.playerHeader:SetPoint("TOPRIGHT", f.teamHeader, "BOTTOMRIGHT", 0, -10);
		f.playerHeader:SetText(L["PLAYER"]..":")

		f.player = CreateFrame("FRAME", "CommDKPAwardConfirmPlayerDropDown", f, "CommunityDKPUIDropDownMenuTemplate")
		f.player:SetPoint("LEFT", f.playerHeader, "RIGHT", -15, 0)
		UIDropDownMenu_SetWidth(f.player, 150)
		UIDropDownMenu_JustifyText(f.player, "LEFT")

	----------------------------------
	-- Item row
	----------------------------------	

		f.lootHeader = f:CreateFontString(nil, "OVERLAY")
		f.lootHeader:SetFontObject("CommDKPLargeRight");
		f.lootHeader:SetScale(0.7)
		f.lootHeader:SetPoint("TOPRIGHT", f.playerHeader, "BOTTOMRIGHT", 0, -10);
		f.lootHeader:SetText(L["ITEM"]..":")

		f.lootIcon = f:CreateTexture(nil, "OVERLAY", nil);
		f.lootIcon:SetPoint("LEFT", f.lootHeader, "RIGHT", 5, 0);
		f.lootIcon:SetColorTexture(0, 0, 0, 1)
		f.lootIcon:SetSize(20, 20);

		f.loot = f:CreateFontString(nil, "OVERLAY")
		f.loot:SetFontObject("CommDKPNormalLeft");
		f.loot:SetPoint("LEFT", f.lootIcon, "RIGHT", 5, 1);
		f.loot:SetSize(200, 28);

	----------------------------------
	-- Cost row
	----------------------------------

		f.costHeader = f:CreateFontString(nil, "OVERLAY")
		f.costHeader:SetFontObject("CommDKPLargeRight");
		f.costHeader:SetScale(0.7)
		f.costHeader:SetPoint("TOPRIGHT", f.lootHeader, "BOTTOMRIGHT", 0, -10);
		f.costHeader:SetText(L["ITEMCOST"]..":")

		f.cost = CreateFrame("EditBox", nil, f)
		f.cost:SetAutoFocus(false)
		f.cost:SetMultiLine(false)
		f.cost:SetPoint("LEFT", f.costHeader, "RIGHT", 5, 0)
		f.cost:SetSize(50, 22)
		f.cost:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
		});
		f.cost:SetBackdropColor(0,0,0,0.9)
		f.cost:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
		f.cost:SetMaxLetters(10)
		f.cost:SetTextColor(1, 1, 1, 1)
		f.cost:SetFontObject("CommDKPSmallRight")
		f.cost:SetTextInsets(10,10,0,0)
		f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:ClearFocus()
		end)
		f.cost:SetScript("OnTabPressed", function(self)    -- clears focus on tab
			self:ClearFocus()
		end)
		f.cost:SetScript("OnEnterPressed", function(self)    -- clears focus on enter
			self:ClearFocus()
		end)

		f.costFooter = f:CreateFontString(nil, "OVERLAY")
		f.costFooter:SetFontObject("CommDKPNormalLeft");
		f.costFooter:SetPoint("LEFT", f.cost, "RIGHT", 5, 0);
		f.costFooter:SetSize(200, 28);

	----------------------------------
	-- Boss row
	----------------------------------

		f.bossHeader = f:CreateFontString(nil, "OVERLAY")
		f.bossHeader:SetFontObject("CommDKPLargeRight");
		f.bossHeader:SetScale(0.7)
		f.bossHeader:SetPoint("TOPRIGHT", f.costHeader, "BOTTOMRIGHT", 0, -10);
		f.bossHeader:SetText(L["BOSS"]..":")

		f.bossDropDown = CreateFrame("FRAME", "CommDKPAwardConfirmBossDropDown", f, "CommunityDKPUIDropDownMenuTemplate")
		f.bossDropDown:SetPoint("LEFT", f.bossHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(f.bossDropDown, 150)
		UIDropDownMenu_JustifyText(f.bossDropDown, "LEFT")

	----------------------------------
	-- Zone row
	----------------------------------

		f.zoneHeader = f:CreateFontString(nil, "OVERLAY")
		f.zoneHeader:SetFontObject("CommDKPLargeRight");
		f.zoneHeader:SetScale(0.7)
		f.zoneHeader:SetPoint("TOPRIGHT", f.bossHeader, "BOTTOMRIGHT", 0, -10);
		f.zoneHeader:SetText(L["ZONE"]..":")

		f.zoneDropDown = CreateFrame("FRAME", "CommDKPAwardConfirmBossDropDown", f, "CommunityDKPUIDropDownMenuTemplate")
		f.zoneDropDown:SetPoint("LEFT", f.zoneHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(f.zoneDropDown, 150)
		UIDropDownMenu_JustifyText(f.zoneDropDown, "LEFT")

	----------------------------------
	-- Buttons
	----------------------------------

		f.yesButton = CommDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15, L["CONFIRM"]);
		f.setPriceButton = CommDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 150, 15, "Set Price");
		f.setPriceButton:SetShown(false);
		f.noButton = CommDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 15, L["CANCEL"]);

	return f;
end


-- this also populates all the drop downs
function CommDKP:AwardConfirm(player, cost, boss, zone, loot, reassign)
	local _,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
	local curBoss, curZone, player, cost = boss, zone, player, cost
	local class, search;
	local PlayerList = {};
	local curSelected = 0;
	local mode = core.DB.modes.mode;
	
	
	if player then
		search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), player)
		class = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]].class)
	end

	for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do
		table.insert(PlayerList, CommDKP:GetTable(CommDKP_DKPTable, true)[i].player)
	end
	table.sort(PlayerList, function(a, b)
		return a < b
	end)

	PlaySound(850)
	core.AwardConfirm = core.AwardConfirm or AwardConfirm_Create()
	core.AwardConfirm:SetShown(not core.AwardConfirm:IsShown())

	if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
		core.AwardConfirm.setPriceButton:SetShown(true);
	end

	--core.AwardConfirm.player:SetText("|c"..class.hex..player.."|r")
	core.AwardConfirm.lootIcon:SetTexture(itemIcon)
	core.AwardConfirm.loot:SetText(loot)
	core.AwardConfirm.cost:SetNumber(cost)
	core.AwardConfirm.cost:SetScript("OnKeyUp", function(self)
		cost = self:GetNumber();
	end)
	core.AwardConfirm.costFooter:SetText("DKP")
	--core.AwardConfirm.boss:SetText(boss.." in "..zone)

	-----
	-- team drop down initialization
	-----

	core.AwardConfirm.team:SetScript("OnEnter", 
		function(self) 
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["TEAMCURRENTLIST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["WARNING"], 1.0, 0, 0, true);
			GameTooltip:AddLine(L["TEAMCURRENTLISTDESC3"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end
	)
	core.AwardConfirm.team:SetScript("OnLeave",
		function(self)
			GameTooltip:Hide()
		end
	)

	-- Create and bind the initialization function to the dropdown menu
		UIDropDownMenu_Initialize(core.AwardConfirm.team, 
			function(self, level, menuList)

				local dropDownMenuItem = UIDropDownMenu_CreateInfo()
				dropDownMenuItem.func = self.SetValue
				dropDownMenuItem.fontObject = "CommDKPSmallCenter"
			
				teamList = CommDKP:GetGuildTeamList()

				for i=1, #teamList do
					dropDownMenuItem.disabled = true
					dropDownMenuItem.text = teamList[i][2]
					dropDownMenuItem.arg1 = teamList[i][2] -- name
					dropDownMenuItem.arg2 = teamList[i][1] -- index
					dropDownMenuItem.checked = teamList[i][1] == tonumber(CommDKP:GetCurrentTeamIndex())
					dropDownMenuItem.isNotRadio = true
					UIDropDownMenu_AddButton(dropDownMenuItem)
				end
			end
		)
		-- Show which team is currently the current one
		UIDropDownMenu_SetText(core.AwardConfirm.team, CommDKP:GetCurrentTeamName())
	
	if player then
		UIDropDownMenu_SetText(core.AwardConfirm.player, "|c"..class.hex..player.."|r")
	else
		UIDropDownMenu_SetText(core.AwardConfirm.player, "")
	end

	UIDropDownMenu_Initialize(core.AwardConfirm.player, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}

		while ranges[#ranges] < #PlayerList do
			table.insert(ranges, ranges[#ranges]+20)
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#PlayerList/20)
			filterName.func = self.SetValue
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = strsub(PlayerList[((i*20)-19)], 1, 1).."-"..strsub(PlayerList[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end
			
		else
			filterName.func = self.SetValue
			for i=ranges[menuList], ranges[menuList]+19 do
				if PlayerList[i] then
					local classSearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), PlayerList[i])
				    local c;

				    if classSearch then
				     	c = CommDKP:GetCColors(CommDKP:GetTable(CommDKP_DKPTable, true)[classSearch[1][1]].class)
				    else
				     	c = { hex="ff444444" }
				    end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|c"..c.hex..PlayerList[i].."|r", PlayerList[i], "|c"..c.hex..PlayerList[i].."|r", PlayerList[i] == player, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)
	
	UIDropDownMenu_SetText(core.AwardConfirm.bossDropDown, curBoss)
	UIDropDownMenu_Initialize(core.AwardConfirm.bossDropDown, function(self, level, menuList)                                   -- BOSS dropdown
		UIDropDownMenu_SetAnchor(core.AwardConfirm.bossDropDown, 10, 10, "TOPLEFT", core.AwardConfirm.bossDropDown, "BOTTOMLEFT")
		--UIDropDownMenu_JustifyText(core.AwardConfirm.bossDropDown, "LEFT") 
		local reason = UIDropDownMenu_CreateInfo()
		local tempNPCs = {};

		table.insert(tempNPCs, core.LastKilledBoss)

		for k,v in pairs(core.LastKilledNPC) do             -- eliminates duplicate zones
			if not CommDKP:Table_Search(tempNPCs, v) then
				table.insert(tempNPCs, v)
			end
		end

		reason.func = self.SetValue

		if not CommDKP:Table_Search(tempNPCs, curBoss) then
			reason.text, reason.arg1, reason.checked, reason.isNotRadio = curBoss, curBoss, curBoss == curBoss, true
			UIDropDownMenu_AddButton(reason)
		end

		for i=1, #tempNPCs do
			reason.text, reason.arg1, reason.checked, reason.isNotRadio = tempNPCs[i], tempNPCs[i], tempNPCs[i] == curBoss, true
			UIDropDownMenu_AddButton(reason)
		end
	end)

	UIDropDownMenu_SetText(core.AwardConfirm.zoneDropDown, curZone)
	UIDropDownMenu_Initialize(core.AwardConfirm.zoneDropDown, function(self, level, menuList)                                   -- ZONE dropdown
		UIDropDownMenu_SetAnchor(core.AwardConfirm.zoneDropDown, 10, 10, "TOPLEFT", core.AwardConfirm.zoneDropDown, "BOTTOMLEFT")
		--UIDropDownMenu_JustifyText(core.AwardConfirm.bossDropDown, "LEFT") 
		local reason = UIDropDownMenu_CreateInfo()
		local tempZones = {};

		table.insert(tempZones, core.CurrentRaidZone)

		for k,v in pairs(core.RecentZones) do             -- eliminates duplicate zones
			if not CommDKP:Table_Search(tempZones, v) then
				table.insert(tempZones, v)
			end
		end

		reason.func = self.SetValue

		for i=1, #tempZones do
			reason.text, reason.arg1, reason.checked, reason.isNotRadio = tempZones[i], tempZones[i], tempZones[i] == curZone, true
			UIDropDownMenu_AddButton(reason)
		end
	end)


	function core.AwardConfirm.player:SetValue(newValue, arg2) 	---- PLAYER dropdown function
		if player ~= newValue then player = newValue end
		UIDropDownMenu_SetText(core.AwardConfirm.player, arg2)
		CloseDropDownMenus()
	end

	function core.AwardConfirm.bossDropDown:SetValue(newValue)          ---- BOSS dropdown function
		UIDropDownMenu_SetText(core.AwardConfirm.bossDropDown, newValue)
		curBoss = newValue;
		CloseDropDownMenus()
	end

	function core.AwardConfirm.zoneDropDown:SetValue(newValue)          ---- ZONE dropdown function
		UIDropDownMenu_SetText(core.AwardConfirm.zoneDropDown, newValue)
		curZone = newValue;
		CloseDropDownMenus()
	end

	core.AwardConfirm.yesButton:SetScript("OnClick", function()         -- Run when "Yes" is clicked
		if not player then
			StaticPopupDialogs["AWARD_VALIDATE"] = {
				text = L["PLAYERVALIDATE"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("AWARD_VALIDATE")
		else
			if reassign then
				AwardItem(player, cost, curBoss, curZone, loot, reassign)
			else
				AwardItem(player, cost, curBoss, curZone, loot)
			end
			core.AwardConfirm:SetShown(false)
		end

		PlaySound(851)
	end)
	core.AwardConfirm.noButton:SetScript("OnClick", function()          -- Run when "No" is clicked
		PlaySound(851)
		core.AwardConfirm:SetShown(false)
	end)
	core.AwardConfirm.setPriceButton:SetScript("OnClick", function()          -- Run when "Set Price" is clicked
		SetItemPrice(cost, loot)
		PlaySound(851)
		core.AwardConfirm:SetShown(false)
	end)
end
