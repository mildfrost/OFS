local HttpService = game:GetService("HttpService")
local SortOrder = {
    Descending = "Desc",
    Ascending = "Asc"
}

function GetServerJobIds(placeId: number, sortOrder, excludeFullGames: boolean, count: number)
    local function Main(jobIds: table, cursor: string)
        local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?cursor=" .. cursor .."&sortOrder=" .. sortOrder .. "&excludeFullGames=" .. tostring(excludeFullGames)
        local response = game:HttpGet(url)

        if response == "" then
            warn("Couldn't request server info")
            return nil
        end

        local data = HttpService:JSONDecode(response)
        print(data)
        print("hi")
        if not data.data then
            print("hello")
            warn("Error")
            print("what")
            return
        end

        local servers = data.data
        for i=0, count do
            local server = servers[i]
            if server then
                table.insert(jobIds, server.id)
            end
        end
        return data.nextPageCursor
    end

    local jobIds = {}
    local cursor = ""
    while #jobIds ~= count and cursor ~= nil do
        local nextPageCursor = Main(jobIds, cursor)
        print(nextPageCursor)
        cursor = nextPageCursor or ""
        print(cursor)
        print(#jobIds)
    end
    
    return jobIds
end

local joinedServers = {}
local joinedServersIsLoaded = true

function LoadJoinedServers()
    if isfile("JoinedServers") then
        local data = readfile("JoinedServers")
        joinedServers = HttpService:JSONDecode(data)
    end
end

function SaveJoinedServers()
    if joinedServersIsLoaded then
        writefile("JoinedServers", HttpService:JSONEncode(joinedServers))
    end
end



local LocalPlayer = game:GetService("Players").LocalPlayer

function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function GetHumanoidRootPart()
    local char = GetCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

repeat task.wait() until LocalPlayer:GetAttribute("LoadedX")
local PlayerGui = LocalPlayer.PlayerGui

local LoadingGui = PlayerGui:FindFirstChild("LoadingGui")
local startTime = os.time()
local timeout = 30 -- seconds

while LoadingGui do
    task.wait()
    -- Play the game
    if os.time() - startTime > timeout then
        break
    end
    local frame = LoadingGui:FindFirstChild("Frame")
    if frame then
        local play = frame:FindFirstChild("Play")
        if play then
            for i,v in pairs(getconnections(play.Activated)) do
                v:Fire()
            end
        end
    end
    LoadingGui = PlayerGui:FindFirstChild("LoadingGui")
end
local hrp = GetHumanoidRootPart()
if hrp.Anchored then
    hrp.Anchored = false
end

function FindBeachBalls()
    local beachBalls = {}
    for _,v in pairs(workspace:GetChildren()) do
        if v.Name == "BeachBall" then
            table.insert(beachBalls, v)
        end
    end
    return beachBalls
end

local beachBalls = FindBeachBalls()
while #beachBalls > 0 do
    task.wait()
    for _,beachBall in pairs(beachBalls) do
        local chestInteract = beachBall:FindFirstChild("ChestInteract")
        if chestInteract then
            hrp = GetHumanoidRootPart()
            hrp.CFrame = beachBall.PrimaryPart.CFrame + Vector3.new(0, 1, 0)
            --task.wait(0.2)
            fireproximityprompt(chestInteract)
        end
    end
    beachBalls = FindBeachBalls()
end
hrp = GetHumanoidRootPart()
hrp.CFrame = CFrame.new(Vector3.new(0, 1000000, 0))

local TeleportService = game:GetService("TeleportService")
local serverAmount = 20
local jobIds = GetServerJobIds(game.PlaceId, SortOrder.Descending, true, serverAmount)
local index = 1
local serverCooldown = 5 * 60 -- 5 minutes in seconds

LoadJoinedServers()
joinedServers[game.JobId] = os.time()
SaveJoinedServers()

while true do
    task.wait()
    if #jobIds == 0 then
        jobIds = GetServerJobIds(game.PlaceId, SortOrder.Descending, true, serverAmount)
        continue
    end
    local jobId = jobIds[index]
    local lastJoinTime = joinedServers[jobId] or nil
    if lastJoinTime then
        if os.clock() - lastJoinTime > serverCooldown then
            joinedServers[jobId] = nil
        else
            index = index + 1
            if index > #jobIds then
                serverAmount = serverAmount + 20
                jobIds = GetServerJobIds(game.PlaceId, SortOrder.Descending, true, serverAmount)
                index = 1
            end
            continue
        end
    end

    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
    if not success then
        print(error)
        index = index + 1
    end
    task.wait(2)
end