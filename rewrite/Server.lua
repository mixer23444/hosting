-- Новый плейс. Script в ServerScriptService. Старый код не использовать.
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Lighting.ClockTime = 14.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(140, 148, 156)
Lighting.OutdoorAmbient = Color3.fromRGB(160, 168, 176)

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = Lighting

local function part(name, size, cf, material, color, parent, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Material = material
	p.Color = color
	p.Anchored = anchored ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or workspace
	return p
end

local base = workspace:FindFirstChild("Baseplate")
if base then
	base:Destroy()
end

part("Ground", Vector3.new(400, 2, 400), CFrame.new(0, -1, 0), Enum.Material.Grass, Color3.fromRGB(86, 112, 68))
part("Road", Vector3.new(24, 0.25, 140), CFrame.new(0, 0.12, 10), Enum.Material.Asphalt, Color3.fromRGB(42, 44, 46))

for i = -4, 4 do
	part("Dash", Vector3.new(0.3, 0.06, 3.5), CFrame.new(0, 0.3, i * 14), Enum.Material.SmoothPlastic, Color3.fromRGB(235, 225, 170))
end

local function house(x, z, w, d, h, material, color)
	part("House", Vector3.new(w, h, d), CFrame.new(x, h / 2, z), material, color)
	part("Roof", Vector3.new(w + 1, 0.8, d + 1), CFrame.new(x, h + 0.4, z), Enum.Material.Metal, Color3.fromRGB(55, 58, 62))
end

house(-32, -8, 14, 12, 10, Enum.Material.Brick, Color3.fromRGB(146, 78, 68))
house(32, 18, 14, 14, 12, Enum.Material.Concrete, Color3.fromRGB(186, 182, 174))

local model = Instance.new("Model")
model.Name = "Car"
model.Parent = workspace

local chassis = part("Chassis", Vector3.new(6, 1, 11), CFrame.new(0, 3, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(20, 20, 24), model, false)
local function weld(other)
	local w = Instance.new("WeldConstraint")
	w.Part0 = chassis
	w.Part1 = other
	w.Parent = chassis
end

weld(part("Body", Vector3.new(6.1, 1, 10), chassis.CFrame * CFrame.new(0, 0.9, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(25, 25, 30), model, false))

local seat = Instance.new("VehicleSeat")
seat.Name = "DriveSeat"
seat.Size = Vector3.new(2, 0.4, 2)
seat.CFrame = chassis.CFrame * CFrame.new(-0.6, 1.1, 0.2)
seat.MaxSpeed = 40
seat.Anchored = false
seat.Parent = model
weld(seat)

for _, side in { -1, 1 } do
	for _, z in { -3.2, 3.2 } do
		local wheel = part("Wheel", Vector3.new(1, 2.2, 2.2), chassis.CFrame * CFrame.new(side * 2.4, -0.5, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Rubber, Color3.fromRGB(12, 12, 12), model, false)
		wheel.Shape = Enum.PartType.Cylinder
		weld(wheel)
	end
end
model.PrimaryPart = chassis

local attachment = Instance.new("Attachment")
attachment.Parent = chassis
local velocity = Instance.new("LinearVelocity")
velocity.Attachment0 = attachment
velocity.MaxForce = 80000
velocity.RelativeTo = Enum.ActuatorRelativeTo.World
velocity.Parent = chassis
local spin = Instance.new("AngularVelocity")
spin.Attachment0 = attachment
spin.MaxTorque = 40000
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

RunService.Heartbeat:Connect(function()
	if seat.Occupant then
		velocity.VectorVelocity = chassis.CFrame.LookVector * seat.ThrottleFloat * 36
		spin.AngularVelocity = Vector3.new(0, -seat.SteerFloat * 1.4, 0)
	else
		velocity.VectorVelocity = Vector3.zero
		spin.AngularVelocity = Vector3.zero
	end
end)

part("Pad", Vector3.new(60, 0.25, 100), CFrame.new(0, 0.12, 280), Enum.Material.Asphalt, Color3.fromRGB(42, 44, 46))

local remote = Instance.new("RemoteEvent")
remote.Name = "GoPad"
remote.Parent = ReplicatedStorage
remote.OnServerEvent:Connect(function(player)
	model:PivotTo(CFrame.new(0, 4, 250))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end
end)
