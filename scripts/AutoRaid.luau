if getgenv().AutoRaid_Loaded then
    print("Already loaded!")
    return
end

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

-- For character related info/functions
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

function isInRaid()
    return game.PlaceId == 17333805250
end

function challengeRaid(raidName)
    REMOTE_EVENT_BRIDGE:Fire("RaidStartParty", raidName)
end

function namekRaid(type)
    REMOTE_EVENT_BRIDGE:Fire("NamekRaid", type)
end

------- ACTUAL CODE ----------

getgenv().AutoRaid_Target = nil

local raids = {}
for raidId, raidInfo in pairs(RaidsInfo) do
    local raid = {}
    local raidName = raidInfo[1]
    raid.RequiredKeyId = raidInfo[2]
    raid.RaidId = raidId
    raids[raidName] = raid
end

local raidNames = {}
for i, _ in pairs(raids) do
    table.insert(raidNames, i)
end

local weaponNames = {}
function refreshWeapons()
    table.clear(weaponNames)
    for _,weapon: Tool in pairs(Character.GetBackpackTools()) do
        table.insert(weaponNames, weapon.Name)
    end
    for _,weapon: Tool in pairs(Character.GetEquippedTools()) do
        table.insert(weaponNames, weapon.Name)
    end
end
refreshWeapons()

local config = {}
if isfile("AutoRaidConfig") then
    config = hs:JSONDecode(readfile("AutoRaidConfig"))
else
    config.SelectedRaid = raidNames[1]
    config.Toggle = false
    config.Weapon = weaponNames[1]
    config.NamekType = "Hard"
    config.AutoNamek = false;
end
getgenv().farm = false

function farmBosses()
    local currentBoss = nil
    while true do
        task.wait()
        if not getgenv().farm then
            coroutine.yield()
        end

        local char = Character.GetCharacter()
        if not char then continue end
        Character.EquipTool(config.Weapon)
        local tool = Character.GetEquippedTools()[1]
        if not tool then continue end
        Character.Attack(tool)
        Haki.ActivateAll()
        for _, boss: Model in pairs(bosses:GetChildren()) do
            if currentBoss and currentBoss.Parent == bosses then
                boss = currentBoss
            end
            local npcConfig: Configuration = boss:FindFirstChild("NpcConfiguration")
            if npcConfig then
                local health = npcConfig:GetAttribute("Health") or 0
                if health > 0 then
                    if boss.PrimaryPart and boss.PrimaryPart.CFrame.Y > 0 then
                        Character.Teleport(boss.PrimaryPart.CFrame + Vector3.new(math.random(-5, 5), 40, math.random(-5, 5)))
                        if tool then
                            Character.UseSkill(tool, Enum.KeyCode.Z, boss.PrimaryPart.CFrame)
                            Character.UseSkill(tool, Enum.KeyCode.X, boss.PrimaryPart.CFrame)
                            Character.UseSkill(tool, Enum.KeyCode.C, boss.PrimaryPart.CFrame)
                            Character.UseSkill(tool, Enum.KeyCode.V, boss.PrimaryPart.CFrame)
                            Character.UseSkill(tool, Enum.KeyCode.B, boss.PrimaryPart.CFrame)
                            Character.UseSkill(tool, Enum.KeyCode.F, boss.PrimaryPart.CFrame)
                        end
                        continue
                    else
                        if config.AutoNamek then
                            local bossSpawns = workspace.__GAME.__Islands.__Bosses.NamekWorld.Spawns
                            for _,v in pairs(bossSpawns:GetDescendants()) do
                                if v:IsA("BasePart") and v.Name == "spawn" then
                                    Character.Teleport(v.CFrame)
                                    task.wait()
                                end
                            end
                        end
                    end
                end
                currentBoss = nil
            end
        end
    end
end

local farmCoro = coroutine.create(farmBosses)

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "One Fruit Simulator - Auto Raid",
    Subtitle = nil,
    Logo = nil,
    LoadingEnabled = false,
    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "Auto Raid"
    }
})

local MainTab = Window:CreateTab({
    Name = "Auto Raids",
    Icon = "home",
    ImageSource = "Material",
    ShowTitle = true
})

local RaidDropdown = MainTab:CreateDropdown({
    Name = "Raids",
    Description = nil,
    MultipleOptions = false,
    SpecialType = nil,
    Options = raidNames,
    CurrentOption = config.SelectedRaid,
    Callback = function(raidName)
        config.SelectedRaid = raidName
        writefile("AutoRaidConfig", hs:JSONEncode(config))
    end
})

local WeaponDropdown = MainTab:CreateDropdown({
    Name = "Weapon",
    Description = nil,
    MultipleOptions = false,
    SpecialType = nil,
    Options = weaponNames,
    CurrentOption = config.Weapon,
    Callback = function(weaponName)
        config.Weapon = weaponName
        writefile("AutoRaidConfig", hs:JSONEncode(config))
    end
})

local RefreshWeaponsButton = MainTab:CreateButton({
    Name = "Refresh Weapons",
    Description = nil,
    Callback = function()
        refreshWeapons()
        WeaponDropdown:Set({
            Options = weaponNames
        })
    end
})

local AutoRaidToggle = MainTab:CreateToggle({
    Name = "Auto Raid",
    Description = nil,
    CurrentValue = config.Toggle,
    Callback = function(toggle)
        config.Toggle = toggle
        writefile("AutoRaidConfig", hs:JSONEncode(config))

        if config.Toggle then
            if not isInRaid() then
                challengeRaid(raids[config.SelectedRaid].RaidId)
            else
                getgenv().farm = true
                local success, result = coroutine.resume(farmCoro)
                print(success, result)
            end
        else
            getgenv().farm = false
        end
    end
})

local NamekDropdown = MainTab:CreateDropdown({
    Name = "Namek raid type",
    Description = nil,
    MultipleOptions = false,
    SpecialType = nil,
    Options = {"Easy", "Normal", "Hard", "Insane"},
    CurrentOption = config.NamekType,
    Callback = function(namekType)
        config.NamekType = namekType
        writefile("AutoRaidConfig", hs:JSONEncode(config))
    end
})

local AutoNamekToggle = MainTab:CreateToggle({
    Name = "Auto Namek",
    Description = nil,
    CurrentValue = config.AutoNamek,
    Callback = function(toggle)
        config.AutoNamek = toggle
        writefile("AutoRaidConfig", hs:JSONEncode(config))

        if config.AutoNamek then
            if not isInRaid() then
                namekRaid(config.NamekType)
            else
                getgenv().farm = true
                local success, result = coroutine.resume(farmCoro)
                print(success, result)
            end
        else
            getgenv().farm = false
        end
    end
})


getgenv().AutoRaid_Loaded = true