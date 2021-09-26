function CommunityDKPButton_OnLoad(self)
	if ( not self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	end
end

function CommunityDKPButton_OnMouseDown(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Down");
		self.Middle:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Down");
		self.Right:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Down");
	end
end

function CommunityDKPButton_OnMouseUp(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
	end
end

function CommunityDKPButton_OnShow(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
	end
end

function CommunityDKPButton_OnDisable(self)
	self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
end

function CommunityDKPButton_OnEnable(self)
	self.Left:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
	self.Middle:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
	self.Right:SetTexture("Interface\\AddOns\\CommunityDKP\\Media\\Textures\\CommunityDKP-Button-Up");
end
