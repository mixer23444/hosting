-- Garage place: private bay, upgrades, proving pad, friend invite onto the race place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Physics = require(Shared.Physics)
local CarBuilder = require(Shared.CarBuilder)
local GarageBuilder = require(Shared.GarageBuilder)
local ProvingBuilder = require(Shared.ProvingBuilder)
local Checkpoints = require(Shared.Checkpoints)
local VehicleDriver = require(Shared.VehicleDriver)
local GhostLap = require(Shared.GhostLap)
local World = require(Shared.World)
local ProfileService = require(script.Parent.ProfileService)

ProfileService.start()
VehicleDriver.bindServer()
Workspace.Gravity = 196.2
World.dress()
World.pad(Vector3.zero, 3600)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function event(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local function func(name: string): RemoteFunction
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local Remotes = {
	State = event("State"),
	Notify = event("Notify"),
	ProvingResult = event("ProvingResult"),
	ProvingLive = event("ProvingLive"),
	Roster = event("Roster"),
	InvitePrompt = event("InvitePrompt"),
	InviteReply = event("InviteReply"),
	BuyUpgrade = func("BuyUpgrade"),
	SetColor = func("SetColor"),
	GoProving = func("GoProving"),
	ReturnGarage = func("ReturnGarage"),
	Upright = func("Upright"),
	Ghost = func("Ghost"),
	Invite = func("Invite"),
}

local world = Instance.new("Folder")
world.Name = "GarazhWorld"
world.Parent = Workspace

local sessions: { [Player]: any } = {}
local slotCursor = 0
local pads: { [number]: Model } = {}
local pendingCharge: { [number]: number } = {}

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

local function buildOf(profile)
	return {
		speed = profile.speed,
		acceleration = profile.acceleration,
		grip = profile.grip,
		weight = profile.weight,
		color = profile.color,
	}
end

local function payload(player: Player)
	local profile = ProfileService.get(player)
	local session = sessions[player]
	if not profile or not session then
		return nil
	end
	local tune = Physics.publicTune(Physics.derive(profile))
	local costs = {}
	for _, stat in Config.STATS do
		costs[stat] = Config.cost(stat, profile[stat])
	end
	return {
		money = profile.money,
		build = buildOf(profile),
		tune = tune,
		costs = costs,
		maxLevel = Config.MAX_LEVEL,
		mode = session.mode,
		sessionOnly = ProfileService.sessionOnly(player),
	}
end

local function pushState(player: Player)
	local state = payload(player)
	if state then
		Remotes.State:FireClient(player, state)
	end
end

local function sitPrompt(model: Model, enabled: boolean)
	local chassis = model.PrimaryPart
	local prompt = chassis and chassis:FindFirstChild("SitPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = enabled
	end
end

local function seatPlayer(player: Player, model: Model)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = model:FindFirstChild("Seat", true)
	if humanoid and seat and seat:IsA("VehicleSeat") then
		seat.Disabled = false
		seat.MaxSpeed = 0
		seat.Torque = 0
		seat.TurnSpeed = 0
		humanoid.Sit = true
		seat:Sit(humanoid)
		humanoid:ChangeState(Enum.HumanoidStateType.Seated)
	end
end

local function applyCar(player: Player)
	local session = sessions[player]
	local profile = ProfileService.get(player)
	if not session or not profile or not session.car then
		return
	end
	CarBuilder.applyTune(session.car, profile)
	CarBuilder.applyPaint(session.car, profile.color)
end

local function freshTelemetry()
	return {
		armed = false,
		next = 1,
		sawCorner = false,
		t0 = 0,
		accelStart = nil,
		accelTime = nil,
		topSpeed = 0,
		cornerSum = 0,
		cornerN = 0,
		cornerMin = math.huge,
		prev = nil,
		lastLive = 0,
	}
end

local function padFor(index: number): Model
	local pad = pads[index]
	if pad then
		return pad
	end
	local origin = CFrame.new(0, 0, -900 - (index - 1) * 420)
	pad = ProvingBuilder.build(origin)
	pad.Parent = world
	pads[index] = pad
	return pad
end

local function moveCharacter(player: Player, cf: CFrame)
	local character = player.Character
	if character then
		character:PivotTo(cf + Vector3.new(0, 3, 0))
	end
end

local function goGarage(player: Player)
	local session = sessions[player]
	if not session or session.mode ~= "proving" then
		return false, "Вы уже в гараже."
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Sit = false
	end
	session.car:PivotTo(session.garage.CarSlot.CFrame)
	CarBuilder.setParked(session.car, true)
	sitPrompt(session.car, true)
	session.mode = "garage"
	session.telemetry = nil
	player.RespawnLocation = session.garage.Spawn
	moveCharacter(player, session.garage.Spawn.CFrame)
	pushState(player)
	return true, "Машина в боксе."
end

local function goProving(player: Player)
	local session = sessions[player]
	if not session then
		return false, "Гараж ещё не собран."
	end
	if session.mode == "proving" then
		return false, "Вы уже на полигоне."
	end
	local pad = padFor(session.index)
	session.car:PivotTo(pad.CarSlot.CFrame)
	CarBuilder.setParked(session.car, false)
	sitPrompt(session.car, true)
	session.mode = "proving"
	session.telemetry = freshTelemetry()
	session.gates = Checkpoints.readGates(pad)
	player.RespawnLocation = session.garage.Spawn
	task.defer(function()
		seatPlayer(player, session.car)
	end)
	pushState(player)
	notify(player, "Полигон. Выплаты нет. Круг: прямая, дуга, финиш на белой черте.")
	return true, "Выехали."
end

local function roster()
	local list = {}
	for _, player in Players:GetPlayers() do
		table.insert(list, {
			userId = player.UserId,
			name = player.DisplayName,
		})
	end
	Remotes.Roster:FireAllClients(list)
end

local function sampleCorner(telemetry, chassis: BasePart, speed: number)
	local velocity = chassis.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude < 10 then
		return
	end
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	if look.Magnitude < 0.05 then
		return
	end
	local dot = math.clamp(look.Unit:Dot(flat.Unit), -1, 1)
	local angle = math.deg(math.acos(dot))
	local excess = math.max(0, angle - 5)
	local penalty = math.clamp(excess / 28, 0, 1)
	local speedFactor = math.clamp(speed / 55, 0, 1)
	telemetry.cornerSum += (1 - penalty) * (0.35 + 0.65 * speedFactor)
	telemetry.cornerN += 1
	telemetry.cornerMin = math.min(telemetry.cornerMin, speed)
end

local function finishLap(player: Player, telemetry)
	local grip = if telemetry.cornerN > 0 then telemetry.cornerSum / telemetry.cornerN else 0
	local result = {
		lapTime = os.clock() - telemetry.t0,
		accelTime = telemetry.accelTime,
		topSpeed = telemetry.topSpeed,
		cornerGrip = grip,
		cornerMin = if telemetry.cornerMin < math.huge then telemetry.cornerMin else 0,
		samples = telemetry.cornerN,
	}
	Remotes.ProvingResult:FireClient(player, result)
	telemetry.armed = true
	telemetry.next = 2
	telemetry.sawCorner = false
	telemetry.t0 = os.clock()
	telemetry.accelStart = nil
	telemetry.accelTime = nil
	telemetry.topSpeed = 0
	telemetry.cornerSum = 0
	telemetry.cornerN = 0
	telemetry.cornerMin = math.huge
end

local function onGate(player: Player, telemetry, gateIndex: number)
	if gateIndex ~= telemetry.next then
		return
	end
	if gateIndex == 1 and not telemetry.armed then
		telemetry.armed = true
		telemetry.t0 = os.clock()
		telemetry.next = 2
		notify(player, "Отсечка. Круг пошёл.")
		return
	end
	if gateIndex == 1 and telemetry.armed and telemetry.sawCorner then
		finishLap(player, telemetry)
		return
	end
	if gateIndex == 1 then
		return
	end
	telemetry.next += 1
	if telemetry.next > 4 then
		telemetry.next = 1
		telemetry.sawCorner = true
	end
end

local function stepProving(player: Player, session, dt: number)
	local telemetry = session.telemetry
	local chassis = session.car and session.car.PrimaryPart
	if not telemetry or not chassis then
		return
	end
	if chassis.Position.Y < -12 then
		session.car:PivotTo(padFor(session.index).CarSlot.CFrame)
		CarBuilder.setParked(session.car, false)
		sitPrompt(session.car, true)
		telemetry.prev = nil
		return
	end
	local velocity = chassis.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local pos = chassis.Position
	if telemetry.armed then
		telemetry.topSpeed = math.max(telemetry.topSpeed, speed)
		if not telemetry.accelStart and speed > 8 then
			telemetry.accelStart = os.clock()
		end
		if telemetry.accelStart and not telemetry.accelTime and speed >= Config.ACCEL_MARK then
			telemetry.accelTime = os.clock() - telemetry.accelStart
		end
		if telemetry.next == 4 then
			sampleCorner(telemetry, chassis, speed)
		end
	end
	if telemetry.prev then
		for index, gate in session.gates do
			if Checkpoints.crossed(telemetry.prev, pos, gate.cframe, gate.halfWidth) then
				onGate(player, telemetry, index)
			end
		end
	end
	telemetry.prev = pos
	if os.clock() - telemetry.lastLive > 0.25 then
		telemetry.lastLive = os.clock()
		local lapTime = if telemetry.armed then os.clock() - telemetry.t0 else 0
		local clock = padFor(session.index):FindFirstChild("LapClock", true)
		if clock and clock:IsA("TextLabel") then
			clock.Text = if telemetry.armed then ("КРУГ  " .. Format.seconds(lapTime)) else "КРУГ  ждёт отсечку"
		end
		Remotes.ProvingLive:FireClient(player, {
			speed = speed,
			armed = telemetry.armed,
			lapTime = lapTime,
			next = telemetry.next,
		})
	end
	-- dt is unused; the driver has its own heartbeat. Kept so the signature stays honest.
	return dt
end

local function giveGarage(player: Player)
	if sessions[player] then
		return
	end
	ProfileService.load(player)
	slotCursor += 1
	local index = slotCursor
	local origin = CFrame.new((index - 1) * 100, 0, 0)
	local garage = GarageBuilder.build(origin)
	garage.Name = "Garage_" .. tostring(player.UserId)
	garage.Parent = world

	local profile = ProfileService.get(player)
	local car = CarBuilder.spawn(profile, garage.CarSlot.CFrame, true)
	car.Name = "Car_" .. tostring(player.UserId)
	car.Parent = garage
	VehicleDriver.add(car)

	local chassis = car.PrimaryPart
	local sit = chassis and chassis:FindFirstChild("SitPrompt")
	if sit and sit:IsA("ProximityPrompt") then
		sit.Enabled = true
		sit.Triggered:Connect(function(who)
			if who ~= player or not sessions[player] then
				return
			end
			CarBuilder.setParked(car, false)
			seatPlayer(player, car)
		end)
	end
	local button = garage:FindFirstChild("ExitButton", true)
	local leave = button and button:FindFirstChild("LeavePrompt")
	if leave and leave:IsA("ProximityPrompt") then
		leave.Triggered:Connect(function(who)
			if who == player then
				local ok, message = goProving(player)
				if not ok then
					notify(player, message)
				end
			end
		end)
	end

	sessions[player] = {
		index = index,
		garage = garage,
		car = car,
		mode = "garage",
		telemetry = nil,
		gates = nil,
	}
	player.RespawnLocation = garage.Spawn
	task.defer(function()
		if player.Parent and sessions[player] and sessions[player].mode == "garage" then
			moveCharacter(player, garage.Spawn.CFrame)
		end
	end)
	pushState(player)
	roster()
end

Remotes.BuyUpgrade.OnServerInvoke = function(player, stat)
	if typeof(stat) ~= "string" then
		return { ok = false, error = "Неизвестная доработка." }
	end
	local known = false
	for _, name in Config.STATS do
		if name == stat then
			known = true
		end
	end
	if not known then
		return { ok = false, error = "Нет такой доработки." }
	end
	local profile = ProfileService.get(player)
	if not profile then
		return { ok = false, error = "Профиль ещё не загружен." }
	end
	local price = Config.cost(stat, profile[stat])
	if not price then
		return { ok = false, error = "Дальше некуда." }
	end
	if profile.money < price then
		return { ok = false, error = "Мало гоночных денег." }
	end
	local spent = ProfileService.mutate(player, function(data)
		local nextPrice = Config.cost(stat, data[stat])
		if not nextPrice or data.money < nextPrice then
			return false
		end
		data.money -= nextPrice
		data[stat] += 1
		return true
	end)
	if not spent then
		return { ok = false, error = "Не вышло списать деньги." }
	end
	applyCar(player)
	pushState(player)
	return { ok = true }
end

Remotes.SetColor.OnServerInvoke = function(player, colorIndex)
	if typeof(colorIndex) ~= "number" then
		return { ok = false, error = "Нет такого цвета." }
	end
	colorIndex = math.floor(colorIndex)
	if colorIndex < 1 or colorIndex > #Config.PALETTE then
		return { ok = false, error = "Нет такого цвета." }
	end
	local changed = ProfileService.mutate(player, function(data)
		data.color = colorIndex
		return true
	end)
	if not changed then
		return { ok = false, error = "Профиль ещё не загружен." }
	end
	applyCar(player)
	pushState(player)
	return { ok = true }
end

Remotes.GoProving.OnServerInvoke = function(player)
	local ok, message = goProving(player)
	return { ok = ok, error = if ok then nil else message }
end

Remotes.ReturnGarage.OnServerInvoke = function(player)
	local ok, message = goGarage(player)
	return { ok = ok, error = if ok then nil else message }
end

Remotes.Upright.OnServerInvoke = function(player)
	local session = sessions[player]
	if not session or session.mode ~= "proving" or not session.car then
		return { ok = false }
	end
	VehicleDriver.upright(session.car)
	seatPlayer(player, session.car)
	return { ok = true }
end

Remotes.Ghost.OnServerInvoke = function(_player)
	return { ok = false, error = GhostLap.status() }
end

local function refund(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	ProfileService.addMoney(player, amount)
	pendingCharge[player.UserId] = nil
	pushState(player)
	notify(player, "Взнос вернулся: гонка не стартовала.")
end

TeleportService.TeleportInitFailed:Connect(function(player, _result, errorMessage)
	local amount = pendingCharge[player.UserId]
	if amount then
		warn("[Гараж] телепорт не вышел: " .. tostring(errorMessage))
		refund(player, amount)
	end
end)

Remotes.Invite.OnServerInvoke = function(host, userIds)
	if typeof(userIds) ~= "table" then
		return { ok = false, error = "Некого звать." }
	end
	local unique = {}
	local party = { host }
	for _, userId in userIds do
		if typeof(userId) ~= "number" then
			continue
		end
		if userId == host.UserId or unique[userId] then
			continue
		end
		unique[userId] = true
		local friend = Players:GetPlayerByUserId(userId)
		if friend then
			table.insert(party, friend)
		end
	end
	if #party - 1 > Config.MAX_INVITES then
		return { ok = false, error = "Не больше четырёх друзей." }
	end
	if #party < 2 then
		return { ok = false, error = "Нужен хотя бы один друг на этом сервере." }
	end

	local accepted = { [host] = true }
	local waiting = #party - 1
	local inviteId = tostring(os.clock()) .. "_" .. tostring(host.UserId)
	local closed = false

	local function finishWait()
		waiting = 0
	end

	local connection = Remotes.InviteReply.OnServerEvent:Connect(function(player, replyId, accept)
		if replyId ~= inviteId or player == host or not table.find(party, player) then
			return
		end
		if accepted[player] ~= nil then
			return
		end
		accepted[player] = accept == true
		waiting -= 1
		if waiting <= 0 then
			finishWait()
		end
	end)

	for _, player in party do
		if player ~= host then
			Remotes.InvitePrompt:FireClient(player, {
				inviteId = inviteId,
				from = host.DisplayName,
				fee = Config.ENTRY_FEE,
			})
		end
	end

	local deadline = os.clock() + Config.INVITE_TIMEOUT
	while waiting > 0 and os.clock() < deadline do
		task.wait(0.2)
	end
	connection:Disconnect()
	if closed then
		return { ok = false, error = "Приглашение уже закрыто." }
	end
	closed = true

	local going = {}
	for _, player in party do
		if accepted[player] then
			table.insert(going, player)
		elseif player ~= host then
			notify(player, "Вы не едете на эту гонку.")
		end
	end
	if #going < 2 then
		notify(host, "Никто не принял приглашение.")
		return { ok = false, error = "Никто не принял." }
	end

	for _, player in going do
		local profile = ProfileService.get(player)
		if not profile or profile.money < Config.ENTRY_FEE then
			notify(host, player.DisplayName .. " без взноса.")
			return { ok = false, error = "Кому-то не хватает гоночных денег." }
		end
	end

	if Config.RACE_PLACE_ID == 0 then
		return {
			ok = false,
			error = "Впишите RACE_PLACE_ID в Config. ReserveServer работает только на опубликованном плейсе.",
		}
	end

	for _, player in going do
		local charged = ProfileService.mutate(player, function(data)
			if data.money < Config.ENTRY_FEE then
				return false
			end
			data.money -= Config.ENTRY_FEE
			return true
		end)
		if not charged then
			for _, other in going do
				if pendingCharge[other.UserId] then
					refund(other, pendingCharge[other.UserId])
				end
			end
			return { ok = false, error = "Не вышло снять взнос." }
		end
		pendingCharge[player.UserId] = Config.ENTRY_FEE
		pushState(player)
	end

	local racers = {}
	for _, player in going do
		local profile = ProfileService.get(player)
		table.insert(racers, {
			userId = player.UserId,
			name = player.DisplayName,
			speed = profile.speed,
			acceleration = profile.acceleration,
			grip = profile.grip,
			weight = profile.weight,
			color = profile.color,
		})
	end
	local teleportData = {
		feesPaid = true,
		fee = Config.ENTRY_FEE,
		racers = racers,
	}

	local reserveOk, codeOrErr = pcall(function()
		return TeleportService:ReserveServer(Config.RACE_PLACE_ID)
	end)
	if not reserveOk then
		for _, player in going do
			refund(player, Config.ENTRY_FEE)
		end
		return {
			ok = false,
			error = "ReserveServer не вышел. Нужен опубликованный плейс гонки в том же universe. " .. tostring(codeOrErr),
		}
	end

	local teleportOk, teleportErr = pcall(function()
		TeleportService:TeleportToPrivateServer(Config.RACE_PLACE_ID, codeOrErr, going, teleportData)
	end)
	if not teleportOk then
		for _, player in going do
			refund(player, Config.ENTRY_FEE)
		end
		return { ok = false, error = "Телепорт не вышел: " .. tostring(teleportErr) }
	end

	notify(host, "Сервер гонки зарезервирован, перевозим.")
	return { ok = true }
end

RunService.Heartbeat:Connect(function(dt)
	for player, session in sessions do
		if session.mode == "proving" then
			stepProving(player, session, dt)
		end
		local carriage = session.garage:FindFirstChild("LiftCarriage")
		if carriage and carriage:IsA("BasePart") then
			local rest = carriage:GetAttribute("RestY") or carriage.Position.Y
			local offset = 1.5 + math.sin(os.clock() * 0.4 + session.index) * 1.5
			carriage.CFrame = CFrame.new(carriage.Position.X, rest + offset, carriage.Position.Z)
				* (carriage.CFrame - carriage.Position)
		end
	end
end)

task.spawn(function()
	while true do
		roster()
		task.wait(2)
	end
end)

Players.PlayerAdded:Connect(giveGarage)
Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then
		if session.car then
			VehicleDriver.remove(session.car)
		end
		if session.garage then
			session.garage:Destroy()
		end
		sessions[player] = nil
	end
	roster()
end)

for _, player in Players:GetPlayers() do
	task.spawn(giveGarage, player)
end
