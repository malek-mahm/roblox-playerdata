local Players = game:GetService("Players")
local RunService = game:GetService("RunService")



local PlayerData = {}
PlayerData.__index = PlayerData

PlayerData.All = {}



--// simple validation
local function isNumber(v)
	return typeof(v) == "number" and v >= 0
end



--// safe value update
local function setValue(obj, value)
	if obj and obj.Parent then
		obj.Value = value
	end
end



--// create player object
function PlayerData.new(player)

	local self = setmetatable({}, PlayerData)

	self.Player = player

	self.Money = 0
	self.Rate = 1
	self.Multiplier = 1

	self.Upgrades = 0
	self.Rebirths = 0

	self.RebirthBoost = 1

	self.UpgradeCost = 100
	self.RebirthCost = 500



	-- leaderstats
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = stats

	local upgrades = Instance.new("IntValue")
	upgrades.Name = "Upgrades"
	upgrades.Value = 0
	upgrades.Parent = stats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = stats



	self.MoneyValue = money
	self.UpgradesValue = upgrades
	self.RebirthsValue = rebirths



	-- price storage
	local folder = Instance.new("Folder")
	folder.Name = "Prices"
	folder.Parent = player

	local upCost = Instance.new("IntValue")
	upCost.Name = "UpgradeCost"
	upCost.Value = self.UpgradeCost
	upCost.Parent = folder

	local rebCost = Instance.new("IntValue")
	rebCost.Name = "RebirthCost"
	rebCost.Value = self.RebirthCost
	rebCost.Parent = folder

	self.UpgradeCostValue = upCost
	self.RebirthCostValue = rebCost



	PlayerData.All[player] = self

	return self
end



--// money system
function PlayerData:SetMoney(amount)
	if not isNumber(amount) then return end
	self.Money = amount
	setValue(self.MoneyValue, amount)
end



function PlayerData:AddMoney(amount)
	if not isNumber(amount) then return end

	local gain = amount * self.Multiplier * self.RebirthBoost
	self:SetMoney(self.Money + gain)
end



function PlayerData:RemoveMoney(amount)
	if not isNumber(amount) then return end
	self:SetMoney(self.Money - amount)
end



function PlayerData:CanAfford(amount)
	return isNumber(amount) and self.Money >= amount
end



--// income loop logic
function PlayerData:TickIncome()

	local income = self.Rate * self.RebirthBoost
	self:AddMoney(income)

end



--// upgrade system
function PlayerData:Upgrade()

	if not self:CanAfford(self.UpgradeCost) then return end

	self:RemoveMoney(self.UpgradeCost)

	self.Upgrades += 1
	self.Rate += 1

	self.UpgradeCost = math.floor(self.UpgradeCost * 1.4)

	setValue(self.UpgradesValue, self.Upgrades)
	setValue(self.UpgradeCostValue, self.UpgradeCost)

end



function PlayerData:ResetUpgrades()

	self.Upgrades = 0
	self.Rate = 1
	self.UpgradeCost = 100

	setValue(self.UpgradesValue, 0)
	setValue(self.UpgradeCostValue, 100)

end



--// rebirth system
function PlayerData:Rebirth()

	if not self:CanAfford(self.RebirthCost) then return end

	self:SetMoney(0)
	self:ResetUpgrades()

	self.Rebirths += 1

	self.RebirthBoost = 1 + (self.Rebirths * 0.5)

	self.RebirthCost = math.floor(self.RebirthCost * 1.6)

	setValue(self.RebirthsValue, self.Rebirths)
	setValue(self.RebirthCostValue, self.RebirthCost)

end



--// multiplier system
function PlayerData:SetMultiplier(value)
	if not isNumber(value) then return end
	self.Multiplier = value
end



--// reset system
function PlayerData:ResetAll()

	self:SetMoney(0)

	self.Upgrades = 0
	self.Rebirths = 0

	self.Rate = 1
	self.RebirthBoost = 1

	self.UpgradeCost = 100
	self.RebirthCost = 500

end



--// validity check
function PlayerData:IsValid()
	return self.Player and self.Player.Parent
end



--// remove player
function PlayerData.Remove(player)
	PlayerData.All[player] = nil
end



--// auto income loop
task.spawn(function()

	while true do
		task.wait(1)

		for _, data in pairs(PlayerData.All) do
			if data and data:IsValid() then
				pcall(function()
					data:TickIncome()
				end)
			end
		end
	end

end)



--// player handling
Players.PlayerAdded:Connect(function(player)
	PlayerData.new(player)
end)



Players.PlayerRemoving:Connect(function(player)
	PlayerData.Remove(player)
end)



--// fix for players already in server
for _, player in ipairs(Players:GetPlayers()) do
	PlayerData.new(player)
end



return PlayerData