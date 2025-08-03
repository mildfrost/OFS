local LocalPlayer = game:GetService("Players").LocalPlayer
repeat task.wait() until LocalPlayer:GetAttribute("LoadedX")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local INDEXER = ReplicatedStorage:WaitForChild("INDEXER")
local ItemsInfo = require(INDEXER:WaitForChild("ItensInfo"))
local RaidsInfo = require(INDEXER:WaitForChild("RaidBoosts"))["RaidDisplay"]
local hs = game:GetService("HttpService")
local SharedModules = ReplicatedStorage.SharedModules
local ToolController = require(SharedModules.Controllers.ToolController)
local ExtraFunctions = require(SharedModules.ExtraFunctions)
local ToolsInfo = require(INDEXER.ToolsInfo)
local bosses = workspace.__GAME.__Mobs.__Bosses
local ClientBridge = require(ReplicatedStorage.BridgeNet.ClientBridge)
local TOOL_EVENT2_BRIDGE = ClientBridge.from("TOOL_EVENT2")

local Character = {}
-- For haki related info/functions
local Haki = {Ken = {}, Buso = {}, Hao = {}}

function Character.GetCharacter()
    return LocalPlayer.Character or nil
end

function Character.GetHumanoidRootPart()
    local char = Character.GetCharacter()
    if not char then return nil end
    if not char.PrimaryPart then return nil end
    return char.PrimaryPart
end

function Character.GetEquippedTools()
    local char = Character.GetCharacter()
    if not char then return {} end
    local tools = {}
    for _,v: Tool? in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            table.insert(tools, v)
        end
    end
    return tools
end

function Character.GetBackpackTools()
    local backpack = LocalPlayer.Backpack
    local tools = {}
    for _,v: Tool? in pairs(backpack:GetChildren()) do
        if v:IsA("Tool") then
            table.insert(tools, v)
        end
    end
    return tools
end

function Character.EquipTool(toolName: string)
    local char = Character.GetCharacter()
    if not char then return end
    for _, tool: Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == toolName then
            char.Humanoid:EquipTool(tool)
            return tool
        end
    end
end

function Character.Teleport(cframe: CFrame)
    local hrp = Character.GetHumanoidRootPart()
    if not hrp then return end
    hrp.CFrame = cframe
end

function Character.Attack(tool)
    local toolType = tool:GetAttribute("Type")
    TOOL_EVENT2_BRIDGE:Fire("Combat", 1, false, tool, toolType)
end

function Character.UseSkill(tool: Tool, key: Enum.KeyCode, cframe: CFrame)
    local toolType = tool:GetAttribute("Type")
    if not toolType then return end
    local inputObject = {
        KeyCode = key
    }
    local toolInfo = ToolsInfo[tool.Name][key.Name]
    local oldGetCurrentMouse = nil

    oldGetCurrentMouse = hookfunction(ExtraFunctions.GetCurrentMouse, function(player, boolean, distanceAdd)
        local LocalPlayer = game:GetService("Players").LocalPlayer
        local char = LocalPlayer.Character or nil
        if not char then return end
        local hrp = char.PrimaryPart
        if not hrp then return end
        local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {
			char,
			workspace.__Zones,
			workspace.__GAME.__SpawnLocations,
			workspace.__GAME.__Ocean,
			workspace.__Cache,
			workspace.Effects
		}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local direction = (cframe.Position - hrp.CFrame.Position)
        local distance = distanceAdd + math.floor(direction.Magnitude)
        local ray: RaycastResult = workspace:Raycast(hrp.CFrame.Position, direction * distance, raycastParams)
        return ray and { ray.Position, direction } or { ray.Origin + ray.Direction * distance, ray.Direction }
    end)

    local oldBodyControl = nil
    oldBodyControl = hookfunction(ToolController.BodyControl, function() end)

    pcall(function()
        ToolController.UseSkill(tool, tool:GetAttribute("Type"), Enum.UserInputState.Begin, inputObject, toolInfo)
        ToolController.UseSkill(tool, tool:GetAttribute("Type"), Enum.UserInputState.End, inputObject, toolInfo)
    end)
    

    hookfunction(ExtraFunctions.GetCurrentMouse, oldGetCurrentMouse)
    hookfunction(ToolController.BodyControl, oldBodyControl)
end

function spoofDevice()
    local old = nil
    old = hookfunction(ExtraFunctions.VerifyMobile, function()
        return false
    end)
    return old
end

function Haki.Ken.IsActive()
    local char = Character.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Ken") or false
end

function Haki.Buso.IsActive()
    local char = Character.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Buso") or false
end

function Haki.Hao.IsActive()
    local char = Character.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Hao") or false
end

function Haki.Ken.Activate()
    ToolController.Haki("Ken")
end

function Haki.Buso.Activate()
    ToolController.Haki("Buso")
end

function Haki.Hao.Activate()
    ToolController.Haki("Hao")
end

function Haki.ActivateAll()
    if not Haki.Ken.IsActive() then
        Haki.Ken.Activate()
    end
    if not Haki.Buso.IsActive() then
        Haki.Buso.Activate()
    end
    if not Haki.Hao.IsActive() then
        Haki.Hao.Activate()
    end
end

local bosses = workspace.__GAME.__Mobs.__Bosses

for i,v in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do
    v:Disable()
end

getgenv().farm = true
while getgenv().farm do
    task.wait()
    local char = Character.GetCharacter()
    if not char then continue end
    Character.EquipTool("SStaff")
    local tool = Character.GetEquippedTools()[1]
    if not tool then continue end
    Character.Attack(tool)
    Haki.ActivateAll()
    local spawnLocs = workspace.__GAME.__SpawnLocations
    local target = nil
    for _, boss in pairs(bosses:GetChildren()) do
        local npcConfig = boss:FindFirstChild("NpcConfiguration")
        if npcConfig and npcConfig:GetAttribute("Name") == "Alien Invader" and npcConfig:GetAttribute("Health") > 0 then
            target = boss
            break
        end
    end
    if target == nil then
        local ball = nil
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and string.match(v.Name, "Star") then
                local proximityPrompt = v.Eat
                local primaryPart = v.PrimaryPart
                if primaryPart and proximityPrompt then
                    ball = v
                    Character.Teleport(primaryPart.CFrame)
                    fireproximityprompt(proximityPrompt)
                end
            end
        end
        if not ball or ball.Parent ~= workspace then
            Character.Teleport(spawnLocs:GetChildren()[1].CFrame)
        end
        continue
    end
    while target and target.Parent == bosses do
        task.wait()
        if target.PrimaryPart and target.PrimaryPart.CFrame.Y > 0 then
            Character.Teleport(target.PrimaryPart.CFrame + Vector3.new(math.random(-5, 5), 40, math.random(-5, 5)))
            if tool then
                Character.UseSkill(tool, Enum.KeyCode.Z, target.PrimaryPart.CFrame)
                Character.UseSkill(tool, Enum.KeyCode.X, target.PrimaryPart.CFrame)
                Character.UseSkill(tool, Enum.KeyCode.V, target.PrimaryPart.CFrame)
            end
        end
    end
end