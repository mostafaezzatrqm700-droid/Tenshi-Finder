-- NYX Beast Egg Auto-Join local loader
-- Put Tenshi-Finder-Beast-AutoJoin.lua in your executor's workspace/files folder,
-- then execute this loader.
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end

    local Players = game:GetService("Players")
    while not Players.LocalPlayer do task.wait(0.2) end
    Players.LocalPlayer:WaitForChild("PlayerGui")
    task.wait(2)

    assert(type(readfile) == "function",
        "This loader needs executor readfile support. Execute the main .lua file directly instead.")

    local ok, source = pcall(readfile, "Tenshi-Finder-Beast-AutoJoin.lua")
    assert(ok and type(source) == "string" and #source > 0,
        "Could not read Tenshi-Finder-Beast-AutoJoin.lua. Put it in the executor workspace/files folder.")

    local fn, compileError = loadstring(source)
    assert(fn, "Tenshi Finder compile error: " .. tostring(compileError))
    local ran, failure = pcall(fn)
    if not ran then warn("[NYX Beast Auto-Join] " .. tostring(failure)) end
end)