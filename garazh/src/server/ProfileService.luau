-- Money and the four upgrade tracks. A published server shares one DataStore.
-- Studio Play on an unpublished place must not call DataStoreService at all:
-- GetDataStore halts Play on "publish this place" even inside pcall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ProfileService = {}

local store = nil
local cache: { [Player]: { data: { [string]: any }, sessionOnly: boolean, key: string } } = {}
local started = false

local function keyFor(player: Player): string
	return "u_" .. tostring(player.UserId)
end

local function defaultData()
	return {
		money = Config.STARTING_MONEY,
		speed = 0,
		acceleration = 0,
		grip = 0,
		weight = 0,
		color = 1,
	}
end

local function sanitize(raw): { [string]: any }
	local data = defaultData()
	if typeof(raw) ~= "table" then
		return data
	end
	if typeof(raw.money) == "number" and raw.money == raw.money then
		data.money = math.max(0, math.floor(raw.money))
	end
	for _, stat in Config.STATS do
		local value = raw[stat]
		if typeof(value) == "number" then
			data[stat] = math.clamp(math.floor(value), 0, Config.MAX_LEVEL)
		end
	end
	if typeof(raw.color) == "number" then
		data.color = math.clamp(math.floor(raw.color), 1, #Config.PALETTE)
	end
	return data
end

local function save(entry): boolean
	if entry.sessionOnly or not store then
		return true
	end
	local ok, err = pcall(function()
		store:SetAsync(entry.key, entry.data)
	end)
	if not ok then
		warn("[Гараж] не записал профиль: " .. tostring(err))
	end
	return ok
end

function ProfileService.load(player: Player)
	local key = keyFor(player)
	local sessionOnly = false
	local data = defaultData()
	if store then
		local ok, result = pcall(function()
			return store:GetAsync(key)
		end)
		if ok then
			data = sanitize(result)
		else
			sessionOnly = true
			warn("[Гараж] DataStore недоступен, деньги только на эту сессию: " .. tostring(result))
		end
	else
		sessionOnly = true
	end
	cache[player] = {
		data = data,
		sessionOnly = sessionOnly,
		key = key,
	}
	return data
end

function ProfileService.get(player: Player)
	local entry = cache[player]
	if not entry then
		return nil
	end
	return table.clone(entry.data)
end

function ProfileService.sessionOnly(player: Player): boolean
	local entry = cache[player]
	return entry ~= nil and entry.sessionOnly
end

function ProfileService.mutate(player: Player, fn): boolean
	local entry = cache[player]
	if not entry then
		return false
	end
	local copy = table.clone(entry.data)
	local result = fn(copy)
	if result == false then
		return false
	end
	entry.data = sanitize(copy)
	save(entry)
	return true
end

function ProfileService.addMoney(player: Player, delta: number): number
	local entry = cache[player]
	if not entry then
		ProfileService.load(player)
		entry = cache[player]
	end
	if not entry then
		return 0
	end
	if entry.sessionOnly or not store then
		entry.data.money = math.max(0, math.floor(entry.data.money + delta))
		return entry.data.money
	end
	local newMoney = entry.data.money
	local ok, err = pcall(function()
		store:UpdateAsync(entry.key, function(old)
			local data = sanitize(old)
			for _, stat in Config.STATS do
				data[stat] = math.max(data[stat], entry.data[stat])
			end
			data.color = entry.data.color
			data.money = math.max(0, data.money + delta)
			newMoney = data.money
			entry.data = data
			return data
		end)
	end)
	if not ok then
		warn("[Гараж] не начислил деньги: " .. tostring(err))
		entry.data.money = math.max(0, math.floor(entry.data.money + delta))
		return entry.data.money
	end
	return newMoney
end

function ProfileService.release(player: Player)
	local entry = cache[player]
	if entry then
		save(entry)
		cache[player] = nil
	end
end

function ProfileService.start()
	if started then
		return
	end
	started = true
	-- PlaceId/GameId are 0 until the place is published. Do not touch DataStore there.
	local published = game.PlaceId ~= 0 and game.GameId ~= 0
	if RunService:IsStudio() or not published then
		store = nil
	else
		local ok, result = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore(Config.DATASTORE)
		end)
		if ok and result ~= nil then
			store = result
		else
			store = nil
			if not ok then
				warn("[Гараж] DataStore не открылся, играем в памяти: " .. tostring(result))
			end
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		ProfileService.release(player)
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			ProfileService.release(player)
		end
	end)
end

return ProfileService
