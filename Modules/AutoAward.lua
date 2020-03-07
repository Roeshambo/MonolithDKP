local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local function GetEligibleGuildMembers(onlineOnly, sameZone, currZone)
    -- Get list of guild members, optionally filtered for only online members and/or members currently in zone currZone
    -- Returns table playerTable where playerTable[playerName] is not nil iff playerName is eligible
    local playerTable = {}
    for playerIndex = 1, GetNumGuildMembers() do
        local name, _, _, _, _, zone, _, _, online, _, _, _, _, _, _, _ = GetGuildRosterInfo(playerIndex);
        if ((not onlineOnly) or online) and ((not sameZone) or (zone == currZone)) then
            playerTable[name] = 1
        end
    end
    return playerTable
end

function MonDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
    local raidAwardList = ""; -- List of players in raid that are awarded DKP
    local standbyAwardList = ""; -- List of players on standby that are awarded DKP
    local curTime = time();
    local curOfficer = UnitName("player")

    if MonDKP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
        if phase == 1 or phase == 3 then
            -- Award DKP to raid members
            for i = 1, 40 do
                local tempName, _, _, _, _, _, zone, online = GetRaidRosterInfo(i)
                local search_DKP = MonDKP:Table_Search(MonDKP_DKPTable, tempName)
                local isSameZone = (zone == GetRealZoneText())

                if search_DKP and (not MonDKP_DB.modes.OnlineOnly or online) and (not MonDKP_DB.modes.SameZoneOnly or isSameZone) then
                    MonDKP:AwardPlayer(tempName, amount)
                    raidAwardList = raidAwardList .. tempName .. ",";
                end
            end
        end

        -- Potentially award DKP to standby list members
        if #MonDKP_Standby > 0 and MonDKP_DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
            -- Collect list of all current raid members
            local raidParty = "";
            for i = 1, 40 do
                local tempName = GetRaidRosterInfo(i)
                if tempName then
                    raidParty = raidParty .. tempName .. ","
                end
            end

            -- Delete standby members from standby list if they are already in raid
            local i = 1
            while i <= #MonDKP_Standby do
                if strfind(raidParty, MonDKP_Standby[i].player .. ",") == 1 then
                    table.remove(MonDKP_Standby, i)
                else
                    i = i + 1
                end
            end

            -- Get list of online/same-zone players in the guild
            -- WARNING: Can not check if non-guild members are online/same-zone - these will be excluded from DKP if same-zone/only-online is active!
            local standbyEligible = GetEligibleGuildMembers(MonDKP_DB.modes.OnlineOnly, MonDKP_DB.modes.SameZoneOnly, GetRealZoneText())

            -- Now award standby members DKP (which are not in raid since they would have been deleted before otherwise)
            for i = 1, #MonDKP_Standby do
                if ((not MonDKP_DB.modes.OnlineOnly) and (not MonDKP_DB.modes.SameZoneOnly)) or (standbyEligible[MonDKP_Standby[i].player] ~= nil) then
                MonDKP :AwardPlayer(MonDKP_Standby[i].player, amount)
                    standbyAwardList = standbyAwardList .. MonDKP_Standby[i].player .. ",";
                end
            end
        end

        -- List of players to award is prepared (raidAwardList, standbyAwardList) - now assign DKP to them!
        if raidAwardList ~= "" then -- Raid Member DKP
            local newIndex = curOfficer .. "-" .. curTime
            tinsert(MonDKP_DKPHistory, 1, { players = raidAwardList, dkp = amount, reason = reason, date = curTime, index = newIndex })
            MonDKP.Sync:SendData("MonDKPBCastMsg", L["RAIDDKPADJUSTBY"] .. " " .. amount .. " " .. L["FORREASON"] .. ": " .. reason)
            MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP_DKPHistory[1])
        end
        if standbyAwardList ~= "" then -- Standby DKP
            local newIndex = curOfficer .. "-" .. curTime + 1
            tinsert(MonDKP_DKPHistory, 1, { players = standbyAwardList, dkp = amount, reason = reason .. " (Standby)", date = curTime + 1, index = newIndex })
            MonDKP.Sync:SendData("MonDKPBCastMsg", L["STANDBYADJUSTBY"] .. " " .. amount .. " " .. L["FORREASON"] .. ": " .. reason)
            MonDKP.Sync:SendData("MonDKPDKPDist", MonDKP_DKPHistory[1])
        end

        if raidAwardList ~= "" or standbyAwardList ~= "" then -- If we made any changes at all, trigger update
            if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
                MonDKP:DKPHistory_Update(true)
            end
            DKPTable_Update()
        end
    end
end