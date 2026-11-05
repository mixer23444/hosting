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
	return part
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
	sky.SkyboxBk = "rbxassetid://12064107"
	sky.SkyboxDn = "rbxassetid://12064152"
	sky.SkyboxFt = "rbxassetid://12064121"
	sky.SkyboxLf = "rbxassetid://12063984"
	sky.SkyboxRt = "rbxassetid://12064115"
	sky.SkyboxUp = "rbxassetid://12064131"
	sky.SunAngularSize = 18
	sky.StarCount = 0
	sky.Parent = Lighting
	Lighting.ClockTime = 14.6
	Lighting.Brightness = 2.3
	Lighting.FogColor = Color3.fromRGB(176, 198, 220)
	Lighting.FogStart = 400
	Lighting.FogEnd = 2800
end

function World.pad(center: Vector3, span: number)
	local thickness = 8
	local pad = World.part(Workspace, {
		name = "AsphaltPad",
		size = Vector3.new(span, thickness, span),
		cframe = CFrame.new(center.X, -thickness * 0.5 - 0.04, center.Z),
		color = Color3.fromRGB(52, 52, 54),
		material = Enum.Material.Asphalt,
	})
	World.tile(pad, "rbxassetid://7551987784", Enum.NormalId.Top, 18)
	return pad
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
