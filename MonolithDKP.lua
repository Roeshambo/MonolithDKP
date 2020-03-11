local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;
local L = core.L;

local OptionsLoaded = false;

function MonDKP_RestoreFilterOptions()  		-- restores default filter selections
	MonDKP.UIConfig.search:SetText(L["SEARCH"])
	MonDKP.UIConfig.search:SetTextColor(0.3, 0.3, 0.3, 1)
	MonDKP.UIConfig.search:ClearFocus()
	core.WorkingTable = CopyTable(MonDKP_DKPTable)
	core.CurView = "all"
	core.CurSubView = "all"
	for i=1, 9 do
		MonDKP.ConfigTab1.checkBtn[i]:SetChecked(true)
	end
	MonDKP.ConfigTab1.checkBtn[10]:SetChecked(false)
	MonDKP.ConfigTab1.checkBtn[11]:SetChecked(false)
	MonDKP.ConfigTab1.checkBtn[12]:SetChecked(false)
	MonDKPFilterChecks(MonDKP.ConfigTab1.checkBtn[1])
end

function MonDKP:Toggle()        -- toggles IsShown() state of MonDKP.UIConfig, the entire addon window
	core.MonDKPUI = MonDKP.UIConfig or MonDKP:CreateMenu();
	core.MonDKPUI:SetShown(not core.MonDKPUI:IsShown())
	MonDKP.UIConfig:SetFrameLevel(10)
	MonDKP.UIConfig:SetClampedToScreen(true)
	if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
	if core.ModesWindow then core.ModesWindow:SetFrameLevel(2) end
		
	if core.IsOfficer == nil then
		MonDKP:CheckOfficer()
	end
	--core.IsOfficer = C_GuildInfo.CanEditOfficerNote()  -- seemingly removed from classic API
	if core.IsOfficer == false then
		for i=2, 3 do
			_G["MonDKPMonDKP.ConfigTabMenuTab"..i]:Hide();
		end
		_G["MonDKPMonDKP.ConfigTabMenuTab4"]:SetPoint("TOPLEFT", _G["MonDKPMonDKP.ConfigTabMenuTab1"], "TOPRIGHT", -14, 0)
		_G["MonDKPMonDKP.ConfigTabMenuTab5"]:SetPoint("TOPLEFT", _G["MonDKPMonDKP.ConfigTabMenuTab4"], "TOPRIGHT", -14, 0)
		_G["MonDKPMonDKP.ConfigTabMenuTab6"]:SetPoint("TOPLEFT", _G["MonDKPMonDKP.ConfigTabMenuTab5"], "TOPRIGHT", -14, 0)
	end

	if not OptionsLoaded then
		core.MonDKPOptions = core.MonDKPOptions or MonDKP:Options()
		OptionsLoaded = true;
	end

	if #MonDKP_Whitelist > 0 and core.IsOfficer then 				-- broadcasts whitelist any time the window is opened if one exists (help ensure everyone has the information even if they were offline when it was created)
		MonDKP.Sync:SendData("MonDKPWhitelist", MonDKP_Whitelist)   -- Only officers propagate the whitelist, and it is only accepted by players that are NOT the GM (prevents overwriting new Whitelist set by GM, if any.)
	end

	if core.CurSubView == "raid" then
		MonDKP:ViewLimited(true)
	elseif core.CurSubView == "standby" then
		MonDKP:ViewLimited(false, true)
	elseif core.CurSubView == "raid and standby" then
		MonDKP:ViewLimited(true, true)
	elseif core.CurSubView == "core" then
		MonDKP:ViewLimited(false, false, true)
	elseif core.CurSubView == "all" then
		MonDKP:ViewLimited()
	end

	core.MonDKPUI:SetScale(MonDKP_DB.defaults.MonDKPScaleSize)
	if MonDKP.ConfigTab6.history and MonDKP.ConfigTab6:IsShown() then
		MonDKP:DKPHistory_Update(true)
	elseif MonDKP.ConfigTab5 and MonDKP.ConfigTab5:IsShown() then
		MonDKP:LootHistory_Update(L["NOFILTER"]);
	end

	MonDKP:StatusVerify_Update()
	DKPTable_Update()
end

---------------------------------------
-- Sort Function
---------------------------------------
local SortButtons = {}

function MonDKP:FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table. core.currentSort should be used in most cases
	local parentTable;

	if not MonDKP.UIConfig then 
		return
	end

	if core.CurSubView ~= "all" then
		if core.CurSubView == "raid" then
			MonDKP:ViewLimited(true)
		elseif core.CurSubView == "standby" then
			MonDKP:ViewLimited(false, true)
		elseif core.CurSubView == "raid and standby" then
			MonDKP:ViewLimited(true, true)
		elseif core.CurSubView == "core" then
			MonDKP:ViewLimited(false, false, true)
		end
		parentTable = core.WorkingTable;
	else
		parentTable = MonDKP_DKPTable;
	end

	core.WorkingTable = {}
	for k,v in ipairs(parentTable) do
		local IsOnline = false;
		local name;
		local InRaid = false;
		local searchFilter = true

		if MonDKP.UIConfig.search:GetText() ~= L["SEARCH"] and MonDKP.UIConfig.search:GetText() ~= "" then
			if not strfind(string.upper(v.player), string.upper(MonDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.class), string.upper(MonDKP.UIConfig.search:GetText()))
			and not strfind(string.upper(v.role), string.upper(MonDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.rankName), string.upper(MonDKP.UIConfig.search:GetText())) 
			and not strfind(string.upper(v.spec), string.upper(MonDKP.UIConfig.search:GetText())) then
				searchFilter = false;
			end
		end
		
		if MonDKP.ConfigTab1.checkBtn[11]:GetChecked() then
			local guildSize,_,_ = GetNumGuildMembers();
			for i=1, guildSize do
				local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
				name = strsub(name, 1, string.find(name, "-")-1)
				
				if name == v.player then
					IsOnline = online;
					break;
				end
			end
		end
		if(core.classFiltered[parentTable[k]["class"]] == true) and searchFilter == true then
			if MonDKP.ConfigTab1.checkBtn[10]:GetChecked() or MonDKP.ConfigTab1.checkBtn[12]:GetChecked() then
				for i=1, 40 do
					tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
					if tempName and tempName == v.player and MonDKP.ConfigTab1.checkBtn[10]:GetChecked() then
						tinsert(core.WorkingTable, v)
					elseif tempName and tempName == v.player and MonDKP.ConfigTab1.checkBtn[12]:GetChecked() then
						InRaid = true;
					end
				end
			else
				if ((MonDKP.ConfigTab1.checkBtn[11]:GetChecked() and IsOnline) or not MonDKP.ConfigTab1.checkBtn[11]:GetChecked()) then
					tinsert(core.WorkingTable, v)
				end
			end
			if MonDKP.ConfigTab1.checkBtn[12]:GetChecked() and InRaid == false then
				if MonDKP.ConfigTab1.checkBtn[11]:GetChecked() then
					if IsOnline then
						tinsert(core.WorkingTable, v)
					end
				else
					tinsert(core.WorkingTable, v)
				end
			end
		end
		InRaid = false;
	end

	if #core.WorkingTable == 0 then  		-- removes all filter settings if the filter combination results in an empty table
		--MonDKP_RestoreFilterOptions()
		MonDKP.DKPTable.Rows[1].DKPInfo[1]:SetText("|cffff0000No Entries Returned.|r")
		MonDKP.DKPTable.Rows[1]:Show()
	end
	MonDKP:SortDKPTable(sort, reset);
end

function MonDKP:SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)

	if id == "class" or id == "rank" or id == "role" or id == "spec" then
		button = SortButtons.class
	elseif id == "spec" then                -- doesn't allow "spec" to be sorted.
		DKPTable_Update()
		return;
	else
		button = SortButtons[id]
	end

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(SortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.WorkingTable, function(a, b)
		if button.Ascend then
			if id == "dkp" then
				return a[button.Id] > b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" then
				if a[button.Id] < b[button.Id] then
					return true
				elseif a[button.Id] > b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] < b[button.Id]
			end
		else
			if id == "dkp" then
				return a[button.Id] < b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" then
				if a[button.Id] > b[button.Id] then
					return true
				elseif a[button.Id] < b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] > b[button.Id]
			end
		end
	end)
	core.currentSort = id;
	DKPTable_Update()
end

function MonDKP:CreateMenu()
	MonDKP.UIConfig = CreateFrame("Frame", "MonDKPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
	MonDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	MonDKP.UIConfig:SetSize(550, 590);
	MonDKP.UIConfig:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	MonDKP.UIConfig:SetBackdropColor(0,0,0,0.8);
	MonDKP.UIConfig:SetMovable(true);
	MonDKP.UIConfig:EnableMouse(true);
	--MonDKP.UIConfig:SetResizable(true);
	--MonDKP.UIConfig:SetMaxResize(1400, 875)
	--MonDKP.UIConfig:SetMinResize(1000, 590)
	MonDKP.UIConfig:RegisterForDrag("LeftButton");
	MonDKP.UIConfig:SetScript("OnDragStart", MonDKP.UIConfig.StartMoving);
	MonDKP.UIConfig:SetScript("OnDragStop", MonDKP.UIConfig.StopMovingOrSizing);
	MonDKP.UIConfig:SetFrameStrata("DIALOG")
	MonDKP.UIConfig:SetFrameLevel(10)
	MonDKP.UIConfig:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(2) end
	end)

	-- Close Button
	MonDKP.UIConfig.closeContainer = CreateFrame("Frame", "MonDKPTitle", MonDKP.UIConfig)
	MonDKP.UIConfig.closeContainer:SetPoint("CENTER", MonDKP.UIConfig, "TOPRIGHT", -4, 0)
	MonDKP.UIConfig.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	MonDKP.UIConfig.closeContainer:SetBackdropColor(0,0,0,0.9)
	MonDKP.UIConfig.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	MonDKP.UIConfig.closeContainer:SetSize(28, 28)

	MonDKP.UIConfig.closeBtn = CreateFrame("Button", nil, MonDKP.UIConfig, "UIPanelCloseButton")
	MonDKP.UIConfig.closeBtn:SetPoint("CENTER", MonDKP.UIConfig.closeContainer, "TOPRIGHT", -14, -14)
	tinsert(UISpecialFrames, MonDKP.UIConfig:GetName()); -- Sets frame to close on "Escape"

	---------------------------------------
	-- Create and Populate Tab Menu and DKP Table
	---------------------------------------

	MonDKP.TabMenu = MonDKP:ConfigMenuTabs();        -- Create and populate Config Menu Tabs
	MonDKP:DKPTable_Create();                        -- Create DKPTable and populate rows
	MonDKP.UIConfig.TabMenu:Hide()                   -- Hide menu until expanded
	---------------------------------------
	-- DKP Table Header and Sort Buttons
	---------------------------------------

	MonDKP.DKPTable_Headers = CreateFrame("Frame", "MonDKPDKPTableHeaders", MonDKP.UIConfig)
	MonDKP.DKPTable_Headers:SetSize(500, 22)
	MonDKP.DKPTable_Headers:SetPoint("BOTTOMLEFT", MonDKP.DKPTable, "TOPLEFT", 0, 1)
	MonDKP.DKPTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	MonDKP.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
	MonDKP.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	MonDKP.DKPTable_Headers:Show()

	---------------------------------------
	-- Sort Buttons
	--------------------------------------- 

	SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", MonDKP.DKPTable_Headers)
	SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", MonDKP.DKPTable_Headers)
	SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", MonDKP.DKPTable_Headers)
	 
	SortButtons.class:SetPoint("BOTTOM", MonDKP.DKPTable_Headers, "BOTTOM", 0, 2)
	SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
	SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
	 
	for k, v in pairs(SortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((core.TableWidth/3)-1, core.TableRowHeight)
		if v.Id == "class" then
			v:SetScript("OnClick", function(self) MonDKP:SortDKPTable(core.CenterSort, "Clear") end)
		else
			v:SetScript("OnClick", function(self) MonDKP:SortDKPTable(self.Id, "Clear") end)
		end
	end

	SortButtons.player:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)
	SortButtons.class:SetSize((core.TableWidth*0.2)-1, core.TableRowHeight)
	SortButtons.dkp:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)

	SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.player.t:SetFontObject("MonDKPNormal")
	SortButtons.player.t:SetTextColor(1, 1, 1, 1);
	SortButtons.player.t:SetPoint("LEFT", SortButtons.player, "LEFT", 50, 0);
	SortButtons.player.t:SetText(L["PLAYER"]); 

	--[[SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
	SortButtons.class.t:SetFontObject("MonDKPNormal");
	SortButtons.class.t:SetTextColor(1, 1, 1, 1);
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 0, 0);
	SortButtons.class.t:SetText(L["CLASS"]); --]]

	-- center column dropdown (class, rank, spec etc..)
	SortButtons.class.t = CreateFrame("FRAME", "MonDKPSortColDropdown", SortButtons.class, "MonolithDKPTableHeaderDropDownMenuTemplate")
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 4, -3)
	UIDropDownMenu_JustifyText(SortButtons.class.t, "CENTER")
	UIDropDownMenu_SetWidth(SortButtons.class.t, 80)
	UIDropDownMenu_SetText(SortButtons.class.t, L["CLASS"])

	UIDropDownMenu_Initialize(SortButtons.class.t, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "MonDKPSmallCenter"
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["CLASS"], "class", L["CLASS"], "class" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["SPEC"], "spec", L["SPEC"], "spec" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["RANK"], "rank", L["RANK"], "rank" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["ROLE"], "role", L["ROLE"], "role" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function SortButtons.class.t:SetValue(newValue, arg2)
		
		core.CenterSort = newValue
		SortButtons.class.Id = newValue;
		UIDropDownMenu_SetText(SortButtons.class.t, arg2)
		MonDKP:SortDKPTable(newValue, "reset")
		core.currentSort = newValue;
		CloseDropDownMenus()
	end

	SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
	SortButtons.dkp.t:SetFontObject("MonDKPNormal")
	SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	if MonDKP_DB.modes.mode == "Roll Based Bidding" then
		SortButtons.dkp.t:SetPoint("RIGHT", SortButtons.dkp, "RIGHT", -50, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);

		SortButtons.dkp.roll = SortButtons.dkp:CreateFontString(nil, "OVERLAY");
		SortButtons.dkp.roll:SetFontObject("MonDKPNormal")
		SortButtons.dkp.roll:SetScale("0.8")
		SortButtons.dkp.roll:SetTextColor(1, 1, 1, 1);
		SortButtons.dkp.roll:SetPoint("LEFT", SortButtons.dkp, "LEFT", 20, -1);
		SortButtons.dkp.roll:SetText(L["ROLLRANGE"])
	else
		SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER", 20, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);
	end

	----- Counter below DKP Table
	MonDKP.DKPTable.counter = CreateFrame("Frame", "MonDKPDisplayFrameCounter", MonDKP.UIConfig);
	MonDKP.DKPTable.counter:SetPoint("TOP", MonDKP.DKPTable, "BOTTOM", 0, 0)
	MonDKP.DKPTable.counter:SetSize(400, 30)

	MonDKP.DKPTable.counter.t = MonDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	MonDKP.DKPTable.counter.t:SetFontObject("MonDKPNormal");
	MonDKP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
	MonDKP.DKPTable.counter.t:SetPoint("CENTER", MonDKP.DKPTable.counter, "CENTER");

	MonDKP.DKPTable.counter.s = MonDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	MonDKP.DKPTable.counter.s:SetFontObject("MonDKPTiny");
	MonDKP.DKPTable.counter.s:SetTextColor(1, 1, 1, 0.7);
	MonDKP.DKPTable.counter.s:SetPoint("CENTER", MonDKP.DKPTable.counter, "CENTER", 0, -15);

	------------------------------
	-- Search Box
	------------------------------

	MonDKP.UIConfig.search = CreateFrame("EditBox", nil, MonDKP.UIConfig)
	MonDKP.UIConfig.search:SetPoint("BOTTOMLEFT", MonDKP.UIConfig, "BOTTOMLEFT", 50, 18)
	MonDKP.UIConfig.search:SetAutoFocus(false)
	MonDKP.UIConfig.search:SetMultiLine(false)
	MonDKP.UIConfig.search:SetSize(140, 24)
	MonDKP.UIConfig.search:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	MonDKP.UIConfig.search:SetBackdropColor(0,0,0,0.9)
	MonDKP.UIConfig.search:SetBackdropBorderColor(1,1,1,0.6)
	MonDKP.UIConfig.search:SetMaxLetters(50)
	MonDKP.UIConfig.search:SetTextColor(0.4, 0.4, 0.4, 1)
	MonDKP.UIConfig.search:SetFontObject("MonDKPNormalLeft")
	MonDKP.UIConfig.search:SetTextInsets(10, 10, 5, 5)
	MonDKP.UIConfig.search:SetText(L["SEARCH"])
	MonDKP.UIConfig.search:SetScript("OnKeyUp", function(self)    -- clears text and focus on esc
		if (MonDKP.UIConfig.search:GetText():match("[%^%$%(%)%%%.%[%]%*%+%-%?]")) then
			MonDKP.UIConfig.search:SetText(string.gsub(MonDKP.UIConfig.search:GetText(), "[%^%$%(%)%%%.%[%]%*%+%-%?]", ""))
			--MonDKP.UIConfig.search:SetText(strsub(MonDKP.UIConfig.search:GetText(), 1, -2))
		else
			MonDKP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
	MonDKP.UIConfig.search:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.3, 0.3, 0.3, 1)
		self:ClearFocus()
		MonDKP:FilterDKPTable(core.currentSort, "reset")
	end)
	MonDKP.UIConfig.search:SetScript("OnEnterPressed", function(self)    -- clears text and focus on enter
		self:ClearFocus()
	end)
	MonDKP.UIConfig.search:SetScript("OnTabPressed", function(self)    -- clears text and focus on tab
		self:ClearFocus()
	end)
	MonDKP.UIConfig.search:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() ==  L["SEARCH"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		else
			self:HighlightText();
		end
	end)
	MonDKP.UIConfig.search:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["SEARCH"])
			self:SetTextColor(0.3, 0.3, 0.3, 1)
		end
	end)
	MonDKP.UIConfig.search:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SEARCH"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SEARCHDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	MonDKP.UIConfig.search:SetScript("OnLeave", function(self)
		GameTooltip:Hide();
	end)

	---------------------------------------
	-- Expand / Collapse Arrow
	---------------------------------------

	MonDKP.UIConfig.expand = CreateFrame("Frame", "MonDKPTitle", MonDKP.UIConfig)
	MonDKP.UIConfig.expand:SetPoint("LEFT", MonDKP.UIConfig, "RIGHT", 0, 0)
	MonDKP.UIConfig.expand:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
	});
	MonDKP.UIConfig.expand:SetBackdropColor(0,0,0,0.7)
	MonDKP.UIConfig.expand:SetSize(15, 60)
	
	MonDKP.UIConfig.expandtab = MonDKP.UIConfig.expand:CreateTexture(nil, "OVERLAY", nil);
	MonDKP.UIConfig.expandtab:SetColorTexture(0, 0, 0, 1)
	MonDKP.UIConfig.expandtab:SetPoint("CENTER", MonDKP.UIConfig.expand, "CENTER");
	MonDKP.UIConfig.expandtab:SetSize(15, 60);
	MonDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\expand-arrow.tga");

	MonDKP.UIConfig.expand.trigger = CreateFrame("Button", "$ParentCollapseExpandButton", MonDKP.UIConfig.expand)
	MonDKP.UIConfig.expand.trigger:SetSize(15, 60)
	MonDKP.UIConfig.expand.trigger:SetPoint("CENTER", MonDKP.UIConfig.expand, "CENTER", 0, 0)
	MonDKP.UIConfig.expand.trigger:SetScript("OnClick", function(self) 
		if core.ShowState == false then
			MonDKP.UIConfig:SetWidth(1050)
			MonDKP.UIConfig.TabMenu:Show()
			MonDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\collapse-arrow");
		else
			MonDKP.UIConfig:SetWidth(550)
			MonDKP.UIConfig.TabMenu:Hide()
			MonDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\expand-arrow");
		end
		PlaySound(62540)
		core.ShowState = not core.ShowState
	end)

	-- Title Frame (top/center)
	MonDKP.UIConfig.TitleBar = CreateFrame("Frame", "MonDKPTitle", MonDKP.UIConfig, "ShadowOverlaySmallTemplate")
	MonDKP.UIConfig.TitleBar:SetPoint("BOTTOM", SortButtons.class, "TOP", 0, 10)
	MonDKP.UIConfig.TitleBar:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	MonDKP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
	MonDKP.UIConfig.TitleBar:SetSize(166, 54)

	-- Addon Title
	MonDKP.UIConfig.Title = MonDKP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	MonDKP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
	MonDKP.UIConfig.Title:SetPoint("CENTER", MonDKP.UIConfig.TitleBar, "CENTER");
	MonDKP.UIConfig.Title:SetSize(160, 48);
	MonDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\EssentialDKP\\Media\\Textures\\mondkp-title-t.tga");

	---------------------------------------
	-- CHANGE LOG WINDOW
	---------------------------------------
	if MonDKP_DB.defaults.HideChangeLogs < core.BuildNumber then
		MonDKP.ChangeLogDisplay = CreateFrame("Frame", "MonDKP_ChangeLogDisplay", UIParent, "ShadowOverlaySmallTemplate");

		MonDKP.ChangeLogDisplay:SetPoint("TOP", UIParent, "TOP", 0, -200);
		MonDKP.ChangeLogDisplay:SetSize(800, 100);
		MonDKP.ChangeLogDisplay:SetBackdrop( {
			bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
			edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		});
		MonDKP.ChangeLogDisplay:SetBackdropColor(0,0,0,0.9);
		MonDKP.ChangeLogDisplay:SetBackdropBorderColor(1,1,1,1)
		MonDKP.ChangeLogDisplay:SetFrameStrata("DIALOG")
		MonDKP.ChangeLogDisplay:SetFrameLevel(1)
		MonDKP.ChangeLogDisplay:SetMovable(true);
		MonDKP.ChangeLogDisplay:EnableMouse(true);
		MonDKP.ChangeLogDisplay:RegisterForDrag("LeftButton");
		MonDKP.ChangeLogDisplay:SetScript("OnDragStart", MonDKP.ChangeLogDisplay.StartMoving);
		MonDKP.ChangeLogDisplay:SetScript("OnDragStop", MonDKP.ChangeLogDisplay.StopMovingOrSizing);

		MonDKP.ChangeLogDisplay.ChangeLogHeader = MonDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		MonDKP.ChangeLogDisplay.ChangeLogHeader:ClearAllPoints();
		MonDKP.ChangeLogDisplay.ChangeLogHeader:SetFontObject("MonDKPLargeLeft")
		MonDKP.ChangeLogDisplay.ChangeLogHeader:SetPoint("TOPLEFT", MonDKP.ChangeLogDisplay, "TOPLEFT", 10, -10);
		MonDKP.ChangeLogDisplay.ChangeLogHeader:SetText("Essential DKP Changelog");

		MonDKP.ChangeLogDisplay.Notes = MonDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		MonDKP.ChangeLogDisplay.Notes:ClearAllPoints();
		MonDKP.ChangeLogDisplay.Notes:SetWidth(780)
		MonDKP.ChangeLogDisplay.Notes:SetFontObject("MonDKPNormalLeft")
		MonDKP.ChangeLogDisplay.Notes:SetPoint("TOPLEFT", MonDKP.ChangeLogDisplay.ChangeLogHeader, "BOTTOMLEFT", 0, -10);

		MonDKP.ChangeLogDisplay.VerNumber = MonDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		MonDKP.ChangeLogDisplay.VerNumber:ClearAllPoints();
		MonDKP.ChangeLogDisplay.VerNumber:SetWidth(780)
		MonDKP.ChangeLogDisplay.VerNumber:SetScale(0.8)
		MonDKP.ChangeLogDisplay.VerNumber:SetFontObject("MonDKPLargeLeft")
		MonDKP.ChangeLogDisplay.VerNumber:SetPoint("TOPLEFT", MonDKP.ChangeLogDisplay.Notes, "BOTTOMLEFT", 35, -10);

		MonDKP.ChangeLogDisplay.ChangeLogText = MonDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		MonDKP.ChangeLogDisplay.ChangeLogText:ClearAllPoints();
		MonDKP.ChangeLogDisplay.ChangeLogText:SetWidth(740)
		MonDKP.ChangeLogDisplay.ChangeLogText:SetFontObject("MonDKPNormalLeft")
		MonDKP.ChangeLogDisplay.ChangeLogText:SetPoint("TOPLEFT", MonDKP.ChangeLogDisplay.VerNumber, "BOTTOMLEFT", -15, -0);

		-- Change Log Close Button
		MonDKP.ChangeLogDisplay.closeContainer = CreateFrame("Frame", "MonDKPChangeLogClose", MonDKP.ChangeLogDisplay)
		MonDKP.ChangeLogDisplay.closeContainer:SetPoint("CENTER", MonDKP.ChangeLogDisplay, "TOPRIGHT", -4, 0)
		MonDKP.ChangeLogDisplay.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\EssentialDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		MonDKP.ChangeLogDisplay.closeContainer:SetBackdropColor(0,0,0,0.9)
		MonDKP.ChangeLogDisplay.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		MonDKP.ChangeLogDisplay.closeContainer:SetSize(28, 28)

		MonDKP.ChangeLogDisplay.closeBtn = CreateFrame("Button", nil, MonDKP.ChangeLogDisplay, "UIPanelCloseButton")
		MonDKP.ChangeLogDisplay.closeBtn:SetPoint("CENTER", MonDKP.ChangeLogDisplay.closeContainer, "TOPRIGHT", -14, -14)

		MonDKP.ChangeLogDisplay.DontShowCheck = CreateFrame("CheckButton", nil, MonDKP.ChangeLogDisplay, "UICheckButtonTemplate");
		MonDKP.ChangeLogDisplay.DontShowCheck:SetChecked(false)
		MonDKP.ChangeLogDisplay.DontShowCheck:SetScale(0.6);
		MonDKP.ChangeLogDisplay.DontShowCheck.text:SetText("  |cff9BB5BD"..L["DONTSHOW"].."|r");
		MonDKP.ChangeLogDisplay.DontShowCheck.text:SetScale(1.5);
		MonDKP.ChangeLogDisplay.DontShowCheck.text:SetFontObject("MonDKPSmallLeft")
		MonDKP.ChangeLogDisplay.DontShowCheck:SetPoint("LEFT", MonDKP.ChangeLogDisplay.ChangeLogHeader, "RIGHT", 10, 0);
		MonDKP.ChangeLogDisplay.DontShowCheck:SetScript("OnClick", function(self)
			if self:GetChecked() then
				MonDKP_DB.defaults.HideChangeLogs = core.BuildNumber
			else
				MonDKP_DB.defaults.HideChangeLogs = 0
			end
		end)

		MonDKP.ChangeLogDisplay.Notes:SetText("|cff9BB5BD"..L["BESTPRACTICES"].."|r")
		MonDKP.ChangeLogDisplay.VerNumber:SetText(core.MonVersion)

		--------------------------------------
		-- ChangeLog variable calls (bottom of localization files)
		--------------------------------------
		MonDKP.ChangeLogDisplay.ChangeLogText:SetText(L["CHANGELOG1"].."\n\n"..L["CHANGELOG2"].."\n\n"..L["CHANGELOG3"].."\n\n"..L["CHANGELOG4"].."\n\n"..L["CHANGELOG5"].."\n\n"..L["CHANGELOG6"].."\n\n"..L["CHANGELOG7"].."\n\n"..L["CHANGELOG8"].."\n\n"..L["CHANGELOG9"].."\n\n"..L["CHANGELOG10"]);

		local logHeight = MonDKP.ChangeLogDisplay.ChangeLogHeader:GetHeight() + MonDKP.ChangeLogDisplay.Notes:GetHeight() + MonDKP.ChangeLogDisplay.VerNumber:GetHeight() + MonDKP.ChangeLogDisplay.ChangeLogText:GetHeight();
		MonDKP.ChangeLogDisplay:SetSize(800, logHeight);  -- resize container
	end

	---------------------------------------
	-- VERSION IDENTIFIER
	---------------------------------------
	local c = MonDKP:GetThemeColor();
	MonDKP.UIConfig.Version = MonDKP.UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
	MonDKP.UIConfig.Version:ClearAllPoints();
	MonDKP.UIConfig.Version:SetFontObject("MonDKPSmallCenter");
	MonDKP.UIConfig.Version:SetScale("0.9")
	MonDKP.UIConfig.Version:SetTextColor(c[1].r, c[1].g, c[1].b, 0.5);
	MonDKP.UIConfig.Version:SetPoint("BOTTOMRIGHT", MonDKP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 4);
	MonDKP.UIConfig.Version:SetText(core.MonVersion); 

	MonDKP.UIConfig:Hide(); -- hide menu after creation until called.
	MonDKP:FilterDKPTable(core.currentSort)   -- initial sort and populates data values in DKPTable.Rows{} MonDKP:FilterDKPTable() -> MonDKP:SortDKPTable() -> DKPTable_Update()
	core.Initialized = true
	
	return MonDKP.UIConfig;
end
