-- Новый плейс. LocalScript в StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local yaw, pitch = 0, 0.25
local lapStart = nil

local gui = Instance.new("ScreenGui")
gui.Name = "Garage"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(230, 250)
panel.Position = UDim2.fromOffset(12, 12)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
panel.BackgroundTransparency = 0.15
panel.Parent = gui

local money = Instance.new("TextLabel")
money.Size = UDim2.new(1, -16, 0, 28)
money.Position = UDim2.fromOffset(8, 8)
money.BackgroundTransparency = 1
money.TextColor3 = Color3.new(1, 1, 1)
money.Font = Enum.Font.GothamMedium
money.TextSize = 16
money.TextXAlignment = Enum.TextXAlignment.Left
money.Text = "500 кр."
money.Parent = panel

local rows = {
	{ "speed", "Скорость" },
	{ "accel", "Разгон" },
	{ "grip", "Держак" },
	{ "weight", "Масса" },
}
local labels = {}
for index, row in rows do
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(110, 28)
	label.Position = UDim2.fromOffset(8, 40 + (index - 1) * 36)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = row[2] .. " 1"
	label.Parent = panel
	labels[row[1]] = label
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(90, 26)
	button.Position = UDim2.fromOffset(128, 40 + (index - 1) * 36)
	button.BackgroundColor3 = Color3.fromRGB(196, 140, 40)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.Text = "Купить"
	button.Parent = panel
	button.MouseButton1Click:Connect(function()
		ReplicatedStorage:WaitForChild("BuyUpgrade"):FireServer(row[1])
	end)
end

local leave = Instance.new("TextButton")
leave.Size = UDim2.fromOffset(206, 30)
leave.Position = UDim2.fromOffset(12, 196)
leave.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
leave.TextColor3 = Color3.new(1, 1, 1)
leave.Font = Enum.Font.GothamMedium
leave.TextSize = 15
leave.Text = "На полигон"
leave.Parent = panel
leave.MouseButton1Click:Connect(function()
	ReplicatedStorage:WaitForChild("GoPad"):FireServer()
	lapStart = os.clock()
end)

local finish = Instance.new("TextButton")
finish.Size = UDim2.fromOffset(206, 30)
finish.Position = UDim2.fromOffset(12, 274)
finish.BackgroundColor3 = Color3.fromRGB(40, 70, 48)
finish.TextColor3 = Color3.new(1, 1, 1)
finish.Font = Enum.Font.GothamMedium
finish.TextSize = 15
finish.Text = "Финиш круга"
finish.Parent = gui
finish.MouseButton1Click:Connect(function()
	if not lapStart then
		return
	end
	ReplicatedStorage:WaitForChild("FinishLap"):FireServer(os.clock() - lapStart)
	lapStart = nil
end)

ReplicatedStorage:WaitForChild("GarageUpdate").OnClientEvent:Connect(function(amount, data)
	money.Text = tostring(amount) .. " кр."
	for key, label in labels do
		label.Text = label.Text:gsub("%d+$", tostring(data[key]))
	end
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
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	camera.CFrame = CFrame.new(focus) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 1.4, 14)
end)
