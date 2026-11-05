-- Private bay: concrete shell, window light, a lift, a workbench.
-- The car slot is on the floor in front of the lift, nose toward the open door.

local Config = require(script.Parent.Config)
local World = require(script.Parent.World)

local GarageBuilder = {}

local CONCRETE = Color3.fromRGB(158, 156, 150)
local CONCRETE_DARK = Color3.fromRGB(124, 122, 116)
local METAL = Color3.fromRGB(118, 120, 124)
local ASPHALT = Color3.fromRGB(62, 62, 64)
local WOOD = Color3.fromRGB(92, 70, 48)

local function at(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

function GarageBuilder.build(origin: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Garage"

	local pivot = World.part(model, {
		name = "Pivot",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new(0, 0, 0),
		transparency = 1,
		collide = false,
		shadow = false,
	})
	pivot.CanQuery = false
	model.PrimaryPart = pivot

	-- Floor and the apron outside the open door (+Z).
	local floor = World.part(model, {
		name = "Floor",
		size = Vector3.new(30, 1, 44),
		cframe = at(0, -0.5, 2),
		color = Color3.fromRGB(92, 90, 86),
		material = Enum.Material.DiamondPlate,
	})
	World.tile(floor, "rbxassetid://7547337977", Enum.NormalId.Top, 8)
	local apron = World.part(model, {
		name = "Apron",
		size = Vector3.new(30, 1, 24),
		cframe = at(0, -0.55, 36),
		color = ASPHALT,
		material = Enum.Material.Asphalt,
	})
	World.tile(apron, "rbxassetid://7551987784", Enum.NormalId.Top, 14)
	-- Threshold strip where concrete meets asphalt.
	World.part(model, {
		name = "Threshold",
		size = Vector3.new(30, 0.08, 0.4),
		cframe = at(0, 0.02, 24),
		color = Color3.fromRGB(96, 96, 98),
		material = Enum.Material.DiamondPlate,
		collide = false,
	})

	-- Shell. Open front. Back wall is split so the windows are real openings.
	local wallLeft = World.part(model, {
		name = "WallLeft",
		size = Vector3.new(0.7, 10, 40),
		cframe = at(-15.35, 5, 0),
		color = CONCRETE_DARK,
		material = Enum.Material.Concrete,
	})
	World.tile(wallLeft, "rbxassetid://7547630026", Enum.NormalId.Right, 8)
	local wallRight = World.part(model, {
		name = "WallRight",
		size = Vector3.new(0.7, 10, 40),
		cframe = at(15.35, 5, 0),
		color = CONCRETE_DARK,
		material = Enum.Material.Concrete,
	})
	World.tile(wallRight, "rbxassetid://7547630026", Enum.NormalId.Left, 8)
	local wallBack = World.part(model, {
		name = "WallBackLow",
		size = Vector3.new(30, 3.4, 0.7),
		cframe = at(0, 1.7, -20.35),
		color = CONCRETE_DARK,
		material = Enum.Material.Concrete,
	})
	World.tile(wallBack, "rbxassetid://7547630026", Enum.NormalId.Back, 8)
	World.part(model, {
		name = "WallCapL",
		size = Vector3.new(0.9, 0.28, 40),
		cframe = at(-15.35, 10.05, 0),
		color = Color3.fromRGB(118, 122, 128),
		material = Enum.Material.DiamondPlate,
		reflectance = 0.22,
	})
	World.part(model, {
		name = "WallCapR",
		size = Vector3.new(0.9, 0.28, 40),
		cframe = at(15.35, 10.05, 0),
		color = Color3.fromRGB(118, 122, 128),
		material = Enum.Material.DiamondPlate,
		reflectance = 0.22,
	})
	World.part(model, {
		name = "WallBackHigh",
		size = Vector3.new(30, 2.2, 0.7),
		cframe = at(0, 8.9, -20.35),
		color = CONCRETE_DARK,
		material = Enum.Material.Concrete,
	})

	local cursor = -15
	local bands = {
		{ 2.6, false },
		{ 6.4, true },
		{ 2.2, false },
		{ 6.4, true },
		{ 2.2, false },
		{ 6.4, true },
		{ 3.8, false },
	}
	for _, band in bands do
		local width = band[1]
		local glass = band[2]
		local center = cursor + width * 0.5
		cursor += width
		if glass then
			local pane = World.part(model, {
				name = "Window",
				size = Vector3.new(width - 0.3, 4.2, 0.16),
				cframe = at(center, 5.6, -20.35),
				color = Color3.fromRGB(186, 198, 206),
				material = Enum.Material.Glass,
				transparency = 0.35,
				reflectance = 0.12,
				collide = false,
			})
			local fill = Instance.new("SpotLight")
			fill.Name = "WindowLight"
			fill.Face = Enum.NormalId.Back
			fill.Angle = 70
			fill.Range = 22
			fill.Brightness = 0.55
			fill.Color = Color3.fromRGB(214, 224, 232)
			fill.Shadows = false
			fill.Parent = pane
		else
			World.part(model, {
				name = "Pier",
				size = Vector3.new(width, 4.4, 0.7),
				cframe = at(center, 5.6, -20.35),
				color = CONCRETE_DARK,
				material = Enum.Material.Concrete,
			})
		end
	end

	World.part(model, {
		name = "RoofLeft",
		size = Vector3.new(11, 0.4, 40),
		cframe = at(-9.5, 10.2, 0),
		color = CONCRETE,
		material = Enum.Material.Concrete,
	})
	World.part(model, {
		name = "RoofRight",
		size = Vector3.new(11, 0.4, 40),
		cframe = at(9.5, 10.2, 0),
		color = CONCRETE,
		material = Enum.Material.Concrete,
	})
	local skylight = World.part(model, {
		name = "Skylight",
		size = Vector3.new(7.4, 0.12, 18),
		cframe = at(0, 10.22, -1),
		color = Color3.fromRGB(198, 208, 214),
		material = Enum.Material.Glass,
		transparency = 0.32,
		reflectance = 0.08,
	})
	local sky = Instance.new("SpotLight")
	sky.Name = "WindowLight"
	sky.Face = Enum.NormalId.Bottom
	sky.Angle = 90
	sky.Range = 28
	sky.Brightness = 0.7
	sky.Color = Color3.fromRGB(232, 236, 240)
	sky.Shadows = true
	sky.Parent = skylight

	-- Two-post lift behind the car. The car stays on the floor.
	local steel = Color3.fromRGB(72, 76, 82)
	local chrome = Color3.fromRGB(186, 190, 196)
	local function post(name: string, x: number)
		local column = World.part(model, {
			name = name,
			size = Vector3.new(0.55, 7.4, 0.55),
			cframe = at(x, 3.7, -17.2),
			color = steel,
			material = Enum.Material.DiamondPlate,
			reflectance = 0.18,
		})
		World.part(model, {
			name = name .. "Base",
			size = Vector3.new(1.3, 0.18, 1.3),
			cframe = at(x, 0.1, -17.2),
			color = steel,
			material = Enum.Material.Metal,
			reflectance = 0.25,
		})
		World.part(model, {
			name = name .. "Stripe",
			size = Vector3.new(0.58, 0.35, 0.58),
			cframe = at(x, 1.4, -17.2),
			color = Color3.fromRGB(214, 168, 42),
			material = Enum.Material.Metal,
			reflectance = 0.2,
		})
		return column
	end
	post("LiftPostL", -4.4)
	post("LiftPostR", 4.4)
	World.part(model, {
		name = "LiftBeam",
		size = Vector3.new(9.6, 0.4, 0.5),
		cframe = at(0, 7.35, -17.2),
		color = steel,
		material = Enum.Material.DiamondPlate,
		reflectance = 0.16,
	})
	World.part(model, {
		name = "LiftRam",
		size = Vector3.new(5.2, 0.42, 0.42),
		cframe = at(0, 3.1, -17.2, 0, 0, 90),
		color = Color3.fromRGB(48, 50, 54),
		material = Enum.Material.Metal,
		reflectance = 0.35,
		shape = "cylinder",
	})
	World.part(model, {
		name = "LiftPiston",
		size = Vector3.new(3.2, 0.22, 0.22),
		cframe = at(0, 4.4, -17.2, 0, 0, 90),
		color = chrome,
		material = Enum.Material.Metal,
		reflectance = 0.55,
		shape = "cylinder",
	})
	for _, x in { -2.2, 2.2 } do
		World.part(model, {
			name = "LiftArm",
			size = Vector3.new(0.35, 0.22, 3.6),
			cframe = at(x, 1.35, -15.3),
			color = steel,
			material = Enum.Material.Metal,
			reflectance = 0.28,
		})
		World.part(model, {
			name = "LiftPad",
			size = Vector3.new(0.7, 0.12, 0.7),
			cframe = at(x, 1.15, -13.6),
			color = Color3.fromRGB(196, 154, 36),
			material = Enum.Material.Metal,
			reflectance = 0.2,
		})
	end
	local carriage = World.part(model, {
		name = "LiftCarriage",
		size = Vector3.new(8.4, 0.2, 2.4),
		cframe = at(0, 1.55, -17.2),
		color = Color3.fromRGB(90, 94, 100),
		material = Enum.Material.DiamondPlate,
		reflectance = 0.22,
	})
	carriage.Reflectance = 0.22

	-- Workbench on the right wall.
	World.part(model, {
		name = "BenchTop",
		size = Vector3.new(2.1, 0.16, 6.4),
		cframe = at(13.4, 3.15, -1),
		color = WOOD,
		material = Enum.Material.WoodPlanks,
	})
	for _, z in { -3.6, 1.6 } do
		World.part(model, {
			name = "BenchLeg",
			size = Vector3.new(0.28, 3.05, 0.28),
			cframe = at(12.6, 1.52, z),
			color = METAL,
			material = Enum.Material.Metal,
		})
		World.part(model, {
			name = "BenchLeg",
			size = Vector3.new(0.28, 3.05, 0.28),
			cframe = at(14.2, 1.52, z),
			color = METAL,
			material = Enum.Material.Metal,
		})
	end
	World.part(model, {
		name = "Vise",
		size = Vector3.new(0.7, 0.4, 0.45),
		cframe = at(13.5, 3.42, 1.4),
		color = Color3.fromRGB(78, 80, 84),
		material = Enum.Material.Metal,
		reflectance = 0.18,
	})
	World.part(model, {
		name = "Wrench",
		size = Vector3.new(0.12, 0.12, 1.4),
		cframe = at(13.2, 3.32, -1.2) * CFrame.Angles(0, math.rad(20), math.rad(90)),
		color = Color3.fromRGB(150, 150, 148),
		material = Enum.Material.Metal,
		collide = false,
	})
	World.part(model, {
		name = "Jack",
		size = Vector3.new(0.8, 0.35, 0.5),
		cframe = at(13.6, 3.4, -2.6),
		color = Color3.fromRGB(150, 48, 36),
		material = Enum.Material.DiamondPlate,
		collide = false,
	})
	local lampArm = World.part(model, {
		name = "BenchLamp",
		size = Vector3.new(0.4, 0.15, 1.2),
		cframe = at(13.2, 5.4, -1),
		color = Color3.fromRGB(40, 40, 42),
		material = Enum.Material.Metal,
	})
	local warm = Instance.new("SpotLight")
	warm.Face = Enum.NormalId.Bottom
	warm.Angle = 60
	warm.Range = 14
	warm.Brightness = 1.6
	warm.Color = Color3.fromRGB(255, 214, 160)
	warm.Shadows = true
	warm.Parent = lampArm

	local slot = World.part(model, {
		name = "CarSlot",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.lookAt(Vector3.new(0, Config.CHASSIS_Y + 0.05, 62), Vector3.new(0, Config.CHASSIS_Y + 0.05, 100)),
		transparency = 1,
		collide = false,
		shadow = false,
	})
	slot.CanQuery = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(6, 0.3, 6)
	spawn.CFrame = CFrame.lookAt(Vector3.new(7, 0.2, 62), Vector3.new(0, 0.2, 62))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Parent = model

	local pedestal = World.part(model, {
		name = "ExitPedestal",
		size = Vector3.new(1.4, 3.1, 1.4),
		cframe = at(8.5, 1.55, 13.5),
		color = Color3.fromRGB(72, 74, 78),
		material = Enum.Material.DiamondPlate,
		reflectance = 0.08,
	})
	local button = World.part(model, {
		name = "ExitButton",
		size = Vector3.new(0.9, 0.28, 0.9),
		cframe = at(8.5, 3.2, 13.5),
		color = Color3.fromRGB(214, 168, 72),
		material = Enum.Material.Metal,
		reflectance = 0.12,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LeavePrompt"
	prompt.ActionText = "Выехать"
	prompt.ObjectText = "Полигон"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	local sign = Instance.new("SurfaceGui")
	sign.Face = Enum.NormalId.Back
	sign.CanvasSize = Vector2.new(200, 80)
	sign.Parent = pedestal
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Font = Enum.Font.GothamBold
	signText.TextColor3 = Color3.fromRGB(236, 232, 220)
	signText.TextScaled = true
	signText.Text = "ВЫЕХАТЬ"
	signText.Parent = sign

	local road = World.part(model, {
		name = "Street",
		size = Vector3.new(22, 1, 170),
		cframe = at(0, -0.52, 110),
		color = ASPHALT,
		material = Enum.Material.Asphalt,
	})
	World.tile(road, "rbxassetid://7551987784", Enum.NormalId.Top, 14)
	for z = 28, 180, 10 do
		World.part(model, {
			name = "LaneDash",
			size = Vector3.new(0.35, 0.06, 4),
			cframe = at(0, 0.04, z),
			color = Color3.fromRGB(230, 228, 216),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			shadow = false,
		})
	end
	for _, side in { -1, 1 } do
		local walk = World.part(model, {
			name = "Sidewalk",
			size = Vector3.new(6, 1.05, 170),
			cframe = at(side * 16, -0.42, 110),
			color = Color3.fromRGB(138, 136, 130),
			material = Enum.Material.Concrete,
		})
		World.tile(walk, "rbxassetid://7547337977", Enum.NormalId.Top, 6)
		World.part(model, {
			name = "Curb",
			size = Vector3.new(0.7, 0.28, 170),
			cframe = at(side * 12.6, 0.12, 110),
			color = Color3.fromRGB(210, 208, 200),
			material = Enum.Material.Concrete,
		})
	end

	for i = -5, 5 do
		World.part(model, {
			name = "Crosswalk",
			size = Vector3.new(1.15, 0.05, 8),
			cframe = at(i * 1.7, 0.05, 40),
			color = Color3.fromRGB(236, 234, 226),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			shadow = false,
		})
	end
	for _, side in { -1, 1 } do
		World.part(model, {
			name = "LaneEdge",
			size = Vector3.new(0.22, 0.05, 160),
			cframe = at(side * 9.2, 0.05, 115),
			color = Color3.fromRGB(232, 230, 220),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			shadow = false,
		})
	end

	local function shop(index: number, spec)
		local face = if spec.x > 0 then -1 else 1
		local body = World.part(model, {
			name = "Building" .. tostring(index),
			size = Vector3.new(spec.w, spec.h, spec.d),
			cframe = at(spec.x, spec.h * 0.5, spec.z),
			color = spec.color,
			material = spec.material,
		})
		if spec.brickTex then
			World.tile(body, "rbxassetid://7547630026", if face < 0 then Enum.NormalId.Left else Enum.NormalId.Right, 6)
		end
		World.part(model, {
			name = "Cornice" .. tostring(index),
			size = Vector3.new(spec.w + 0.8, 0.45, spec.d + 0.8),
			cframe = at(spec.x, spec.h - 0.2, spec.z),
			color = Color3.fromRGB(86, 88, 92),
			material = Enum.Material.Concrete,
		})
		World.part(model, {
			name = "Roof" .. tostring(index),
			size = Vector3.new(spec.w + spec.over, spec.roofH, spec.d + spec.over),
			cframe = at(spec.x, spec.h + spec.roofH * 0.5, spec.z),
			color = spec.roofColor,
			material = spec.roofMat,
			reflectance = 0.18,
		})
		local doorX = spec.x + face * (spec.w * 0.5 + 0.08)
		World.part(model, {
			name = "Door" .. tostring(index),
			size = Vector3.new(0.25, 3.4, 2.2),
			cframe = at(doorX, 1.7, spec.z - spec.d * 0.18),
			color = Color3.fromRGB(58, 46, 38),
			material = Enum.Material.Wood,
		})
		local floors = math.clamp(math.floor((spec.h - 4) / 3.6), 1, 6)
		for level = 1, floors do
			local y = 4.2 + (level - 1) * 3.5
			for pane = -1, 1 do
				local glass = World.part(model, {
					name = "Pane",
					size = Vector3.new(0.16, 1.7, 1.5),
					cframe = at(doorX, y, spec.z + pane * 2.3),
					color = Color3.fromRGB(186, 214, 224),
					material = Enum.Material.Glass,
					transparency = 0.28,
					reflectance = 0.22,
					collide = false,
				})
				if level == floors and pane == 0 then
					local lamp = Instance.new("PointLight")
					lamp.Color = Color3.fromRGB(255, 220, 180)
					lamp.Range = 12
					lamp.Brightness = 0.45
					lamp.Parent = glass
				end
			end
		end
	end

	local block = {
		{ x = -28, z = 48, w = 14, d = 16, h = 11, color = Color3.fromRGB(140, 78, 64), material = Enum.Material.Brick, roofH = 0.5, over = 1.4, roofColor = Color3.fromRGB(92, 58, 48), roofMat = Enum.Material.Brick, brickTex = false },
		{ x = -31, z = 74, w = 16, d = 18, h = 22, color = Color3.fromRGB(168, 164, 156), material = Enum.Material.Concrete, roofH = 1.2, over = 0.6, roofColor = Color3.fromRGB(70, 74, 80), roofMat = Enum.Material.Metal, brickTex = true },
		{ x = -27, z = 102, w = 12, d = 20, h = 8, color = Color3.fromRGB(118, 92, 74), material = Enum.Material.Brick, roofH = 0.4, over = 2, roofColor = Color3.fromRGB(64, 68, 72), roofMat = Enum.Material.DiamondPlate, brickTex = false },
		{ x = -30, z = 132, w = 18, d = 14, h = 30, color = Color3.fromRGB(96, 108, 118), material = Enum.Material.Concrete, roofH = 0.8, over = 0.4, roofColor = Color3.fromRGB(40, 44, 48), roofMat = Enum.Material.Metal, brickTex = true },
		{ x = 28, z = 44, w = 15, d = 17, h = 16, color = Color3.fromRGB(150, 146, 138), material = Enum.Material.Concrete, roofH = 0.6, over = 1, roofColor = Color3.fromRGB(82, 86, 90), roofMat = Enum.Material.Metal, brickTex = true },
		{ x = 32, z = 72, w = 13, d = 22, h = 9, color = Color3.fromRGB(126, 70, 58), material = Enum.Material.Brick, roofH = 1.6, over = 1.8, roofColor = Color3.fromRGB(110, 72, 52), roofMat = Enum.Material.Wood, brickTex = false },
		{ x = 27, z = 104, w = 18, d = 15, h = 26, color = Color3.fromRGB(176, 172, 164), material = Enum.Material.Concrete, roofH = 0.45, over = 0.5, roofColor = Color3.fromRGB(58, 62, 68), roofMat = Enum.Material.DiamondPlate, brickTex = false },
		{ x = 30, z = 136, w = 14, d = 18, h = 13, color = Color3.fromRGB(104, 98, 92), material = Enum.Material.Brick, roofH = 0.7, over = 1.2, roofColor = Color3.fromRGB(74, 78, 84), roofMat = Enum.Material.Metal, brickTex = false },
	}
	for index, spec in block do
		shop(index, spec)
	end

	for _, z in { 34, 62, 90, 118, 146 } do
		for _, side in { -1, 1 } do
			World.part(model, {
				name = "LampPole",
				size = Vector3.new(0.35, 8, 0.35),
				cframe = at(side * 14.4, 4, z),
				color = Color3.fromRGB(48, 50, 54),
				material = Enum.Material.Metal,
				reflectance = 0.2,
			})
			local head = World.part(model, {
				name = "LampHead",
				size = Vector3.new(1.4, 0.28, 0.7),
				cframe = at(side * 14.4, 8.1, z),
				color = Color3.fromRGB(226, 220, 196),
				material = Enum.Material.Glass,
				transparency = 0.15,
				collide = false,
			})
			local streetLight = Instance.new("PointLight")
			streetLight.Color = Color3.fromRGB(255, 226, 186)
			streetLight.Range = 28
			streetLight.Brightness = 1.1
			streetLight.Parent = head
		end
	end

	World.part(model, {
		name = "Shelf",
		size = Vector3.new(1.2, 4.2, 8),
		cframe = at(-13.2, 2.1, -2),
		color = Color3.fromRGB(62, 64, 68),
		material = Enum.Material.Metal,
		reflectance = 0.12,
	})
	for _, z in { -4.6, -2, 0.6 } do
		World.part(model, {
			name = "Crate",
			size = Vector3.new(0.9, 0.7, 0.9),
			cframe = at(-13.2, 4.5, z),
			color = Color3.fromRGB(112, 78, 48),
			material = Enum.Material.Wood,
		})
	end
	local bayLight = World.part(model, {
		name = "BayLamp",
		size = Vector3.new(6, 0.2, 1.2),
		cframe = at(0, 8.6, 2),
		color = Color3.fromRGB(236, 230, 210),
		material = Enum.Material.Glass,
		transparency = 0.1,
		collide = false,
	})
	local bayGlow = Instance.new("SpotLight")
	bayGlow.Face = Enum.NormalId.Bottom
	bayGlow.Angle = 80
	bayGlow.Range = 24
	bayGlow.Brightness = 1.5
	bayGlow.Color = Color3.fromRGB(255, 236, 210)
	bayGlow.Shadows = true
	bayGlow.Parent = bayLight

	model:PivotTo(origin)
	local carriage = model:FindFirstChild("LiftCarriage")
	if carriage and carriage:IsA("BasePart") then
		carriage:SetAttribute("RestY", carriage.Position.Y)
	end
	return model
end

return GarageBuilder
