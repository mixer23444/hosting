-- Вставь это в LocalScript внутри StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local yaw = 0
local pitch = 0.3

local gui = Instance.new("ScreenGui")
gui.Name = "GarazhGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(160, 36)
button.Position = UDim2.new(0, 12, 1, -48)
button.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
button.TextColor3 = Color3.fromRGB(245, 245, 245)
button.Font = Enum.Font.GothamMedium
button.TextSize = 16
button.Text = "Выехать"
button.Parent = gui

local remote = ReplicatedStorage:WaitForChild("GoProving")
button.MouseButton1Click:Connect(function()
	remote:FireServer()
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		return
	end
	yaw -= input.Delta.X * 0.005
	pitch = math.clamp(pitch + input.Delta.Y * 0.005, -0.5, 1)
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
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	camera.CFrame = CFrame.new(focus) * rotation * CFrame.new(0, 1.5, 14)
end)
