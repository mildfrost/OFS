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

        if data.errors then
            warn("Request Error:", data.errors.code)
            return nil
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
        cursor = nextPageCursor
    end
    
    return jobIds
end

local LocalPlayer = game:GetService("Players").LocalPlayer
repeat task.wait() until LocalPlayer:GetAttribute("LoadedX")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

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
        task.wait()
        local chestInteract = beachBall:FindFirstChild("ChestInteract")
        if chestInteract then
            hrp.CFrame = beachBall.PrimaryPart.CFrame - Vector3.new(0, 10, 0)
            task.wait(0.2)
            fireproximityprompt(chestInteract)
        end
    end
    beachBalls = FindBeachBalls()
end

hrp.CFrame = CFrame.new(Vector3.new(0, 1000000, 0))

local TeleportService = game:GetService("TeleportService")
local serverAmount = 20
local jobIds = GetServerJobIds(game.PlaceId, SortOrder.Descending, true, serverAmount)
local index = 1
local serverCooldown = 5 * 60 -- 5 minutes in seconds

while true do
    task.wait()
    local jobId = jobIds[index]
    local joinedServers = {}

    if isfile("JoinedServers") then
        joinedServers = HttpService:JSONDecode(readfile("JoinedServers"))
    end

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
        end
    end

    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end)
    if success then
        joinedServers[game.JobId] = os.clock()
        writefile("JoinedServers", HttpService:JSONEncode(joinedServers))
    else
        print(error)
        index = index + 1
    end
    task.wait(2)
end