-- Shared records for the garage, the proving pad, and the race place.

export type Build = {
	speed: number,
	acceleration: number,
	grip: number,
	weight: number,
	color: number,
}

export type Tune = {
	mass: number,
	friction: number,
	frictionWeight: number,
	torque: number,
	maxSpeed: number,
	dragCoeff: number,
	lateralGrip: number,
	steerAngle: number,
	lightness: number,
	wheelRadius: number,
}

export type PublicTune = {
	mass: number,
	torque: number,
	maxSpeed: number,
	lateralGrip: number,
	friction: number,
	lightness: number,
}

return nil
