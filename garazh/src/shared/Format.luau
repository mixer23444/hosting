local Format = {}

function Format.money(amount: number): string
	return string.format("%d кр.", math.floor(amount + 0.5))
end

function Format.seconds(seconds: number?): string
	if seconds == nil then
		return "—"
	end
	return string.format("%.1f с", seconds)
end

function Format.speed(studsPerSecond: number): string
	return string.format("%d", math.floor(studsPerSecond + 0.5))
end

function Format.percent(unit: number): string
	return string.format("%d%%", math.floor(math.clamp(unit, 0, 1) * 100 + 0.5))
end

return Format
