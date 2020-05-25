local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempList = "";
	local tempList2 = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	if MonDKP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
		if phase == 1 or phase == 3 then
			for i=1, 40 do
				local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
				local search_DKP = MonDKP:Table_Search(MonDKP:GetTable(MonDKP_Player_DKPTable, true), tempName)
				local OnlineOnly = core.DB.modes.OnlineOnly
				local limitToZone = core.DB.modes.SameZoneOnly
				local isSameZone = zone == GetRealZoneText()

				if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
					MonDKP:AwardPlayer(tempName, amount)
					tempList = tempList..tempName..",";
				end
			end
		end

		if #MonDKP:GetTable(MonDKP_Player_Standby, true) > 0 and core.DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
			local raidParty = "";
			for i=1, 40 do
				local tempName = GetRaidRosterInfo(i)
				if tempName then	
					raidParty = raidParty..tempName..","
				end
			end
			for i=1, #MonDKP:GetTable(MonDKP_Player_Standby, true) do
				if strfind(raidParty, MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player..",") ~= 1 and not strfind(raidParty, ","..MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player..",") then
					MonDKP:AwardPlayer(MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player, amount)
					tempList2 = tempList2..MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player..",";
				end
			end
			local i = 1
			while i <= #MonDKP:GetTable(MonDKP_Player_Standby, true) do
				if MonDKP:GetTable(MonDKP_Player_Standby, true)[i] and (strfind(raidParty, MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player..",") == 1 or strfind(raidParty, ","..MonDKP:GetTable(MonDKP_Player_Standby, true)[i].player..",")) then
					table.remove(MonDKP:GetTable(MonDKP_Player_Standby, true), i)
				else
					i=i+1
				end
			end
		end

		if tempList ~= "" or tempList2 ~= "" then
			if (phase == 1 or phase == 3) and tempList ~= "" then
				local newIndex = curOfficer.."-"..curTime
				tinsert(MonDKP:GetTable(MonDKP_Player_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP:GetTable(MonDKP_Player_DKPHistory, true)[1])
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				local newIndex = curOfficer.."-"..curTime+1
				tinsert(MonDKP:GetTable(MonDKP_Player_DKPHistory, true), 1, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1, index=newIndex})
				MonDKP.Sync:SendData("MonDKPBCastMsg", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP:GetTable(MonDKP_Player_DKPHistory, true)[1])
			end

			if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
				MonDKP:DKPHistory_Update(true)
			end
			DKPTable_Update()
		end
	end
end