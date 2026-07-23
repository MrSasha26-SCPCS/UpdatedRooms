-- Settings
local dt = 1
--

local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

-- Local functions

local function getIndex(tab, val)
    for i, value in ipairs(tab) do
        if value == val then
            return i
        end
    end
    return -1
end

---@class EZ_Medibay_event:CS.Akequ.Base.Room

EZ_Medibay_event = {}

EZ_Medibay_event.dt = dt
EZ_Medibay_event.players = {}

function EZ_Medibay_event:Init()       
    --SPAWNING COLLIDER with TRIGGER
    if self.main.netEvent.isServer then    
        local parent = self.main.netEvent.transform
        
        local empty = GameObject()
        empty.transform:SetParent(parent)
        empty.transform.localPosition = Vector3(-4.36, 1.38, -2.16)
        empty.transform.localRotation = CS.UnityEngine.Quaternion.identity

        local triggerBox = empty:AddComponent(typeof(CS.UnityEngine.BoxCollider))     
        triggerBox.isTrigger = true  
        triggerBox.size = Vector3(4.8, 2.38, 9.11)

        local trigger = empty:AddComponent(typeof(CS.Trigger))
        trigger.onEnterFunc = function(collider) 
            local player = collider:GetComponent(typeof(CS.Player))
            if player ~= nil then                             
                if getIndex(self.players, player) == -1 then
                    table.insert(self.players, player)
                end
            end
        end

        trigger.onExitFunc = function(collider) 
            local player = collider:GetComponent(typeof(CS.Player))            
            if player ~= nil then
                local index = getIndex(self.players, player)
                if index ~= -1 then
                    table.remove(self.players, index)
                end
            end
        end

        local firstAid2_obj = CS.ResourcesManager.SpawnItem("FirstAid2")
        firstAid2_obj.transform:SetParent(self.main.netEvent.transform)
        firstAid2_obj.transform.localPosition = Vector3(-2.27, 0.82, -0.55)
        firstAid2_obj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 11.11)

        local cup_obj = CS.ResourcesManager.SpawnItem("Cup")
        cup_obj.transform:SetParent(self.main.netEvent.transform)
        cup_obj.transform.localPosition = Vector3(-2.2, 1.52, 1.19)
    end
end

function EZ_Medibay_event:Update()
    if self.main.netEvent.isServer then
        self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        if self.dt <= 0 then
            self.dt = dt
            self:PluginUpdate()
        end
    end
end

-- SERVER

function EZ_Medibay_event:PluginUpdate()
    local damage_h = CS.DamageHandler()
    damage_h.ignoreResist = true
    damage_h.deathReason = "Healed"
    damage_h.killID = "MedHeal"
    damage_h.damage = -CS.Config.GetInt("pd_damage_per_second", 3)
    
    for _, player in ipairs(self.players) do
        if player ~= nil then    
            player:ChangeHealth(damage_h)
        end
    end
end

return EZ_Medibay_event