-- Гараж. Script в ServerScriptService. Замени старый Script целиком.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Lighting.ClockTime = 15
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(140, 148, 156)
Lighting.OutdoorAmbient = Color3.fromRGB(160, 168, 176)
Lighting.EnvironmentDiffuseScale = 0.45

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = Lighting

local function paint(part, textureId, studs)
	local face = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	for _, normal in face do
		local texture = Instance.new("Texture")
		texture.Face = normal
		texture.Texture = textureId
		texture.StudsPerTileU = studs
		texture.StudsPerTileV = studs
		texture.Parent = part
	end
end

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

local lot = part("Lot", Vector3.new(280, 1, 220), CFrame.new(0, -0.5, 20), Enum.Material.Concrete, Color3.fromRGB(120, 122, 124))
paint(lot, "rbxassetid://6372755229", 18)

local road = part("Road", Vector3.new(28, 0.2, 160), CFrame.new(0, 0.15, 40), Enum.Material.Asphalt, Color3.fromRGB(38, 40, 42))
paint(road, "rbxassetid://6372755229", 10)
for i = -5, 6 do
	part("Dash", Vector3.new(0.28, 0.05, 4), CFrame.new(0, 0.3, i * 12), Enum.Material.SmoothPlastic, Color3.fromRGB(230, 220, 160))
end
part("SidewalkL", Vector3.new(8, 0.25, 160), CFrame.new(-18, 0.2, 40), Enum.Material.Concrete, Color3.fromRGB(170, 170, 168))
part("SidewalkR", Vector3.new(8, 0.25, 160), CFrame.new(18, 0.2, 40), Enum.Material.Concrete, Color3.fromRGB(170, 170, 168))

local pad = part("Pad", Vector3.new(70, 0.2, 110), CFrame.new(0, 0.15, 250), Enum.Material.Asphalt, Color3.fromRGB(38, 40, 42))
paint(pad, "rbxassetid://6372755229", 12)
part("PadLine", Vector3.new(0.3, 0.05, 80), CFrame.new(0, 0.32, 250), Enum.Material.SmoothPlastic, Color3.fromRGB(230, 220, 160))

local slots = {
	Vector3.new(-48, 0, -20),
	Vector3.new(-48, 0, 16),
	Vector3.new(48, 0, -20),
	Vector3.new(48, 0, 16),
}

local function garage(origin, face)
	local floor = part("GarageFloor", Vector3.new(22, 0.25, 16), CFrame.new(origin + Vector3.new(0, 0.2, 0)), Enum.Material.DiamondPlate, Color3.fromRGB(88, 90, 94))
	paint(floor, "rbxassetid://143657515", 6)
	part("BackWall", Vector3.new(22, 8, 1), CFrame.new(origin + Vector3.new(0, 4, -face * 8)), Enum.Material.Concrete, Color3.fromRGB(168, 166, 160))
	part("SideA", Vector3.new(1, 8, 16), CFrame.new(origin + Vector3.new(-11, 4, 0)), Enum.Material.Concrete, Color3.fromRGB(158, 156, 150))
	part("SideB", Vector3.new(1, 8, 16), CFrame.new(origin + Vector3.new(11, 4, 0)), Enum.Material.Concrete, Color3.fromRGB(158, 156, 150))
	part("Roof", Vector3.new(22, 0.5, 16), CFrame.new(origin + Vector3.new(0, 8.2, 0)), Enum.Material.Metal, Color3.fromRGB(62, 66, 72))
	local window = part("Window", Vector3.new(6, 2.2, 0.3), CFrame.new(origin + Vector3.new(0, 5.2, -face * 8)), Enum.Material.Glass, Color3.fromRGB(180, 210, 220))
	window.Transparency = 0.35
	part("Bench", Vector3.new(6, 1, 2), CFrame.new(origin + Vector3.new(6, 0.8, -4)), Enum.Material.Wood, Color3.fromRGB(110, 78, 48))
end

for index, origin in slots do
	garage(origin, if origin.X < 0 then 1 else -1)
end

local cash = {}
local stats = {}
local cars = {}

local function defaultStats()
	return { speed = 1, accel = 1, grip = 1, weight = 1 }
end

local function weld(chassis, other)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = chassis
	constraint.Part1 = other
	constraint.Parent = chassis
end

local function makeCar(position)
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = workspace
	local chassis = part("Chassis", Vector3.new(5.4, 0.7, 11), CFrame.new(position + Vector3.new(0, 2.2, 6)), Enum.Material.SmoothPlastic, Color3.fromRGB(22, 24, 30), model, false)
	weld(chassis, part("Hood", Vector3.new(5.2, 0.5, 3.2), chassis.CFrame * CFrame.new(0, 0.7, -3.2), Enum.Material.SmoothPlastic, Color3.fromRGB(28, 32, 42), model, false))
	weld(chassis, part("Cabin", Vector3.new(4.8, 1.3, 4), chassis.CFrame * CFrame.new(0, 1.15, 0.4), Enum.Material.SmoothPlastic, Color3.fromRGB(18, 20, 26), model, false))
	local glass = part("Glass", Vector3.new(4.5, 1, 3.4), chassis.CFrame * CFrame.new(0, 1.3, 0.2), Enum.Material.Glass, Color3.fromRGB(170, 200, 214), model, false)
	glass.Transparency = 0.4
	glass.CanCollide = false
	weld(chassis, glass)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"
	seat.Size = Vector3.new(1.6, 0.35, 1.6)
	seat.CFrame = chassis.CFrame * CFrame.new(-0.45, 0.85, 0.3)
	seat.MaxSpeed = 45
	seat.Anchored = false
	seat.Parent = model
	weld(chassis, seat)
	for _, side in { -1, 1 } do
		for _, z in { -3.3, 3.3 } do
			local wheel = part("Wheel", Vector3.new(0.9, 2.1, 2.1), chassis.CFrame * CFrame.new(side * 2.15, -0.35, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Rubber, Color3.fromRGB(16, 16, 16), model, false)
			wheel.Shape = Enum.PartType.Cylinder
			weld(chassis, wheel)
		end
	end
	model.PrimaryPart = chassis
	local attachment = Instance.new("Attachment")
	attachment.Parent = chassis
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "Drive"
	velocity.Attachment0 = attachment
	velocity.MaxForce = 120000
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = chassis
	local spin = Instance.new("AngularVelocity")
	spin.Name = "Steer"
	spin.Attachment0 = attachment
	spin.MaxTorque = 70000
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.Parent = chassis
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Сесть"
	prompt.ObjectText = "Машина"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			seat:Sit(humanoid)
		end
	end)
	return model, chassis, seat, velocity, spin
end

local update = Instance.new("RemoteEvent")
update.Name = "GarageUpdate"
update.Parent = ReplicatedStorage
local buy = Instance.new("RemoteEvent")
buy.Name = "BuyUpgrade"
buy.Parent = ReplicatedStorage
local goPad = Instance.new("RemoteEvent")
goPad.Name = "GoPad"
goPad.Parent = ReplicatedStorage
local finish = Instance.new("RemoteEvent")
finish.Name = "FinishLap"
finish.Parent = ReplicatedStorage

local prices = { speed = 150, accel = 150, grip = 120, weight = 180 }
local taken = {}

local function push(player)
	update:FireClient(player, cash[player] or 500, stats[player])
end

local function giveCar(player)
	for index, origin in slots do
		if not taken[index] then
			taken[index] = player
			local model, chassis, seat, velocity, spin = makeCar(origin + Vector3.new(0, 0, 0))
			cars[player] = { model = model, chassis = chassis, seat = seat, velocity = velocity, spin = spin, home = origin + Vector3.new(0, 2.2, 6) }
			player.AncestryChanged:Connect(function()
				if not player:IsDescendantOf(game) then
					taken[index] = nil
				end
			end)
			return
		end
	end
end

RunService.Heartbeat:Connect(function()
	for player, car in cars do
		local seat = car.seat
		if seat.Occupant and seat.Occupant.Parent and Players:GetPlayerFromCharacter(seat.Occupant.Parent) == player then
			local data = stats[player]
			local top = 26 + data.speed * 7
			car.velocity.VectorVelocity = car.chassis.CFrame.LookVector * seat.ThrottleFloat * top
			car.spin.AngularVelocity = Vector3.new(0, -seat.SteerFloat * (1 + data.grip * 0.12), 0)
		else
			car.velocity.VectorVelocity = Vector3.zero
			car.spin.AngularVelocity = Vector3.zero
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	cash[player] = 500
	stats[player] = { speed = 1, accel = 1, grip = 1, weight = 1 }
	giveCar(player)
	task.defer(function()
		push(player)
	end)
end)
for _, player in Players:GetPlayers() do
	cash[player] = 500
	stats[player] = { speed = 1, accel = 1, grip = 1, weight = 1 }
	giveCar(player)
	push(player)
end

Players.PlayerRemoving:Connect(function(player)
	local car = cars[player]
	if car and car.model then
		car.model:Destroy()
	end
	cars[player] = nil
	cash[player] = nil
	stats[player] = nil
end)

buy.OnServerEvent:Connect(function(player, key)
	local cost = prices[key]
	local data = stats[player]
	if not cost or not data or data[key] >= 5 or (cash[player] or 0) < cost then
		return
	end
	cash[player] -= cost
	data[key] += 1
	push(player)
end)

goPad.OnServerEvent:Connect(function(player)
	local car = cars[player]
	if not car then
		return
	end
	car.model:PivotTo(CFrame.new(0, 3, 210))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		car.seat:Sit(humanoid)
	end
end)

finish.OnServerEvent:Connect(function(player, seconds)
	if typeof(seconds) ~= "number" then
		return
	end
	local car = cars[player]
	cash[player] = (cash[player] or 0) + math.clamp(math.floor(90 - seconds), 20, 90)
	if car then
		car.model:PivotTo(CFrame.new(car.home))
	end
	push(player)
end)
