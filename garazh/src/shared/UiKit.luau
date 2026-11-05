local Players = game:GetService("Players")

local UiKit = {}

UiKit.BG = Color3.fromRGB(16, 17, 19)
UiKit.PANEL = Color3.fromRGB(28, 30, 34)
UiKit.PANEL_SOFT = Color3.fromRGB(38, 40, 45)
UiKit.ACCENT = Color3.fromRGB(214, 162, 74)
UiKit.TEXT = Color3.fromRGB(236, 236, 234)
UiKit.MUTED = Color3.fromRGB(154, 156, 160)
UiKit.DANGER = Color3.fromRGB(164, 72, 62)
UiKit.OK = Color3.fromRGB(92, 138, 98)
UiKit.FONT = Enum.Font.GothamMedium
UiKit.FONT_BOLD = Enum.Font.GothamBold

function UiKit.screen(name: string): ScreenGui
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

function UiKit.frame(parent: Instance, props): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.name or "Frame"
	frame.Size = props.size or UDim2.fromScale(1, 1)
	frame.Position = props.position or UDim2.fromScale(0, 0)
	frame.AnchorPoint = props.anchor or Vector2.zero
	frame.BackgroundColor3 = props.color or UiKit.PANEL
	frame.BackgroundTransparency = props.transparency or 0
	frame.BorderSizePixel = 0
	frame.Visible = if props.visible == nil then true else props.visible
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, props.radius or 8)
	corner.Parent = frame
	if props.pad then
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, props.pad)
		padding.PaddingBottom = UDim.new(0, props.pad)
		padding.PaddingLeft = UDim.new(0, props.pad)
		padding.PaddingRight = UDim.new(0, props.pad)
		padding.Parent = frame
	end
	return frame
end

function UiKit.label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = UiKit.FONT
	label.TextSize = size
	label.TextColor3 = color or UiKit.TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = text
	label.Size = UDim2.new(1, 0, 0, size + 8)
	label.Parent = parent
	return label
end

function UiKit.button(parent: Instance, text: string): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Font = UiKit.FONT_BOLD
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(24, 22, 18)
	button.BackgroundColor3 = UiKit.ACCENT
	button.BorderSizePixel = 0
	button.Text = text
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

function UiKit.stroke(parent: Instance, color: Color3?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(64, 66, 72)
	stroke.Thickness = 1
	stroke.Parent = parent
	return stroke
end

return UiKit
