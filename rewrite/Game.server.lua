-- Гараж. Новый плейс, один Script в ServerScriptService.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Lighting.ClockTime = 15
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(150, 156, 164)
Lighting.OutdoorAmbient = Color3.fromRGB(168, 174, 182)

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = Lighting

local function part(name, size, cf, material, color, parent, anchored)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cf
	item.Material = material
	item.Color = color
	item.Anchored = anchored ~= false
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent or workspace
	return item
end

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

part("Grass", Vector3.new(420, 2, 420), CFrame.new(0, -1, 0), Enum.Material.Grass, Color3.fromRGB(78, 108, 62))
part("Road", Vector3.new(22, 0.3, 160), CFrame.new(0, 0.15, 30), Enum.Material.Asphalt, Color3.fromRGB(40, 42, 44))
part("GarageFloor", Vector3.new(26, 0.3, 20), CFrame.new(-40, 0.15, -6), Enum.Material.DiamondPlate, Color3.fromRGB(90, 92, 96))
part("GarageWall", Vector3.new(1, 8, 20), CFrame.new(-53, 4, -6), Enum.Material.Concrete, Color3.fromRGB(168, 166, 160))
part("GarageRoof", Vector3.new(26, 0.6, 20), CFrame.new(-40, 8, -6), Enum.Material.Metal, Color3.fromRGB(70, 72, 76))
part("Pad", Vector3.new(50, 0.3, 90), CFrame.new(0, 0.15, 240), Enum.Material.Asphalt, Color3.fromRGB(40, 42, 44))

local cash = {}
local stats = {}

local function defaultStats()
	return { speed = 1, accel = 1, grip = 1, weight = 1 }
end

local model = Instance.new("Model")
model.Name = "Car"
model.Parent = workspace

local chassis = part("Chassis", Vector3.new(6, 1, 11), CFrame.new(-28, 3, -6), Enum.Material.SmoothPlastic, Color3.fromRGB(18, 18, 22), model, false)
local function weld(other)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = chassis
	constraint.Part1 = other
	constraint.Parent = chassis
end
weld(part("Body", Vector3.new(6.2, 1, 10.2), chassis.CFrame * CFrame.new(0, 0.9, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(24, 24, 28), model, false))

local seat = Instance.new("VehicleSeat")
seat.Name = "DriveSeat"
seat.Size = Vector3.new(2, 0.4, 2)
seat.CFrame = chassis.CFrame * CFrame.new(-0.55, 1.05, 0.2)
seat.Anchored = false
seat.Parent = model
weld(seat)

for _, side in { -1, 1 } do
	for _, z in { -3.2, 3.2 } do
		local wheel = part("Wheel", Vector3.new(1, 2.2, 2.2), chassis.CFrame * CFrame.new(side * 2.4, -0.45, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Rubber, Color3.fromRGB(10, 10, 10), model, false)
		wheel.Shape = Enum.PartType.Cylinder
		weld(wheel)
	end
end
model.PrimaryPart = chassis

local attachment = Instance.new("Attachment")
attachment.Parent = chassis
local velocity = Instance.new("LinearVelocity")
velocity.Attachment0 = attachment
velocity.MaxForce = 100000
velocity.RelativeTo = Enum.ActuatorRelativeTo.World
velocity.Parent = chassis
local spin = Instance.new("AngularVelocity")
spin.Attachment0 = attachment
spin.MaxTorque = 60000
spin.RelativeTo = Enum.ActuatorRelativeTo.World
spin.Parent = chassis

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Сесть"
prompt.ObjectText = "Машина"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = seat
prompt.Triggered:Connect(function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end
end)

local function tune(player)
	local data = stats[player] or defaultStats()
	return 28 + data.speed * 8, 1 + data.grip * 0.15, math.max(0.7, 1.3 - data.weight * 0.08)
end

RunService.Heartbeat:Connect(function()
	local occupant = seat.Occupant
	local player = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
	if player then
		local top, grip, mass = tune(player)
		velocity.VectorVelocity = chassis.CFrame.LookVector * seat.ThrottleFloat * top
		spin.AngularVelocity = Vector3.new(0, -seat.SteerFloat * grip, 0)
		chassis.CustomPhysicalProperties = PhysicalProperties.new(mass, 0.4, 0.2)
	else
		velocity.VectorVelocity = Vector3.zero
		spin.AngularVelocity = Vector3.zero
	end
end)

local update = Instance.new("RemoteEvent")
update.Name = "GarageUpdate"
update.Parent = ReplicatedStorage
local buy = Instance.new("RemoteEvent")
buy.Name = "BuyUpgrade"
buy.Parent = ReplicatedStorage
local drive = Instance.new("RemoteEvent")
drive.Name = "GoPad"
drive.Parent = ReplicatedStorage
local race = Instance.new("RemoteEvent")
race.Name = "FinishLap"
race.Parent = ReplicatedStorage

local prices = { speed = 150, accel = 150, grip = 120, weight = 180 }

local function push(player)
	update:FireClient(player, cash[player] or 500, stats[player] or defaultStats())
end

Players.PlayerAdded:Connect(function(player)
	cash[player] = 500
	stats[player] = defaultStats()
	player.CharacterAdded:Wait()
	push(player)
end)

buy.OnServerEvent:Connect(function(player, key)
	local cost = prices[key]
	local data = stats[player]
	if not cost or not data or data[key] >= 5 then
		return
	end
	if (cash[player] or 0) < cost then
		return
	end
	cash[player] -= cost
	data[key] += 1
	push(player)
end)

drive.OnServerEvent:Connect(function(player)
	model:PivotTo(CFrame.new(0, 4, 210))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end
end)

race.OnServerEvent:Connect(function(player, seconds)
	if typeof(seconds) ~= "number" then
		return
	end
	local payout = math.clamp(math.floor(80 - seconds), 15, 80)
	cash[player] = (cash[player] or 0) + payout
	model:PivotTo(CFrame.new(-28, 4, -6))
	push(player)
end)
