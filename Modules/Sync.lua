local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

function MonDKP_InitMeta_Handler(meta)		-- creates table to be sent during a Sync Request. Only sends values that are lower than the initiating officers "current" to limit guild wide traffic
	local tempMeta = { DKP={}, Loot={} }
	local flagFullSync = true

	for k1,v1 in pairs(meta) do
		for k2,v2 in pairs(v1) do
			if not MonDKP_Meta[k1][k2] then  -- creates meta fields for officer if they don't exist
				MonDKP_Meta[k1][k2] = {lowest=0, current=0}
			end
			if not MonDKP_Meta_Remote[k1][k2] or meta[k1][k2].current > MonDKP_Meta_Remote[k1][k2] then -- Updates remote meta table (used to identify highest values anyone in the guild has. IE: Tells you if you're missing anything from an offline officer)
				MonDKP_Meta_Remote[k1][k2] = meta[k1][k2].current
			end
			if MonDKP_Meta[k1][k2].current ~= meta[k1][k2].current then 	-- adds value to table if it's different
				tempMeta[k1][k2] = MonDKP_Meta[k1][k2].current
			end
			if MonDKP_Meta[k1][k2].current > 0  then 			-- removes full sync flag if entries exist if all Meta entries are 0, flag stays true, full sync required
				flagFullSync = false 							-- at end of script, if all values were 0, requests full sync
			end
			if MonDKP_Meta[k1][k2].current+1 < meta[k1][k2].lowest then 	-- cancels script. if any local current+1 is lower than officers "lowest", data has been archived and can't be sent. full sync w/ archive required
				return "Full Sync"
			end
		end
	end

	for k,v in pairs(tempMeta) do -- removes table if it's empty
		if next(v) == nil then
			tempMeta[k] = nil
		end
	end

	if next(tempMeta) == nil then 	--if entire table is empty, replaces with false preventing anything from being returned (means all values are identical to initiating officer)
		tempMeta = false
	end

	if flagFullSync then 			-- after completing the meta, if all "current" values were zero, flag remains true and request for full sync is sent.
		return "Full Sync"		-- sends string back for full sync rather than entire meta table to limit traffic
	end

	return tempMeta
end

function MonDKP_TableComp_Handler(meta)		-- Same-ish as above. When a sync request is send with no officers online, creates table to communicate highest known values in guild
	local tempMeta = { DKP={}, Loot={} }	-- Used to identify if someone has higher values to identify that someone is out of date and current values may not reflect true DKP
	local flagFullSync = true

	for k1,v1 in pairs(meta) do
		for k2,v2 in pairs(v1) do
			if not MonDKP_Meta[k1][k2] then  -- creates meta fields for officer if they don't exist
				MonDKP_Meta[k1][k2] = {lowest=0, current=0}
			end
			if not MonDKP_Meta_Remote[k1][k2] or meta[k1][k2].current > MonDKP_Meta_Remote[k1][k2] then -- Updates remote meta table (used to identify highest values anyone in the guild has. IE: Tells you if you're missing anything from an offline officer)
				MonDKP_Meta_Remote[k1][k2] = meta[k1][k2].current
			end
			if MonDKP_Meta[k1][k2].current ~= meta[k1][k2].current then 	-- adds value to table if it's different
				tempMeta[k1][k2] = MonDKP_Meta[k1][k2].current
			end
		end
	end

	for k,v in pairs(tempMeta) do -- removes table if it's empty
		if next(v) == nil then
			tempMeta[k] = nil
		end
	end

	if next(tempMeta) == nil then 	--if entire table is empty, replaces with false preventing anything from being returned (means all values are identical to initiating officer)
		tempMeta = false
	end

	return tempMeta
end

function MonDKP_OffMetaCount_Handler(meta) -- returns number of entries officer has over initiating officer to determine who should update them
	local count = 0

	for k1,v1 in pairs(MonDKP_Meta) do
		for k2,v2 in pairs(v1) do
			if meta[k1][k2] and MonDKP_Meta[k1][k2].current > meta[k1][k2].current then
				count = count + MonDKP_Meta[k1][k2].current - meta[k1][k2].current
			elseif not meta[k1][k2] then
				count = count + MonDKP_Meta[k1][k2].current
			end
		end
	end

	return count
end