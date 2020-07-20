local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
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
				local search = CommDKP:Table_Search(DKPTableTemp, ConsolidatedTable[i].player, "player")

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
						local search2 = CommDKP:Table_Search(DKPTableTemp, players[j], "player")

						if search2 and DKPTableTemp[search2[1][1]].dkp > 0 then
							local deduction = DKPTableTemp[search2[1][1]].dkp * -value;
							deduction = CommDKP_round(deduction, core.DB.modes.rounding)

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

					local EntrySearch = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true), ConsolidatedTable[i].date, "date")

					if EntrySearch then
						CommDKP:GetTable(CommDKP_DKPHistory, true)[EntrySearch[1][1]].players = playerString
						CommDKP:GetTable(CommDKP_DKPHistory, true)[EntrySearch[1][1]].dkp = DKPString
					end
				else
					local dkp = tonumber(ConsolidatedTable[i].dkp)

					for j=1, #players do
						local search = CommDKP:Table_Search(DKPTableTemp, players[j], "player")

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
				for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do 
					local search = CommDKP:Table_Search(DKPTableTemp, CommDKP:GetTable(CommDKP_DKPTable, true)[i].player, "player")

					if search then
						if CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp ~= DKPTableTemp[search[1][1]].dkp then
							local val = CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp - DKPTableTemp[search[1][1]].dkp
							val = CommDKP_round(val, core.DB.modes.rounding)
							PlayerStringTemp = PlayerStringTemp..CommDKP:GetTable(CommDKP_DKPTable, true)[i].player..","
							DKPStringTemp = DKPStringTemp..val..","
						end
					end
				end

				if DKPStringTemp ~= "" and PlayerStringTemp ~= "" then
					local insert = {
						players = PlayerStringTemp,
						index 	= UnitName("player").."-"..(time()-10),
						dkp 	= DKPStringTemp.."-1%",
						date 	= time(),
						reason	= "Migration Correction",
						hidden	= true,
					}
					table.insert(CommDKP:GetTable(CommDKP_DKPHistory, true), insert)
				end
			else
				for i=1, #CommDKP:GetTable(CommDKP_DKPTable, true) do 
					local search = CommDKP:Table_Search(DKPTableTemp, CommDKP:GetTable(CommDKP_DKPTable, true)[i].player, "player")

					if search then
						CommDKP:GetTable(CommDKP_DKPTable, true)[i].dkp = DKPTableTemp[search[1][1]].dkp
						CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent
						CommDKP:GetTable(CommDKP_DKPTable, true)[i].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained
					end
				end
			end

			local curTime = time();
			for i=1, #DKPTableTemp do 	-- finds who had history but was deleted; adds them to archive if so
				local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPTable, true), DKPTableTemp[i].player)

				if not search then
					CommDKP:GetTable(CommDKP_Archive, true)[DKPTableTemp[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime } 
				end
			end

			table.sort(CommDKP:GetTable(CommDKP_Loot, true), function(a,b)
				return a["date"] > b["date"]
			end)
			table.sort(CommDKP:GetTable(CommDKP_DKPHistory, true), function(a,b)
				return a["date"] > b["date"]
			end)
			CommDKP:GetTable(CommDKP_DKPHistory, true).seed = CommDKP:GetTable(CommDKP_DKPHistory, true)[1].index;
			CommDKP:GetTable(CommDKP_Loot, true).seed = CommDKP:GetTable(CommDKP_Loot, true)[1].index
			CommDKP:FilterDKPTable(core.currentSort, "reset")
			ValInProgress = false
			CommDKP:Print(L["REPAIRCOMP"])
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
		if timer > 0.01 and i <= #CommDKP:GetTable(CommDKP_DKPHistory, true) and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_DKPHistory, true), CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date, "date")
			
			if CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletes or CommDKP:GetTable(CommDKP_DKPHistory, true)[i].deletedby or CommDKP:GetTable(CommDKP_DKPHistory, true)[i].reason == "Migration Correction" then  -- removes deleted entries/Migration Correction
				table.remove(CommDKP:GetTable(CommDKP_DKPHistory, true), i)
			elseif #search > 1 then 		-- removes duplicate entries
				for j=2, #search do
					table.remove(CommDKP:GetTable(CommDKP_DKPHistory, true), search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				local curTime = CommDKP:GetTable(CommDKP_DKPHistory, true)[i].date
				CommDKP:GetTable(CommDKP_DKPHistory, true)[i].index = officer.."-"..curTime
				if not strfind(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp, "%-%d*%.?%d+%%") then
					CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp = tonumber(CommDKP:GetTable(CommDKP_DKPHistory, true)[i].dkp)
				end
				table.insert(ConsolidatedTable, CommDKP:GetTable(CommDKP_DKPHistory, true)[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #CommDKP:GetTable(CommDKP_DKPHistory, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			ConsolidateTables(keepDKP)
		end
	end)
end

function CommDKP:RepairTables(keepDKP)  -- Repair starts
	if ValInProgress then
		CommDKP:Print(L["VALIDATEINPROG"])
		return
	end

	local officer = UnitName("player")
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	CommDKP:Print(L["REPAIRSTART"])

	if keepDKP then
		CommDKP:Print("Keep DKP: true")
	else
		CommDKP:Print("Keep DKP: false")
	end

	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #CommDKP:GetTable(CommDKP_Loot, true) and not processing then
			processing = true
			local search = CommDKP:Table_Search(CommDKP:GetTable(CommDKP_Loot, true), CommDKP:GetTable(CommDKP_Loot, true)[i].date, "date")
			
			if CommDKP:GetTable(CommDKP_Loot, true)[i].deletedby or CommDKP:GetTable(CommDKP_Loot, true)[i].deletes then
				table.remove(CommDKP:GetTable(CommDKP_Loot, true), i)
			elseif search and #search > 1 then
				for j=2, #search do
					if CommDKP:GetTable(CommDKP_Loot, true)[search[j][1]].loot == CommDKP:GetTable(CommDKP_Loot, true)[i].loot then
						table.remove(CommDKP:GetTable(CommDKP_Loot, true), search[j][1])
					end
				end
			else
				local curTime = CommDKP:GetTable(CommDKP_Loot, true)[i].date
				CommDKP:GetTable(CommDKP_Loot, true)[i].index = officer.."-"..curTime
				if tonumber(CommDKP:GetTable(CommDKP_Loot, true)[i].cost) > 0 then
					CommDKP:GetTable(CommDKP_Loot, true)[i].cost = tonumber(CommDKP:GetTable(CommDKP_Loot, true)[i].cost) * -1
				end
				table.insert(ConsolidatedTable, CommDKP:GetTable(CommDKP_Loot, true)[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #CommDKP:GetTable(CommDKP_Loot, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			RepairDKPHistory(keepDKP)
		end
	end)
end
