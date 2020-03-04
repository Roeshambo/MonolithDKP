local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local function AwardItem(player, cost, boss, zone, loot, reassign)
	local cost = cost;
	local winner = player;
	local curTime = time();
	local curZone = zone;
	local curBoss = boss;
	local loot = loot;
	local BidsEntry = {};
	local mode = MonDKP_DB.modes.mode;
	local curOfficer = UnitName("player")
	local bids;
	local search_reassign;

	MonDKP:StatusVerify_Update()

	if core.IsOfficer then
		if MonDKP_DB.modes.costvalue == "Percent" then
			local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

			if MonDKP_DB.modes.mode == "Roll Based Bidding" then
				if search then
					cost = MonDKP_DKPTable[search[1][1]].dkp * (cost / 100)
					cost = MonDKP_round(cost, MonDKP_DB.modes.rounding);
				else
					print(L["ERROR"])
				end
			else
				cost = MonDKP_DKPTable[search[1][1]].dkp * (cost / 100)
				cost = MonDKP_round(cost, MonDKP_DB.modes.rounding);
			end
		else
			cost = MonDKP_round(cost, MonDKP_DB.modes.rounding)
		end

		if cost > 0 then
			cost = cost * -1
		end

		if reassign then
			search_reassign = MonDKP:Table_Search(MonDKP_Loot, reassign, "index")

			if search_reassign then
				local deleted = CopyTable(MonDKP_Loot[search_reassign[1][1]])
				local reimburse = MonDKP:Table_Search(MonDKP_DKPTable, deleted.player, "player")
				local newIndex = curOfficer.."-"..curTime-2
				deleted.cost = deleted.cost * -1
				deleted.deletes = reassign
				deleted.index = newIndex
				deleted.date = curTime-2
				if deleted.bids then
					bids = CopyTable(deleted.bids);
					deleted.bids = nil;
				end
				MonDKP_Loot[search_reassign[1][1]].deletedby = newIndex
				MonDKP_DKPTable[reimburse[1][1]].dkp = MonDKP_DKPTable[reimburse[1][1]].dkp + deleted.cost
				MonDKP_DKPTable[reimburse[1][1]].lifetime_spent = MonDKP_DKPTable[reimburse[1][1]].lifetime_spent + deleted.cost
				table.insert(MonDKP_Loot, 1, deleted)
				MonDKP.Sync:SendData("MonDKPDelLoot", MonDKP_Loot[1])
			end
		end

		if MonDKP_DB.modes.StoreBids and not reassign then
			local Bids_Submitted = MonDKP:BidsSubmitted_Get();
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
					tinsert(MonDKP_Loot, 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, bids={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(MonDKP_Loot[1].bids, {bidder=k, bid=v});
					end
				elseif Bids_Submitted[1].dkp then
					tinsert(MonDKP_Loot, 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, dkp={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(MonDKP_Loot[1].dkp, {bidder=k, dkp=v});
					end
				elseif Bids_Submitted[1].roll then
					tinsert(MonDKP_Loot, 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex, rolls={ }})
					for k,v in pairs(BidsEntry) do
						table.insert(MonDKP_Loot[1].rolls, {bidder=k, roll=v});
					end
				end
			else
				tinsert(MonDKP_Loot, 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex})
			end
		else
			local newIndex = curOfficer.."-"..curTime
			tinsert(MonDKP_Loot, 1, {player=winner, loot=loot, zone=curZone, date=curTime, boss=curBoss, cost=cost, index=newIndex})
			if reassign then
				local search = MonDKP:Table_Search(MonDKP_Loot, reassign, "index")

				if search and MonDKP_Loot[search[1][1]].player ~= winner then
					MonDKP_Loot[1].reassigned = true
				end
			end 
			if type(bids) == "table" then
				MonDKP_Loot[1].bids = bids
			end
		end
		
		MonDKP:BidsSubmitted_Clear()
		MonDKP.Sync:SendData("MonDKPLootDist", MonDKP_Loot[1])
		MonDKP:DKPTable_Set(winner, "dkp", MonDKP_round(cost, MonDKP_DB.modes.rounding), true)
		MonDKP:LootHistory_Reset();
		MonDKP:LootHistory_Update(L["NOFILTER"])

		if core.BiddingWindow and core.BiddingWindow:IsShown() then  -- runs below if award is through bidding window (update minbids and zerosum bank)
			if _G["MonDKPBiddingStartBiddingButton"] then
				_G["MonDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
				_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
					ToggleTimerBtn(self)
				end)
				timerToggle = 0;
			end

			core.BidInProgress = false;
			MonDKP:BroadcastStopBidTimer()
			
			SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..-cost.." "..L["DKP"], "RAID_WARNING")
			if MonDKP_DB.modes.AnnounceAward then
				SendChatMessage(L["CONGRATS"].." "..winner.." "..L["ON"].." "..loot.." @ "..-cost.." "..L["DKP"], "GUILD")
      end

				
			if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
				local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
				local val = MonDKP:GetMinBid(loot);

				if not search and core.BiddingWindow.cost:GetNumber() ~= tonumber(val) then
					tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
					core.BiddingWindow.CustomMinBid:SetShown(true);
					core.BiddingWindow.CustomMinBid:SetChecked(true);
				elseif search and core.BiddingWindow.cost:GetNumber() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
					if MonDKP_MinBids[search[1][1]].minbid ~= core.BiddingWindow.cost:GetText() then
					MonDKP_MinBids[search[1][1]].minbid = MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding);
					core.BiddingWindow.CustomMinBid:SetShown(true);
					core.BiddingWindow.CustomMinBid:SetChecked(true);
				end
			end

			if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
				table.remove(MonDKP_MinBids, search[1][1])
				core.BiddingWindow.CustomMinBid:SetShown(false);
			end
				end
				
			if mode == "Zero Sum" and not reassign then
				MonDKP_DB.modes.ZeroSumBank.balance = MonDKP_DB.modes.ZeroSumBank.balance + -tonumber(cost)
				table.insert(MonDKP_DB.modes.ZeroSumBank, { loot = loot, cost = -tonumber(cost) })
				MonDKP:ZeroSumBank_Update()
				MonDKP.Sync:SendData("MonDKPZSumBank", MonDKP_DB.modes.ZeroSumBank)
			end
			core.BiddingWindow:Hide()
			ClearBidWindow()
		end
	end
end

local function AwardConfirm_Create()
	local f = CreateFrame("Frame", "MonDKP_AwardWindowConfirm", UIParent, "ShadowOverlaySmallTemplate");

	f:SetPoint("TOP", UIParent, "TOP", 0, -200);
	f:SetSize(400, 230);
	f:SetClampedToScreen(true)
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(15)
	f:Hide()

	f.confirmHeader = f:CreateFontString(nil, "OVERLAY")
	f.confirmHeader:SetFontObject("MonDKPLargeRight");
	f.confirmHeader:SetScale(0.9)
	f.confirmHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -15);
	f.confirmHeader:SetText(L["CONFAWARD"])

	f.playerHeader = f:CreateFontString(nil, "OVERLAY")
	f.playerHeader:SetFontObject("MonDKPLargeRight");
	f.playerHeader:SetScale(0.7)
	f.playerHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 120, -60);
	f.playerHeader:SetText(L["PLAYER"]..":")

	f.player = CreateFrame("FRAME", "MonDKPAwardConfirmPlayerDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.player:SetPoint("LEFT", f.playerHeader, "RIGHT", -15, 0)
	UIDropDownMenu_SetWidth(f.player, 150)
	UIDropDownMenu_JustifyText(f.player, "LEFT")


	--[[f.player = f:CreateFontString(nil, "OVERLAY")
	f.player:SetFontObject("MonDKPNormalLeft");
	f.player:SetPoint("LEFT", f.playerHeader, "RIGHT", 5, 1);
	f.player:SetSize(200, 28);--]]

	f.lootHeader = f:CreateFontString(nil, "OVERLAY")
	f.lootHeader:SetFontObject("MonDKPLargeRight");
	f.lootHeader:SetScale(0.7)
	f.lootHeader:SetPoint("TOPRIGHT", f.playerHeader, "BOTTOMRIGHT", 0, -10);
	f.lootHeader:SetText(L["ITEM"]..":")

	f.lootIcon = f:CreateTexture(nil, "OVERLAY", nil);
	f.lootIcon:SetPoint("LEFT", f.lootHeader, "RIGHT", 5, 0);
	f.lootIcon:SetColorTexture(0, 0, 0, 1)
	f.lootIcon:SetSize(20, 20);

	f.loot = f:CreateFontString(nil, "OVERLAY")
	f.loot:SetFontObject("MonDKPNormalLeft");
	f.loot:SetPoint("LEFT", f.lootIcon, "RIGHT", 5, 1);
	f.loot:SetSize(200, 28);

	f.costHeader = f:CreateFontString(nil, "OVERLAY")
	f.costHeader:SetFontObject("MonDKPLargeRight");
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
	f.cost:SetFontObject("MonDKPSmallRight")
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
	f.costFooter:SetFontObject("MonDKPNormalLeft");
	f.costFooter:SetPoint("LEFT", f.cost, "RIGHT", 5, 0);
	f.costFooter:SetSize(200, 28);

	f.bossHeader = f:CreateFontString(nil, "OVERLAY")
	f.bossHeader:SetFontObject("MonDKPLargeRight");
	f.bossHeader:SetScale(0.7)
	f.bossHeader:SetPoint("TOPRIGHT", f.costHeader, "BOTTOMRIGHT", 0, -10);
	f.bossHeader:SetText(L["BOSS"]..":")

	f.bossDropDown = CreateFrame("FRAME", "MonDKPAwardConfirmBossDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.bossDropDown:SetPoint("LEFT", f.bossHeader, "RIGHT", -15, -2)
	UIDropDownMenu_SetWidth(f.bossDropDown, 150)
	UIDropDownMenu_JustifyText(f.bossDropDown, "LEFT")

	f.zoneHeader = f:CreateFontString(nil, "OVERLAY")
	f.zoneHeader:SetFontObject("MonDKPLargeRight");
	f.zoneHeader:SetScale(0.7)
	f.zoneHeader:SetPoint("TOPRIGHT", f.bossHeader, "BOTTOMRIGHT", 0, -10);
	f.zoneHeader:SetText(L["ZONE"]..":")

	f.zoneDropDown = CreateFrame("FRAME", "MonDKPAwardConfirmBossDropDown", f, "MonolithDKPUIDropDownMenuTemplate")
	f.zoneDropDown:SetPoint("LEFT", f.zoneHeader, "RIGHT", -15, -2)
	UIDropDownMenu_SetWidth(f.zoneDropDown, 150)
	UIDropDownMenu_JustifyText(f.zoneDropDown, "LEFT")

	f.yesButton = MonDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15, L["CONFIRM"]);
	f.noButton = MonDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 15, L["CANCEL"]);

	return f;
end

function MonDKP:AwardConfirm(player, cost, boss, zone, loot, reassign)
	local _,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
	local curBoss, curZone, player, cost = boss, zone, player, cost
	local class, search;
	local PlayerList = {};
	local curSelected = 0;

	if cost == 0 then
		cost = MonDKP:GetMinBid(itemLink)
	end
	
	if player then
		search = MonDKP:Table_Search(MonDKP_DKPTable, player)
		class = MonDKP:GetCColors(MonDKP_DKPTable[search[1][1]].class)
	end

	for i=1, #MonDKP_DKPTable do
		table.insert(PlayerList, MonDKP_DKPTable[i].player)
	end
	table.sort(PlayerList, function(a, b)
		return a < b
	end)

	PlaySound(850)
	core.AwardConfirm = core.AwardConfirm or AwardConfirm_Create()
	core.AwardConfirm:SetShown(not core.AwardConfirm:IsShown())

	--core.AwardConfirm.player:SetText("|cff"..class.hex..player.."|r")
	core.AwardConfirm.lootIcon:SetTexture(itemIcon)
	core.AwardConfirm.loot:SetText(loot)
	core.AwardConfirm.cost:SetNumber(cost)
	core.AwardConfirm.cost:SetScript("OnKeyUp", function(self)
		cost = self:GetNumber();
	end)
	core.AwardConfirm.costFooter:SetText("DKP")
	--core.AwardConfirm.boss:SetText(boss.." in "..zone)

	if player then
		UIDropDownMenu_SetText(core.AwardConfirm.player, "|cff"..class.hex..player.."|r")
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
					local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, PlayerList[i])
				    local c;

				    if classSearch then
				     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
				    else
				     	c = { hex="444444" }
				    end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i], "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i] == player, true
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
			if not MonDKP:Table_Search(tempNPCs, v) then
				table.insert(tempNPCs, v)
			end
		end

		reason.func = self.SetValue

		if not MonDKP:Table_Search(tempNPCs, curBoss) then
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
			if not MonDKP:Table_Search(tempZones, v) then
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
end