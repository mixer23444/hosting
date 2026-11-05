-- Race HUD: opponent builds before the start, laps, result, rematch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local UiKit = require(Shared.UiKit)
local ChaseCam = require(Shared.ChaseCam)

ChaseCam.bind()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RaceState = remotes:WaitForChild("RaceState")
local Notify = remotes:WaitForChild("Notify")
local Rematch = remotes:WaitForChild("Rematch")
local LeaveRace = remotes:WaitForChild("LeaveRace")
local Upright = remotes:WaitForChild("Upright")

local gui = UiKit.screen("GarazhRace")

local top = UiKit.frame(gui, {
	name = "Top",
	size = UDim2.fromOffset(420, 64),
	position = UDim2.new(0.5, -210, 0, 12),
	color = UiKit.BG,
	transparency = 0.15,
	pad = 8,
})
UiKit.stroke(top)
local topText = UiKit.label(top, "ГАРАЖ", 16)
topText.Size = UDim2.fromScale(1, 1)
topText.TextXAlignment = Enum.TextXAlignment.Center
topText.Font = UiKit.FONT_BOLD

local countdown = UiKit.label(gui, "", 72)
countdown.AnchorPoint = Vector2.new(0.5, 0.5)
countdown.Position = UDim2.fromScale(0.5, 0.42)
countdown.Size = UDim2.fromOffset(200, 90)
countdown.TextXAlignment = Enum.TextXAlignment.Center
countdown.Font = UiKit.FONT_BOLD
countdown.TextColor3 = UiKit.ACCENT
countdown.Visible = false

local cards = UiKit.frame(gui, {
	name = "Builds",
	size = UDim2.new(0, 560, 0, 280),
	position = UDim2.new(0.5, -280, 1, -300),
	color = UiKit.BG,
	transparency = 0.1,
	visible = false,
	pad = 10,
})
UiKit.stroke(cards, UiKit.ACCENT)
local cardsTitle = UiKit.label(cards, "Чужие машины. Цвет — косметика.", 14, UiKit.MUTED)
cardsTitle.Size = UDim2.new(1, 0, 0, 20)
local cardList = Instance.new("Frame")
cardList.BackgroundTransparency = 1
cardList.Position = UDim2.new(0, 0, 0, 26)
cardList.Size = UDim2.new(1, 0, 1, -26)
cardList.Parent = cards
local cardLayout = Instance.new("UIListLayout")
cardLayout.Padding = UDim.new(0, 6)
cardLayout.Parent = cardList

local side = UiKit.frame(gui, {
	name = "Order",
	size = UDim2.fromOffset(220, 240),
	position = UDim2.new(1, -232, 0, 12),
	color = UiKit.BG,
	transparency = 0.15,
	pad = 8,
})
UiKit.stroke(side)
local sideText = UiKit.label(side, "", 14)
sideText.Size = UDim2.fromScale(1, 1)
sideText.TextYAlignment = Enum.TextYAlignment.Top
sideText.TextWrapped = true

local results = UiKit.frame(gui, {
	name = "Results",
	size = UDim2.fromOffset(380, 280),
	position = UDim2.new(0.5, -190, 0.5, -140),
	color = UiKit.PANEL,
	visible = false,
	pad = 12,
})
UiKit.stroke(results, UiKit.ACCENT)
local resultText = UiKit.label(results, "", 15)
resultText.Size = UDim2.new(1, 0, 1, -44)
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.TextWrapped = true
local rematch = UiKit.button(results, "Реванш")
rematch.Position = UDim2.new(0, 0, 1, -36)
rematch.Size = UDim2.new(0.48, 0, 0, 34)
local leave = UiKit.button(results, "В гараж")
leave.Position = UDim2.new(0.52, 0, 1, -36)
leave.Size = UDim2.new(0.48, 0, 0, 34)
leave.BackgroundColor3 = UiKit.PANEL_SOFT
leave.TextColor3 = UiKit.TEXT

local upright = UiKit.button(gui, "На колёса")
upright.Size = UDim2.fromOffset(140, 32)
upright.Position = UDim2.new(0.5, -70, 1, -48)
upright.Visible = false

rematch.MouseButton1Click:Connect(function()
	Rematch:FireServer()
	rematch.Text = "Готов"
end)
leave.MouseButton1Click:Connect(function()
	LeaveRace:FireServer()
end)
upright.MouseButton1Click:Connect(function()
	Upright:InvokeServer()
end)

local function colorName(index: number): string
	local entry = Config.PALETTE[index]
	return if entry then entry.name else "—"
end

local function fillCards(racers)
	for _, child in cardList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for _, racer in racers do
		local label = UiKit.label(cardList, "", 14)
		label.Size = UDim2.new(1, 0, 0, 36)
		label.TextWrapped = true
		label.Text = string.format(
			"%s   цвет %s\nскорость %d  разгон %d  держак %d  масса %d    ·    %.0f / потолок %d",
			racer.name,
			colorName(racer.color),
			racer.speed,
			racer.acceleration,
			racer.grip,
			racer.weight,
			racer.mass or 0,
			racer.maxSpeed or 0
		)
	end
end

local function fillOrder(racers)
	local lines = { "Порядок" }
	for _, racer in racers do
		local mark = if racer.finished then "фин" else ("круг " .. tostring(math.min(Config.LAPS, (racer.lap or 0) + 1)))
		table.insert(lines, string.format("%d  %s  %s", racer.place, racer.name, mark))
	end
	sideText.Text = table.concat(lines, "\n")
end

Notify.OnClientEvent:Connect(function(text)
	topText.Text = tostring(text)
end)

RaceState.OnClientEvent:Connect(function(snapshot)
	local phase = snapshot.phase
	cards.Visible = phase == "grid"
	results.Visible = phase == "results"
	upright.Visible = phase == "racing"
	countdown.Visible = phase == "grid"
	if phase == "grid" then
		local left = math.ceil(snapshot.countdown or 0)
		countdown.Text = if left > 0 then tostring(left) else "СТАРТ"
		topText.Text = "Смотрите сборки. Цвет скорость не меняет."
		fillCards(snapshot.racers or {})
		rematch.Text = "Реванш"
	elseif phase == "racing" then
		topText.Text = string.format("Круг из %d    %s", snapshot.laps, Format.seconds(snapshot.raceTime))
	elseif phase == "results" then
		countdown.Visible = false
		local info = snapshot.results or {}
		local lines = {}
		if info.winner then
			table.insert(lines, "Победитель: " .. info.winner)
		else
			table.insert(lines, "Никто не закрыл три круга.")
		end
		if info.feesPaid then
			table.insert(lines, "Банк " .. Format.money(info.pot or 0) .. " забирает победитель.")
			table.insert(lines, "Остальным — участие " .. Format.money(Config.PARTICIPATION) .. ".")
		else
			table.insert(lines, "Без выплаты: заезд открыт не из гаража.")
		end
		for _, payout in info.payouts or {} do
			local timeText = if payout.time then Format.seconds(payout.time) else "сход"
			table.insert(lines, string.format("%d. %s  %s  %s", payout.place, payout.name, timeText, Format.money(payout.amount or 0)))
		end
		table.insert(lines, string.format("Реванш %d/%d", snapshot.ready or 0, snapshot.total or 0))
		resultText.Text = table.concat(lines, "\n")
		topText.Text = "Финиш"
	else
		topText.Text = "Ждём сетку"
	end
	fillOrder(snapshot.racers or {})
end)

task.spawn(function()
	local player = Players.LocalPlayer
	while true do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") and not countdown.Visible then
			local model = seat:FindFirstAncestorOfClass("Model")
			local chassis = model and model.PrimaryPart
			if chassis and topText.Text:find("Круг") then
				local velocity = chassis.AssemblyLinearVelocity
				local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
				-- Speed sits in the upright button's spare space via the top line only when racing.
				upright.Text = "На колёса  " .. Format.speed(speed)
			end
		end
		task.wait(0.1)
	end
end)
