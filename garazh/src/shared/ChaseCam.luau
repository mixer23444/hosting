-- Chase camera that orbits with the right mouse button.
-- The rig follows the car, not the car's heading.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ChaseCam = {}

local bound = false
local active = false
local yaw = 0
local pitch = 0.28
local orbiting = false

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

local function setOrbiting(on: boolean)
	if orbiting == on then
		return
	end
	orbiting = on
	UserInputService.MouseBehavior = if on then Enum.MouseBehavior.LockCurrentPosition else Enum.MouseBehavior.Default
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

	UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			setOrbiting(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			setOrbiting(false)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		camera = Workspace.CurrentCamera
		local seat = desiredSeat()
		if not seat or not camera then
			if active then
				active = false
				setOrbiting(false)
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

		if orbiting or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local delta = UserInputService:GetMouseDelta()
			yaw -= delta.X * 0.005
			pitch = math.clamp(pitch - delta.Y * 0.004, -0.2, 1.05)
		end

		local ignore = { model }
		local character = Players.LocalPlayer.Character
		if character then
			table.insert(ignore, character)
		end
		params.FilterDescendantsInstances = ignore

		local focus = chassis.Position + Vector3.new(0, 2.4, 0)
		local spin = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local back = focus + spin:VectorToWorldSpace(Vector3.new(0, 0, 22))
		local hit = Workspace:Raycast(focus, back - focus, params)
		local eye = if hit then hit.Position + hit.Normal * 0.6 else back
		local goal = CFrame.lookAt(eye, focus)
		local alpha = 1 - math.exp(-10 * dt)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	end)
end

return ChaseCam
