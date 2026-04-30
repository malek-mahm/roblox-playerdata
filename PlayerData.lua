local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local DataStoreService=game:GetService("DataStoreService")

local PlayerData={}
PlayerData.__index=PlayerData
PlayerData.All={}

local function isNumber(v)
	return typeof(v)=="number" and v>=0
end

local function setValue(obj,value)
	if obj and obj.Parent then
		obj.Value=value
	end
end

function PlayerData.new(player)

	local self=setmetatable({},PlayerData)

	self.Player=player
	self.Money=0
	self.Rate=1
	self.Multiplier=1
	self.Upgrades=0
	self.Rebirths=0
	self.PrestigeLevel=0
	self.RebirthBoost=1
	self.PrestigeBoost=1
	self.UpgradeCost=100
	self.RebirthCost=500
	self.PrestigeCost=5000
	self.LastUpgrade=0
	self.SessionTime=0
	self.PlayTime=0
	self.TotalEarned=0
	self.Clicks=0
	self.Loaded=true

	local stats=Instance.new("Folder")
	stats.Name="leaderstats"
	stats.Parent=player

	local money=Instance.new("IntValue")
	money.Name="Money"
	money.Value=0
	money.Parent=stats

	local upgrades=Instance.new("IntValue")
	upgrades.Name="Upgrades"
	upgrades.Value=0
	upgrades.Parent=stats

	local rebirths=Instance.new("IntValue")
	rebirths.Name="Rebirths"
	rebirths.Value=0
	rebirths.Parent=stats

	local prestige=Instance.new("IntValue")
	prestige.Name="Prestige"
	prestige.Value=0
	prestige.Parent=stats

	self.MoneyValue=money
	self.UpgradesValue=upgrades
	self.RebirthsValue=rebirths
	self.PrestigeValue=prestige

	local folder=Instance.new("Folder")
	folder.Name="Prices"
	folder.Parent=player

	local upCost=Instance.new("IntValue")
	upCost.Name="UpgradeCost"
	upCost.Value=self.UpgradeCost
	upCost.Parent=folder

	local rebCost=Instance.new("IntValue")
	rebCost.Name="RebirthCost"
	rebCost.Value=self.RebirthCost
	rebCost.Parent=folder

	local preCost=Instance.new("IntValue")
	preCost.Name="PrestigeCost"
	preCost.Value=self.PrestigeCost
	preCost.Parent=folder

	self.UpgradeCostValue=upCost
	self.RebirthCostValue=rebCost
	self.PrestigeCostValue=preCost

	PlayerData.All[player]=self

	return self
end

function PlayerData:SetMoney(amount)
	if not isNumber(amount) then return end
	self.Money=amount
	setValue(self.MoneyValue,amount)
end

function PlayerData:AddMoney(amount)
	if not isNumber(amount) then return end
	local gain=amount*self.Multiplier*self.RebirthBoost*self.PrestigeBoost
	self:SetMoney(self.Money+gain)
	self.TotalEarned+=gain
end

function PlayerData:RemoveMoney(amount)
	if not isNumber(amount) then return end
	self:SetMoney(self.Money-amount)
end

function PlayerData:CanAfford(amount)
	return isNumber(amount) and self.Money>=amount
end

function PlayerData:Click()
	self.Clicks+=1
	self:AddMoney(1*self.Multiplier)
end

function PlayerData:TickIncome()
	local income=self.Rate*self.RebirthBoost*self.PrestigeBoost
	self:AddMoney(income)
	self.PlayTime+=1
end

function PlayerData:Upgrade()
	local now=os.clock()
	if now-self.LastUpgrade<0.2 then return end
	self.LastUpgrade=now
	if not self:CanAfford(self.UpgradeCost) then return end
	self:RemoveMoney(self.UpgradeCost)
	self.Upgrades+=1
	self.Rate+=1
	self.UpgradeCost=math.floor(self.UpgradeCost*1.4)
	setValue(self.UpgradesValue,self.Upgrades)
	setValue(self.UpgradeCostValue,self.UpgradeCost)
end

function PlayerData:Rebirth()
	if not self:CanAfford(self.RebirthCost) then return end
	self:SetMoney(0)
	self:ResetUpgrades()
	self.Rebirths+=1
	self.RebirthBoost=1+(self.Rebirths*0.5)
	self.RebirthCost=math.floor(self.RebirthCost*1.6)
	setValue(self.RebirthsValue,self.Rebirths)
	setValue(self.RebirthCostValue,self.RebirthCost)
end

function PlayerData:Prestige()
	if not self:CanAfford(self.PrestigeCost) then return end
	self:SetMoney(0)
	self:ResetUpgrades()
	self.Rebirths=0
	self.RebirthBoost=1
	self.PrestigeLevel+=1
	self.PrestigeBoost=1+(self.PrestigeLevel*2)
	self.PrestigeCost=math.floor(self.PrestigeCost*3)
	setValue(self.PrestigeValue,self.PrestigeLevel)
	setValue(self.PrestigeCostValue,self.PrestigeCost)
end

function PlayerData:ResetUpgrades()
	self.Upgrades=0
	self.Rate=1
	self.UpgradeCost=100
	setValue(self.UpgradesValue,0)
	setValue(self.UpgradeCostValue,100)
end

function PlayerData:SoftReset()
	self:SetMoney(0)
	self.Upgrades=0
	self.Rate=1
	self.Rebirths=0
	self.RebirthBoost=1
end

function PlayerData:ResetAll()
	self:SetMoney(0)
	self.Upgrades=0
	self.Rebirths=0
	self.PrestigeLevel=0
	self.Rate=1
	self.RebirthBoost=1
	self.PrestigeBoost=1
	self.UpgradeCost=100
	self.RebirthCost=500
	self.PrestigeCost=5000
end

function PlayerData:UpdateSession()
	self.SessionTime+=1
end

function PlayerData:IsValid()
	return self.Player and self.Player.Parent
end

function PlayerData:GetStats()
	return{
		Money=self.Money,
		Upgrades=self.Upgrades,
		Rebirths=self.Rebirths,
		Prestige=self.PrestigeLevel,
		Rate=self.Rate,
		Clicks=self.Clicks,
		TotalEarned=self.TotalEarned,
		PlayTime=self.PlayTime
	}
end

function PlayerData.Remove(player)
	PlayerData.All[player]=nil
end

task.spawn(function()
	while true do
		task.wait(1)
		for _,data in pairs(PlayerData.All) do
			if data and data:IsValid() then
				pcall(function()
					data:TickIncome()
					data:UpdateSession()
				end)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	PlayerData.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Remove(player)
end)

for _,player in ipairs(Players:GetPlayers()) do
	PlayerData.new(player)
end

return PlayerData
