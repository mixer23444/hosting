-- Race place. Friends arrive through TeleportService:TeleportToPrivateServer.
-- Three laps, winner takes the pot, the rest get a small participation payout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Physics = require(Shared.Physics)
local CarBuilder = require(Shared.CarBuilder)
local RaceTrackBuilder = require(Shared.RaceTrackBuilder)
local Checkpoints = require(Shared.Checkpoints)
local VehicleDriver = require(Shared.VehicleDriver)
local ProfileService = require(script.Parent.ProfileService)

ProfileService.start()
VehicleDriver.bindServer()
Workspace.Gravity = 196.2
Workspace.FallenPartsDestroyHeight = -80

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

local RaceState = event("RaceState")
local Notify = event("Notify")
local Rematch = event("Rematch")
local LeaveRace = event("LeaveRace")
local Upright = func("Upright")

local track = RaceTrackBuilder.build(CFrame.new(0, 0, 0))
track.Parent = Workspace

local spawn = Instance.new("SpawnLocation")
spawn.Name = "RaceSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 1, 6)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.CanCollide = false
spawn.Transparency = 1
spawn.Parent = track

local gates = Checkpoints.readGates(track)
local gateCount = 0
for _ in gates do
	gateCount += 1
end

local racers: { [number]: any } = {}
local phase = "waiting"
local feesPaid = false
local fee = Config.ENTRY_FEE
local expected: { number }? = nil
local starterCount = 0
local raceBeganAt = 0
local countdownEnd = 0
local results = nil
local lastBroadcast = 0
local launchToken = 0
local waitStarted = 0

local function notify(player: Player, text: string)
	Notify:FireClient(player, text)
end

local function buildFrom(raw, fallback)
	local source = raw or fallback or {}
	return {
		speed = source.speed or 0,
		acceleration = source.acceleration or 0,
		grip = source.grip or 0,
		weight = source.weight or 0,
		color = source.color or 1,
	}
end

local function eachRacer()
	local list = {}
	for _, record in racers do
		table.insert(list, record)
	end
	return list
end

local function tuneOf(build)
	return Physics.publicTune(Physics.derive(build))
end

local function progress(record): number
	local gateScore = record.next - 1
	if record.next == 1 and record.started then
		gateScore = gateCount
	end
	return record.lap * (gateCount + 1) + gateScore
end

local function standings()
	local list = eachRacer()
	table.sort(list, function(a, b)
		if a.finished ~= b.finished then
			return a.finished
		end
		if a.finishTime and b.finishTime and a.finishTime ~= b.finishTime then
			return a.finishTime < b.finishTime
		end
		local pa = progress(a)
		local pb = progress(b)
		if pa ~= pb then
			return pa > pb
		end
		return a.distance < b.distance
	end)
	return list
end

local function snapshot()
	local rows = {}
	for place, record in ipairs(standings()) do
		local tune = tuneOf(record.build)
		table.insert(rows, {
			place = place,
			name = record.name,
			userId = record.userId,
			speed = record.build.speed,
			acceleration = record.build.acceleration,
			grip = record.build.grip,
			weight = record.build.weight,
			color = record.build.color,
			mass = tune.mass,
			maxSpeed = tune.maxSpeed,
			lateralGrip = tune.lateralGrip,
			lap = record.lap,
			finished = record.finished,
			finishTime = record.finishTime,
			ready = record.ready,
		})
	end
	local ready = 0
	local total = 0
	for _, record in racers do
		total += 1
		if record.ready then
			ready += 1
		end
	end
	return {
		phase = phase,
		laps = Config.LAPS,
		countdown = if phase == "grid" then math.max(0, countdownEnd - os.clock()) else 0,
		raceTime = if phase == "racing" then os.clock() - raceBeganAt else 0,
		feesPaid = feesPaid,
		fee = fee,
		results = results,
		ready = ready,
		total = total,
		racers = rows,
	}
end

local function broadcast(force: boolean?)
	if not force and os.clock() - lastBroadcast < 0.2 then
		return
	end
	lastBroadcast = os.clock()
	RaceState:FireAllClients(snapshot())
end

local function setLights(red: boolean)
	for _, descendant in track:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("StartLight") then
			descendant.Color = if red then Color3.fromRGB(150, 32, 28) else Color3.fromRGB(70, 150, 86)
			local light = descendant:FindFirstChildOfClass("PointLight")
			if light then
				light.Color = descendant.Color
				light.Brightness = if red then 0.7 else 1.4
			end
		end
	end
end

local function seatPlayer(player: Player, model: Model)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = model:FindFirstChild("Seat")
	if humanoid and seat and seat:IsA("VehicleSeat") then
		seat.Disabled = false
		task.defer(function()
			if seat.Parent and humanoid.Parent then
				seat:Sit(humanoid)
			end
		end)
	end
end

local function clearCars()
	for _, record in racers do
		if record.model then
			VehicleDriver.remove(record.model)
			record.model:Destroy()
			record.model = nil
		end
		record.lap = 0
		record.next = 1
		record.started = false
		record.finished = false
		record.finishTime = nil
		record.ready = false
		record.prev = nil
		record.distance = 9999
		record.clock = nil
	end
end

local function spawnGrid()
	clearCars()
	local ordered = eachRacer()
	table.sort(ordered, function(a, b)
		return a.userId < b.userId
	end)
	for index, record in ipairs(ordered) do
		local slot = track:FindFirstChild("Grid" .. tostring(math.clamp(index, 1, 5)))
		if not slot or not slot:IsA("BasePart") then
			continue
		end
		local model = CarBuilder.spawn(record.build, slot.CFrame, true)
		model.Name = "RaceCar_" .. tostring(record.userId)
		model.Parent = track
		VehicleDriver.add(model)
		record.model = model
		local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("SitPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
			prompt.Triggered:Connect(function(who)
				if who == record.player and record.model then
					seatPlayer(record.player, record.model)
				end
			end)
		end
		seatPlayer(record.player, model)
	end
end

local function launch()
	phase = "racing"
	raceBeganAt = os.clock()
	results = nil
	setLights(false)
	local count = 0
	for _, record in racers do
		if record.model and record.player.Parent then
			count += 1
			CarBuilder.setParked(record.model, false)
			record.prev = record.model.PrimaryPart.Position
			local prompt = record.model.PrimaryPart:FindFirstChild("SitPrompt")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = true
			end
		end
	end
	starterCount = math.max(count, starterCount)
	broadcast(true)
end

local function beginGrid()
	if phase == "grid" or phase == "racing" then
		return
	end
	launchToken += 1
	local token = launchToken
	phase = "grid"
	results = nil
	setLights(true)
	spawnGrid()
	countdownEnd = os.clock() + Config.GRID_COUNTDOWN
	broadcast(true)
	task.spawn(function()
		while phase == "grid" and token == launchToken do
			if os.clock() >= countdownEnd then
				launch()
				return
			end
			broadcast(true)
			task.wait(0.2)
		end
	end)
end

local function connectedRecords()
	local list = {}
	for _, record in racers do
		if record.player.Parent then
			table.insert(list, record)
		end
	end
	return list
end

local function payAndPublish()
	local ranked = standings()
	local winner = nil
	for _, record in ipairs(ranked) do
		if record.finished then
			winner = record
			break
		end
	end
	local pot = if feesPaid then fee * math.max(starterCount, 1) else 0
	local payouts = {}
	for place, record in ipairs(ranked) do
		local amount = 0
		if feesPaid and record.player.Parent then
			if winner and record == winner then
				amount = pot
			else
				amount = Config.PARTICIPATION
			end
			ProfileService.addMoney(record.player, amount)
		end
		table.insert(payouts, {
			name = record.name,
			amount = amount,
			place = place,
			finished = record.finished,
			time = record.finishTime,
		})
	end
	results = {
		payouts = payouts,
		pot = pot,
		feesPaid = feesPaid,
		winner = if winner then winner.name else nil,
	}
	phase = "results"
	for _, record in racers do
		if record.model then
			CarBuilder.setParked(record.model, true)
		end
	end
	broadcast(true)
end

local function everyoneFinished(): boolean
	local any = false
	for _, record in racers do
		if record.player.Parent and record.model then
			any = true
			if not record.finished then
				return false
			end
		end
	end
	return any
end

local function advance(record)
	if record.next == 1 then
		if not record.started then
			record.started = true
			record.clock = os.clock()
			record.next = 2
			return
		end
		record.lap += 1
		if record.lap >= Config.LAPS then
			record.finished = true
			record.finishTime = os.clock() - (record.clock or os.clock())
		else
			record.next = 2
		end
		return
	end
	record.next += 1
	if record.next > gateCount then
		record.next = 1
	end
end

local function maybeStart()
	if phase ~= "waiting" then
		return
	end
	if expected then
		for _, userId in expected do
			if not racers[userId] then
				if os.clock() - waitStarted < 15 then
					return
				end
				break
			end
		end
		local count = 0
		for _ in racers do
			count += 1
		end
		if count >= 1 then
			beginGrid()
		end
		return
	end
	if os.clock() - waitStarted >= 2 then
		beginGrid()
	end
end

local function readJoin(player: Player)
	local join = player:GetJoinData()
	local data = join and join.TeleportData
	if typeof(data) ~= "table" or typeof(data.racers) ~= "table" then
		return nil
	end
	feesPaid = data.feesPaid == true
	if typeof(data.fee) == "number" then
		fee = data.fee
	end
	if not expected then
		expected = {}
		for _, racer in data.racers do
			if typeof(racer) == "table" and typeof(racer.userId) == "number" then
				table.insert(expected, racer.userId)
			end
		end
	end
	for _, racer in data.racers do
		if typeof(racer) == "table" and racer.userId == player.UserId then
			return racer
		end
	end
	return nil
end

local function addPlayer(player: Player)
	if racers[player.UserId] then
		return
	end
	ProfileService.load(player)
	if waitStarted == 0 then
		waitStarted = os.clock()
	end
	local joined = readJoin(player)
	local profile = ProfileService.get(player)
	local build = buildFrom(joined, profile)
	racers[player.UserId] = {
		player = player,
		userId = player.UserId,
		name = player.DisplayName,
		build = build,
		lap = 0,
		next = 1,
		started = false,
		finished = false,
		finishTime = nil,
		ready = false,
		prev = nil,
		model = nil,
		distance = 9999,
		clock = nil,
	}
	if not joined and not expected then
		notify(player, "Studio-заезд: взнос не снимается и банк не платится. Друзей зовут из гаража.")
	end
	if phase == "waiting" then
		task.delay(0.5, maybeStart)
	else
		notify(player, "Гонка уже идёт. Дождитесь реванша.")
	end
	broadcast(true)
end

Rematch.OnServerEvent:Connect(function(player)
	local record = racers[player.UserId]
	if not record or phase ~= "results" then
		return
	end
	record.ready = true
	local pending = connectedRecords()
	local allReady = true
	for _, other in pending do
		if not other.ready then
			allReady = false
		end
	end
	broadcast(true)
	if not allReady then
		return
	end
	if #pending < 1 then
		return
	end
	if feesPaid and #pending < 2 then
		notify(player, "Для реванша со взносом нужны двое.")
		record.ready = false
		broadcast(true)
		return
	end
	if feesPaid then
		for _, other in pending do
			local profile = ProfileService.get(other.player)
			if not profile or profile.money < fee then
				notify(other.player, "Не хватает гоночных денег на реванш.")
				other.ready = false
				broadcast(true)
				return
			end
		end
		for _, other in pending do
			local charged = ProfileService.mutate(other.player, function(data)
				if data.money < fee then
					return false
				end
				data.money -= fee
				return true
			end)
			if not charged then
				notify(other.player, "Взнос на реванш не снялся.")
				return
			end
		end
		starterCount = #pending
	end
	-- Drop anyone who left. Rebuild the active map from whoever is still here.
	local keep = {}
	for _, other in pending do
		keep[other.userId] = other
	end
	for userId, other in racers do
		if not keep[userId] then
			if other.model then
				VehicleDriver.remove(other.model)
				other.model:Destroy()
			end
			racers[userId] = nil
		end
	end
	phase = "waiting"
	results = nil
	beginGrid()
end)

LeaveRace.OnServerEvent:Connect(function(player)
	if Config.GARAGE_PLACE_ID == 0 then
		notify(player, "Впишите GARAGE_PLACE_ID в Config, чтобы вернуться в гараж.")
		return
	end
	local ok, err = pcall(function()
		TeleportService:Teleport(Config.GARAGE_PLACE_ID, player)
	end)
	if not ok then
		notify(player, "Телепорт в гараж не вышел: " .. tostring(err))
	end
end)

Upright.OnServerInvoke = function(player)
	local record = racers[player.UserId]
	if not record or not record.model or phase ~= "racing" then
		return { ok = false }
	end
	VehicleDriver.upright(record.model)
	seatPlayer(player, record.model)
	return { ok = true }
end

RunService.Heartbeat:Connect(function()
	if phase == "waiting" then
		maybeStart()
	end
	if phase ~= "racing" then
		return
	end
	for _, record in racers do
		local model = record.model
		local chassis = model and model.PrimaryPart
		if record.finished or not chassis or not record.player.Parent then
			continue
		end
		if chassis.Position.Y < -15 then
			local slot = track:FindFirstChild("Grid1")
			if slot and slot:IsA("BasePart") then
				model:PivotTo(slot.CFrame + Vector3.new(0, 1, 0))
				chassis.AssemblyLinearVelocity = Vector3.zero
				record.prev = nil
			end
			continue
		end
		local pos = chassis.Position
		if record.prev then
			local gate = gates[record.next]
			if gate and Checkpoints.crossed(record.prev, pos, gate.cframe, gate.halfWidth) then
				advance(record)
			end
			local upcoming = gates[record.next]
			if upcoming then
				record.distance = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(upcoming.cframe.Position.X, 0, upcoming.cframe.Position.Z)).Magnitude
			end
		end
		record.prev = pos
	end
	if everyoneFinished() or os.clock() - raceBeganAt > Config.RACE_TIMEOUT then
		payAndPublish()
		return
	end
	broadcast(false)
end)

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	local record = racers[player.UserId]
	if record and record.model then
		VehicleDriver.remove(record.model)
		record.model:Destroy()
		record.model = nil
	end
	broadcast(true)
end)

for _, player in Players:GetPlayers() do
	task.spawn(addPlayer, player)
end
