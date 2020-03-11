local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--
local checkAll = true;                    -- changes to false when less than all of the boxes are checked
local curReason;                          -- stores user input in dropdown 

local function ScrollFrame_OnMouseWheel(self, delta)          -- scroll function for all but the DKPTable frame
	local newValue = self:GetVerticalScroll() - (delta * 20);   -- DKPTable frame uses FauxScrollFrame_OnVerticalScroll()
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end

function MonDKPFilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs MonDKP:FilterDKPTable() above
	local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
	if (self:GetChecked() == false and not MonDKP.ConfigTab1.checkBtn[10]) then
		core.CurView = "limited"
		core.CurSubView = "raid"
		MonDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
		checkAll = false;
		verifyCheck = false
	end
	for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
		if MonDKP.ConfigTab1.checkBtn[i]:GetChecked() == false then
			verifyCheck = false;
		end
	end
	if (verifyCheck == true) then
		MonDKP.ConfigTab1.checkBtn[9]:SetChecked(true);
	else
		MonDKP.ConfigTab1.checkBtn[9]:SetChecked(false);
	end
	for k,v in pairs(core.classes) do
		if (MonDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
			core.classFiltered[v] = true;
		else
			core.classFiltered[v] = false;
		end
	end
	PlaySound(808)
	MonDKP:FilterDKPTable(core.currentSort, "reset");
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());
	
	if self:GetID() > 4 then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	elseif self:GetID() == 4 and core.IsOfficer == true then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	else
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	if self:GetID() == 5 then
		MonDKP:LootHistory_Update(L["NOFILTER"]);
	elseif self:GetID() == 6 then
		MonDKP:DKPHistory_Update(true)
	end

	local scrollChild = self:GetParent().ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	PlaySound(808)
	self:GetParent().ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
	self:GetParent().ScrollFrame:SetVerticalScroll(0)
end

function MonDKP:SetTabs(frame, numTabs, width, height, ...)
	frame.numTabs = numTabs;
	
	local contents = {};
	local frameName = frame:GetName();
	
	for i = 1, numTabs do 
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "MonDKPTabButtonTemplate");
		tab:SetID(i);
		tab:SetText(select(i, ...));
		tab:GetFontString():SetFontObject("MonDKPSmallOutlineCenter")
		tab:GetFontString():SetTextColor(0.7, 0.7, 0.86, 1)
		tab:SetScript("OnClick", Tab_OnClick);
		
		tab.content = CreateFrame("Frame", nil, frame.ScrollFrame);
		tab.content:SetSize(width, height);
		tab.content:Hide();
				
		table.insert(contents, tab.content);
		
		if (i == 1) then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, 1);
		else
			tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -17, 0);
		end 
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

---------------------------------------
-- Populate Tabs 
---------------------------------------
function MonDKP:ConfigMenuTabs()
	---------------------------------------
	-- TabMenu
	---------------------------------------

	MonDKP.UIConfig.TabMenu = CreateFrame("Frame", "MonDKPMonDKP.ConfigTabMenu", MonDKP.UIConfig);
	MonDKP.UIConfig.TabMenu:SetPoint("TOPRIGHT", MonDKP.UIConfig, "TOPRIGHT", -25, -25);
	MonDKP.UIConfig.TabMenu:SetSize(477, 510);
	MonDKP.UIConfig.TabMenu:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	MonDKP.UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
	MonDKP.UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

	MonDKP.UIConfig.TabMenuBG = MonDKP.UIConfig.TabMenu:CreateTexture(nil, "OVERLAY", nil);
	MonDKP.UIConfig.TabMenuBG:SetColorTexture(0, 0, 0, 1)
	MonDKP.UIConfig.TabMenuBG:SetPoint("TOPLEFT", MonDKP.UIConfig.TabMenu, "TOPLEFT", 2, -2);
	MonDKP.UIConfig.TabMenuBG:SetSize(478, 511);
	MonDKP.UIConfig.TabMenuBG:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\menu-bg");

	-- TabMenu ScrollFrame and ScrollBar
	MonDKP.UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, MonDKP.UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
	MonDKP.UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
	MonDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  MonDKP.UIConfig.TabMenu, "TOPLEFT", 4, -8);
	MonDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
	MonDKP.UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
	MonDKP.UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	
	MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
	MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, MonDKP.UIConfig.TabMenu.ScrollFrame, "UIPanelScrollBarTrimTemplate")
	MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
	MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", MonDKP.UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
	MonDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);

	MonDKP.ConfigTab1, MonDKP.ConfigTab2, MonDKP.ConfigTab3, MonDKP.ConfigTab4, MonDKP.ConfigTab5, MonDKP.ConfigTab6 = MonDKP:SetTabs(MonDKP.UIConfig.TabMenu, 6, 475, 490, L["FILTERS"], L["ADJUSTDKP"], L["MANAGE"], L["OPTIONS"], L["LOOTHISTORY"], L["DKPHISTORY"]);

	---------------------------------------
	-- MENU TAB 1
	---------------------------------------

	MonDKP.ConfigTab1.text = MonDKP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- Filters header
	MonDKP.ConfigTab1.text:ClearAllPoints();
	MonDKP.ConfigTab1.text:SetFontObject("MonDKPLargeCenter")
	MonDKP.ConfigTab1.text:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab1.text:SetText(L["FILTERS"]);
	MonDKP.ConfigTab1.text:SetScale(1.2)

	local checkBtn = {}
	MonDKP.ConfigTab1.checkBtn = checkBtn;

	-- Create CheckBoxes
	for i=1, 10 do
		MonDKP.ConfigTab1.checkBtn[i] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
		if i <= 9 then MonDKP.ConfigTab1.checkBtn[i]:SetChecked(true) else MonDKP.ConfigTab1.checkBtn[i]:SetChecked(false) end;
		MonDKP.ConfigTab1.checkBtn[i]:SetID(i)
		if i <= 8 then
			MonDKP.ConfigTab1.checkBtn[i].text:SetText("|cff9BB5BD"..core.LocalClass[core.classes[i]].."|r");
		end
		if i==9 then
			MonDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick",
				function()
					for j=1, 9 do
						if (checkAll) then
							MonDKP.ConfigTab1.checkBtn[j]:SetChecked(false)
						else
							MonDKP.ConfigTab1.checkBtn[j]:SetChecked(true)
						end
					end
					checkAll = not checkAll;
					MonDKPFilterChecks(MonDKP.ConfigTab1.checkBtn[9]);
				end)

			for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
				if (MonDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
					core.classFiltered[v] = true;
				else
					core.classFiltered[v] = false;
				end
			end
		elseif i==10 then
			MonDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", function(self)
				MonDKP.ConfigTab1.checkBtn[12]:SetChecked(false);
				MonDKPFilterChecks(self)
			end)
		else
			MonDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", MonDKPFilterChecks)
		end
		MonDKP.ConfigTab1.checkBtn[i].text:SetFontObject("MonDKPSmall")
	end

	-- Class Check Buttons:
	MonDKP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", MonDKP.ConfigTab1, "TOPLEFT", 85, -70);
	MonDKP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
	MonDKP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
	MonDKP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
	MonDKP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
	MonDKP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
	MonDKP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
	MonDKP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);

	MonDKP.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", MonDKP.ConfigTab1.checkBtn[2], "TOPLEFT", 50, 0);
	MonDKP.ConfigTab1.checkBtn[9].text:SetText("|cff9BB5BD"..L["ALLCLASSES"].."|r");
	MonDKP.ConfigTab1.checkBtn[10]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[5], "BOTTOMLEFT", 0, 0);
	MonDKP.ConfigTab1.checkBtn[10].text:SetText("|cffE7ED6D"..L["INPARTYRAID"].."|r");         -- executed in filterDKPTable (MonolithDKP.lua)

	MonDKP.ConfigTab1.checkBtn[11] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
	MonDKP.ConfigTab1.checkBtn[11]:SetID(11)
	MonDKP.ConfigTab1.checkBtn[11].text:SetText("|cff9BB5BD"..L["ONLINE"].."|r");
	MonDKP.ConfigTab1.checkBtn[11].text:SetFontObject("MonDKPSmall")
	MonDKP.ConfigTab1.checkBtn[11]:SetScript("OnClick", MonDKPFilterChecks)
	MonDKP.ConfigTab1.checkBtn[11]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[10], "TOPRIGHT", 100, 0);

	MonDKP.ConfigTab1.checkBtn[12] = CreateFrame("CheckButton", nil, MonDKP.ConfigTab1, "UICheckButtonTemplate");
	MonDKP.ConfigTab1.checkBtn[12]:SetID(12)
	MonDKP.ConfigTab1.checkBtn[12].text:SetText("|cff9BB5BD"..L["NOTINRAIDFILTER"].."|r");
	MonDKP.ConfigTab1.checkBtn[12].text:SetFontObject("MonDKPSmall")
	MonDKP.ConfigTab1.checkBtn[12]:SetScript("OnClick", function(self)
		MonDKP.ConfigTab1.checkBtn[10]:SetChecked(false);
		MonDKPFilterChecks(self)
	end)
	MonDKP.ConfigTab1.checkBtn[12]:SetPoint("TOPLEFT", MonDKP.ConfigTab1.checkBtn[11], "TOPRIGHT", 65, 0);

	core.ClassGraph = MonDKP:ClassGraph()  -- draws class graph on tab1

	---------------------------------------
	-- Adjust DKP TAB
	---------------------------------------

	MonDKP:AdjustDKPTab_Create()

	---------------------------------------
	-- Manage DKP TAB
	---------------------------------------

	MonDKP.ConfigTab3.header = MonDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab3.header:ClearAllPoints();
	MonDKP.ConfigTab3.header:SetFontObject("MonDKPLargeCenter");
	MonDKP.ConfigTab3.header:SetPoint("TOPLEFT", MonDKP.ConfigTab3, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab3.header:SetText(L["MANAGEDKP"]); 
	MonDKP.ConfigTab3.header:SetScale(1.2)

	-- Populate Manage Tab
	MonDKP:ManageEntries()

	---------------------------------------
	-- Loot History TAB
	---------------------------------------

	MonDKP.ConfigTab5.text = MonDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab5.text:ClearAllPoints();
	MonDKP.ConfigTab5.text:SetFontObject("MonDKPLargeLeft");
	MonDKP.ConfigTab5.text:SetPoint("TOPLEFT", MonDKP.ConfigTab5, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab5.text:SetText(L["LOOTHISTORY"]);
	MonDKP.ConfigTab5.text:SetScale(1.2)

	MonDKP.ConfigTab5.inst = MonDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab5.inst:ClearAllPoints();
	MonDKP.ConfigTab5.inst:SetFontObject("MonDKPSmallRight");
	MonDKP.ConfigTab5.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	MonDKP.ConfigTab5.inst:SetPoint("TOPRIGHT", MonDKP.ConfigTab5, "TOPRIGHT", -40, -43);
	MonDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);

	-- Populate Loot History (LootHistory.lua)
	local looter = {}
	MonDKP.ConfigTab5.looter = looter
	local lootFrame = {}
	MonDKP.ConfigTab5.lootFrame = lootFrame
	for i=1, #MonDKP_Loot do
	MonDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "MonDKPLootHistoryFrame"..i, MonDKP.ConfigTab5);
	end

	if #MonDKP_Loot > 0 then
		MonDKP:LootHistory_Update(L["NOFILTER"])
		CreateSortBox();
	end

	---------------------------------------
	-- DKP History Tab
	---------------------------------------

	MonDKP.ConfigTab6.text = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab6.text:ClearAllPoints();
	MonDKP.ConfigTab6.text:SetFontObject("MonDKPLargeLeft");
	MonDKP.ConfigTab6.text:SetPoint("TOPLEFT", MonDKP.ConfigTab6, "TOPLEFT", 15, -10);
	MonDKP.ConfigTab6.text:SetText(L["DKPHISTORY"]);
	MonDKP.ConfigTab6.text:SetScale(1.2)

	MonDKP.ConfigTab6.inst = MonDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	MonDKP.ConfigTab6.inst:ClearAllPoints();
	MonDKP.ConfigTab6.inst:SetFontObject("MonDKPSmallRight");
	MonDKP.ConfigTab6.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	MonDKP.ConfigTab6.inst:SetPoint("TOPRIGHT", MonDKP.ConfigTab6, "TOPRIGHT", -40, -43);
	
	if #MonDKP_DKPHistory > 0 then
		MonDKP:DKPHistory_Update()
	end
	DKPHistoryFilterBox_Create()

end
	
