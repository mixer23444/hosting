-- Place ids stay 0 until both places are published into one universe.
-- ReserveServer only works on a published place. Studio play does not reserve a server.

local Config = {
	MAX_LEVEL = 5,
	STARTING_MONEY = 500,
	ENTRY_FEE = 100,
	PARTICIPATION = 30,
	LAPS = 3,
	MAX_INVITES = 4,
	RACE_PLACE_ID = 0,
	GARAGE_PLACE_ID = 0,
	DATASTORE = "GarazhProfile_v1",

	WHEEL_RADIUS = 1.15,
	CHASSIS_Y = 1.7,
	ACCEL_MARK = 48,
	STEER_SIGN = -1,
	DRIVE_SIGN = -1,

	INVITE_TIMEOUT = 20,
	RACE_TIMEOUT = 240,
	GRID_COUNTDOWN = 6,

	STATS = { "speed", "acceleration", "grip", "weight" },

	COSTS = {
		speed = { 150, 350, 700, 1200, 2000 },
		acceleration = { 150, 350, 700, 1200, 2000 },
		grip = { 120, 280, 560, 1000, 1700 },
		weight = { 180, 400, 800, 1400, 2300 },
	},

	STAT_LABEL = {
		speed = "Скорость",
		acceleration = "Разгон",
		grip = "Держак",
		weight = "Масса",
	},

	STAT_HINT = {
		speed = "Выше потолок на прямой и меньше сопротивление.",
		acceleration = "Больше момент на колёсах. Массу не прибавляет.",
		grip = "Шина держит бок. Цвет кузова сюда не входит.",
		weight = "Облегчение: резче со старта, свободнее в дуге.",
	},

	PALETTE = {
		{ name = "Графит", color = Color3.fromRGB(42, 46, 51) },
		{ name = "Белый", color = Color3.fromRGB(226, 228, 230) },
		{ name = "Красный", color = Color3.fromRGB(148, 28, 28) },
		{ name = "Синий", color = Color3.fromRGB(28, 58, 120) },
		{ name = "Серебро", color = Color3.fromRGB(168, 172, 176) },
		{ name = "Зелёный", color = Color3.fromRGB(24, 72, 48) },
		{ name = "Чёрный", color = Color3.fromRGB(16, 16, 18) },
	},
}

function Config.cost(stat: string, level: number): number?
	local row = Config.COSTS[stat]
	if not row then
		return nil
	end
	if level < 0 or level >= Config.MAX_LEVEL then
		return nil
	end
	return row[level + 1]
end

function Config.paletteColor(index: number): Color3
	local entry = Config.PALETTE[index]
	if not entry then
		entry = Config.PALETTE[1]
	end
	return entry.color
end

return Config
