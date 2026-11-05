-- Гараж. LocalScript в StarterPlayer > StarterPlayerScripts. Замени старый LocalScript целиком.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local yaw, pitch = 0, 0.28
local lapStart = nil

local gui = Instance.new("ScreenGui")
gui.Name = "Garage"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(240, 292)
panel.Position = UDim2.fromOffset(14, 14)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 26)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Text = "Гараж"
title.Parent = panel

local money = Instance.new("TextLabel")
money.Size = UDim2.new(1, -16, 0, 20)
money.Position = UDim2.fromOffset(10, 32)
money.BackgroundTransparency = 1
money.Font = Enum.Font.Gotham
money.TextSize = 14
money.TextXAlignment = Enum.TextXAlignment.Left
money.TextColor3 = Color3.fromRGB(220, 190, 110)
money.Text = "500 кр."
money.Parent = panel

local names = { speed = "Скорость", accel = "Разгон", grip = "Держак", weight = "Масса" }
local order = { "speed", "accel", "grip", "weight" }
local labels = {}
for index, key in order do
	local y = 58 + (index - 1) * 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(120, 22)
	label.Position = UDim2.fromOffset(10, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Text = names[key] .. "  1"
	label.Parent = panel
	labels[key] = label
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(88, 26)
	button.Position = UDim2.fromOffset(140, y - 2)
	button.BackgroundColor3 = Color3.fromRGB(186, 128, 36)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.Text = "Купить"
	button.Parent = panel
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button
	button.MouseButton1Click:Connect(function()
		ReplicatedStorage:WaitForChild("BuyUpgrade"):FireServer(key)
	end)
end

local function action(text, y, color, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(216, 30)
	button.Position = UDim2.fromOffset(12, y)
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 15
	button.Text = text
	button.Parent = panel
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button
	button.MouseButton1Click:Connect(callback)
end

action("На полигон", 214, Color3.fromRGB(46, 48, 56), function()
	ReplicatedStorage:WaitForChild("GoPad"):FireServer()
	lapStart = os.clock()
end)
action("Финиш круга", 250, Color3.fromRGB(42, 78, 52), function()
	if not lapStart then
		return
	end
	ReplicatedStorage:WaitForChild("FinishLap"):FireServer(os.clock() - lapStart)
	lapStart = nil
end)

ReplicatedStorage:WaitForChild("GarageUpdate").OnClientEvent:Connect(function(amount, data)
	money.Text = tostring(amount) .. " кр."
	for key, label in labels do
		label.Text = names[key] .. "  " .. tostring(data[key])
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
	local focus = root.Position + Vector3.new(0, 1.6, 0)
	camera.CFrame = CFrame.new(focus) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 1.5, 14)
end)
