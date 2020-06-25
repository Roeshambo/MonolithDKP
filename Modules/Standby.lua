local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

local function CMD_Handler(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	end

	return cmd;
end

function CommDKP_Standby_Announce(bossName)
	core.StandbyActive = true; -- activates opt in
	table.wipe(CommDKP:GetTable(CommDKP_Standby, true));
	if CommDKP:CheckRaidLeader() then
		SendChatMessage(bossName..L["STANDBYOPTINBEGIN"], "GUILD") -- only raid leader announces
	end
	C_Timer.After(120, function ()
		core.StandbyActive = false;  -- deactivates opt in
		if CommDKP:CheckRaidLeader() then
			SendChatMessage(L["STANDBYOPTINEND"]..bossName, "GUILD") -- only raid leader announces
			if core.DB.DKPBonus.AutoIncStandby then
				CommDKP:AutoAward(2, core.DB.DKPBonus.BossKillBonus, core.DB.bossargs.CurrentRaidZone..": "..core.DB.bossargs.LastKilledBoss)
			end
		end
	end)
end

function CommDKP_Standby_Handler(text, ...)
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
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), cmd)
			local verify = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Standby, true), cmd)

			if search and not verify then
				table.insert(CommDKP:GetTable(CommDKP_Standby, true), CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]])
				response = "CommunityDKP: "..cmd.." "..L["STANDBYWHISPERRESP1"]
			elseif search and verify then
				response = "CommunityDKP: "..cmd.." "..L["STANDBYWHISPERRESP2"]
			else
				response = "CommunityDKP: "..cmd.." "..L["STANDBYWHISPERRESP3"];
			end
		else
			-- if it's just !standby
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), name)
			local verify = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Standby, true), name)

			if search and not verify then
				table.insert(CommDKP:GetTable(CommDKP_Standby, true), CommDKP:GetTable(CommDKP_DKPTable, true)[search[1][1]])
				response = "CommunityDKP: "..L["STANDBYWHISPERRESP4"]
			elseif search and verify then
				response = "CommunityDKP: "..L["STANDBYWHISPERRESP5"]
			else
				response = "CommunityDKP: "..L["STANDBYWHISPERRESP6"];
			end
		end
		if CommDKP:CheckRaidLeader() then 						 -- only raid leader responds to add.
			SendChatMessage(response, "WHISPER", nil, name)
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)		-- suppresses outgoing whisper responses to limit spam
		if core.StandbyActive and core.DB.defaults.SuppressTells then
			if strfind(msg, "CommunityDKP: ") then
				return true
			end
		end
	end)
end
