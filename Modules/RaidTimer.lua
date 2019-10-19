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

local function AwardPlayer(name, amount)
	local search = MonDKP:Table_Search(MonDKP_DKPTable, name)
	local path;

	if search then
		path = MonDKP_DKPTable[search[1][1]]
		path.dkp = path.dkp + amount
		path.lifetime_gained = path.lifetime_gained + amount;
	end
end

local function AwardRaid(amount, reason)
	if UnitAffectingCombat("player") then
		C_Timer.After(30, function() AwardRaid(amount, reason) end)
		return;
	end

	local tempName
	local tempList = "";
	local curTime = time();

	for i=1, 40 do
		local tempName, tempClass, search_DKP, search_standby

		tempName = GetRaidRosterInfo(i)
		search_DKP = MonDKP:Table_Search(MonDKP_DKPTable, tempName)

		if search_DKP then
			AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.IncStandby then
		for i=1, #MonDKP_Standby do
			if strfind(tempList, MonDKP_Standby[i].player) then
				table.remove(MonDKP_Standby, i)
			else
				AwardPlayer(MonDKP_Standby[i].player, amount)
				tempList = tempList..MonDKP_Standby[i].player..",";
			end
		end
	end

	if tempList ~= "" then
		tinsert(MonDKP_DKPHistory, {players=tempList, dkp=amount, reason=reason, date=curTime})

		MonDKP:SeedVerify_Update()
		if core.UpToDate and core.IsOfficer then -- updates seeds only if table is currently up to date.
			MonDKP:UpdateSeeds()
		end
		MonDKP.Sync:SendData("MonDKPDataSync", MonDKP_DKPTable)         -- broadcast updated DKP table
		if MonDKP.ConfigTab6.history then
			MonDKP:DKPHistory_Reset()
		end
		MonDKP:DKPHistory_Update()
		DKPTable_Update()

		local temp_table = {}
		tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=tempList, dkp=amount, reason=reason, date=curTime}})
		MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
		table.wipe(temp_table)

		MonDKP.Sync:SendData("MonDKPBroadcast", L["RaidDKPAdjustBy"].." "..amount.." "..L["ForReason"]..": "..reason)
	end
end

local function CheckRaidLeader()
	local tempName,tempRank;

	for i=1, 40 do
		tempName, tempRank = GetRaidRosterInfo(i)

		if tempName == UnitName("player") and tempRank == 2 then
			return true
		end
	end
	return false;
end

function MonDKP:StopRaidTimer()
	MonDKP.RaidTimer:SetScript("OnUpdate", nil)
	core.RaidInProgress = false
	MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RaidEnded"]..":")
	MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["InitRaid"])
	MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..strsub(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
	MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
	MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["TotalDKPAward"]..":")
	timer = 0;
	awards = 0;
	StartAwarded = false;
	MinuteCount = 0;
	SecondCount = 0;
	SecondTracker = 0;
	StartBonus = 0;

	if IsInRaid() and CheckRaidLeader() and core.IsOfficer then
		if MonDKP_DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(MonDKP_DB.DKPBonus.CompletionBonus, L["RaidCompletionBonus"])
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..tonumber(strsub(MonDKP.ConfigTab2.RaidTimerContainer.Bonus:GetText(), 11, -3)) +  MonDKP_DB.DKPBonus.CompletionBonus.."|r")
		end
	end
end

function MonDKP:StartRaidTimer(pause)
	local increment;
	
	MonDKP.RaidTimer = MonDKP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)

	if not pause then
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["EndRaid"])
		MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TimeElapsed"]..":")
		MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
		if MonDKP_DB.DKPBonus.GiveRaidStart then
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..MonDKP_DB.DKPBonus.OnTimeBonus.."|r")
		else
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff00000|r")
		end
		MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BonusAwarded"]..":")
		MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
		increment = MonDKP_DB.modes.increment;
		core.RaidInProgress = true
	else
		MonDKP.RaidTimer:SetScript("OnUpdate", nil)
		MonDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ContinueRaid"])
		MonDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RaidPaused"]..":")
		MonDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..strsub(MonDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
		core.RaidInProgress = false
		return;
	end

	if IsInRaid() and CheckRaidLeader() and not pause and core.IsOfficer then
		if not StartAwarded and MonDKP_DB.DKPBonus.GiveRaidStart then -- Award On Time Bonus
			AwardRaid(MonDKP_DB.DKPBonus.OnTimeBonus, L["OnTimeBonus"])
			StartBonus = MonDKP_DB.DKPBonus.OnTimeBonus;
			StartAwarded = true;
		end
	end

	MonDKP.RaidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		SecondTracker = SecondTracker + elapsed

		if SecondTracker >= 1 then
			MonDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..SecondsToClock(timer).."|r")
			SecondTracker = 0;
			SecondCount = SecondCount + 1;
		end

		if SecondCount >= 60 then						-- counds minutes past toward interval
			SecondCount = 0;
			MinuteCount = MinuteCount + 1;
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			awards = awards + 1;
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..(awards*MonDKP_DB.DKPBonus.IntervalBonus)+StartBonus.."|r");

			if IsInRaid() and CheckRaidLeader() then
				AwardRaid(MonDKP_DB.DKPBonus.IntervalBonus, L["TimeIntervalBonus"])
			end
		end
	end)
end