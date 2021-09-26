local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local awards = 0;  		-- counts the number of hourly DKP awards given
local timer = 0;
local SecondTracker = 0;
local MinuteCount = 0;
local SecondCount = 0;
local StartAwarded = false;
local StartBonus = 0;
local totalAwarded = 0;

local function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    
    if tonumber(mins) <= 0 then
    	return secs
    elseif tonumber(hours) <= 0 then
    	return mins..":"..secs
    else
    	return hours..":"..mins..":"..secs
    end
  end
end

function CommDKP:AwardPlayer(name, amount)
	local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name, "player")
	local path;

	if search then
		path = CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]]
		path.dkp = path.dkp + amount
		path.lifetime_gained = path.lifetime_gained + amount;
	end
end

local function AwardRaid(amount, reason)
	if UnitAffectingCombat("player") then
		C_Timer.After(5, function() AwardRaid(amount, reason) end)
		return;
	end

	local tempName
	local tempList = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	local OnlineOnly = core.DB.modes.OnlineOnly
	local limitToZone = core.DB.modes.SameZoneOnly

	for i=1, 40 do
		local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)

		local search_DKP = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), tempName)
		local isSameZone = zone == GetRealZoneText()

		if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
			CommDKP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #CommDKP:GetTable(CommDKP_Standby, true) > 0 and core.DB.DKPBonus.IncStandby then
		local i = 1

		while i <= #CommDKP:GetTable(CommDKP_Standby, true) do
			local standbyProfile = CommDKP:GetTable(CommDKP_Standby, true)[i].player;
			local isOnline = UnitIsConnected(standbyProfile);
			if strfind(tempList, standbyProfile) then
				table.remove(CommDKP:GetTable(CommDKP_Standby, true), i)
			else
				if standbyProfile and (not OnlineOnly or isOnline) then
					CommDKP:AwardPlayer(standbyProfile, amount)
					tempList = tempList..standbyProfile..",";
				end
				i=i+1
			end
		end
	end

	if tempList ~= "" then
		local newIndex = curOfficer.."-"..curTime
		tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})

		if CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
			CommDKP:DKPHistory_Update(true)
		end
		CommDKP:DKPTable_Update()

		CommDKP.Sync:SendData("CommDKPDKPDist", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])

		CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
		CommDKP:Print(L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
	end
end

function CommDKP:StopRaidTimer()
	if CommDKP.RaidTimer then
		CommDKP.RaidTimer:SetScript("OnUpdate", nil)
	end
	core.RaidInProgress = false
	core.RaidInPause = false
	CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDENDED"]..":")
	CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["INITRAID"])
	CommDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..strsub(CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
	CommDKP.RaidTimerPopout.Output:SetText(CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText());
	CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
	CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["TOTALDKPAWARD"]..":")
	timer = 0;
	awards = 0;
	StartAwarded = false;
	MinuteCount = 0;
	SecondCount = 0;
	SecondTracker = 0;
	StartBonus = 0;

	if IsInRaid() and CommDKP:CheckRaidLeader() and core.IsOfficer then
		if core.DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(core.DB.DKPBonus.CompletionBonus, L["RAIDCOMPLETIONBONUS"])
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	elseif IsInRaid() and core.IsOfficer then
		if core.DB.DKPBonus.GiveRaidEnd then
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	end
end

function CommDKP:StartRaidTimer(pause, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
	local increment;
	
	CommDKP.RaidTimer = CommDKP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)
	if not syncTimer then
		if not pause then -- pause == false
			CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
				CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				if totalAwarded == 0 then
					CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
				else
					CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
				end
			end
			CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = core.DB.modes.increment;
			core.RaidInProgress = true
			core.RaidInPause = false
		else -- pause == true
			CommDKP.RaidTimer:SetScript("OnUpdate", nil)
			CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["CONTINUERAID"])
			CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDPAUSED"]..":")
			CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
			CommDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..strsub(CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
			CommDKP.RaidTimerPopout.Output:SetText(CommDKP.ConfigTab2.RaidTimerContainer.Output:GetText())
			core.RaidInProgress = false
			core.RaidInPause = true
			return;
		end
		if IsInRaid() and CommDKP:CheckRaidLeader() and not pause and core.IsOfficer then
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then -- Award On Time Bonus
				AwardRaid(core.DB.DKPBonus.OnTimeBonus, L["ONTIMEBONUS"])
				StartBonus = core.DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		else
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then
				StartBonus = core.DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		end
	else
		if core.RaidInProgress == false and timer == 0 and SecondCount == 0 and MinuteCount == 0 then
			timer = tonumber(syncTimer);
			SecondCount = tonumber(syncSecondCount);
			MinuteCount = tonumber(syncMinuteCount);
			totalAwarded = tonumber(syncAward) - tonumber(core.DB.DKPBonus.OnTimeBonus);

			CommDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			CommDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
				CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
			end
			CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			CommDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = core.DB.modes.increment;
			StartBonus = core.DB.DKPBonus.OnTimeBonus;
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then
				StartAwarded = true;
				core.RaidInProgress = true
			end
		else
			return;
		end
	end
	
	CommDKP.RaidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		SecondTracker = SecondTracker + elapsed

		if SecondTracker >= 1 then
			local curTicker = SecondsToClock(timer);
			CommDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..curTicker.."|r")
			CommDKP.RaidTimerPopout.Output:SetText("|cff00ff00"..curTicker.."|r")
			SecondTracker = 0;
			SecondCount = SecondCount + 1;
		end

		if SecondCount >= 60 then						-- counds minutes past toward interval
			SecondCount = 0;
			MinuteCount = MinuteCount + 1;
			CommDKP.Sync:SendData("CommDKPRaidTime", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment and increment > 0 then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.IntervalBonus)
			CommDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			CommDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and CommDKP:CheckRaidLeader() and core.RaidInProgress then
				AwardRaid(core.DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end
