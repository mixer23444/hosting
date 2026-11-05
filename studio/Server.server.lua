-- Вставь это в Script внутри ServerScriptService. Без Rojo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Lighting.ClockTime = 14
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(130, 140, 150)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = Lighting

local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Density = 0.25
atmo.Color = Color3.fromRGB(190, 205, 220)
atmo.Decay = Color3.fromRGB(170, 185, 200)
atmo.Glare = 0
atmo.Haze = 0.8
atmo.Parent = Lighting

local function part(props)
	local p = Instance.new(props.class or "Part")
	p.Anchored = if props.anchored == nil then true else props.anchored
	p.CanCollide = if props.collide == nil then true else props.collide
	p.Size = props.size or Vector3.new(4, 1, 4)
	p.CFrame = props.cf or CFrame.new()
	p.Color = props.color or Color3.fromRGB(160, 160, 160)
	p.Material = props.material or Enum.Material.Concrete
	p.Name = props.name or "Part"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency = props.transparency or 0
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent or workspace
	return p
end

local old = workspace:FindFirstChild("Baseplate")
if old then
	old:Destroy()
end

part({
	name = "Ground",
	size = Vector3.new(500, 2, 500),
	cf = CFrame.new(0, -1, 0),
	material = Enum.Material.Grass,
	color = Color3.fromRGB(90, 110, 70),
})

part({
	name = "Asphalt",
	size = Vector3.new(28, 0.3, 180),
	cf = CFrame.new(0, 0.15, 20),
	material = Enum.Material.Asphalt,
	color = Color3.fromRGB(45, 47, 49),
})

for i = -6, 6 do
	part({
		name = "Dash",
		size = Vector3.new(0.35, 0.08, 4),
		cf = CFrame.new(0, 0.36, i * 12),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(240, 230, 180),
	})
end

local function house(x, z, w, d, h, material, color)
	part({
		name = "House",
		size = Vector3.new(w, h, d),
		cf = CFrame.new(x, h / 2, z),
		material = material,
		color = color,
	})
	part({
		name = "Roof",
		size = Vector3.new(w + 1, 1, d + 1),
		cf = CFrame.new(x, h + 0.5, z),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(60, 64, 70),
	})
	part({
		name = "Window",
		size = Vector3.new(0.3, 2.5, 3),
		cf = CFrame.new(x - math.sign(x) * w / 2, 4, z),
		material = Enum.Material.Glass,
		color = Color3.fromRGB(190, 220, 230),
		transparency = 0.35,
	})
end

house(-36, -10, 16, 14, 12, Enum.Material.Brick, Color3.fromRGB(150, 80, 70))
house(-38, 25, 14, 16, 16, Enum.Material.Concrete, Color3.fromRGB(190, 186, 176))
house(36, 0, 16, 18, 14, Enum.Material.Brick, Color3.fromRGB(130, 95, 75))
house(38, 40, 14, 14, 11, Enum.Material.Concrete, Color3.fromRGB(175, 178, 182))

local function makeCar(position)
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = workspace

	local chassis = part({
		name = "Chassis",
		size = Vector3.new(6, 1, 11),
		cf = CFrame.new(position),
		color = Color3.fromRGB(22, 22, 26),
		material = Enum.Material.SmoothPlastic,
		anchored = false,
		parent = model,
	})

	local function weld(other)
		local w = Instance.new("WeldConstraint")
		w.Part0 = chassis
		w.Part1 = other
		w.Parent = chassis
	end

	local body = part({
		name = "Body",
		size = Vector3.new(6.2, 1.1, 10.5),
		cf = chassis.CFrame * CFrame.new(0, 1, 0),
		color = Color3.fromRGB(28, 28, 32),
		material = Enum.Material.SmoothPlastic,
		anchored = false,
		parent = model,
	})
	weld(body)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"
	seat.Size = Vector3.new(2, 0.5, 2)
	seat.CFrame = chassis.CFrame * CFrame.new(-0.6, 1.15, 0.3)
	seat.MaxSpeed = 50
	seat.Torque = 5
	seat.TurnSpeed = 2
	seat.Disabled = false
	seat.Anchored = false
	seat.Parent = model
	weld(seat)

	for _, side in { -1, 1 } do
		for _, z in { -3.4, 3.4 } do
			local wheel = part({
				name = "Wheel",
				size = Vector3.new(1.1, 2.3, 2.3),
				shape = Enum.PartType.Cylinder,
				cf = chassis.CFrame * CFrame.new(side * 2.5, -0.6, z) * CFrame.Angles(0, 0, math.rad(90)),
				color = Color3.fromRGB(15, 15, 15),
				material = Enum.Material.Rubber,
				anchored = false,
				parent = model,
			})
			weld(wheel)
		end
	end

	model.PrimaryPart = chassis

	local attachment = Instance.new("Attachment")
	attachment.Parent = chassis
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = 90000
	velocity.VectorVelocity = Vector3.zero
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = chassis
	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = attachment
	spin.MaxTorque = 50000
	spin.AngularVelocity = Vector3.zero
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.Parent = chassis

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Сесть"
	prompt.ObjectText = "Машина"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			seat:Sit(humanoid)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat
		if seat.Occupant then
			velocity.VectorVelocity = chassis.CFrame.LookVector * throttle * 42
			spin.AngularVelocity = Vector3.new(0, -steer * 1.5, 0)
		else
			velocity.VectorVelocity = Vector3.zero
			spin.AngularVelocity = Vector3.zero
		end
	end)

	return model
end

local car = makeCar(Vector3.new(0, 3, 6))

part({
	name = "ProvingPad",
	size = Vector3.new(70, 0.3, 140),
	cf = CFrame.new(0, 0.15, 380),
	material = Enum.Material.Asphalt,
	color = Color3.fromRGB(45, 47, 49),
})

local remote = ReplicatedStorage:FindFirstChild("GoProving") or Instance.new("RemoteEvent")
remote.Name = "GoProving"
remote.Parent = ReplicatedStorage
remote.OnServerEvent:Connect(function(player)
	car:PivotTo(CFrame.new(0, 4, 330))
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = car:FindFirstChild("DriveSeat")
	if humanoid and seat then
		seat:Sit(humanoid)
	end
end)
