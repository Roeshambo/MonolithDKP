local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

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

		if GetLocale() == 'deDE' then RANDOM_ROLL_RESULT = "%s w\195\188rfelt. Ergebnis: %d (%d-%d)" end
		local pattern = string.gsub(RANDOM_ROLL_RESULT, "[%(%)-]", "%%%1")
		pattern = string.gsub(pattern, "%%s", "(.+)")
		pattern = string.gsub(pattern, "%%d", "%(%%d+%)")

		for name, roll, low, high in string.gmatch(arg1, pattern) do
			local search = MonDKP:Table_Search(MonDKP_DKPTable, name)

			if search and mode == "Roll Based Bidding" and core.BiddingWindow.cost:GetNumber() > MonDKP_DKPTable[search[1][1]].dkp and not MonDKP_DB.modes.SubZeroBidding and MonDKP_DB.modes.costvalue ~= "Percent" then
        		SendChatMessage(L["RollNotAccepted"].." "..MonDKP_DKPTable[search[1][1]].dkp.." "..L["DKP"]..".", "WHISPER", nil, name)

        		return;
            end

			if not MonDKP:Table_Search(Bids_Submitted, name) and search then
				table.insert(Bids_Submitted, {player=name, roll=roll, range=" ("..low.."-"..high..")"})
			else
				if not search then
					SendChatMessage(L["NameNotFound"], "WHISPER", nil, name)
				else
					SendChatMessage(L["OnlyOneRollWarn"], "WHISPER", nil, name)
				end
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
	local response = L["ErrorProcessing"];
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
						response = L["BidCancelled"]
						--SendChatMessage(response, "WHISPER", nil, name)
						--return;
					end
				end
				if not response then
					response = L["NotSubmittedBid"]
				end
			end
			dkp = tonumber(MonDKP:GetPlayerDKP(name))
			if not dkp then		-- exits function if player is not on the DKP list
				response = L["InvalidPlayer"]
				SendChatMessage(response, "WHISPER", nil, name)
				return
			end
			if (tonumber(cmd) and (MonDKP_DB.modes.MaximumBid == nil or tonumber(cmd) <= MonDKP_DB.modes.MaximumBid or MonDKP_DB.modes.MaximumBid == 0)) or ((mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) and not cmd) then
				if dkp then
					if not MonDKP_DB.modes.SubZeroBidding then MonDKP_DB.modes.SubZeroBidding = false end
					if (cmd and cmd <= dkp) or (MonDKP_DB.modes.SubZeroBidding == true and dkp >= 0) or (MonDKP_DB.modes.SubZeroBidding == true and MonDKP_DB.modes.AllowNegativeBidders == true) or (mode == "Static Item Values" and dkp > 0 and (dkp > core.BiddingWindow.cost:GetNumber() or MonDKP_DB.modes.SubZeroBidding == true or MonDKP_DB.modes.costvalue == "Percent")) or ((mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") and not cmd) then
						if (cmd and core.BiddingWindow.minBid and tonumber(core.BiddingWindow.minBid:GetNumber()) <= cmd) or mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid" and cmd >= core.BiddingWindow.minBid:GetNumber()) then
							for i=1, #Bids_Submitted do 					-- checks if a bid was submitted, removes last bid if it was
								if Bids_Submitted[i] and Bids_Submitted[i].player == name then
									table.remove(Bids_Submitted, i)
								end
							end
							if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
								table.insert(Bids_Submitted, {player=name, bid=cmd})
								response = L["YourBidOf"].." "..cmd.." "..L["DKPWasAccepted"].."."
							elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
								table.insert(Bids_Submitted, {player=name, dkp=dkp})
								response = L["BidWasAccepted"]
							end
								
							BidScrollFrame_Update()
						else
							response = L["BidDeniedMinBid"].." "..core.BiddingWindow.minBid:GetNumber().."!"
						end
					elseif MonDKP_DB.modes.SubZeroBidding == true and dkp < 0 then
						response = L["BidDeniedNegative"].." ("..dkp.." "..L["DKP"]..")."
					else
						response = L["BidDeniedOnlyHave"].." "..dkp.." "..L["DKP"]
					end
				end
			elseif not cmd and (mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) then
				response = L["BidDeniedNoValue"]
			elseif cmd ~= "cancel" and (tonumber(cmd) and tonumber(cmd) > MonDKP_DB.modes.MaximumBid) then
				response = L["BidDeniedExceedMax"].." "..MonDKP_DB.modes.MaximumBid.." "..L["DKP"].."."
			else
				if cmd ~= "cancel" then
					response = L["BidDeniedInvalid"]
				end
			end
			SendChatMessage(response, "WHISPER", nil, name)
		else
			SendChatMessage(L["NoBidInProgress"], "WHISPER", nil, name)
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
				response = "MonolithDKP: "..MonDKP_DKPTable[search[1][1]].player.." "..L["CurrentlyHas"].." "..MonDKP_DKPTable[search[1][1]].dkp.." "..L["DKPAvailable"].."."
			else
				response = "MonolithDKP: "..L["PlayerNotFound"]
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
	        	range = range.." "..L["Use"].." /random "..MonDKP_round(minimum, 0).."-"..MonDKP_round(maximum, 0).." "..L["ToBid"].." "..perc..".";
	        end

			if search then
				response = "MonolithDKP: "..L["YouCurrentlyHave"].." "..MonDKP_DKPTable[search[1][1]].dkp.." "..L["DKP"].."."..range;
			else
				response = "MonolithDKP: "..L["PlayerNotFound"]
			end
		end

		SendChatMessage(response, "WHISPER", nil, name)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)			-- suppresses outgoing whisper responses to limit spam
		if core.BidInProgress and MonDKP_DB.defaults.SupressTells then
			if strfind(msg, L["YourBidOf"]) == 1 then
				return true
			elseif strfind(msg, L["BidDeniedFilter"]) == 1 then
				return true
			elseif strfind(msg, L["BidAcceptedFilter"]) == 1 then
				return true;
			elseif strfind(msg, L["NotSubmittedBid"]) == 1 then
				return true;
			elseif strfind(msg, L["OnlyOneRollWarn"]) == 1 then
				return true;
			elseif strfind(msg, L["RollNotAccepted"]) == 1 then
				return true;
			elseif strfind(msg, L["YourBid"].." "..L["ManuallyDenied"]) == 1 then
				return true;
			end
		end

		if strfind(msg, "MonolithDKP: ") == 1 then
			return true
		elseif strfind(msg, L["NoBidInProgress"]) == 1 then
			return true
		elseif strfind(msg, L["BidCancelled"]) == 1 then
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

function MonDKP:GetMinBid(itemLink)
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
	mode = MonDKP_DB.modes.mode;

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
		 					core.BiddingWindow.minBid:SetText(MonDKP_round(minBid, MonDKP_DB.modes.rounding))
		 				else
		 					core.BiddingWindow.minBid:SetText(MonDKP:GetMinBid(CurrItemForBid))
		 				end
		 			end)
		 		elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		 			core.BiddingWindow.CustomMinBid:Show();
		 			core.BiddingWindow.CustomMinBid:SetChecked(true)
		 			core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
		 				if self:GetChecked() == true then
		 					core.BiddingWindow.cost:SetText(MonDKP_round(minBid, MonDKP_DB.modes.rounding))
		 				else
		 					core.BiddingWindow.cost:SetText(MonDKP:GetMinBid(CurrItemForBid))
		 				end
		 			end)
		 		end
	 		else
	 			minBid = MonDKP:GetMinBid(CurrItemForBid)
	 			core.BiddingWindow.CustomMinBid:Hide();
	 		end
	 		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
 				core.BiddingWindow.minBid:SetText(MonDKP_round(minBid, MonDKP_DB.modes.rounding))
 			end

	 		core.BiddingWindow.cost:SetText(MonDKP_round(minBid, MonDKP_DB.modes.rounding))
	 		core.BiddingWindow.itemName:SetText(itemName)
	 		core.BiddingWindow.bidTimer:SetText(core.settings["DKPBonus"]["BidTimer"])
	 		core.BiddingWindow.boss:SetText(core.LastKilledBoss)
	 	end
	 	UpdateBidWindow()
	 	BidScrollFrame_Update()
	else
		MonDKP:Print(L["NoPermission"])
	end
end

local function StartBidding()
	local perc;
	mode = MonDKP_DB.modes.mode;

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BiddingWindow.cost:SetNumber(MonDKP_round(core.BiddingWindow.minBid:GetNumber(), MonDKP_DB.modes.rounding))
		MonDKP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), CurrItemIcon)

		local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
		local val = MonDKP:GetMinBid(CurrItemForBid);
		
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
					channelText = channelText.." "..L["OR"].." "..channels[i]
				else
					channelText = channelText..", "..channels[i]
				end
			end
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
			SendChatMessage(L["TakingBidsOn"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.minBid:GetText().." "..L["DKPMinBid"]..")", "RAID_WARNING")
			SendChatMessage(L["ToBidUse"].." "..channelText.." "..L["ToSend"].." !bid <"..L["Value"].."> (ex: !bid "..core.BiddingWindow.minBid:GetText().."). "..L["OR"].." !bid cancel "..L["ToWithdrawBid"], "RAID_WARNING")
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
			SendChatMessage(L["TakingBidsOn"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
			SendChatMessage(L["ToBidUse"].." "..channelText.." "..L["ToSend"].." !bid. "..L["OR"].." !bid cancel "..L["ToWithdrawBid"], "RAID_WARNING")
		elseif mode == "Roll Based Bidding" then
			SendChatMessage(L["RollFor"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")", "RAID_WARNING")
			SendChatMessage(L["ToBidRollRange"].." "..channelText.." "..L["With"].." !dkp", "RAID_WARNING")
		end
	end
end

local function ToggleTimerBtn(self)
	mode = MonDKP_DB.modes.mode;

	if timerToggle == 0 then
		--if not IsInRaid() then MonDKP:Print("You are not in a raid.") return false end
		if (mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.minBid:GetText() == "") then MonDKP:Print(L["NoMinBidOrItem"]) return false end
		if (mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then MonDKP:Print(L["NoItemOrItemCost"]) return false end
		if mode == "Roll Based Bidding" and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then MonDKP:Print(L["NoItemOrItemCost"]) return false end

		timerToggle = 1;
		self:SetText(L["EndBidding"])
		StartBidding()
	else
		timerToggle = 0;
		core.BidInProgress = false;
		self:SetText(L["StartBidding"])
		SendChatMessage(L["BiddingClosed"], "RAID_WARNING")
		events:UnregisterEvent("CHAT_MSG_SYSTEM")
		MonDKP:BroadcastStopBidTimer()
	end
end

function ClearBidWindow()
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
	_G["MonDKPBiddingStartBiddingButton"]:SetText(L["StartBidding"])
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

--[[local function AwardItem()   			-- function no longer in use.
	local cost;
	local winner;
	local curTime;
	local selected;
	local curZone = GetRealZoneText();

	MonDKP:SeedVerify_Update()
	if core.UpToDate == false and core.IsOfficer == true then
		StaticPopupDialogs["CONFIRM_PUSH"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OutdateModifyWarn"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				if SelectedBidder["player"] then
					cost = core.BiddingWindow.cost:GetNumber();
					winner = SelectedBidder["player"];
					curTime = time()

					if strlen(strtrim(core.BiddingWindow.boss:GetText(), " ")) < 1 then
						StaticPopupDialogs["VALIDATE_BOSS"] = {
							text = L["InvalidBossName"],
							button1 = L["OK"],
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}
						StaticPopup_Show ("VALIDATE_BOSS")
						return;
					end
					
					if MonDKP_DB.modes.costvalue == "Percent" then
						if MonDKP_DB.modes.mode == "Roll Based Bidding" then
							local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

							if search then
								cost = MonDKP_round(MonDKP_DKPTable[search[1][1]]--[[.dkp * (cost / 100), MonDKP_DB.modes.rounding);
							else
								print(L["Error"])
							end
						else
							cost = MonDKP_round(SelectedBidder["dkp"] * (cost / 100), MonDKP_DB.modes.rounding);
						end
						selected = L["AwardItemTo"].." "..SelectedBidder["player"].." "..L["For"].." |CFF00ff00"..MonDKP_round(cost, MonDKP_DB.modes.rounding).."|r (|CFFFF0000"..core.BiddingWindow.cost:GetNumber().."%%|r) "..L["DKP"].."?";
					else
						cost = MonDKP_round(cost, MonDKP_DB.modes.rounding)
						selected = "Award item to "..SelectedBidder["player"].." "..L["For"].." |CFF00ff00"..MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding).."|r "..L["DKP"].."?";
					end

					StaticPopupDialogs["CONFIRM_AWARD"] = {
					  text = selected,
					  button1 = L["YES"],
					  button2 = L["NO"],
					  OnAccept = function()
						SendChatMessage(L["Congrats"].." "..winner.." "..L["On"].." "..CurrItemForBid.." @ "..cost.." "..L["DKP"], "RAID_WARNING")
						MonDKP:DKPTable_Set(winner, "dkp", MonDKP_round(-cost, MonDKP_DB.modes.rounding), true)
						tinsert(MonDKP_Loot, {player=winner, loot=CurrItemForBid, zone=curZone, date=curTime, boss=core.BiddingWindow.boss:GetText(), cost=cost})
						local temp_table = {}
						tinsert(temp_table, {seed = MonDKP_Loot.seed, {player=winner, loot=CurrItemForBid, zone=curZone, date=curTime, boss=core.BiddingWindow.boss:GetText(), cost=cost}})
						MonDKP:LootHistory_Reset();
						MonDKP:LootHistory_Update("No Filter")
						local leader = MonDKP:GetGuildRankGroup(1)
						MonDKP:RosterSeedUpdate(leader[1].index)
						MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
						MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])

						if _G["MonDKPBiddingStartBiddingButton"] then
							_G["MonDKPBiddingStartBiddingButton"]:SetText(L["StartBidding"])
							_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
								ToggleTimerBtn(self)
							end)
							timerToggle = 0;
						end

						core.BidInProgress = false;
						MonDKP:BroadcastStopBidTimer()

						if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
							local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
							local val = MonDKP:GetMinBid(CurrItemForBid);
							
							if not search and core.BiddingWindow.cost:GetText() ~= tonumber(val) then
								tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
								core.BiddingWindow.CustomMinBid:SetShown(true);
							 	core.BiddingWindow.CustomMinBid:SetChecked(true);
							elseif search and core.BiddingWindow.cost:GetText() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
								if MonDKP_MinBids[search[1][1]]--[[.minbid ~= core.BiddingWindow.cost:GetText() then
									MonDKP_MinBids[search[1][1]]--[[.minbid = MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding);
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
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("CONFIRM_PUSH")
	else
		if SelectedBidder["player"] then
			cost = core.BiddingWindow.cost:GetNumber();
			winner = SelectedBidder["player"];
			curTime = time()

			if strlen(strtrim(core.BiddingWindow.boss:GetText(), " ")) < 1 then
				StaticPopupDialogs["VALIDATE_BOSS"] = {
					text = L["InvalidBossName"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("VALIDATE_BOSS")
				return;
			end
			
			if MonDKP_DB.modes.costvalue == "Percent" then
				if MonDKP_DB.modes.mode == "Roll Based Bidding" then
					local search = MonDKP:Table_Search(MonDKP_DKPTable, winner);

					if search then
						cost = MonDKP_round(MonDKP_DKPTable[search[1][1]]--[[.dkp * (cost / 100), MonDKP_DB.modes.rounding);
					else
						print(L["Error"])
					end
				else
					cost = MonDKP_round(SelectedBidder["dkp"] * (cost / 100), MonDKP_DB.modes.rounding);
				end
				selected = L["AwardItemTo"].." "..SelectedBidder["player"].." "..L["For"].." |CFF00ff00"..MonDKP_round(cost, MonDKP_DB.modes.rounding).."|r (|CFFFF0000"..core.BiddingWindow.cost:GetNumber().."%%|r) "..L["DKP"].."?";
			else
				cost = MonDKP_round(cost, MonDKP_DB.modes.rounding)
				selected = L["AwardItemTo"].." "..SelectedBidder["player"].." "..L["For"].." |CFF00ff00"..MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding).."|r "..L["DKP"].."?";
			end

			StaticPopupDialogs["CONFIRM_AWARD"] = {
			  text = selected,
			  button1 = L["YES"],
			  button2 = L["NO"],
			  OnAccept = function()
				SendChatMessage(L["Congrats"].." "..winner.." "..L["On"].." "..CurrItemForBid.." @ "..cost.." "..L["DKP"], "RAID_WARNING")
				MonDKP:DKPTable_Set(winner, "dkp", MonDKP_round(-cost, MonDKP_DB.modes.rounding), true)
				tinsert(MonDKP_Loot, {player=winner, loot=CurrItemForBid, zone=curZone, date=curTime, boss=core.BiddingWindow.boss:GetText(), cost=cost})
				MonDKP:UpdateSeeds()
				local temp_table = {}
				tinsert(temp_table, {seed = MonDKP_Loot.seed, {player=winner, loot=CurrItemForBid, zone=curZone, date=curTime, boss=core.BiddingWindow.boss:GetText(), cost=cost}})
				MonDKP:LootHistory_Reset();
				MonDKP:LootHistory_Update("No Filter")
				local leader = MonDKP:GetGuildRankGroup(1)
				MonDKP:RosterSeedUpdate(leader[1].index)
				MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)
				MonDKP.Sync:SendData("MonDKPLootAward", temp_table[1])

				if _G["MonDKPBiddingStartBiddingButton"] then
					_G["MonDKPBiddingStartBiddingButton"]:SetText(L["StartBidding"])
					_G["MonDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
						ToggleTimerBtn(self)
					end)
					timerToggle = 0;
				end

				core.BidInProgress = false;
				MonDKP:BroadcastStopBidTimer()

				if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
					local search = MonDKP:Table_Search(MonDKP_MinBids, core.BiddingWindow.itemName:GetText())
					local val = MonDKP:GetMinBid(CurrItemForBid);
					
					if not search and core.BiddingWindow.cost:GetText() ~= tonumber(val) then
						tinsert(MonDKP_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.cost:GetNumber()})
						core.BiddingWindow.CustomMinBid:SetShown(true);
					 	core.BiddingWindow.CustomMinBid:SetChecked(true);
					elseif search and core.BiddingWindow.cost:GetText() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
						if MonDKP_MinBids[search[1][1]]--[[.minbid ~= core.BiddingWindow.cost:GetText() then
							MonDKP_MinBids[search[1][1]]--[[.minbid = MonDKP_round(core.BiddingWindow.cost:GetNumber(), MonDKP_DB.modes.rounding);
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
end--]]

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
	local num = GetNumLootItems();
	
	if getglobal("ElvLootSlot1") then 			-- fixes hook for ElvUI loot frame
		for i = 1, num do 
			getglobal("ElvLootSlot"..i):HookScript("OnClick", function()
		        if ( IsShiftKeyDown() and IsAltKeyDown() ) then
		        	MonDKP:CheckOfficer();
	        		lootIcon, itemName, _, _, _ = GetLootSlotInfo(i)
	        		itemLink = GetLootSlotLink(i)
		            MonDKP:ToggleBidWindow(itemLink, lootIcon, itemName)
		        end
			end)
		end
	else
		if num > 4 then num = 4 end

		for i = 1, num do 
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
		timerText = MonDKP_round(duration - timer, 1)
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
			MonDKP:Print(L["TenSecondsToBid"])
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
			if CurrItemForBid and core.BidInProgress then
				SendChatMessage(L["BiddingClosed"], "RAID_WARNING")
				events:UnregisterEvent("CHAT_MSG_SYSTEM")
			end
			core.BidInProgress = false;
			if _G["MonDKPBiddingStartBiddingButton"] then
				_G["MonDKPBiddingStartBiddingButton"]:SetText(L["StartBidding"])
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
		{ text = L["RemoveEntry"], notCheckable = true, func = function()
			if Bids_Submitted[self.index].bid then
				SendChatMessage(L["YourBidOf"].." "..Bids_Submitted[self.index].bid.." "..L["DKP"].." "..L["ManuallyDenied"], "WHISPER", nil, Bids_Submitted[self.index].player)
			else
				SendChatMessage(L["YourBid"].." "..L["ManuallyDenied"], "WHISPER", nil, Bids_Submitted[self.index].player)
			end
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
            	row.Strings[3]:SetText(MonDKP_round(MonDKP_DKPTable[dkp_total[1][1]].dkp, MonDKP_DB.modes.rounding))
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
            	row.Strings[3]:SetText(math.floor(minRoll).."-"..math.floor(maxRoll))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
            	row.Strings[3]:SetText(MonDKP_round(Bids_Submitted[i].dkp, MonDKP_DB.modes.rounding))
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
	f:SetClampedToScreen(true)
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
			MonDKP:Print(L["ClosedBidInProgress"])
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
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
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
	f.bossHeader:SetText(L["Boss"]..":")

	f.boss = CreateFrame("EditBox", nil, f)
	f.boss:SetFontObject("MonDKPNormalLeft");
	f.boss:SetAutoFocus(false)
	f.boss:SetMultiLine(false)
	f.boss:SetTextInsets(10, 15, 5, 5)
	f.boss:SetBackdrop({
    	bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2, 
	});
	f.boss:SetBackdropColor(0,0,0,0.6)
	f.boss:SetBackdropBorderColor(1,1,1,0.6)
	f.boss:SetPoint("LEFT", f.bossHeader, "RIGHT", 9, 0);
	f.boss:SetSize(200, 28)
	f.boss:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:HighlightText(0,0)
		self:ClearFocus()
	end)
	f.boss:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:HighlightText(0,0)
		self:ClearFocus()
	end)
	f.boss:SetScript("OnTabPressed", function(self)    -- clears focus on esc
		self:HighlightText(0,0)
		self:ClearFocus()
	end)

	f.itemHeader = f:CreateFontString(nil, "OVERLAY")
	f.itemHeader:SetFontObject("MonDKPLargeRight");
	f.itemHeader:SetScale(0.7)
	f.itemHeader:SetPoint("TOP", f.bossHeader, "BOTTOM", 0, -25);
	f.itemHeader:SetText(L["Item"]..":")

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
		f.minBidHeader:SetText(L["MinimumBid"]..": ")
		
		f.minBid = CreateFrame("EditBox", nil, f)
		f.minBid:SetPoint("LEFT", f.minBidHeader, "RIGHT", 8, 0)   
	    f.minBid:SetAutoFocus(false)
	    f.minBid:SetMultiLine(false)
	    f.minBid:SetSize(70, 28)
	    f.minBid:SetBackdrop({
      	  bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	    });
	    f.minBid:SetBackdropColor(0,0,0,0.6)
	    f.minBid:SetBackdropBorderColor(1,1,1,0.6)
	    f.minBid:SetMaxLetters(8)
	    f.minBid:SetTextColor(1, 1, 1, 1)
	    f.minBid:SetFontObject("MonDKPSmallRight")
	    f.minBid:SetTextInsets(10, 10, 5, 5)
	    f.minBid.tooltipText = L["MinimumBid"];
	    f.minBid.tooltipDescription = L["MinBidTTDesc"]
	    f.minBid.tooltipWarning = L["MinBidTTWarn"]
	    f.minBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	      self:ClearFocus()
	    end)
	    f.minBid:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MinimumBid"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MinBidTTDesc"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["MinBidTTWarn"], 1.0, 0, 0, true);
			GameTooltip:AddLine(L["MinBidTTExt"], 1.0, 0.5, 0, true);
			GameTooltip:Show();
		end)
		f.minBid:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end

	f.CustomMinBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.CustomMinBid:SetChecked(true)
	f.CustomMinBid:SetScale(0.6);
	f.CustomMinBid.text:SetText("  |cff5151de"..L["Custom"].."|r");
	f.CustomMinBid.text:SetScale(1.5);
	f.CustomMinBid.text:SetFontObject("MonDKPSmallLeft")
	f.CustomMinBid.text:SetPoint("LEFT", f.CustomMinBid, "RIGHT", -10, 0)
	f.CustomMinBid:Hide();
	f.CustomMinBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CustomMinBid"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["CustomMinBidTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["CustomMinBidTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.CustomMinBid:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

    f.bidTimerHeader = f:CreateFontString(nil, "OVERLAY")
	f.bidTimerHeader:SetFontObject("MonDKPLargeRight");
	f.bidTimerHeader:SetScale(0.7)
	f.bidTimerHeader:SetPoint("TOP", f.minBidHeader, "BOTTOM", 13, -25);
	f.bidTimerHeader:SetText(L["BidTimer"]..": ")

	f.bidTimer = CreateFrame("EditBox", nil, f)
	f.bidTimer:SetPoint("LEFT", f.bidTimerHeader, "RIGHT", 8, 0)   
    f.bidTimer:SetAutoFocus(false)
    f.bidTimer:SetMultiLine(false)
    f.bidTimer:SetSize(70, 28)
    f.bidTimer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    f.bidTimer:SetBackdropColor(0,0,0,0.6)
    f.bidTimer:SetBackdropBorderColor(1,1,1,0.6)
    f.bidTimer:SetMaxLetters(4)
    f.bidTimer:SetTextColor(1, 1, 1, 1)
    f.bidTimer:SetFontObject("MonDKPSmallRight")
    f.bidTimer:SetTextInsets(10, 10, 5, 5)
    f.bidTimer.tooltipText = L["BidTimer"];
    f.bidTimer.tooltipDescription = L["BidTimerTTDesc"]
    f.bidTimer.tooltipWarning = L["BidTimerTTWarn"]
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
	f.bidTimerFooter:SetText(L["Seconds"])

	f.StartBidding = CreateFrame("Button", "MonDKPBiddingStartBiddingButton", f, "MonolithDKPButtonTemplate")
	f.StartBidding:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -100);
	f.StartBidding:SetSize(90, 25);
	f.StartBidding:SetText(L["StartBidding"]);
	f.StartBidding:GetFontString():SetTextColor(1, 1, 1, 1)
	f.StartBidding:SetNormalFontObject("MonDKPSmallCenter");
	f.StartBidding:SetHighlightFontObject("MonDKPSmallCenter");
	f.StartBidding:SetScript("OnClick", function (self)
		ToggleTimerBtn(self)
	end)
	f.StartBidding:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["StartBidding"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["StartBiddingTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["StartBiddingTTWarn"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.StartBidding:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.ClearBidWindow = MonDKP:CreateButton("TOP", f.StartBidding, "BOTTOM", 0, -10, L["ClearBidWindow"]);
	f.ClearBidWindow:SetSize(90,25)
	f.ClearBidWindow:SetScript("OnClick", ClearBidWindow)
	f.ClearBidWindow:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ClearBidWindow"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ClearBidWindowTTDesc"], 1.0, 1.0, 1.0, true);
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
	headerButtons.player.t:SetText(L["Player"]); 

	headerButtons.bid.t = headerButtons.bid:CreateFontString(nil, "OVERLAY")
	headerButtons.bid.t:SetFontObject("MonDKPNormal");
	headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
	headerButtons.bid.t:SetPoint("CENTER", headerButtons.bid, "CENTER", 0, 0);
	
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		headerButtons.bid.t:SetText(L["Bid"]); 
	elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		headerButtons.bid.t:Hide(); 
	elseif mode == "Roll Based Bidding" then
		headerButtons.bid.t:SetText(L["PlayerRoll"])
	end

	headerButtons.dkp.t = headerButtons.dkp:CreateFontString(nil, "OVERLAY")
	headerButtons.dkp.t:SetFontObject("MonDKPNormal")
	headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	headerButtons.dkp.t:SetPoint("CENTER", headerButtons.dkp, "CENTER", 0, 0);
	
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
		headerButtons.dkp.t:SetText(L["TotalDKP"]);
	elseif mode == "Static Item Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Static") then
		headerButtons.dkp.t:SetText(L["DKP"]);
	elseif mode == "Roll Based Bidding" then
		headerButtons.dkp.t:SetText(L["ExpectedRoll"])
	end
    
    ------------------------------------
    --	AWARD ITEM
    ------------------------------------

    f.cost = CreateFrame("EditBox", nil, f)
	f.cost:SetPoint("TOPLEFT", f.bidTable, "BOTTOMLEFT", 71, -15)   
    f.cost:SetAutoFocus(false)
    f.cost:SetMultiLine(false)
    f.cost:SetSize(70, 28)
    f.cost:SetTextInsets(10, 10, 5, 5)
    f.cost:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    f.cost:SetBackdropColor(0,0,0,0.6)
    f.cost:SetBackdropBorderColor(1,1,1,0.6)
    f.cost:SetMaxLetters(8)
    f.cost:SetTextColor(1, 1, 1, 1)
    f.cost:SetFontObject("MonDKPSmallRight")
    f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    f.cost:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ItemCost"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ItemCostTTDesc"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.cost:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.costHeader = f:CreateFontString(nil, "OVERLAY")
	f.costHeader:SetFontObject("MonDKPLargeRight");
	f.costHeader:SetScale(0.7)
	f.costHeader:SetPoint("RIGHT", f.cost, "LEFT", -7, 0);
	f.costHeader:SetText(L["ItemCost"]..": ")

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

	f.StartBidding = MonDKP:CreateButton("LEFT", f.cost, "RIGHT", 80, 0, L["AwardItem"]);
	f.StartBidding:SetSize(90,25)
	f.StartBidding:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if SelectedBidder["player"] then
			if strlen(strtrim(core.BiddingWindow.boss:GetText(), " ")) < 1 then 			-- verifies there is a boss name
				StaticPopupDialogs["VALIDATE_BOSS"] = {
					text = L["InvalidBossName"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("VALIDATE_BOSS")
				return;
			end
			if core.UpToDate == false and core.IsOfficer == true then
			    StaticPopupDialogs["CONFIRM_PUSH"] = {
					text = "|CFFFF0000"..L["WARNING"].."|r: "..L["OutdateModifyWarn"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						MonDKP:AwardConfirm(SelectedBidder["player"], f.cost:GetNumber(), f.boss:GetText(), GetRealZoneText(), CurrItemForBid)
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("CONFIRM_PUSH")
			else
				MonDKP:AwardConfirm(SelectedBidder["player"], f.cost:GetNumber(), f.boss:GetText(), GetRealZoneText(), CurrItemForBid)
			end

			
		else
			local selected = L["PlayerValidate"];

			StaticPopupDialogs["CONFIRM_AWARD"] = {
			  text = selected,
			  button1 = L["OK"],
			  timeout = 5,
			  whileDead = true,
			  hideOnEscape = true,
			  preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_AWARD")
		end
	end);

	f:SetScript("OnMouseUp", function(self)    -- clears focus on esc
		local item,_,link = GetCursorInfo();

		if item == "item" then

			local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(link)

			CurrItemForBid = link
			CurrItemIcon = itemIcon
			MonDKP:ToggleBidWindow(CurrItemForBid, CurrItemIcon, itemName)
			ClearCursor()
		end
    end)

	return f;
end