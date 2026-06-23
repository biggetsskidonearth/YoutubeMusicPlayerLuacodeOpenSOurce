--[[
This script was made for an suggestion to hopefully get this into the popular admin script called Novoline
join theyre server please https://discord.gg/b7gpJTJ9pE or discord.gg/novo-line theyre website is https://novoline.pro
made possible with me @thedude_whotalks on discord and with railway.com for the server to always stay online
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local WS_URL = "wss://youtube-music-player-robloxexpl-production.up.railway.app"

local Socket = nil
local WSConnected = false
local hue = 0

-- Gradient Color Generator
local function getGradientColor(h, s, v)
    return Color3.fromHSV(h % 1, s or 0.8, v or 1)
end

local Theme = {
    BgDark = Color3.fromRGB(8, 8, 10), 
    BgMain = Color3.fromRGB(14, 14, 18),
    BgSurface = Color3.fromRGB(20, 20, 26), 
    BgHover = Color3.fromRGB(30, 30, 38),
    TextMain = Color3.fromRGB(240, 240, 245),
    TextSub = Color3.fromRGB(140, 140, 155), 
    TextMuted = Color3.fromRGB(60, 60, 70),
    Error = Color3.fromRGB(255, 50, 50)
}

local State = {
    isPlaying = false, isPaused = false, title = "", artist = "", 
    duration = 0, currentTime = 0, volume = 0.5, queue = {}, 
    currentIndex = -1, isSearching = false
}

local function new(c, p, par)
    local i = Instance.new(c)
    for k,v in pairs(p or {}) do if k~="Parent" then i[k]=v end end
    if par then i.Parent=par end
    return i
end
local function addCorner(i, r) return new("UICorner",{CornerRadius=UDim.new(0,r or 8)},i) end
local function tw(i, p, d) TweenService:Create(i, TweenInfo.new(d or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end
local function fmt(s)
    if not s or s<=0 then return "0:00" end
    s=math.floor(s)
    return string.format("%d:%02d", math.floor(s/60), s%60)
end

-- Main GUI
local ScreenGui = new("ScreenGui", {Name="NovoYT", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999}, PlayerGui)
local MainFrame = new("Frame", {Size=UDim2.new(0,480,0,620), Position=UDim2.new(0.5,-240,0.5,-310), BackgroundColor3=Theme.BgMain, BorderSizePixel=0, ClipsDescendants=true}, ScreenGui)
addCorner(MainFrame, 16)

-- Animated Gradient Top Bar
local StatusBar = new("Frame", {Size=UDim2.new(1, 0, 0, 4), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, MainFrame)

-- Subtle Glow Frame behind UI
local GlowFrame = new("ImageLabel", {
    Size = UDim2.new(1, 40, 1, 40), 
    Position = UDim2.new(0, -20, 0, -20),
    BackgroundTransparency = 1,
    Image = "rbxassetid://7669168585",
    ImageColor3 = Color3.new(1,1,1),
    ImageTransparency = 0.85,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(100, 100, 300, 300),
    ZIndex = -1
}, ScreenGui)
addCorner(GlowFrame, 24)

-- Header
local Header = new("Frame", {Size=UDim2.new(1,0,0,60), BackgroundColor3=Theme.BgMain, BorderSizePixel=0}, MainFrame)
local Dot = new("TextLabel", {Text="", Size=UDim2.new(0,12,0,12), Position=UDim2.new(0,20,0,24), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, Header)
addCorner(Dot, 6)
new("TextLabel", {Text="NOVO", Size=UDim2.new(0,60,0,20), Position=UDim2.new(0,38,0,20), BackgroundTransparency=1, TextColor3=Theme.TextMain, TextSize=18, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, Header)
local WsStatus = new("TextLabel", {Text="", Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,100,0,28), BackgroundColor3=Theme.Error, BorderSizePixel=0}, Header)
addCorner(WsStatus, 4)

local ReconnectBtn = new("TextButton", {Text="", Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-40,0,15), BackgroundColor3=Theme.BgSurface, BorderSizePixel=0}, Header)
addCorner(ReconnectBtn, 8)
new("TextLabel", {Text="↻", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=Theme.TextMuted, TextSize=16, Font=Enum.Font.GothamBold}, ReconnectBtn)
ReconnectBtn.MouseButton1Click:Connect(function() if not WSConnected then ConnectWS() end end)

local CloseBtn = new("TextButton", {Text="", Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-76,0,15), BackgroundColor3=Theme.BgSurface, BorderSizePixel=0}, Header)
addCorner(CloseBtn, 8)
new("TextLabel", {Text="×", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=Theme.TextMuted, TextSize=16, Font=Enum.Font.GothamBold}, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function() tw(MainFrame, {Size=UDim2.new(0,480,0,0)}, 0.3) delay(0.3, function() ScreenGui:Destroy() end) end)

-- Drag
local drag={a=false,i=nil,s=Vector3.new(0,0,0),p=UDim2.new()}
Header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag.a=true drag.i=i drag.s=i.Position drag.p=MainFrame.Position end end)
Header.InputEnded:Connect(function(i) if i==drag.i then drag.a=false end end)
UserInputService.InputChanged:Connect(function(i) if drag.a and i.UserInputType==Enum.UserInputType.MouseMovement then MainFrame.Position=UDim2.new(drag.p.X.Scale,drag.p.X.Offset+(i.Position-drag.s).X,drag.p.Y.Scale,drag.p.Y.Offset+(i.Position-drag.s).Y) GlowFrame.Position = UDim2.new(0, MainFrame.Position.X.Offset - 20, 0, MainFrame.Position.Y.Offset - 20) end end)

-- Search
local SearchPanel = new("Frame", {Size=UDim2.new(1,-40,0,40), Position=UDim2.new(0,20,0,72), BackgroundColor3=Theme.BgSurface, BorderSizePixel=0}, MainFrame)
addCorner(SearchPanel, 10)
local SearchBox = new("TextBox", {PlaceholderText="", Text="", Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, TextColor3=Theme.TextMain, PlaceholderColor3=Theme.TextMuted, TextSize=14, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false}, SearchPanel)
local SearchBtn = new("TextButton", {Text="→", Size=UDim2.new(0,36,0,28), Position=UDim2.new(1,-40,0.5,-14), BackgroundColor3=Color3.new(1,1,1), TextColor3=Theme.BgDark, TextSize=16, Font=Enum.Font.GothamBold, BorderSizePixel=0}, SearchPanel)
addCorner(SearchBtn, 8)

-- Results
local ResultsScroll = new("ScrollingFrame", {Size=UDim2.new(1,-40,0,284), Position=UDim2.new(0,20,0,120), BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=Theme.BgHover, BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y}, MainFrame)
new("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)}, ResultsScroll)

-- Now Playing
local NPPanel = new("Frame", {Size=UDim2.new(1,0,0,200), Position=UDim2.new(0,0,1,-200), BackgroundColor3=Theme.BgDark, BorderSizePixel=0}, MainFrame)

local ProgressBack = new("Frame", {Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,0), BackgroundColor3=Theme.BgSurface, BorderSizePixel=0}, NPPanel)
local ProgressFill = new("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, ProgressBack)

local TimeL = new("TextLabel", {Text="0:00", Size=UDim2.new(0,36,0,14), Position=UDim2.new(0,20,0,10), BackgroundTransparency=1, TextColor3=Theme.TextMuted, TextSize=10, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left}, NPPanel)
local TimeR = new("TextLabel", {Text="0:00", Size=UDim2.new(0,36,0,14), Position=UDim2.new(1,-56,0,10), BackgroundTransparency=1, TextColor3=Theme.TextMuted, TextSize=10, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Right}, NPPanel)

local TrackTitle = new("TextLabel", {Text="", Size=UDim2.new(0.6,0,0,22), Position=UDim2.new(0,20,0,28), BackgroundTransparency=1, TextColor3=Theme.TextMain, TextSize=15, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, NPPanel)
local TrackArtist = new("TextLabel", {Text="", Size=UDim2.new(0.6,0,0,14), Position=UDim2.new(0,20,0,50), BackgroundTransparency=1, TextColor3=Theme.TextSub, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, NPPanel)

-- Controls
local Controls = new("Frame", {Size=UDim2.new(1,0,0,50), Position=UDim2.new(0,0,1,-80), BackgroundTransparency=1}, NPPanel)
local function makeCtrl(t, x, s, cb)
    local b=new("TextButton",{Text=t,Size=UDim2.new(0,s or 40,0,40),Position=UDim2.new(0.5,x,0.5,-20),BackgroundTransparency=1,TextColor3=Theme.TextSub,TextSize=(s or 40)>40 and 14 or 20,Font=Enum.Font.GothamBold},Controls)
    b.MouseEnter:Connect(function() tw(b,{TextColor3=Theme.TextMain}) end)
    b.MouseLeave:Connect(function() tw(b,{TextColor3=Theme.TextSub}) end)
    b.MouseButton1Click:Connect(cb)
    return b
end
makeCtrl("⏮",-90,36,function() wsSend({action="prev"}) end)
local BtnPlay = makeCtrl("▶",-46,44,function() if State.isPlaying then wsSend({action="pause"}) else wsSend({action="resume"}) end end)
makeCtrl("⏭",-4,36,function() wsSend({action="next"}) end)
makeCtrl("⏹",38,36,function() wsSend({action="clear_queue"}) end)

-- Volume
local VolCont = new("Frame", {Size=UDim2.new(0,100,0,40), Position=UDim2.new(1,-120,1,-80), BackgroundTransparency=1}, NPPanel)
local VolIcon = new("TextLabel", {Text="🔊", Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,0,0.5,-10), BackgroundTransparency=1, TextSize=14}, VolCont)
local VolBg = new("Frame", {Size=UDim2.new(0,70,0,4), Position=UDim2.new(0,26,0.5,-2), BackgroundColor3=Theme.BgSurface, BorderSizePixel=0}, VolCont)
local VolFill = new("Frame", {Size=UDim2.new(State.volume,0,1,0), BackgroundColor3=Theme.TextSub, BorderSizePixel=0}, VolBg)
local volDrag = false
VolBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then volDrag=true updateVol(i) end end)
VolBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then volDrag=false end end)
UserInputService.InputChanged:Connect(function(i) if volDrag and i.UserInputType==Enum.UserInputType.MouseMovement then updateVol(i) end end)
function updateVol(i)
    local r=math.clamp((i.Position.X-VolBg.AbsolutePosition.X)/VolBg.AbsoluteSize.X,0,1)
    State.volume=r VolFill.Size=UDim2.new(r,0,1,0)
    VolIcon.Text=r==0 and "🔇" or (r<0.5 and "🔉" or "🔊")
    wsSend({action="volume",data={volume=r}})
end

-- Seek
local seekDrag = false
ProgressBack.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then seekDrag=true doSeek(i) end end)
ProgressBack.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then seekDrag=false end end)
function doSeek(i)
    local r=math.clamp((i.Position.X-ProgressBack.AbsolutePosition.X)/ProgressBack.AbsoluteSize.X,0,1)
    ProgressFill.Size=UDim2.new(r,0,1,0)
    wsSend({action="seek",data={time=r*State.duration}})
end

-- Core WS Logic
function wsSend(data)
    if not WSConnected or not Socket then return false end
    local success = pcall(function() Socket:Send(HttpService:JSONEncode(data)) end)
    if not success then WSConnected = false UpdateUIOffline() end
    return success
end

function UpdateUIOffline()
    WSConnected = false
    WsStatus.BackgroundColor3 = Theme.Error
end

function ConnectWS()
    if WSConnected then return end
    local success = pcall(function()
        Socket = WebSocket.connect(WS_URL)
        WSConnected = true
        WsStatus.BackgroundColor3 = getGradientColor(hue, 0.8, 1)
        
        spawn(function()
            while WSConnected do
                local recvOk, msg = pcall(function() return Socket:Receive() end)
                if not recvOk or not msg then UpdateUIOffline() break end
                
                local decodeOk, data = pcall(function() return HttpService:JSONDecode(msg) end)
                if decodeOk and data then
                    if data.type == "sync" then
                        local d = data.data
                        State.isPlaying = d.is_playing State.isPaused = d.is_paused
                        State.title = d.title or "" State.artist = d.artist or ""
                        State.duration = d.duration or 0 State.currentTime = d.current_time or 0
                        State.queue = d.queue or {} State.currentIndex = d.current_index or -1
                        
                        TrackTitle.Text = State.title TrackArtist.Text = State.artist
                        BtnPlay.Text = State.isPlaying and "⏸" or "▶"
                        TimeR.Text = fmt(State.duration) TimeL.Text = fmt(State.currentTime)
                        
                        if State.duration > 0 and not seekDrag then
                            ProgressFill.Size = UDim2.new(math.clamp(State.currentTime / State.duration, 0, 1), 0, 1, 0)
                        end
                    elseif data.type == "event" then
                        if data.event == "loading" then TrackTitle.Text = data.data.title or "" TrackArtist.Text = "" BtnPlay.Text = "⏳"
                        elseif data.event == "ended" then BtnPlay.Text = "▶"
                        end
                    elseif data.type == "search_results" then
                        populateResults(data.data) State.isSearching = false
                    end
                end
            end
        end)
    end)
    if not success then UpdateUIOffline() end
end

-- Results UI
local resultBtns = {}
function populateResults(results)
    for _, b in ipairs(resultBtns) do if b.Parent then b:Destroy() end end
    resultBtns = {}
    if not results or #results == 0 then return end
    for i, item in ipairs(results) do
        local btn = new("TextButton", {Size=UDim2.new(1,0,0,60), BackgroundColor3=Theme.BgSurface, Text="", AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=i}, ResultsScroll)
        addCorner(btn, 10)
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3=Theme.BgHover}) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3=Theme.BgSurface}) end)
        
        local thumb = new("Frame", {Size=UDim2.new(0,44,0,44), Position=UDim2.new(0,8,0.5,-22), BackgroundColor3=Theme.BgHover, BorderSizePixel=0}, btn)
        addCorner(thumb, 8)
        new("TextLabel", {Text="♪", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=Theme.TextMuted, TextSize=18, Font=Enum.Font.GothamBold}, thumb)
        
        if item.duration and item.duration > 0 then
            local badge = new("Frame", {Size=UDim2.new(0,30,0,14), Position=UDim2.new(0,14,1,-16), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.4, BorderSizePixel=0}, thumb)
            addCorner(badge, 3)
            new("TextLabel", {Text=fmt(item.duration), Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextSize=8, Font=Enum.Font.GothamBold}, badge)
        end
        
        new("TextLabel", {Text=item.title or "", Size=UDim2.new(1,-68,0,24), Position=UDim2.new(0,60,0,8), BackgroundTransparency=1, TextColor3=Theme.TextMain, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
        new("TextLabel", {Text=item.artist or "", Size=UDim2.new(1,-68,0,16), Position=UDim2.new(0,60,0,34), BackgroundTransparency=1, TextColor3=Theme.TextSub, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
        
        btn.MouseButton1Click:Connect(function() wsSend({action="play", data={id=item.id, title=item.title, artist=item.artist, duration=item.duration}}) end)
        table.insert(resultBtns, btn)
    end
end

local function doSearch()
    local q = SearchBox.Text
    if #q == 0 or State.isSearching or not WSConnected then return end
    State.isSearching = true
    for _, b in ipairs(resultBtns) do if b.Parent then b:Destroy() end end
    resultBtns = {}
    wsSend({action="search", data={query=q}})
end

SearchBtn.MouseButton1Click:Connect(doSearch)
SearchBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode==Enum.KeyCode.RightControl then ScreenGui.Enabled=not ScreenGui.Enabled end end)

-- GRADIENT ANIMATION LOOP
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.08) % 1
    local c1 = getGradientColor(hue, 0.8, 1)
    local c2 = getGradientColor(hue + 0.5, 0.6, 0.8) -- Complementary darker color for glow
    
    StatusBar.BackgroundColor3 = c1
    ProgressFill.BackgroundColor3 = c1
    Dot.BackgroundColor3 = c1
    SearchBtn.BackgroundColor3 = c1
    GlowFrame.ImageColor3 = c2
    
    if WSConnected then
        WsStatus.BackgroundColor3 = c1
    end
end)

spawn(function() ConnectWS() end)
