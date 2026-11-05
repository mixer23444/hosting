-- Small part factory. Surfaces stay smooth so materials read as concrete, metal, and paint.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local World = {}

export type PartProps = {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	shape: string?,
	anchored: boolean?,
	collide: boolean?,
	transparency: number?,
	reflectance: number?,
	massless: boolean?,
	shadow: boolean?,
}

function World.part(parent: Instance, props: PartProps): BasePart
	local className = if props.shape == "wedge" then "WedgePart" else "Part"
	local part = Instance.new(className) :: BasePart
	part.Name = props.name or "Part"
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color or Color3.fromRGB(148, 148, 146)
	part.Material = props.material or Enum.Material.Concrete
	part.Anchored = if props.anchored == nil then true else props.anchored
	part.CanCollide = if props.collide == nil then true else props.collide
	part.CanQuery = true
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = if props.shadow == nil then true else props.shadow
	if props.transparency then
		part.Transparency = props.transparency
	end
	if props.reflectance then
		part.Reflectance = props.reflectance
	end
	if props.massless then
		part.Massless = true
	end
	if props.shape == "cylinder" then
		(part :: Part).Shape = Enum.PartType.Cylinder
	elseif props.shape == "ball" then
		(part :: Part).Shape = Enum.PartType.Ball
	end
	part.Parent = parent
	World.dressSurface(part)
	return part
end

-- Image textures, not flat plastic. Glass stays clear so windows read as glass.
local SURFACE = {
	[Enum.Material.Brick] = { "rbxassetid://131227297", 4 },
	[Enum.Material.Asphalt] = { "rbxassetid://7551987784", 14 },
	[Enum.Material.DiamondPlate] = { "rbxassetid://7547304724", 3 },
	[Enum.Material.Metal] = { "rbxassetid://7547304724", 4 },
	[Enum.Material.Wood] = { "rbxassetid://28720778", 4 },
	[Enum.Material.WoodPlanks] = { "rbxassetid://28720778", 4 },
	[Enum.Material.Concrete] = { "rbxassetid://7547630026", 6 },
}

function World.dressSurface(part: BasePart)
	if part.Material == Enum.Material.Glass or part.Material == Enum.Material.SmoothPlastic or part.Material == Enum.Material.Neon then
		return
	end
	if part.Transparency >= 0.9 then
		return
	end
	local spec = SURFACE[part.Material] or SURFACE[Enum.Material.Concrete]
	for _, face in {
		Enum.NormalId.Top,
		Enum.NormalId.Front,
		Enum.NormalId.Back,
		Enum.NormalId.Left,
		Enum.NormalId.Right,
	} do
		World.tile(part, spec[1], face, spec[2])
	end
end

function World.weld(a: BasePart, b: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = a
	weld.Part1 = b
	weld.Parent = b
	return weld
end

function World.tile(part: BasePart, assetId: string, face: Enum.NormalId, studs: number)
	local texture = Instance.new("Texture")
	texture.Name = "Surface"
	texture.Texture = assetId
	texture.Face = face
	texture.StudsPerTileU = studs
	texture.StudsPerTileV = studs
	texture.Parent = part
	return texture
end

function World.dress()
	for _, child in Workspace:GetChildren() do
		if child.Name == "Baseplate" or child.Name == "BasePlate" then
			child:Destroy()
		end
	end
	local existing = Lighting:FindFirstChildOfClass("Sky")
	if existing then
		existing:Destroy()
	end
	local sky = Instance.new("Sky")
	sky.Name = "GarazhSky"
	sky.SkyboxBk = "rbxassetid://271042516"
	sky.SkyboxDn = "rbxassetid://271077243"
	sky.SkyboxFt = "rbxassetid://271042556"
	sky.SkyboxLf = "rbxassetid://271042310"
	sky.SkyboxRt = "rbxassetid://271042467"
	sky.SkyboxUp = "rbxassetid://271077958"
	sky.SunAngularSize = 11
	sky.StarCount = 0
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.18
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 198, 206)
	atmosphere.Decay = Color3.fromRGB(150, 160, 170)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 0.4

	Lighting.ClockTime = 13.2
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 168, 176)
	Lighting.Ambient = Color3.fromRGB(70, 74, 80)
	Lighting.ColorShift_Top = Color3.fromRGB(210, 218, 224)
	Lighting.ColorShift_Bottom = Color3.fromRGB(170, 176, 182)
	Lighting.FogColor = Color3.fromRGB(186, 194, 202)
	Lighting.FogStart = 1800
	Lighting.FogEnd = 7000
end

function World.pad(center: Vector3, span: number)
	-- Buried under the street so it cannot z-fight the asphalt.
	local thickness = 6
	local concrete = World.part(Workspace, {
		name = "ConcretePad",
		size = Vector3.new(span, thickness, span),
		cframe = CFrame.new(center.X, -thickness * 0.5 - 1.4, center.Z),
		color = Color3.fromRGB(120, 118, 112),
		material = Enum.Material.Concrete,
	})
	return concrete
end

function World.markPaint(part: BasePart)
	part:SetAttribute("Paint", true)
end

function World.paintModel(model: Model, color: Color3)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Paint") then
			descendant.Color = color
		end
	end
end

return World
