-- Stub. The proving pad and the friend race are the playable paths.
-- A later pass can store CFrame samples and play a translucent chassis.

local GhostLap = {}

function GhostLap.status(): string
	return "Призрачный круг ещё не пишется. Полигон и гонка с друзьями уже работают."
end

function GhostLap.recordSample(_sample): boolean
	return false
end

function GhostLap.playback(): nil
	return nil
end

return GhostLap
