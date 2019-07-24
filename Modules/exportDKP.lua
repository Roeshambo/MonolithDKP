local _, core = ...;
local _G = _G;
local MonDKP = core.MonDKP;



local function GenerateDKPTables(table)
	local ExportString;

	if table == MonDKP_DKPTable then
		ExportString = "<html>\n<script>\nfunction openTab(tabName) {\n   var i;\n   var x = document.getElementsByClassName(\"tab\");\n   for (i = 0; i < x.length; i++) {\n      x[i].style.display = \"none\";\n   }\n   document.getElementById(tabName).style.display = \"block\";\n}\n</script>\n";
		ExportString = ExportString.."<script>var whTooltips = {colorLinks: true, iconizeLinks: true, renameLinks: true};</script><script src=\"https://wow.zamimg.com/widgets/power.js\"></script>\n"
		ExportString = ExportString.."<style>\nhtml { background-color: #000; };\n.divTable{ display: table; float: left; margin: 10px 10px; }\n.divTableRow { display: table-row; background-color: #000}\n.divTableRow:hover { background-color: #222; }\n.divTableHeading { background-color: #EEE; display: table-header-group; }\n.divTableCell, .divTableHead { border: 1px solid #999999; display: table-cell; padding: 3px 10px; }\n";
		ExportString = ExportString..".divPlayer { border: 1px solid #999999; display: table-cell; width: 700px; padding: 3px 10px; text-align: left; vertical-align: middle; word-wrap: normal; color: #ffffff; }\n.divClass { border: 1px solid #999999; display: table-cell; padding: 3px 10px; text-align: center; vertical-align: middle; color: #ffffff; }\n.divDKP { border: 1px solid #999999; display: table-cell; width: 200px%; padding: 3px 10px; text-align: center; vertical-align: middle; color: #ffffff; }\n"
		ExportString = ExportString..".divPlayerHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 50%; padding: 3px 10px; text-align: left; background-color: #bbb; }\n.divClassHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 150px; padding: 3px 10px; text-align: center; background-color: #bbb; }\n.divDKPHeader { border: 1px solid #999999; display: table-cell; font-weight: bold; width: 30%; padding: 3px 10px; text-align: center; background-color: #bbb; }\n"
		ExportString = ExportString..".divTableHeading { background-color: #EEE; display: table-header-group; font-weight: bold; }\n.divTableFoot { background-color: #EEE; display: table-footer-group; font-weight: bold; }\n.divTableBody { display: table-row-group; }\n</style>\n\n"
		ExportString = ExportString.."<br /><br />\n<div>\n   <button onclick=\"openTab('DKP')\">DKP Table</button>\n   <button onclick=\"openTab('DKPHistory')\">DKP History</button>\n   <button onclick=\"openTab('LootHistory')\">Loot History</button>\n</div>\n<br /><br />\n"

		ExportString = ExportString.."<div id=\"DKP\" class=\"tab\"><div class=\"divTable\" style=\"width: 30%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Player</div>\n         <div class=\"divClassHeader\">Class</div>\n         <div class=\"divDKPHeader\">DKP</div>\n      </div>\n"

		for i=1, #MonDKP_DKPTable do
			ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\">"..MonDKP_DKPTable[i].player.."</div>\n         <div class=\"divClass\" style=\"width: 150px;\"><img src=\"https://wow.zamimg.com/images/wow/icons/large/classicon_"..strlower(MonDKP_DKPTable[i].class)..".jpg\" height=\"24\" width=\"24\" /></div>\n         <div class=\"divDKP\">"..MonDKP_DKPTable[i].dkp.."</div>\n      </div>\n"
		end

		ExportString = ExportString.."   </div>\n</div>\n</div>"
	elseif table == MonDKP_DKPHistory then
		local numrows;

		if #MonDKP_DKPHistory > 200 then
			numrows = 200;
		else
			numrows = #MonDKP_DKPHistory
		end

		ExportString = "<div id=\"DKPHistory\" class=\"tab\" style=\"display:none;\"><div class=\"divTable\" style=\"width: 95%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Players</div>\n         <div class=\"divClassHeader\" style=\"width: 4%;\">DKP</div>\n         <div class=\"divDKPHeader\">Date/Reason</div>\n      </div>\n"

		for i=1, numrows do
			ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\" style=\"font-size: 0.7em; width: 71%;\">"..gsub(MonDKP_DKPHistory[i].players, ",", ", ").."</div>\n         <div class=\"divClass\" style=\"width: 4%;\">"..MonDKP_DKPHistory[i].dkp.."</div>\n         <div class=\"divDKP\" style=\"width: 25%; font-size: 0.7em;\">"..MonDKP_DKPHistory[i].reason.."<br />("..date("%m/%d/%y %H:%M:%S", MonDKP_DKPHistory[i].date)..") </div>\n      </div>\n"
		end
		ExportString = ExportString.."   </div>\n</div>\n</div>"

	elseif table == MonDKP_Loot then
		local numrows;

		if #MonDKP_Loot > 200 then
			numrows = 200;
		else
			numrows = #MonDKP_Loot
		end
		ExportString = "<div id=\"LootHistory\" class=\"tab\" style=\"display:none;\"><div class=\"divTable\" style=\"width: 50%;border: 1px solid #000;\">\n   <div class=\"divTableBody\">\n      <div class=\"divTableRow\">\n         <div class=\"divPlayerHeader\">Loot</div>\n         <div class=\"divClassHeader\">Player</div>\n         <div class=\"divDKPHeader\">From</div>\n      </div>\n"
		for i=1, numrows do
			local cur = MonDKP_Loot[i].loot
			local itemNumber = strsub(cur, string.find(cur, "Hitem:")+6, string.find(cur, ":", string.find(cur, "Hitem:")+6)-1)
			ExportString = ExportString.."      <div class=\"divTableRow\">\n         <div class=\"divPlayer\" style=\"width: 40%;\"><a href=\"https://www.wowhead.com/item="..itemNumber.."\" data-wowhead=\"item="..itemNumber.."\"></a></div>\n         <div class=\"divClass\" style=\"width: 20%;\">"..MonDKP_Loot[i].player.."</div>\n         <div class=\"divDKP\" style=\"width: 40%; font-size: 0.7em;\">"..MonDKP_Loot[i].zone..": "..MonDKP_Loot[i].boss.."<br />("..date("%m/%d/%y %H:%M:%S", MonDKP_Loot[i].date)..") </div>\n      </div>\n"
		end
		ExportString = ExportString.."   </div>\n</div>\n</div>\n</html>"
	end

	MonDKPExportBoxEditBox:SetText(ExportString)
end

function MonDKPExportBox_Show(text)
    if not MonDKPExportBox then
        local f = CreateFrame("Frame", "MonDKPExportBox", UIParent)
        f:SetPoint("CENTER")
        f:SetSize(700, 590)
        
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 17,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
        
        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)

        -- Close Button
		f.closeContainer = CreateFrame("Frame", "MonDKPTitle", f)
		f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
		f.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\MonolithDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		f.closeContainer:SetBackdropColor(0,0,0,0.9)
		f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		f.closeContainer:SetSize(28, 28)

		f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
		tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"
        
        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "MonDKPExportBoxScrollFrame", MonDKPExportBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 20, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -20)
        sf:SetPoint("BOTTOM", 0, 120)

        -- Description
        desc = f:CreateFontString(nil, "OVERLAY")
		desc:SetFontObject("MonDKPSmallLeft");
		desc:SetPoint("TOPLEFT", sf, "BOTTOMLEFT", 10, -20);
		desc:SetText("Export below one at a time in order. Copy all and paste into local .html file one after the other. DKP and Loot History often take a few seconds to generate and will lock your screen briefly. As a result they are limited to the most recent 200 entries for each. All tables will be tabbed for convenience.");
		desc:SetWidth(sf:GetWidth()-30)
        
        -- EditBox
        local eb = CreateFrame("EditBox", "MonDKPExportBoxEditBox", MonDKPExportBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        
        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(650, 500)
        
        local rb = CreateFrame("Button", "MonDKPExportBoxResizeButton", MonDKPExportBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)
        
        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
            end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())
            desc:SetWidth(sf:GetWidth()-30)
        end)
        f:Show()

        f.GenerateDKPButton = MonDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -355, 20, "1) Generate DKP Table");
		f.GenerateDKPButton:SetSize(150, 24)
		f.GenerateDKPButton:SetScript("OnClick", function()
			GenerateDKPTables(MonDKP_DKPTable)
		end)

		f.GenerateDKPHistoryButton = MonDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -200, 20, "2) Generate DKP History");
		f.GenerateDKPHistoryButton:SetSize(150, 24)
		f.GenerateDKPHistoryButton:SetScript("OnClick", function()
			GenerateDKPTables(MonDKP_DKPHistory)
		end)

		f.GenerateDKPLootButton = MonDKP:CreateButton("BOTTOMRIGHT", f, "BOTTOMRIGHT", -45, 20, "3) Generate Loot History");
		f.GenerateDKPLootButton:SetSize(150, 24)
		f.GenerateDKPLootButton:SetScript("OnClick", function()
			GenerateDKPTables(MonDKP_Loot)
		end)

		f.SelectAllButton = MonDKP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 45, 20, "Select All");
		f.SelectAllButton:SetSize(100, 20)
		f.SelectAllButton:SetScript("OnClick", function()
			MonDKPExportBoxEditBox:HighlightText()
			MonDKPExportBoxEditBox:SetFocus()
		end)
    end
    
    if text then
        MonDKPExportBoxEditBox:SetText(text)
    end
    MonDKPExportBox:Show()
end

function MonDKP:ToggleExportWindow()
	MonDKPExportBox_Show()
end