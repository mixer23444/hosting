-- Vehicle tune. Upgrades change mass, tire friction, and wheel torque.
-- They are not a hidden speed multiplier.
--
-- weight 0 is the heavy car: slow off the line, holds a corner.
-- weight 5 is the light car: quick on the straight, loose when the wheel is turned.
-- Cosmetic paint never enters this function.

local Config = require(script.Parent.Config)

local Physics = {}

local function clampLevel(value: number): number
	return math.clamp(math.floor(value + 0.5), 0, Config.MAX_LEVEL)
end

function Physics.derive(build)
	local lightness = clampLevel(build.weight) / Config.MAX_LEVEL
	local speed = clampLevel(build.speed)
	local accel = clampLevel(build.acceleration)
	local grip = clampLevel(build.grip)

	local heavyMass = 58
	local lightMass = 30
	local mass = heavyMass + (lightMass - heavyMass) * lightness

	-- Tire bite. Lightness trims the contact patch; grip buys it back.
	local friction = math.clamp(0.85 + grip * 0.12 - lightness * 0.28, 0.42, 1.65)
	local frictionWeight = math.clamp(0.7 + grip * 0.14 + (1 - lightness) * 0.55, 0.45, 2.2)

	-- Torque stays independent of mass, so the same motor loses the start in a heavy car.
	local torque = 480 + accel * 260 + speed * 30

	local maxSpeed = (58 + speed * 8) * (1 + lightness * 0.1)
	local dragCoeff = 0.1 * (1 - speed * 0.09) * (1 - lightness * 0.2)
	dragCoeff = math.max(0.028, dragCoeff)

	-- How fast sideways speed is scrubbed off, per second.
	-- Heavy and high grip scrub it. A light car keeps the slide.
	local lateralGrip = (1.6 + grip * 1.05) * (1.35 - 0.85 * lightness)

	local steerAngle = 26 + lightness * 5 - grip * 0.3

	return {
		mass = mass,
		friction = friction,
		frictionWeight = frictionWeight,
		torque = torque,
		maxSpeed = maxSpeed,
		dragCoeff = dragCoeff,
		lateralGrip = lateralGrip,
		steerAngle = steerAngle,
		lightness = lightness,
		wheelRadius = Config.WHEEL_RADIUS,
	}
end

function Physics.publicTune(tune)
	return {
		mass = math.floor(tune.mass * 10) / 10,
		torque = math.floor(tune.torque),
		maxSpeed = math.floor(tune.maxSpeed + 0.5),
		lateralGrip = math.floor(tune.lateralGrip * 10) / 10,
		friction = math.floor(tune.friction * 100) / 100,
		lightness = math.floor(tune.lightness * 100) / 100,
	}
end

return Physics
