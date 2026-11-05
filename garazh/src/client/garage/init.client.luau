-- Garage HUD: upgrades, paint, proving readout, friend invite.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local UiKit = require(Shared.UiKit)
local ChaseCam = require(Shared.ChaseCam)

ChaseCam.bind()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local State = remotes:WaitForChild("State")
local Notify = remotes:WaitForChild("Notify")
local ProvingResult = remotes:WaitForChild("ProvingResult")
local ProvingLive = remotes:WaitForChild("ProvingLive")
local Roster = remotes:WaitForChild("Roster")
local InvitePrompt = remotes:WaitForChild("InvitePrompt")
local InviteReply = remotes:WaitForChild("InviteReply")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade")
local SetColor = remotes:WaitForChild("SetColor")
local GoProving = remotes:WaitForChild("GoProving")
local ReturnGarage = remotes:WaitForChild("ReturnGarage")
local Upright = remotes:WaitForChild("Upright")
local Ghost = remotes:WaitForChild("Ghost")
local Invite = remotes:WaitForChild("Invite")

local gui = UiKit.screen("Garazh")
local selected: { [number]: boolean } = {}
local roster = {}
local state = nil

local panel = UiKit.frame(gui, {
	name = "Panel",
	size = UDim2.fromOffset(280, 0),
	position = UDim2.new(0, 12, 0, 12),
	color = UiKit.BG,
	transparency = 0.12,
	pad = 10,
})
panel.AutomaticSize = Enum.AutomaticSize.Y
UiKit.stroke(panel)
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function row(order: number): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = order
	frame.Parent = panel
	return frame
end

local title = UiKit.label(row(1), "ГАРАЖ", 22)
title.Font = UiKit.FONT_BOLD
local moneyLabel = UiKit.label(row(2), "—", 16, UiKit.ACCENT)
local modeLabel = UiKit.label(row(3), "", 13, UiKit.MUTED)
modeLabel.TextWrapped = true

local statRows = {}
for index, stat in ipairs(Config.STATS) do
	local holder = row(10 + index)
	local nameLabel = UiKit.label(holder, Config.STAT_LABEL[stat], 15)
	nameLabel.Size = UDim2.new(1, -110, 0, 22)
	local buy = UiKit.button(holder, "Купить")
	buy.Size = UDim2.new(0, 100, 0, 28)
	buy.Position = UDim2.new(1, -100, 0, 0)
	buy.MouseButton1Click:Connect(function()
		local result = BuyUpgrade:InvokeServer(stat)
		if result and result.ok == false then
			modeLabel.Text = result.error or "Не купилось."
		end
	end)
	local level = UiKit.label(holder, "", 13)
	level.Position = UDim2.new(0, 0, 0, 30)
	level.Size = UDim2.new(1, 0, 0, 16)
	statRows[stat] = { buy = buy, level = level }
end

local tuneLabel = UiKit.label(row(20), "", 13, UiKit.MUTED)
tuneLabel.TextWrapped = true
tuneLabel.Size = UDim2.new(1, 0, 0, 32)

local colorRow = row(21)
colorRow.Size = UDim2.new(1, 0, 0, 28)
local colorNote = UiKit.label(row(22), "Цвет кузова — косметика, на физику не влияет.", 12, UiKit.MUTED)
colorNote.TextWrapped = true
colorNote.Size = UDim2.new(1, 0, 0, 28)

for index, swatch in ipairs(Config.PALETTE) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(28, 28)
	button.Position = UDim2.fromOffset((index - 1) * 34, 0)
	button.BackgroundColor3 = swatch.color
	button.Text = ""
	button.BorderSizePixel = 0
	button.Parent = colorRow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = button
	button.MouseButton1Click:Connect(function()
		SetColor:InvokeServer(index)
	end)
end

local function action(order: number, text: string, callback)
	local holder = row(order)
	holder.Size = UDim2.new(1, 0, 0, 34)
	local button = UiKit.button(holder, text)
	button.MouseButton1Click:Connect(callback)
	return button
end

local driveButton = action(30, "Выехать", function()
	local result = GoProving:InvokeServer()
	if result and result.ok == false then
		modeLabel.Text = result.error or ""
	end
end)

local extra = row(31)
extra.Size = UDim2.new(1, 0, 0, 28)
local extraLayout = Instance.new("UIListLayout")
extraLayout.FillDirection = Enum.FillDirection.Horizontal
extraLayout.Padding = UDim.new(0, 4)
extraLayout.Parent = extra
local function mini(text: string, callback)
	local button = UiKit.button(extra, text)
	button.Size = UDim2.new(1 / 3, -3, 1, 0)
	button.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 12
	limit.MinTextSize = 8
	limit.Parent = button
	button.MouseButton1Click:Connect(callback)
end
mini("В гараж", function()
	local result = ReturnGarage:InvokeServer()
	if result and result.ok == false then
		modeLabel.Text = result.error or ""
	end
end)
mini("На колёса", function()
	Upright:InvokeServer()
end)
mini("Призрачный круг", function()
	local result = Ghost:InvokeServer()
	modeLabel.Text = (result and result.error) or "Заглушка."
end)

local raceButton = action(34, "Гонка с друзьями", function() end)

local racePanel = UiKit.frame(gui, {
	name = "Race",
	size = UDim2.new(0, 280, 0, 320),
	position = UDim2.new(0, 300, 0, 12),
	color = UiKit.PANEL,
	visible = false,
	pad = 10,
})
UiKit.stroke(racePanel)
local raceTitle = UiKit.label(racePanel, "До 4 друзей на этом сервере", 16)
raceTitle.Font = UiKit.FONT_BOLD
local raceList = Instance.new("Frame")
raceList.BackgroundTransparency = 1
raceList.Position = UDim2.new(0, 0, 0, 36)
raceList.Size = UDim2.new(1, 0, 1, -90)
raceList.Parent = racePanel
local raceLayout = Instance.new("UIListLayout")
raceLayout.Padding = UDim.new(0, 4)
raceLayout.Parent = raceList
local inviteButton = UiKit.button(racePanel, "Пригласить")
inviteButton.Position = UDim2.new(0, 0, 1, -36)
inviteButton.MouseButton1Click:Connect(function()
	local ids = {}
	for userId, on in selected do
		if on then
			table.insert(ids, userId)
		end
	end
	inviteButton.Text = "Ждём ответ…"
	local result = Invite:InvokeServer(ids)
	inviteButton.Text = "Пригласить"
	if result and result.ok == false then
		modeLabel.Text = result.error or "Гонка не стартовала."
	end
end)

raceButton.MouseButton1Click:Connect(function()
	racePanel.Visible = not racePanel.Visible
end)

local function redrawRoster()
	for _, child in raceList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local me = Players.LocalPlayer
	for _, entry in roster do
		if entry.userId == me.UserId then
			continue
		end
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 28)
		button.BackgroundColor3 = if selected[entry.userId] then UiKit.ACCENT else UiKit.PANEL_SOFT
		button.TextColor3 = if selected[entry.userId] then Color3.fromRGB(20, 18, 14) else UiKit.TEXT
		button.Font = UiKit.FONT
		button.TextSize = 14
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Text = "  " .. entry.name
		button.AutoButtonColor = true
		button.Parent = raceList
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = button
		button.MouseButton1Click:Connect(function()
			local count = 0
			for _, on in selected do
				if on then
					count += 1
				end
			end
			if selected[entry.userId] then
				selected[entry.userId] = false
			elseif count < Config.MAX_INVITES then
				selected[entry.userId] = true
			end
			redrawRoster()
		end)
	end
end

local banner = UiKit.frame(gui, {
	name = "Banner",
	size = UDim2.new(0, 360, 0, 150),
	position = UDim2.new(0.5, -180, 0, 16),
	color = UiKit.PANEL,
	visible = false,
	pad = 10,
})
UiKit.stroke(banner, UiKit.ACCENT)
local bannerText = UiKit.label(banner, "", 16)
bannerText.Size = UDim2.fromScale(1, 1)
bannerText.TextWrapped = true
bannerText.TextYAlignment = Enum.TextYAlignment.Top

local lapLabel = UiKit.label(gui, "", 22, UiKit.ACCENT)
lapLabel.AnchorPoint = Vector2.new(0.5, 1)
lapLabel.Position = UDim2.new(0.5, 0, 1, -64)
lapLabel.Size = UDim2.fromOffset(220, 28)
lapLabel.TextXAlignment = Enum.TextXAlignment.Center
lapLabel.Font = UiKit.FONT_BOLD
lapLabel.Visible = false

local speedLabel = UiKit.label(gui, "", 28)
speedLabel.AnchorPoint = Vector2.new(0.5, 1)
speedLabel.Position = UDim2.new(0.5, 0, 1, -24)
speedLabel.Size = UDim2.fromOffset(200, 36)
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
speedLabel.Font = UiKit.FONT_BOLD
speedLabel.Visible = false

local modal = UiKit.frame(gui, {
	name = "Invite",
	size = UDim2.fromOffset(320, 160),
	position = UDim2.new(0.5, -160, 0.5, -80),
	color = UiKit.PANEL,
	visible = false,
	pad = 12,
})
UiKit.stroke(modal, UiKit.ACCENT)
local modalText = UiKit.label(modal, "", 16)
modalText.Size = UDim2.new(1, 0, 0, 70)
modalText.TextWrapped = true
local accept = UiKit.button(modal, "Принять")
accept.Position = UDim2.new(0, 0, 1, -36)
accept.Size = UDim2.new(0.48, 0, 0, 34)
local decline = UiKit.button(modal, "Отказать")
decline.Position = UDim2.new(0.52, 0, 1, -36)
decline.Size = UDim2.new(0.48, 0, 0, 34)
decline.BackgroundColor3 = UiKit.PANEL_SOFT
decline.TextColor3 = UiKit.TEXT
local pendingInvite = nil

accept.MouseButton1Click:Connect(function()
	if pendingInvite then
		InviteReply:FireServer(pendingInvite, true)
	end
	modal.Visible = false
end)
decline.MouseButton1Click:Connect(function()
	if pendingInvite then
		InviteReply:FireServer(pendingInvite, false)
	end
	modal.Visible = false
end)

local function render()
	if not state then
		return
	end
	moneyLabel.Text = "Гоночные  " .. Format.money(state.money)
	if state.sessionOnly then
		moneyLabel.Text ..= "  ·  только эта сессия"
	end
	if state.mode ~= "proving" then
		lapLabel.Visible = false
	end
	modeLabel.Text = if state.mode == "proving"
		then "Полигон. Выплаты нет. Белая черта — старт и финиш."
		else "Бокс. Машина на полу, подъёмник сзади."
	driveButton.Text = if state.mode == "proving" then "Уже на полигоне" else "Выехать"
	local tune = state.tune
	tuneLabel.Text = string.format(
		"Масса %.0f   момент %d   потолок %d   боковой %.1f",
		tune.mass,
		tune.torque,
		tune.maxSpeed,
		tune.lateralGrip
	)
	for _, stat in Config.STATS do
		local level = state.build[stat]
		local price = state.costs[stat]
		local marks = string.rep("●", level) .. string.rep("○", state.maxLevel - level)
		local priceText = if price then Format.money(price) else "макс."
		statRows[stat].level.Text = marks .. "   " .. priceText
		statRows[stat].buy.Text = if price then "Купить" else "Макс."
		statRows[stat].buy.AutoButtonColor = price ~= nil
	end
end

State.OnClientEvent:Connect(function(nextState)
	state = nextState
	render()
end)

Notify.OnClientEvent:Connect(function(text)
	modeLabel.Text = tostring(text)
end)

ProvingLive.OnClientEvent:Connect(function(live)
	speedLabel.Visible = true
	speedLabel.Text = Format.speed(live.speed)
	lapLabel.Visible = live.armed == true
	if live.armed then
		local text = "Круг  " .. Format.seconds(live.lapTime)
		modeLabel.Text = text
		lapLabel.Text = text
	end
end)

ProvingResult.OnClientEvent:Connect(function(result)
	banner.Visible = true
	local accel = if result.accelTime then Format.seconds(result.accelTime) else "не достиг " .. tostring(Config.ACCEL_MARK)
	bannerText.Text = string.format(
		"Круг %s\nРазгон до %d: %s\nМаксимум: %s\nДержак в дуге: %s\nСкорость в дуге: %s\nВыплаты нет.",
		Format.seconds(result.lapTime),
		Config.ACCEL_MARK,
		accel,
		Format.speed(result.topSpeed),
		Format.percent(result.cornerGrip or 0),
		Format.speed(result.cornerMin or 0)
	)
end)

Roster.OnClientEvent:Connect(function(list)
	roster = list
	redrawRoster()
end)

InvitePrompt.OnClientEvent:Connect(function(invite)
	pendingInvite = invite.inviteId
	modalText.Text = string.format("%s зовёт на гонку.\nВзнос %s с каждого. Банк забирает победитель.", invite.from, Format.money(invite.fee))
	modal.Visible = true
end)

task.spawn(function()
	while true do
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local driving = seat ~= nil and seat:IsA("VehicleSeat")
		speedLabel.Visible = driving
		if driving then
			local model = seat:FindFirstAncestorOfClass("Model")
			local chassis = model and model.PrimaryPart
			if chassis then
				local velocity = chassis.AssemblyLinearVelocity
				local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
				speedLabel.Text = Format.speed(speed)
			end
		end
		task.wait(0.1)
	end
end)

-- Keep the camera script warm even before the first seat.
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() end)
