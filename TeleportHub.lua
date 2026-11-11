-- TC坐标传送 · Delta 执行器专用（纯客户端 / 手机竖屏）
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local DSStore = nil
pcall(function()
    DSStore = game:GetService("DataStoreService"):GetDataStore("TPH_Delta_v1")
end)

local K_COORDS = "TPH_coords_v1"
local K_GROUPS = "TPH_groups_v1"
local K_QUICK  = "TPH_quickGroupId"
local K_INTERV = "TPH_interval_v1"
local K_SPEED  = "TPH_speed_v1"

local Coords = {}
local Groups = {}
local QuickGroupId = nil
local Sel = {}
local Interval = 0.5
local Speed = 30
local LoopRunning = false
local LoopThread = nil
local LoopGroupId = nil
local MoveRunning = false
local MoveThread = nil
local MoveGroupId = nil
local minimized = false
local quickOn = false
local currentTab = 1
local Spectating = false
local SpectateRedirect = true
local savedCamType, savedCamSubject = nil, nil
local camPos = Vector3.new(0, 0, 0)
local camBaseRot = CFrame.new()
local camYaw, camPitch = 0, 0
local camStickVec = Vector2.new(0, 0)
local camStickInput = nil
local camLookInput = nil
local camLookStart = nil
local spectateCharCF = nil

local C_BG   = Color3.fromRGB(24, 25, 28)
local C_BG2  = Color3.fromRGB(35, 37, 42)
local C_BG3  = Color3.fromRGB(52, 55, 62)
local C_BLUE = Color3.fromRGB(58, 128, 245)
local C_GREEN= Color3.fromRGB(52, 168, 88)
local C_ORG  = Color3.fromRGB(232, 148, 52)
local C_RED  = Color3.fromRGB(208, 68, 68)
local C_PURP = Color3.fromRGB(142, 86, 214)
local C_TXT  = Color3.fromRGB(240, 242, 248)
local C_TXT2 = Color3.fromRGB(158, 163, 178)
local C_WHITE= Color3.fromRGB(255, 255, 255)

local IMG_W, IMG_H, IMG_NPAL = 48, 48, 24
local IMG_B64 = table.concat({
    "AAAA1NbXgYODS0pJExMSBAQCBAMCAwMDAwMCAwMBAwMAAgMAAwIBAgICAgIBAgIAAQIBAgEBAQECAQEBAQEAAAEBAAABAAAAAAAAAAAAAAAAAA",
    "AAAAAAAAAAAAAODg4ODhMTEwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABMTEw4JCAkODhMTEw4ODg4AAAAAAAAAAAAAAAAA",
    "AAAAAAAAAAAAAAAAAAAAAAAOCAkOEw4JCQ4ODhMWEw4ODg4ODgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACQkICAUIDg4ODg4OCQ4RDgkJDA",
    "kODgkJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUFCQgICAUICQkJDg4JCAgJCAkJDg4JDg8KCgoAAAAAAAAAAAAAAAAAAAAAAAAACQUFBQUJCQUJ",
    "BQUJBgUFCQkICQ4ODhMODg8PDw8JAAAAAAAAAAAAAAAAAAAAAAAJBQkJBQUJCQgFBQgJBQUJCQkJDhMODg4JDg8PDw8JCQAAAAAAAAAAAAAAAA",
    "AAAAkJCAgJCAkICAkJCQkJCAkICQgJDhMOCAkICQ8PDAkJCQkAAAAAAAAAAAAAAAAACQkICQkJCQkJCQ4OEw4JCQkJCQkICQkJCQkICQkKCQkJ",
    "Cg8KAAAAAAAAAAAAAAAJCQkJCQ4LCQkJCQ4OExEJCQkJCQkJBgkJCQkJCAkJCQoPDw8PDwAAAAAAAAAAAA4JCQkJDhETDgkJCAkJCQ4JBQkJCQ",
    "gFBQkJCQkJCQkJCQwPFA8PDwoAAAAAAAAAAA4OCQkODg4TDgkJCQgICAkJBQkICAUJCQUGCAkJCQkJCQ8UFA8UFAsAAAAAAAAACQ4TDg4ODg4O",
    "DgkJCAkJCQUFCQkJCQgJCQgFBQkJCQkJCQ8UFBQPFA8JAAAAAAAADg4TDgwODg4MDgwJCQkICAUFCQkJCQ4OCQkJCQkJCQkJCQkUFBEPDwoJAA",
    "AAAAAODg4OCQ4ODgkJCQkICAkOFAgIDhQODhcXDQ0OCQkICQkJCQkUFA8PDwoPDwAAAAAODgwJDg4QDggJCQkJCQkNBRcXEQcTDgURFxcTEQkI",
    "CQkJCQ8PDw8PDwwPDwAAAAkODg4ODg4OEwkJCQkJBQ4FAwICAgQTEwQCAgMXDA4JCQkJChQPEQ8PDwoUFA8AAAkJDg4OExEOEwkJCQkJCQkNFw",
    "IBAxcHCBcEAQEFEwgJCQkJChEUFBQPDwkMDw8AAAkODg4RExMTEQkJCAkJCAgFFwIBAxcFCBMIAQEDFwUOCQkPFA8UFBQPCgkJCQ8AAAkODhMW",
    "ExMRDgkJCQkJCAUFFwIBAxcFBRcDAwEBDQ0ICQkJFA8PFA8KCQoKCQoAEQkJDhMTExMODgkJCAgJCQkFEwIBAxcFDgUDBwIBAxcFCQkJDw8PDw",
    "kJCgkKCQkPEwkJCQ4OExMRDgkJCAkIBQ4XFwIBAxMFEwMDFwMBAhcFCQkJCQ8PDwkJCgoLCgkPEw4ODg4OExMTDgkJCQgXFxcEBAIBAxcXFwME",
    "FwQBAQQXBQkKCgkJDwoJCg8PDwoPEwkMDg4JCQ4ODg4OCBcFAwMDAwIBAgMDBAMXBRcCAQIXBQwKCQkJCgkJCQkPDw8PDgkJDgkJCAkJCQkIFw",
    "QCAgQXFwIBAwQDAgIEFxcEAQEHEQkKCgkJCQkKCQkKDAoPEw4JDg4ICQkICQUTBAECFxcFDQIBAxcXAwQDAwQXAgEDFwUPDwoJCQkKCQkPDwkP",
    "Ew4ODhMOCQkOCQcXAwEEEwUFFwIBAxMEAxcXBAMDAgECFwgPDw8KCgoKCQkPDwkPEw4ODhMOCQkRDggXAgEDFwUFFwIBAxcDBBMFFxcEBAIBBB",
    "cIDxEPDw8KCgkPDwkPAA4OCQkJCQkRDggXAwIDEwUIEwICBAcDDREOCAcXFwMBAxcFDw8PFA8JCgkJCQkAAA4TEw4JCQkOEwUXBAIDFwUXFwID",
    "FwQEFwYODg4FEwQCAgQXCQ8PDw8JCgkJCQkAAAwTExMTEw4ODg4OBgMCBBcTAwIEBAIDDQgODg4IEwQCAgMFDQ8PDwwJCgkJCQkAAAgODg4TEQ",
    "4ODg4OExcEAwMDAwQFAwMDBBMIDg4TBQMDAwMDFAkPCgkJCQkJCQkAAAAODg4ODg4OCQkOCQgXFwUHFxcSFxcXFw4OExMTExcXFxcXDwkJCQkJ",
    "DA8KDwAAAAAMDg4MCQ4ODg4ODAkFBRQPBQwUDQgIDg4RFBMTDggFBQYODwkJCQkPDw8PDwAAAAAAEQ8KCg8PDw8PDw8PDAkKDA8PDw8PDw8PDw",
    "8UCgoJCg8UEQoJCQoPDw8JAAAAAAAADw8JCQ8PDxEPCg8PCQkJCQkJCQoPDw8PCQkKCQkJCQkPDwkJCQwPDw8JAAAAAAAAAAkJCQkPDw8JCQkK",
    "CQkJCQkJCQkPCQkJCQkJCQkJCQkJCQkJCQkKDwkAAAAAAAAAAAkJCQkPFAoJCQkJCQUGCQkFBQkJCQkJCQYJCQkJCQkJCQkJCQkJCQkAAAAAAA",
    "AAAAAJCQkJCgkJCQkJCQYJCQkJBQYJCQkJCQkJCQkJCQkJCQkJCgkKCQAAAAAAAAAAAAAACQkJCQkJCQkJCQkJCQkJBQkJCQkJCQkJCQkJCQkJ",
    "CQwPCgoKAAAAAAAAAAAAAAAAAAkJCQkJCQkJCQkJCQoKDAkJCQkJCgkJCQoMDAoJChEPDw8AAAAAAAAAAAAAAAAAAAAKCQkJCQkJCQkJCQ8PDw",
    "8KCQkKDw8PDw8PCQoKDxQUDwAAAAAAAAAAAAAAAAAAAAAACQkJCQkJCQkJCQoPDw8JCQkKDw8PDw8KCQkJDw8PAAAAAAAAAAAAAAAAAAAAAAAA",
    "AAkJCQkJCQkJCQkJCgkJCQkJCQ8MCQkJCQkJDw8AAAAAAAAAAAAAAAAAAAAAAAAAAAAACQkJCQkJCQkJCQkJCQkJCQkJCQkJCQoJAAAAAAAAAA",
    "AAAAAAAAAAAAAAAAAAAAAAAAAJCQkJCQkJCQkJCQkJCQkJCQkJCQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAkJCQkJCQkJCQkJCQkJ",
    "CQkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAODg4ODg8PDgAAAAAAAAAAAAAAAAAAAAAAAAAA",
}, "")

local Rainbow = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 95, 95)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 190, 70)),
    ColorSequenceKeypoint.new(0.34, Color3.fromRGB(90, 225, 130)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(70, 185, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(150, 110, 255)),
    ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 110, 205)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 95, 95))
})

local function safe(fn)
    local ok, res = pcall(fn)
    if ok then return res end
    return nil
end

local function viewport()
    local cam = safe(function() return workspace.CurrentCamera end)
    if cam then return cam.ViewportSize end
    return Vector2.new(1080, 1920)
end

local function saveAttr(key, value)
    safe(function()
        LP:SetAttribute(key, HttpService:JSONEncode(value))
    end)
end

local function loadAttr(key)
    local raw = safe(function() return LP:GetAttribute(key) end)
    if type(raw) ~= "string" then return nil end
    local dec = safe(function() return HttpService:JSONDecode(raw) end)
    if type(dec) == "table" then return dec end
    return nil
end

local function trySaveDS(key, value)
    if not DSStore then return end
    safe(function()
        DSStore:SetAsync(tostring(LP.UserId) .. "_" .. key, HttpService:JSONEncode(value))
    end)
end

local function tryLoadDS(key)
    if not DSStore then return nil end
    local raw = safe(function()
        return DSStore:GetAsync(tostring(LP.UserId) .. "_" .. key)
    end)
    if type(raw) ~= "string" then return nil end
    local dec = safe(function() return HttpService:JSONDecode(raw) end)
    if type(dec) == "table" then return dec end
    return nil
end

local function newId(prefix)
    return prefix .. tostring(math.random(100000, 999999))
end

local function findCoord(id)
    for _, c in ipairs(Coords) do if c.id == id then return c end end
    return nil
end

local function findGroup(id)
    for _, g in ipairs(Groups) do if g.id == id then return g end end
    return nil
end

local function make(class, props)
    local radius = props.CornerRadius
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "CornerRadius" then obj[k] = v end
    end
    if obj:IsA("GuiObject") then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 6)
        c.Parent = obj
    end
    return obj
end

local function label(parent, text, size, pos, color, fs, z, align)
    return make("TextLabel", {
        Text = text,
        Size = size,
        Position = pos,
        BackgroundTransparency = 1,
        TextColor3 = color or C_TXT,
        Font = Enum.Font.Gotham,
        TextSize = fs or 12,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        ZIndex = z or 12,
        Parent = parent
    })
end

local function button(parent, text, size, pos, color, fs, z)
    return make("TextButton", {
        Text = text,
        Size = size,
        Position = pos,
        BackgroundColor3 = color,
        TextColor3 = C_WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = fs or 12,
        ZIndex = z or 13,
        Parent = parent
    })
end

local Gui = make("ScreenGui", {
    Name = "TC坐标传送",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    Parent = PlayerGui
})

local function b64decode(s)
    local B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local map = {}
    for i = 1, #B do map[B:sub(i, i)] = i - 1 end
    local out, acc, bits = {}, 0, 0
    for i = 1, #s do
        local c = s:sub(i, i)
        if c ~= "=" then
            local v = map[c]
            if v then
                acc = acc * 64 + v
                bits = bits + 6
                if bits >= 8 then
                    bits = bits - 8
                    local d = 2 ^ bits
                    out[#out + 1] = string.char(math.floor(acc / d) % 256)
                    acc = acc % d
                end
            end
        end
    end
    return table.concat(out)
end

local AvatarRaw = nil
local function avatarRaw()
    if AvatarRaw then return AvatarRaw end
    local ok, res = pcall(b64decode, IMG_B64)
    if ok and type(res) == "string" and #res >= IMG_NPAL * 3 + IMG_W * IMG_H then
        AvatarRaw = res
    end
    return AvatarRaw
end

local function avatarColor(raw, idx)
    local o = idx * 3
    return string.byte(raw, o + 1) or 0,
        string.byte(raw, o + 2) or 0,
        string.byte(raw, o + 3) or 0
end

local function applyAvatar(btn, txtLabel)
    local raw = avatarRaw()
    if not raw then return false end
    local OFF = IMG_NPAL * 3
    local ok = pcall(function()
        local AS = game:GetService("AssetService")
        local ei = AS:CreateEditableImage({Size = Vector2.new(IMG_W, IMG_H)})
        if not ei then error("editable unavailable") end
        local buf = buffer.create(IMG_W * IMG_H * 4)
        for p = 0, IMG_W * IMG_H - 1 do
            local idx = string.byte(raw, OFF + p + 1) or 0
            local o = p * 4
            if idx == 0 then
                buffer.writeu8(buf, o, 0)
                buffer.writeu8(buf, o + 1, 0)
                buffer.writeu8(buf, o + 2, 0)
                buffer.writeu8(buf, o + 3, 0)
            else
                local r, g, b = avatarColor(raw, idx)
                buffer.writeu8(buf, o, r)
                buffer.writeu8(buf, o + 1, g)
                buffer.writeu8(buf, o + 2, b)
                buffer.writeu8(buf, o + 3, 255)
            end
        end
        ei:WritePixelsBuffer(Vector2.zero, Vector2.new(IMG_W, IMG_H), buf)
        local content = Content.fromObject(ei)
        local okSet = pcall(function() btn.ImageContent = content end)
        if not okSet then pcall(function() btn.Image = content end) end
    end)
    if ok then
        if txtLabel then txtLabel.Visible = false end
        return true
    end
    local drawn = pcall(function()
        local N = 24
        local cell = 44 / N
        for gy = 0, N - 1 do
            for gx = 0, N - 1 do
                local sx = math.floor(gx * IMG_W / N)
                local sy = math.floor(gy * IMG_H / N)
                local idx = string.byte(raw, OFF + sy * IMG_W + sx + 1) or 0
                if idx ~= 0 then
                    local r, g, b = avatarColor(raw, idx)
                    local f = Instance.new("Frame")
                    f.BorderSizePixel = 0
                    f.Size = UDim2.new(0, cell + 0.6, 0, cell + 0.6)
                    f.Position = UDim2.new(0, gx * cell, 0, gy * cell)
                    f.BackgroundColor3 = Color3.fromRGB(r, g, b)
                    f.ZIndex = 22
                    f.Parent = btn
                end
            end
        end
    end)
    if drawn and txtLabel then txtLabel.Visible = false end
    return drawn
end

local spinTween = nil
local function rainbowBorder(target, pad, radius, spin)
    local back = make("Frame", {
        Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + pad * 2,
            target.Size.Y.Scale, target.Size.Y.Offset + pad * 2),
        Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset - pad,
            target.Position.Y.Scale, target.Position.Y.Offset - pad),
        BackgroundColor3 = C_WHITE,
        ZIndex = math.max(1, target.ZIndex - 1),
        CornerRadius = radius,
        Parent = target.Parent
    })
    local grad = Instance.new("UIGradient")
    grad.Color = Rainbow
    grad.Rotation = 0
    grad.Parent = back
    if spin then
        local tw = TweenService:Create(grad,
            TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {Rotation = 360})
        spinTween = tw
        tw:Play()
    end
    return back
end

local Toast = make("TextLabel", {
    Text = "",
    Size = UDim2.new(0, 240, 0, 38),
    Position = UDim2.new(0.5, -120, 0, 14),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.08,
    TextColor3 = C_WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Visible = false,
    ZIndex = 990,
    CornerRadius = 12,
    Parent = Gui
})

local toastToken = 0
local function showToast(msg)
    toastToken = toastToken + 1
    local my = toastToken
    Toast.Text = tostring(msg)
    Toast.Visible = true
    Toast.TextTransparency = 0
    Toast.BackgroundTransparency = 0.08
    task.delay(2.5, function()
        if my ~= toastToken then return end
        local tw = TweenService:Create(Toast, TweenInfo.new(0.4), {
            TextTransparency = 1,
            BackgroundTransparency = 1
        })
        tw:Play()
        tw.Completed:Connect(function()
            if my == toastToken then Toast.Visible = false end
        end)
    end)
end

local modalDepth = 500
local function newOverlay()
    modalDepth = modalDepth + 10
    return make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55,
        Active = true,
        Visible = true,
        ZIndex = modalDepth,
        CornerRadius = 0,
        Parent = Gui
    })
end

local function closeOverlay(ov)
    modalDepth = ov.ZIndex - 10
    safe(function() ov:Destroy() end)
end

local function modalInput(title, defaultText)
    local ov = newOverlay()
    local z = ov.ZIndex
    local win = make("Frame", {
        Size = UDim2.new(0, 268, 0, 148),
        Position = UDim2.new(0.5, -134, 0.5, -74),
        BackgroundColor3 = C_BG2,
        ZIndex = z + 1,
        CornerRadius = 10,
        Parent = ov
    })
    rainbowBorder(win, 2, 12, false)
    label(win, title, UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, 10), C_WHITE, 15, z + 2)
    local box = make("TextBox", {
        Text = defaultText or "",
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, 44),
        BackgroundColor3 = C_BG3,
        TextColor3 = C_WHITE,
        PlaceholderText = "请输入...",
        PlaceholderColor3 = C_TXT2,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        ClearTextOnFocus = false,
        ZIndex = z + 2,
        Parent = win
    })
    local closed = false
    local result = nil
    local escConn = nil
    local function close(v)
        if closed then return end
        closed = true
        result = v
        if escConn then safe(function() escConn:Disconnect() end) end
        closeOverlay(ov)
    end
    button(win, "取消", UDim2.new(0, 76, 0, 32), UDim2.new(0, 12, 1, -42), C_BG3, 13, z + 2)
        .MouseButton1Click:Connect(function() close(nil) end)
    button(win, "确定", UDim2.new(0, 76, 0, 32), UDim2.new(1, -88, 1, -42), C_GREEN, 13, z + 2)
        .MouseButton1Click:Connect(function() close(box.Text) end)
    box.FocusLost:Connect(function(enter)
        if enter and not closed then close(box.Text) end
    end)
    escConn = UIS.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.Escape and ov.ZIndex == modalDepth then close(nil) end
    end)
    task.delay(0.1, function()
        if not closed then pcall(function() box:CaptureFocus() end) end
    end)
    repeat task.wait(0.05) until closed
    return result
end

local function modalConfirm(title, msg, okText)
    local ov = newOverlay()
    local z = ov.ZIndex
    local win = make("Frame", {
        Size = UDim2.new(0, 268, 0, 158),
        Position = UDim2.new(0.5, -134, 0.5, -79),
        BackgroundColor3 = C_BG2,
        ZIndex = z + 1,
        CornerRadius = 10,
        Parent = ov
    })
    rainbowBorder(win, 2, 12, false)
    label(win, title, UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 10), C_ORG, 15, z + 2)
    label(win, msg, UDim2.new(1, -24, 0, 48), UDim2.new(0, 12, 0, 42), C_TXT, 13, z + 2)
    local closed = false
    local result = false
    local escConn = nil
    local function close(v)
        if closed then return end
        closed = true
        result = v
        if escConn then safe(function() escConn:Disconnect() end) end
        closeOverlay(ov)
    end
    button(win, "取消", UDim2.new(0, 76, 0, 32), UDim2.new(0, 12, 1, -42), C_BG3, 13, z + 2)
        .MouseButton1Click:Connect(function() close(false) end)
    button(win, okText or "确认", UDim2.new(0, 76, 0, 32), UDim2.new(1, -88, 1, -42), C_RED, 13, z + 2)
        .MouseButton1Click:Connect(function() close(true) end)
    escConn = UIS.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.Escape and ov.ZIndex == modalDepth then close(false) end
    end)
    repeat task.wait(0.05) until closed
    return result
end

local function tel(x, y, z)
    if Spectating and SpectateRedirect then
        camPos = Vector3.new(x, y, z)
        return true
    end
    local char = LP.Character
    if not char or not char.PrimaryPart then
        char = safe(function() return LP.CharacterAdded:Wait() end)
    end
    if not char then showToast("角色未就绪") return false end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then showToast("角色未就绪") return false end
    if not char.PrimaryPart then
        pcall(function() char.PrimaryPart = root end)
    end
    local rot = root.CFrame - root.CFrame.Position
    pcall(function() char:PivotTo(CFrame.new(x, y, z) * rot) end)
    return true
end

local function getPos()
    local char = LP.Character
    if not char or not char.PrimaryPart then
        char = safe(function() return LP.CharacterAdded:Wait() end)
    end
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return nil end
    return root.Position
end

local refreshC, refreshG, startLoop, stopLoop, openManage, applyLayout, switchTab, updateQuickUI, makeDrag
local startMove, stopMove, updateMoveUI

local Main = make("Frame", {
    Size = UDim2.new(0, 280, 0, 380),
    Position = UDim2.new(0, 12, 0.5, -190),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.06,
    ZIndex = 10,
    CornerRadius = 10,
    Parent = Gui
})
local Glow = rainbowBorder(Main, 2, 12, true)

local Title = make("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = C_BG2,
    ZIndex = 11,
    CornerRadius = 10,
    Parent = Main
})
local TitleLbl = label(Title, "TC坐标传送", UDim2.new(1, -128, 1, 0), UDim2.new(0, 10, 0, 0), C_WHITE, 14, 12)
local QuitB = button(Title, "关脚本", UDim2.new(0, 40, 0, 30), UDim2.new(1, -118, 0, 2), Color3.fromRGB(150, 45, 45), 9, 12)
local MinB = button(Title, "—", UDim2.new(0, 32, 0, 30), UDim2.new(1, -74, 0, 2), C_BG3, 16, 12)
local CloseB = button(Title, "X", UDim2.new(0, 32, 0, 30), UDim2.new(1, -38, 0, 2), C_RED, 15, 12)

local Tabs = make("Frame", {
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 34),
    BackgroundColor3 = C_BG,
    ZIndex = 11,
    Parent = Main
})
local TabC, TabG, TabS
do
    local defs = {"📌 坐标", "🧩 组合", "⚙️ 设置"}
    local btns = {}
    for i, t in ipairs(defs) do
        btns[i] = button(Tabs, t,
            UDim2.new(1 / 3, -2, 1, -4),
            UDim2.new((i - 1) / 3, 1, 0, 2),
            C_BG3, 11, 12)
    end
    TabC, TabG, TabS = btns[1], btns[2], btns[3]
end

local CPage = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -122),
    Position = UDim2.new(0, 0, 0, 66),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 11,
    Visible = true,
    Parent = Main
})
local GPage = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -122),
    Position = UDim2.new(0, 0, 0, 66),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 11,
    Visible = false,
    Parent = Main
})
local SPage = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -122),
    Position = UDim2.new(0, 0, 0, 66),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 340),
    ZIndex = 11,
    Visible = false,
    Parent = Main
})

local SaveB = button(CPage, "💾 保存当前位置", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), C_GREEN, 14, 12)
local CHdr = make("Frame", {
    Size = UDim2.new(1, -20, 0, 28),
    Position = UDim2.new(0, 10, 0, 50),
    BackgroundTransparency = 1,
    ZIndex = 12,
    Parent = CPage
})
local CCount = label(CHdr, "📍 所有坐标 (0)", UDim2.new(0, 170, 1, 0), UDim2.new(0, 0, 0, 0), C_TXT2, 12, 13)
local AllB = button(CHdr, "全选", UDim2.new(0, 54, 0, 24), UDim2.new(1, -58, 0, 2), C_BG3, 11, 13)
local CList = make("Frame", {
    Size = UDim2.new(1, -20, 0, 0),
    Position = UDim2.new(0, 10, 0, 84),
    BackgroundTransparency = 1,
    ZIndex = 12,
    Parent = CPage
})
local CLayout = Instance.new("UIListLayout")
CLayout.Padding = UDim.new(0, 4)
CLayout.Parent = CList

local CrGB = button(GPage, "➕ 从选中坐标创建组合", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), C_PURP, 13, 12)
local MngB = button(GPage, "🔧 管理组合", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 50), C_BG3, 13, 12)
local MoveBar = make("Frame", {
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.new(0, 10, 0, 88),
    BackgroundTransparency = 1,
    ZIndex = 12,
    Parent = GPage
})
local MoveBtn = button(MoveBar, "🚀 快速移动", UDim2.new(0, 140, 0, 34), UDim2.new(0, 0, 0, 0), C_PURP, 12, 13)
label(MoveBar, "速度", UDim2.new(0, 28, 1, 0), UDim2.new(0, 142, 0, 0), C_TXT2, 11, 13)
local SpeedBox = make("TextBox", {
    Text = tostring(Speed),
    Size = UDim2.new(0, 84, 0, 30),
    Position = UDim2.new(0, 172, 0, 2),
    TextScaled = true,
    BackgroundColor3 = C_BG3,
    TextColor3 = C_WHITE,
    PlaceholderText = "30",
    PlaceholderColor3 = C_TXT2,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ClearTextOnFocus = false,
    ZIndex = 13,
    Parent = MoveBar
})
local GList = make("Frame", {
    Size = UDim2.new(1, -20, 0, 0),
    Position = UDim2.new(0, 10, 0, 126),
    BackgroundTransparency = 1,
    ZIndex = 12,
    Parent = GPage
})
local GLayout = Instance.new("UIListLayout")
GLayout.Padding = UDim.new(0, 4)
GLayout.Parent = GList

label(SPage, "存储: Player Attributes (本地)", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 8), C_TXT2, 12, 12)
label(SPage, "DataStore 可选，失败静默忽略", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 30), C_TXT2, 11, 12)
local ExpB = make("TextBox", {
    Text = "",
    Size = UDim2.new(1, -20, 0, 76),
    Position = UDim2.new(0, 10, 0, 58),
    BackgroundColor3 = C_BG3,
    TextColor3 = C_TXT,
    PlaceholderText = "导出 JSON 显示在这里...",
    PlaceholderColor3 = C_TXT2,
    Font = Enum.Font.Code,
    TextSize = 10,
    TextWrapped = true,
    MultiLine = true,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 12,
    Parent = SPage
})
local LoadB = button(SPage, "🔄 从 DataStore 加载", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 142), C_BLUE, 13, 12)
local SavB  = button(SPage, "💾 手动保存", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 180), C_GREEN, 13, 12)
local JsnB  = button(SPage, "📤 导出 JSON", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 218), C_ORG, 13, 12)
local ClrB  = button(SPage, "🗑 清空所有数据", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 256), C_RED, 13, 12)

local QPanel = make("Frame", {
    Size = UDim2.new(0, 196, 0, 46),
    Position = UDim2.new(0, 8, 1, -52),
    BackgroundColor3 = C_BG2,
    ZIndex = 14,
    CornerRadius = 8,
    Parent = Main
})
local QToggle = button(QPanel, "💤", UDim2.new(0, 46, 0, 46), UDim2.new(0, 0, 0, 0), C_BG3, 18, 15)
local QGo = button(QPanel, "⚡ 快捷传送", UDim2.new(0, 142, 0, 44), UDim2.new(0, 50, 0, 1), C_ORG, 12, 15)
QGo.Visible = false

local FloatB = make("ImageButton", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(0, 12, 0.5, -22),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit,
    Visible = false,
    ZIndex = 20,
    CornerRadius = 22,
    Parent = Gui
})
local FloatTxt = label(FloatB, "开", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    C_WHITE, 18, 23, Enum.TextXAlignment.Center)
local FloatGlow = rainbowBorder(FloatB, 1, 23, false)
FloatGlow.Visible = false
applyAvatar(FloatB, FloatTxt)

local SpecBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 1, 5),
    BackgroundColor3 = C_BG2,
    ZIndex = 14,
    CornerRadius = 8,
    Parent = Main
})
local SpecBtn = button(SpecBar, "旁观视角", UDim2.new(0, 150, 0, 30), UDim2.new(0, 4, 0, 2), C_BG3, 11, 15)
local SpecMode = button(SpecBar, "模式:视角", UDim2.new(0, 118, 0, 30), UDim2.new(0, 158, 0, 2), C_BLUE, 10, 15)

local CamPanel = make("Frame", {
    Size = UDim2.new(0, 168, 0, 62),
    Position = UDim2.new(1, -178, 0, 12),
    BackgroundColor3 = C_BG,
    BackgroundTransparency = 0.12,
    Visible = false,
    ZIndex = 30,
    CornerRadius = 10,
    Parent = Gui
})
local CamHdr = make("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = C_BG2,
    ZIndex = 31,
    CornerRadius = 10,
    Parent = CamPanel
})
label(CamHdr, "自由视角", UDim2.new(1, -62, 1, 0), UDim2.new(0, 9, 0, 0), C_WHITE, 12, 32)
local CamExit = button(CamHdr, "退出", UDim2.new(0, 48, 0, 24), UDim2.new(1, -54, 0, 2), C_RED, 11, 32)
local CamHint = label(CamPanel, "右滑转视角 · 左摇杆移动", UDim2.new(1, -12, 0, 28),
    UDim2.new(0, 6, 0, 32), C_ORG, 10, 32, Enum.TextXAlignment.Center)

local CamStick = make("Frame", {
    Size = UDim2.new(0, 116, 0, 116),
    Position = UDim2.new(0, 16, 1, -136),
    BackgroundColor3 = C_BG2,
    BackgroundTransparency = 0.45,
    Active = true,
    Visible = false,
    ZIndex = 25,
    CornerRadius = 58,
    Parent = Gui
})
local CamKnob = make("Frame", {
    Size = UDim2.new(0, 48, 0, 48),
    Position = UDim2.new(0.5, -24, 0.5, -24),
    BackgroundColor3 = C_WHITE,
    BackgroundTransparency = 0.18,
    ZIndex = 26,
    CornerRadius = 24,
    Parent = CamStick
})
label(CamStick, "移动", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0.5, 22),
    C_TXT2, 10, 26, Enum.TextXAlignment.Center)

local function currentCam()
    return safe(function() return workspace.CurrentCamera end)
end

local function enterSpectate()
    if Spectating then return end
    local cam = currentCam()
    if not cam then showToast("相机不可用") return end
    savedCamType = cam.CameraType
    savedCamSubject = cam.CameraSubject
    local cf = cam.CFrame
    camPos = cf.Position
    camBaseRot = cf - cf.Position
    camYaw, camPitch = 0, 0
    camStickVec = Vector2.new(0, 0)
    camStickInput, camLookInput, camLookStart = nil, nil, nil
    CamKnob.Position = UDim2.new(0.5, -24, 0.5, -24)
    local ch = LP.Character
    local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart) or nil
    spectateCharCF = root and root.CFrame or nil
    Spectating = true
    pcall(function()
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CameraSubject = nil
    end)
    CamPanel.Visible = true
    CamStick.Visible = true
    SpecBtn.Text = "退出旁观"
    SpecBtn.BackgroundColor3 = C_ORG
    showToast("旁观已开 · 右滑转视角 / 左下摇杆移动")
end

local function exitSpectate()
    if not Spectating then return end
    Spectating = false
    camStickVec = Vector2.new(0, 0)
    camStickInput, camLookInput, camLookStart = nil, nil, nil
    CamKnob.Position = UDim2.new(0.5, -24, 0.5, -24)
    CamPanel.Visible = false
    CamStick.Visible = false
    spectateCharCF = nil
    SpecBtn.Text = "旁观视角"
    SpecBtn.BackgroundColor3 = C_BG3
    local cam = currentCam()
    if cam then
        pcall(function()
            cam.CameraType = savedCamType or Enum.CameraType.Custom
            cam.CameraSubject = savedCamSubject
        end)
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid") or nil
        if hum then pcall(function() cam.CameraSubject = hum end) end
    end
    showToast("视角已回到角色")
end

local RunService = safe(function() return game:GetService("RunService") end)
if RunService then
    pcall(function()
        RunService.RenderStepped:Connect(function(dt)
            if not Spectating then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
            dt = math.min(tonumber(dt) or 0.03, 0.1)
            local rot = CFrame.Angles(camPitch, camYaw, 0)
            local cf = CFrame.new(camPos) * camBaseRot * rot
            local _, yawOnly = cf:ToEulerAnglesYXZ()
            local flat = CFrame.Angles(0, yawOnly, 0)
            local f = flat.LookVector
            local r = flat.RightVector
            local v = f * (-camStickVec.Y) + r * camStickVec.X
            local step = Vector3.zero
            if v.Magnitude > 0.01 then
                step = v.Unit * (Speed * dt) * math.min(1, v.Magnitude)
            end
            local ch = LP.Character
            local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart) or nil
            if SpectateRedirect then
                camPos = camPos + step
                if root and spectateCharCF then
                    local drift = (root.CFrame.Position - spectateCharCF.Position).Magnitude
                    if drift > 0.4 then
                        pcall(function()
                            root.CFrame = spectateCharCF
                            root.AssemblyLinearVelocity = Vector3.zero
                        end)
                    end
                end
            elseif root and step.Magnitude > 0 then
                pcall(function() root.CFrame = root.CFrame + step end)
            end
            cam.CFrame = CFrame.new(camPos) * camBaseRot * rot
        end)
    end)
end

-- 左下摇杆：按住拖动，方向映射到前进/左右
CamStick.InputBegan:Connect(function(i)
    if not Spectating or camStickInput then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 or
        i.UserInputType == Enum.UserInputType.Touch then
        camStickInput = i
        local c = CamStick.AbsolutePosition + CamStick.AbsoluteSize / 2
        local d = Vector2.new(i.Position.X - c.X, i.Position.Y - c.Y)
        local m = math.min(1, d.Magnitude / 42)
        camStickVec = d.Magnitude > 0 and d.Unit * m or Vector2.new(0, 0)
        CamKnob.Position = UDim2.new(0.5, -24 + camStickVec.X * 34,
            0.5, -24 + camStickVec.Y * 34)
    end
end)
UIS.InputChanged:Connect(function(i)
    if not camStickInput or not Spectating then return end
    local touchSame = camStickInput.UserInputType == Enum.UserInputType.Touch and i == camStickInput
    local mouseMove = i.UserInputType == Enum.UserInputType.MouseMovement and
        camStickInput.UserInputType ~= Enum.UserInputType.Touch
    if not (touchSame or mouseMove) then return end
    local c = CamStick.AbsolutePosition + CamStick.AbsoluteSize / 2
    local d = Vector2.new(i.Position.X - c.X, i.Position.Y - c.Y)
    local m = math.min(1, d.Magnitude / 42)
    camStickVec = d.Magnitude > 0 and d.Unit * m or Vector2.new(0, 0)
    CamKnob.Position = UDim2.new(0.5, -24 + camStickVec.X * 34,
        0.5, -24 + camStickVec.Y * 34)
end)

-- 屏幕空白处直接滑动转视角（点在 UI 上时不抢）
local function inStick(pos)
    local a = CamStick.AbsolutePosition
    local s = CamStick.AbsoluteSize
    return pos.X >= a.X - 8 and pos.X <= a.X + s.X + 8 and
        pos.Y >= a.Y - 8 and pos.Y <= a.Y + s.Y + 8
end

local function overMyUI(pos)
    local ok, objs = pcall(function()
        return UIS:GetGuiObjectsAtPosition(Vector2.new(pos.X, pos.Y))
    end)
    if not ok or type(objs) ~= "table" then
        local vp = viewport()
        return pos.X < vp.X * 0.45
    end
    for _, o in ipairs(objs) do
        if o and o:IsA("GuiObject") and o.Visible and o.ZIndex >= 10 then
            local okMine, isMine = pcall(function() return o:IsDescendantOf(Gui) end)
            if okMine and isMine then return true end
        end
    end
    return false
end

local function sameInput(a, b)
    if a == b then return true end
    if a and b and a.UserInputType == b.UserInputType and
        a.UserInputType ~= Enum.UserInputType.Touch then return true end
    return false
end

UIS.InputBegan:Connect(function(i)
    if not Spectating or camStickInput or camLookInput then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and
        i.UserInputType ~= Enum.UserInputType.Touch then return end
    if CamStick.Visible and inStick(i.Position) then return end
    if overMyUI(i.Position) then return end
    camLookInput = i
    camLookStart = i.Position
end)
UIS.InputChanged:Connect(function(i)
    if not camLookInput or not camLookStart or not Spectating then return end
    local touchSame = camLookInput.UserInputType == Enum.UserInputType.Touch and i == camLookInput
    local mouseMove = i.UserInputType == Enum.UserInputType.MouseMovement and
        camLookInput.UserInputType ~= Enum.UserInputType.Touch
    if not (touchSame or mouseMove) then return end
    local d = i.Position - camLookStart
    camLookStart = i.Position
    camYaw = camYaw - d.X * 0.006
    camPitch = math.clamp(camPitch - d.Y * 0.006, -1.45, 1.45)
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and
        i.UserInputType ~= Enum.UserInputType.Touch then return end
    if camLookInput and sameInput(i, camLookInput) then
        camLookInput, camLookStart = nil, nil
    end
    if camStickInput and sameInput(i, camStickInput) then
        camStickInput = nil
        camStickVec = Vector2.new(0, 0)
        CamKnob.Position = UDim2.new(0.5, -24, 0.5, -24)
    end
end)

SpecBtn.MouseButton1Click:Connect(function()
    if Spectating then exitSpectate() else enterSpectate() end
end)
SpecMode.MouseButton1Click:Connect(function()
    SpectateRedirect = not SpectateRedirect
    SpecMode.Text = SpectateRedirect and "模式:视角" or "模式:角色"
    SpecMode.BackgroundColor3 = SpectateRedirect and C_BLUE or C_PURP
    CamHint.Text = SpectateRedirect and "角色留在原地" or "摇杆移动角色"
    showToast(SpectateRedirect and "角色不动，摇杆飞视角" or "摇杆移动角色，视角独立")
end)
CamExit.MouseButton1Click:Connect(exitSpectate)

stopLoop = function()
    LoopRunning = false
    LoopGroupId = nil
    if LoopThread then
        pcall(function() task.cancel(LoopThread) end)
        LoopThread = nil
    end
    refreshG()
    updateQuickUI()
    updateMoveUI()
end

updateMoveUI = function()
    if not MoveBtn then return end
    MoveBtn.Text = MoveRunning and "■ 停止移动" or "🚀 快速移动"
    MoveBtn.BackgroundColor3 = MoveRunning and C_ORG or C_PURP
end

stopMove = function()
    MoveRunning = false
    MoveGroupId = nil
    if MoveThread then
        pcall(function() task.cancel(MoveThread) end)
        MoveThread = nil
    end
    updateMoveUI()
end

startMove = function()
    if MoveRunning then
        stopMove()
        showToast("■ 已停止快速移动")
        return
    end
    local g = QuickGroupId and findGroup(QuickGroupId) or nil
    if not g then
        showToast("⚠️ 请先在组合里选中一个组合")
        return
    end
    local pts = {}
    for _, cid in ipairs(g.coordIds or {}) do
        local c = findCoord(cid)
        if c then table.insert(pts, Vector3.new(c.x, c.y, c.z)) end
    end
    if #pts < 2 then
        showToast("⚠️ 组合内需要至少 2 个有效坐标")
        return
    end
    if LoopRunning then stopLoop() end
    MoveRunning = true
    MoveGroupId = g.id
    updateMoveUI()
    showToast("🚀 " .. Speed .. " studs/s · " .. #pts .. "个坐标循环")
    MoveThread = task.spawn(function()
        local n = #pts
        local idx = 1
        local cur = (Spectating and SpectateRedirect) and camPos or (getPos() or pts[1])
        local rot = CFrame.new()
        local ch0 = LP.Character
        local r0 = ch0 and (ch0:FindFirstChild("HumanoidRootPart") or ch0.PrimaryPart)
        if r0 then rot = r0.CFrame - r0.CFrame.Position end
        local hb = safe(function()
            return game:GetService("RunService").Heartbeat
        end)
        while MoveRunning do
            local dt = hb and hb:Wait() or task.wait(0.03)
            if not MoveRunning then break end
            dt = math.min(tonumber(dt) or 0.03, 0.1)
            local ch = LP.Character
            local toCam = Spectating and SpectateRedirect
            if not toCam and (not ch or not ch.PrimaryPart) then break end
            local target = pts[idx]
            local d = target - cur
            local dist = d.Magnitude
            local step = Speed * dt
            if dist <= step or dist < 0.05 then
                cur = target
                idx = idx % n + 1
            else
                cur = cur + d.Unit * step
            end
            if toCam then
                camPos = cur
            else
                pcall(function() ch:PivotTo(CFrame.new(cur) * rot) end)
            end
        end
        if MoveRunning then stopMove() end
    end)
end

startLoop = function(g)
    if LoopRunning then
        stopLoop()
        showToast("■ 已关闭循环传送")
        return
    end
    if MoveRunning then stopMove() end
    if not g or not g.coordIds or #g.coordIds == 0 then
        showToast("组合为空")
        return
    end
    LoopRunning = true
    LoopGroupId = g.id
    refreshG()
    updateQuickUI()
    showToast("循环传送: " .. tostring(g.name) .. " / 间隔 " .. Interval .. "s")
    LoopThread = task.spawn(function()
        local i = 1
        while LoopRunning do
            local ids = g.coordIds
            if not ids or #ids == 0 then break end
            i = ((i - 1) % #ids) + 1
            local c = findCoord(ids[i])
            if c then tel(c.x, c.y, c.z) end
            i = i + 1
            local waited = 0
            while waited < Interval and LoopRunning do
                local step = math.min(0.05, Interval - waited)
                task.wait(step)
                waited = waited + step
            end
        end
    end)
end

updateQuickUI = function()
    QToggle.Text = quickOn and "⚡" or "💤"
    QToggle.BackgroundColor3 = quickOn and C_ORG or C_BG3
    QGo.Visible = quickOn
    local g = QuickGroupId and findGroup(QuickGroupId) or nil
    if LoopRunning and LoopGroupId == QuickGroupId then
        QGo.Text = "■ 关闭循环"
    elseif g then
        QGo.Text = "⚡ " .. tostring(g.name)
    else
        QGo.Text = "⚡ 快捷传送"
    end
end

refreshC = function()
    for _, v in ipairs(CList:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    CCount.Text = "📍 所有坐标 (" .. #Coords .. ")"
    for _, c in ipairs(Coords) do
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, 62),
            BackgroundColor3 = Sel[c.id] and C_BG3 or C_BG2,
            ZIndex = 13,
            CornerRadius = 6,
            Parent = CList
        })
        local cb = button(row, Sel[c.id] and "√" or "□",
            UDim2.new(0, 28, 0, 28), UDim2.new(0, 6, 0, 4), Sel[c.id] and C_BLUE or C_BG, 16, 14)
        local one = button(row, "单选", UDim2.new(0, 44, 0, 28), UDim2.new(0, 38, 0, 4),
            Sel[c.id] and C_BLUE or C_BG3, 10, 14)
        label(row, tostring(c.name or "?"),
            UDim2.new(1, -94, 0, 28), UDim2.new(0, 88, 0, 4), C_TXT, 12, 14)
        label(row, "X" .. math.floor(c.x) .. " Y" .. math.floor(c.y) .. " Z" .. math.floor(c.z),
            UDim2.new(0, 140, 0, 26), UDim2.new(0, 8, 0, 32), C_TXT2, 10, 14)
        local tp = button(row, "传", UDim2.new(0, 34, 0, 26), UDim2.new(0, 148, 0, 32), C_BLUE, 11, 14)
        local rn = button(row, "改名", UDim2.new(0, 40, 0, 26), UDim2.new(0, 186, 0, 32), C_ORG, 10, 14)
        local dl = button(row, "删", UDim2.new(0, 28, 0, 26), UDim2.new(0, 230, 0, 32), C_RED, 11, 14)
        cb.MouseButton1Click:Connect(function()
            Sel[c.id] = not Sel[c.id]
            refreshC()
        end)
        one.MouseButton1Click:Connect(function()
            Sel = {}
            Sel[c.id] = true
            refreshC()
            showToast("单选: " .. tostring(c.name or "?"))
        end)
        tp.MouseButton1Click:Connect(function()
            if LoopRunning then stopLoop() end
            if MoveRunning then stopMove() end
            tel(c.x, c.y, c.z)
        end)
        rn.MouseButton1Click:Connect(function()
            local n = modalInput("✏️ 重命名坐标", tostring(c.name or ""))
            if n and n ~= "" then
                c.name = n
                saveAttr(K_COORDS, Coords)
                trySaveDS(K_COORDS, Coords)
                refreshC()
            end
        end)
        dl.MouseButton1Click:Connect(function()
            local ok = modalConfirm("删除坐标", "确认删除「" .. tostring(c.name or "") .. "」？\n组合内引用也会清理。", "删除")
            if not ok then return end
            for _, g in ipairs(Groups) do
                local keep = {}
                for _, cid in ipairs(g.coordIds or {}) do
                    if cid ~= c.id then table.insert(keep, cid) end
                end
                g.coordIds = keep
            end
            local nc = {}
            for _, cc in ipairs(Coords) do
                if cc.id ~= c.id then table.insert(nc, cc) end
            end
            Coords = nc
            Sel[c.id] = nil
            saveAttr(K_COORDS, Coords)
            saveAttr(K_GROUPS, Groups)
            trySaveDS(K_COORDS, Coords)
            trySaveDS(K_GROUPS, Groups)
            if MoveRunning then stopMove() end
            refreshC()
            refreshG()
            updateQuickUI()
        end)
    end
    local h = #Coords * 66
    CList.Size = UDim2.new(1, -20, 0, h)
    CPage.CanvasSize = UDim2.new(0, 0, 0, 84 + h + 12)
end

refreshG = function()
    for _, v in ipairs(GList:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    local sorted = {}
    for _, g in ipairs(Groups) do table.insert(sorted, g) end
    table.sort(sorted, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    for _, g in ipairs(sorted) do
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = (QuickGroupId == g.id) and C_BG3 or C_BG2,
            ZIndex = 13,
            CornerRadius = 6,
            Parent = GList
        })
        local running = LoopRunning and LoopGroupId == g.id
        label(row, tostring(g.name or "?") .. " (" .. #(g.coordIds or {}) .. "个)" ..
            ((QuickGroupId == g.id) and " ⚡已选" or ""),
            UDim2.new(0, 120, 1, 0), UDim2.new(0, 8, 0, 0),
            (QuickGroupId == g.id) and C_ORG or C_TXT, 11, 14)
        local pb = button(row, running and "关" or "开",
            UDim2.new(0, 34, 0, 28), UDim2.new(0.48, 0, 0, 9),
            running and C_ORG or C_BLUE, 11, 14)
        local sb = button(row, (QuickGroupId == g.id) and "✓" or "选",
            UDim2.new(0, 30, 0, 28), UDim2.new(0.63, 0, 0, 9),
            (QuickGroupId == g.id) and C_GREEN or C_BG3, 11, 14)
        local db = button(row, "删", UDim2.new(0, 30, 0, 28), UDim2.new(0.88, 0, 0, 9), C_RED, 11, 14)
        pb.MouseButton1Click:Connect(function() startLoop(g) end)
        sb.MouseButton1Click:Connect(function()
            QuickGroupId = (QuickGroupId == g.id) and nil or g.id
            safe(function() LP:SetAttribute(K_QUICK, QuickGroupId or "") end)
            refreshG()
            updateQuickUI()
        end)
        db.MouseButton1Click:Connect(function()
            local ok = modalConfirm("删除组合", "确认删除「" .. tostring(g.name or "") .. "」？", "删除")
            if not ok then return end
            local ng = {}
            for _, gg in ipairs(Groups) do
                if gg.id ~= g.id then table.insert(ng, gg) end
            end
            Groups = ng
            if QuickGroupId == g.id then QuickGroupId = nil end
            if LoopGroupId == g.id then stopLoop() end
            if MoveGroupId == g.id then stopMove() end
            safe(function() LP:SetAttribute(K_QUICK, QuickGroupId or "") end)
            saveAttr(K_GROUPS, Groups)
            trySaveDS(K_GROUPS, Groups)
            refreshG()
            updateQuickUI()
        end)
    end
    local h = #sorted * 50
    GList.Size = UDim2.new(1, -20, 0, h)
    GPage.CanvasSize = UDim2.new(0, 0, 0, 126 + h + 12)
end

openManage = function()
    local ov = newOverlay()
    local z = ov.ZIndex
    local win = make("Frame", {
        Size = UDim2.new(0, 276, 0, 340),
        Position = UDim2.new(0.5, -138, 0.5, -170),
        BackgroundColor3 = C_BG2,
        ZIndex = z + 1,
        CornerRadius = 10,
        Parent = ov
    })
    rainbowBorder(win, 2, 12, false)
    label(win, "📁 管理组合", UDim2.new(1, -48, 0, 28), UDim2.new(0, 12, 0, 8), C_WHITE, 15, z + 2)
    local closeBtn = button(win, "X", UDim2.new(0, 30, 0, 28), UDim2.new(1, -38, 0, 8), C_RED, 14, z + 2)
    label(win, "间隔(秒)", UDim2.new(0, 80, 0, 26), UDim2.new(0, 12, 0, 40), C_TXT2, 12, z + 2)
    label(win, "长按坐标拖动排序", UDim2.new(0, 110, 0, 26), UDim2.new(0, 166, 0, 40), C_ORG, 10, z + 2)
    local intBox = make("TextBox", {
        Text = tostring(Interval),
        Size = UDim2.new(0, 70, 0, 26),
        Position = UDim2.new(0, 96, 0, 40),
        BackgroundColor3 = C_BG3,
        TextColor3 = C_WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = z + 2,
        Parent = win
    })
    intBox.FocusLost:Connect(function()
        local n = tonumber(intBox.Text)
        if n and n >= 0.1 then
            Interval = n
            safe(function() LP:SetAttribute(K_INTERV, Interval) end)
        else
            intBox.Text = tostring(Interval)
        end
    end)
    local scroll = make("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -84),
        Position = UDim2.new(0, 8, 0, 74),
        BackgroundColor3 = C_BG,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = z + 2,
        Parent = win
    })

    local connA, connB, connC, rebuild
    local STRIDE = 34
    local press, drag, ghost = nil, nil, nil
    local groupRows = {}
    local closed = false
    local function close()
        if closed then return end
        closed = true
        for _, c in ipairs({connA, connB, connC}) do
            if c then safe(function() c:Disconnect() end) end
        end
        if ghost then safe(function() ghost:Destroy() end) ghost = nil end
        scroll.ScrollingEnabled = true
        press, drag = nil, nil
        closeOverlay(ov)
    end
    closeBtn.MouseButton1Click:Connect(close)
    connC = UIS.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.Escape and ov.ZIndex == modalDepth then close() end
    end)

    local function endDrag(commit)
        if ghost then safe(function() ghost:Destroy() end) ghost = nil end
        scroll.ScrollingEnabled = true
        if drag and commit then
            local d = drag
            local ids = d.g.coordIds
            if d.from ~= d.to and d.from >= 1 and d.from <= #ids then
                local id = table.remove(ids, d.from)
                local to = math.clamp(d.to, 1, #ids + 1)
                table.insert(ids, to, id)
                saveAttr(K_GROUPS, Groups)
                trySaveDS(K_GROUPS, Groups)
                refreshG()
                showToast("顺序 " .. d.from .. " -> " .. to)
            end
        end
        drag = nil
        press = nil
        rebuild()
    end

    local function enterDrag(p)
        press = nil
        local info = groupRows[p.g.id]
        if not info then return end
        scroll.ScrollingEnabled = false
        local c = findCoord(p.g.coordIds[p.idx])
        ghost = make("Frame", {
            Size = UDim2.new(0, 244, 0, 32),
            Position = UDim2.new(0, p.sx - 24, 0, p.sy - 16),
            BackgroundColor3 = C_ORG,
            ZIndex = 950,
            CornerRadius = 8,
            Parent = Gui
        })
        label(ghost, tostring(p.idx) .. "  " .. (c and tostring(c.name or "?") or "已删除"),
            UDim2.new(1, -12, 1, 0), UDim2.new(0, 10, 0, 0), C_WHITE, 12, 951)
        drag = {g = p.g, from = p.idx, to = p.idx, info = info}
        local r = info.rows[p.idx]
        if r then r.BackgroundTransparency = 0.65 end
        showToast("拖到目标位置后松手")
    end

    connA = UIS.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and
            i.UserInputType ~= Enum.UserInputType.Touch then return end
        if press and not drag then
            if math.abs(i.Position.X - press.sx) > 10 or
                math.abs(i.Position.Y - press.sy) > 10 then
                press = nil
            end
            return
        end
        if not drag then return end
        if ghost then
            ghost.Position = UDim2.new(0, i.Position.X - 24, 0, i.Position.Y - 16)
        end
        local d = drag
        local canvasY = i.Position.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
        local n = #d.info.rows
        if n == 0 then return end
        local to = math.clamp(math.floor((canvasY - d.info.yStart) / STRIDE) + 1, 1, n)
        d.to = to
        for idx2, r in ipairs(d.info.rows) do
            local disp = idx2
            if idx2 == d.from then
                disp = to
            elseif d.from < to and idx2 > d.from and idx2 <= to then
                disp = idx2 - 1
            elseif d.from > to and idx2 >= to and idx2 < d.from then
                disp = idx2 + 1
            end
            r.Position = UDim2.new(0, 4, 0, d.info.yStart + (disp - 1) * STRIDE)
            r.BackgroundColor3 = (idx2 == d.from) and C_ORG or C_BG2
        end
    end)
    connB = UIS.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and
            i.UserInputType ~= Enum.UserInputType.Touch then return end
        if drag then
            endDrag(true)
        elseif press then
            press = nil
            scroll.ScrollingEnabled = true
        end
    end)

    rebuild = function()
        for _, v in ipairs(scroll:GetChildren()) do
            if v:IsA("GuiObject") then v:Destroy() end
        end
        local sorted = {}
        for _, g in ipairs(Groups) do table.insert(sorted, g) end
        table.sort(sorted, function(a, b)
            return tostring(a.name or "") < tostring(b.name or "")
        end)
        local y = 6
        for _, g in ipairs(sorted) do
            local hdr = make("Frame", {
                Size = UDim2.new(1, -8, 0, 32),
                Position = UDim2.new(0, 4, 0, y),
                BackgroundColor3 = C_BG3,
                ZIndex = z + 3,
                Parent = scroll
            })
            label(hdr, tostring(g.name or "?") .. " (" .. #(g.coordIds or {}) .. ")" ..
                ((QuickGroupId == g.id) and " ⚡已选" or ""),
                UDim2.new(0, 110, 1, 0), UDim2.new(0, 8, 0, 0), C_TXT, 11, z + 4)
            local running = LoopRunning and LoopGroupId == g.id
            local pb = button(hdr, running and "关" or "传送",
                UDim2.new(0, 40, 0, 26), UDim2.new(0.44, 0, 0, 3),
                running and C_ORG or C_BLUE, 10, z + 4)
            local sb = button(hdr, (QuickGroupId == g.id) and "✓" or "选",
                UDim2.new(0, 30, 0, 26), UDim2.new(0.64, 0, 0, 3),
                (QuickGroupId == g.id) and C_GREEN or C_BG2, 10, z + 4)
            local db = button(hdr, "删",
                UDim2.new(0, 30, 0, 26), UDim2.new(0.86, 0, 0, 3), C_RED, 10, z + 4)
            pb.MouseButton1Click:Connect(function() startLoop(g) end)
            sb.MouseButton1Click:Connect(function()
                QuickGroupId = g.id
                safe(function() LP:SetAttribute(K_QUICK, QuickGroupId) end)
                rebuild()
                refreshG()
                updateQuickUI()
            end)
            local armed = false
            db.MouseButton1Click:Connect(function()
                if not armed then
                    armed = true
                    db.Text = "确认?"
                    task.delay(3, function()
                        if db and db.Parent then armed = false db.Text = "删" end
                    end)
                    return
                end
                local ng = {}
                for _, gg in ipairs(Groups) do
                    if gg.id ~= g.id then table.insert(ng, gg) end
                end
                Groups = ng
                if QuickGroupId == g.id then QuickGroupId = nil end
                if LoopGroupId == g.id then stopLoop() end
            if MoveGroupId == g.id then stopMove() end
                safe(function() LP:SetAttribute(K_QUICK, QuickGroupId or "") end)
                saveAttr(K_GROUPS, Groups)
                trySaveDS(K_GROUPS, Groups)
                rebuild()
                refreshG()
                updateQuickUI()
                showToast("已删除组合")
            end)
            y = y + 36
            local info = {rows = {}, yStart = y}
            groupRows[g.id] = info
            for idx, cid in ipairs(g.coordIds or {}) do
                local c = findCoord(cid)
                local row = make("Frame", {
                    Size = UDim2.new(1, -8, 0, 30),
                    Position = UDim2.new(0, 4, 0, y),
                    BackgroundColor3 = C_BG2,
                    Active = true,
                    ZIndex = z + 3,
                    Parent = scroll
                })
                make("TextLabel", {
                    Text = tostring(idx),
                    Size = UDim2.new(0, 22, 0, 22),
                    Position = UDim2.new(0, 6, 0, 4),
                    BackgroundColor3 = C_BG3,
                    TextColor3 = C_ORG,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = z + 4,
                    Parent = row
                })
                local txt = (c and tostring(c.name or "?") or "已删除")
                if c then
                    txt = txt .. "   " .. math.floor(c.x) .. "," .. math.floor(c.y) .. "," .. math.floor(c.z)
                end
                label(row, txt, UDim2.new(1, -36, 1, 0), UDim2.new(0, 34, 0, 0),
                    c and C_TXT2 or C_RED, 10, z + 4)
                table.insert(info.rows, row)
                row.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or
                        input.UserInputType == Enum.UserInputType.Touch then
                        local p = {g = g, idx = idx, sx = input.Position.X, sy = input.Position.Y}
                        press = p
                        task.delay(0.32, function()
                            if press == p and not drag then enterDrag(p) end
                        end)
                    end
                end)
                y = y + STRIDE
            end
            y = y + 8
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end
    rebuild()
end

switchTab = function(n)
    currentTab = n
    CPage.Visible = (n == 1)
    GPage.Visible = (n == 2)
    SPage.Visible = (n == 3)
    TabC.BackgroundColor3 = (n == 1) and C_BLUE or C_BG3
    TabG.BackgroundColor3 = (n == 2) and C_BLUE or C_BG3
    TabS.BackgroundColor3 = (n == 3) and C_BLUE or C_BG3
end

applyLayout = function()
    local w, h = 280, minimized and 34 or 380
    Main.Size = UDim2.new(0, w, 0, h)
    Glow.Size = UDim2.new(0, w + 4, 0, h + 4)
    MinB.Text = minimized and "+" or "—"
    Tabs.Visible = not minimized
    QPanel.Visible = not minimized
    switchTab(currentTab)
    if minimized then
        CPage.Visible = false
        GPage.Visible = false
        SPage.Visible = false
    end
end

makeDrag = function(frame, handle, boundsFrame, movedRef, border, pad)
    local dragging = false
    local startInput = nil
    local startAbs = nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
            i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = i.Position
            startAbs = frame.AbsolutePosition
            if movedRef then movedRef.moved = false end
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and
            i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - startInput
        if movedRef and (math.abs(d.X) > 6 or math.abs(d.Y) > 6) then
            movedRef.moved = true
        end
        local maxX, maxY
        if boundsFrame then
            maxX = boundsFrame.AbsoluteSize.X - frame.AbsoluteSize.X
            maxY = boundsFrame.AbsoluteSize.Y - frame.AbsoluteSize.Y
        else
            local vp = viewport()
            maxX = vp.X - frame.AbsoluteSize.X
            maxY = vp.Y - frame.AbsoluteSize.Y
        end
        local nx = math.clamp(startAbs.X + d.X, 0, math.max(0, maxX))
        local ny = math.clamp(startAbs.Y + d.Y, 0, math.max(0, maxY))
        frame.Position = UDim2.new(0, nx, 0, ny)
        if border then
            local p = pad or 2
            border.Position = UDim2.new(0, nx - p, 0, ny - p)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
            i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

SaveB.MouseButton1Click:Connect(function()
    local p = getPos()
    if not p then showToast("角色未就绪") return end
    local def = string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
    local n = modalInput("💾 给坐标起个名字", def)
    if not n or n == "" then return end
    table.insert(Coords, {id = newId("c_"), name = n, x = p.X, y = p.Y, z = p.Z})
    saveAttr(K_COORDS, Coords)
    trySaveDS(K_COORDS, Coords)
    refreshC()
    if Spectating then
        showToast("已保存角色本体位置（非视角）")
    else
        showToast("✅ 已保存")
    end
end)

AllB.MouseButton1Click:Connect(function()
    local all = true
    for _, c in ipairs(Coords) do
        if not Sel[c.id] then all = false break end
    end
    for _, c in ipairs(Coords) do Sel[c.id] = not all end
    refreshC()
end)

CrGB.MouseButton1Click:Connect(function()
    local ids = {}
    for _, c in ipairs(Coords) do
        if Sel[c.id] then table.insert(ids, c.id) end
    end
    if #ids < 2 then showToast("⚠️ 请至少勾选 2 个坐标") return end
    local n = modalInput("➕ 组合名称", "组合 " .. tostring(#Groups + 1))
    if not n or n == "" then return end
    table.insert(Groups, {id = newId("g_"), name = n, coordIds = ids})
    Sel = {}
    saveAttr(K_GROUPS, Groups)
    trySaveDS(K_GROUPS, Groups)
    refreshC()
    refreshG()
    showToast("✅ 已创建组合")
end)

MngB.MouseButton1Click:Connect(function() openManage() end)

MoveBtn.MouseButton1Click:Connect(function() startMove() end)
SpeedBox.FocusLost:Connect(function()
    local n = tonumber(SpeedBox.Text)
    if n and n == n and n > 0 and n < math.huge then
        Speed = n
        safe(function() LP:SetAttribute(K_SPEED, Speed) end)
        showToast("速度 " .. tostring(Speed) .. " studs/s")
    else
        SpeedBox.Text = tostring(Speed)
        showToast("速度需填大于 0 的数字")
    end
end)

LoadB.MouseButton1Click:Connect(function()
    local c = tryLoadDS(K_COORDS)
    local g = tryLoadDS(K_GROUPS)
    if type(c) == "table" then Coords = c end
    if type(g) == "table" then Groups = g end
    if type(c) == "table" or type(g) == "table" then
        saveAttr(K_COORDS, Coords)
        saveAttr(K_GROUPS, Groups)
        refreshC()
        refreshG()
        updateQuickUI()
        showToast("✅ 已从 DataStore 加载")
    else
        showToast("云端无数据或不可用")
    end
end)

SavB.MouseButton1Click:Connect(function()
    trySaveDS(K_COORDS, Coords)
    trySaveDS(K_GROUPS, Groups)
    showToast("💾 已尝试保存（失败则忽略）")
end)

JsnB.MouseButton1Click:Connect(function()
    local j = safe(function()
        return HttpService:JSONEncode({
            coords = Coords, groups = Groups,
            quick = QuickGroupId, interval = Interval, speed = Speed
        })
    end)
    ExpB.Text = j or "导出失败"
    showToast("已导出，可长按复制")
end)

ClrB.MouseButton1Click:Connect(function()
    local a = modalConfirm("⚠️ 清空数据", "将删除所有坐标与组合，确定？", "下一步")
    if not a then return end
    local b = modalConfirm("再次确认", "真的要清空吗？此操作不可撤销。", "清空")
    if not b then return end
    if LoopRunning then stopLoop() end
    if MoveRunning then stopMove() end
    Coords = {}
    Groups = {}
    QuickGroupId = nil
    Sel = {}
    saveAttr(K_COORDS, Coords)
    saveAttr(K_GROUPS, Groups)
    safe(function() LP:SetAttribute(K_QUICK, "") end)
    trySaveDS(K_COORDS, Coords)
    trySaveDS(K_GROUPS, Groups)
    ExpB.Text = ""
    refreshC()
    refreshG()
    updateQuickUI()
    showToast("🗑 已清空全部数据")
end)

TabC.MouseButton1Click:Connect(function() switchTab(1) end)
TabG.MouseButton1Click:Connect(function() switchTab(2) end)
TabS.MouseButton1Click:Connect(function() switchTab(3) end)

MinB.MouseButton1Click:Connect(function()
    minimized = not minimized
    applyLayout()
end)

CloseB.MouseButton1Click:Connect(function()
    Main.Visible = false
    Glow.Visible = false
    FloatB.Visible = true
    FloatGlow.Visible = true
end)

QuitB.MouseButton1Click:Connect(function()
    local ok = modalConfirm("关闭脚本", "彻底关闭 TC坐标传送？\n会恢复角色视角，数据保留。", "关闭")
    if not ok then return end
    if LoopRunning then stopLoop() end
    if MoveRunning then stopMove() end
    if Spectating then exitSpectate() end
    if spinTween then safe(function() spinTween:Cancel() end) end
    safe(function() Gui:Destroy() end)
end)

local floatMoved = {moved = false}
FloatB.MouseButton1Click:Connect(function()
    if floatMoved.moved then
        floatMoved.moved = false
        return
    end
    Main.Visible = true
    Glow.Visible = true
    FloatB.Visible = false
    FloatGlow.Visible = false
end)

makeDrag(Main, Title, nil, nil, Glow, 2)
makeDrag(Main, TitleLbl, nil, nil, Glow, 2)
makeDrag(FloatB, FloatB, nil, floatMoved, FloatGlow, 1)
makeDrag(CamPanel, CamHdr)

local qDrag, qStart, qStartPos, qMoved = false, nil, nil, false
QToggle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or
        i.UserInputType == Enum.UserInputType.Touch then
        qDrag = true
        qMoved = false
        qStart = i.Position
        qStartPos = QPanel.AbsolutePosition - Main.AbsolutePosition
    end
end)
UIS.InputChanged:Connect(function(i)
    if not qDrag then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMovement and
        i.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = i.Position - qStart
    if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then qMoved = true end
    if not qMoved then return end
    local maxX = Main.AbsoluteSize.X - QPanel.AbsoluteSize.X
    local maxY = Main.AbsoluteSize.Y - QPanel.AbsoluteSize.Y
    QPanel.Position = UDim2.new(0,
        math.clamp(qStartPos.X + d.X, 0, math.max(0, maxX)), 0,
        math.clamp(qStartPos.Y + d.Y, 0, math.max(0, maxY)))
end)
UIS.InputEnded:Connect(function()
    qDrag = false
end)

QToggle.MouseButton1Click:Connect(function()
    if qMoved then qMoved = false return end
    if not quickOn then
        local g = QuickGroupId and findGroup(QuickGroupId) or nil
        if not g or #(g.coordIds or {}) == 0 then
            showToast("⚠️ 请先在组合里选中一个组合")
            return
        end
    end
    quickOn = not quickOn
    updateQuickUI()
end)

QGo.MouseButton1Click:Connect(function()
    local g = QuickGroupId and findGroup(QuickGroupId) or nil
    if not g then showToast("⚠️ 请先选中一个组合") return end
    startLoop(g)
end)

LP.CharacterAdded:Connect(function()
    if LoopRunning then stopLoop() end
    if MoveRunning then stopMove() end
end)

local c = loadAttr(K_COORDS)
if type(c) == "table" then Coords = c end
local g = loadAttr(K_GROUPS)
if type(g) == "table" then Groups = g end
local q = safe(function() return LP:GetAttribute(K_QUICK) end)
if type(q) == "string" and q ~= "" then QuickGroupId = q end
local iv = safe(function() return LP:GetAttribute(K_INTERV) end)
if type(iv) == "number" and iv >= 0.1 then Interval = iv end
local sp = safe(function() return LP:GetAttribute(K_SPEED) end)
if type(sp) == "number" and sp == sp and sp > 0 and sp < math.huge then Speed = sp end
SpeedBox.Text = tostring(Speed)

refreshC()
refreshG()
switchTab(1)
applyLayout()
updateQuickUI()
updateMoveUI()
showToast("TC坐标传送 已加载")
