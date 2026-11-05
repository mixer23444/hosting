-- Small part factory. Surfaces stay smooth so materials read as concrete, metal, and paint.

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
