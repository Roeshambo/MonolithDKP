local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local ConsolidatedTable = {}
local DKPTableTemp = {}
local ValInProgress = false

local function ConsolidateTables(keepDKP)
	table.sort(ConsolidatedTable, function(a,b)   	-- inverts tables; oldest to newest
		return a["date"] < b["date"]
	end)

	local i=1
	local timer = 0
	local processing = false
	local DKPStringTemp = ""	-- stores DKP comparisons to create a new entry if they are different
	local PlayerStringTemp = "" -- stores player list to create new DKPHistory entry if any values differ from the DKPTable
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #ConsolidatedTable and not processing then
			processing = true

			if ConsolidatedTable[i].loot then
				local search = MonDKP:Table_Search(DKPTableTemp, ConsolidatedTable[i].player, "player")

				if search then
					DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(ConsolidatedTable[i].cost)
					DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + tonumber(ConsolidatedTable[i].cost)
				else
					table.insert(DKPTableTemp, { player=ConsolidatedTable[i].player, dkp=tonumber(ConsolidatedTable[i].cost), lifetime_spent=tonumber(ConsolidatedTable[i].cost), lifetime_gained=0 })
				end
			elseif ConsolidatedTable[i].reason then
				local players = {strsplit(",", strsub(ConsolidatedTable[i].players, 1, -2))}

				if strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%") then -- is a decay, calculate new values
					local f = {strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%")}
					local playerString = ""
					local DKPString = ""
					local value = tonumber(strsub(ConsolidatedTable[i].dkp, f[1]+1, f[2]-1)) / 100

					for j=1, #players do
						local search2 = MonDKP:Table_Search(DKPTableTemp, players[j], "player")

						if search2 and DKPTableTemp[search2[1][1]].dkp > 0 then
							local deduction = DKPTableTemp[search2[1][1]].dkp * -value;
							deduction = MonDKP_round(deduction, MonDKP_DB.modes.rounding)

							DKPTableTemp[search2[1][1]].dkp = DKPTableTemp[search2[1][1]].dkp + deduction
							playerString = playerString..players[j]..","
							DKPString = DKPString..deduction..","
						else
							playerString = playerString..players[j]..","
							DKPString = DKPString.."0,"

							if not search2 then
								table.insert(DKPTableTemp, { player=players[j], dkp=0, lifetime_gained=0, lifetime_spent=0 })
							end
						end

					end
					local perc = value * 100
					DKPString = DKPString.."-"..perc.."%"

					local EntrySearch = MonDKP:Table_Search(MonDKP_DKPHistory, ConsolidatedTable[i].date, "date")

					if EntrySearch then
						MonDKP_DKPHistory[EntrySearch[1][1]].players = playerString
						MonDKP_DKPHistory[EntrySearch[1][1]].dkp = DKPString
					end
				else
					local dkp = tonumber(ConsolidatedTable[i].dkp)

					for j=1, #players do
						local search = MonDKP:Table_Search(DKPTableTemp, players[j], "player")

						if search then
							DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + dkp
							DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + dkp
						else
							if dkp > 0 then
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=dkp, lifetime_spent=0 })
							else
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=0, lifetime_spent=0 })
							end
						end
					end
				end
			end
			i=i+1
			processing = false
			timer = 0
		elseif i > #ConsolidatedTable then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			-- Create new DKPHistory entry compensating for difference between history and DKPTable (if some history was lost due to overwriting)
			if keepDKP then
				for i=1, #MonDKP_DKPTable do 
					local search = MonDKP:Table_Search(DKPTableTemp, MonDKP_DKPTable[i].player, "player")

					if search then
						if MonDKP_DKPTable[i].dkp ~= DKPTableTemp[search[1][1]].dkp then
							local val = MonDKP_DKPTable[i].dkp - DKPTableTemp[search[1][1]].dkp
							val = MonDKP_round(val, MonDKP_DB.modes.rounding)
							PlayerStringTemp = PlayerStringTemp..MonDKP_DKPTable[i].player..","
							DKPStringTemp = DKPStringTemp..val..","
						end
					end
				end

				if DKPStringTemp ~= "" and PlayerStringTemp ~= "" then
					local insert = {
						players = PlayerStringTemp,
						index 	= UnitName("player").."-"..MonDKP_DB.defaults.installed210-10,
						dkp 	= DKPStringTemp.."-1%",
						date 	= time(),
						reason	= "Migration Correction",
						hidden	= true,
					}
					table.insert(MonDKP_DKPHistory, insert)
				end
			else
				for i=1, #MonDKP_DKPTable do 
					local search = MonDKP:Table_Search(DKPTableTemp, MonDKP_DKPTable[i].player, "player")

					if search then
						MonDKP_DKPTable[i].dkp = DKPTableTemp[search[1][1]].dkp
						MonDKP_DKPTable[i].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent
						MonDKP_DKPTable[i].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained
					end
				end
			end

			local curTime = time();
			for i=1, #DKPTableTemp do 	-- finds who had history but was deleted; adds them to archive if so
				local search = MonDKP:Table_Search(MonDKP_DKPTable, DKPTableTemp[i].player)

				if not search then
					MonDKP_Archive[DKPTableTemp[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime } 
				end
			end

			table.sort(MonDKP_Loot, function(a,b)
				return a["date"] > b["date"]
			end)
			table.sort(MonDKP_DKPHistory, function(a,b)
				return a["date"] > b["date"]
			end)
			MonDKP_DKPHistory.seed = MonDKP_DKPHistory[1].index;
			MonDKP_Loot.seed = MonDKP_Loot[1].index
			MonDKP:FilterDKPTable(core.currentSort, "reset")
			ValInProgress = false
			MonDKP:Print(L["REPAIRCOMP"])
		end
	end)
end

local function RepairDKPHistory(keepDKP)
	local deleted_entries = 0
	local i=1
	local timer = 0
	local processing = false
	local officer = UnitName("player")
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #MonDKP_DKPHistory and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = MonDKP:Table_Search(MonDKP_DKPHistory, MonDKP_DKPHistory[i].date, "date")
			
			if MonDKP_DKPHistory[i].deletes or MonDKP_DKPHistory[i].deletedby or MonDKP_DKPHistory[i].reason == "Migration Correction" then  -- removes deleted entries/Migration Correction
				table.remove(MonDKP_DKPHistory, i)
			elseif #search > 1 then 		-- removes duplicate entries
				for j=2, #search do
					table.remove(MonDKP_DKPHistory, search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				local curTime = MonDKP_DKPHistory[i].date
				MonDKP_DKPHistory[i].index = officer.."-"..curTime
				if not strfind(MonDKP_DKPHistory[i].dkp, "%-%d*%.?%d+%%") then
					MonDKP_DKPHistory[i].dkp = tonumber(MonDKP_DKPHistory[i].dkp)
				end
				table.insert(ConsolidatedTable, MonDKP_DKPHistory[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #MonDKP_DKPHistory then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			ConsolidateTables(keepDKP)
		end
	end)
end

function MonDKP:RepairTables(keepDKP)  -- Repair starts
	if ValInProgress then
		MonDKP:Print(L["VALIDATEINPROG"])
		return
	end

	local officer = UnitName("player")
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	MonDKP:Print(L["REPAIRSTART"])

	if keepDKP then
		MonDKP:Print("Keep DKP: true")
	else
		MonDKP:Print("Keep DKP: false")
	end

	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #MonDKP_Loot and not processing then
			processing = true
			local search = MonDKP:Table_Search(MonDKP_Loot, MonDKP_Loot[i].date, "date")
			
			if MonDKP_Loot[i].deletedby or MonDKP_Loot[i].deletes then
				table.remove(MonDKP_Loot, i)
			elseif search and #search > 1 then
				for j=2, #search do
					if MonDKP_Loot[search[j][1]].loot == MonDKP_Loot[i].loot then
						table.remove(MonDKP_Loot, search[j][1])
					end
				end
			else
				local curTime = MonDKP_Loot[i].date
				MonDKP_Loot[i].index = officer.."-"..curTime
				if tonumber(MonDKP_Loot[i].cost) > 0 then
					MonDKP_Loot[i].cost = tonumber(MonDKP_Loot[i].cost) * -1
				end
				table.insert(ConsolidatedTable, MonDKP_Loot[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #MonDKP_Loot then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			RepairDKPHistory(keepDKP)
		end
	end)
end