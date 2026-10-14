local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Glamorph = {}
Glamorph.Version = "0.3.0"
Glamorph.Windows = {}

Glamorph.Theme = {
	Background = Color3.fromRGB(13, 13, 18),
	BackgroundTransparency = 0.08,
	SidebarBackground = Color3.fromRGB(9, 9, 13),
	SidebarTransparency = 0.12,
	TitleColor = Color3.fromRGB(245, 245, 248),
	SubtitleColor = Color3.fromRGB(148, 150, 164),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.84,
	SheenTransparency = 0.7,
	TabIdleText = Color3.fromRGB(150, 152, 166),
	TabSelectedText = Color3.fromRGB(255, 255, 255),
	TabSelectedBackground = Color3.fromRGB(255, 255, 255),
	TabSelectedTransparency = 0.9,
	TabHoverTransparency = 0.94,
	ElementBackground = Color3.fromRGB(255, 255, 255),
	ElementTransparency = 0.95,
	ElementHoverTransparency = 0.9,
	ElementStrokeTransparency = 0.92,
	ControlIdle = Color3.fromRGB(255, 255, 255),
	ControlIdleTransparency = 0.94,
	ControlHoverTransparency = 0.85,
	CloseHover = Color3.fromRGB(242, 85, 90),
	CloseHoverTransparency = 0.12,
	IconColor = Color3.fromRGB(200, 201, 212),
	IconHover = Color3.fromRGB(255, 255, 255),
	TrackOff = Color3.fromRGB(255, 255, 255),
	TrackOffTransparency = 0.86,
	KnobColor = Color3.fromRGB(255, 255, 255),
	LockedTransparency = 0.6,
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

local function Pick(first, second, fallback)
	if first ~= nil then
		return first
	end
	if second ~= nil then
		return second
	end
	return fallback
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

local function ParseKeybind(value, fallback)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" then
		local ok, code = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok and code then
			return code
		end
	end
	return fallback
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
	function ctl.Paint(color)
		for _, p in ipairs(ctl.Parts) do
			Tween(p.Obj, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { [p.Prop] = color })
		end
		if image.Visible then
			Tween(image, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { ImageColor3 = color })
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
	return ctl
end

local function DrawHomeIcon(holder, color)
	local parts = {}
	local body = New("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, 11, 0, 8),
		BackgroundTransparency = 1,
		Parent = holder
	})
	ApplyCorner(body, 1)
	local bodyStroke = ApplyStroke(body, color, 0, 1.6)
	table.insert(parts, { Obj = bodyStroke, Prop = "Color" })
	local left = New("Frame", {
		Name = "RoofL",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -3, 0, 5),
		Size = UDim2.new(0, 8, 0, 2),
		Rotation = 38,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = holder
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = left })
	table.insert(parts, { Obj = left, Prop = "BackgroundColor3" })
	local right = New("Frame", {
		Name = "RoofR",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 3, 0, 5),
		Size = UDim2.new(0, 8, 0, 2),
		Rotation = -38,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = holder
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = right })
	table.insert(parts, { Obj = right, Prop = "BackgroundColor3" })
	return parts
end

local function DrawSettingsIcon(holder, color)
	local parts = {}
	local hub = New("Frame", {
		Name = "Hub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 6, 0, 6),
		BackgroundTransparency = 1,
		Parent = holder
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hub })
	local hubStroke = ApplyStroke(hub, color, 0, 1.6)
	table.insert(parts, { Obj = hubStroke, Prop = "Color" })
	for i = 0, 7 do
		local deg = i * 45
		local rad = math.rad(deg)
		local ox = math.cos(rad) * 5.4
		local oy = math.sin(rad) * 5.4
		local spoke = New("Frame", {
			Name = "Spoke",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, ox, 0.5, oy),
			Size = UDim2.new(0, 3.4, 0, 1.8),
			Rotation = deg,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder
		})
		New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = spoke })
		table.insert(parts, { Obj = spoke, Prop = "BackgroundColor3" })
	end
	return parts
end

local function BuildTabIcon(holder, tile, letter, icon, color)
	for _, c in ipairs(holder:GetChildren()) do
		if c ~= tile and c ~= letter then
			c:Destroy()
		end
	end
	tile.Visible = false
	letter.Visible = false
	local image = holder:FindFirstChild("Image")
	if image then
		image:Destroy()
	end
	local parts = {}
	local id = nil
	if type(icon) == "number" then
		id = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and string.match(icon, "^rbxassetid://") then
		id = icon
	end
	if id then
		local img = New("ImageLabel", {
			Name = "Image",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 15, 0, 15),
			BackgroundTransparency = 1,
			Image = id,
			ImageColor3 = color,
			Parent = holder
		})
		table.insert(parts, { Obj = img, Prop = "ImageColor3" })
	elseif icon == "home" then
		parts = DrawHomeIcon(holder, color)
	elseif icon == "settings" then
		parts = DrawSettingsIcon(holder, color)
	else
		tile.Visible = true
		letter.Visible = true
		table.insert(parts, { Obj = letter, Prop = "TextColor3" })
	end
	return parts
end

local function BuildSection(page, order, name)
	local theme = Glamorph.Theme
	local holder = New("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = page
	})
	local label = New("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(1, -4, 0, 18),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = holder
	})
	local api = {}
	function api.Set(text)
		label.Text = text
	end
	function api.Destroy()
		holder:Destroy()
	end
	return api
end

local function BuildButton(page, order, settings)
	local theme = Glamorph.Theme
	local name = Pick(settings.Name, settings.Title, "Button")
	local desc = Pick(settings.Desc, settings.Description, nil)
	local cb = settings.Callback or function() end
	local height = 44
	if desc then
		height = 58
	end
	local btn = New("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.ElementBackground,
		BackgroundTransparency = theme.ElementTransparency,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = page
	})
	ApplyCorner(btn, theme.CornerContent)
	ApplyStroke(btn, theme.StrokeColor, theme.ElementStrokeTransparency, 1)
	local title = New("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 0, height),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn
	})
	if desc then
		New("UIPadding", { PaddingTop = UDim.new(0, 9), Parent = title })
	end
	local sub = nil
	if desc then
		sub = New("TextLabel", {
			Name = "Desc",
			Position = UDim2.new(0, 14, 1, -26),
			Size = UDim2.new(1, -28, 0, 15),
			BackgroundTransparency = 1,
			Text = desc,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = theme.SubtitleColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = btn
		})
	end
	btn.MouseEnter:Connect(function()
		Tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementHoverTransparency })
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementTransparency })
	end)
	btn.MouseButton1Click:Connect(function()
		Tween(btn, 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementHoverTransparency - 0.05 })
		task.delay(0.08, function()
			if btn.Parent then
				Tween(btn, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementTransparency })
			end
		end)
		pcall(cb)
	end)
	local api = {}
	function api.Set(text)
		title.Text = text
	end
	function api.Destroy()
		btn:Destroy()
	end
	return api
end

local function BuildToggle(page, order, settings)
	local theme = Glamorph.Theme
	local name = Pick(settings.Name, settings.Title, "Toggle")
	local desc = Pick(settings.Desc, settings.Description, nil)
	local cb = settings.Callback or function() end
	local value = Pick(settings.Value, settings.CurrentValue, false)
	local height = 50
	if desc then
		height = 60
	end
	local row = New("TextButton", {
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.ElementBackground,
		BackgroundTransparency = theme.ElementTransparency,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = page
	})
	ApplyCorner(row, theme.CornerContent)
	ApplyStroke(row, theme.StrokeColor, theme.ElementStrokeTransparency, 1)
	local title = New("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -76, 0, height),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row
	})
	if desc then
		New("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = title })
	end
	local sub = nil
	if desc then
		sub = New("TextLabel", {
			Name = "Desc",
			Position = UDim2.new(0, 14, 1, -26),
			Size = UDim2.new(1, -76, 0, 15),
			BackgroundTransparency = 1,
			Text = desc,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = theme.SubtitleColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row
		})
	end
	local track = New("TextButton", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 24),
		BackgroundColor3 = theme.TrackOff,
		BackgroundTransparency = theme.TrackOffTransparency,
		Text = "",
		AutoButtonColor = false,
		Parent = row
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = theme.KnobColor,
		BorderSizePixel = 0,
		Parent = track
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local api = {}
	api.Value = value
	api.Locked = false
	local function render(instant)
		local kx = 3
		local tc = theme.TrackOff
		local tt = theme.TrackOffTransparency
		if api.Value then
			kx = 23
			tc = theme.AccentDark
			tt = 0
		end
		if instant then
			knob.Position = UDim2.new(0, kx, 0.5, 0)
			track.BackgroundColor3 = tc
			track.BackgroundTransparency = tt
		else
			Tween(knob, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Position = UDim2.new(0, kx, 0.5, 0) })
			Tween(track, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundColor3 = tc, BackgroundTransparency = tt })
		end
	end
	function api.Set(v)
		api.Value = v and true or false
		render(false)
	end
	function api.Lock()
		api.Locked = true
		Tween(row, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.LockedTransparency })
	end
	function api.Unlock()
		api.Locked = false
		Tween(row, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementTransparency })
	end
	function api.Destroy()
		row:Destroy()
	end
	local function flip()
		if api.Locked then
			return
		end
		api.Value = not api.Value
		render(false)
		pcall(cb, api.Value)
	end
	track.MouseButton1Click:Connect(flip)
	row.MouseButton1Click:Connect(flip)
	row.MouseEnter:Connect(function()
		if not api.Locked then
			Tween(row, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementHoverTransparency })
		end
	end)
	row.MouseLeave:Connect(function()
		if not api.Locked then
			Tween(row, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementTransparency })
		end
	end)
	render(true)
	return api
end

function Glamorph:CreateWindow(config)
	config = config or {}
	local theme = self.Theme
	local title = Pick(config.Name, config.Title, "Glamorph")
	local author = Pick(config.Subtitle, config.Author, "by Glamorph")
	local size = config.Size or UDim2.new(0, 580, 0, 460)
	local sideWidth = config.SideBarWidth or 200
	local toggleKey = ParseKeybind(Pick(config.ToggleKey, config.ToggleUIKeybind, nil), Enum.KeyCode.RightShift)
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

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, sideWidth, 1, 0),
		BackgroundColor3 = theme.SidebarBackground,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = main
	})
	ApplyCorner(sidebar, theme.CornerMain)
	local sideFix = New("Frame", {
		Name = "Fix",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 14, 1, 0),
		BackgroundColor3 = theme.SidebarBackground,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = sidebar
	})
	local sideDivider = New("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 14),
		Size = UDim2.new(0, 1, 1, -28),
		BackgroundColor3 = theme.StrokeColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = sidebar
	})

	local sideHeader = New("Frame", {
		Name = "Header",
		Position = UDim2.new(0, 14, 0, 14),
		Size = UDim2.new(1, -28, 0, 36),
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	local logo = New("Frame", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = sideHeader
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
		TextSize = 17,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = logo
	})
	local sideTitle = New("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, 42, 0, 1),
		Size = UDim2.new(1, -42, 0, 19),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = sideHeader
	})
	New("TextLabel", {
		Name = "Author",
		Position = UDim2.new(0, 42, 0, 20),
		Size = UDim2.new(1, -42, 0, 14),
		BackgroundTransparency = 1,
		Text = author,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = theme.SubtitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = sideHeader
	})

	local searchBox = New("TextBox", {
		Name = "Search",
		Position = UDim2.new(0, 14, 0, 60),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundColor3 = theme.ElementBackground,
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = theme.SubtitleColor,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = sidebar
	})
	ApplyCorner(searchBox, 9)
	ApplyStroke(searchBox, theme.StrokeColor, 1, 1)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = searchBox
	})

	local tabList = New("ScrollingFrame", {
		Name = "TabList",
		Position = UDim2.new(0, 14, 0, 100),
		Size = UDim2.new(1, -28, 1, -146),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = sidebar
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList
	})

	New("TextLabel", {
		Name = "Version",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -12),
		Size = UDim2.new(0, 120, 0, 14),
		BackgroundTransparency = 1,
		Text = "Glamorph " .. self.Version,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.SubtitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sidebar
	})

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, sideWidth, 0, 0),
		Size = UDim2.new(1, -sideWidth, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = main
	})
	local pageHeader = New("Frame", {
		Name = "PageHeader",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, topHeight),
		BackgroundTransparency = 1,
		Parent = content
	})
	local pageTitle = New("TextLabel", {
		Name = "PageTitle",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0.5, 0),
		Size = UDim2.new(1, -120, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextColor3 = theme.TitleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = pageHeader
	})
	local controls = New("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, 68, 0, 30),
		BackgroundTransparency = 1,
		Parent = pageHeader
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
	local pageDivider = New("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, 20, 0, topHeight - 1),
		Size = UDim2.new(1, -40, 0, 1),
		BackgroundColor3 = theme.StrokeColor,
		BackgroundTransparency = theme.DividerTransparency,
		BorderSizePixel = 0,
		Parent = content
	})
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Parent = pageDivider
	})
	local pageHolder = New("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 0, 0, topHeight),
		Size = UDim2.new(1, 0, 1, -topHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = content
	})

	MakeDraggable(pageHeader, main)
	MakeDraggable(sideHeader, main)

	local window = {}
	window.Gui = screenGui
	window.Main = main
	window.Tabs = {}
	window.Selected = nil
	window.Minimized = false
	window.Hidden = false
	window.Destroyed = false
	window.FullSize = size
	window.TopHeight = topHeight
	window.SideWidth = sideWidth

	local searchStroke = searchBox:FindFirstChildOfClass("UIStroke")

	Tween(main, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = size, BackgroundTransparency = theme.BackgroundTransparency })
	Tween(mainStroke, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = theme.StrokeTransparency })
	Tween(scale, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	Tween(sheen, theme.OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SheenTransparency })
	task.delay(0.14, function()
		if window.Destroyed or window.Minimized then
			return
		end
		sidebar.Visible = true
		content.Visible = true
		Tween(sidebar, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SidebarTransparency })
		Tween(sideFix, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SidebarTransparency })
		Tween(sideDivider, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.9 })
		Tween(searchBox, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.ElementTransparency })
		if searchStroke then
			Tween(searchStroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = theme.ElementStrokeTransparency })
		end
	end)

	function window:SelectTab(tab)
		if self.Destroyed or self.Selected == tab then
			return
		end
		self.Selected = tab
		pageTitle.Text = tab.Title
		for _, t in ipairs(self.Tabs) do
			local active = t == tab
			t.Page.Visible = active
			t.SetSelected(active)
			if active then
				t.Page.CanvasPosition = Vector2.new(0, 0)
				t.Page.Position = UDim2.new(0, 28, 0, 0)
				Tween(t.Page, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Position = UDim2.new(0, 0, 0, 0) })
			end
		end
	end

	function window:CreateTab(title, icon)
		if type(title) == "table" then
			icon = Pick(title.Icon, title.Image, icon)
			title = Pick(title.Name, title.Title, "Tab")
		end
		title = title or "Tab"
		local order = #self.Tabs + 1
		local row = New("TextButton", {
			Name = "Tab",
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = theme.TabSelectedBackground,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			Parent = tabList
		})
		ApplyCorner(row, 10)
		local iconHolder = New("Frame", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.new(0, 22, 0, 22),
			BackgroundTransparency = 1,
			Parent = row
		})
		local tile = New("Frame", {
			Name = "Tile",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = accentDark,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Visible = false,
			Parent = iconHolder
		})
		ApplyCorner(tile, 7)
		local letter = New("TextLabel", {
			Name = "Letter",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = string.upper(string.sub(title, 1, 1)),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = theme.TabIdleText,
			Visible = false,
			Parent = iconHolder
		})
		local label = New("TextLabel", {
			Name = "Label",
			Position = UDim2.new(0, 36, 0, 0),
			Size = UDim2.new(1, -44, 1, 0),
			BackgroundTransparency = 1,
			Text = title,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = theme.TabIdleText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row
		})
		local page = New("ScrollingFrame", {
			Name = "Page",
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
			ScrollBarImageTransparency = 0.75,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = pageHolder
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page
		})
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 20),
			Parent = page
		})
		local tab = {}
		tab.Title = title
		tab.Row = row
		tab.Page = page
		tab.Order = 0
		tab.Selected = false
		local iconParts = BuildTabIcon(iconHolder, tile, letter, icon, theme.TabIdleText)
		local function paint(color)
			for _, p in ipairs(iconParts) do
				Tween(p.Obj, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { [p.Prop] = color })
			end
		end
		function tab.SetSelected(active)
			tab.Selected = active
			if active then
				Tween(row, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.TabSelectedTransparency })
				Tween(label, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = theme.TabSelectedText })
				paint(theme.IconHover)
			else
				Tween(row, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
				Tween(label, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = theme.TabIdleText })
				paint(theme.TabIdleText)
			end
		end
		function tab.Select()
			window:SelectTab(tab)
		end
		function tab.CreateSection(name)
			tab.Order = tab.Order + 1
			return BuildSection(page, tab.Order, name)
		end
		function tab.CreateButton(settings)
			tab.Order = tab.Order + 1
			return BuildButton(page, tab.Order, settings or {})
		end
		function tab.CreateToggle(settings)
			tab.Order = tab.Order + 1
			return BuildToggle(page, tab.Order, settings or {})
		end
		row.MouseButton1Click:Connect(function()
			window:SelectTab(tab)
		end)
		row.MouseEnter:Connect(function()
			if not tab.Selected then
				Tween(row, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = theme.TabHoverTransparency })
			end
		end)
		row.MouseLeave:Connect(function()
			if not tab.Selected then
				Tween(row, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
			end
		end)
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then
			self:SelectTab(tab)
		end
		return tab
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(searchBox.Text)
		for _, t in ipairs(window.Tabs) do
			if q == "" then
				t.Row.Visible = true
			else
				t.Row.Visible = string.find(string.lower(t.Title), q, 1, true) ~= nil
			end
		end
	end)

	function window:SetTitle(t)
		sideTitle.Text = t
	end

	function window:SetSubtitle(t)
		for _, c in ipairs(sideHeader:GetChildren()) do
			if c.Name == "Author" then
				c.Text = t
			end
		end
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
		if shouldMin == self.Minimized and sidebar.Visible == (not shouldMin) then
			return
		end
		self.Minimized = shouldMin
		if shouldMin then
			Tween(sidebar, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
			Tween(content, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
			task.delay(0.14, function()
				if self.Minimized and not self.Destroyed then
					sidebar.Visible = false
					content.Visible = false
				end
			end)
			Tween(self.Main, theme.CollapseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(self.FullSize.X.Scale, self.FullSize.X.Offset, 0, self.TopHeight) })
			minCtl.SetKind("Restore")
		else
			sidebar.Visible = true
			content.Visible = true
			Tween(self.Main, theme.CollapseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = self.FullSize })
			task.delay(0.1, function()
				if not self.Minimized and not self.Destroyed then
					Tween(sidebar, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SidebarTransparency })
					Tween(sideFix, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = theme.SidebarTransparency })
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
