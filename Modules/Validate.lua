local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local DKPTableTemp = {}

local function TableCompare(t1,t2) 		-- compares two tables. returns true if all keys and values match
	local ty1 = type(t1)
	local ty2 = type(t2)
	
	if ty1 ~= ty2 then
		return false
	end
	
	if ty1 ~= 'table' and ty2 ~= 'table' then
		return t1 == t2
	end
	
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	return true
end

function MonDKP:ErrantCheck()
	for k,v in pairs(MonDKP_Meta.DKP) do
		for i=v.lowest, v.current do
			local search = MonDKP:Table_Search(MonDKP_DKPHistory, k.."-"..i, "index")

			if not search and i > 0 then
				table.insert(core.Errant,"DKP,"..k.."-"..i)
			end
		end
	end
	for k,v in pairs(MonDKP_Meta.Loot) do
		for i=v.lowest, v.current do
			local search = MonDKP:Table_Search(MonDKP_Loot, k.."-"..i, "index")

			if not search and i > 0 then
				table.insert(core.Errant,"Loot,"..k.."-"..i)
			end
		end
	end

	if #core.Errant > 0 then
		for i=1, #core.Errant do
			if core.Errant[i] then
				local tab, curIndex = strsplit(",", core.Errant[i])

				if tab == "DKP" then
					local search = MonDKP:Table_Search(MonDKP_DKPHistory, curIndex, "index")

					if search then
						table.remove(core.Errant, i)
					end
				else
					local search = MonDKP:Table_Search(MonDKP_Loot, curIndex, "index")

					if search then
						table.remove(core.Errant, i)
					end
				end
			end
		end
	end
end

function MonDKP:ValidateDKPTable_Loot()
	DKPTableTemp = {}
	for i=1, #MonDKP_Loot do
		local search = MonDKP:Table_Search(DKPTableTemp, MonDKP_Loot[i].player, "player")

		if search then
			DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + MonDKP_Loot[i].cost
			DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + MonDKP_Loot[i].cost
		else
			table.insert(DKPTableTemp, { player=MonDKP_Loot[i].player, dkp=MonDKP_Loot[i].cost, lifetime_gained=0, lifetime_spent=MonDKP_Loot[i].cost })
		end
	end
end

function MonDKP:ValidateDKPTable_DKP()
	for i=1, #MonDKP_DKPHistory do
		local players = {strsplit(",", strsub(MonDKP_DKPHistory[i].players, 1, -2))}
		local dkp = {strsplit(",", MonDKP_DKPHistory[i].dkp)}

		if #dkp == 1 then
			for i=1, #players do
				dkp[i] = tonumber(dkp[1])
			end
		else
			for i=1, #dkp do
				dkp[i] = tonumber(dkp[i])
			end
		end

		for j=1, #players do
			local search = MonDKP:Table_Search(DKPTableTemp, players[j], "player")

			if search then
				DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + dkp[j]
				if ((dkp[j] > 0 and not MonDKP_DKPHistory[i].deletes) or (dkp[j] < 0 and MonDKP_DKPHistory[i].deletes)) and not strfind(MonDKP_DKPHistory[i].dkp, "%-%d+%%") then
					DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + dkp[j]
				end
			else
				if ((dkp[j] > 0 and not MonDKP_DKPHistory[i].deletes) or (dkp[j] < 0 and MonDKP_DKPHistory[i].deletes)) and not strfind(MonDKP_DKPHistory[i].dkp, "%-%d+%%") then
					table.insert(DKPTableTemp, { player=players[j], dkp=dkp[j], lifetime_gained=dkp[j], lifetime_spent=0 })
				else
					table.insert(DKPTableTemp, { player=players[j], dkp=dkp[j], lifetime_gained=0, lifetime_spent=0 })
				end
			end
		end
	end
end

function MonDKP:ValidateDKPTable_Final()
	-- validates all profile DKP values against saved values created above
	for i=1, #DKPTableTemp do
		local search = MonDKP:Table_Search(MonDKP_DKPTable, DKPTableTemp[i].player, "player")

		if search then
			if MonDKP_Archive[DKPTableTemp[i].player] then
				DKPTableTemp[i].dkp = DKPTableTemp[i].dkp + MonDKP_Archive[DKPTableTemp[i].player].dkp
				DKPTableTemp[i].lifetime_gained = DKPTableTemp[i].lifetime_gained + MonDKP_Archive[DKPTableTemp[i].player].lifetime_gained
				DKPTableTemp[i].lifetime_spent = DKPTableTemp[i].lifetime_spent + MonDKP_Archive[DKPTableTemp[i].player].lifetime_spent
			end
			if DKPTableTemp[i].dkp ~= MonDKP_DKPTable[search[1][1]].dkp then
				MonDKP_DKPTable[search[1][1]].dkp = DKPTableTemp[i].dkp
			end
			if DKPTableTemp[i].lifetime_gained ~= MonDKP_DKPTable[search[1][1]].lifetime_gained then
				MonDKP_DKPTable[search[1][1]].lifetime_gained = DKPTableTemp[i].lifetime_gained
			end
			if DKPTableTemp[i].lifetime_spent ~= MonDKP_DKPTable[search[1][1]].lifetime_spent then
				MonDKP_DKPTable[search[1][1]].lifetime_spent = DKPTableTemp[i].lifetime_spent
			end
		end
	end
	MonDKP:ErrantCheck()
end

function MonDKP:ValidateLootTable()
	local deleted_entries = 0
	local i = 1;

	-- delete duplicate entries and correct DKP (loot table)
	while i <= #MonDKP_Loot do
		local search = MonDKP:Table_Search(MonDKP_Loot, MonDKP_Loot[i].index, "index")
		
		if search and #search > 1 then
			for j=2, #search do
				table.remove(MonDKP_Loot, search[j][1])
				deleted_entries = deleted_entries + 1
			end
		else
			i=i+1
		end
	end
end

function MonDKP:ValidateDKPHistory()
	local deleted_entries = 0
	local i = 1;

	-- delete duplicate entries and correct DKP (DKPHistory table)
	while i <= #MonDKP_DKPHistory do
		local search = MonDKP:Table_Search(MonDKP_DKPHistory, MonDKP_DKPHistory[i].index, "index")
		
		if #search > 1 then
			for j=2, #search do
				table.remove(MonDKP_DKPHistory, search[j][1])
				deleted_entries = deleted_entries + 1
			end
		else
			i=i+1
		end
	end
end