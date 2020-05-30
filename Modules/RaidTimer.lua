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
	local search = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), name, "player")
	local path;

	if search then
		path = MonDKP:GetTable(MonDKP_DKPTable, true)[search[1][1]]
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

	for i=1, 40 do
		local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
		local search_DKP = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_DKPTable, true), tempName)
		local OnlineOnly = core.DB.modes.OnlineOnly
		local limitToZone = core.DB.modes.SameZoneOnly
		local isSameZone = zone == GetRealZoneText()

		if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
			MonDKP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #MonDKP:GetTable(MonDKP_Standby, true) > 0 and core.DB.DKPBonus.IncStandby then
		local i = 1

		while i <= #MonDKP:GetTable(MonDKP_Standby, true) do
			if strfind(tempList, MonDKP:GetTable(MonDKP_Standby, true)[i].player) then
				table.remove(MonDKP:GetTable(MonDKP_Standby, true), i)
			else
				MonDKP:AwardPlayer(MonDKP:GetTable(MonDKP_Standby, true)[i].player, amount)
				tempList = tempList..MonDKP:GetTable(MonDKP_Standby, true)[i].player..",";
				i=i+1
			end
		end
	end

	if tempList ~= "" then
		local newIndex = curOfficer.."-"..curTime
		tinsert(MonDKP:GetTable(MonDKP_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})

		if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
			MonDKP:DKPHistory_Update(true)
		end
		DKPTable_Update()

		MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP:GetTable(MonDKP_DKPHistory, true)[1])

		MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
		MonDKP:Print(L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
	end
end

function MonDKP:StopRaidTimer()
	if MonDKP.RaidTimer then
		MonDKP.RaidTimer:SetScript("OnUpdate", nil)
	end
	core.RaidInProgress = false
	core.RaidInPause = false
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
		if core.DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(core.DB.DKPBonus.CompletionBonus, L["RAIDCOMPLETIONBONUS"])
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	elseif IsInRaid() and core.IsOfficer then
		if core.DB.DKPBonus.GiveRaidEnd then
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	end
end

function MonDKP:StartRaidTimer(pause, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
	local increment;
	
	MonDKP.RaidTimer = MonDKP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)

	if not syncTimer then
		if not pause then -- pause == false
			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
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
			increment = core.DB.modes.increment;
			core.RaidInProgress = true
			core.RaidInPause = false
		else -- pause == true
			MonDKP.RaidTimer:SetScript("OnUpdate", nil)
			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["CONTINUERAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDPAUSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
			MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..strsub(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
			MonDKP.RaidTimerPopout.Output:SetText(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText())
			core.RaidInProgress = false
			core.RaidInPause = true
			return;
		end

		if IsInRaid() and MonDKP:CheckRaidLeader() and not pause and core.IsOfficer then
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

			MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
				MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
			end
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
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
			MonDKP.Sync:SendData("MonDKPRaidTime", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment and increment > 0 then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.IntervalBonus)
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and MonDKP:CheckRaidLeader() then
				AwardRaid(core.DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end