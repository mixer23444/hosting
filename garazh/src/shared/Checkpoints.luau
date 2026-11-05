-- Gate crossing in the gate's local frame.
-- LookVector of the gate points along the track. A car moving that way
-- goes from local +Z to local -Z.

local Checkpoints = {}

function Checkpoints.crossed(prevPos: Vector3, pos: Vector3, gateCF: CFrame, halfWidth: number): boolean
	local prevLocal = gateCF:PointToObjectSpace(prevPos)
	local nowLocal = gateCF:PointToObjectSpace(pos)
	local crossedForward = prevLocal.Z > 0 and nowLocal.Z <= 0
	if not crossedForward then
		return false
	end
	if math.abs(nowLocal.X) > halfWidth and math.abs(prevLocal.X) > halfWidth then
		return false
	end
	if math.abs(nowLocal.Y) > 18 then
		return false
	end
	return true
end

function Checkpoints.readGates(folder: Instance): { [number]: { cframe: CFrame, halfWidth: number, part: BasePart } }
	local gates = {}
	for _, child in folder:GetDescendants() do
		if child:IsA("BasePart") and child:GetAttribute("Gate") then
			local index = child:GetAttribute("Gate")
			gates[index] = {
				cframe = child.CFrame,
				halfWidth = child:GetAttribute("HalfWidth") or (child.Size.X * 0.5),
				part = child,
			}
		end
	end
	return gates
end

return Checkpoints
