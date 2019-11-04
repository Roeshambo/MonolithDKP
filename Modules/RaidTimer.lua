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
		C_Timer.After(5, function() AwardRaid(amount, reason) end)
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
			MonDKP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.IncStandby then
		for i=1, #MonDKP_Standby do
			if strfind(tempList, MonDKP_Standby[i].player) then
				table.remove(MonDKP_Standby, i)
			else
				MonDKP:AwardPlayer(MonDKP_Standby[i].player, amount)
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
		if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
			MonDKP:DKPHistory_Reset()
			MonDKP:DKPHistory_Update()
		end
		DKPTable_Update()

		local temp_table = {}
		tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=tempList, dkp=amount, reason=reason, date=curTime}})
		MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
		table.wipe(temp_table)

		MonDKP.Sync:SendData("MonDKPBroadcast", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
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

	if IsInRaid() and CheckRaidLeader() and core.IsOfficer then
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

		if IsInRaid() and CheckRaidLeader() and not pause and core.IsOfficer then
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
			totalAwarded = tonumber(syncAward);

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
			MonDKP.Sync:SendData("MonDKPRaidTimer", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(MonDKP_DB.DKPBonus.IntervalBonus)
			MonDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			MonDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and CheckRaidLeader() then
				AwardRaid(MonDKP_DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end