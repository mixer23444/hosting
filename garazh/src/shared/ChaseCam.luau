-- Third-person camera while the local player is in a VehicleSeat.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ChaseCam = {}

local bound = false
local active = false

local function desiredSeat(): VehicleSeat?
	local player = Players.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		return seat
	end
	return nil
end

function ChaseCam.bind()
	if bound then
		return
	end
	bound = true
	local camera = Workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	RunService.RenderStepped:Connect(function(dt)
		camera = Workspace.CurrentCamera
		local seat = desiredSeat()
		if not seat or not camera then
			if active then
				active = false
				camera.CameraType = Enum.CameraType.Custom
				camera.FieldOfView = 70
			end
			return
		end
		local model = seat:FindFirstAncestorOfClass("Model")
		local chassis = model and model.PrimaryPart
		if not chassis then
			return
		end
		active = true
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 74

		local ignore = { model }
		local character = Players.LocalPlayer.Character
		if character then
			table.insert(ignore, character)
		end
		params.FilterDescendantsInstances = ignore

		local look = chassis.CFrame.LookVector
		local origin = chassis.Position + Vector3.new(0, 2.2, 0)
		local back = origin - look * 20 + Vector3.new(0, 6.5, 0)
		local hit = Workspace:Raycast(origin, back - origin, params)
		local eye = if hit then hit.Position + hit.Normal * 0.6 else back
		local focus = chassis.Position + Vector3.new(0, 1.4, 0) + look * 6
		local goal = CFrame.lookAt(eye, focus)
		local alpha = 1 - math.exp(-7 * dt)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	end)
end

return ChaseCam
