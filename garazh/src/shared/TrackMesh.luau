-- Asphalt ribbon, barriers, and timing gates from a polyline on the XZ plane.

local World = require(script.Parent.World)

local TrackMesh = {}

function TrackMesh.stadium(length: number, radius: number): { Vector3 }
	local points = {}
	local function push(v: Vector3)
		table.insert(points, v)
	end

	local straightSteps = 10
	for i = 0, straightSteps do
		push(Vector3.new(0, 0, length * i / straightSteps))
	end

	local arcSteps = 10
	for i = 1, arcSteps do
		local angle = math.pi - math.pi * i / arcSteps
		local center = Vector3.new(radius, 0, length)
		push(center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
	end

	for i = 1, straightSteps do
		push(Vector3.new(radius * 2, 0, length - length * i / straightSteps))
	end

	for i = 1, arcSteps do
		local angle = -math.pi * i / arcSteps
		local center = Vector3.new(radius, 0, 0)
		push(center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
	end

	return points
end

function TrackMesh.lay(parent: Instance, points: { Vector3 }, width: number)
	local asphalt = Color3.fromRGB(54, 54, 56)
	local edge = Color3.fromRGB(38, 38, 40)
	local concrete = Color3.fromRGB(132, 132, 130)
	local parts = {}

	for index = 1, #points - 1 do
		local a = points[index]
		local b = points[index + 1]
		local delta = b - a
		local length = delta.Magnitude
		if length < 0.05 then
			continue
		end
		local mid = (a + b) * 0.5
		local cf = CFrame.lookAt(Vector3.new(mid.X, 0, mid.Z), Vector3.new(b.X, 0, b.Z))
		local road = World.part(parent, {
			name = "Asphalt",
			size = Vector3.new(width, 1, length + 0.9),
			cframe = cf * CFrame.new(0, -0.5, 0),
			color = asphalt,
			material = Enum.Material.Asphalt,
		})
		table.insert(parts, road)

		World.part(parent, {
			name = "Edge",
			size = Vector3.new(width + 1.4, 0.4, length + 0.7),
			cframe = cf * CFrame.new(0, -0.85, 0),
			color = edge,
			material = Enum.Material.Asphalt,
			shadow = false,
		})

		if index % 2 == 0 then
			World.part(parent, {
				name = "Dash",
				size = Vector3.new(0.28, 0.04, math.max(1.2, length * 0.42)),
				cframe = cf * CFrame.new(0, 0.04, 0),
				color = Color3.fromRGB(214, 214, 206),
				material = Enum.Material.SmoothPlastic,
				collide = false,
				shadow = false,
			})
		end

		local right = cf.RightVector
		for side = -1, 1, 2 do
			local pos = Vector3.new(mid.X, 1.05, mid.Z) + right * side * (width * 0.5 + 0.7)
			World.part(parent, {
				name = "Barrier",
				size = Vector3.new(1.15, 2.1, length + 0.5),
				cframe = CFrame.new(pos) * (cf - cf.Position),
				color = concrete,
				material = Enum.Material.Concrete,
			})
		end
	end

	return parts
end

function TrackMesh.gate(parent: Instance, index: number, points: { Vector3 }, pointIndex: number, width: number): BasePart
	local a = points[pointIndex]
	local nextIndex = math.min(pointIndex + 1, #points)
	local b = points[nextIndex]
	if (b - a).Magnitude < 0.2 and pointIndex > 1 then
		b = a + (a - points[pointIndex - 1])
	end
	local cf = CFrame.lookAt(Vector3.new(a.X, 3, a.Z), Vector3.new(b.X, 3, b.Z))
	local gate = World.part(parent, {
		name = "Gate" .. tostring(index),
		size = Vector3.new(math.max(8, width - 4), 7, 0.4),
		cframe = cf,
		transparency = 1,
		collide = false,
		shadow = false,
	})
	gate.CanQuery = false
	gate:SetAttribute("Gate", index)
	gate:SetAttribute("HalfWidth", (width - 4) * 0.5)

	local lineColor = if index == 1 then Color3.fromRGB(236, 236, 232) else Color3.fromRGB(176, 52, 46)
	World.part(parent, {
		name = "TimingLine" .. tostring(index),
		size = Vector3.new(math.max(6, width - 8), 0.05, 0.7),
		cframe = CFrame.new(a.X, 0.06, a.Z) * (cf - cf.Position),
		color = lineColor,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		shadow = false,
	})
	return gate
end

function TrackMesh.ground(parent: Instance, center: Vector3, size: Vector3)
	World.part(parent, {
		name = "Verge",
		size = size,
		cframe = CFrame.new(center + Vector3.new(0, -1.6, 0)),
		color = Color3.fromRGB(78, 92, 64),
		material = Enum.Material.Grass,
	})
end

return TrackMesh
