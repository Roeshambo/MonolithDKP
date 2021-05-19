local _, core = ...;
local _G = _G;
local CommDKP = core.CommDKP;
local L = core.L;

function IsItemLink(link)

    if link == nil then
        return false;
    end

    local id = link:match("|Hitem:(%d+):")
    if id then
        return true;
    end
    return false;
end

function CommDKP:VerifyMinBidItemTable(dbTable)
    local newTable = {};

    if dbTable.dbinfo.name ~= "CommDKP_MinBids" then
        return dbTable;
    end

    CommDKP:Print("Beginning MinBid Table Verification...");
    for realmName, realm in pairs(dbTable) do
        if realmName == "__default" or realmName == "dbinfo" then
            -- System Objects
            newTable[realmName] = realm;
        else
            -- Realm Level
            newTable[realmName] = {};
            for guildName, guild in pairs(realm) do
                --Guild Level
                newTable[realmName][guildName] = {}
                
                for teamId, oldTeamItems in pairs(guild) do
                    -- Team Level
                    newTable[realmName][guildName][teamId] = {}
                    local newTeamItems = newTable[realmName][guildName][teamId];
                    
                    CommDKP:Print("Updating "..guildName.." Team "..teamId.." on "..realmName);
                    local numItems = 0;
                    for k, v in pairs(oldTeamItems) do
                        numItems = numItems + 1;
                    end
                
                    for oldKey, oldItem in pairs(oldTeamItems) do
                        -- Item Level -- Work Happens Here
                        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(oldKey);

                        -- Is item Blank?
                        if oldItem.icon == nil and oldItem.item == nil and oldItem.minbid == nil and oldItem.link == nil and oldKey ~= nil and IsItemLink(itemLink) then
                            -- If Blank, create new
                            oldItem.item = itemName;
                            oldItem.link = itemLink;
                            oldItem.icon = itemTexture;
                            oldItem.disenchants = 0;
                            oldItem.lastbid = 0;
                            oldItem.minbid = 0;
                            oldItem.itemID = oldKey;
                        end

                        -- Verify that Link is a Link
                        if oldItem.link ~= nil and IsItemLink(oldItem.link) then
                            -- Verify itemName is present
                            if oldItem.item == nil then
                                oldItem.item = itemName;
                            end

                            --Verify itemId is present
                            if oldItem.itemID == nil then
                                local id = oldItem.link:match("|Hitem:(%d+):")
                                if id then
                                    oldItem.itemID = id;
                                end
                            end

                            --Save Item to New Table
                            newTeamItems[oldItem.itemID] = oldItem;
                        end
                    end
                    numItems = 0;
                    for k, v in pairs(newTeamItems) do
                        numItems = numItems + 1;
                    end

                end
            end
        end
    end
    CommDKP:Print("Finished MinBid Table Verification!");
    return newTable
end

function CommDKP:RefactorMinBidItemTable(dbTable)
    local newTable = {};

    if dbTable.dbinfo.name ~= "CommDKP_MinBids" then
        return dbTable;
    end
    CommDKP:Print("Beginning MinBid Table Upgrade...");
    for realmName, realm in pairs(dbTable) do
        if realmName == "__default" or realmName == "dbinfo" then
            -- System Objects
            newTable[realmName] = realm;
        else
            -- Realm Level
            newTable[realmName] = {};
            for guildName, guild in pairs(realm) do
                --Guild Level
                newTable[realmName][guildName] = {}
                
                for teamId, oldTeamItems in pairs(guild) do
                    -- Team Level
                    newTable[realmName][guildName][teamId] = {}
                    local newTeamItems = newTable[realmName][guildName][teamId];
                    
                    CommDKP:Print("Updating "..guildName.." Team "..teamId.." on "..realmName);
                    for i=1, #oldTeamItems do
                        -- Item Level -- Work Happens Here
                        local oldItem = oldTeamItems[i];

                        -- If Link doesn't exist in the old Item, we can't do much, we're going to exclude it.
                        if oldItem.link ~= nil then
                            local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(oldItem.link,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

                            if newTeamItems[itemID] == nil then
                                --Item doesn't exist yet.

                                newTeamItems[itemID] = {}
                                newTeamItems[itemID]["itemID"] = itemID;

                                --Set Item Name
                                if oldItem["item"] ~= nil then
                                    newTeamItems[itemID]["item"] = oldItem.item;
                                end
                                
                                --Set Cost
                                if oldItem["cost"] ~= nil then
                                    newTeamItems[itemID]["cost"] = oldItem.cost;
                                end

                                --Set Last Bid
                                if oldItem["lastbid"] ~= nil then
                                    newTeamItems[itemID]["lastbid"] = oldItem.lastbid;
                                end

                                --Set Link
                                if oldItem["link"] ~= nil then
                                    newTeamItems[itemID]["link"] = oldItem.link;
                                end

                                --Set Icon
                                if oldItem["icon"] ~= nil then
                                    newTeamItems[itemID]["icon"] = oldItem.icon;
                                end

                                --Set Disenchants
                                if oldItem["disenchants"] ~= nil then
                                    newTeamItems[itemID]["disenchants"] = oldItem.disenchants;
                                end

                                --Set Minbid
                                if oldItem["minbid"] ~= nil then
                                    newTeamItems[itemID]["minbid"] = oldItem.minbid;
                                end
                                
                            else
                                -- Item Exists

                                --Update For Disenchants
                                if oldItem["disenchants"] ~= nil and newTeamItems[itemID]["disenchants"] ~= nil then
                                    if oldItem["disenchants"] > newTeamItems[itemID]["disenchants"] then
                                        if oldItem["disenchants"] ~= nil then
                                            newTeamItems[itemID]["disenchants"] = oldItem["disenchants"];
                                        end
                                        
                                        if oldItem["minbid"] ~= nil and oldItem["minbid"] ~= 0 then
                                            newTeamItems[itemID]["minbid"] = oldItem["minbid"];
                                        end
                                        
                                        if oldItem["cost"] ~= nil then
                                            newTeamItems[itemID]["cost"] = oldItem["cost"];
                                        end
                                        
                                        if oldItem["lastbid"] ~= nil then
                                            newTeamItems[itemID]["lastbid"] = oldItem["lastbid"];
                                        end
                                    end
                                end

                                --Determine MinBid Value
                                if newTeamItems[itemID]["minbid"] == nil and oldItem["minbid"] ~= nil then
                                    newTeamItems[itemID]["minbid"] = oldItem["minbid"];
                                elseif newTeamItems[itemID]["minbid"] == 0 and oldItem["minbid"] > 0 then
                                    newTeamItems[itemID]["minbid"] = oldItem["minbid"];
                                end

                                --Determine Cost Value
                                if newTeamItems[itemID]["cost"] == nil and oldItem["cost"] ~= nil then
                                    newTeamItems[itemID]["cost"] = oldItem["cost"];
                                end

                                --Determine Last Bid Value
                                if newTeamItems[itemID]["lastbid"] == nil and oldItem["lastbid"] ~= nil then
                                    newTeamItems[itemID]["lastbid"] = oldItem["lastbid"];
                                end
                            end
                        end
                    end

                    --Fix MinBid Value Missing
                    for k, v in pairs(newTeamItems) do
                        if v.minbid == nil then
                            v["minbid"] = v.lastbid or v.cost or 0;
                        end

                        if core.DB.defaults.DecreaseDisenchantValue then
                            if v.lastbid == nil then
                                v.lastbid = v.minbid;
                            end
    
                            if v.disenchants ~= nil then
                                if v.disenchants >= 3 and v.lastbid < v.minbid then
                                    v.minbid = v.lastbid;
                                    v.cost = v.lastbid;
                                end
                            else
                                v.disenchants = 0;
                            end

                            if v.disenchants >= 3 and v.minbid > 30 then
                                for i=3, v.disenchants do
                                    v.minbid = v.minbid / 2

                                    if v.minbid < 5 then
                                        v.minbid = 5
                                    end
                                end
                            end
                        end
                    end
                    local numItems = 0;
                    for k, v in pairs(newTeamItems) do
                        numItems = numItems + 1;
                    end
                end
            end
        end
    end
    CommDKP:Print("Finished MinBid Table Upgrade!");
    return newTable
end
