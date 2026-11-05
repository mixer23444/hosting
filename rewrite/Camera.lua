-- Новый плейс. LocalScript в StarterPlayerScripts.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local yaw, pitch = 0, 0.3

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(150, 34)
button.Position = UDim2.new(0, 12, 1, -46)
button.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamMedium
button.TextSize = 16
button.Text = "Выехать"
button.Parent = gui
button.MouseButton1Click:Connect(function()
	ReplicatedStorage:WaitForChild("GoPad"):FireServer()
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		return
	end
	yaw -= input.Delta.X * 0.005
	pitch = math.clamp(pitch + input.Delta.Y * 0.005, -0.4, 1)
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not humanoid.SeatPart then
		camera.CameraType = Enum.CameraType.Custom
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local focus = root.Position + Vector3.new(0, 1.4, 0)
	camera.CFrame = CFrame.new(focus) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 1.2, 13)
end)
