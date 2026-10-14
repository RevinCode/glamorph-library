local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Glamorph = {}
Glamorph.Version = "0.1.0"
Glamorph.Windows = {}

Glamorph.Theme = {
	Background = Color3.fromRGB(16, 16, 21),
	BackgroundTransparency = 0.12,
	TopBarTransparency = 1,
	TitleColor = Color3.fromRGB(255, 255, 255),
	SubtitleColor = Color3.fromRGB(150, 152, 165),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.87,
	DividerTransparency = 0.9,
	ContentBackground = Color3.fromRGB(255, 255, 255),
	ContentTransparency = 0.96,
	ControlIdle = Color3.fromRGB(255, 255, 255),
	ControlIdleTransparency = 0.92,
	ControlHover = 0.82,
	CloseHover = Color3.fromRGB(255, 95, 95),
	CornerMain = 12,
	CornerSmall = 8,
	TweenTime = 0.28,
	TweenStyle = Enum.EasingStyle.Quint,
	TweenDirection = Enum.EasingDirection.Out
}

local function New(className, properties, children)
	local obj = Instance.new(className)
	for k, v in pairs(properties) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = obj
		end
	end
	obj.Parent = properties.Parent
	return obj
end

local function ApplyCorner(parent, radius)
	return New("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent
	})
end

local function ApplyStroke(parent, color, transparency, thickness)
	return New("UIStroke", {
		Color = color,
		Transparency = transparency,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
end

local function Tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function TweenInfoDefault(time)
	return TweenInfo.new(time or 0.28, Glamorph.Theme.TweenStyle, Glamorph.Theme.TweenDirection)
end

local function MakeDraggable(handle, target)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new(0, 0, 0, 0)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function GetGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local player = Players.LocalPlayer
	if player then
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if pg then
			return pg
		end
	end
	return CoreGui
end

local function BuildControlButton(parent, text, layoutOrder, isClose)
	local btn = New("TextButton", {
		Name = isClose and "Close" or "Minimize",
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundColor3 = Glamorph.Theme.ControlIdle,
		BackgroundTransparency = Glamorph.Theme.ControlIdleTransparency,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(220, 221, 228),
		LayoutOrder = layoutOrder,
		AutoButtonColor = false,
		Parent = parent
	})
	ApplyCorner(btn, Glamorph.Theme.CornerSmall)
	local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	btn.MouseEnter:Connect(function()
		if isClose then
			Tween(btn, info, { BackgroundColor3 = Glamorph.Theme.CloseHover, BackgroundTransparency = 0.15, TextColor3 = Color3.fromRGB(255, 255, 255) })
		else
			Tween(btn, info, { BackgroundTransparency = Glamorph.Theme.ControlHover, TextColor3 = Color3.fromRGB(255, 255, 255) })
		end
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, info, { BackgroundColor3 = Glamorph.Theme.ControlIdle, BackgroundTransparency = Glamorph.Theme.ControlIdleTransparency, TextColor3 = Color3.fromRGB(220, 221, 228) })
	end)
	return btn
end

function Glamorph:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Glamorph"
	local subtitle = config.Subtitle or "v0.1.0"
	local size = config.Size or UDim2.new(0, 580, 0, 380)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	local topHeight = 52

	local guiParent = GetGuiParent()
	local screenGui = New("ScreenGui", {
		Name = "GlamorphGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = guiParent
	})

	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = self.Theme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	})
	ApplyCorner(main, self.Theme.CornerMain)
	local mainStroke = ApplyStroke(main, self.Theme.StrokeColor, 1, 1)

	local sheen = New("Frame", {
		Name = "Sheen",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		Parent = main
	})
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Rotation = 0,
		Parent = sheen
	})

	local topBar = New("Frame", {
		Name = "TopBar",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, topHeight),
		BackgroundTransparency = self.Theme.TopBarTransparency,
		BorderSizePixel = 0,
		Parent = main
	})

	local titleHolder = New("Frame", {
		Name = "TitleHolder",
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Parent = topBar
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleHolder
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		Parent = titleHolder
	})

	local titleLabel = New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = self.Theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = titleHolder
	})

	local subLabel = New("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.new(1, 0, 0, 15),
		BackgroundTransparency = 1,
		Text = subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self.Theme.SubtitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = titleHolder
	})

	local controls = New("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 28),
		BackgroundTransparency = 1,
		Parent = topBar
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = controls
	})

	local minimizeBtn = BuildControlButton(controls, "_", 1, false)
	local closeBtn = BuildControlButton(controls, "X", 2, true)
	minimizeBtn.TextSize = 16
	minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
	closeBtn.TextSize = 12

	local divider = New("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, 18, 0, topHeight - 1),
		Size = UDim2.new(1, -36, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = self.Theme.DividerTransparency,
		BorderSizePixel = 0,
		Parent = main
	})

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 14, 0, topHeight + 8),
		Size = UDim2.new(1, -28, 1, -(topHeight + 22)),
		BackgroundColor3 = self.Theme.ContentBackground,
		BackgroundTransparency = self.Theme.ContentTransparency,
		BorderSizePixel = 0,
		Parent = main
	})
	ApplyCorner(content, self.Theme.CornerSmall)
	ApplyStroke(content, self.Theme.StrokeColor, 0.92, 1)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = content
	})

	MakeDraggable(topBar, main)
	MakeDraggable(titleHolder, main)

	local window = {}
	window.Gui = screenGui
	window.Main = main
	window.TopBar = topBar
	window.Content = content
	window.Minimized = false
	window.Hidden = false
	window.Destroyed = false
	window.FullSize = size
	window.TopHeight = topHeight

	local openInfo = TweenInfo.new(self.Theme.TweenTime + 0.07, self.Theme.TweenStyle, self.Theme.TweenDirection)
	Tween(main, openInfo, { Size = size, BackgroundTransparency = self.Theme.BackgroundTransparency })
	Tween(mainStroke, openInfo, { Transparency = self.Theme.StrokeTransparency })

	function window:SetTitle(t)
		titleLabel.Text = t
	end

	function window:SetSubtitle(t)
		subLabel.Text = t
	end

	function window:SetSize(s)
		self.FullSize = s
		if not self.Minimized then
			Tween(self.Main, TweenInfoDefault(0.3), { Size = s })
		end
	end

	function window:Minimize(state)
		if self.Destroyed then
			return
		end
		local shouldMin = if state == nil then not self.Minimized else state
		self.Minimized = shouldMin
		if shouldMin then
			Tween(self.Main, TweenInfoDefault(0.3), { Size = UDim2.new(self.FullSize.X.Scale, self.FullSize.X.Offset, 0, self.TopHeight) })
			Tween(content, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
			task.delay(0.18, function()
				if self.Minimized and not self.Destroyed then
					content.Visible = false
					divider.Visible = false
				end
			end)
			minimizeBtn.Text = "+"
		else
			content.Visible = true
			divider.Visible = true
			Tween(self.Main, TweenInfoDefault(0.3), { Size = self.FullSize })
			Tween(content, TweenInfo.new(0.3), { BackgroundTransparency = self.Theme.ContentTransparency })
			minimizeBtn.Text = "_"
		end
	end

	function window:Show()
		if self.Destroyed then
			return
		end
		self.Hidden = false
		screenGui.Enabled = true
		main.Visible = true
		Tween(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = self.Theme.BackgroundTransparency })
	end

	function window:Hide()
		if self.Destroyed then
			return
		end
		self.Hidden = true
		local tw = Tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
		tw.Completed:Wait()
		if self.Hidden then
			main.Visible = false
		end
	end

	function window:Toggle()
		if self.Hidden then
			self:Show()
		else
			self:Hide()
		end
	end

	function window:Close()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		local info = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(main, info, { Size = UDim2.new(0, self.Main.Size.X.Offset - 20, 0, self.Main.Size.Y.Offset - 20), BackgroundTransparency = 1 })
		Tween(mainStroke, info, { Transparency = 1 })
		task.wait(0.24)
		screenGui:Destroy()
		local idx = table.find(Glamorph.Windows, self)
		if idx then
			table.remove(Glamorph.Windows, idx)
		end
	end

	minimizeBtn.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		window:Close()
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == toggleKey and not window.Destroyed then
			window:Toggle()
		end
	end)

	table.insert(self.Windows, window)
	return window
end

return Glamorph
