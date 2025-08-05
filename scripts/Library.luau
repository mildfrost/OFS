local lib = {}

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
local REMOTE_EVENT_BRIDGE = ClientBridge.from("REMOTE_EVENT")

function lib.GetCharacter(): Model?
    return LocalPlayer.Character or nil
end

function lib.GetHumanoidRootPart(): Part?
    local char = lib.GetCharacter()
    if not char then return nil end
    if not char.PrimaryPart then return nil end
    return char.PrimaryPart
end

function lib.GetEquippedTools(): table
    local char = lib.GetCharacter()
    if not char then return {} end
    local tools = {}
    for _,v: Tool? in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            table.insert(tools, v)
        end
    end
    return tools
end

function lib.GetBackpackTools(): table
    local backpack = LocalPlayer.Backpack
    local tools = {}
    for _,v: Tool? in pairs(backpack:GetChildren()) do
        if v:IsA("Tool") then
            table.insert(tools, v)
        end
    end
    return tools
end

function lib.EquipTool(toolName: string): Tool?
    local char = lib.GetCharacter()
    if not char then return end
    for _, tool: Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == toolName then
            char.Humanoid:EquipTool(tool)
            return tool
        end
    end
end

function lib.Teleport(cframe: CFrame)
    local hrp = lib.GetHumanoidRootPart()
    if not hrp then return end
    hrp.CFrame = cframe
end

function lib.Attack(tool)
    local toolType = tool:GetAttribute("Type")
    TOOL_EVENT2_BRIDGE:Fire("Combat", 1, false, tool, toolType)
end

function lib.UseSkill(tool: Tool, key: Enum.KeyCode, cframe: CFrame)
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

function lib.IsKenActive(): boolean
    local char = lib.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Ken") or false
end

function lib.IsBusoActive(): boolean
    local char = lib.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Buso") or false
end

function lib.IsHaoActive(): boolean
    local char = lib.GetCharacter()
    if not char then return false end
    return char:GetAttribute("Hao") or false
end

function lib.ActivateKen()
    ToolController.Haki("Ken")
end

function lib.ActivateBuso()
    ToolController.Haki("Buso")
end

function lib.ActivateHao()
    ToolController.Haki("Hao")
end

function lib.ActivateAllHaki()
    if not lib.IsKenActive() then
        lib.ActivateKen()
    end
    if not lib.IsBusoActive() then
        lib.ActivateBuso()
    end
    if not lib.Hao.IsActive() then
        lib.ActivateHao()
    end
end

function lib.IsInRaid(): boolean
    return game.PlaceId == 17333805250
end

function lib.ChallengeRaid(raidName: string)
    REMOTE_EVENT_BRIDGE:Fire("RaidStartParty", raidName)
end

function lib.NamekRaid(type: string)
    REMOTE_EVENT_BRIDGE:Fire("NamekRaid", type)
end

function lib.GetRaidInfo(): table
    return require(INDEXER:WaitForChild("RaidBoosts"))["RaidDisplay"]
end

return lib