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
local timerToggle = 0;
local mode;
local events = CreateFrame("Frame", "EventsFrame");
local menuFrame = CreateFrame("Frame", "MonDKPBidWindowMenuFrame", UIParent, "UIDropDownMenuTemplate")

local function UpdateBidWindow()
	core.BiddingWindow.item:SetText(CurrItemForBid)
	core.BiddingWindow.itemIcon:SetTexture(CurrItemIcon)
end

local function Roll_OnEvent(self, event, arg1, ...)
	if event == "CHAT_MSG_SYSTEM" and core.BidInProgress then

		local pattern = string.gsub(RANDOM_ROLL_RESULT, "[%(%)-]", "%%%1")
		pattern = string.gsub(pattern, "%%s", "(.+)")
		pattern = string.gsub(pattern, "%%d", "%(%%d+%)")

		for name, roll, low, high in string.gmatch(arg1, pattern) do
			local search = MonDKP:Table_Search(MonDKP_DKPTable, name)

			if mode == "Roll Based Bidding" and core.BiddingWindow.cost:GetNumber() > MonDKP_DKPTable[search[1][1]].dkp and not MonDKP_DB.modes.SubZeroBidding and MonDKP_DB.modes.costvalue ~= "Percent" then
        		SendChatMessage("Your roll was not accepted. You only have "..MonDKP_DKPTable[search[1][1]].dkp.." DKP.", "WHISPER", nil, name)

        		return;
            end

			if not MonDKP:Table_Search(Bids_Submitted, name) then
				table.insert(Bids_Submitted, {player=name, roll=roll, range=" ("..low.."-"..high..")"})
			else
				SendChatMessage("Only one roll can be accepted!", "WHISPER", nil, name)
			end
			BidScrollFrame_Update()
		end
	end
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
	mode = MonDKP_DB.modes.mode;

	if string.find(text, "!bid") == 1 and core.IsOfficer == true then
		if core.BidInProgress then
			cmd = BidCmd(text)
			if (mode == "Static Item Values" and cmd ~= "cancel") or (mode == "Zero Sum" and cmd ~= "cancel" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
				cmd = nil;
			end
			if string.find(name, "-") then					-- finds and removes server name from name if exists
				local dashPos = string.find(name, "-")
				name = strsub(name, 1, dashPos-1)
			end
			if cmd == "cancel" then
				for i=1, #Bids_Submitted do 					-- !bid cancel will cancel their bid
					if Bids_Submitted[i] and Bids_Submitted[i].player == name then
						table.remove(Bids_Submitted, i)
						BidScrollFrame_Update()
						response = "Your bid has been canceled."
						--SendChatMessage(response, "WHISPER", nil, name)
						--return;
					end
				end
				if not response then
					response = "You have not submitted a bid."
				end
			end
			dkp = tonumber(MonDKP:GetPlayerDKP(name))
			if not dkp then		-- exits function if player is not on the DKP list
				response = "Invalid Player. You are not listed in the DKP table."
				SendChatMessage(response, "WHISPER", nil, name)
				return
			end
			if (tonumber(cmd) and (tonumber(cmd) <= MonDKP_DB.modes.MaximumBid or MonDKP_DB.modes.MaximumBid == 0)) or ((mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) and not cmd) then
				if dkp then
					if not MonDKP_DB.modes.SubZeroBidding then MonDKP_DB.modes.SubZeroBidding = false end
					if (cmd and cmd <= dkp) or (MonDKP_DB.modes.SubZeroBidding == true and dkp >= 0) or (mode == "Static Item Values" and dkp > 0 and (dkp > core.BiddingWindow.cost:GetNumber() or MonDKP_DB.modes.SubZeroBidding == true or MonDKP_DB.modes.costvalue == "Percent")) or ((mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") and not cmd) then
						if (cmd and core.BiddingWindow.minBid and tonumber(core.BiddingWindow.minBid:GetNumber()) <= cmd) or mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid" and cmd >= core.BiddingWindow.minBid:GetNumber()) then
							for i=1, #Bids_Submitted do 					-- checks if a bid was submitted, removes last bid if it was
								if Bids_Submitted[i] and Bids_Submitted[i].player == name then
									table.remove(Bids_Submitted, i)
								end
							end
							if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
								table.insert(Bids_Submitted, {player=name, bid=cmd})
								response = "Your bid of "..cmd.." DKP was Accepted."
							elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
								table.insert(Bids_Submitted, {player=name, dkp=dkp})
								response = "Your bid was Accepted."
							end
								
							BidScrollFrame_Update()
						else
							response = "Bid Denied! Below minimum bid of "..core.BiddingWindow.minBid:GetNumber().."!"
						end
					elseif MonDKP_DB.modes.SubZeroBidding == true and dkp < 0 then
						response = "Bid Denied! Your DKP is in the negative ("..dkp.." DKP)."
					else
						response = "Bid Denied! You only have "..dkp.." DKP"
					end
				end
			elseif not cmd and (mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) then
				response = "Bid Denied! No value given for bid."
			elseif cmd ~= "cancel" and (tonumber(cmd) and tonumber(cmd) > MonDKP_DB.modes.MaximumBid) then
				response = "Bid Denied! Your bid exceeded the maximum bid value of "..MonDKP_DB.modes.MaximumBid.." DKP."
			else
				if cmd ~= "cancel" then
					response = "Bid Denied! Invalid Bid Received."
				end
			end
			SendChatMessage(response, "WHISPER", nil, name)
		else
			SendChatMessage("No Bids in Progress", "WHISPER", nil, name)
		end	
	elseif string.find(text, "!dkp") == 1 and core.IsOfficer == true then
		cmd = BidCmd(text)

		if string.find(name, "-") then					-- finds and removes server name from name if exists
			local dashPos = string.find(name, "-")
			name = strsub(name, 1, dashPos-1)
		end

		if cmd and cmd:gsub("%s+", "") ~= "" then		-- allows command if it has content (removes empty spaces)
			local search = MonDKP:Table_Search(MonDKP_DKPTable, cmd)
			
			if search then
				response = "MonolithDKP: "..MonDKP_DKPTable[search[1][1]].player.." currently has "..MonDKP_DKPTable[search[1][1]].dkp.." DKP available."
			else
				response = "MonolithDKP: That player was not found."
			end
		else
			local search = MonDKP:Table_Search(MonDKP_DKPTable, name)
			local minimum;
			local maximum;
			local range = "";
			local perc = "";

			if MonDKP_DB.modes.mode == "Roll Based Bidding" and search then
				if MonDKP_DB.modes.rolls.UsePerc then
					if MonDKP_DB.modes.rolls.min == 0 then
            			minimum = 1;
            		else
            			minimum = MonDKP_DKPTable[search[1][1]].dkp * (MonDKP_DB.modes.rolls.min / 100);
            		end
	        		
	        		perc = " ("..MonDKP_DB.modes.rolls.min.."% - "..MonDKP_DB.modes.rolls.max.."%)";
	        		maximum = MonDKP_DKPTable[search[1][1]].dkp * (MonDKP_DB.modes.rolls.max / 100) + MonDKP_DB.modes.rolls.AddToMax;
	        	elseif not MonDKP_DB.modes.rolls.UsePerc then
	        		minimum = MonDKP_DB.modes.rolls.min;

	        		if MonDKP_DB.modes.rolls.max == 0 then
	        			maximum = MonDKP_DKPTable[search[1][1]].dkp + MonDKP_DB.modes.rolls.AddToMax;
	        		else
	        			maximum = MonDKP_DB.modes.rolls.max + MonDKP_DB.modes.rolls.AddToMax;
	        		end
	        		if maximum < 0 then maximum = 0 end
          			if minimum < 0 then minimum = 0 end
	        	end
	        	range = range.." Use /random "..round(minimum, 0).."-"..round(maximum, 0).." to bid"..perc..".";
	        end

			if search then
				response = "MonolithDKP: You currently have "..MonDKP_DKPTable[search[1][1]].dkp.." DKP."..range;
			end
		end

		SendChatMessage(response, "WHISPER", nil, name)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)			-- suppresses outgoing whisper responses to limit spam
		if core.BidInProgress and MonDKP_DB.defaults.SupressTells then
			if strfind(msg, "Your bid of") == 1 then
				return true
			elseif strfind(msg, "Bid Denied!") == 1 then
				return true
			elseif strfind(msg, "Your bid was Accepted.") == 1 then
				return true;
			elseif strfind(msg, "You have not submitted a bid.") == 1 then
				return true;
			elseif strfind(msg, "Only one roll can be accepted!") == 1 then
				return true;
			elseif strfind(msg, "Your roll was not accepted. You only have") == 1 then
				return true;
			end
		end

		if strfind(msg, "MonolithDKP: ") == 1 then
			return true
		elseif strfind(msg, "No Bids in Progress") == 1 then
			return true
		elseif strfind(msg, "Your bid has been canceled.") == 1 then
			return true
		end
	end)

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg, ...)			-- suppresses incoming whisper responses to limit spam
		if core.BidInProgress and MonDKP_DB.defaults.SupressTells then
			if strfind(msg, "!bid") == 1 then
				return true
			end
		end
		
		if strfind(msg, "!dkp") == 1 then
			return true
		end
	end)
end

local function GetMinBid(itemLink)
	local _,_,_,_,_,_,_,_,loc = GetItemInfo(itemLink);

	if loc == "INVTYPE_HEAD" then
		return MonDKP_DB.MinBidBySlot.Head
	elseif loc == "INVTYPE_NECK" then
		return MonDKP_DB.MinBidBySlot.Neck
	elseif loc == "INVTYPE_SHOULDER" then
		return MonDKP_DB.MinBidBySlot.Shoulders
	elseif loc == "INVTYPE_CLOAK" then
		return MonDKP_DB.MinBidBySlot.Cloak
	elseif loc == "INVTYPE_CHEST" or loc == "INVTYPE_ROBE" then
		return MonDKP_DB.MinBidBySlot.Chest
	elseif loc == "INVTYPE_WRIST" then
		return MonDKP_DB.MinBidBySlot.Bracers
	elseif loc == "INVTYPE_HAND" then
		return MonDKP_DB.MinBidBySlot.Hands
	elseif loc == "INVTYPE_WAIST" then
		return MonDKP_DB.MinBidBySlot.Belt
	elseif loc == "INVTYPE_LEGS" then
		return MonDKP_DB.MinBidBySlot.Legs
	elseif loc == "INVTYPE_FEET" then
		return MonDKP_DB.MinBidBySlot.Boots
	elseif loc == "INVTYPE_FINGER" then
		return MonDKP_DB.MinBidBySlot.Ring
	elseif loc == "INVTYPE_TRINKET" then
		return MonDKP_DB.MinBidBySlot.Trinket
	elseif loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONMAINHAND" or loc == "INVTYPE_WEAPONOFFHAND" then
		return MonDKP_DB.MinBidBySlot.OneHanded
	elseif loc == "INVTYPE_2HWEAPON" then
		return MonDKP_DB.MinBidBySlot.TwoHanded
	elseif loc == "INVTYPE_HOLDABLE" or loc == "INVTYPE_SHIELD" then
		return MonDKP_DB.MinBidBySlot.OffHand
	elseif loc == "INVTYPE_RANGED" or loc == "INVTYPE_THROWN" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_RELIC" then
		return MonDKP_DB.MinBidBySlot.Range
	else
		return MonDKP_DB.MinBidBySlot.Other
	end
end

function MonDKP:ToggleBidWindow(loot, lootIcon, itemName)
	local minBid;

	if core.IsOfficer == true then
		core.BiddingWindow = core.BiddingWindow or MonDKP:CreateBidWindow();
	 	core.BiddingWindow:SetShown(true)
	 	core.BiddingWindow:SetFrameLevel(10)

	 	if MonDKP_DB.modes.mode == "Zero Sum" then
		 	core.ZeroSumBank = core.ZeroSumBank or MonDKP:ZeroSumBank_Create()
		 	core.ZeroSumBank:SetShown(true)
		 	core.ZeroSumBank:SetFrameLevel(10)

		 	MonDKP:ZeroSumBank_Update();
		end

		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end

	 	if loot then
	 		local search = MonDKP:Table_Search(MonDKP_MinBids, itemName)

	 		CurrItemForBid = loot;
	 		CurrItemIcon = lootIcon
	 		CurZone = GetRealZoneText()
	 		
	 		if search then
	 			minBid = MonDKP_MinBids[search[1][1]].minbid
		 		
		 		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		 			core.BiddingWindow.CustomMinBid:Show();
		 			core.BiddingWindow.CustomMinBid:SetChecked(true)
		 			core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
		 				if self:GetChecked() == true then
		 					core.BiddingWindow.minBid:SetText(minBid)
		 				else
		 					core.BiddingWindow.minBid:SetText(GetMinBid(CurrItemForBid))
		 				end
		 			end)
		 		elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		 			core.BiddingWindow.CustomMinBid:Show();
		 			core.BiddingWindow.CustomMinBid:SetChecked(true)
		 			core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
		 				if self:GetChecked() == true then
		 					core.BiddingWindow.cost:SetText(minBid)
		 				else
		 					core.BiddingWindow.cost:SetText(GetMinBid(CurrItemForBid))
		 				end
		 			end)
		 		end
	 		else
	 			minBid = GetMinBid(CurrItemForBid)
	 			core.BiddingWindow.CustomMinBid:Hide();
	 		end
	 		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
 				core.BiddingWindow.minBid:SetText(minBid)
 			end

	 		core.BiddingWindow.cost:SetText(minBid)
	 		core.BiddingWindow.itemName:SetText(itemName)
	 		core.BiddingWindow.bidTimer:SetText(core.settings["DKPBonus"]["BidTimer"])
	 		core.BiddingWindow.boss:SetText(core.LastKilledBoss.." in "..CurZone)
	 	end
	 	UpdateBidWindow()
	 	BidScrollFrame_Update()
	else
		MonDKP:Print("You do not have permission to access that feature.")
	end
end

local function StartBidding()
	local perc;

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BiddingWindow.cost:SetNumber(core.BiddingWindow.minBid:GetNumber())
		MonDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), CurrItemIcon)

		local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
		local val = GetMinBid(CurrItemForBid);
		
		if not search and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val) then
			tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.minBid:GetNumber()})
			core.BiddingWindow.CustomMinBid:SetShown(true);
		 	core.BiddingWindow.CustomMinBid:SetChecked(true);
		elseif search and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
			if MonDKP_MinBids[search[1][1]].minbid ~= core.BiddingWindow.minBid:GetNumber() then
				MonDKP_MinBids[search[1][1]].minbid = core.BiddingWindow.minBid:GetNumber();
				core.BiddingWindow.CustomMinBid:SetShown(true);
		 		core.BiddingWindow.CustomMinBid:SetChecked(true);
			end
		end

		if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
			table.remove(MonDKP_MinBids, search[1][1])
			core.BiddingWindow.CustomMinBid:SetShown(false);
		end
	else
		if MonDKP_DB.modes.costvalue == "Percent" then perc = "%" else perc = " DKP" end;
		MonDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Cost: "..core.BiddingWindow.cost:GetNumber()..perc, CurrItemIcon)
	end

	if mode == "Roll Based Bidding" then
		events:RegisterEvent("CHAT_MSG_SYSTEM")
		events:SetScript("OnEvent", Roll_OnEvent);
	end
	
	core.BidInProgress = true;
	if CurrItemForBid then
		local channels = {};
		local channelText = "";

		if MonDKP_DB.modes.channels.raid then table.insert(channels, "/raid") end
		if MonDKP_DB.modes.channels.guild then table.insert(channels, "/guild") end
		if MonDKP_DB.modes.channels.whisper then table.insert(channels, "/whisper") end

		for i=1, #channels do
			if #channels == 1 then
				channelText = channels[i]
			else
				if i == 1 then
					channelText = channels[i];
				elseif i == #channels then
					channelText = channelText.." or "..channels[i]
				else
					channelText = channelText..", "..channels[i]
				end
			end
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
			SendChatMessage("Taking bids on "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.minBid:GetText().." DKP Minimum bid)", "RAID_WARNING")
			SendChatMessage("To bid use "..channelText.." to send !bid <value> (ex: !bid "..core.BiddingWindow.minBid:GetText().."). Or !bid cancel to withdraw your bid.", "RAID_WARNING")
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
			SendChatMessage("Taking bids on "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
			SendChatMessage("To bid use "..channelText.." to send !bid. Or !bid cancel to withdraw your bid.", "RAID_WARNING")
		elseif mode == "Roll Based Bidding" then
			SendChatMessage("Roll for "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
			SendChatMessage("To bid use /random. Your expected range can be seen on the DKP table or by using "..channelText.." with !dkp", "RAID_WARNING")
		end
	end
end

local function ToggleTimerBtn(self)
	mode = MonDKP_DB.modes.mode;

	if timerToggle == 0 then
		--if not IsInRaid() then MonDKP:Print("You are not in a raid.") return false end
		if (mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.minBid:GetText() == "") then MonDKP:Print("No minimum bid and/or item to bid on!") return false end
		if (mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then MonDKP:Print("No item cost and/or item to bid on!") return false end
		if mode == "Roll Based Bidding" and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then MonDKP:Print("No item cost and/or item to bid on!") return false end

		timerToggle = 1;
		self:SetText("End Bidding")
		StartBidding()
	else
		timerToggle = 0;
		core.BidInProgress = false;
		self:SetText("Start Bidding")
		SendChatMessage("Bidding Closed!", "RAID_WARNING")
		events:UnregisterEvent("CHAT_MSG_SYSTEM")
		MonDKP:BroadcastStopBidTimer()
	end
end

local function ClearBidWindow()
	CurrItemForBid = "";
	CurrItemIcon = "";
	Bids_Submitted = {}
	SelectedBidder = {}
	core.BiddingWindow.cost:SetText("")
	core.BiddingWindow.CustomMinBid:Hide();
	BidScrollFrame_Update()
	UpdateBidWindow()
	core.BidInProgress = false;
	core.BiddingWindow.boss:SetText("")
	_G["MonDKPBiddingStartBiddingButton"]:SetText("Start Bidding")
	_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
		ToggleTimerBtn(self)
	end)
	timerToggle = 0;
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BiddingWindow.minBid:SetText("")
	end
	for i=1, numrows do
		core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	end
end

local function AwardItem()
	local cost;
	local winner;
	local date;
	local selected;

	MonDKP:SeedVerify_Update()
	if core.UpToDate == false and core.IsOfficer == true then
		StaticPopupDialogs["CONFIRM_AWARD"] = {
			text = "|CFFFF0000WARNING|r: You are attempting to modify an outdated DKP table. This may inadvertently corrupt data for the officers that have the most recent tables.\n\n Are you sure you would like to do this?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				if SelectedBidder["player"] then
					cost = core.BiddingWindow.cost:GetNumber();
					winner = SelectedBidder["player"];
					date = time()
					
					if MonDKP_DB.modes.costvalue == "Percent" then
						if MonDKP_DB.modes.mode == "Roll Based Bidding" then
							local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

							if search then
								cost = round(MonDKP_DKPTable[search[1][1]].dkp * (cost / 100), MonDKP_DB.modes.rounding);
							else
								print("Error")
							end
						else
							cost = round(SelectedBidder["dkp"] * (cost / 100), MonDKP_DB.modes.rounding);
						end
						selected = "Award item to "..SelectedBidder["player"].." for |CFF00ff00"..round(cost, MonDKP_DB.modes.rounding).."|r (|CFFFF0000"..core.BiddingWindow.cost:GetNumber().."%%|r) DKP?";
					else
						cost = round(cost, MonDKP_DB.modes.rounding)
						selected = "Award item to "..SelectedBidder["player"].." for |CFF00ff00"..round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding).."|r DKP?";
					end

					StaticPopupDialogs["CONFIRM_AWARD"] = {
					  text = selected,
					  button1 = "Yes",
					  button2 = "No",
					  OnAccept = function()
						SendChatMessage("Congrats "..winner.." on "..CurrItemForBid.." @ "..cost.." DKP", "RAID_WARNING")
						MonDKP:DKPTable_Set(winner, "dkp", round(-cost, MonDKP_DB.modes.rounding), true)
						tinsert(MonDKP_Loot, {player=winner, loot=CurrItemForBid, zone=core.CurrentRaidZone, date=date, boss=core.LastKilledBoss, cost=cost})
						local temp_table = {}
						tinsert(temp_table, {seed = MonDKP_Loot.seed, {player=winner, loot=CurrItemForBid, zone=core.CurrentRaidZone, date=date, boss=core.LastKilledBoss, cost=cost}})
						MonDKP:LootHistory_Reset();
						MonDKP:LootHistory_Update("No Filter")
						local leader = MonDKP:GetGuildRankGroup(1)
						GuildRosterSetPublicNote(leader[1].index, time())
						MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
						MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])

						if _G["MonDKPBiddingStartBiddingButton"] then
							_G["MonDKPBiddingStartBiddingButton"]:SetText("Start Bidding")
							_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
								ToggleTimerBtn(self)
							end)
							timerToggle = 0;
						end

						core.BidInProgress = false;
						MonDKP:BroadcastStopBidTimer()

						if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
							local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
							local val = GetMinBid(CurrItemForBid);
							
							if not search and core.BiddingWindow.cost:GetText() ~= tonumber(val) then
								tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
								core.BiddingWindow.CustomMinBid:SetShown(true);
							 	core.BiddingWindow.CustomMinBid:SetChecked(true);
							elseif search and core.BiddingWindow.cost:GetText() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
								if MonDKP_MinBids[search[1][1]].minbid ~= core.BiddingWindow.cost:GetText() then
									MonDKP_MinBids[search[1][1]].minbid = core.BiddingWindow.cost:GetNumber();
									core.BiddingWindow.CustomMinBid:SetShown(true);
							 		core.BiddingWindow.CustomMinBid:SetChecked(true);
								end
							end

							if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
								table.remove(MonDKP_MinBids, search[1][1])
								core.BiddingWindow.CustomMinBid:SetShown(false);
							end
						end
						
						if mode == "Zero Sum" then
							MonDKP_DB.modes.ZeroSumBank.balance = MonDKP_DB.modes.ZeroSumBank.balance + tonumber(cost)
							table.insert(MonDKP_DB.modes.ZeroSumBank, { loot = CurrItemForBid, cost = tonumber(cost) })
							MonDKP:ZeroSumBank_Update()
						end

						core.BiddingWindow:Hide()
						table.wipe(temp_table)
						ClearBidWindow()
						MonDKP.Sync:SendData("MonDKPZeroSum", MonDKP_DB.modes.ZeroSumBank)
					  end,
					  timeout = 0,
					  whileDead = true,
					  hideOnEscape = true,
					  preferredIndex = 3,
					}
					StaticPopup_Show ("CONFIRM_AWARD")
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_AWARD")
	else
		if SelectedBidder["player"] then
			cost = core.BiddingWindow.cost:GetNumber();
			winner = SelectedBidder["player"];
			date = time()
			
			if MonDKP_DB.modes.costvalue == "Percent" then
				if MonDKP_DB.modes.mode == "Roll Based Bidding" then
					local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

					if search then
						cost = round(MonDKP_DKPTable[search[1][1]].dkp * (cost / 100), MonDKP_DB.modes.rounding);
					else
						print("Error")
					end
				else
					cost = round(SelectedBidder["dkp"] * (cost / 100), MonDKP_DB.modes.rounding);
				end
				selected = "Award item to "..SelectedBidder["player"].." for |CFF00ff00"..round(cost, MonDKP_DB.modes.rounding).."|r (|CFFFF0000"..core.BiddingWindow.cost:GetNumber().."%%|r) DKP?";
			else
				cost = round(cost, MonDKP_DB.modes.rounding)
				selected = "Award item to "..SelectedBidder["player"].." for |CFF00ff00"..round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding).."|r DKP?";
			end

			StaticPopupDialogs["CONFIRM_AWARD"] = {
			  text = selected,
			  button1 = "Yes",
			  button2 = "No",
			  OnAccept = function()
				SendChatMessage("Congrats "..winner.." on "..CurrItemForBid.." @ "..cost.." DKP", "RAID_WARNING")
				MonDKP:DKPTable_Set(winner, "dkp", round(-cost, MonDKP_DB.modes.rounding), true)
				tinsert(MonDKP_Loot, {player=winner, loot=CurrItemForBid, zone=core.CurrentRaidZone, date=date, boss=core.LastKilledBoss, cost=cost})
				MonDKP:UpdateSeeds()
				local temp_table = {}
				tinsert(temp_table, {seed = MonDKP_Loot.seed, {player=winner, loot=CurrItemForBid, zone=core.CurrentRaidZone, date=date, boss=core.LastKilledBoss, cost=cost}})
				MonDKP:LootHistory_Reset();
				MonDKP:LootHistory_Update("No Filter")
				local leader = MonDKP:GetGuildRankGroup(1)
				GuildRosterSetPublicNote(leader[1].index, time())
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
				MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])

				if _G["MonDKPBiddingStartBiddingButton"] then
					_G["MonDKPBiddingStartBiddingButton"]:SetText("Start Bidding")
					_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
						ToggleTimerBtn(self)
					end)
					timerToggle = 0;
				end

				core.BidInProgress = false;
				MonDKP:BroadcastStopBidTimer()

				if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
					local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
					local val = GetMinBid(CurrItemForBid);
					
					if not search and core.BiddingWindow.cost:GetText() ~= tonumber(val) then
						tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
						core.BiddingWindow.CustomMinBid:SetShown(true);
					 	core.BiddingWindow.CustomMinBid:SetChecked(true);
					elseif search and core.BiddingWindow.cost:GetText() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
						if MonDKP_MinBids[search[1][1]].minbid ~= core.BiddingWindow.cost:GetText() then
							MonDKP_MinBids[search[1][1]].minbid = core.BiddingWindow.cost:GetNumber();
							core.BiddingWindow.CustomMinBid:SetShown(true);
					 		core.BiddingWindow.CustomMinBid:SetChecked(true);
						end
					end

					if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
						table.remove(MonDKP_MinBids, search[1][1])
						core.BiddingWindow.CustomMinBid:SetShown(false);
					end
				end
				
				if mode == "Zero Sum" then
					MonDKP_DB.modes.ZeroSumBank.balance = MonDKP_DB.modes.ZeroSumBank.balance + tonumber(cost)
					table.insert(MonDKP_DB.modes.ZeroSumBank, { loot = CurrItemForBid, cost = tonumber(cost) })
					MonDKP:ZeroSumBank_Update()
					MonDKP.Sync:SendData("MonDKPZeroSum", MonDKP_DB.modes.ZeroSumBank)
				end

				core.BiddingWindow:Hide()
				table.wipe(temp_table)
				ClearBidWindow()
			  end,
			  timeout = 0,
			  whileDead = true,
			  hideOnEscape = true,
			  preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_AWARD")
		end
	end
end

function MonDKP:BroadcastBidTimer(seconds, title, itemIcon)       -- broadcasts timer and starts it natively
	local title = title;
	MonDKP:StartBidTimer(seconds, title, itemIcon)
	MonDKP.Sync:SendData("MonDKPNotify", "StartBidTimer,"..seconds..","..title..","..itemIcon)
end

function MonDKP:BroadcastStopBidTimer()
	MonDKP.BidTimer:SetScript("OnUpdate", nil)
	MonDKP.BidTimer:Hide()
	MonDKP.Sync:SendData("MonDKPNotify", "StopBidTimer")
end

function MonDKP_Register_ShiftClickLootWindowHook()			-- hook function into LootFrame window (BREAKS if more than 4 loot slots... trying to fix)
	for i = 1, 4 do 
		getglobal("LootButton"..i):HookScript("OnClick", function()
	        if ( IsShiftKeyDown() and IsAltKeyDown() ) then
	        	MonDKP:CheckOfficer();
        		lootIcon, itemName, _, _, _ = GetLootSlotInfo(i)
        		itemLink = GetLootSlotLink(i)
	            MonDKP:ToggleBidWindow(itemLink, lootIcon, itemName)
	        end
		end)
	end
end

function MonDKP:StartBidTimer(seconds, title, itemIcon)
	local duration = tonumber(seconds)
	local title = title;
	local alpha = 1;

	MonDKP.BidTimer = MonDKP.BidTimer or MonDKP:CreateTimer();		-- recycles bid timer frame so multiple instances aren't created
	MonDKP.BidTimer:SetShown(not MonDKP.BidTimer:IsShown())					-- shows if not shown
	MonDKP.BidTimer:SetMinMaxValues(0, duration or 20)
	MonDKP.BidTimer.timerTitle:SetText(title)
	MonDKP.BidTimer.itemIcon:SetTexture(itemIcon)
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
			if CurrItemForBid then
				SendChatMessage("Bidding Closed!", "RAID_WARNING")
				events:UnregisterEvent("CHAT_MSG_SYSTEM")
			end
			core.BidInProgress = false;
			if _G["MonDKPBiddingStartBiddingButton"] then
				_G["MonDKPBiddingStartBiddingButton"]:SetText("Start Bidding")
				_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
					ToggleTimerBtn(self)
				end)
				timerToggle = 0;
			end
			MonDKP.BidTimer:SetScript("OnUpdate", nil)
			MonDKP.BidTimer:Hide();
		end
	end)
end

function MonDKP:CreateTimer()

	local f = CreateFrame("StatusBar", nil, UIParent)
	f:SetSize(300, 25)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(18)
	f:SetBackdrop({
	    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground", tile = true,
	  });
	f:SetBackdropColor(0, 0, 0, 0.7)
	f:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])
	f:SetMovable(true);
	f:EnableMouse(true);
	f:SetScale(MonDKP_DB.defaults.BidTimerSize)
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
	f.border:SetSize(300, 25);
	f.border:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.border:SetBackdropColor(0,0,0,0);
	f.border:SetBackdropBorderColor(1,1,1,1)

	f.timerTitle = f:CreateFontString(nil, "OVERLAY")
	f.timerTitle:SetFontObject("MonDKPNormalOutlineLeft")
	f.timerTitle:SetWidth(270)
	f.timerTitle:SetHeight(25)
	f.timerTitle:SetTextColor(1, 1, 1, 1);
	f.timerTitle:SetPoint("LEFT", f, "LEFT", 3, 0);
	f.timerTitle:SetText(nil);

	f.timertext = f:CreateFontString(nil, "OVERLAY")
	f.timertext:SetFontObject("MonDKPSmallOutlineRight")
	f.timertext:SetTextColor(1, 1, 1, 1);
	f.timertext:SetPoint("RIGHT", f, "RIGHT", -5, 0);
	f.timertext:SetText(nil);

	f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	f.itemIcon:SetPoint("RIGHT", f, "LEFT", 0, 0);
	f.itemIcon:SetColorTexture(0, 0, 0, 1)
	f.itemIcon:SetSize(25, 25);

	return f;
end

local function BidRow_OnClick(self)
	if SelectedBidder.player == strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1) then
		for i=1, numrows do
			core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
			core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
		end
		SelectedBidder = {}
	else
		for i=1, numrows do
			core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
			core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
		end
	    self:SetNormalTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
	    self:GetNormalTexture():SetAlpha(0.7)

	    if MonDKP_DB.modes.costvalue == "Percent" then
	    	SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), dkp=tonumber(self.Strings[3]:GetText())}
	    else
	    	SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), bid=tonumber(self.Strings[2]:GetText())}
	    end
    end
end

local function RightClickMenu(self)
	local menu;
  
	menu = {
		{ text = "Remove Entry", notCheckable = true, func = function()
			table.remove(Bids_Submitted, self.index)
			SelectedBidder = {}
			for i=1, #core.BiddingWindow.bidTable.Rows do
				core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
				core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
			end
			BidScrollFrame_Update()
		end },
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 1);
end

function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.Strings = {}
    f:SetSize(width, height)
    f:SetHighlightTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    f:SetScript("OnClick", BidRow_OnClick)
    for i=1, 3 do
        f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
        f.Strings[i]:SetTextColor(1, 1, 1, 1);
        if i==1 then 
        	f.Strings[i]:SetFontObject("MonDKPNormalLeft");
        else
        	f.Strings[i]:SetFontObject("MonDKPNormalCenter");
        end
    end
    f.Strings[1]:SetWidth((width/2)-10)
    f.Strings[2]:SetWidth(width/4)
    f.Strings[3]:SetWidth(width/4)
    f.Strings[1]:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.Strings[2]:SetPoint("LEFT", f.Strings[1], "RIGHT", 0, 0)
    f.Strings[3]:SetPoint("RIGHT", 0, 0)

    f:SetScript("OnMouseDown", function(self, button)
      if button == "RightButton" then
        RightClickMenu(self)
      end
    end)

    return f
end

local function SortBidTable()             -- sorts the Loot History Table by date
	mode = MonDKP_DB.modes.mode;
	table.sort(Bids_Submitted, function(a, b)
	    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
	    	return a["bid"] > b["bid"]
	    elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
	    	return a["dkp"] > b["dkp"]
	    elseif mode == "Roll Based Bidding" then
	    	return a["roll"] > b["roll"]
	    end
  	end)
end

function BidScrollFrame_Update()
	local numOptions = #Bids_Submitted;
	local index, row
    local offset = FauxScrollFrame_GetOffset(core.BiddingWindow.bidTable) or 0
    local rank;

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
        rank = MonDKP:GetGuildRank(Bids_Submitted[i].player)
        if Bids_Submitted[index] then
            row:Show()
            row.index = index
            row.Strings[1]:SetText(Bids_Submitted[i].player.." |cff666666("..rank..")|r")
            row.Strings[1]:SetTextColor(c.r, c.g, c.b, 1)
            if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
            	row.Strings[2]:SetText(Bids_Submitted[i].bid)
            	row.Strings[3]:SetText(MonDKP_DKPTable[dkp_total[1][1]].dkp)
            elseif mode == "Roll Based Bidding" then
            	local minRoll;
            	local maxRoll;

            	if MonDKP_DB.modes.rolls.UsePerc then
            		if MonDKP_DB.modes.rolls.min == 0 or MonDKP_DB.modes.rolls.min == 1 then
            			minRoll = 1;
            		else
            			minRoll = MonDKP_DKPTable[dkp_total[1][1]].dkp * (MonDKP_DB.modes.rolls.min / 100);
            		end
            		maxRoll = MonDKP_DKPTable[dkp_total[1][1]].dkp * (MonDKP_DB.modes.rolls.max / 100) + MonDKP_DB.modes.rolls.AddToMax;
            	elseif not MonDKP_DB.modes.rolls.UsePerc then
            		minRoll = MonDKP_DB.modes.rolls.min;

            		if MonDKP_DB.modes.rolls.max == 0 then
            			maxRoll = MonDKP_DKPTable[dkp_total[1][1]].dkp + MonDKP_DB.modes.rolls.AddToMax;
            		else
            			maxRoll = MonDKP_DB.modes.rolls.max + MonDKP_DB.modes.rolls.AddToMax;
            		end
            	end
            	if tonumber(minRoll) < 1 then minRoll = 1 end

            	row.Strings[2]:SetText(Bids_Submitted[i].roll..Bids_Submitted[i].range)
            	row.Strings[3]:SetText(round(minRoll, 0).."-"..round(maxRoll,0))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
            	row.Strings[3]:SetText(Bids_Submitted[i].dkp)
            end
        else
            row:Hide()
        end
    end
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
	    if MonDKP_DB.modes.CostSelection == "First Bidder" and Bids_Submitted[1] then
	    	core.BiddingWindow.cost:SetText(Bids_Submitted[1].bid)
	    elseif MonDKP_DB.modes.CostSelection == "Second Bidder" and Bids_Submitted[2] then
	    	core.BiddingWindow.cost:SetText(Bids_Submitted[2].bid)
	    end
	end
    FauxScrollFrame_Update(core.BiddingWindow.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function MonDKP:CreateBidWindow()
	local f = CreateFrame("Frame", "MonDKP_BiddingWindow", UIParent, "ShadowOverlaySmallTemplate");
	mode = MonDKP_DB.modes.mode;

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(400, 500);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:SetScript("OnHide", function ()
		if core.BidInProgress then
			MonDKP:Print("Bidding window closed with a bid in progress! Type /dkp bid to reopen to current bid session.")
		end
	end)
	f:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if MonDKP.UIConfig then MonDKP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	  -- Close Button
	f.closeContainer = CreateFrame("Frame", "MonDKPBiddingWindowCloseButtonContainer", f)
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
	f.boss:SetFontObject("MonDKPNormalLeft");
	f.boss:SetPoint("LEFT", f.bossHeader, "RIGHT", 5, 0);
	f.boss:SetSize(300, 28)


	f.itemHeader = f:CreateFontString(nil, "OVERLAY")
	f.itemHeader:SetFontObject("MonDKPLargeRight");
	f.itemHeader:SetScale(0.7)
	f.itemHeader:SetPoint("TOP", f.bossHeader, "BOTTOM", 0, -25);
	f.itemHeader:SetText("Item:")

	f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);
	f.itemIcon:SetPoint("LEFT", f.itemHeader, "RIGHT", 8, 0);
	f.itemIcon:SetColorTexture(0, 0, 0, 1)
	f.itemIcon:SetSize(28, 28);

	f.item = f:CreateFontString(nil, "OVERLAY")
	f.item:SetFontObject("MonDKPNormalLeft");
	f.item:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 2);
	f.item:SetSize(200, 28)

	f.itemName = f:CreateFontString(nil, "OVERLAY") 			-- hidden itemName field
	f.itemName:SetFontObject("MonDKPNormalLeft");

	f.minBidHeader = f:CreateFontString(nil, "OVERLAY")
	f.minBidHeader:SetFontObject("MonDKPLargeRight");
	f.minBidHeader:SetScale(0.7)
	f.minBidHeader:SetPoint("TOP", f.itemHeader, "BOTTOM", -30, -25);
	
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		f.minBidHeader:SetText("Minimum Bid: ")
		
		f.minBid = CreateFrame("EditBox", nil, f)
		f.minBid:SetPoint("LEFT", f.minBidHeader, "RIGHT", 8, 0)   
	    f.minBid:SetAutoFocus(false)
	    f.minBid:SetMultiLine(false)
	    f.minBid:SetSize(70, 28)
	    f.minBid:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.minBid:SetBackdropColor(0,0,0,0.9)
	    f.minBid:SetBackdropBorderColor(1,1,1,0.4)
	    f.minBid:SetMaxLetters(4)
	    f.minBid:SetTextColor(1, 1, 1, 1)
	    f.minBid:SetFontObject("MonDKPSmallRight")
	    f.minBid:SetTextInsets(10, 10, 5, 5)
	    f.minBid.tooltipText = "Minimum Bid";
	    f.minBid.tooltipDescription = "Minimum bid value that will be accepted."
	    f.minBid.tooltipWarning = "Defaults can be set in Options tab."
	    f.minBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	      self:ClearFocus()
	    end)
	    f.minBid:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Minimum Bid", 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine("Minimum bid value that will be accepted.", 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine("Defaults can be set in Options tab.", 1.0, 0, 0, true);
			GameTooltip:AddLine("If you enter a value other than what is set in Options, that custom value will be stored for that specific item.", 1.0, 0.5, 0, true);
			GameTooltip:Show();
		end)
		f.minBid:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end

	f.CustomMinBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.CustomMinBid:SetChecked(true)
	f.CustomMinBid:SetScale(0.6);
	f.CustomMinBid.text:SetText("  |cff5151deCustom|r");
	f.CustomMinBid.text:SetScale(1.5);
	f.CustomMinBid.text:SetFontObject("MonDKPSmallLeft")
	f.CustomMinBid.text:SetPoint("LEFT", f.CustomMinBid, "RIGHT", -10, 0)
	f.CustomMinBid:Hide();
	f.CustomMinBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Custom Minimum Bid", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("You have set a custom minimum bid for this item. Uncheck this box to use the standard bid for this item type (set in Options tab).", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Starting bid with this unchecked will delete the custom minimum bid value from the database.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.CustomMinBid:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
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
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.bidTimer:SetBackdropColor(0,0,0,0.9)
    f.bidTimer:SetBackdropBorderColor(1,1,1,0.4)
    f.bidTimer:SetMaxLetters(4)
    f.bidTimer:SetTextColor(1, 1, 1, 1)
    f.bidTimer:SetFontObject("MonDKPSmallRight")
    f.bidTimer:SetTextInsets(10, 10, 5, 5)
    f.bidTimer.tooltipText = "Bid Timer";
    f.bidTimer.tooltipDescription = "How long bidding for this item will stay open in seconds."
    f.bidTimer.tooltipWarning = "Default can be set in Options tab."
    f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    f.bidTimer:SetScript("OnEnter", function(self)
		if (self.tooltipText) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
		end
		if (self.tooltipDescription) then
			GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end
		if (self.tooltipWarning) then
			GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
			GameTooltip:Show();
		end
	end)
	f.bidTimer:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.bidTimerFooter = f:CreateFontString(nil, "OVERLAY")
	f.bidTimerFooter:SetFontObject("MonDKPNormalLeft");
	f.bidTimerFooter:SetPoint("LEFT", f.bidTimer, "RIGHT", 5, 0);
	f.bidTimerFooter:SetText("Seconds")

	f.StartBidding = CreateFrame("Button", "MonDKPBiddingStartBiddingButton", f, "MonolithDKPButtonTemplate")
	f.StartBidding:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -100);
	f.StartBidding:SetSize(90, 25);
	f.StartBidding:SetText("Start Bidding");
	f.StartBidding:GetFontString():SetTextColor(1, 1, 1, 1)
	f.StartBidding:SetNormalFontObject("MonDKPSmallCenter");
	f.StartBidding:SetHighlightFontObject("MonDKPSmallCenter");
	f.StartBidding:SetScript("OnClick", function (self)
		ToggleTimerBtn(self)
	end)
	f.StartBidding:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Start Bidding", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Begins bidding for current item. Bids will only be accepted while this is running.", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("Bidding duration can be set in \"Bid Timer\" box.", 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.StartBidding:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ClearBidWindow = MonDKP:CreateButton("TOP", f.StartBidding, "BOTTOM", 0, -10, "Clear Window");
	f.ClearBidWindow:SetSize(90,25)
	f.ClearBidWindow:SetScript("OnClick", ClearBidWindow)
	f.ClearBidWindow:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText("Clear Window", 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine("Clears all item information and submitted bids from window.", 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.ClearBidWindow:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)


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
	mode = MonDKP_DB.modes.mode;

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

	headerButtons.player:SetPoint("LEFT", f.BidTable_Headers, "LEFT", 2, 0)
	headerButtons.bid:SetPoint("LEFT", headerButtons.player, "RIGHT", 0, 0)
	headerButtons.dkp:SetPoint("RIGHT", f.BidTable_Headers, "RIGHT", -1, 0)

	for k, v in pairs(headerButtons) do
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		if k == "player" then
			if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
				v:SetSize((width/2)-1, height)
			elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
				v:SetSize((width*0.75)-1, height)
			end
		else
			if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
				v:SetSize((width/4)-1, height)
			elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
				if k == "bid" then
					v:Hide()
				else
					v:SetSize((width/4)-1, height)
				end
			end
			
		end
	end

	headerButtons.player.t = headerButtons.player:CreateFontString(nil, "OVERLAY")
	headerButtons.player.t:SetFontObject("MonDKPNormalLeft")
	headerButtons.player.t:SetTextColor(1, 1, 1, 1);
	headerButtons.player.t:SetPoint("LEFT", headerButtons.player, "LEFT", 20, 0);
	headerButtons.player.t:SetText("Player"); 

	headerButtons.bid.t = headerButtons.bid:CreateFontString(nil, "OVERLAY")
	headerButtons.bid.t:SetFontObject("MonDKPNormal");
	headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
	headerButtons.bid.t:SetPoint("CENTER", headerButtons.bid, "CENTER", 0, 0);
	
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		headerButtons.bid.t:SetText("Bid"); 
	elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		headerButtons.bid.t:Hide(); 
	elseif mode == "Roll Based Bidding" then
		headerButtons.bid.t:SetText("Player Roll")
	end

	headerButtons.dkp.t = headerButtons.dkp:CreateFontString(nil, "OVERLAY")
	headerButtons.dkp.t:SetFontObject("MonDKPNormal")
	headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	headerButtons.dkp.t:SetPoint("CENTER", headerButtons.dkp, "CENTER", 0, 0);
	
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		headerButtons.dkp.t:SetText("Total DKP");
	elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		headerButtons.dkp.t:SetText("DKP");
	elseif mode == "Roll Based Bidding" then
		headerButtons.dkp.t:SetText("Expected Roll")
	end
    
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
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.cost:SetBackdropColor(0,0,0,0.9)
    f.cost:SetBackdropBorderColor(1,1,1,0.4)
    f.cost:SetMaxLetters(4)
    f.cost:SetTextColor(1, 1, 1, 1)
    f.cost:SetFontObject("MonDKPSmallRight")
    f.cost:SetTextInsets(10, 10, 5, 5)
    f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)

	f.costHeader = f:CreateFontString(nil, "OVERLAY")
	f.costHeader:SetFontObject("MonDKPLargeRight");
	f.costHeader:SetScale(0.7)
	f.costHeader:SetPoint("RIGHT", f.cost, "LEFT", -7, 0);
	f.costHeader:SetText("Item Cost: ")

	if MonDKP_DB.modes.costvalue == "Percent" then
		f.cost.perc = f.cost:CreateFontString(nil, "OVERLAY")
		f.cost.perc:SetFontObject("MonDKPNormalLeft");
		f.cost.perc:SetPoint("LEFT", f.cost, "RIGHT", -15, 1);
		f.cost.perc:SetText("%")
		f.cost:SetTextInsets(10, 15, 5, 5)
	end

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		f.CustomMinBid:SetPoint("LEFT", f.minBid, "RIGHT", 10, 0);
	elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		f.CustomMinBid:SetPoint("LEFT", f.cost, "RIGHT", 10, 0);
	end

	f.StartBidding = MonDKP:CreateButton("LEFT", f.cost, "RIGHT", 80, 0, "Award Item");
	f.StartBidding:SetSize(90,25)
	f.StartBidding:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if SelectedBidder["player"] then
			AwardItem()
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