-- Sedan assembled from mesh-style parts: painted shell, glass, lamp lenses, rubber tires.
-- Not a single neon brick. Collider is the lower hull; wheels carry the car.

local Config = require(script.Parent.Config)
local Physics = require(script.Parent.Physics)
local World = require(script.Parent.World)
local VehicleDriver = require(script.Parent.VehicleDriver)

local CarBuilder = {}

local R = Config.WHEEL_RADIUS

local function smooth(part: BasePart)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function panel(model: Model, chassis: BasePart, props): BasePart
	local part = Instance.new(props.class or "Part")
	part.Name = props.name or "Panel"
	part.Size = props.size
	local rot = props.rot or Vector3.zero
	part.CFrame = chassis.CFrame
		* CFrame.new(props.pos)
		* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	part.Color = props.color or Color3.fromRGB(42, 46, 51)
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = props.collide == true
	part.Massless = props.massless ~= false
	part.Transparency = props.transparency or 0
	part.Reflectance = props.reflectance or 0
	part.CastShadow = true
	smooth(part)
	if props.shape == "cylinder" then
		part.Shape = Enum.PartType.Cylinder
	elseif props.shape == "ball" then
		part.Shape = Enum.PartType.Ball
	end
	if props.paint then
		part:SetAttribute("Paint", true)
	end
	part.Parent = model
	World.weld(chassis, part)
	return part
end

local function addWheel(model: Model, chassis: BasePart, constraints: Folder, name: string, x: number, z: number, isFront: boolean)
	local localPos = Vector3.new(x, R - Config.CHASSIS_Y, z)
	local wheelCF = chassis.CFrame * CFrame.new(localPos)

	local hub = Instance.new("Part")
	hub.Name = name .. "Hub"
	hub.Size = Vector3.new(0.4, 0.4, 0.4)
	hub.CFrame = wheelCF
	hub.Transparency = 1
	hub.Anchored = true
	hub.CanCollide = false
	hub.Massless = false
	hub.CustomPhysicalProperties = PhysicalProperties.new(0.05, 0.1, 0, 0, 0)
	hub.Parent = model

	if isFront then
		local mount = Instance.new("Attachment")
		mount.Name = name .. "SteerMount"
		mount.CFrame = CFrame.new(localPos)
		mount.Axis = Vector3.new(0, 1, 0)
		mount.SecondaryAxis = Vector3.new(1, 0, 0)
		mount.Parent = chassis

		local hubAtt = Instance.new("Attachment")
		hubAtt.Axis = Vector3.new(0, 1, 0)
		hubAtt.SecondaryAxis = Vector3.new(1, 0, 0)
		hubAtt.Parent = hub

		local servo = Instance.new("HingeConstraint")
		servo.Name = "Steer" .. name
		servo.Attachment0 = mount
		servo.Attachment1 = hubAtt
		servo.ActuatorType = Enum.ActuatorType.Servo
		servo.ServoMaxTorque = 80000
		servo.AngularSpeed = 3
		servo.AngularResponsiveness = 30
		servo.TargetAngle = 0
		servo.LimitsEnabled = true
		servo.LowerAngle = -34
		servo.UpperAngle = 34
		servo:SetAttribute("Role", "steer")
		servo.Parent = constraints
	else
		World.weld(chassis, hub)
	end

	local tire = Instance.new("Part")
	tire.Name = name
	tire.Shape = Enum.PartType.Cylinder
	tire.Size = Vector3.new(0.74, R * 2, R * 2)
	tire.CFrame = wheelCF
	tire.Color = Color3.fromRGB(18, 18, 18)
	tire.Material = Enum.Material.SmoothPlastic
	tire.Reflectance = 0.015
	tire.Anchored = true
	tire.CanCollide = true
	tire.Massless = false
	tire.Parent = model
	smooth(tire)

	local hubSpin = Instance.new("Attachment")
	hubSpin.Axis = Vector3.new(1, 0, 0)
	hubSpin.SecondaryAxis = Vector3.new(0, 1, 0)
	hubSpin.Parent = hub

	local tireSpin = Instance.new("Attachment")
	tireSpin.Axis = Vector3.new(1, 0, 0)
	tireSpin.SecondaryAxis = Vector3.new(0, 1, 0)
	tireSpin.Parent = tire

	local motor = Instance.new("HingeConstraint")
	motor.Name = "Drive" .. name
	motor.Attachment0 = hubSpin
	motor.Attachment1 = tireSpin
	motor.ActuatorType = Enum.ActuatorType.Motor
	motor.MotorMaxTorque = 0
	motor.AngularVelocity = 0
	motor:SetAttribute("Role", "drive")
	motor:SetAttribute("Share", if isFront then 0.2 else 0.3)
	motor.Parent = constraints

	local noHit = Instance.new("NoCollisionConstraint")
	noHit.Part0 = chassis
	noHit.Part1 = tire
	noHit.Parent = tire

	local rim = Instance.new("Part")
	rim.Name = name .. "Rim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.8, R * 1.28, R * 1.28)
	rim.CFrame = wheelCF
	rim.Color = Color3.fromRGB(154, 156, 160)
	rim.Material = Enum.Material.Metal
	rim.Reflectance = 0.4
	rim.Anchored = true
	rim.CanCollide = false
	rim.Massless = true
	rim.Parent = model
	smooth(rim)
	World.weld(tire, rim)

	for spoke = 0, 4 do
		local blade = Instance.new("Part")
		blade.Name = name .. "Spoke"
		blade.Size = Vector3.new(0.08, 0.1, R * 0.62)
		blade.CFrame = wheelCF * CFrame.Angles(math.rad(spoke * 72), 0, 0) * CFrame.new(0, R * 0.28, 0)
		blade.Color = Color3.fromRGB(186, 188, 192)
		blade.Material = Enum.Material.Metal
		blade.Reflectance = 0.28
		blade.Anchored = true
		blade.CanCollide = false
		blade.Massless = true
		blade.Parent = model
		smooth(blade)
		World.weld(tire, blade)
	end

	local outward = if x >= 0 then 1 else -1
	local cap = Instance.new("Part")
	cap.Name = name .. "Cap"
	cap.Shape = Enum.PartType.Cylinder
	cap.Size = Vector3.new(0.18, 0.46, 0.46)
	cap.CFrame = wheelCF * CFrame.new(outward * 0.34, 0, 0)
	cap.Color = Color3.fromRGB(46, 48, 52)
	cap.Material = Enum.Material.Metal
	cap.Reflectance = 0.2
	cap.Anchored = true
	cap.CanCollide = false
	cap.Massless = true
	cap.Parent = model
	smooth(cap)
	World.weld(tire, cap)

	-- Sidewall lip, slightly proud of the tread.
	local lip = Instance.new("Part")
	lip.Name = name .. "Sidewall"
	lip.Shape = Enum.PartType.Cylinder
	lip.Size = Vector3.new(0.7, R * 2.06, R * 2.06)
	lip.CFrame = wheelCF
	lip.Color = Color3.fromRGB(12, 12, 12)
	lip.Material = Enum.Material.SmoothPlastic
	lip.Reflectance = 0.01
	lip.Anchored = true
	lip.CanCollide = false
	lip.Massless = true
	lip.Parent = model
	smooth(lip)
	World.weld(tire, lip)
end

local function plate(model: Model, chassis: BasePart, pos: Vector3, face: Enum.NormalId)
	local board = panel(model, chassis, {
		name = "Plate",
		size = Vector3.new(1.35, 0.36, 0.06),
		pos = pos,
		color = Color3.fromRGB(232, 230, 222),
		material = Enum.Material.SmoothPlastic,
		massless = true,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = Vector2.new(200, 56)
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(232, 230, 222)
	text.TextColor3 = Color3.fromRGB(18, 18, 18)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = "ГАРАЖ"
	text.Parent = gui
end

function CarBuilder.applyTune(model: Model, build)
	local tune = Physics.derive(build)
	VehicleDriver.applyAttributes(model, tune)

	local chassis = model.PrimaryPart
	if not chassis then
		return tune
	end

	local wheelMass = math.max(2.2, tune.mass * 0.045)
	local wheelCount = 0
	for _, name in { "FL", "FR", "RL", "RR" } do
		local wheel = model:FindFirstChild(name)
		if wheel and wheel:IsA("BasePart") then
			wheelCount += 1
			local volume = wheel.Size.X * wheel.Size.Y * wheel.Size.Z
			local density = wheelMass / math.max(volume, 0.01)
			wheel.CustomPhysicalProperties = PhysicalProperties.new(density, tune.friction, 0.02, tune.frictionWeight, 0.15)
		end
	end

	local chassisMass = math.max(8, tune.mass - wheelMass * wheelCount)
	local volume = chassis.Size.X * chassis.Size.Y * chassis.Size.Z
	local density = chassisMass / math.max(volume, 0.01)
	chassis.CustomPhysicalProperties = PhysicalProperties.new(density, 0.35, 0.04, 0.4, 0.2)
	return tune
end

function CarBuilder.applyPaint(model: Model, colorIndex: number)
	World.paintModel(model, Config.paletteColor(colorIndex))
end

function CarBuilder.setParked(model: Model, parked: boolean)
	model:SetAttribute("Drive", not parked)
	local seat = model:FindFirstChild("Seat")
	if seat and seat:IsA("VehicleSeat") then
		seat.Disabled = parked
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = parked
		end
	end
	if not parked and model.PrimaryPart then
		model.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		model.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
	end
end

function CarBuilder.chassisCFrame(position: Vector3, lookTarget: Vector3): CFrame
	local flatLook = Vector3.new(lookTarget.X, position.Y, lookTarget.Z)
	return CFrame.lookAt(position, flatLook)
end

function CarBuilder.create(build): Model
	local model = Instance.new("Model")
	model.Name = "Sedan"

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(5.55, 0.62, 11.6)
	chassis.CFrame = CFrame.new(0, 0, 0)
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.Color = Config.paletteColor(build.color or 1)
	chassis.Reflectance = 0.08
	chassis.Anchored = true
	chassis.CanCollide = true
	chassis.Massless = false
	smooth(chassis)
	chassis:SetAttribute("Paint", true)
	chassis.Parent = model
	model.PrimaryPart = chassis

	local constraints = Instance.new("Folder")
	constraints.Name = "Constraints"
	constraints.Parent = model

	local paint = Color3.fromRGB(42, 46, 51)
	local metal = Color3.fromRGB(90, 92, 96)
	local glassColor = Color3.fromRGB(168, 186, 196)
	local lamp = Color3.fromRGB(236, 236, 228)
	local tail = Color3.fromRGB(140, 24, 22)
	local rubber = Color3.fromRGB(20, 20, 20)

	-- Shell. Offsets are in chassis space: -Z is the nose.
	local shell = {
		{ name = "FrontClip", size = Vector3.new(5.35, 0.48, 1.7), pos = Vector3.new(0, 0.02, -5.35), paint = true },
		{ name = "RearClip", size = Vector3.new(5.35, 0.5, 1.45), pos = Vector3.new(0, 0.04, 5.15), paint = true },
		{ name = "Hood", size = Vector3.new(5.15, 0.1, 3.15), pos = Vector3.new(0, 0.48, -3.55), rot = Vector3.new(7, 0, 0), paint = true },
		{ name = "Trunk", size = Vector3.new(4.9, 0.1, 2.15), pos = Vector3.new(0, 0.58, 3.95), rot = Vector3.new(8, 0, 0), paint = true },
		{ name = "Cabin", size = Vector3.new(4.7, 0.85, 4.15), pos = Vector3.new(0, 0.72, 0.15), paint = true },
		{ name = "Roof", size = Vector3.new(4.35, 0.12, 3.15), pos = Vector3.new(0, 1.48, 0.05), paint = true },
		{ name = "BumperF", size = Vector3.new(5.5, 0.38, 0.32), pos = Vector3.new(0, -0.12, -6.25), paint = true },
		{ name = "BumperR", size = Vector3.new(5.5, 0.38, 0.32), pos = Vector3.new(0, -0.1, 5.95), paint = true },
		{ name = "SkirtL", size = Vector3.new(0.16, 0.28, 9.2), pos = Vector3.new(-2.82, -0.22, -0.15), color = rubber, material = Enum.Material.SmoothPlastic },
		{ name = "SkirtR", size = Vector3.new(0.16, 0.28, 9.2), pos = Vector3.new(2.82, -0.22, -0.15), color = rubber, material = Enum.Material.SmoothPlastic },
		{ name = "FenderFL", size = Vector3.new(0.28, 0.72, 2.05), pos = Vector3.new(-2.78, 0.18, -3.85), paint = true },
		{ name = "FenderFR", size = Vector3.new(0.28, 0.72, 2.05), pos = Vector3.new(2.78, 0.18, -3.85), paint = true },
		{ name = "FenderRL", size = Vector3.new(0.28, 0.72, 2.05), pos = Vector3.new(-2.78, 0.18, 3.65), paint = true },
		{ name = "FenderRR", size = Vector3.new(0.28, 0.72, 2.05), pos = Vector3.new(2.78, 0.18, 3.65), paint = true },
		{ name = "Grille", size = Vector3.new(2.5, 0.42, 0.1), pos = Vector3.new(0, 0.12, -6.32), color = Color3.fromRGB(24, 24, 26), material = Enum.Material.Metal, reflectance = 0.15 },
		{ name = "GrilleSlat", size = Vector3.new(2.3, 0.06, 0.12), pos = Vector3.new(0, 0.22, -6.34), color = metal, material = Enum.Material.Metal, reflectance = 0.3 },
		{ name = "Trim", size = Vector3.new(5.7, 0.06, 0.08), pos = Vector3.new(0, 0.36, -2.2), color = metal, material = Enum.Material.Metal, reflectance = 0.35 },
		{ name = "Interior", size = Vector3.new(4.2, 0.45, 3.4), pos = Vector3.new(0, 0.55, 0.1), color = Color3.fromRGB(12, 12, 14), material = Enum.Material.Fabric },
	}

	for _, spec in shell do
		panel(model, chassis, {
			name = spec.name,
			size = spec.size,
			pos = spec.pos,
			rot = spec.rot,
			color = spec.color or paint,
			material = spec.material or Enum.Material.SmoothPlastic,
			reflectance = spec.reflectance or (if spec.paint then 0.14 else 0.04),
			paint = spec.paint,
			massless = true,
		})
	end

	local glass = {
		{ name = "Windshield", size = Vector3.new(4.55, 1.2, 0.08), pos = Vector3.new(0, 1.02, -1.72), rot = Vector3.new(28, 0, 0) },
		{ name = "RearGlass", size = Vector3.new(4.4, 1.05, 0.08), pos = Vector3.new(0, 1.08, 1.95), rot = Vector3.new(-32, 0, 0) },
		{ name = "WindowL", size = Vector3.new(0.07, 0.72, 2.15), pos = Vector3.new(-2.36, 1.02, 0.05), rot = Vector3.zero },
		{ name = "WindowR", size = Vector3.new(0.07, 0.72, 2.15), pos = Vector3.new(2.36, 1.02, 0.05), rot = Vector3.zero },
	}
	for _, spec in glass do
		panel(model, chassis, {
			name = spec.name,
			size = spec.size,
			pos = spec.pos,
			rot = spec.rot,
			color = glassColor,
			material = Enum.Material.Glass,
			transparency = 0.45,
			reflectance = 0.22,
			massless = true,
		})
	end

	local leftLamp = panel(model, chassis, {
		name = "HeadlampL",
		size = Vector3.new(1.2, 0.36, 0.12),
		pos = Vector3.new(-1.65, 0.18, -6.34),
		color = lamp,
		material = Enum.Material.Glass,
		transparency = 0.2,
		reflectance = 0.35,
		massless = true,
	})
	local rightLamp = panel(model, chassis, {
		name = "HeadlampR",
		size = Vector3.new(1.2, 0.36, 0.12),
		pos = Vector3.new(1.65, 0.18, -6.34),
		color = lamp,
		material = Enum.Material.Glass,
		transparency = 0.2,
		reflectance = 0.35,
		massless = true,
	})
	for _, lampPart in { leftLamp, rightLamp } do
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Angle = 52
		spot.Range = 34
		spot.Brightness = 1.3
		spot.Color = Color3.fromRGB(255, 244, 224)
		spot.Shadows = true
		spot.Parent = lampPart
	end

	for _, side in { -1, 1 } do
		local lens = panel(model, chassis, {
			name = if side < 0 then "TailL" else "TailR",
			size = Vector3.new(1.15, 0.32, 0.1),
			pos = Vector3.new(side * 1.75, 0.28, 6.08),
			color = tail,
			material = Enum.Material.Glass,
			transparency = 0.15,
			reflectance = 0.25,
			massless = true,
		})
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(180, 30, 24)
		glow.Range = 7
		glow.Brightness = 0.45
		glow.Parent = lens
	end

	panel(model, chassis, {
		name = "MirrorL",
		size = Vector3.new(0.12, 0.28, 0.55),
		pos = Vector3.new(-2.65, 0.78, -1.15),
		paint = true,
		reflectance = 0.12,
		massless = true,
	})
	panel(model, chassis, {
		name = "MirrorR",
		size = Vector3.new(0.12, 0.28, 0.55),
		pos = Vector3.new(2.65, 0.78, -1.15),
		paint = true,
		reflectance = 0.12,
		massless = true,
	})

	for _, side in { -1, 1 } do
		panel(model, chassis, {
			name = "Exhaust",
			size = Vector3.new(0.55, 0.22, 0.22),
			pos = Vector3.new(side * 0.7, -0.28, 6.2),
			rot = Vector3.new(0, 90, 0),
			color = Color3.fromRGB(70, 68, 64),
			material = Enum.Material.Metal,
			reflectance = 0.25,
			shape = "cylinder",
			massless = true,
		})
	end

	plate(model, chassis, Vector3.new(0, -0.08, 6.14), Enum.NormalId.Back)
	plate(model, chassis, Vector3.new(0, -0.08, -6.42), Enum.NormalId.Front)

	addWheel(model, chassis, constraints, "FL", -2.72, -3.85, true)
	addWheel(model, chassis, constraints, "FR", 2.72, -3.85, true)
	addWheel(model, chassis, constraints, "RL", -2.72, 3.7, false)
	addWheel(model, chassis, constraints, "RR", 2.72, 3.7, false)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(1.4, 0.3, 1.4)
	seat.CFrame = chassis.CFrame * CFrame.new(-0.55, 0.62, 0.15)
	seat.Anchored = true
	seat.CanCollide = false
	seat.Massless = true
	seat.Transparency = 1
	seat.Disabled = true
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.HeadsUpDisplay = false
	seat.Parent = model
	smooth(seat)
	World.weld(chassis, seat)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SitPrompt"
	prompt.ActionText = "Сесть"
	prompt.ObjectText = "Седан"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = chassis

	CarBuilder.applyTune(model, build)
	CarBuilder.applyPaint(model, build.color or 1)
	model:SetAttribute("Drive", false)
	return model
end

function CarBuilder.spawn(build, chassisCFrame: CFrame, parked: boolean): Model
	local model = CarBuilder.create(build)
	model:PivotTo(chassisCFrame)
	CarBuilder.setParked(model, parked)
	return model
end

return CarBuilder
