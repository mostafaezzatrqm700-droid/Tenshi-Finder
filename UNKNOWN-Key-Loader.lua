-- UNKNOWN | Tenshi-Finder Key Loader
-- This loader validates a user key with the Tenshi Cloudflare Worker before loading
-- the existing stable Tenshi-Finder build. It does not modify the stable script.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local VERIFY_URL = "https://tenshi-key-system.tenshifinder.workers.dev/validate"
local SCRIPT_URL = "https://raw.githubusercontent.com/mostafaezzatrqm700-droid/Tenshi-Finder/main/Tenshi-Finder-Beast-AutoJoin.lua"

local function httpRequest(options)
    local req = request or http_request or (syn and syn.request)
    if type(req) == "function" then
        return req(options)
    end
    error("Your executor does not expose a supported HTTP request function.")
end

local gui = Instance.new("ScreenGui")
gui.Name = "UNKNOWN_KeySystem"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parent
pcall(function()
    parent = gethui()
end)
if not parent then
    parent = player:WaitForChild("PlayerGui")
end
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(340, 205)
frame.Position = UDim2.new(0.5, -170, 0.5, -102)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(85, 85, 105)
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 38)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "UNKNOWN"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -24, 0, 22)
subtitle.Position = UDim2.fromOffset(12, 43)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Enter your access key to continue"
subtitle.TextColor3 = Color3.fromRGB(160, 160, 175)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.Parent = frame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -32, 0, 40)
keyBox.Position = UDim2.fromOffset(16, 77)
keyBox.BackgroundColor3 = Color3.fromRGB(31, 31, 39)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "TF-..."
keyBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(245, 245, 250)
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.ClearTextOnFocus = false
keyBox.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 7)
boxCorner.Parent = keyBox

local verifyButton = Instance.new("TextButton")
verifyButton.Size = UDim2.new(1, -32, 0, 36)
verifyButton.Position = UDim2.fromOffset(16, 128)
verifyButton.BackgroundColor3 = Color3.fromRGB(93, 75, 190)
verifyButton.BorderSizePixel = 0
verifyButton.Text = "VERIFY KEY"
verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyButton.Font = Enum.Font.GothamBold
verifyButton.TextSize = 13
verifyButton.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 7)
buttonCorner.Parent = verifyButton

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 22)
status.Position = UDim2.fromOffset(16, 168)
status.BackgroundTransparency = 1
status.Text = "Waiting for key..."
status.TextColor3 = Color3.fromRGB(160, 160, 175)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local busy = false

local function setStatus(message, color)
    status.Text = message
    status.TextColor3 = color or Color3.fromRGB(160, 160, 175)
end

verifyButton.MouseButton1Click:Connect(function()
    if busy then return end

    local key = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
        setStatus("Please enter your key.", Color3.fromRGB(255, 190, 90))
        return
    end

    busy = true
    verifyButton.Text = "CHECKING..."
    setStatus("Checking key with server...")

    local ok, response = pcall(function()
        return httpRequest({
            Url = VERIFY_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({ key = key })
        })
    end)

    if not ok or type(response) ~= "table" then
        setStatus("Connection failed. Try again.", Color3.fromRGB(255, 100, 100))
        verifyButton.Text = "VERIFY KEY"
        busy = false
        return
    end

    local body = response.Body or response.body or ""
    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodedOk or type(data) ~= "table" or data.valid ~= true then
        local reason = decodedOk and data.reason == "expired" and "Key expired." or "Invalid or revoked key."
        setStatus(reason, Color3.fromRGB(255, 100, 100))
        verifyButton.Text = "VERIFY KEY"
        busy = false
        return
    end

    setStatus("Key accepted. Loading UNKNOWN...", Color3.fromRGB(100, 220, 140))
    verifyButton.Text = "ACCEPTED"

    task.wait(0.35)
    gui:Destroy()

    local loadOk, loadError = pcall(function()
        local source = game:HttpGet(SCRIPT_URL)
        assert(type(source) == "string" and #source > 0, "Script download was empty.")
        local chunk = loadstring(source)
        assert(type(chunk) == "function", "Script could not be compiled.")
        chunk()
    end)

    if not loadOk then
        warn("[UNKNOWN] Tenshi-Finder failed to load: " .. tostring(loadError))
    end
end)
