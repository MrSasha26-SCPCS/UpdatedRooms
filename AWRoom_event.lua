local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

---@class AWRoom_event:CS.Akequ.Base.Room
AWRoom_event = {}

local const_time = CS.Config.GetInt("hd_time", 45)
local const_dt = 1

AWRoom_event.dt = 0

AWRoom_event.players = {}

function AWRoom_event:Init()    
    --SPAWNING COLLIDER with TRIGGER
    if self.main.netEvent.isServer then    
        local parent = GameObject.Find("Map_AW(Clone)").transform
        
        local empty = GameObject()
        empty.transform:SetParent(parent)
        empty.transform.localPosition = Vector3(0, 1.73, 2.92)
        empty.transform.localRotation = CS.UnityEngine.Quaternion.identity

        local triggerBox = empty:AddComponent(typeof(CS.UnityEngine.BoxCollider))     
        triggerBox.isTrigger = true  
        triggerBox.size = Vector3(14, 2.5, 22)

        local trigger = empty:AddComponent(typeof(CS.Trigger))
        trigger.onEnterFunc = function(collider) 
            local player = collider:GetComponent(typeof(CS.Player))
            if player ~= nil then                             
                if self.players[player] == nil then
                    self.players[player] = {const_time, 0}
                end
            end
        end
        trigger.onExitFunc = function(collider) 
            local player = collider:GetComponent(typeof(CS.Player))            
            if player ~= nil then
                if self.players[player] ~= nil then
                    self.players[player] = nil
                end
            end
        end
    end
end

function AWRoom_event:Update()
    if self.main.netEvent.isServer then    
        if self.dt <= 0 then
            self:dtUpdate()
        else
            self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        end
    end
end

--SERVER

function AWRoom_event:dtUpdate()
    self.dt = const_dt

    if self.players ~= nil then
        for player, tableda in pairs(self.players) do
            if player ~= nil then    
                local time = tableda[1]
                local damage = tableda[2]
                if time > 0 then    
                    time = time - const_dt
                else 
                    time = const_time
                    damage = damage + 3
                end
                if damage > 0 then
                    local damage_h = CS.DamageHandler()
                    damage_h.ignoreResist = true
                    damage_h.deathReason = "Радиоактивное излучение."
                    damage_h.killID = "RAI"
                    damage_h.damage = damage
                    player:ChangeHealth(damage_h)
                end
                self.players[player] = {time, damage}
            else
                self.player[player] = nil
            end
        end
    end
end

return AWRoom_event