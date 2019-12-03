local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempName
	local tempList = "";
	local tempList2 = "";
	local curTime = time();
	local curOfficer = UnitName("player")
	local curIndex, newIndex

	if not MonDKP_Meta.DKP[curOfficer] then
		MonDKP_Meta.DKP[curOfficer] = { current=0, lowest=0 }
	end

	curIndex = MonDKP_Meta.DKP[curOfficer].current
	newIndex = tonumber(curIndex) + 1;

	if MonDKP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
		if phase == 1 or phase == 3 then
			for i=1, 40 do
				local tempName, tempClass, search_DKP, search_standby

				tempName = GetRaidRosterInfo(i)
				search_DKP = MonDKP:Table_Search(MonDKP_DKPTable, tempName)

				if search_DKP then
					MonDKP:AwardPlayer(tempName, amount)
					tempList = tempList..tempName..",";
				end
			end
		end

		if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
			local raidParty = "";
			for i=1, 40 do
				local tempName = GetRaidRosterInfo(i)
				if tempName then	
					raidParty = raidParty..tempName..","
				end
			end
			for i=1, #MonDKP_Standby do
				if not strfind(raidParty, MonDKP_Standby[i].player..",") then
					MonDKP:AwardPlayer(MonDKP_Standby[i].player, amount)
					tempList2 = tempList2..MonDKP_Standby[i].player..",";
				end
			end
			for i=1, #MonDKP_Standby do
				if MonDKP_Standby[i] and strfind(raidParty, MonDKP_Standby[i].player..",") then
					table.remove(MonDKP_Standby, i)
				end
			end
		end

		if tempList ~= "" or tempList2 ~= "" then
			if (phase == 1 or phase == 3) and tempList ~= "" then
				tinsert(MonDKP_DKPHistory, 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=curOfficer.."-"..newIndex})
				MonDKP.Sync:SendData("MDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				MonDKP.Sync:SendData("MDKPDKPDist", MonDKP_DKPHistory[1])
				MonDKP_Meta.DKP[curOfficer].current = newIndex
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				tinsert(MonDKP_DKPHistory, 1, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1, index=curOfficer.."-"..newIndex})
				MonDKP.Sync:SendData("MDKPBCastMsg", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				MonDKP.Sync:SendData("MDKPDKPDist", MonDKP_DKPHistory[1])
				if phase == 3 then
					MonDKP_Meta.DKP[curOfficer].current = newIndex+1
				else
					MonDKP_Meta.DKP[curOfficer].current = newIndex
				end
			end

			if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
				MonDKP:DKPHistory_Update(true)
			end
			DKPTable_Update()
		end
	end
end