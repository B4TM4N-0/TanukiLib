local TanukiLib = { 
	Options = {}, 
	PagesGroup = {},
	Pages = { },
    Sections = { },
	
	Folders = {
		Directory = "abcdefg",
		abcdefg = "abcdefg/abcdefg"
	},
	
	Themes = {},
	CurrentTheme = "Light",
	themeCallbacks = {},
}

for Index, Value in TanukiLib.Folders do 
    if not isfolder(Value) then
        makefolder(Value)
    end
end

GetService = function(service)
	return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
end

gethui = gethui or function()
	return cloneref(GetService("CoreGui")) or GetService("CoreGui")
end

TanukiLib.AddTheme = function(self, ThemeData)
	self.Themes[ThemeData.Name] = ThemeData
end

TanukiLib.GetTheme = function(self)
	return self.Themes[self.CurrentTheme]
end

TanukiLib.GetThemes = function(self)
	local list = {}
	for name in pairs(self.Themes) do
		table.insert(list, name)
	end
	return list
end

TanukiLib.SetTheme = function(self, name)
	if self.Themes[name] then
		self.CurrentTheme = name
		for _, cb in ipairs(self.themeCallbacks) do
			cb(name)
		end
	end
end

TanukiLib:AddTheme({
	Name = "Tanuki",
	Accent = Color3.fromRGB(101, 75, 50),
	Background = Color3.fromRGB(42, 31, 20),
	Surface = Color3.fromRGB(210, 175, 130),
	Outline = Color3.fromRGB(160, 120, 80),
	Text = Color3.fromRGB(235, 210, 175),
	Placeholder = Color3.fromRGB(130, 100, 70),
	Button = Color3.fromRGB(140, 100, 60),
	Icon = Color3.fromRGB(190, 155, 110),
})

TanukiLib:AddTheme({
	Name = "Dark",
	Accent = Color3.fromRGB(24, 24, 27),
	Background = Color3.fromRGB(10,10,10),
	Surface = Color3.fromRGB(18,18,18),
	Outline = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Placeholder = Color3.fromRGB(122, 122, 122),
	Button = Color3.fromRGB(87, 86, 86),
	Icon = Color3.fromRGB(180, 180, 180),
})

TanukiLib:AddTheme({
	Name = "Light",
	Accent = Color3.fromRGB(210, 210, 218),
	Background = Color3.fromRGB(245, 245, 245),
	Surface = Color3.fromRGB(255, 255, 255),
	Outline = Color3.fromRGB(170,170,170),
	Text = Color3.fromRGB(20, 20, 20),
	Placeholder = Color3.fromRGB(130, 130, 130),
	Button = Color3.fromRGB(235, 235, 235),
	Icon = Color3.fromRGB(80, 80, 80),
})

local TweenService = GetService("TweenService")
local RunService = GetService("RunService")
local HttpService = GetService("HttpService")
local ContentProvider = GetService("ContentProvider")
local UserInputService = GetService("UserInputService")
local Lighting = GetService("Lighting")
local Players = GetService("Players")

--! Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local windowState
local sidebarExpanded
local unloaded
local ActivePage

do
	local _iconsV2
	local _iconsReady = false
	local _iconsCallbacks = {}

	task.spawn(function()
		_iconsV2 = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
		_iconsReady = true
		for _, cb in ipairs(_iconsCallbacks) do
			cb(_iconsV2)
		end
		_iconsCallbacks = {}
	end)

	local function resolveWithIcons(icons, path)
		local iconType, iconName = path:match("^(.+)/(.+)$")
		if iconType and iconName then
			icons.SetIconsType(iconType)
			return icons.GetIcon(iconName)
		end
		return icons.GetIcon(path)
	end

	function TanukiLib:GetIcon(path)
		if _iconsReady then
			return resolveWithIcons(_iconsV2, path)
		end
		local result
		local thread = coroutine.running()
		table.insert(_iconsCallbacks, function(icons)
			result = resolveWithIcons(icons, path)
			coroutine.resume(thread)
		end)
		coroutine.yield()
		return result
	end

	function TanukiLib:ResolveImage(path, instance, prop)
		if not path then return "" end
		if path:match("^%d+$") then
			local id = "rbxassetid://" .. path
			if instance then instance[prop] = id end
			return id
		end
		if path:find("rbxassetid") then
			if instance then instance[prop] = path end
			return path
		end
		if path:find("/") then
			if _iconsReady then
				local id = resolveWithIcons(_iconsV2, path)
				if instance then instance[prop] = id end
				return id
			end
			if instance then
				table.insert(_iconsCallbacks, function(icons)
				    instance[prop] = resolveWithIcons(icons, path)
				end)
			end
			return ""
		end
		return path
	end
end

function TanukiLib:Gradient(text, fromColor, toColor)
	local colors
	if type(fromColor) == "table" then
		colors = fromColor
	else
		colors = {fromColor, toColor}
	end
	local result = ""
	local len = utf8.len(text)
	if len == 0 then return text end
	local segments = #colors - 1
	local i = 0
	for _, codepoint in utf8.codes(text) do
		local t = len > 1 and (i / (len - 1)) or 0
		local seg = math.min(math.floor(t * segments), segments - 1)
		local localT = t * segments - seg
		local c1 = colors[seg + 1]
		local c2 = colors[seg + 2]
		local r = math.round(c1.R * 255 + (c2.R * 255 - c1.R * 255) * localT)
		local g = math.round(c1.G * 255 + (c2.G * 255 - c1.G * 255) * localT)
		local b = math.round(c1.B * 255 + (c2.B * 255 - c1.B * 255) * localT)
		local char = utf8.char(codepoint)
		result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, char)
		i += 1
	end
	return result
end

local assets = {
	interFont = "rbxassetid://12187365364",
	grid = "rbxassetid://121484455191370",
	move = "rbxassetid://116138709011735",
	
	dashboard = "rbxassetid://75536606374585",
	settings = "rbxassetid://135684703553372",
	close = "rbxassetid://110786993356448",
}

TanukiLib.__index = TanukiLib
TanukiLib.Sections.__index = TanukiLib.Sections
TanukiLib.Pages.__index = TanukiLib
TanukiLib.PagesGroup.__index = TanukiLib

local function Create(Class, Properties)
    local NewItem = Instance.new(Class)
    for Property, Value in pairs(Properties or {}) do
        NewItem[Property] = Value
    end
    return NewItem
end

local function Tween(instance, tweeninfo, propertytable)
	return TweenService:Create(instance, tweeninfo, propertytable)
end

local function IsMouseOverFrame(Frame)
    local MousePosition = Vector2.new(Mouse.X, Mouse.Y)
    return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
end

local function GetObjectProperty(Item)
    if Item:IsA("Frame") then
        return { "BackgroundTransparency" }
    elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
        return { "TextTransparency", "BackgroundTransparency" }
    elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
        return { "BackgroundTransparency", "ImageTransparency" }
    elseif Item:IsA("ScrollingFrame") then
        return { "BackgroundTransparency", "ScrollBarImageTransparency" }
    elseif Item:IsA("TextBox") then
        return { "TextTransparency", "BackgroundTransparency" }
    elseif Item:IsA("UIStroke") then 
        return { "Transparency" }
    end
end

local themeRegistry = {}
local Theme = {}

local function setThemed(inst, prop, key)
    inst[prop] = Theme[key]
    table.insert(themeRegistry, {inst = inst, prop = prop, key = key})
end

local function setElementLock(ItemFrame, state)
    local existing = ItemFrame:FindFirstChild("LockOverlay")
    if state then
        if existing then return end
        
        local LockOverlay = Create("Frame", {
            Name = "LockOverlay",
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.7,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 20,
            Active = true,
            Parent = ItemFrame,
        })

        Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = LockOverlay,
        })
        
        Create("UIListLayout", {
		    Name = "FrameLayout",
		    Padding = UDim.new(0, 6),
		    SortOrder = Enum.SortOrder.LayoutOrder,
		    FillDirection = Enum.FillDirection.Horizontal,
		    HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		    Parent = LockOverlay
		})

        local LockIcon = Create("ImageLabel", {
            Name = "LockIcon",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://134724289526879",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = LockOverlay
        }) setThemed(LockIcon, "ImageColor3", "Text")

        local LockText = Create("TextLabel", {
            Name = "LockText",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium),
            Text = "Locked",
            TextSize = 16,
            Size = UDim2.fromOffset(100, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromScale(0.5, 0.5),
            Parent = LockOverlay
        }) setThemed(LockText, "TextColor3", "Text")
    else
        if existing then
            existing:Destroy()
        end
    end
end


local function GetGui()
	local ScreenGui = Create("ScreenGui", {
	    ScreenInsets = Enum.ScreenInsets.None,
	    ResetOnSpawn = false,
	    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	    DisplayOrder = 1696966967,
	    Parent = gethui(),
	})
	
	return ScreenGui
end


local Folder = Create("Folder", {
	Parent = gethui(),
    Name = "\0",
})

local NotificationGUI = GetGui()
NotificationGUI.Parent = Folder

local GuiHolder = GetGui()
GuiHolder.Parent = Folder

--! stores our notification so it checks and move the notification above it
local ActiveNotify = {}
TanukiLib.Notify = function(self, Data)
	local Notify = {
        Name = Data.Name or "Window",
        Desc = Data.Description or "Fine-tuning for sure wins",
        Duration = Data.Duration or 5,
        
    }
    
    local Items = {}
    
	Items["Base"] = Create("ImageButton", {
		Parent = NotificationGUI,
		ZIndex = 20,
		Name = "frame",
		Active = false,
		Size = UDim2.new(0, 288, 0, 0),
		Position = UDim2.new(1, 10, 0.65, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoButtonColor = false,
	}) setThemed(Items["Base"], "BackgroundColor3", "Background")
	
	Create("UIListLayout", {
	    Name = "BaseLayout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    FillDirection = Enum.FillDirection.Horizontal,
	    Padding = UDim.new(0, 10),
		Parent = Items["Base"]
	})
	
	Create("UIPadding", {
	    Name = "BaseUIPadding",
	    PaddingTop = UDim.new(0, 16),
	    PaddingLeft = UDim.new(0, 20),
	    PaddingRight = UDim.new(0, 30),
	    PaddingBottom = UDim.new(0, 16),
		Parent = Items["Base"] 
	})
	
	Items["BaseUIStroke"] = Create("UIStroke", {
	    Name = "BaseUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 0.9,
	    Parent = Items["Base"] 
	}) setThemed(Items["BaseUIStroke"], "Color", "Outline")
	
	Items["BaseUIStroke"] = Create("UICorner", {
	    Name = "BaseUIStroke",
	    CornerRadius = UDim.new(0, 15),
	    Parent = Items["Base"]
	})
	
	Items["Shadow"]  = Create("ImageLabel", {
	    ZIndex = 0,
	    ImageTransparency = 0.5,
	    Image = "rbxassetid://72548733587158",
	    ImageColor3 = Color3.fromRGB(0, 0, 0),
	    Size = UDim2.new(0, 146, 0, 0),
	    Position = UDim2.new(0.5, 0, 0, 0),
	    AutomaticSize = Enum.AutomaticSize.Y,
	    AnchorPoint = Vector2.new(0.5, 0),
	    BackgroundTransparency = 1,
		Parent = NotificationGUI,
	})
	
	
	Items["TextFrame"] = Create("Frame", {
	    Parent = Items["Base"] ,
		ZIndex = 20,
	    BorderSizePixel = 0,
	    Name = "TextFrame",
	    LayoutOrder = 2,
	    Size = UDim2.new(0, 0, 0, 0),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	})
	
	Create("UIListLayout", {
	    Parent = Items["TextFrame"],
	    Name = "BaseLayout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    FillDirection = Enum.FillDirection.Vertical,
	    Padding = UDim.new(0, 2),
	})
	
	Items["Title"] = Create("TextLabel", {
	    Parent = Items["TextFrame"],
		ZIndex = 20,
	    BorderSizePixel = 0,
	    Name = "Title",
	    LayoutOrder = 1,
	    Size = UDim2.new(0, 0, 0, 0),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	    Text = Notify.Name,
	    TextSize = 15,
		TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	    TextWrapped = true,
	}) setThemed(Items["Title"], "TextColor3", "Text")
	
	Items["Description"] = Create("TextLabel", {
	    Parent = Items["TextFrame"],
		ZIndex = 20,
	    BorderSizePixel = 0,
	    Name = "Description",
	    LayoutOrder = 2,
	    Size = UDim2.new(0, 0, 0, 0),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	    Text = Notify.Desc,
	    TextSize = 12,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    TextYAlignment = Enum.TextYAlignment.Top,
	    FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    TextWrapped = true,
	    TextTransparency = 0.6,
	}) setThemed(Items["Description"], "TextColor3", "Text")
	
	Items["IconFrame"] = Create("Frame", {
		Parent = Items["Base"],
		ZIndex = 20,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundTransparency = 1,
	})

	Items["Icon"] = Create("ImageLabel", {
		Parent = Items["IconFrame"],
		ZIndex = 20,
		Name = "icon",
		Image = "rbxassetid://11963371162",
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}) setThemed(Items["Icon"], "ImageColor3", "Icon")

	Items["PinnedFrame"] = Create("Frame", {
		BorderSizePixel = 0,
		ZIndex = 20,
		Visible = false,
		LayoutOrder = 3,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = Items["Base"],
	})

	Items["PinnedIcon"] = Create("ImageLabel", {
		Parent = Items["PinnedFrame"],
		ZIndex = 20,
		ImageTransparency = 0.8,
		Image = "rbxassetid://116297337005602",
		Name = "icon",
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0.5, 6, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}) setThemed(Items["PinnedIcon"], "ImageColor3", "Icon")

	Create("UIScale", {
		Parent = NotificationGUI,
		Name = "scale",
	})
	
	Notify.Items = Items
	local Base = Items["Base"]
	local totalOffset = 0
	
	local dismissed = false

	local function dismiss()
	    if dismissed then return end
	    dismissed = true
	
	    local i = table.find(ActiveNotify, Base)
	    if i then 
	        table.remove(ActiveNotify, i) 
	    end
	    
	    if Base and Base.Parent then
	        Base:TweenPosition(UDim2.new(1, 10, Base.Position.Y.Scale, Base.Position.Y.Offset), "In", "Sine", 0.3, true)
	        task.delay(0.3, function() 
	            if Base then Base:Destroy() end 
	        end)
	    end
	end
	
	Items["Base"].MouseButton1Click:Connect(dismiss)
	table.insert(ActiveNotify, Base)
	
	task.wait()
	
	for i = #ActiveNotify - 1, 1, -1 do
	    local v = ActiveNotify[i]
	    totalOffset = totalOffset + (ActiveNotify[i + 1].AbsoluteSize.Y + 6)
	    v:TweenPosition(
	        UDim2.new(1, -v.AbsoluteSize.X - 10, 0.65, -totalOffset),
	        "Out", "Quad", 0.3, true
	    )
	end
	
	if #ActiveNotify > 4 then
	    local oldest = table.remove(ActiveNotify, 1)
	    oldest:TweenPosition(UDim2.new(1, 10, oldest.Position.Y.Scale, oldest.Position.Y.Offset), "In", "Sine", 0.3, true)
	    task.delay(0.3, function() if oldest.Parent then oldest:Destroy() end end)
	end
	Base:TweenPosition(UDim2.new(1, -Base.AbsoluteSize.X - 10, 0.65, 0), "Out", "Back", 0.5, true)

	task.delay(Notify.Duration, function()
	    if not dismissed then
	        dismiss()
	    end
	end)
	
	return setmetatable(Notify, TanukiLib)
end

TanukiLib.Window = function(self, Data)
	Data = Data or {}
	
	local Window = {
        Name = Data.Name or "Window",
        SubName = Data.SubName or "Fine-tuning for sure wins",
        Icon = Data.Icon,
        Theme = Data.Theme,
        SidebarState = Data.SidebarState or "Expand",
        Search = Data.Search or false,
        PagesGroup = { },
        Pages = { },
        Items = { },
    }
    
    local src = TanukiLib.Themes[Window.Theme or TanukiLib.CurrentTheme] or {}
	for k, v in pairs(src) do
	    Theme[k] = v
	end
    
	local Items = {}
	
	Items["FloatingButton"] = Create("ImageLabel", {
	    Name = "FloatingButton",
	    Size = UDim2.new(0, 0, 0, 0),
	    AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0,0, 15),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    ImageTransparency = 1,
	    Active = true,
	    BackgroundTransparency = 0,
	    Parent = GuiHolder,
		Visible = false,
	}) setThemed(Items["FloatingButton"], "BackgroundColor3", "Background")
	
	Create("UICorner", {
	    Name = "FloatingButtonUICorner",
	    CornerRadius = UDim.new(0, 10),
	    Parent = Items["FloatingButton"],
	})
	
	Create("UIPadding", {
	    Name = "FloatingButtonUIPadding",
	    PaddingTop = UDim.new(0, 4),
	    PaddingBottom = UDim.new(0, 4),
	    PaddingLeft = UDim.new(0, 4),
	    PaddingRight = UDim.new(0, 4),
	    Parent = Items["FloatingButton"],
	})
	
	Create("UIListLayout", {
	    Name = "FloatingButtonUIListLayout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    Padding = UDim.new(0, 6),
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["FloatingButton"],
	})
	
	Items["FloatingButtonIcon"] = Create("ImageLabel", {
	    Name = "FloatingButtonIcon",
	    Size = UDim2.new(0, 20, 0, 20),
	    ImageColor3 = Color3.fromRGB(255, 255, 255),
	    Image = assets.move,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    Parent = Items["FloatingButton"],
	}) setThemed(Items["FloatingButtonIcon"], "ImageColor3", "Text")
	
	
	Items["Divider"] = Create("ImageLabel", {
	    Name = "Divider",
	    Size = UDim2.new(0, 1, 0, 20),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    BackgroundTransparency = 0.6,
	    Parent = Items["FloatingButton"],
	}) setThemed(Items["Divider"], "BackgroundColor3", "Text")
	
	Items["FloatingButtonTitle"] = Create("TextButton", {
	    Name = "FloatingButtonTitle",
	    Size = UDim2.new(0, 80, 0, 0),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    BorderSizePixel = 0,
	    Text = "Open Interface",
	    BackgroundTransparency = 1,
	    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	    TextXAlignment = Enum.TextXAlignment.Left,
	    TextSize = 15,
	    Parent = Items["FloatingButton"],
	}) setThemed(Items["FloatingButtonTitle"], "TextColor3", "Text")
	
	Create("UIPadding", {
	    Name = "FloatingButtonUIPadding",
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    Parent = Items["FloatingButtonTitle"],
	})
	
	Items["FloatingButtonUIStroke"] = Create("UIStroke", {
	    Name = "FloatingButtonUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 0.9,
	    Parent = Items["FloatingButton"],
	}) setThemed(Items["FloatingButtonUIStroke"], "Color", "Outline")
	
	
	Items["Base"] = Create("Frame", {
	    Name = "Base",
	    Size = UDim2.new(0, 500, 0, 320),
	    Position = UDim2.new(0, 0, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(10,10,10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 0,
	    Parent = GuiHolder
	}) setThemed(Items["Base"], "BackgroundColor3", "Background")
	
	Items["BaseCorner"] = Create("UICorner", {
	    Name = "Corner",
	    CornerRadius = UDim.new(0, 15),
	    Parent = Items["Base"]
	})
	
	Items["BaseUIScale"] = Create("UIScale", {
	    Name = "BaseUIScale",
	    Parent = Items["Base"]
	})
	
	Items["BaseUIStroke"] = Create("UIStroke", {
	    Name = "BaseUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 0.9,
	    Parent = Items["Base"]
	}) setThemed(Items["BaseUIStroke"], "Color", "Outline")
	
	Items["Topbar"] = Create("Frame", {
	    Name = "Topbar",
	    Size = UDim2.fromScale(1, 0.14),
	    Position = UDim2.new(0, 0, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    Active = true,
	    BackgroundTransparency = 1,
	    Parent = Items["Base"]
	})
	
	Items["TopbarPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingTop = UDim.new(0, 10),
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    Parent = Items["Topbar"]
	})
	
	Items["TopbarLayout"] = Create("UIListLayout", {
	    Name = "Layout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Padding = UDim.new(0, 10),
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
	    FillDirection = Enum.FillDirection.Horizontal,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Topbar"]
	})
	
	Items["Icon"] = Create("ImageLabel", {
	    Name = "Icon",
	    Size = UDim2.fromOffset(30, 30),
	    ImageTransparency = 0,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    LayoutOrder = 1,
	    Parent = Items["Topbar"]
	}) 
	TanukiLib:ResolveImage(Window.Icon, Items["Icon"], "Image")
	setThemed(Items["Icon"] , "ImageColor3", "Text")
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
	    Size = UDim2.fromScale(0, 0),
	    AutomaticSize = Enum.AutomaticSize.XY,
	    Position = UDim2.new(0, 0, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 1,
	    LayoutOrder = 2,
	    Parent = Items["Topbar"]
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "Layout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Padding = UDim.new(0, 1),
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["Title"] = Create("TextLabel", {
	    Name = "Title",
	    Size = UDim2.fromScale(0, 0.5),
		AutomaticSize = Enum.AutomaticSize.X,
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Window.Name,
	    BackgroundTransparency = 1,
		TextTransparency = 0.1,
		TextTruncate = Enum.TextTruncate.SplitWord,
		TextXAlignment = Enum.TextXAlignment.Left,
	    TextSize = 16,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["Title"], "TextColor3", "Text")
	
	Items["SubTitle"] = Create("TextLabel", {
	    Name = "SubTitle",
	    Size = UDim2.fromScale(0, 0.5),
		AutomaticSize = Enum.AutomaticSize.X,
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Window.SubName,
	    BackgroundTransparency = 1,
		TextTransparency = 0.6,
		TextTruncate = Enum.TextTruncate.SplitWord,
		TextXAlignment = Enum.TextXAlignment.Left,
	    TextSize = 14,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["SubTitle"] , "TextColor3", "Text")
	
	Items["Separator"] = Create("Frame", {
	    Name = "Separator",
	    Size = UDim2.new(1, 0, 1, 0),
	    BackgroundTransparency = 1,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    LayoutOrder = 3,
	    Parent = Items["Topbar"]
	})
	
	
	
	Items["WindowControls"] = Create("Frame", {
	    Name = "WindowControls",
	    Size = UDim2.fromScale(0, 1),
	    Position = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.X,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 1,
	    LayoutOrder = 4,
	    Parent = Items["Topbar"]
	})
	
	Items["WindowControlsPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingTop = UDim.new(0, 5),
	    PaddingBottom = UDim.new(0, 5),
	    PaddingLeft = UDim.new(0, 3),
	    --PaddingRight = UDim.new(0, 3),
	    Parent = Items["WindowControls"]
	})
	
	Items["WindowControlsLayout"] = Create("UIListLayout", {
	    Name = "UIListLayout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	    Padding = UDim.new(0, 2),
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["WindowControls"]
	})
	
	Items["SidebarButton"] = Create("ImageButton", {
	    Name = "SidebarButton",
	    Size = UDim2.fromOffset(25, 25),
	    Position = UDim2.new(0, 0, 0, 0),
	    ImageColor3 = Color3.fromRGB(255, 255, 255),
	    Image = assets.dashboard,
	    ImageTransparency = 0,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    Parent = Items["WindowControls"]
	}) setThemed(Items["SidebarButton"], "ImageColor3", "Icon")
	
	Items["SettingsButton"] = Create("ImageButton", {
	    Name = "SettingsButton",
	    Size = UDim2.fromOffset(25, 25),
	    Position = UDim2.new(0, 26, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    ImageColor3 = Color3.fromRGB(255, 255, 255),
	    Image = assets.settings,
	    ImageTransparency = 0,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    Parent = Items["WindowControls"]
	}) setThemed(Items["SettingsButton"], "ImageColor3", "Icon")
	
	Items["CloseButton"] = Create("ImageButton", {
	    Name = "CloseButton",
	    Size = UDim2.fromOffset(25, 25),
	    Position = UDim2.new(0, 26, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    ImageColor3 = Color3.fromRGB(255, 255, 255),
	    Image = assets.close,
	    ImageTransparency = 0,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    Parent = Items["WindowControls"]
	}) setThemed(Items["CloseButton"], "ImageColor3", "Icon")
	
	Items["Sidebar"] = Create("Frame", {
	    Name = "Sidebar",
	    Size = UDim2.fromScale(0.35, 1-0.14),
	    Position = UDim2.fromScale(0, 0.14),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 1,
	    Parent = Items["Base"]
	})
	
	Items["SidebarPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingTop = UDim.new(0, 5),
	    PaddingBottom = UDim.new(0, 5),
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    Parent = Items["Sidebar"]
	})
	
	Items["ScrollTab"] = Create("ScrollingFrame", {
	    Name = "ScrollTab",
	    Size = UDim2.new(1, 0, 1, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BottomImage = "",
		CanvasSize = UDim2.new(),
		ScrollBarImageTransparency = 0.8,
		ScrollBarThickness = 1,
		TopImage = "",
	    ScrollingEnabled = true,
		BorderSizePixel = 0,
	    BackgroundTransparency = 1,
	    Parent = Items["Sidebar"]
	})
	
	Items["ScrollTabLayout"] = Create("UIListLayout", {
	    Name = "UIListLayout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Padding = UDim.new(0, 6),
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    VerticalAlignment = Enum.VerticalAlignment.Top,
	    Parent = Items["ScrollTab"]
	})
	
	Items["ScrollTabPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingTop = UDim.new(0, 5),
	    PaddingBottom = UDim.new(0, 5),
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    Parent = Items["ScrollTab"]
	})
	
	Items["Body"] = Create("Frame", {
	    Name = "Body",
	    Size = UDim2.new(1-0.35, 0, 1, -50),
	    Position = UDim2.new(0.35, 0, 0, 50),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 1,
	    ClipsDescendants = true,
	    Parent = Items["Base"]
	})
	
	
	Items["Search"] = Create("Frame", {
        Name = "Search",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.75,
        BorderSizePixel = 0,
        LayoutOrder = -1,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = Window.Search,
        Parent = Items["ScrollTab"],
    }) setThemed(Items["Search"], "BackgroundColor3", "Surface")

    Create("UICorner", {
        Name = "SectionUICorner",
        Parent = Items["Search"],
    })

    Items["SearchIcon"] = Create("ImageLabel", {
        Name = "SearchIcon",
        Image = "rbxassetid://121018724060431",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Parent = Items["Search"],
    }) setThemed(Items["SearchIcon"], "ImageColor3", "Icon")

    Items["SearchIconUIPadding"] = Create("UIPadding", {
        Name = "UIPadding",
        PaddingLeft = UDim.new(0, 15),
        Parent = Items["Search"],
    })

    Items["SearchBox"] = Create("TextBox", {
        Name = "SearchBox",
        CursorPosition = -1,
        FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        PlaceholderText = "Search...",
        Text = "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Items["Search"],
    })
    setThemed(Items["SearchBox"], "TextColor3", "Text")
    setThemed(Items["SearchBox"], "PlaceholderColor3", "Placeholder")

    Items["SearchBoxUIPadding"] = Create("UIPadding", {
        Name = "SearchBoxUIPadding",
        PaddingLeft = UDim.new(0, 23),
        Parent = Items["SearchBox"],
    })
    
	
	
	Window.Items = Items
	
	local function findOption()
	    local searchTerm = Items["SearchBox"].Text:lower()
	    for _, page in ipairs(Window.Pages) do
	        local name = page.Name:lower()
	        local isVisible = string.find(name, searchTerm, 1, true) ~= nil	
	        if page.Items["Inactive"].Visible ~= isVisible then
	            page.Items["Inactive"].Visible = isVisible
	        end
	    end
		for _, deco in ipairs(Items["ScrollTab"]:GetChildren()) do
            if deco:IsA"Frame" and deco.Name == "TabDivider" then
                deco.Visible = searchTerm == ""
            end
        end
	end
	
    Items["SearchBox"]:GetPropertyChangedSignal("Text"):Connect(findOption)


	local dragging_ = false
	local dragInput
	local dragStart
	local startPos
	local dragTarget
	
	local function update(input)
	    local delta = input.Position - dragStart
	    dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	local function onDragStart(input, moving)
	    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
	        dragging_ = true
	        dragInput = input
	        dragStart = input.Position
	        dragTarget = moving
	        startPos = moving.Position
	    end
	end
	
	local function onDragUpdate(input)
	    if dragging_ and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
	        dragInput = input
	    end
	end
	
	Items["Topbar"].InputBegan:Connect(function(input)
	    onDragStart(input, Items["Base"])
	end)
	Items["Topbar"].InputChanged:Connect(onDragUpdate)
	
	local floatingDragConn1 = Items["FloatingButtonIcon"].InputBegan:Connect(function(input)
	    onDragStart(input, Items["FloatingButton"])
	end)
	local floatingDragConn2 = Items["FloatingButtonIcon"].InputChanged:Connect(onDragUpdate)
	
	UserInputService.InputChanged:Connect(function(input)
	    if input == dragInput and dragging_ then
	        update(input)
	    end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
	    if input == dragInput then
	        dragging_ = false
	        dragInput = nil
	    end
	end)
		
	local function CheckSize()
	    local scale = Items["BaseUIScale"].Scale
	    local padding = Items["TopbarLayout"].Padding.Offset
	    local iconWidth = Items["Icon"].AbsoluteSize.X / scale
	    local textFrameWidth = Items["TextFrame"].AbsoluteSize.X / scale
	    local windowControlsWidth = Items["WindowControls"].AbsoluteSize.X / scale
	    local totalWidth = Items["Topbar"].AbsoluteSize.X / scale
	    local newWidth = totalWidth - (iconWidth + textFrameWidth + windowControlsWidth + padding * 3 + Items["TopbarPadding"].PaddingLeft.Offset + Items["TopbarPadding"].PaddingRight.Offset)
	    Items["Separator"].Size = UDim2.new(0, newWidth, 1, 0)
	end
	
	Items["Topbar"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["WindowControls"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["TextFrame"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	task.defer(CheckSize)
		
	
	function Window:Unload()
		if onUnloadCallback then
			onUnloadCallback()  
		end
		Folder:Destroy()
		unloaded = true
	end

	function Window.onUnloaded(callback)
		onUnloadCallback = callback
	end
	
	function Window:SetSize(Size)
		Items["Base"].Size = Size
	end
	function Window:GetSize(Size)
		return Items["Base"].Size
	end
	
	function Window:SetScale(Scale)
		Items["BaseUIScale"].Scale = Scale
	end
	function Window:GetScale()
		return Items["BaseUIScale"].Scale
	end
	
	function Window:SetState(State)
		windowState = State
		Items["Base"].Visible = State
		Items["FloatingButton"].Visible =  not State -- opposite of the Base
	end
	function Window:GetState()
		return windowState
	end
	
	function Window:EditOpenButton(Data)
	    Data = Data or {}  
	    if Data.Title ~= nil then
	        Items["FloatingButtonTitle"].Text = Data.Title
	    end   
	    if Data.Icon ~= nil then
	        TanukiLib:ResolveImage(Data.Icon, Items["FloatingButtonIcon"], "Image")
	    end    
	    if Data.Enabled ~= nil then
	        Items["FloatingButton"].Visible = not Window:GetState() and Data.Enabled
	    end   
	    if Data.Draggable ~= nil then
		    if Data.Draggable then
		        if not floatingDragConn1.Connected then
		            floatingDragConn1 = Items["FloatingButtonIcon"].InputBegan:Connect(function(input)
		                onDragStart(input, Items["FloatingButton"])
		            end)
		            floatingDragConn2 = Items["FloatingButtonIcon"].InputChanged:Connect(onDragUpdate)
		        end
		    else
		        floatingDragConn1:Disconnect()
		        floatingDragConn2:Disconnect()
		    end
		end
	end
	

	local function ToggleMenu()
	    local state = not Window:GetState()
	    Window:SetState(state)
	    if not state then
	        TanukiLib:Notify({
	            Name = "Interface",
	            Description = "Click the floating button to open the UI again!",
	            Duration = 5
	        })
	    end
	end

	Items["CloseButton"].MouseButton1Click:Connect(ToggleMenu)
	Items["FloatingButtonTitle"].MouseButton1Click:Connect(ToggleMenu)
	
	local TweenSettings = {
		SidebarExpand = UDim2.new(0.32, 0, 1, -50),
		SidebarCollapse = UDim2.new(0.12, 0, 1, -50),
		ElementsExpand = { Size = UDim2.new(1 - 0.32, 0, 1, -50), Position = UDim2.new(0.32, 0, 0, 50) },
		ElementsCollapse = { Size = UDim2.new(1 - 0.12, 0, 1, -50), Position = UDim2.new(0.12, 0, 0, 50) },

		EasingStyle = Enum.EasingStyle.Sine
	}

	local function ChangeState(State)
	    if State == "Expand" then
	        Tween(Items["Sidebar"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
	            Size = TweenSettings.SidebarExpand
	        }):Play()
			Tween(Items["Body"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                Size = TweenSettings.ElementsExpand.Size,
                Position = TweenSettings.ElementsExpand.Position
            }):Play()
	        for _, p in ipairs(Window.Pages) do
	            
	            local pad = p.Items["InactiveUIPadding"]
	            pad.PaddingLeft = UDim.new(0, 24)
	            pad.PaddingRight = UDim.new(0, 35)
	            pad.PaddingTop = UDim.new(0, 1)
	            pad.PaddingBottom = UDim.new(0, 0)
	            p.Items["InactiveTitle"].Visible = true
	        end
	    elseif State == "Collapse" then
	        Tween(Items["Sidebar"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
	            Size = TweenSettings.SidebarCollapse
	        }):Play()
		Tween(Items["Body"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                Size = TweenSettings.ElementsCollapse.Size,
                Position = TweenSettings.ElementsCollapse.Position
            }):Play()
	        for _, p in ipairs(Window.Pages) do
	            
	            local pad = p.Items["InactiveUIPadding"]
	            pad.PaddingLeft = UDim.new(0, 0)
	            pad.PaddingRight = UDim.new(0, 0)
	            pad.PaddingTop = UDim.new(0, 1)
	            pad.PaddingBottom = UDim.new(0, 0)
	            p.Items["InactiveTitle"].Visible = false
	        end
	    end
	end
	
	Items["SidebarButton"].MouseButton1Click:Connect(function()
	    sidebarExpanded = not sidebarExpanded
	    ChangeState(sidebarExpanded and "Expand" or "Collapse")
	end)
	
	table.insert(TanukiLib.themeCallbacks, function(name)
	    local newTheme = TanukiLib.Themes[name] or {}
	    for k in pairs(Theme) do
	        Theme[k] = newTheme[k] or Theme[k]
	    end
	    for _, entry in ipairs(themeRegistry) do
	        if entry.inst and entry.inst.Parent then
	            entry.inst[entry.prop] = Theme[entry.key]
	        end
	    end
	end)
	
	task.spawn(function()
		local assetList = {}
		for _, assetId in pairs(assets) do
			table.insert(assetList, assetId)
		end
		ContentProvider:PreloadAsync(assetList)
	end)
	
	sidebarExpanded = true
	windowState = true
	ChangeState(Window.SidebarState)
	
	return setmetatable(Window, TanukiLib)
end


TanukiLib.PageGroup = function(self, Data)
    Data = Data or {}
    
	local PageGroup = {
	    Window = self,
	    Parent = self,
	    Items = { },
	    
	}
	
	local Items = {}
	Items["PageGroup"] = Create("Frame", {
	    Name = "PageGroup",
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    BorderSizePixel = 0,
	    Size = UDim2.fromScale(1, 0),
	    Parent = PageGroup.Window.Items["ScrollTab"],
	})
	
	Items["PageTabSwitchers"] = Create("Frame", {
	    Name = "PageTabSwitchers",
	    BackgroundTransparency = 1,
	    BorderSizePixel = 0,
	    Size = UDim2.fromScale(1, 1),
	    Parent = Items["PageGroup"] ,
	})
	
	Create("UIListLayout", {
	    Padding = UDim.new(0, 15),
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Parent = Items["PageTabSwitchers"],
	})
	
	Create("UIPadding", {
	    PaddingBottom = UDim.new(0, 6),
	    Parent = Items["PageTabSwitchers"],
	})
	PageGroup.Items = Items
	
	return setmetatable(PageGroup, TanukiLib.PagesGroup)
end

TanukiLib.Page = function(self, Data)
    Data = Data or {}
    
    local Window = self.Parent or self 
    local scrollParent = self.Items["PageTabSwitchers"] or self.Items["ScrollTab"]
    
	local Page = {
	    Window = Window,
	    Name = Data.Name or "Main",
	    Icon = Data.Icon or "100050851789190",
		
	    Items = { },
	    Sections = { },
	
	}
	
	local Items = {}
	
	
	Items["Inactive"] = Create("ImageButton", {
	    Name = "Inactive",
	    Size = UDim2.new(1, 0, 0, 38),
	    Position = UDim2.new(0, 10, 0, 10),
	    BackgroundColor3 = Color3.fromRGB(16,16,16),
	    ImageTransparency = 1,
	    BackgroundTransparency = 0,
	    Parent = scrollParent,
	})
	
	Items["InactiveCorner"] = Create("UICorner", {
	    Name = "Corner",
	    Parent = Items["Inactive"]
	})
	
	Items["InactiveUIStroke"] = Create("UIStroke", {
	    Name = "BaseUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 1,
	    Parent = Items["Inactive"]
	}) setThemed(Items["InactiveUIStroke"], "Color", "Outline")
	
	Items["InactiveLayout"] = Create("UIListLayout", {
	    Name = "Layout",
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    Padding = UDim.new(0, 5),
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Inactive"]
	})
	
	Items["InactiveIcon"] = Create("ImageLabel", {
	    Name = "Icon",
	    Size = UDim2.fromOffset(20, 20),
	    Position = UDim2.new(0, 0, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    ImageColor3 = Color3.fromRGB(255, 255, 255),
	    ImageTransparency = 0,
	    ScaleType = Enum.ScaleType.Fit,
	    BackgroundTransparency = 1,
	    Parent = Items["Inactive"]
	}) setThemed(Items["InactiveIcon"], "ImageColor3", "Icon")
	TanukiLib:ResolveImage(Page.Icon, Items["InactiveIcon"], "Image")
	
	Items["InactiveTitle"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	    RichText = true,
	    Size = UDim2.fromScale(1, 0),
	    AutomaticSize = Enum.AutomaticSize.Y,
	    TextTruncate = Enum.TextTruncate.SplitWord,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    TextYAlignment = Enum.TextYAlignment.Top,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    Text = Page.Name,
	    BackgroundTransparency = 1,
	    TextSize = 16,
	    Parent = Items["Inactive"]
	}) setThemed(Items["InactiveTitle"], "TextColor3", "Text")
	
	Items["InactiveUIPadding"] = Create("UIPadding", {
	    Name = "InactiveUIPadding",
	    PaddingLeft = UDim.new(0, 24),
	    PaddingRight = UDim.new(0, 35),
	    PaddingTop = UDim.new(0, 1),
	    Parent = Items["Inactive"]
	})
	
	
	Items["Elements"] = Create("Frame", {
	    Name = "Elements",
	    Size = UDim2.new(1, 0, 1, 0),
	    Position = UDim2.new(0, 0, 0, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Active = true,
	    BackgroundTransparency = 1,
	    ClipsDescendants = true,
	    Parent = Page.Window.Items["Body"]
	})
	
	Items["ElementsPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    PaddingTop = UDim.new(0, 10),
	    PaddingBottom = UDim.new(0, 10),
	    Parent = Items["Elements"]
	})
	
	Items["ElementsScroll"] = Create("ScrollingFrame", {
	    Name = "ElementsScroll",
	    Size = UDim2.fromScale(1, 1),
	    AutomaticCanvasSize = Enum.AutomaticSize.Y,
	    BottomImage = "",
	    CanvasSize = UDim2.new(),
	    ScrollBarImageTransparency = 0.5,
	    ScrollBarThickness = 1,
	    TopImage = "",
		ClipsDescendants = false,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    ScrollingEnabled = true,
	    BackgroundTransparency = 1,
	    Parent = Items["Elements"]
	})
	
	Items["ElementsScrollPadding"] = Create("UIPadding", {
	    Name = "Padding",
	    PaddingTop = UDim.new(0, 5),
	    PaddingBottom = UDim.new(0, 5),
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    Parent = Items["ElementsScroll"]
	})
	
	Items["ElementsScrollingList"] = Create("UIListLayout", {
	    Name = "ElementsScrollingList",
	    Padding = UDim.new(0, 10),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    HorizontalAlignment = Enum.HorizontalAlignment.Center,
	    Parent = Items["ElementsScroll"]
	})
	
	Page.Items = Items

	local function RefreshPageView()
	    local ease = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
	
	    for _, p in ipairs(Page.Window.Pages) do
	        local isActive = (p == Page)
	
	        Tween(p.Items["Inactive"], ease, {
	            BackgroundTransparency = isActive and 0.98 or 1
	        }):Play()
	
	        Tween(p.Items["InactiveUIStroke"], ease, {
	            Transparency = isActive and 0.95 or 1
	        }):Play()
	
	        Tween(p.Items["InactiveIcon"], ease, {
	            ImageTransparency = isActive and 0.1 or 0.5
	        }):Play()
	
	        Tween(p.Items["InactiveTitle"], ease, {
	            TextTransparency = isActive and 0.1 or 0.5
	        }):Play()
	
	        p.Items["Elements"].Visible = isActive
	    end
	
	    ActivePage = Page
	end

	Items["Inactive"].MouseButton1Click:Connect(function()
		RefreshPageView()
	end)

	function Page:Select()
		RefreshPageView()
	end

	function Page:SetName(Name)
		Items["InactiveTitle"].Text = Name
	end

	function Page:SetVisibility(State)
		Items["Inactive"].Visible = State
	end

	function Page:Destroy()
		Items["Inactive"]:Destroy()
	end
			
	Page.Window.Pages[#Page.Window.Pages + 1] = Page
	return setmetatable(Page, TanukiLib.Pages)
end

TanukiLib.Divider = function(self, Data)
    Data = Data or {}
    
	local Divider = {
	    Window = self,
	}
	
	local DividerFrame = Create("Frame", {
		Name = "TabDivider",
		Size = UDim2.new(1, -21, 0, 12),
		Position = UDim2.fromScale(0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = Divider.Window.Items["ScrollTab"]
	})

	local Line = Create("Frame", {
		Name = "Line",
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Parent = DividerFrame
	})
	
	Create("UICorner", {
	    Name = "SectionUICorner",
	    Parent = Line
	})

	setThemed(Line, "BackgroundColor3", "Outline")
	
	return Divider
end

TanukiLib.Section = function(self, Data)
    Data = Data or {}

    local Section = {
        Window = self.Window,
        Page = self,
        
        Name = Data.Name or "le",
        
        Items = { },
        Elements = { }
    }
	
	local Items = {}
	Items["Section"] = Create("Frame", {
	    Name = "Section",
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BorderSizePixel = 0,
	    Position = UDim2.fromScale(0, 6.78e-08),
	    Size = UDim2.fromScale(1, 0),
	    ClipsDescendants = true,
	    Parent = Section.Page.Items["ElementsScroll"],
	})
	
	Items["SectionUICorner"] = Create("UICorner", {
	    Name = "SectionUICorner",
	    Parent = Items["Section"]
	})
	
	Items["SectionUIListLayout"] = Create("UIListLayout", {
	    Name = "SectionUIListLayout",
	    Padding = UDim.new(0, 10),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Parent = Items["Section"]
	})
	
	Items["SectionUIPadding"] = Create("UIPadding", {
	    Name = "SectionUIPadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 12),
	    Parent = Items["Section"]
	})
	
	Section.Items = Items
    
    
    Section.Page.Sections[Section.Name] = Section
    return setmetatable(Section, TanukiLib.Sections)
end

TanukiLib.Sections.Header = function(self, Data)         
    Data = Data or {}

    local Header = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Button",
    }
    local Items ={}
	Items["Header"] = Create("Frame", {
	    Name = "Header",
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    LayoutOrder = 0,
	    Size = UDim2.fromScale(1, 0),
	    Parent = Header.Section.Items["Section"],
	})
	
	Items["HeaderUIPadding"] = Create("UIPadding", {
	    Name = "UIPadding",
	    PaddingBottom = UDim.new(0, 5),
	    Parent = Items["Header"]
	})
	
	Items["HeaderText"] = Create("TextLabel", {
	    Name = "HeaderText",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Header.Name,
	    TextSize = 16,
	    TextTransparency = 0.3,
	    TextWrapped = true,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Size = UDim2.fromScale(1, 0),
	    Parent = Items["Header"]
	}) setThemed(Items["HeaderText"], "TextColor3", "Text")
	
	Header.Items = Items
end

TanukiLib.Sections.Button = function(self, Data)         
    Data = Data or {}

    local Button = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Button",
        Desc = Data.Description or nil,
        Callback = Data.Callback or function() end,
        
    }
    
    local Items = {}
	Items["Button"] = Create("ImageButton", {
	    Name = "Button",
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Size = UDim2.new(1, 0, 0, 38),
	    Parent = Button.Section.Items["Section"],
	})
	
	Items["SectionUICorner"] = Create("UICorner", {
	    Name = "SectionUICorner",
	    Parent = Items["Button"]
	})
	
	Items["SectionUIStroke"] = Create("UIStroke", {
	    Name = "SectionUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 0.95,
	    Parent = Items["Button"]
	}) setThemed(Items["SectionUIStroke"], "Color", "Outline")
	
	Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Button"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 6),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, -26, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Button.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Button.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = Button.Desc ~= nil and Button.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")
	
	Items["ButtonImage"] = Create("ImageLabel", {
	    Name = "ButtonImage",
	    Image = "rbxassetid://10709791437",
	    ImageTransparency = 0.6,
	    AnchorPoint = Vector2.new(1, 0.5),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Position = UDim2.fromScale(1, 0.5),
	    Size = UDim2.fromOffset(15, 15),
	    Parent = Items["Frame"]
	}) setThemed(Items["ButtonImage"], "ImageColor3", "Icon")
	
	Button.Items = Items
	local locked = false
	
	local TweenSettings = {
		TitleTransparency = 0.4,
		TitleHoverTransparency = 0.2,	
		
		DescTransparency = 0.6,
		DescHoverTransparency = 0.4,
		
		
		EasingStyle = Enum.EasingStyle.Sine
	}

	local function ChangeState(State)
		if State == "Idle" then
			Tween(Items["TitleText"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				TextTransparency = TweenSettings.TitleTransparency
			}):Play()
			Tween(Items["DescText"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				TextTransparency = TweenSettings.DescTransparency
			}):Play()
			Tween(Items["ButtonImage"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				ImageTransparency = TweenSettings.DescHoverTransparency
			}):Play()
		elseif State == "Hover" then
			Tween(Items["TitleText"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				TextTransparency = TweenSettings.TitleHoverTransparency
			}):Play()
			Tween(Items["DescText"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				TextTransparency = TweenSettings.DescHoverTransparency
			}):Play()
			Tween(Items["ButtonImage"], TweenInfo.new(0.2, TweenSettings.EasingStyle), {
				ImageTransparency = TweenSettings.DescHoverTransparency
			}):Play()
		end
	end 
	
	local function Callback()
		if locked then return end
		if Button.Callback then
			Button.Callback()
		end
	end
	Items["Button"].MouseButton1Click:Connect(Callback)
	
	Items["Button"].MouseEnter:Connect(function()
		ChangeState("Hover")
	end)
	Items["Button"].MouseLeave:Connect(function()
		ChangeState("Idle")
	end)
	
	function Button:UpdateName(Name)
		Items["TitleText"].Text = Name
	end
	function Button:SetName(Name)
		Items["TitleText"].Text = Name
	end	
	function Button:UpdateDesc(Name)
		Items["DescText"].Text = Name
	end
	function Button:SetDesc(Name)
		Items["DescText"].Text = Name
	end
	
	function Button:SetVisibility(State)
		Items["Button"].Visible = State
	end
	function Button:Destroy()
		Items["Button"]:Destroy()
	end
	
	Button.Section.Elements[#Button.Section.Elements+1] = Button
	return Button
end


TanukiLib.Sections.Toggle = function(self, Data)
    Data = Data or {}
    
    local Toggle = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Toggle",
        Desc = Data.Description or nil,
        Default = Data.Default or false,
        Flag = Data.Flag or nil,
        Callback = Data.Callback or Data.callback or function() end,

    }
    local Items = {}
    local locked = false
	Items["Toggle"] = Create("Frame", {
	    Name = "Toggle",
	    AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Size = UDim2.new(1, 0, 0, 38),
	    Parent = Toggle.Section.Items["Section"],
	})
	
	Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Toggle"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 6),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, -41, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Toggle.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Toggle.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
	    Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = Toggle.Desc ~= nil and Toggle.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")
	
	Items["ToggleButton"] = Create("ImageButton", {
	    Name = "Toggle",
	    AutoButtonColor = false,
	    AnchorPoint = Vector2.new(1, 0.5),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 0,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Position = UDim2.fromScale(1, 0.5),
	    Size = UDim2.fromOffset(41, 21),
	    BackgroundTransparency = 0.8,
	    Parent = Items["Frame"]
	}) setThemed(Items["ToggleButton"], "BackgroundColor3", "Button")
	
	Items["ToggleButtonCorner"] = Create("UICorner", {
	    Name = "Corner",
	    CornerRadius = UDim.new(1, 0),
	    Parent = Items["ToggleButton"]
	})
	
	Items["ToggleUIPadding"] = Create("UIPadding", {
	    Name = "ToggleUIPadding",
	    PaddingBottom = UDim.new(0, 1),
	    PaddingLeft = UDim.new(0, -2),
	    PaddingRight = UDim.new(0, 3),
	    PaddingTop = UDim.new(0, 1),
	    Parent = Items["ToggleButton"]
	})
	
	Items["TogglerHead"] = Create("ImageLabel", {
	    Name = "TogglerHead",
	    AnchorPoint = Vector2.new(1, 0.5),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 0,
	    BorderColor3 = Color3.fromRGB(0, 0, 0),
	    BorderSizePixel = 0,
	    Position = UDim2.fromScale(0.5, 0.5),
	    Size = UDim2.fromOffset(15, 15),
	    ZIndex = 2,
	    BackgroundTransparency = 0.8,
	    Parent = Items["ToggleButton"]
	}) setThemed(Items["TogglerHead"], "BackgroundColor3", "Icon")
	
	Items["TogglerHeadCorner"] = Create("UICorner", {
	    Name = "Corner",
	    CornerRadius = UDim.new(1, 0),
	    Parent = Items["TogglerHead"]
	})
	
	Toggle.Items = Items
	
	local toggle1Transparency = {Enabled = 0.5, Disabled = 0.85}
	local togglerHeadTransparency = {Enabled = 0.6, Disabled = 0.9}

	local TweenSettings = {
		Info = TweenInfo.new(0.15, Enum.EasingStyle.Quad),

		EnabledPosition = UDim2.new(1, 0, 0.5, 0),
		DisabledPosition = UDim2.new(0.5, 0, 0.5, 0),
	}

	local togglebool = Toggle.Default
	
	local function NewState(State, callback)
		local transparencyValues = State and {toggle1Transparency.Enabled, togglerHeadTransparency.Enabled}
			or {toggle1Transparency.Disabled, togglerHeadTransparency.Disabled}
		local position = State and TweenSettings.EnabledPosition or TweenSettings.DisabledPosition

		Tween(Items["ToggleButton"], TweenSettings.Info, {
			BackgroundTransparency = transparencyValues[1]
		}):Play()

		Tween(Items["TogglerHead"], TweenSettings.Info, {
			BackgroundTransparency = transparencyValues[2]
		}):Play()

		Tween(Items["TogglerHead"], TweenSettings.Info, {
			Position = position
		}):Play()

		Toggle.State = State
		if callback then
			callback(togglebool)
		end
	end

	NewState(togglebool)

	local function Toggling()
		if locked then return end
		togglebool = not togglebool
		NewState(togglebool, Toggle.Callback)
	end

	Items["ToggleButton"].MouseButton1Click:Connect(Toggling)

	function Toggle:Toggle()
		Toggling()
	end
	function Toggle:UpdateState(State)
		togglebool = State
		NewState(togglebool, Toggle.Callback)
	end
	function Toggle:GetState()
		return togglebool
	end
	
	function Toggle:UpdateName(Name)
		Items["TitleText"].Text = Name
	end
	function Toggle:SetName(Name)
		Items["TitleText"].Text = Name
	end
	function Toggle:UpdateDesc(Name)
		Items["DescText"].Text = Name
	end
	function Toggle:SetDesc(Name)
		Items["DescText"].Text = Name
	end
	function Toggle:SetVisibility(State)
		Items["Toggle"].Visible = State
	end
	function Toggle:Destroy()
		Items["Toggle"]:Destroy()
	end
	
   function Toggle:Lock()
        locked = true
        setElementLock(Items["Toggle"], true)
    end
    function Toggle:Unlock()
        locked = false
        setElementLock(Items["Toggle"], false)
    end
    function Toggle:GetLocked()
		return locked
	end
	
	if Toggle.Flag then
		TanukiLib.Options[Toggle.Flag] = Toggle
	end
	
	Toggle.Section.Elements[#Toggle.Section.Elements+1] = Toggle
	return Toggle
end

TanukiLib.Sections.Slider = function(self, Data)
    Data = Data or {}

    local Slider = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Slider",
        Desc = Data.Description or nil,
        Flag = Data.Flag or nil,
        Minimum = Data.Minimum or 0,
        Maximum = Data.Maximum or 100,
        Default = Data.Default or 0,
        Precision = Data.Precision or nil,
        Prefix = Data.Prefix or "",
        Suffix = Data.Suffix or "",
        DisplayMethod = Data.DisplayMethod or "Value",
        Callback = Data.Callback or function() end,
        onInputComplete = Data.onInputComplete or nil,

        Value = nil,
    }

    local Items = {}

    Items["Slider"] = Create("Frame", {
        Name = "Slider",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Slider.Section.Items["Section"],
    })
    
    Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Slider"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 10),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	    --Size = UDim2.new(0, 0, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Slider.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Slider.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = Slider.Desc ~= nil and Slider.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")

    Items["SliderValue"] = Create("TextBox", {
        Name = "SliderValue",
        FontFace = Font.new(assets.interFont),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        TextTransparency = 0.1,
        BackgroundTransparency = 0.92,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Position = UDim2.fromScale(-0.0789, 0.171),
        Size = UDim2.fromOffset(41, 21),
        ClipsDescendants = true,
        Parent = Items["Frame"],
    }) 
    setThemed(Items["SliderValue"], "BackgroundColor3", "Surface")
    setThemed(Items["SliderValue"], "TextColor3", "Text")

    Items["SliderValueUICorner"] = Create("UICorner", {
        Name = "SliderValueUICorner",
        CornerRadius = UDim.new(0, 4),
        Parent = Items["SliderValue"],
    })

    Items["SliderValueUIStroke"] = Create("UIStroke", {
        Name = "SliderValueUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["SliderValue"],
    }) setThemed(Items["SliderValueUIStroke"] , "Color", "Outline")

    Items["SliderValueUIPadding"] = Create("UIPadding", {
        Name = "SliderValueUIPadding",
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
        Parent = Items["SliderValue"],
    })

    Items["SliderBar"] = Create("ImageLabel", {
        Name = "SliderBar",
        BackgroundTransparency = 0,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.219, 0.457),
        Size = UDim2.fromOffset(123, 3),
        Parent = Items["Frame"],
    }) setThemed(Items["SliderBar"] , "BackgroundColor3", "Button")
    
    Items["SliderBarCorner"] = Create("UICorner", {
	    Name = "Corner",
	    CornerRadius = UDim.new(1, 0),
	    Parent = Items["SliderBar"]
	})

    Items["SliderHead"] = Create("ImageButton", {
        Name = "SliderHead",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 0,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Parent = Items["SliderBar"],
    }) setThemed(Items["SliderHead"] , "BackgroundColor3", "Icon")
    
    Items["SliderHeadCorner"] = Create("UICorner", {
	    Name = "Corner",
	    CornerRadius = UDim.new(1, 0),
	    Parent = Items["SliderHead"]
	})

    Slider.Items = Items

    local dragging = false
    local dragInput = nil
    local locked = false
    local finalValue

    local DisplayMethods = {
        Hundredths = function(v) return string.format("%.2f", v) end,
        Tenths = function(v) return string.format("%.1f", v) end,
        Round = function(v, p) return p and string.format("%." .. p .. "f", v) or tostring(math.round(v)) end,
        Degrees = function(v, p) return (p and string.format("%." .. p .. "f", v) or tostring(v)) .. "°" end,
        Percent = function(v, p)
            local pct = (v - Slider.Minimum) / (Slider.Maximum - Slider.Minimum) * 100
            return (p and string.format("%." .. p .. "f", pct) or tostring(math.round(pct))) .. "%"
        end,
        Value = function(v, p) return p and string.format("%." .. p .. "f", v) or tostring(v) end,
    }

    local ValueDisplayMethod = DisplayMethods[Slider.DisplayMethod] or DisplayMethods.Value

    local function SetValue(val, ignorecallback)
        local posXScale

        if typeof(val) == "Instance" then
            posXScale = math.clamp((val.Position.X - Items["SliderBar"].AbsolutePosition.X) / Items["SliderBar"].AbsoluteSize.X, 0, 1)
        else
            posXScale = (val - Slider.Minimum) / (Slider.Maximum - Slider.Minimum)
        end

        Items["SliderHead"].Position = UDim2.new(posXScale, 0, 0.5, 0)
        finalValue = posXScale * (Slider.Maximum - Slider.Minimum) + Slider.Minimum
        Items["SliderValue"].Text = (Slider.Prefix or "") .. ValueDisplayMethod(finalValue, Slider.Precision) .. (Slider.Suffix or "")

        Slider.Value = finalValue

        if not ignorecallback then
            task.spawn(function()
                Slider.Callback(finalValue)
            end)
        end
    end

    SetValue(Slider.Default, true)

    Items["SliderHead"].InputBegan:Connect(function(input)
        if locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            SetValue(input)
        end
    end)

    Items["SliderBar"].InputBegan:Connect(function(input)
        if locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            SetValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
            if Slider.onInputComplete then
                Slider.onInputComplete(finalValue)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if locked then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
            SetValue(input)
        end
    end)

    Items["SliderValue"].FocusLost:Connect(function()
        if locked then
            Items["SliderValue"].Text = (Slider.Prefix or "") .. ValueDisplayMethod(finalValue, Slider.Precision) .. (Slider.Suffix or "")
            return
        end
        local inputText = Items["SliderValue"].Text
        local value, isPercent = inputText:match("^(%-?%d+%.?%d*)(%%?)$")

        if value then
            value = tonumber(value)
            isPercent = isPercent == "%"
            if isPercent then
                value = Slider.Minimum + (value / 100) * (Slider.Maximum - Slider.Minimum)
            end
            SetValue(math.clamp(value, Slider.Minimum, Slider.Maximum))
        else
            Items["SliderValue"].Text = ValueDisplayMethod(finalValue, Slider.Precision)
        end

        if Slider.onInputComplete then
            Slider.onInputComplete(finalValue)
        end
    end)

    local function CheckSize()
	    local scale = Slider.Window.Items["BaseUIScale"].Scale
	    local padding = Items["FrameLayout"].Padding.Offset
	    local valueWidth = Items["SliderValue"].AbsoluteSize.X / scale
	    local nameWidth = Items["TextFrame"].AbsoluteSize.X / scale
	    local totalWidth = Items["Frame"].AbsoluteSize.X / scale
	    local newBarWidth = (totalWidth - (padding + valueWidth + nameWidth + 20))
	    Items["SliderBar"].Size = UDim2.new(0, newBarWidth, 0, 3)
	end

    CheckSize()
    Items["TextFrame"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
    Items["Slider"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)

    function Slider:UpdateName(Name)
	    Items["TitleText"].Text = Name
	end
	function Slider:SetName(Name)
	    Items["TitleText"].Text = Name
	end
	function Slider:UpdateDesc(Name)
	    Items["DescText"].Text = Name
	end
	function Slider:SetDesc(Name)
	    Items["DescText"].Text = Name
	end
	
    function Slider:SetVisibility(State)
	    Items["Slider"].Visible = State
	end
	function Slider:Destroy()
	    Items["Slider"]:Destroy()
	end
	
    function Slider:Lock()
        locked = true
        setElementLock(Items["Slider"], true)
    end
    function Slider:Unlock()
        locked = false
        setElementLock(Items["Slider"], false)
    end
    function Slider:GetLocked()
		return locked
	end
    function Slider:UpdateValue(Value)
		SetValue(tonumber(Value), true)
	end
    function Slider:GetValue()
		return finalValue
	end
    
    if Slider.Flag then
		TanukiLib.Options[Slider.Flag] = Slider
	end
					
    Slider.Section.Elements[#Slider.Section.Elements + 1] = Slider
    return Slider
end

TanukiLib.Sections.Input = function(self, Data)
    Data = Data or {}

    local Input = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Input",
        Desc = Data.Description or nil,
        Default = Data.Default or "",
        Placeholder = Data.Placeholder or "",
        CharacterLimit = Data.CharacterLimit or nil,
        AcceptedCharacters = Data.AcceptedCharacters or "All",
        Callback = Data.Callback or function() end,
        onChanged = Data.onChanged or nil,
        Flag = Data.Flag or nil,
        
        Text = Data.Default or "",
    }

    local Items = {}
    

    Items["Input"] = Create("Frame", {
        Name = "Input",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Input.Section.Items["Section"],
    })
    
    Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Input"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 10),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	    --Size = UDim2.new(0, 0, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Input.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Input.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = Input.Desc ~= nil and Input.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")
	
	Items["Separator"] = Create("ImageLabel", {
        Name = "\0",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(123, 3),
        Parent = Items["Frame"],
    }) 
    
    Items["InputBox"] = Create("TextBox", {
        Name = "InputBox",
        FontFace = Font.new(assets.interFont),
        Text = Input.Default,
        PlaceholderText = Input.Placeholder,
        TextSize = 12,
        TextTransparency = 0.1,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 0.92,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(21, 21),
        Parent = Items["Frame"],
    })
	setThemed(Items["InputBox"], "BackgroundColor3", "Surface")
    setThemed(Items["InputBox"], "TextColor3", "Text")

    Items["InputBoxUICorner"] = Create("UICorner", {
        Name = "InputBoxUICorner",
        CornerRadius = UDim.new(0, 4),
        Parent = Items["InputBox"],
    })

    Items["InputBoxUIStroke"] = Create("UIStroke", {
        Name = "InputBoxUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["InputBox"],
    }) setThemed(Items["InputBoxUIStroke"], "Color", "Outline")

    Items["InputBoxUIPadding"] = Create("UIPadding", {
        Name = "InputBoxUIPadding",
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = Items["InputBox"],
    })

    Items["InputBoxUISizeConstraint"] = Create("UISizeConstraint", {
        Name = "InputBoxUISizeConstraint",
        Parent = Items["InputBox"],
    })

    Input.Items = Items
    local locked = false
    
    local function applyCharacterLimit(value)
        if Input.CharacterLimit then
            return value:sub(1, Input.CharacterLimit)
        end
        return value
    end

    local CharacterSubs = {
        All = function(value)
            return applyCharacterLimit(value)
        end,
        Numeric = function(value)
            local result = value:match("^%-?%d*$") and value or value:gsub("[^%d-]", ""):gsub("(%-)", function(match, pos)
                return pos == 1 and match or ""
            end)
            return applyCharacterLimit(result)
        end,
        Alphabetic = function(value)
            return applyCharacterLimit(value:gsub("[^a-zA-Z ]", ""))
        end,
        AlphaNumeric = function(value)
            return applyCharacterLimit(value:gsub("[^a-zA-Z0-9]", ""))
        end,
    }

    local FilterFn
    if type(Input.AcceptedCharacters) == "function" then
        FilterFn = Input.AcceptedCharacters
    else
        FilterFn = CharacterSubs[Input.AcceptedCharacters] or CharacterSubs.All
    end

    local function CheckSize()
	    local scale = Input.Window.Items["BaseUIScale"].Scale 
	    local padding = Items["FrameLayout"].Padding.Offset
	    local nameWidth = Items["TextFrame"].AbsoluteSize.X / scale
	    local inputWidth = Items["InputBox"].AbsoluteSize.X / scale
	    local totalWidth = Items["Frame"].AbsoluteSize.X / scale
	    local maxWidth = totalWidth - nameWidth - 20
	    local newWidth = totalWidth - (padding + inputWidth + nameWidth + 20)
	    Items["InputBoxUISizeConstraint"].MaxSize = Vector2.new(maxWidth, 9e9)
	    Items["Separator"].Size = UDim2.new(0, newWidth, 0, 3)
	end

    task.defer(CheckSize)
    Items["TextFrame"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["InputBox"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["Frame"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)

    Items["InputBox"].FocusLost:Connect(function()
        if locked then return end
        local filtered = FilterFn(Items["InputBox"].Text)
        Items["InputBox"].Text = filtered
        task.spawn(function()
            Input.Callback(filtered)
        end)
    end)

    Items["InputBox"]:GetPropertyChangedSignal("Text"):Connect(function()
        if locked then return end
        Items["InputBox"].Text = FilterFn(Items["InputBox"].Text)
        if Input.onChanged then
            Input.onChanged(Items["InputBox"].Text)
        end
        Input.Text = Items["InputBox"].Text
    end)

	function Input:UpdateName(Name)
	    Items["TitleText"].Text = Name
	end
	function Input:SetName(Name)
	    Items["TitleText"].Text = Name
	end
	function Input:UpdateDesc(Name)
	    Items["DescText"].Text = Name
	end
	function Input:SetDesc(Name)
	    Items["DescText"].Text = Name
	end
	
	function Input:SetVisibility(State)
	    Items["Input"].Visible = State
	end
	function Input:Destroy()
	    Items["Input"]:Destroy()
	end
	function Input:GetInput()
	    return Items["InputBox"].Text
	end
	function Input:UpdatePlaceholder(Placeholder)
	    Items["InputBox"].PlaceholderText = Placeholder
	end
	
	function Input:GetLocked()
	    return locked
	end

    function Input:Lock()
        locked = true
        setElementLock(Items["Input"], true)
    end

    function Input:Unlock()
        locked = false
        setElementLock(Items["Input"], false)
    end

    function Input:UpdateText(Text)
        local filtered = FilterFn(Text)
        Items["InputBox"].Text = filtered
        Input.Text = filtered
        task.spawn(function()
            Input.Callback(filtered)
        end)
    end
    
    if Input.Flag then
		TanukiLib.Options[Input.Flag] = Input
	end

    Input.Section.Elements[#Input.Section.Elements + 1] = Input
    return Input
end

TanukiLib.Sections.Keybind = function(self, Data)
    Data = Data or {}

    local Keybind = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Keybind",
        Desc = Data.Description or nil,
        Default = Data.Default or nil,
        Blacklist = Data.Blacklist or nil,
        Callback = Data.Callback or function() end,
        onBinded = Data.onBinded or nil,
        onBindHeld = Data.onBindHeld or nil,
        Flag = Data.Flag or nil,

        Value = nil,
    }

    local Items = {}
    local locked = false
    local focused
    local isBinding = false
    local reset = false
    local binded = Keybind.Default

    Items["Keybind"] = Create("Frame", {
        Name = "Keybind",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Keybind.Section.Items["Section"],
    })

    Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Keybind"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 6),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, -21, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Keybind.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Keybind.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = Keybind.Desc ~= nil and Keybind.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")
	
    Items["BinderBox"] = Create("TextBox", {
        Name = "BinderBox",
        CursorPosition = -1,
        FontFace = Font.new(assets.interFont),
        PlaceholderText = "...",
        Text = "",
        TextSize = 12,
        TextTransparency = 0.1,
        AnchorPoint = Vector2.new(1, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 0.92,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(21, 21),
        Parent = Items["Frame"],
    })
    setThemed(Items["BinderBox"], "TextColor3", "Text")
    setThemed(Items["BinderBox"], "BackgroundColor3", "Surface")

    Create("UICorner", {
        Name = "BinderBoxUICorner",
        CornerRadius = UDim.new(0, 4),
        Parent = Items["BinderBox"],
    })

    Create("UIStroke", {
        Name = "BinderBoxUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["BinderBox"],
    })
    setThemed(Items["BinderBox"]:FindFirstChild("BinderBoxUIStroke"), "Color", "Outline")

    Create("UIPadding", {
        Name = "BinderBoxUIPadding",
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = Items["BinderBox"],
    })

    Create("UISizeConstraint", {
        Name = "BinderBoxUISizeConstraint",
        Parent = Items["BinderBox"],
    })

    Keybind.Items = Items

    local function resetFocusState()
        focused = false
        isBinding = false
        Items["BinderBox"]:ReleaseFocus()
    end

    if binded then
        Items["BinderBox"].Text = binded.Name
    end

    Items["BinderBox"].Focused:Connect(function()
        if locked then Items["BinderBox"]:ReleaseFocus() return end
        focused = true
    end)

    Items["BinderBox"].FocusLost:Connect(function()
        focused = false
    end)

    UserInputService.InputBegan:Connect(function(inp)
        if focused and not isBinding then
            isBinding = true

            local Event
            Event = UserInputService.InputBegan:Connect(function(input)
                if Keybind.Blacklist and (table.find(Keybind.Blacklist, input.KeyCode) or table.find(Keybind.Blacklist, input.UserInputType)) then
                    Items["BinderBox"]:ReleaseFocus()
                    resetFocusState()
                    Event:Disconnect()
                    return
                end

                if input.UserInputType == Enum.UserInputType.Keyboard then
                    binded = input.KeyCode
                    Items["BinderBox"].Text = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                    binded = input.UserInputType
                    Items["BinderBox"].Text = input.UserInputType.Name
                end

                if Keybind.onBinded then
                    Keybind.onBinded(binded)
                end
                reset = true
                resetFocusState()
                Event:Disconnect()
            end)
        else
            if not reset and (inp.KeyCode == binded or inp.UserInputType == binded) then
                if Keybind.Callback then
                    Keybind.Callback(binded)
                end
                if Keybind.onBindHeld then
                    Keybind.onBindHeld(true, binded)
                end
            else
                reset = false
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if not focused and not isBinding then
            if inp.KeyCode == binded or inp.UserInputType == binded then
                if Keybind.onBindHeld then
                    Keybind.onBindHeld(false, binded)
                end
            end
        end
    end)

    function Keybind:Bind(Key)
        binded = Key
        Items["BinderBox"].Text = Key.Name
    end

    function Keybind:Unbind()
        binded = nil
        Items["BinderBox"].Text = ""
    end

    function Keybind:GetBind()
        return binded
    end

    function Keybind:UpdateName(Name)
        Items["TitleText"].Text = Name
    end
    function Keybind:SetName(Name)
        Items["TitleText"].Text = Name
    end
    function Keybind:UpdateDesc(Name)
        Items["DescText"].Text = Name
    end

    function Keybind:SetDesc(Name)
        Items["DescText"].Text = Name
    end

    function Keybind:SetVisibility(State)
        Items["Keybind"].Visible = State
    end

    function Keybind:Destroy()
        Items["Keybind"]:Destroy()
    end

    function Keybind:Lock()
        locked = true
        setElementLock(Items["Keybind"], true)
    end

    function Keybind:Unlock()
        locked = false
        setElementLock(Items["Keybind"], false)
    end

    function Keybind:GetLocked()
        return locked
    end

    if Keybind.Flag then
        TanukiLib.Options[Keybind.Flag] = Keybind
    end

    Keybind.Section.Elements[#Keybind.Section.Elements + 1] = Keybind
    return Keybind
end

TanukiLib.Sections.Dropdown = function(self, Data)
    Data = Data or {}

    local Dropdown = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Dropdown",
        Desc = Data.Description or nil,
        Options = Data.Options or {},
        Default = Data.Default or nil,
        Multi = Data.Multi or false,
        Search = Data.Search or false,
        Required = Data.Required or false,
        Callback = Data.Callback or function() end,
        Flag = Data.Flag or nil,
        Value = nil,
    }

    local Items = {}
    local Selected = {}
    local OptionObjs = {}
    local dropped = false
    local locked = false
    local db = false

    Items["Dropdown"] = Create("ImageButton", {
        Name = "Dropdown",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.985,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Dropdown.Section.Items["Section"],
    })
    
    Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Dropdown"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 10),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.XY,
	    BackgroundTransparency = 1,
	    --Size = UDim2.new(0, 0, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Dropdown.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Dropdown.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = Dropdown.Desc ~= nil and Dropdown.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")

    Items["DropdownName"] = Create("TextLabel", {
        Name = "DropdownName",
        FontFace = Font.new(assets.interFont, Dropdown.Bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = Dropdown.Default and table.concat(Selected, ", ") or "...",
        RichText = true,
        TextSize = 13,
        TextTransparency = 0.5,
        TextTruncate = Enum.TextTruncate.SplitWord,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 38),
        Parent = Items["Frame"],
    }) setThemed(Items["DropdownName"], "TextColor3", "Text")
        
    Items["DropdownImage"] = Create("ImageLabel", {
        Name = "DropdownImage",
        Image = "rbxassetid://18865373378",
        ImageTransparency = 0.5,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 12),
        Size = UDim2.fromOffset(14, 14),
        Parent = Items["Frame"],
    }) setThemed(Items["DropdownImage"], "ImageColor3", "Icon")

    Items["DropdownFrame"] = Create("ScrollingFrame", {
	    Name = "DropdownMenu",
	    AutomaticCanvasSize = Enum.AutomaticSize.Y,
	    CanvasSize = UDim2.new(),
	    ScrollBarImageTransparency = 0.8,
	    ScrollBarThickness = 2,
	    TopImage = "",
	    BottomImage = "",
	    ScrollingEnabled = true,
	    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	    BorderSizePixel = 0,
	    Visible = false,
		Active = true,
	    Parent = GuiHolder,
	}) setThemed(Items["DropdownFrame"], "BackgroundColor3", "Background")
	
    Items["DropdownMenuUIStroke"] = Create("UIStroke", {
	    Name = "DropdownMenuUIStroke",
	    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	    Transparency = 0.9,
	    Parent = Items["DropdownFrame"] ,
	}) setThemed(Items["DropdownMenuUIStroke"], "Color", "Outline")
	
	Create("UICorner", {
	    Name = "DropdownMenuUICorner",
	    CornerRadius = UDim.new(0, 10),
	    Parent = Items["DropdownFrame"] ,
	})
	
	Items["DropdownMenuUIPadding"] = Create("UIPadding", {
	    Name = "DropdownMenuUIPadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 5),
	    PaddingRight = UDim.new(0, 5),
	    Parent = Items["DropdownFrame"] ,
	})
	
	Items["DropdownMenuUIListLayout"] = Create("UIListLayout", {
	    Name = "DropdownMenuUIListLayout",
	    Padding = UDim.new(0, 5),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    Parent = Items["DropdownFrame"] ,
	})

    Items["Search"] = Create("Frame", {
        Name = "Search",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        LayoutOrder = -1,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = Dropdown.Search,
        Parent = Items["DropdownFrame"],
    })

    Create("UICorner", {
        Name = "SectionUICorner",
        Parent = Items["Search"],
    })

    Items["SearchIcon"] = Create("ImageLabel", {
        Name = "SearchIcon",
        Image = "rbxassetid://121018724060431",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        Parent = Items["Search"],
    }) setThemed(Items["SearchIcon"], "ImageColor3", "Icon")

    Items["SearchIconUIPadding"] = Create("UIPadding", {
        Name = "UIPadding",
        PaddingLeft = UDim.new(0, 15),
        Parent = Items["Search"],
    })

    Items["SearchBox"] = Create("TextBox", {
        Name = "SearchBox",
        CursorPosition = -1,
        FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        PlaceholderText = "Search...",
        Text = "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Items["Search"],
    })
    setThemed(Items["SearchBox"], "TextColor3", "Text")
    setThemed(Items["SearchBox"], "PlaceholderColor3", "Placeholder")

    Items["SearchBoxUIPadding"] = Create("UIPadding", {
        Name = "SearchBoxUIPadding",
        PaddingLeft = UDim.new(0, 23),
        Parent = Items["SearchBox"],
    })

    Dropdown.Items = Items
    local MenuSize = Items["DropdownFrame"].AbsoluteSize.X

    local tweensettings = {
        duration = 0.2,
        easingStyle = Enum.EasingStyle.Quint,
        transparencyIn = 0.2,
        transparencyOut = 0.5,
        checkSizeIncrease = 12,
        checkSizeDecrease = -13,
    }

    local function CalculateDropdownSize()
        local totalHeight = 0
        local visibleChildrenCount = 0
        local padding = Items["DropdownMenuUIPadding"].PaddingTop.Offset + Items["DropdownMenuUIPadding"].PaddingBottom.Offset

        for _, v in pairs(Items["DropdownFrame"]:GetChildren()) do
            if not v:IsA("UIBase") and v.Visible then
                totalHeight += v.AbsoluteSize.Y
                visibleChildrenCount += 1
            end
        end

        local spacing = Items["DropdownMenuUIListLayout"].Padding.Offset * (visibleChildrenCount - 1)
        return totalHeight + spacing + padding
    end

    local function findOption()
        local searchTerm = Items["SearchBox"].Text:lower()
        for _, v in pairs(OptionObjs) do
            local isVisible = string.find(v.NameLabel.Text:lower(), searchTerm) ~= nil
            if v.Button.Visible ~= isVisible then
                v.Button.Visible = isVisible
            end
        end
        Items["DropdownFrame"].Size = UDim2.new(0, MenuSize, 0, CalculateDropdownSize())
    end

    Items["SearchBox"]:GetPropertyChangedSignal("Text"):Connect(findOption)

    local function Toggle(optionName, State)
        local option = OptionObjs[optionName]
        if not option then return end

        local checkmark = option.Checkmark
        local optionNameLabel = option.NameLabel

        if State then
            if Dropdown.Multi then
                if not table.find(Selected, optionName) then
                    table.insert(Selected, optionName)
                    Dropdown.Value = Selected
                end
            else
                for name, opt in pairs(OptionObjs) do
                    if name ~= optionName then
                        Tween(opt.Checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                            Size = UDim2.new(opt.Checkmark.Size.X.Scale, tweensettings.checkSizeDecrease, opt.Checkmark.Size.Y.Scale, opt.Checkmark.Size.Y.Offset)
                        }):Play()
                        Tween(opt.NameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                            TextTransparency = tweensettings.transparencyOut
                        }):Play()
                        opt.Checkmark.TextTransparency = 1
                    end
                end
                Selected = {optionName}
                Dropdown.Value = Selected[1]
            end
            Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeIncrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
            }):Play()
            Tween(optionNameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                TextTransparency = tweensettings.transparencyIn
            }):Play()
            checkmark.TextTransparency = 0
        else
            if Dropdown.Multi then
                local idx = table.find(Selected, optionName)
                if idx then table.remove(Selected, idx) end
            else
                Selected = {}
            end
            Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeDecrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
            }):Play()
            Tween(optionNameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                TextTransparency = tweensettings.transparencyOut
            }):Play()
            checkmark.TextTransparency = 1
        end

        if Dropdown.Required and #Selected == 0 and not State then return end

        if #Selected > 0 then
            Items["DropdownName"].Text = table.concat(Selected, ", ")
        else
            Items["DropdownName"].Text = "..."
        end
    end
    
    local RenderStepped

	local function ToggleDropdown()
	    if locked then return end
	    if db then return end
	    db = true
	
	    local isOpen = not dropped
	
	    if RenderStepped then
	        RenderStepped:Disconnect()
	        RenderStepped = nil
	    end
	
	    local iconTween = Tween(Items["DropdownImage"], TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = isOpen and -90 or 0 })
	    iconTween:Play()
	
	    if isOpen then
	        RenderStepped = RunService.RenderStepped:Connect(function()
			    local Pos = Items["Dropdown"].AbsolutePosition
			    local Size = Items["Dropdown"].AbsoluteSize
			    local screenHeight = GuiHolder.AbsoluteSize.Y
			    local screenWidth = GuiHolder.AbsoluteSize.X
			    local contentHeight = CalculateDropdownSize()
			    local maxHeight = screenHeight * 0.4
			
			    if contentHeight > maxHeight then
			        Items["DropdownFrame"].AnchorPoint = Vector2.new(0.5, 0.5)
			        Items["DropdownFrame"].Position = UDim2.fromScale(0.5, 0.5)
			        Items["DropdownFrame"].Size = UDim2.new(0, Size.X, 1, -20)
			        Items["DropdownFrame"].ScrollingEnabled = true
			    else
			        Items["DropdownFrame"].AnchorPoint = Vector2.new(0, 0)
			        Items["DropdownFrame"].Position = UDim2.fromOffset(Pos.X, Pos.Y + Size.Y + 4)
			        Items["DropdownFrame"].Size = UDim2.fromOffset(Size.X, contentHeight)
			        Items["DropdownFrame"].ScrollingEnabled = false
			    end
			end)
	        Items["DropdownFrame"].Visible = true
	        db = false
	    else
	        Items["DropdownFrame"].Visible = false
	        db = false
	    end
	
	    dropped = isOpen
	end

    Items["Dropdown"].MouseButton1Click:Connect(ToggleDropdown)
    
    UserInputService.InputBegan:Connect(function(Input)
	    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
	        if not dropped then return end
	        if IsMouseOverFrame(Items["DropdownFrame"]) then return end
	        ToggleDropdown()
	    end
	end)
    
    local function CheckSize()
	    local scale = Dropdown.Window.Items["BaseUIScale"].Scale
	    local padding = Items["FrameLayout"].Padding.Offset
	    local textWidth = Items["TextFrame"].AbsoluteSize.X / scale
	    local imageWidth = Items["DropdownImage"].AbsoluteSize.X / scale
	    local totalWidth = Items["Frame"].AbsoluteSize.X / scale
	    local newWidth = totalWidth - (textWidth + imageWidth + padding * 2 + Items["FramePadding"].PaddingLeft.Offset + Items["FramePadding"].PaddingRight.Offset)
	    Items["DropdownName"].Size = UDim2.new(0, newWidth, 0, 38)
	end
	
	task.defer(CheckSize)
	Items["TextFrame"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["DropdownName"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
	Items["Dropdown"]:GetPropertyChangedSignal("AbsoluteSize"):Connect(CheckSize)
    
    local function addOption(i, v)
        local Option = Create("TextButton", {
            Name = "Option",
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Parent = Items["DropdownFrame"],
        })

        Create("UIPadding", {
            Name = "OptionUIPadding",
            PaddingLeft = UDim.new(0, 15),
            Parent = Option,
        })

        Create("UIListLayout", {
            Name = "OptionUIListLayout",
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = Option,
        })

        local Checkmark = Create("TextLabel", {
            Name = "Checkmark",
            FontFace = Font.new(assets.interFont),
            Text = "✓",
            TextSize = 13,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = -1,
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(-10, 0),
            Parent = Option,
        }) setThemed(Checkmark, "TextColor3", "Text")

        local OptionName = Create("TextLabel", {
            Name = "OptionName",
            FontFace = Font.new(assets.interFont),
            Text = v,
            RichText = true,
            TextSize = 13,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0, 0.5),
            Parent = Option,
        }) setThemed(OptionName, "TextColor3", "Text")

        OptionObjs[v] = {
            Index = i,
            Button = Option,
            NameLabel = OptionName,
            Checkmark = Checkmark,
        }

        local isSelected = false
        if Dropdown.Default then
            if Dropdown.Multi then
                isSelected = table.find(Dropdown.Default, v) and true or false
            else
                isSelected = Dropdown.Default == v
            end
        end
        Toggle(v, isSelected)

        Option.MouseButton1Click:Connect(function()
            local isSelected = table.find(Selected, v) and true or false
            local newSelected = not isSelected

            if Dropdown.Required and not newSelected and #Selected <= 1 then return end

            Toggle(v, newSelected)

            task.spawn(function()
                if Dropdown.Multi then
                    local Return = {}
                    for _, opt in ipairs(Selected) do Return[opt] = true end
                    Dropdown.Callback(Return)
                else
                    if newSelected then Dropdown.Callback(Selected[1] or nil) end
                end
            end)
        end)

        if dropped then
            Items["DropdownFrame"].Size = UDim2.new(1, 0, 0, CalculateDropdownSize())
        end
    end

    for i, v in pairs(Dropdown.Options) do
        addOption(i, v)
    end

    function Dropdown:UpdateName(New)
	    Items["TitleText"].Text = New
	end
	function Dropdown:SetName(New)
	    Items["TitleText"].Text = New
	end
	
	function Dropdown:UpdateDesc(New)
	    Items["DescText"].Text = New
	end
	function Dropdown:SetDesc(New)
	    Items["DescText"].Text = New
	end
	
	function Dropdown:SetVisibility(State)
	    Items["Dropdown"].Visible = State
	end
	function Dropdown:Destroy()
	    Items["Dropdown"]:Destroy()
	end
	
    function Dropdown:Lock()
        locked = true
        setElementLock(Items["Dropdown"], true)
    end
    function Dropdown:Unlock()
        locked = false
        setElementLock(Items["Dropdown"], false)
    end
    function Dropdown:GetLocked() return locked end
    function Dropdown:UpdateSelection(newSelection)
        if not newSelection then return end
        for option in pairs(OptionObjs) do Toggle(option, false) end

        local selectedOptions = {}
        if type(newSelection) == "string" then
            Toggle(newSelection, true)
            table.insert(selectedOptions, newSelection)
        elseif type(newSelection) == "table" then
            for _, opt in ipairs(newSelection) do
                Toggle(opt, true)
                table.insert(selectedOptions, opt)
            end
        end

        if Dropdown.Multi then
            local Return = {}
            for _, opt in ipairs(selectedOptions) do Return[opt] = true end
            Dropdown.Callback(Return)
        else
            Dropdown.Callback(selectedOptions[1] or nil)
        end
    end
    function Dropdown:InsertOptions(newOptions)
        if not newOptions then return end
        Dropdown.Options = newOptions
        for i, v in pairs(newOptions) do addOption(i, v) end
    end
    function Dropdown:ClearOptions()
        for _, optionData in pairs(OptionObjs) do optionData.Button:Destroy() end
        OptionObjs = {}
        Selected = {}
        if dropped then Items["DropdownFrame"].Size = UDim2.new(1, 0, 0, CalculateDropdownSize()) end
    end
    function Dropdown:GetOptions()
        local optionsStatus = {}
        for option in pairs(OptionObjs) do
            optionsStatus[option] = table.find(Selected, option) and true or false
        end
        return optionsStatus
    end
    function Dropdown:RemoveOptions(remove)
        if not remove then return end
        for _, optionName in ipairs(remove) do
            local optionData = OptionObjs[optionName]
            if optionData then
                for i = #Selected, 1, -1 do
                    if Selected[i] == optionName then table.remove(Selected, i) end
                end
                optionData.Button:Destroy()
                OptionObjs[optionName] = nil
            end
        end
        if dropped then Items["DropdownFrame"].Size = UDim2.new(1, 0, 0, CalculateDropdownSize()) end
    end
    function Dropdown:IsOption(optionName)
        return OptionObjs[optionName] ~= nil
    end
    
    if Dropdown.Flag then
		TanukiLib.Options[Dropdown.Flag] = Dropdown
	end

    Dropdown.Section.Elements[#Dropdown.Section.Elements + 1] = Dropdown
    return Dropdown
end

TanukiLib.Sections.Colorpicker = function(self, Data)
    Data = Data or {}

    local Colorpicker = {
        Window = self.Window,
        Page = self.Page,
        Section = self,

        Name = Data.Name or "Colorpicker",
        Desc = Data.Description or nil,
        Default = Data.Default or Color3.fromRGB(255, 255, 255),
        Alpha = Data.Alpha or nil,
        Flag = Data.Flag or nil,
        Callback = Data.Callback or function() end,

        Color = Data.Default or Color3.fromRGB(255, 255, 255),
        Value = nil,
    }

    local isAlpha = Colorpicker.Alpha and true or false
    local Items = {}

    Items["Colorpicker"] = Create("Frame", {
        Name = "Colorpicker",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Colorpicker.Section.Items["Section"],
    })
    
   Items["Frame"] = Create("Frame", {
	    Name = "Frame",
	    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, 0, 1, 0),
	    Parent = Items["Colorpicker"],
	})
	
	Items["FramePadding"] = Create("UIPadding", {
	    Name = "FramePadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Frame"]
	})
	
	Items["FrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 6),
	    SortOrder = Enum.SortOrder.LayoutOrder,
	    FillDirection = Enum.FillDirection.Horizontal,
	    HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["Frame"]
	})
	
	Items["TextFrame"] = Create("Frame", {
	    Name = "TextFrame",
		AutomaticSize = Enum.AutomaticSize.Y,
	    BackgroundTransparency = 1,
	    Size = UDim2.new(1, -21, 0, 0),
	    Parent = Items["Frame"],
	})
	
	Items["TextFrameLayout"] = Create("UIListLayout", {
	    Name = "FrameLayout",
	    Padding = UDim.new(0, 1),
	    SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	    Parent = Items["TextFrame"]
	})
	
	Items["TitleText"] = Create("TextLabel", {
	    Name = "Title",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Colorpicker.Name,
	    TextSize = 14,
		TextWrapped = true,
	    TextTransparency = 0.3,
	    TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	    Parent = Items["TextFrame"]
	}) setThemed(Items["TitleText"], "TextColor3", "Text")
	
	Items["DescText"] = Create("TextLabel", {
	    Name = "Description",
	    FontFace = Font.new(assets.interFont, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	    RichText = true,
	    Text = Colorpicker.Desc,
	    TextSize = 13,
		TextWrapped = true,
	    TextTransparency = 0.4,
	    TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = Colorpicker.Desc ~= nil and Colorpicker.Desc ~= "",
	    Parent = Items["TextFrame"]
	}) setThemed(Items["DescText"], "TextColor3", "Text")

    Items["ColorCbg"] = Create("ImageLabel", {
        Name = "NewColor",
        Image = assets.grid,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(500, 500),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(21, 21),
        Parent = Items["Frame"],
    })

    Items["ColorCbgUICorner"] = Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(0, 8),
        Parent = Items["ColorCbg"],
    })

    Items["ColorC"] = Create("ImageButton", {
        Name = "Color",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Colorpicker.Color,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = Colorpicker.Alpha or 0,
        Parent = Items["ColorCbg"],
    })

    Items["ColorCUICorner"] = Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(0, 6),
        Parent = Items["ColorC"],
    })
    
    Items["PickerCanvas"] = Create("CanvasGroup", {
        Name = "ColorPickerCanvas",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Active = true,
        GroupTransparency = 1,
        Visible = false,
        Parent = Colorpicker.Window.Items["Base"],
    })

    Items["ColorPicker"] = Create("Frame", {
        Name = "ColorPicker",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Active = true,
        Size = UDim2.fromScale(1, 1),
        Parent = Items["PickerCanvas"],
    })

    Items["BaseUICorner"] = Create("UICorner", {
        Name = "BaseUICorner",
        CornerRadius = UDim.new(0, 10),
        Parent = Items["ColorPicker"],
    })

    Items["Prompt"] = Create("Frame", {
        Name = "Prompt",
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 0),
        Parent = Items["ColorPicker"],
    }) setThemed(Items["Prompt"], "BackgroundColor3", "Background")

    Items["PromptUIScale"] = Create("UIScale", {
        Name = "PromptUIScale",
        Scale = 0.95,
        Parent = Items["Prompt"],
    })

    Items["PromptUIStroke"] = Create("UIStroke", {
        Name = "PromptUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["Prompt"],
    }) setThemed(Items["PromptUIStroke"], "Color", "Outline")

    Items["PromptUICorner"] = Create("UICorner", {
        Name = "PromptUICorner",
        CornerRadius = UDim.new(0, 10),
        Parent = Items["Prompt"],
    })

    Items["PromptUIListLayout"] = Create("UIListLayout", {
        Name = "PromptUIListLayout",
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Prompt"],
    })
    
    Items["PromptUIPadding"] = Create("UIPadding", {
        Name = "PromptUIPadding",
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
        PaddingTop = UDim.new(0, 20),
        Parent = Items["Prompt"],
    })
    
    Items["Paragraph"] = Create("Frame", {
        Name = "Paragraph",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Prompt"],
    })

    Items["ParagraphHeader"] = Create("TextLabel", {
        Name = "ParagraphHeader",
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        RichText = true,
        Text = Colorpicker.Name,
        TextSize = 18,
        TextTransparency = 0.4,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Paragraph"],
    }) setThemed(Items["ParagraphHeader"], "TextColor3", "Text")

    Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 15),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Paragraph"],
    })

    Items["Line"] = Create("Frame", {
        Name = "Line",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Items["Paragraph"],
    })

    Items["ColorOptions"] = Create("Frame", {
        Name = "ColorOptions",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Prompt"],
    })

    Items["ColorOptionsLayout"] = Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 25),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["ColorOptions"],
    })

    Items["Wheel"] = Create("Frame", {
        Name = "Wheel",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Items["ColorOptions"],
    })

    Items["WheelLayout"] = Create("UIListLayout", {
        Name = "WheelUIListLayout",
        Padding = UDim.new(0, 15),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = Items["Wheel"],
    })

	Items["ColorBox"] = Create("ImageButton", {
	    Name = "ColorBox",
	    BackgroundColor3 = Color3.fromHSV(hue, 1, 1), -- This shows the pure Hue
	    BorderSizePixel = 0,
	    AutoButtonColor = false,
	    LayoutOrder = 0,
	    Size = UDim2.fromOffset(160, 160),
	    Parent = Items["Wheel"],
	})
	
	Items["ColorBoxCorner"] = Create("UICorner", {
        Name = "ColorBoxCorner",
        Parent = Items["ColorBox"],
    })
	
	Items["SatGradient"] = Create("Frame", {
	    Size = UDim2.fromScale(1, 1),
	    BackgroundTransparency = 0,
	    Parent = Items["ColorBox"],
	})
	Create("UIGradient", {
	    Color = ColorSequence.new(Color3.new(1, 1, 1)),
	    Transparency = NumberSequence.new({
	        NumberSequenceKeypoint.new(0, 0),
	        NumberSequenceKeypoint.new(1, 1)
	    }),
	    Parent = Items["SatGradient"]
	})
	Items["SatGradientUICorner"] = Create("UICorner", {
        Name = "SatGradientUICorner",
        Parent = Items["SatGradient"],
    })
	
	Items["ValGradient"] = Create("Frame", {
	    Size = UDim2.fromScale(1, 1),
	    BackgroundTransparency = 0,
	    Parent = Items["ColorBox"],
	})
	Create("UIGradient", {
	    Color = ColorSequence.new(Color3.new(0, 0, 0)),
	    Rotation = 90,
	    Transparency = NumberSequence.new({
	        NumberSequenceKeypoint.new(0, 1),
	        NumberSequenceKeypoint.new(1, 0)
	    }),
	    Parent = Items["ValGradient"]
	})
	Items["ValGradientUICorner"] = Create("UICorner", {
        Name = "ValGradientUICorner",
        Parent = Items["ValGradient"],
    })
	
	Items["Target"] = Create("ImageLabel", {
	    Name = "Target",
	    AnchorPoint = Vector2.new(0.5, 0.5),
	    BackgroundTransparency = 1,
	    Size = UDim2.fromOffset(14, 14),
	    ZIndex = 5,
	    Parent = Items["ColorBox"],
	}) 
	
	Items["TargetUIStroke"] = Create("UIStroke", {
        Name = "TargetUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Thickness = 2,
        Parent = Items["Target"],
    }) setThemed(Items["TargetUIStroke"], "Color", "Outline")
	
	Items["AlphaSlider"] = Create("ImageLabel", {
	    BackgroundTransparency = 0,
		LayoutOrder = 1,
	    Size = UDim2.new(0, 15, 0, 160),
		Visible = isAlpha ~= false,
	    Parent = Items["Wheel"],
	})
	
	Items["AlphaSliderUICorner"] = Create("UICorner", {
        Name = "AlphaSliderUICorner",
        CornerRadius = UDim.new(0, 6),
        Parent = Items["AlphaSlider"],
    })
	
	Items["AlphaGradient"] = Create("UIGradient", {
	    Rotation = 90,
	    Transparency = NumberSequence.new({
	        NumberSequenceKeypoint.new(0, 0),
	        NumberSequenceKeypoint.new(1, 1)
	    }),
	    Parent = Items["AlphaSlider"],
	})
	
	Items["AlphaSlide"] = Create("ImageLabel", {
	    Name = "AlphaSlide",
	    AnchorPoint = Vector2.new(0.5, 0),
	    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	    Size = UDim2.new(1, 4, 0, 4),
	    Position = UDim2.fromScale(0.5, 0),
	    Parent = Items["AlphaSlider"],
	})
	
	Items["AlphaSlideUICorner"] = Create("UICorner", {
        Name = "AlphaSlideUICorner",
        CornerRadius = UDim.new(1, 0),
        Parent = Items["AlphaSlide"],
    })
    
    Items["AlphaSlideUIStroke"] = Create("UIStroke", {
        Name = "AlphaSlideUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["AlphaSlide"],
    }) setThemed(Items["AlphaSlideUIStroke"], "Color", "Outline")

    Items["AlphaSlideStrokeGradient"] = Create("UIGradient", {
        Name = "UIGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
        }),
        Rotation = 180,
        Parent = Items["AlphaSlideUIStroke"],
    })


    Items["Inputs"] = Create("Frame", {
        Name = "Inputs",
        AnchorPoint = Vector2.new(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.fromOffset(0, 0),
        Parent = Items["Wheel"],
    })

    Items["InputsLayout"] = Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Inputs"],
    })

    local function CreateModifier(modName, layoutOrder, defaultText, visible)
        local frame = Create("Frame", {
            Name = modName,
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            LayoutOrder = layoutOrder,
            Size = UDim2.fromOffset(0, 34),
            Visible = visible ~= false,
            Parent = Items["Inputs"],
        })

        local label = Create("TextLabel", {
            Name = "InputName",
            FontFace = Font.new(assets.interFont),
            Text = modName,
            TextSize = 13,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            LayoutOrder = 2,
            Position = UDim2.fromScale(0, 0.5),
            Parent = frame,
        }) setThemed(label, "TextColor3", "Text")

        Create("UIListLayout", {
            Name = "UIListLayout",
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = frame,
        })

        local box = Create("TextBox", {
            Name = "InputBox",
            ClearTextOnFocus = false,
            CursorPosition = -1,
            FontFace = Font.new(assets.interFont),
            Text = defaultText,
            TextSize = 12,
            TextTransparency = 0.1,
            TextXAlignment = Enum.TextXAlignment.Left,
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 0.92,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = 1,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(75, 25),
            Parent = frame,
        })
        setThemed(box, "TextColor3", "Text")
        setThemed(box, "BackgroundColor3", "Surface")

        Create("UICorner", {
            Name = "InputBoxUICorner",
            CornerRadius = UDim.new(0, 4),
            Parent = box,
        })

        local stroke = Create("UIStroke", {
            Name = "InputBoxUIStroke",
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Transparency = 0.9,
            Parent = box,
        }) setThemed(stroke, "Color", "Outline")

        Create("UISizeConstraint", {
            Name = "InputBoxUISizeConstraint",
            Parent = box,
        })

        Create("UIPadding", {
            Name = "InputBoxUIPadding",
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 10),
            Parent = box,
        })

        Items[modName] = frame
        Items[modName .. "Box"] = box
        return box
    end

    local redBox   = CreateModifier("Red",   1, "255")
    local greenBox = CreateModifier("Green", 2, "255")
    local blueBox  = CreateModifier("Blue",  3, "255")
    local alphaBox = CreateModifier("Alpha", 4, "0", isAlpha)
    local hexBox   = CreateModifier("Hex",   5, "255")
    
    Items["Value"] = Create("ImageLabel", {
        Name = "Value",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        LayoutOrder = 1,
        Position = UDim2.fromScale(0.092, 0.886),
        Size = UDim2.new(1, 0, 0, 15),
        Parent = Items["ColorOptions"],
    })

    Items["ValueGradient"] = Create("UIGradient", {
        Name = "UIGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),     -- Red
		    ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)), -- Yellow
		    ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)), -- Green
		    ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),   -- Cyan
		    ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)), -- Blue
		    ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)), -- Magenta
		    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))      -- Red
        }),
        Parent = Items["Value"],
    })

    Items["ValueUICorner"] = Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(0, 6),
        Parent = Items["Value"],
    })

    Items["ValueUIStroke"] = Create("UIStroke", {
        Name = "UIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["Value"],
    }) setThemed(Items["ValueUIStroke"], "Color", "Outline")

    Items["ValueStrokeGradient"] = Create("UIGradient", {
        Name = "UIGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
        }),
        Rotation = 180,
        Parent = Items["ValueUIStroke"],
    })
    
    Items["Slide"] = Create("ImageLabel", {
        Name = "Slide",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderColor3 = Color3.fromRGB(27, 42, 53),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(0, 10, 1, 8),
        Parent = Items["Value"],
    })

    Items["SlideUICorner"] = Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(1, 0),
        Parent = Items["Slide"],
    })

    Items["SlideUIStroke"] = Create("UIStroke", {
        Name = "UIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.5,
        Parent = Items["Slide"],
    })

    Items["BottomBar"] = Create("Frame", {
        Name = "Interactions",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Prompt"],
    })

    Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["BottomBar"],
    })

    Create("UIPadding", {
        Name = "UIPadding",
        PaddingTop = UDim.new(0, 10),
        Parent = Items["BottomBar"],
    })
    
    
    Items["ColorRing"] = Create("ImageLabel", {
	    Name = "ColorRing",
	    Image = assets.grid,
	    ScaleType = Enum.ScaleType.Tile,
	    TileSize = UDim2.fromOffset(20, 20),
	    Size = UDim2.new(0, 60, 0, 28),
	    BackgroundTransparency = 1,
	    ClipsDescendants = false,
	    Parent = Items["BottomBar"],
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Items["ColorRing"] })
	
	Items["NewColorInner"] = Create("Frame", {
	    Name = "NewColor",
	    BorderSizePixel = 0,
	    Size = UDim2.fromScale(0.6, 1), 
	    ZIndex = 2,
	    Parent = Items["ColorRing"],
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Items["NewColorInner"] })
	
	Items["OldColorInner"] = Create("Frame", {
	    Name = "OldColor",
	    BorderSizePixel = 0,
	    Position = UDim2.fromScale(0.4, 0),
	    Size = UDim2.fromScale(0.6, 1),
	    ZIndex = 1,
	    Parent = Items["ColorRing"],
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Items["OldColorInner"] })


    Items["Separator"] = Create("Frame", {
        Name = "Frame",
        Size = UDim2.new(0, 50, 0, 30),
        BackgroundTransparency = 1,
        Parent = Items["BottomBar"],
    })
    
    Items["Interactions"] = Create("Frame", {
        Name = "Interactions",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Size = UDim2.fromScale(0.6, 0),
        Parent = Items["BottomBar"],
    })
    
    Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Interactions"],
    })
    
    Items["Cancel"] = Create("TextButton", {
        Name = "Cancel",
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = "Cancel",
        TextSize = 15,
        TextTransparency = 0.5,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.5, 0),
        Parent = Items["Interactions"],
    }) setThemed(Items["Cancel"], "TextColor3", "Text")
    
    Items["CancelUIStroke"] = Create("UIStroke", {
        Name = "CancelUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["Cancel"],
    }) setThemed(Items["CancelUIStroke"], "Color", "Outline")

    Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(0, 10),
        Parent = Items["Cancel"],
    })

    Create("UIPadding", {
        Name = "UIPadding",
        PaddingBottom = UDim.new(0, 9),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 9),
        Parent = Items["Cancel"],
    })

    Items["Confirm"] = Create("TextButton", {
        Name = "Confirm",
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = "Confirm",
        TextSize = 15,
        TextTransparency = 0.5,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.5, 0),
        Parent = Items["Interactions"],
    })
    setThemed(Items["Confirm"], "TextColor3", "Text")
    setThemed(Items["Confirm"], "BackgroundColor3", "Accent")

    Create("UIPadding", {
        Name = "UIPadding",
        PaddingBottom = UDim.new(0, 9),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 9),
        Parent = Items["Confirm"],
    })

    Create("UICorner", {
        Name = "UICorner",
        CornerRadius = UDim.new(0, 10),
        Parent = Items["Confirm"],
    })

    

    

    

    Colorpicker.Items = Items
    local locked = false

    local fromHSV, fromRGB, v2, udim2 = Color3.fromHSV, Color3.fromRGB, Vector2.new, UDim2.new

    local wheel  = Items["WheelImage"]
    local ring   = Items["Target"]
    local slider = Items["Value"]
    local slide  = Items["Slide"]
    local colour = Items["NewColorInner"]
    local oldColour = Items["OldColorInner"]

    local modifierInputs = {
        Hex   = hexBox,
        Red   = redBox,
        Green = greenBox,
        Blue  = blueBox,
        Alpha = alphaBox,
    }

    local Mouse = LocalPlayer:GetMouse()
    local WheelDown, SlideDown, AlphaDown = false, false, false
    local hue, saturation, value, alpha = 0, 0, 1, 0

    local function hexToRGB(hex)
        hex = hex:gsub("#","")
        if #hex ~= 6 then return 0, 0, 0 end
        local r = tonumber(hex:sub(1, 2), 16) or 0
        local g = tonumber(hex:sub(3, 4), 16) or 0
        local b = tonumber(hex:sub(5, 6), 16) or 0
        return r, g, b
    end

    local function clampInput(val, min, max)
        local num = tonumber(val)
        if num then return math.clamp(num, min, max) end
        return min
    end

    local function update()
	    local c = fromHSV(hue, saturation, value)
	    local a = alpha
	    colour.BackgroundColor3 = c
	    colour.BackgroundTransparency = a   
	    Items["ColorBox"].BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
	    Items["AlphaGradient"].Color = ColorSequence.new(c) 
	    modifierInputs.Red.Text = tostring(math.floor(c.r * 255 + 0.5))
	    modifierInputs.Green.Text = tostring(math.floor(c.g * 255 + 0.5))
	    modifierInputs.Blue.Text = tostring(math.floor(c.b * 255 + 0.5))
	    modifierInputs.Hex.Text = string.format("#%02X%02X%02X",
	        math.floor(c.r * 255 + 0.5),
	        math.floor(c.g * 255 + 0.5),
	        math.floor(c.b * 255 + 0.5))        
		modifierInputs.Alpha.Text = string.format("%.2f", a)
	    slider.BackgroundColor3 = Color3.new(1, 1, 1)
	end
	


    local function UpdateSlide(iX)
	    local rX = iX - slider.AbsolutePosition.X
	    local cX = math.clamp(rX, 0, slider.AbsoluteSize.X - slide.AbsoluteSize.X)
	    slide.Position = udim2(0, cX, 0.5, 0) 
	    hue = cX / (slider.AbsoluteSize.X - slide.AbsoluteSize.X)
	    slider.BackgroundColor3 = Color3.new(1, 1, 1) 
	    update()
	end

	local function UpdateBox(iX, iY)
	    local box = Items["ColorBox"]
	    local relX = math.clamp((iX - box.AbsolutePosition.X) / box.AbsoluteSize.X, 0, 1)
	    local relY = math.clamp((iY - box.AbsolutePosition.Y) / box.AbsoluteSize.Y, 0, 1)
	
	    saturation = relX
	    value = 1 - relY -- Invert Y because 0 is bottom (black) in HSV but top in UI
	
	    Items["Target"].Position = UDim2.fromScale(relX, relY)
	    update()
	end
	
	local function UpdateAlpha(iY)
	    local slider = Items["AlphaSlider"]
	    local rY = iY - slider.AbsolutePosition.Y
	    local cY = math.clamp(rY, 0, slider.AbsoluteSize.Y - Items["AlphaSlide"].AbsoluteSize.Y)
	    
	    Items["AlphaSlide"].Position = UDim2.new(0.5, 0, 0, cY)
	    alpha = cY / (slider.AbsoluteSize.Y - Items["AlphaSlide"].AbsoluteSize.Y)   
	    update()
	end


	
	local function UpdateBoxFromHSV(h, s, v)
        hue, saturation, value = h, s, v
        Items["ColorBox"].BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        Items["Target"].Position = UDim2.fromScale(s, 1 - v)
        local cX = h * (slider.AbsoluteSize.X - slide.AbsoluteSize.X)
        slide.Position = UDim2.new(0, cX, 0.5, 0)
    end


    local function UpdateSlideFromValue(val)
        local cY = (1 - val) * (slider.AbsoluteSize.X - slide.AbsoluteSize.X)
        slide.Position = UDim2.new(0, cY, 0.5, 0)
    end

	local function UpdateAlphaFromValue(val)
	    local slider = Items["AlphaSlider"]
	    local cY = val * (slider.AbsoluteSize.Y - Items["AlphaSlide"].AbsoluteSize.Y)
	    Items["AlphaSlide"].Position = UDim2.new(0.5, 0, 0, cY)
	end


    local function updateFromRGB()
        local r = clampInput(modifierInputs.Red.Text, 0, 255)
        local g = clampInput(modifierInputs.Green.Text, 0, 255)
        local b = clampInput(modifierInputs.Blue.Text, 0, 255)
        modifierInputs.Red.Text = r
        modifierInputs.Green.Text = g
        modifierInputs.Blue.Text = b
        hue, saturation, value = Color3.fromRGB(r, g, b):ToHSV()
        UpdateSlideFromValue(value)
        UpdateBoxFromHSV(hue, saturation, value)
        update()
    end

    local function updateFromHex()
        local hex = modifierInputs.Hex.Text
        local r, g, b = hexToRGB(hex)
        r = clampInput(r, 0, 255)
        g = clampInput(g, 0, 255)
        b = clampInput(b, 0, 255)
        modifierInputs.Red.Text = r
        modifierInputs.Green.Text = g
        modifierInputs.Blue.Text = b
        hue, saturation, value = Color3.fromRGB(r, g, b):ToHSV()
        UpdateSlideFromValue(value)
        UpdateBoxFromHSV(hue, saturation, value)
        update()
    end

	local function updateFromSettings()
	    local r = math.floor(Colorpicker.Color.R * 255 + 0.5)
	    local g = math.floor(Colorpicker.Color.G * 255 + 0.5)
	    local b = math.floor(Colorpicker.Color.B * 255 + 0.5)
	    
	    alpha = isAlpha and Colorpicker.Alpha or 0
	
	    modifierInputs.Red.Text = tostring(r)
	    modifierInputs.Green.Text = tostring(g)
	    modifierInputs.Blue.Text = tostring(b)
	    modifierInputs.Alpha.Text = string.format("%.2f", alpha)
	    modifierInputs.Hex.Text = string.format("#%02X%02X%02X", r, g, b)
	
	    hue, saturation, value = Colorpicker.Color:ToHSV()
	
	    oldColour.BackgroundColor3 = Colorpicker.Color
	    oldColour.BackgroundTransparency = alpha
	
	    colour.BackgroundColor3 = Colorpicker.Color
	    colour.BackgroundTransparency = alpha
	
	    UpdateBoxFromHSV(hue, saturation, value)
	    UpdateAlphaFromValue(alpha)
	    update()
	end


    local wheelDragInput, slideDragInput, alphaDragInput = nil, nil, nil

    Items["ColorBox"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            WheelDown = true
            wheelDragInput = input
            UpdateBox(input.Position.X, input.Position.Y)
        end
    end)

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            SlideDown = true
            slideDragInput = input
            UpdateSlide(input.Position.X)
        end
    end)
    
    Items["AlphaSlider"].InputBegan:Connect(function(input)
	    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
	        AlphaDown = true
	        alphaDragInput = input
	        UpdateAlpha(input.Position.Y)
	    end
	end)

    UserInputService.InputEnded:Connect(function(input)
        if input == slideDragInput then
            SlideDown = false
            slideDragInput = nil
        elseif input == wheelDragInput then
            WheelDown = false
            wheelDragInput = nil
        elseif input == alphaDragInput then
		    AlphaDown = false
		    alphaDragInput = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
	    if input.UserInputType == Enum.UserInputType.MouseMovement or 
	       input == slideDragInput or 
	       input == wheelDragInput or 
	       input == alphaDragInput then        
	        if SlideDown then
	            UpdateSlide(input.Position.X)
	        elseif WheelDown then
	            UpdateBox(input.Position.X, input.Position.Y)
	        elseif AlphaDown then
	            UpdateAlpha(input.Position.Y)
	        end
	    end
	end)


    local function onFocusEnter(instance)
        local placeholder = instance.Text
        instance.Text = ""
        instance.PlaceholderText = placeholder
    end

    modifierInputs.Hex.FocusLost:Connect(updateFromHex)
    modifierInputs.Red.FocusLost:Connect(updateFromRGB)
    modifierInputs.Green.FocusLost:Connect(updateFromRGB)
    modifierInputs.Blue.FocusLost:Connect(updateFromRGB)
    modifierInputs.Alpha.FocusLost:Connect(update)

    modifierInputs.Hex.Focused:Connect(function()   onFocusEnter(modifierInputs.Hex)   end)
    modifierInputs.Red.Focused:Connect(function()   onFocusEnter(modifierInputs.Red)   end)
    modifierInputs.Green.Focused:Connect(function() onFocusEnter(modifierInputs.Green) end)
    modifierInputs.Blue.Focused:Connect(function()  onFocusEnter(modifierInputs.Blue)  end)
    modifierInputs.Alpha.Focused:Connect(function() onFocusEnter(modifierInputs.Alpha) end)


	local function transition(isIn)
	    local canvas = Items["PickerCanvas"]
	    local picker = Items["ColorPicker"] 
	    local promptScale = Items["PromptUIScale"] 
	    local base = Colorpicker.Window.Items["Base"]    
	    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
	
	    if isIn then
	        picker.Parent = canvas
	        picker.ZIndex = 10
	        canvas.Visible = true
	        canvas.GroupTransparency = 1	        
	        local fadeIn = Tween(canvas, tweenInfo, { GroupTransparency = 0 })
	        Tween(promptScale, tweenInfo, { Scale = 1 }):Play()
	        fadeIn:Play()
	        fadeIn.Completed:Wait()

	        picker.Parent = base
	        canvas.Visible = false
	    else
	        picker.Parent = canvas
	        canvas.Visible = true    
	        local fadeOut = Tween(canvas, tweenInfo, { GroupTransparency = 1 })
	        Tween(promptScale, tweenInfo, { Scale = 0.95 }):Play()
	        fadeOut:Play()
	        fadeOut.Completed:Wait()
	        
	        canvas.Visible = false
	    end
	end
	


    local function colorpickerIn()
        if locked then return end
        transition(true)
    end

    local function colorpickerOut()
        transition(false)
    end

    Items["ColorC"].MouseButton1Click:Connect(colorpickerIn)
    Items["Cancel"].MouseButton1Click:Connect(colorpickerOut)
    Items["Confirm"].MouseButton1Click:Connect(function()
        colorpickerOut()
        
        local c = fromHSV(hue, saturation, value)
        local a = clampInput(modifierInputs.Alpha.Text, 0, 1) -- Get fresh alpha
        
        Colorpicker.Color = c
        Colorpicker.Alpha = a
        oldColour.BackgroundColor3 = c
        oldColour.BackgroundTransparency = isAlpha and a or 0
        Items["ColorCbg"].BackgroundColor3 = c
        Items["ColorCbg"].BackgroundTransparency = isAlpha and a or 0
        Items["ColorC"].BackgroundColor3 = c
        Items["ColorC"].BackgroundTransparency = isAlpha and a or 0
        task.spawn(function()
            Colorpicker.Callback(c, isAlpha and a or 1)
        end)
    end)    

    updateFromSettings()

    function Colorpicker:UpdateName(Name)
        Items["TitleFrame"].Text = Name
        Items["ParagraphHeader"].Text = Name
    end
    function Colorpicker:SetName(Name)
        Items["TextTitle"].Text = Name
        Items["ParagraphHeader"].Text = Name
    end
    function Colorpicker:UpdateDesc(Name)
        Items["DescTitle"].Text = Name
    end
    function Colorpicker:SetDesc(Name)
        Items["DescTitle"].Text = Name
    end
    function Colorpicker:SetVisibility(State)
        Items["Colorpicker"].Visible = State
    end
    function Colorpicker:Destroy()
        Items["Colorpicker"]:Destroy()
        Items["ColorPicker"]:Destroy()
    end
    function Colorpicker:GetLocked()
        return locked
    end
    function Colorpicker:Lock()
        locked = true
        setElementLock(Items["Colorpicker"], true)
    end
    function Colorpicker:Unlock()
        locked = false
        setElementLock(Items["Colorpicker"], false)
    end

    function Colorpicker:SetColor(color3)
        Colorpicker.Color = color3
        Items["ColorC"].BackgroundColor3 = color3

        local r = math.floor(Colorpicker.Color.R * 255 + 0.5)
        local g = math.floor(Colorpicker.Color.G * 255 + 0.5)
        local b = math.floor(Colorpicker.Color.B * 255 + 0.5)
        modifierInputs.Red.Text = r
        modifierInputs.Green.Text = g
        modifierInputs.Blue.Text = b
        modifierInputs.Hex.Text = string.format("#%02X%02X%02X", r, g, b)

        hue, saturation, value = Color3.fromRGB(r, g, b):ToHSV()

        oldColour.BackgroundColor3 = Colorpicker.Color
        colour.BackgroundColor3 = Color3.fromRGB(r, g, b)

        UpdateSlideFromValue(value)
        UpdateBoxFromHSV(hue, saturation, value) -- Changed from UpdateRingFromHSV

        task.spawn(function()
            Colorpicker.Callback(Colorpicker.Color, isAlpha and Colorpicker.Alpha or 1)
        end)
    end

    function Colorpicker:SetAlpha(alpha)
        Colorpicker.Alpha = alpha
        Items["ColorC"].Transparency = alpha
        updateFromSettings()
    end
    
    UserInputService.InputBegan:Connect(function(Input)
	    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
	        if Items["PickerCanvas"].GroupTransparency ~= 0 then return end
	        if IsMouseOverFrame(Items["Prompt"]) then return end
	        colorpickerOut()
	    end
	end)

    if Colorpicker.Flag then
        TanukiLib.Options[Colorpicker.Flag] = Colorpicker
    end

    Colorpicker.Section.Elements[#Colorpicker.Section.Elements + 1] = Colorpicker
    return Colorpicker
end

TanukiLib.Sections.Paragraph = function(self, Data)
    Data = Data or {}

    local Paragraph = {
        Window = self.Window,
        Page = self.Page,
        Section = self,
        Header = Data.Name or "Paragraph",
        Body = Data.Body or "I'm Stupid",
        Flag = Data.Flag or nil,
    }

    local Items = {}

    Items["Paragraph"] = Create("Frame", {
        Name = "Paragraph",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Paragraph.Section.Items["Section"],
    })

    Items["UIListLayout"] = Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Paragraph"],
    })
    
    Items["UIPadding"] = Create("UIPadding", {
	    Name = "UIPadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Paragraph"]
	})

    Items["Header"] = Create("TextLabel", {
        Name = "ParagraphHeader",
        FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        RichText = true,
        Text = Paragraph.Header,
        TextSize = 15,
        TextTransparency = 0.4,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Paragraph"],
    }) setThemed(Items["Header"], "TextColor3", "Text")

    Items["Body"] = Create("TextLabel", {
        Name = "ParagraphBody",
        FontFace = Font.new(assets.interFont, Data.Bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        RichText = true,
        Text = Paragraph.Body,
        TextSize = 13,
        TextTransparency = 0.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Paragraph"],
    }) setThemed(Items["Body"], "TextColor3", "Text")
    
    Paragraph.Items = Items
    
    function Paragraph:UpdateHeader(New)
        Items["Header"].Text = New
    end

    function Paragraph:UpdateBody(New)
        Items["Body"].Text = New
    end

    function Paragraph:SetName(New)
        Items["Header"].Text = New
    end

    function Paragraph:SetVisibility(State)
        Items["Main"].Visible = State
    end

    function Paragraph:Destroy()
        Items["Main"]:Destroy()
    end

    if Paragraph.Flag then
        TanukiLib.Options[Paragraph.Flag] = Paragraph
    end

    Paragraph.Section.Elements[#Paragraph.Section.Elements + 1] = Paragraph
    return Paragraph
end

TanukiLib.Sections.Label = function(self, Data)
    Data = Data or {}

    local Label = {
        Window = self.Window,
        Page = self.Page,
        Section = self,
        Text = Data.Text or Data.Name or "Label",
        Bold = Data.Bold or "Label",
        Flag = Data.Flag or nil,
    }

    local Items = {}

    Items["Label"] = Create("Frame", {
        Name = "Label",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Label.Section.Items["Section"],
    })
    
    Items["UIPadding"] = Create("UIPadding", {
	    Name = "UIPadding",
	    PaddingBottom = UDim.new(0, 10),
	    PaddingLeft = UDim.new(0, 10),
	    PaddingRight = UDim.new(0, 10),
	    PaddingTop = UDim.new(0, 10),
	    Parent = Items["Label"]
	})

    Items["Text"] = Create("TextLabel", {
        Name = "LabelText",
        FontFace = Font.new(assets.interFont, Label.Bold and Enum.FontWeight.Bold or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        RichText = true,
        Text = Label.Text,
        TextSize = 13,
        TextTransparency = 0.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Items["Label"],
    }) setThemed(Items["Text"], "TextColor3", "Text")
    
    Label.Items = Items

    function Label:UpdateName(New)
        Items["Text"].Text = New
    end

    function Label:SetName(New)
        Items["Text"].Text = New
    end

    function Label:SetVisibility(State)
        Items["Label"].Visible = State
    end

    function Label:Destroy()
        Items["Label"]:Destroy()
    end

    if Label.Flag then
        TanukiLib.Options[Label.Flag] = Label
    end

    Label.Section.Elements[#Label.Section.Elements + 1] = Label
    return Label
end

TanukiLib.Sections.Divider = function(self)
    local Divider = {
        Section = self
    }

    local Items = {}

    Items["Divider"] = Create("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(0, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Divider.Section.Items["Section"],
    })

    Items["UIPadding"] = Create("UIPadding", {
        Name = "UIPadding",
        PaddingBottom = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Items["Main"],
    })

    Items["UIListLayout"] = Create("UIListLayout", {
        Name = "UIListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Main"],
    })

    Items["Line"] = Create("Frame", {
        Name = "Line",
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Items["Divider"],
    }) setThemed(Items["Line"], "BackgroundColor3", "Outline")
    
    Divider.Items = Items
    
    function Divider:Remove()
        Items["Divider"]:Destroy()
    end

    function Divider:Destroy()
        Items["Divider"]:Destroy()
    end

    function Divider:SetVisibility(State)
        Items["Divider"].Visible = State
    end

    Divider.Section.Elements[#Divider.Section.Elements + 1] = Divider
    return Divider
end

TanukiLib.Dialog = function(self, Data)
    Data = Data or {}

    local Dialog = {}
    local Items = {}

    Items["DialogCanvas"] = Create("CanvasGroup", {
        Name = "DialogCanvas",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Active = true,
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        Parent = self.Items["Base"],
    })

    Items["Dialog"] = Create("Frame", {
        Name = "Dialog",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = Items["DialogCanvas"],
    })

    Create("UICorner", {
        Name = "BaseUICorner",
        CornerRadius = UDim.new(0, 15),
        Parent = Items["Dialog"],
    })

    Items["Prompt"] = Create("Frame", {
        Name = "Prompt",
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(280, 0),
        Parent = Items["Dialog"],
    })
    setThemed(Items["Prompt"], "BackgroundColor3", "Background")

    Items["PromptUIScale"] = Create("UIScale", {
        Name = "BaseUIScale",
        Scale = 0.95,
        Parent = Items["Prompt"],
    })

    Create("UIStroke", {
        Name = "GlobalSettingsUIStroke",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.9,
        Parent = Items["Prompt"],
    })
    setThemed(Items["Prompt"]:FindFirstChild("GlobalSettingsUIStroke"), "Color", "Outline")

    Create("UICorner", {
        Name = "GlobalSettingsUICorner",
        CornerRadius = UDim.new(0, 10),
        Parent = Items["Prompt"],
    })

    Create("UIPadding", {
        Name = "GlobalSettingsUIPadding",
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
        PaddingTop = UDim.new(0, 20),
        Parent = Items["Prompt"],
    })

    Items["Paragraph"] = Create("Frame", {
        Name = "Paragraph",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = Items["Prompt"],
    })

    Items["ParagraphHeader"] = Create("TextLabel", {
        Name = "ParagraphHeader",
        FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        RichText = true,
        Text = Data.Title or "",
        TextSize = 18,
        TextTransparency = 0.4,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Paragraph"],
    })
    setThemed(Items["ParagraphHeader"], "TextColor3", "Text")

    Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 15),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Paragraph"],
    })

    Items["ParagraphBody"] = Create("TextLabel", {
        Name = "ParagraphBody",
        FontFace = Font.new(assets.interFont),
        RichText = true,
        Text = Data.Description or "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Paragraph"],
    })
    setThemed(Items["ParagraphBody"], "TextColor3", "Text")

    Items["Interactions"] = Create("Frame", {
        Name = "Interactions",
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Items["Prompt"],
    })

    Create("UIListLayout", {
        Name = "UIListLayout",
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Interactions"],
    })

    Create("UIPadding", {
        Name = "UIPadding",
        PaddingTop = UDim.new(0, 20),
        Parent = Items["Interactions"],
    })

    Create("UIListLayout", {
        Name = "UIListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Items["Prompt"],
    })

    local canvasIn = Tween(Items["DialogCanvas"], TweenInfo.new(0.1, Enum.EasingStyle.Sine), { GroupTransparency = 0 })
    local canvasOut = Tween(Items["DialogCanvas"], TweenInfo.new(0.1, Enum.EasingStyle.Sine), { GroupTransparency = 1 })
    local scaleIn = Tween(Items["PromptUIScale"], TweenInfo.new(0.1, Enum.EasingStyle.Sine), { Scale = 1 })
    local scaleOut = Tween(Items["PromptUIScale"], TweenInfo.new(0.1, Enum.EasingStyle.Sine), { Scale = 0.95 })

    local function dialogIn()
        canvasIn:Play()
        scaleIn:Play()
        canvasIn.Completed:Wait()
        Items["Dialog"].Parent = self.Items["Base"]
    end

    local function dialogOut()
        if not Items["Dialog"].Parent then return end
        Items["Dialog"].Parent = Items["DialogCanvas"]
        canvasOut:Play()
        scaleOut:Play()
        canvasOut.Completed:Wait()
        Items["DialogCanvas"]:Destroy()
    end

    if Data.Buttons then
        for _, v in pairs(Data.Buttons) do
            local Button = Create("TextButton", {
                Name = "Button",
                FontFace = Font.new(assets.interFont),
                Text = v.Name,
                TextSize = 15,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 0),
                Parent = Items["Interactions"],
            })
            setThemed(Button, "TextColor3", "Text")
            setThemed(Button, "BackgroundColor3", "Accent")

            Create("UIPadding", {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 9),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 9),
                Parent = Button,
            })

            Create("UICorner", {
                Name = "BaseUICorner",
                CornerRadius = UDim.new(0, 10),
                Parent = Button,
            })

            local TweenSettings = {
                DefaultTransparency = 0,
                DefaultTransparency2 = 0.5,
                HoverTransparency = 0.3,
                HoverTransparency2 = 0.6,
                EasingStyle = Enum.EasingStyle.Sine,
            }

            local function ChangeState(State)
                if State == "Idle" then
                    Tween(Button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                        BackgroundTransparency = TweenSettings.DefaultTransparency,
                        TextTransparency = TweenSettings.DefaultTransparency2,
                    }):Play()
                elseif State == "Hover" then
                    Tween(Button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                        BackgroundTransparency = TweenSettings.HoverTransparency,
                        TextTransparency = TweenSettings.HoverTransparency2,
                    }):Play()
                end
            end

            Button.MouseButton1Click:Connect(function()
                if Items["DialogCanvas"].GroupTransparency ~= 0 then return end
                if v.Callback then v.Callback() end
                dialogOut()
            end)

            Button.MouseEnter:Connect(function() ChangeState("Hover") end)
            Button.MouseLeave:Connect(function() ChangeState("Idle") end)
        end
    end

    dialogIn()

    function Dialog:UpdateTitle(New)
        Items["ParagraphHeader"].Text = New
    end

    function Dialog:UpdateDescription(New)
        Items["ParagraphBody"].Text = New
    end

    function Dialog:Cancel()
        dialogOut()
    end
    
    UserInputService.InputBegan:Connect(function(Input)
	    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
	        if Items["DialogCanvas"].GroupTransparency ~= 0 then return end
	        if IsMouseOverFrame(Items["Prompt"]) then return end
	        Dialog:Cancel()
	    end
	end)

    return Dialog
end

local function Demo()
local Window = TanukiLib:Window({
    Name = "Fe All Emote",
    SubName = "Animations",
    Icon = "lucide/house",
})

local MainPage = Window:Page({ Name = "Main" })

local Group = Window:PageGroup({})

local Misc = Group:Page({ Name = "Miscellaneous", Icon = "lucide/house" })

Window:Divider()

local MainSection = MainPage:Section({
    Name = "General",
})

local SubSection = Misc:Section({
    Name = "Miscellaneous",
})

MainSection:Header({ Name = "My Header Title" })

MainSection:Button({
    Name = "Switch theme to white",
    Callback = function()
        TanukiLib:Notify({
		    Name = "Notification",
		    Description = "Theme Switched",
		    Duration = 5,
		})
		TanukiLib:SetTheme("Light")
    end
})

MainSection:Button({
    Name = "Switch theme to Dark",
    Callback = function()
        TanukiLib:Notify({
		    Name = "Notification",
		    Description = "Theme Switched",
		    Duration = 5,
		})
		TanukiLib:SetTheme("Dark")
    end
})

MainSection:Paragraph({
	Header = "MF what",
	Body = "Click Lock toggle to lock it"
})

MainSection:Label({
	Text = "Bold Label",
	Bold = true,
})

local Toggle = MainSection:Toggle({
    Name = "Enable Thing",
    Default = false,
    Callback = function(state)
        print("toggled:", state)
    end
})

MainSection:Button({
    Name = "Lock Toggle",
    Callback = function()
        Toggle:Lock()
    end
})

MainSection:Slider({
	Name = "Window Size",
	Default = 50,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Percent",
	Precision = 0,
	Callback = function(value)
		print(value)
	end
})

MainSection:Input({
	Name = "Rename Label",
	Placeholder = "New label text...",
	AcceptedCharacters = "All",
	Callback = function(text)
		print(text)
	end
})

MainSection:Keybind({
	Name = "Keybind",
	Blacklist = false,
	Callback = function(binded)
		TanukiLib:Notify({
			Title = "Demo Window",
			Description = "Pressed keybind - "..tostring(binded.Name),
			Duration = 3
		})
	end,
	onBinded = function(bind)
		TanukiLib:Notify({
			Title = "Demo Window",
			Description = "Successfully Binded Keybind to - "..tostring(bind.Name),
			Duration = 3
		})
	end,
})

MainSection:Dropdown({
	Name = "Theme",
	Required = true,
	Options = TanukiLib:GetThemes(),
	Callback = function(value)
		TanukiLib:SetTheme(value)
	end,
})

local optionTable = {
	"Apple",
	"Banana",
	"Orange",
	"Grapes",
	"Pineapple",
	"Mango",
	"Strawberry",
	"Blueberry",
	"Watermelon",
	"Peach"
}

local MultiDropdown = MainSection:Dropdown({
	Name = "Multi Dropdown",
	Search = true,
	Multi = true,
	Required = false,
	Options = optionTable,
	Default = {"Apple", "Orange"},
	Callback = function(Value)
		local Values = {}
		for Value, State in next, Value do
			table.insert(Values, Value)
		end
		print("Mutlidropdown changed:", table.concat(Values, ", "))
	end,
})

MainSection:Colorpicker({
	Name = "Colorpicker",
	Default = Color3.fromRGB(0, 255, 255),
	Callback = function(color)
		print("Color: ", color)
	end,
})

MainSection:Colorpicker({
	Name = "Colorpicker with alpha",
	Default = Color3.fromRGB(0, 255, 255),
    Alpha = 0.67,
	Callback = function(color)
		print("Color: ", color)
	end,
})

SubSection:Slider({
	Name = "Window Size",
	Default = 50,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Percent",
	Precision = 0,
	Callback = function(value)
		local t = value / 100
		Window:SetSize(UDim2.fromOffset(400 + (1000 - 400) * t, 250 + (800 - 250) * t))
	end,
})

SubSection:Slider({
	Name = "Window Scale Size",
	Default = Window:GetScale(),
	Minimum = 0.1,
	Maximum = 5,
	DisplayMethod = "Percent",
	Precision = 0,
	Callback = function(value)
		Window:SetScale(value)
	end,
})

MainPage:Select()
end
--Demo()

TanukiLib.setThemed = setThemed
getgenv().TanukiLib = TanukiLib

return TanukiLib
