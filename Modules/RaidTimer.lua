local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local awards = 0;  		-- counts the number of hourly DKP awards given
local timer = 0;
local SecondTracker = 0;
local MinuteCount = 0;
local SecondCount = 0;
local StartAwarded = false;
local StartBonus = 0;
local totalAwarded = 0;

function SecondsToClock(seconds)
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

function MonDKP:AwardPlayer(name, amount)
	local search = MonDKP:Table_Search(MonDKP_DKPTable, name, "player")
	local path;

	if search then
		path = MonDKP_DKPTable[search[1][1]]
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
	local curIndex, newIndex

	if not MonDKP_Meta.DKP[curOfficer] then
		MonDKP_Meta.DKP[curOfficer] = { current=0, lowest=0 }
	end

	curIndex = MonDKP_Meta.DKP[curOfficer].current
	newIndex = tonumber(curIndex) + 1;

	for i=1, 40 do
		local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
		local search_DKP = MonDKP:Table_Search(MonDKP_DKPTable, tempName)
		local OnlineOnly = MonDKP_DB.modes.OnlineOnly
		local limitToZone = MonDKP_DB.modes.SameZoneOnly
		local isSameZone = zone == GetRealZoneText()

		if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
			MonDKP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.IncStandby then
		local i = 1

		while i <= #MonDKP_Standby do
			if strfind(tempList, MonDKP_Standby[i].player) then
				table.remove(MonDKP_Standby, i)
			else
				MonDKP:AwardPlayer(MonDKP_Standby[i].player, amount)
				tempList = tempList..MonDKP_Standby[i].player..",";
				i=i+1
			end
		end
	end

	if tempList ~= "" then
		tinsert(MonDKP_DKPHistory, 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=curOfficer.."-"..newIndex})
		MonDKP_Meta.DKP[curOfficer].current = newIndex;

		if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
			MonDKP:DKPHistory_Update(true)
		end
		DKPTable_Update()

		MonDKP.Sync:SendData("MDKPDKPDist", MonDKP_DKPHistory[1])

		MonDKP.Sync:SendData("MDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
		MonDKP:Print(L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
	end
end

function MonDKP:StopRaidTimer()
	if MonDKP.RaidTimer then
		MonDKP.RaidTimer:SetScript("OnUpdate", nil)
	end
	core.RaidInProgress = false
	MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDENDED"]..":")
	MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["INITRAID"])
	MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..strsub(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
	MonDKP.RaidTimerPopout.Output:SetText(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText());
	MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
	MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["TOTALDKPAWARD"]..":")
	timer = 0;
	awards = 0;
	StartAwarded = false;
	MinuteCount = 0;
	SecondCount = 0;
	SecondTracker = 0;
	StartBonus = 0;

	if IsInRaid() and MonDKP:CheckRaidLeader() and core.IsOfficer then
		if MonDKP_DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(MonDKP_DB.DKPBonus.CompletionBonus, L["RAIDCOMPLETIONBONUS"])
			totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.CompletionBonus);
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	elseif IsInRaid() and core.IsOfficer then
		if MonDKP_DB.DKPBonus.GiveRaidEnd then
			totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.CompletionBonus);
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	end
end

function MonDKP:StartRaidTimer(pause, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
	local increment;
	
	MonDKP.RaidTimer = MonDKP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)

	if not syncTimer then
		if not pause then
			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if MonDKP_DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.OnTimeBonus)
				MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				if totalAwarded == 0 then
					MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
				else
					MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
				end
			end
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = MonDKP_DB.modes.increment;
			core.RaidInProgress = true
		else
			MonDKP.RaidTimer:SetScript("OnUpdate", nil)
			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["CONTINUERAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDPAUSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
			MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..strsub(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
			MonDKP.RaidTimerPopout.Output:SetText(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText())
			core.RaidInProgress = false
			return;
		end

		if IsInRaid() and MonDKP:CheckRaidLeader() and not pause and core.IsOfficer then
			if not StartAwarded and MonDKP_DB.DKPBonus.GiveRaidStart then -- Award On Time Bonus
				AwardRaid(MonDKP_DB.DKPBonus.OnTimeBonus, L["ONTIMEBONUS"])
				StartBonus = MonDKP_DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		else
			if not StartAwarded and MonDKP_DB.DKPBonus.GiveRaidStart then
				StartBonus = MonDKP_DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		end
	else
		if core.RaidInProgress == false and timer == 0 and SecondCount == 0 and MinuteCount == 0 then
			timer = tonumber(syncTimer);
			SecondCount = tonumber(syncSecondCount);
			MinuteCount = tonumber(syncMinuteCount);
			totalAwarded = tonumber(syncAward) - tonumber(MonDKP_DB.DKPBonus.OnTimeBonus);

			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if MonDKP_DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.OnTimeBonus)
				MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
			end
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = MonDKP_DB.modes.increment;
			StartBonus = MonDKP_DB.DKPBonus.OnTimeBonus;
			if not StartAwarded and MonDKP_DB.DKPBonus.GiveRaidStart then
				StartAwarded = true;
				core.RaidInProgress = true
			end
		else
			return;
		end
	end
	
	MonDKP.RaidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		SecondTracker = SecondTracker + elapsed

		if SecondTracker >= 1 then
			local curTicker = SecondsToClock(timer);
			MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..curTicker.."|r")
			MonDKP.RaidTimerPopout.Output:SetText("|cff00ff00"..curTicker.."|r")
			SecondTracker = 0;
			SecondCount = SecondCount + 1;
		end

		if SecondCount >= 60 then						-- counds minutes past toward interval
			SecondCount = 0;
			MinuteCount = MinuteCount + 1;
			MonDKP.Sync:SendData("MDKPRaidTime", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.IntervalBonus)
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and MonDKP:CheckRaidLeader() then
				AwardRaid(MonDKP_DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end