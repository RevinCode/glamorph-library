local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Glamorph = {}
Glamorph.Version = "0.2.0"
Glamorph.Windows = {}

Glamorph.Theme = {
	Background = Color3.fromRGB(13, 13, 18),
	BackgroundTransparency = 0.08,
	TitleColor = Color3.fromRGB(245, 245, 248),
	SubtitleColor = Color3.fromRGB(148, 150, 164),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.84,
	SheenTransparency = 0.7,
	DividerTransparency = 0.9,
	ContentBackground = Color3.fromRGB(255, 255, 255),
	ContentTransparency = 0.965,
	ContentStrokeTransparency = 0.92,
	ControlIdle = Color3.fromRGB(255, 255, 255),
	ControlIdleTransparency = 0.94,
	ControlHoverTransparency = 0.85,
	CloseHover = Color3.fromRGB(242, 85, 90),
	CloseHoverTransparency = 0.12,
	IconColor = Color3.fromRGB(200, 201, 212),
	IconHover = Color3.fromRGB(255, 255, 255),
	AccentLight = Color3.fromRGB(139, 139, 255),
	AccentDark = Color3.fromRGB(91, 91, 214),
	CornerMain = 14,
	CornerContent = 10,
	CornerControl = 9,
	OpenTime = 0.42,
	CollapseTime = 0.32
}

Glamorph.Icons = {
	Close = "",
	Minimize = "",
	Restore = ""
}

function Glamorph.SetIcon(kind, assetId)
	Glamorph.Icons[kind] = assetId or ""
end

local function New(className, properties)
	local obj = Instance.new(className)
	for k, v in pairs(properties) do
		if k ~= "Parent" then
			obj[k] = v
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

local function Tween(obj, time, style, dir, props)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
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

local function BuildVectorIcon(holder, kind, color)
	for _, c in ipairs(holder:GetChildren()) do
		c:Destroy()
	end
	local parts = {}
	if kind == "Minimize" then
		local line = New("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder
		})
		New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
		table.insert(parts, { Obj = line, Prop = "BackgroundColor3" })
	elseif kind == "Restore" then
		local box = New("Frame", {
			Name = "Box",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			Parent = holder
		})
		ApplyCorner(box, 3)
		local stroke = ApplyStroke(box, color, 0, 1.6)
		table.insert(parts, { Obj = stroke, Prop = "Color" })
	elseif kind == "Close" then
		for _, rot in ipairs({ 45, -45 }) do
			local line = New("Frame", {
				Name = "Line",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 13, 0, 2),
				Rotation = rot,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = holder
			})
			New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
			table.insert(parts, { Obj = line, Prop = "BackgroundColor3" })
		end
	end
	return parts
end

local function BuildIconButton(parent, kind, layoutOrder, isClose)
	local theme = Glamorph.Theme
	local btn = New("TextButton", {
		Name = kind,
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = theme.ControlIdle,
		BackgroundTransparency = theme.ControlIdleTransparency,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = layoutOrder,
		Parent = parent
	})
	ApplyCorner(btn, theme.CornerControl)
	local holder = New("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundTransparency = 1,
		Parent = btn
	})
	local image = New("ImageLabel", {
		Name = "Image",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundTransparency = 1,
		Image = "",
		ImageColor3 = theme.IconColor,
		Visible = false,
		Parent = btn
	})
	local ctl = {}
	ctl.Button = btn
	ctl.Kind = kind
	ctl.Hovered = false
	ctl.Parts = BuildVectorIcon(holder, kind, theme.IconColor)
	function ctl.Paint(color, fast)
		local t = fast and 0.1 or 0.16
		for _, p in ipairs(ctl.Parts) do
			Tween(p.Obj, t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { [p.Prop] = color })
		end
		if image.Visible then
			Tween(image, t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { ImageColor3 = color })
		end
	end
	function ctl.SetKind(nextKind)
		ctl.Kind = nextKind
		btn.Name = nextKind
		local paint = theme.IconColor
		if ctl.Hovered then
			paint = theme.IconHover
		end
		ctl.Parts = BuildVectorIcon(holder, nextKind, paint)
		local id = Glamorph.Icons[nextKind]
		if id ~= nil and id ~= "" then
			image.Image = id
			image.Visible = true
			holder.Visible = false
		else
			image.Visible = false
			holder.Visible = true
		end
	end
	ctl.SetKind(kind)
	btn.MouseEnter:Connect(function()
		ctl.Hovered = true
		if isClose then
			Tween(btn, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = theme.CloseHover, BackgroundTransparency = theme.CloseHoverTransparency })
		else
			Tween(btn, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ControlHoverTransparency })
		end
		ctl.Paint(theme.IconHover)
	end)
	btn.MouseLeave:Connect(function()
		ctl.Hovered = false
		Tween(btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = theme.ControlIdle, BackgroundTransparency = theme.ControlIdleTransparency })
		ctl.Paint(theme.IconColor)
	end)
	btn.MouseButton1Down:Connect(function()
		Tween(btn, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ControlHoverTransparency - 0.06 })
	end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ControlHoverTransparency })
	end)
	return ctl
end

function Glamorph:CreateWindow(config)
	config = config or {}
	local theme = self.Theme
	local title = config.Title or "Glamorph"
	local subtitle = config.Subtitle or "v0.2.0"
	local size = config.Size or UDim2.new(0, 580, 0, 380)
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	local accentLight = config.AccentLight or theme.AccentLight
	local accentDark = config.AccentDark or theme.AccentDark
	local topHeight = 58

	local screenGui = New("ScreenGui", {
		Name = "GlamorphGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = GetGuiParent()
	})

	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(size.X.Scale, size.X.Offset, 0, topHeight),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	})
	ApplyCorner(main, theme.CornerMain)
	local mainStroke = ApplyStroke(main, theme.StrokeColor, 1, 1)
	local scale = New("UIScale", { Scale = 0.95, Parent = main })

	local sheen = New("Frame", {
		Name = "Sheen",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main
	})
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Parent = sheen
	})

	local topBar = New("Frame", {
		Name = "TopBar",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, topHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main
	})

	local logo = New("Frame", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = topBar
	})
	ApplyCorner(logo, 10)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accentLight),
			ColorSequenceKeypoint.new(1, accentDark)
		}),
		Rotation = 45,
		Parent = logo
	})
	New("TextLabel", {
		Name = "Mark",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "G",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = logo
	})

	local titleHolder = New("Frame", {
		Name = "TitleHolder",
		Position = UDim2.new(0, 58, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Parent = topBar
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleHolder
	})
	local titleLabel = New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 19),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = titleHolder
	})
	local subLabel = New("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = theme.SubtitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = titleHolder
	})

	local controls = New("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, 68, 0, 30),
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
	local minCtl = BuildIconButton(controls, "Minimize", 1, false)
	local closeCtl = BuildIconButton(controls, "Close", 2, true)

	local divider = New("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, 18, 0, topHeight - 1),
		Size = UDim2.new(1, -36, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = main
	})
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Parent = divider
	})

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 16, 0, topHeight + 10),
		Size = UDim2.new(1, -32, 1, -(topHeight + 26)),
		BackgroundColor3 = theme.ContentBackground,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = main
	})
	ApplyCorner(content, theme.CornerContent)
	local contentStroke = ApplyStroke(content, theme.StrokeColor, 1, 1)
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

	Tween(main, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = size, BackgroundTransparency = theme.BackgroundTransparency })
	Tween(mainStroke, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = theme.StrokeTransparency })
	Tween(scale, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	Tween(sheen, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SheenTransparency })
	task.delay(0.14, function()
		if window.Destroyed or window.Minimized then
			return
		end
		divider.Visible = true
		content.Visible = true
		Tween(divider, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.DividerTransparency })
		Tween(content, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ContentTransparency })
		Tween(contentStroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = theme.ContentStrokeTransparency })
	end)

	function window:SetTitle(t)
		titleLabel.Text = t
	end

	function window:SetSubtitle(t)
		subLabel.Text = t
	end

	function window:SetSize(s)
		self.FullSize = s
		if not self.Minimized and not self.Destroyed then
			Tween(self.Main, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = s })
		end
	end

	function window:Minimize(state)
		if self.Destroyed then
			return
		end
		local shouldMin = if state == nil then not self.Minimized else state
		if shouldMin == self.Minimized and content.Visible == (not shouldMin) then
			return
		end
		self.Minimized = shouldMin
		if shouldMin then
			Tween(content, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
			Tween(contentStroke, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
			Tween(divider, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
			task.delay(0.14, function()
				if self.Minimized and not self.Destroyed then
					content.Visible = false
					divider.Visible = false
				end
			end)
			Tween(self.Main, theme.CollapseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(self.FullSize.X.Scale, self.FullSize.X.Offset, 0, self.TopHeight) })
			minCtl.SetKind("Restore")
		else
			content.Visible = true
			divider.Visible = true
			Tween(self.Main, theme.CollapseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = self.FullSize })
			task.delay(0.1, function()
				if not self.Minimized and not self.Destroyed then
					Tween(content, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ContentTransparency })
					Tween(contentStroke, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = theme.ContentStrokeTransparency })
					Tween(divider, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.DividerTransparency })
				end
			end)
			minCtl.SetKind("Minimize")
		end
	end

	function window:Show()
		if self.Destroyed then
			return
		end
		self.Hidden = false
		screenGui.Enabled = true
		main.Visible = true
		Tween(main, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.BackgroundTransparency })
		Tween(scale, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	end

	function window:Hide()
		if self.Destroyed then
			return
		end
		self.Hidden = true
		Tween(main, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
		local tw = Tween(scale, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.97 })
		tw.Completed:Wait()
		if self.Hidden and not self.Destroyed then
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
		Tween(main, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1, Size = UDim2.new(0, self.Main.Size.X.Offset - 28, 0, self.Main.Size.Y.Offset - 28) })
		Tween(mainStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
		Tween(scale, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Scale = 0.93 })
		task.wait(0.22)
		screenGui:Destroy()
		local idx = table.find(Glamorph.Windows, self)
		if idx then
			table.remove(Glamorph.Windows, idx)
		end
	end

	minCtl.Button.MouseButton1Click:Connect(function()
		window:Minimize()
	end)
	closeCtl.Button.MouseButton1Click:Connect(function()
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
