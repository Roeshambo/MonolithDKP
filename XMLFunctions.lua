function MonolithDKPButton_OnLoad(self)
	if ( not self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	end
end

function MonolithDKPButton_OnMouseDown(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Down");
		self.Middle:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Down");
		self.Right:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Down");
	end
end

function MonolithDKPButton_OnMouseUp(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
	end
end

function MonolithDKPButton_OnShow(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
	end
end

function MonolithDKPButton_OnDisable(self)
	self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
end

function MonolithDKPButton_OnEnable(self)
	self.Left:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
	self.Middle:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
	self.Right:SetTexture("Interface\\AddOns\\MonolithDKP\\Media\\Textures\\MonolithDKP-Button-Up");
end