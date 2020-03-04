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

function MonDKP_Standby_Announce(bossName)
	core.StandbyActive = true; -- activates opt in
	table.wipe(MonDKP_Standby);
	if MonDKP:CheckRaidLeader() then
		SendChatMessage(bossName..L["STANDBYOPTINBEGIN"], "GUILD") -- only raid leader announces
	end
	C_Timer.After(120, function ()
		core.StandbyActive = false;  -- deactivates opt in
		if MonDKP:CheckRaidLeader() then
			SendChatMessage(L["STANDBYOPTINEND"]..bossName, "GUILD") -- only raid leader announces
			if MonDKP_DB.DKPBonus.AutoIncStandby then
				MonDKP:AutoAward(2, MonDKP_DB.DKPBonus.BossKillBonus, MonDKP_DB.bossargs.CurrentRaidZone..": "..MonDKP_DB.bossargs.LastKilledBoss)
			end
		end
	end)
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
				response = "EssentialDKP: "..cmd.." "..L["STANDBYWHISPERRESP1"]
			elseif search and verify then
				response = "EssentialDKP: "..cmd.." "..L["STANDBYWHISPERRESP2"]
			else
				response = "EssentialDKP: "..cmd.." "..L["STANDBYWHISPERRESP3"];
			end
		else
			-- if it's just !standby
			local search = MonDKP:Table_Search(MonDKP_DKPTable, name)
			local verify = MonDKP:Table_Search(MonDKP_Standby, name)

			if search and not verify then
				table.insert(MonDKP_Standby, MonDKP_DKPTable[search[1][1]])
				response = "EssentialDKP: "..L["STANDBYWHISPERRESP4"]
			elseif search and verify then
				response = "EssentialDKP: "..L["STANDBYWHISPERRESP5"]
			else
				response = "EssentialDKP: "..L["STANDBYWHISPERRESP6"];
			end
		end
		if MonDKP:CheckRaidLeader() then 						 -- only raid leader responds to add.
			SendChatMessage(response, "WHISPER", nil, name)
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)		-- suppresses outgoing whisper responses to limit spam
		if core.StandbyActive and MonDKP_DB.defaults.SupressTells then
			if strfind(msg, "EssentialDKP: ") then
				return true
			end
		end
	end)
end