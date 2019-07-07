local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;

function MonDKP:SortLootTable()             -- sorts the Loot History Table by date
  table.sort(MonDKP_Log, function(a, b)
    return a["date"] > b["date"]
  end)
end


local tooltip = CreateFrame('GameTooltip', "nil", UIParent, 'GameTooltipTemplate')

function MonDKP:LootHistory_Update()
	local lineHeight = -30;

	MonDKP:SortLootTable()

	local curDate = 1;
	local linesToUse = 1;
	local curZone;
	local curBoss;

	for i=1, #MonDKP.ConfigTab5.looter do
		MonDKP.ConfigTab5.looter[i]:SetText("")
	end

	for i=1, #MonDKP_Log do
	  	--if (MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Log[i]["player"])) then
		    local itemToLink = MonDKP_Log[i]["loot"]

		    if strsub(MonDKP_Log[i]["date"], 1, 8) ~= curDate then
		      linesToUse = 3
		    elseif strsub(MonDKP_Log[i]["date"], 1, 8) == curDate and MonDKP_Log[i]["boss"] ~= curBoss and MonDKP_Log[i]["zone"] ~= curZone then
		      linesToUse = 3
		    elseif MonDKP_Log[i]["zone"] ~= curZone or MonDKP_Log[i]["boss"] ~= curBoss then
		      linesToUse = 2
		    else
		      linesToUse = 1
		    end

		    if (type(MonDKP.ConfigTab5.lootFrame[i]) ~= "table") then
		    	MonDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "MonDKPLootHistoryFrame"..i, MonDKP.ConfigTab5);	-- creates line if it doesn't exist yet
		    end
		    -- determine line height 
	    	if linesToUse == 1 then
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 28)
				lineHeight = lineHeight-25;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				MonDKP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 5, lineHeight);
				MonDKP.ConfigTab5.lootFrame[i]:SetSize(270, 42)
				lineHeight = lineHeight-37;
			end;

			MonDKP.ConfigTab5.looter[i] = MonDKP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			MonDKP.ConfigTab5.looter[i]:SetFontObject("MonDKPTinyLeft");
			MonDKP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", MonDKP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);
		   

		    -- print string to history
		    local date1, date2, date3 = strsplit("/", strsub(MonDKP_Log[i]["date"], 1, 8))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = MonDKP:Table_Search(MonDKP_DKPTable, MonDKP_Log[i]["player"])
		    local c;

		    if classSearch then
		     	c = MonDKP:GetCColors(MonDKP_DKPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if strsub(MonDKP_Log[i]["date"], 1, 8) ~= curDate or MonDKP_Log[i]["zone"] ~= curZone then
				feedString = date2.."/"..date3.."/"..date1.." - "..MonDKP_Log[i]["zone"].."\n  |cffff0000"..MonDKP_Log[i]["boss"].."|r |cff555555("..strsub(MonDKP_Log[i]["date"], 10)..")|r".."\n"
				if MonDKP_Log[i]["de"] then
					feedString = feedString.."    "..itemToLink.." was |cff00ff00Disenchanted|r"
				else
					feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Log[i]["player"].."|r |cff555555("..MonDKP_Log[i]["cost"].." DKP)|r"
				end        
					MonDKP.ConfigTab5.looter[i]:SetText(feedString);
					curDate = strsub(MonDKP_Log[i]["date"], 1, 8)
					curZone = MonDKP_Log[i]["zone"];
					curBoss = MonDKP_Log[i]["boss"];
		    elseif MonDKP_Log[i]["boss"] ~= curBoss then
		    	feedString = "  |cffff0000"..MonDKP_Log[i]["boss"].."|r |cff555555("..strsub(MonDKP_Log[i]["date"], 10)..")|r".."\n"
		    	if MonDKP_Log[i]["de"] then
		    		feedString = feedString.."    "..itemToLink.." was |cff00ff00Disenchanted|r"
		    	else
		    		feedString = feedString.."    "..itemToLink.." won by |cff"..c.hex..MonDKP_Log[i]["player"].."|r |cff555555("..MonDKP_Log[i]["cost"].." DKP)|r"
		    	end 
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strsub(MonDKP_Log[i]["date"], 1, 8)
		    	curBoss = MonDKP_Log[i]["boss"]
		    else
		    	if MonDKP_Log[i]["de"] then
		    		feedString = "    "..itemToLink.." was |cff00ff00Disenchanted|r"
		    	else
		    		feedString = "    "..itemToLink.." won by |cff"..c.hex..MonDKP_Log[i]["player"].."|r |cff555555("..MonDKP_Log[i]["cost"].." DKP)|r"
		    	end
		    	MonDKP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = MonDKP_Log[i]["zone"];
		    end


		    -- Set script for tooltip/linking
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function()
		    	tooltip:SetOwner(MonDKP.UIConfig, "ANCHOR_RIGHT", 0, -425)
		    	tooltip:SetHyperlink(itemToLink)
		    	tooltip:Show();
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function()
		    	if IsShiftKeyDown() then
		    		ChatFrame1EditBox:Show();
		    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
		    		ChatFrame1EditBox:SetFocus();
		    	elseif IsControlKeyDown() then
		    		itemID = string.match(itemToLink, "item:[%-?%d]+")
		    		itemID = strsub(itemID, 6)
		    		--DressUpModel:TryOn(tostring(itemID));
		    		--not implemented.... yet
		    	else
		    		ChatFrame1EditBox:Show();
		    		if MonDKP_Log[i]["de"] then
		    			ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)).." was disenchanted on "..date2.."/"..date3.."/"..date1)
		    		else
		    			ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..MonDKP_Log[i]["player"].." won "..select(2,GetItemInfo(itemToLink)).." in "..MonDKP_Log[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") for "..MonDKP_Log[i]["cost"].." DKP")
		    		end
		    		ChatFrame1EditBox:SetFocus();
		    	end
		    end)
		    MonDKP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide();
		    end)
		--end
 	end
end