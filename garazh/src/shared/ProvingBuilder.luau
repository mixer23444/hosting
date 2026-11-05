-- Private test pad: one straight, one measured sweeper, a lap back to the line.
-- No payout lives here. The folder is cloned per player and moved aside.

local Config = require(script.Parent.Config)
local TrackMesh = require(script.Parent.TrackMesh)
local World = require(script.Parent.World)

local ProvingBuilder = {}

local WIDTH = 24

function ProvingBuilder.points(): { Vector3 }
	local points = {}
	local function push(x: number, z: number)
		table.insert(points, Vector3.new(x, 0, z))
	end
	-- Straight, then one sweeper, then a close back to the line.
	push(0, 0)
	push(0, 28)
	push(0, 70)
	push(0, 120)
	push(0, 168)
	push(6, 196)
	push(24, 218)
	push(52, 232)
	push(84, 236)
	push(116, 228)
	push(140, 190)
	push(148, 120)
	push(140, 50)
	push(90, 8)
	push(30, -4)
	push(0, 0)
	return points
end

function ProvingBuilder.build(origin: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "ProvingPad"

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

	local points = ProvingBuilder.points()
	TrackMesh.ground(model, Vector3.new(74, 0, 116), Vector3.new(240, 2, 300))
	TrackMesh.lay(model, points, WIDTH)

	-- 1 start, 2 end of straight, 3 corner entry, 4 corner exit.
	local gatePoints = { 2, 5, 7, 10 }
	for index, pointIndex in gatePoints do
		TrackMesh.gate(model, index, points, pointIndex, WIDTH)
	end

	local slot = World.part(model, {
		name = "CarSlot",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.lookAt(
			Vector3.new(0, Config.CHASSIS_Y + 0.35, 8),
			Vector3.new(0, Config.CHASSIS_Y + 0.35, 40)
		),
		transparency = 1,
		collide = false,
		shadow = false,
	})
	slot.CanQuery = false

	local returnPad = World.part(model, {
		name = "ReturnPad",
		size = Vector3.new(2, 3, 2),
		cframe = CFrame.new(10, 1.5, 8),
		color = Color3.fromRGB(72, 74, 78),
		material = Enum.Material.DiamondPlate,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ReturnPrompt"
	prompt.ActionText = "В гараж"
	prompt.ObjectText = "Полигон"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = returnPad

	local board = World.part(model, {
		name = "Board",
		size = Vector3.new(7, 2.2, 0.3),
		cframe = CFrame.new(-10, 2.4, 6),
		color = Color3.fromRGB(36, 38, 42),
		material = Enum.Material.Metal,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(420, 140)
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 0.42, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.fromRGB(230, 230, 226)
	text.TextScaled = true
	text.Text = "ПОЛИГОН  ·  без выплаты"
	text.Parent = gui
	local clock = Instance.new("TextLabel")
	clock.Name = "LapClock"
	clock.Size = UDim2.new(1, 0, 0.58, 0)
	clock.Position = UDim2.new(0, 0, 0.42, 0)
	clock.BackgroundTransparency = 1
	clock.Font = Enum.Font.GothamBold
	clock.TextColor3 = Color3.fromRGB(214, 162, 74)
	clock.TextScaled = true
	clock.Text = "КРУГ  ждёт отсечку"
	clock.Parent = gui

	model:PivotTo(origin)
	return model
end

return ProvingBuilder
