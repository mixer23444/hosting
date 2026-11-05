-- Official Roblox sedan (public model 6418239833): painted body, glass, lamps, wheels.
-- The chassis and collision tires stay invisible. No neon brick body.

local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")

local Config = require(script.Parent.Config)
local Physics = require(script.Parent.Physics)
local World = require(script.Parent.World)
local VehicleDriver = require(script.Parent.VehicleDriver)
local SedanMesh = require(script.Parent.SedanMesh)

local SEDAN_MODEL = 6418239833

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
	tire.Transparency = 1
	tire.Reflectance = 0
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
end

local WHEEL_NAME = {
	LF_wheel = "FL",
	LF_wheel_trim = "FL",
	RF_wheel = "FR",
	RF_wheel_trim = "FR",
	LR_wheel = "RL",
	LR_wheel_trim = "RL",
	RR_wheel = "RR",
	RR_wheel_trim = "RR",
}

local function paintableName(name: string): boolean
	if string.find(name, "glass", 1, true) then
		return false
	end
	if string.find(name, "light", 1, true) or string.find(name, "wheel", 1, true) then
		return false
	end
	if name == "tire" or name == "grill" or name == "interior" or string.find(name, "trim", 1, true) then
		return false
	end
	if string.find(name, "_int", 1, true) then
		return false
	end
	return true
end

local function hostFor(model: Model, partName: string, position: Vector3): BasePart?
	local mapped = WHEEL_NAME[partName]
	if mapped then
		local wheel = model:FindFirstChild(mapped)
		if wheel and wheel:IsA("BasePart") then
			return wheel
		end
	end
	if partName == "tire" or string.find(partName, "wheel", 1, true) then
		local best: BasePart? = nil
		local bestDistance = 1e9
		for _, id in { "FL", "FR", "RL", "RR" } do
			local wheel = model:FindFirstChild(id)
			if wheel and wheel:IsA("BasePart") then
				local distance = (wheel.Position - position).Magnitude
				if distance < bestDistance then
					best = wheel
					bestDistance = distance
				end
			end
		end
		return best
	end
	return nil
end

local function finishVisual(model: Model, chassis: BasePart, part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.Massless = true
	part.CastShadow = true
	if part.Material == Enum.Material.Neon then
		part.Material = Enum.Material.Glass
	end
	if part.Name == "tire" then
		part.Color = Color3.fromRGB(18, 18, 18)
		part.Material = Enum.Material.SmoothPlastic
		part.Reflectance = 0.02
	end
	if paintableName(part.Name) then
		part:SetAttribute("Paint", true)
		part.Material = Enum.Material.SmoothPlastic
		part.Reflectance = 0.16
	elseif string.find(part.Name, "glass", 1, true) then
		part.Material = Enum.Material.Glass
		part.Reflectance = 0.2
	elseif part.Name == "light_white" then
		part.Material = Enum.Material.Glass
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Angle = 50
		spot.Range = 36
		spot.Brightness = 1.4
		spot.Color = Color3.fromRGB(255, 244, 224)
		spot.Shadows = true
		spot.Parent = part
	elseif string.find(part.Name, "light", 1, true) then
		part.Material = Enum.Material.Glass
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(180, 36, 28)
		glow.Range = 8
		glow.Brightness = 0.5
		glow.Parent = part
	end
	for _, child in part:GetDescendants() do
		if child:IsA("LuaSourceContainer") then
			child:Destroy()
		end
	end
	part.Parent = model
	local host = hostFor(model, part.Name, part.Position) or chassis
	World.weld(host, part)
end

local function attachLoaded(model: Model, chassis: BasePart, source: Instance): boolean
	local points = {}
	for _, descendant in source:GetDescendants() do
		if descendant:IsA("BasePart") and WHEEL_NAME[descendant.Name] and string.sub(descendant.Name, -6) == "_wheel" then
			table.insert(points, descendant.Position)
		end
	end
	if #points ~= 4 then
		return false
	end
	local sum = Vector3.zero
	for _, point in points do
		sum += point
	end
	local ref = CFrame.new(sum / #points)
	local shift = CFrame.new(0, R - Config.CHASSIS_Y, 0)
	local count = 0
	for _, descendant in source:GetDescendants() do
		if descendant:IsA("MeshPart") then
			local clone = descendant:Clone()
			clone.CFrame = shift * ref:Inverse() * descendant.CFrame
			finishVisual(model, chassis, clone)
			count += 1
		end
	end
	return count > 8
end

local function tryCatalogMesh(model: Model, chassis: BasePart): boolean
	local ok, container = pcall(function()
		return InsertService:LoadAsset(SEDAN_MODEL)
	end)
	if not ok or typeof(container) ~= "Instance" then
		return false
	end
	local source = nil
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("Model") and string.find(string.lower(descendant.Name), "white", 1, true) then
			source = descendant
			break
		end
	end
	if not source then
		for _, descendant in container:GetDescendants() do
			if descendant.Name == "LF_wheel" then
				local current = descendant.Parent
				while current and current ~= container do
					local count = 0
					for _, child in current:GetDescendants() do
						if child.Name == "LF_wheel" then
							count += 1
						end
					end
					if count == 1 then
						source = current
						break
					end
					current = current.Parent
				end
				break
			end
		end
	end
	local loaded = false
	if source then
		loaded = attachLoaded(model, chassis, source)
	end
	container:Destroy()
	return loaded
end

local function meshFromId(meshId: string, textureId: string): BasePart
	local uri = "rbxassetid://" .. meshId
	local content = nil
	pcall(function()
		content = Content.fromUri(uri)
	end)
	if content ~= nil then
		local ok, created = pcall(function()
			return AssetService:CreateMeshPartAsync(content)
		end)
		if ok and typeof(created) == "Instance" and created:IsA("BasePart") then
			return created
		end
	end
	local part = Instance.new("Part")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = uri
	if textureId ~= "" then
		mesh.TextureId = "rbxassetid://" .. textureId
	end
	mesh.Parent = part
	return part
end

local function attachFallback(model: Model, chassis: BasePart)
	for _, spec in SedanMesh.PARTS do
		local part = meshFromId(spec.mesh, spec.tex)
		part.Name = spec.name
		if part:IsA("MeshPart") then
			part.Size = Vector3.new(spec.size[1], spec.size[2], spec.size[3])
		else
			-- FileMesh draws at its own size. A failed mesh stays a speck, not a brick.
			part.Size = Vector3.new(0.2, 0.2, 0.2)
		end
		local c = spec.cf
		part.CFrame = CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
		part.Color = Color3.fromRGB(spec.color[1], spec.color[2], spec.color[3])
		part.Transparency = spec.trans
		if spec.kind == "glass" then
			part.Material = Enum.Material.Glass
		elseif spec.kind == "metal" then
			part.Material = Enum.Material.Metal
			part.Reflectance = 0.3
		elseif spec.kind == "wheel" then
			part.Material = if spec.name == "tire" then Enum.Material.SmoothPlastic else Enum.Material.Metal
		else
			part.Material = Enum.Material.SmoothPlastic
		end
		finishVisual(model, chassis, part)
	end
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
	chassis.Size = Vector3.new(6.2, 0.5, 14.2)
	chassis.CFrame = CFrame.new(0, 0, 0)
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.Color = Color3.fromRGB(30, 30, 32)
	chassis.Transparency = 1
	chassis.Reflectance = 0
	chassis.Anchored = true
	chassis.CanCollide = true
	chassis.Massless = false
	chassis.CastShadow = false
	smooth(chassis)
	chassis.Parent = model
	model.PrimaryPart = chassis

	local constraints = Instance.new("Folder")
	constraints.Name = "Constraints"
	constraints.Parent = model

	-- Collision tires sit on the sedan mesh wheel centers. Nose is -Z.
	addWheel(model, chassis, constraints, "FL", -3.447, -6.181, true)
	addWheel(model, chassis, constraints, "FR", 3.447, -6.181, true)
	addWheel(model, chassis, constraints, "RL", -3.732, 6.181, false)
	addWheel(model, chassis, constraints, "RR", 3.733, 6.181, false)

	-- Public Roblox sedan (model 6418239833). Mesh ids are the fallback when LoadAsset cannot run.
	if not tryCatalogMesh(model, chassis) then
		attachFallback(model, chassis)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(1.4, 0.3, 1.4)
	seat.CFrame = chassis.CFrame * CFrame.new(-0.55, 1.05, -1.0)
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
