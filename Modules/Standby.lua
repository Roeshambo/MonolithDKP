local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local function CMD_Handler(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	end

	return cmd;
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

function MonDKP_Standby_Announce(bossName)
	core.StandbyActive = true; -- activates opt in
	table.wipe(MonDKP_Standby);
	if CheckRaidLeader() then
		SendChatMessage(bossName..L["STANDBYOPTINBEGIN"], "GUILD") -- only raid leader announces
	end
	C_Timer.After(120, function ()
		core.StandbyActive = false;  -- deactivates opt in
		if CheckRaidLeader() then
			SendChatMessage(L["STANDBYOPTINEND"]..bossName, "GUILD") -- only raid leader announces
			if MonDKP_DB.DKPBonus.IncStandby then
				MonDKP:AutoAward(2, MonDKP_DB.DKPBonus.BossKillBonus, MonDKP_DB.bossargs.CurrentRaidZone..": "..MonDKP_DB.bossargs.LastKilledBoss)
			end
		end
	end)
end

function MonDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempName
	local tempList = "";
	local tempList2 = "";
	local curTime = time();

	if CheckRaidLeader() then -- only allows raid leader to disseminate DKP
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

		if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.IncStandby and (phase == 2 or phase == 3) then
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
				tinsert(MonDKP_DKPHistory, {players=tempList, dkp=amount, reason=reason, date=curTime})
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				tinsert(MonDKP_DKPHistory, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1})
			end

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
			local temp_table2 = {}
			if (phase == 1 or phase == 3) and tempList ~= "" then
				tinsert(temp_table, {seed = MonDKP_DKPHistory.seed, {players=tempList, dkp=amount, reason=reason, date=curTime}})
				MonDKP.Sync:SendData("MonDKPDKPAward", temp_table[1])
				MonDKP.Sync:SendData("MonDKPBroadcast", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				tinsert(temp_table2, {seed = MonDKP_DKPHistory.seed, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1}})
				MonDKP.Sync:SendData("MonDKPDKPAward", temp_table2[1])
				MonDKP.Sync:SendData("MonDKPBroadcast", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
			end
			table.wipe(temp_table)
			table.wipe(temp_table2)
		end
	end
end

function MonDKP_Standby_Handler(text, ...)
	local name = ...;
	local cmd;
	local response = L["ERRORPROCESSING"];

	if string.find(name, "-") then					-- finds and removes server name from name if exists
		local dashPos = string.find(name, "-")
		name = strsub(name, 1, dashPos-1)
	end

	if string.find(text, "!standby") == 1 and core.IsOfficer then
		cmd = tostring(CMD_Handler(text))

		if cmd and cmd:gsub("%s+", "") ~= "nil" and cmd:gsub("%s+", "") ~= "" then
			-- if it's !standby *name*
			cmd = cmd:gsub("%s+", "") -- removes unintended spaces from string
			local search = MonDKP:Table_Search(MonDKP_DKPTable, cmd)
			local verify = MonDKP:Table_Search(MonDKP_Standby, cmd)

			if search and not verify then
				table.insert(MonDKP_Standby, MonDKP_DKPTable[search[1][1]])
				response = "MonolithDKP: "..cmd.." "..L["STANDBYWHISPERRESP1"]
			elseif search and verify then
				response = "MonolithDKP: "..cmd.." "..L["STANDBYWHISPERRESP2"]
			else
				response = "MonolithDKP: "..cmd.." "..L["STANDBYWHISPERRESP3"];
			end
		else
			-- if it's just !standby
			local search = MonDKP:Table_Search(MonDKP_DKPTable, name)
			local verify = MonDKP:Table_Search(MonDKP_Standby, name)

			if search and not verify then
				table.insert(MonDKP_Standby, MonDKP_DKPTable[search[1][1]])
				response = "MonolithDKP: "..L["STANDBYWHISPERRESP4"]
			elseif search and verify then
				response = "MonolithDKP: "..L["STANDBYWHISPERRESP5"]
			else
				response = "MonolithDKP: "..L["STANDBYWHISPERRESP6"];
			end
		end
		if CheckRaidLeader() then 						 -- only raid leader responds to add.
			SendChatMessage(response, "WHISPER", nil, name)
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)		-- suppresses outgoing whisper responses to limit spam
		if core.StandbyActive and MonDKP_DB.defaults.SupressTells then
			if strfind(msg, "MonolithDKP: ") then
				return true
			end
		end
	end)
end