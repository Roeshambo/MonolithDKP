local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

function CommDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempList = "";
	local tempList2 = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	if CommDKP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
		if phase == 1 or phase == 3 then
			for i=1, 40 do
				local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
				local search_DKP = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), tempName)
				local OnlineOnly = core.DB.modes.OnlineOnly
				local limitToZone = core.DB.modes.SameZoneOnly
				local isSameZone = zone == GetRealZoneText()

				if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
					CommDKP:AwardPlayer(tempName, amount)
					tempList = tempList..tempName..",";
				end
			end
		end

		if #CommDKP:GetTable(CommDKP_Standby, true) > 0 and core.DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
			local raidParty = "";
			for i=1, 40 do
				local tempName = GetRaidRosterInfo(i)
				if tempName then	
					raidParty = raidParty..tempName..","
				end
			end
			for i=1, #CommDKP:GetTable(CommDKP_Standby, true) do
				if strfind(raidParty, CommDKP:GetTable(CommDKP_Standby, true)[i].player..",") ~= 1 and not strfind(raidParty, ","..CommDKP:GetTable(CommDKP_Standby, true)[i].player..",") then
					CommDKP:AwardPlayer(CommDKP:GetTable(CommDKP_Standby, true)[i].player, amount)
					tempList2 = tempList2..CommDKP:GetTable(CommDKP_Standby, true)[i].player..",";
				end
			end
			local i = 1
			while i <= #CommDKP:GetTable(CommDKP_Standby, true) do
				if CommDKP:GetTable(CommDKP_Standby, true)[i] and (strfind(raidParty, CommDKP:GetTable(CommDKP_Standby, true)[i].player..",") == 1 or strfind(raidParty, ","..CommDKP:GetTable(CommDKP_Standby, true)[i].player..",")) then
					table.remove(CommDKP:GetTable(CommDKP_Standby, true), i)
				else
					i=i+1
				end
			end
		end

		if tempList ~= "" or tempList2 ~= "" then
			if (phase == 1 or phase == 3) and tempList ~= "" then
				local newIndex = curOfficer.."-"..curTime
				tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				CommDKP.Sync:SendData("CommDKPDKPDist", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				local newIndex = curOfficer.."-"..curTime+1
				tinsert(CommDKP:GetTable(CommDKP_DKPHistory, true), 1, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1, index=newIndex})
				CommDKP.Sync:SendData("CommDKPBCastMsg", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				CommDKP.Sync:SendData("CommDKPDKPDist", CommDKP:GetTable(CommDKP_DKPHistory, true)[1])
			end

			if CommDKP.ConfigTab6.history and CommDKP.ConfigTab6:IsShown() then
				CommDKP:DKPHistory_Update(true)
			end
			CommDKP:DKPTable_Update()
		end
	end
end
