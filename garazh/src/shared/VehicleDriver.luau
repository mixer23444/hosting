-- Server-side wheel motor, drag, and lateral grip.
-- ThrottleFloat / SteerFloat come from the VehicleSeat the occupant drives.
-- Network ownership stays on the server so this loop is the only force.

local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)

local VehicleDriver = {}

local cars: { [Model]: boolean } = {}
local bound = false

local function attr(model: Model, name: string, fallback: number): number
	local value = model:GetAttribute(name)
	if typeof(value) == "number" then
		return value
	end
	return fallback
end

function VehicleDriver.applyAttributes(model: Model, tune)
	model:SetAttribute("Torque", tune.torque)
	model:SetAttribute("MaxSpeed", tune.maxSpeed)
	model:SetAttribute("DragCoeff", tune.dragCoeff)
	model:SetAttribute("SteerAngle", tune.steerAngle)
	model:SetAttribute("LateralGrip", tune.lateralGrip)
	model:SetAttribute("WheelRadius", tune.wheelRadius)
	model:SetAttribute("Friction", tune.friction)
	model:SetAttribute("FrictionWeight", tune.frictionWeight)
	model:SetAttribute("Mass", tune.mass)
end

function VehicleDriver.step(model: Model, dt: number)
	if model:GetAttribute("Drive") ~= true then
		return
	end
	local chassis = model.PrimaryPart
	local seat = model:FindFirstChild("Seat")
	if not chassis or not chassis:IsA("BasePart") or not seat or not seat:IsA("VehicleSeat") then
		return
	end
	if chassis.Anchored then
		return
	end

	local throttle = seat.ThrottleFloat
	local steer = seat.SteerFloat
	local radius = attr(model, "WheelRadius", Config.WHEEL_RADIUS)
	local maxSpeed = attr(model, "MaxSpeed", 60)
	local torque = attr(model, "Torque", 500)
	local dragCoeff = attr(model, "DragCoeff", 0.08)
	local lateralGrip = attr(model, "LateralGrip", 2)
	local steerAngle = attr(model, "SteerAngle", 28)
	local maxAv = maxSpeed / radius

	local constraints = model:FindFirstChild("Constraints")
	if constraints then
		for _, constraint in constraints:GetChildren() do
			if constraint:IsA("HingeConstraint") then
				local role = constraint:GetAttribute("Role")
				if role == "drive" then
					local share = constraint:GetAttribute("Share") or 0.25
					if math.abs(throttle) > 0.05 then
						constraint.MotorMaxTorque = torque * share
						constraint.AngularVelocity = Config.DRIVE_SIGN * throttle * maxAv
					else
						constraint.MotorMaxTorque = torque * share * 0.12
						constraint.AngularVelocity = 0
					end
				elseif role == "steer" then
					constraint.TargetAngle = Config.STEER_SIGN * steer * steerAngle
				end
			end
		end
	end

	local velocity = chassis.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	local mass = chassis.AssemblyMass

	if speed > 0.4 and mass > 0 then
		local dragForce = dragCoeff * speed * speed
		chassis:ApplyImpulse(-flat.Unit * dragForce * dt)
	end

	local right = Vector3.new(chassis.CFrame.RightVector.X, 0, chassis.CFrame.RightVector.Z)
	if speed > 1 and right.Magnitude > 0.05 and mass > 0 then
		right = right.Unit
		local lateral = flat:Dot(right)
		local keep = math.clamp(1 - lateralGrip * dt, 0, 1)
		local remove = lateral * (1 - keep)
		chassis:ApplyImpulse(-right * remove * mass)
	end

	-- Hard ceiling so a modified client cannot run away with the server car.
	if speed > maxSpeed * 1.06 then
		local clamped = flat.Unit * maxSpeed * 1.06
		chassis.AssemblyLinearVelocity = Vector3.new(clamped.X, velocity.Y, clamped.Z)
	end
end

function VehicleDriver.add(model: Model)
	cars[model] = true
end

function VehicleDriver.remove(model: Model)
	cars[model] = nil
end

function VehicleDriver.bindServer()
	if bound then
		return
	end
	if not RunService:IsServer() then
		return
	end
	bound = true
	RunService.Heartbeat:Connect(function(dt)
		for model in cars do
			if model.Parent then
				VehicleDriver.step(model, dt)
			else
				cars[model] = nil
			end
		end
	end)
end

function VehicleDriver.upright(model: Model)
	local chassis = model.PrimaryPart
	if not chassis or not chassis:IsA("BasePart") then
		return
	end
	local position = chassis.Position + Vector3.new(0, 2.2, 0)
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	if look.Magnitude < 0.2 then
		look = Vector3.new(0, 0, -1)
	end
	model:PivotTo(CFrame.lookAt(position, position + look.Unit))
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
end

return VehicleDriver
