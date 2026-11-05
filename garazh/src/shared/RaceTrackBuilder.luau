-- Closed circuit for a 3-lap friends race. Grid holds the host plus four friends.

local Config = require(script.Parent.Config)
local TrackMesh = require(script.Parent.TrackMesh)
local World = require(script.Parent.World)

local RaceTrackBuilder = {}

local WIDTH = 26
local LENGTH = 180
local RADIUS = 34
local START_POINT = 6

function RaceTrackBuilder.build(origin: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "RaceTrack"

	local pivot = World.part(model, {
		name = "Pivot",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new(),
		transparency = 1,
		collide = false,
		shadow = false,
	})
	pivot.CanQuery = false
	model.PrimaryPart = pivot

	local points = TrackMesh.stadium(LENGTH, RADIUS)
	TrackMesh.ground(model, Vector3.new(RADIUS, 0, LENGTH * 0.5), Vector3.new(1200, 8, 1200))
	TrackMesh.lay(model, points, WIDTH)

	-- Eight gates around the short loop. Gate 1 is the start/finish, mid-straight.
	local gateAt = { START_POINT, 10, 14, 18, 22, 26, 30, 35 }
	for index, pointIndex in gateAt do
		if pointIndex < #points then
			TrackMesh.gate(model, index, points, pointIndex, WIDTH)
		end
	end

	local lineZ = points[START_POINT].Z
	-- Two-wide grid on the asphalt behind the line. The sedan is about 20 studs long.
	local lateral = { -6, 6, -6, 6, 0 }
	local along = { lineZ - 50, lineZ - 50, lineZ - 26, lineZ - 26, lineZ - 74 }
	for index = 1, 5 do
		local slot = World.part(model, {
			name = "Grid" .. tostring(index),
			size = Vector3.new(1, 1, 1),
			cframe = CFrame.lookAt(
				Vector3.new(lateral[index], Config.CHASSIS_Y + 0.7, along[index]),
				Vector3.new(lateral[index], Config.CHASSIS_Y + 0.7, along[index] + 40)
			),
			transparency = 1,
			collide = false,
			shadow = false,
		})
		slot.CanQuery = false
		slot:SetAttribute("Grid", index)
	end

	-- Start gantry. Lamps are glass, not neon bricks.
	World.part(model, {
		name = "GantryLeft",
		size = Vector3.new(1.1, 10, 1.1),
		cframe = CFrame.new(-WIDTH * 0.5 - 1, 5, lineZ),
		color = Color3.fromRGB(120, 120, 118),
		material = Enum.Material.Metal,
	})
	World.part(model, {
		name = "GantryRight",
		size = Vector3.new(1.1, 10, 1.1),
		cframe = CFrame.new(WIDTH * 0.5 + 1, 5, lineZ),
		color = Color3.fromRGB(120, 120, 118),
		material = Enum.Material.Metal,
	})
	World.part(model, {
		name = "GantryBeam",
		size = Vector3.new(WIDTH + 4, 0.6, 1.2),
		cframe = CFrame.new(0, 10.2, lineZ),
		color = Color3.fromRGB(96, 98, 102),
		material = Enum.Material.DiamondPlate,
	})
	for index, x in { -6, 0, 6 } do
		local lamp = World.part(model, {
			name = "StartLight" .. tostring(index),
			size = Vector3.new(1.1, 1.1, 1.1),
			cframe = CFrame.new(x, 9.2, lineZ),
			color = Color3.fromRGB(120, 30, 26),
			material = Enum.Material.Glass,
			transparency = 0.15,
			reflectance = 0.2,
			shape = "ball",
			collide = false,
		})
		lamp:SetAttribute("StartLight", index)
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(180, 40, 32)
		glow.Range = 10
		glow.Brightness = 0.8
		glow.Parent = lamp
	end

	local board = World.part(model, {
		name = "Title",
		size = Vector3.new(14, 3, 0.4),
		cframe = CFrame.new(-WIDTH * 0.5 - 10, 4, lineZ - 30) * CFrame.Angles(0, math.rad(90), 0),
		color = Color3.fromRGB(32, 34, 38),
		material = Enum.Material.Metal,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(640, 140)
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.fromRGB(236, 232, 220)
	text.TextScaled = true
	text.Text = "ГАРАЖ  ·  3 КРУГА"
	text.Parent = gui

	model:PivotTo(origin)
	return model
end

return RaceTrackBuilder
