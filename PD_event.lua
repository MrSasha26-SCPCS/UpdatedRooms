local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

---@class PD_event:CS.Akequ.Base.Room
PD_event = {}

local const_dt = 1
local const_time = CS.Config.GetInt("time_to_teleport_items", 60)

PD_event.dt = 0
PD_event.time = const_time
PD_event.round_started = false
PD_event.PD_teleports = {}

function PD_event:Init()    
    if self.main.netEvent.isServer then        
        CS.HookManager.Add("onRoundStart", function(obj) self.round_started = true end)
        
        local netRooms = GameObject.FindObjectsOfType(typeof(CS.NetRoom))
        for i = 0, netRooms.Length - 1 do
            local netRoom = netRooms[i]
            local roomObj = netRoom.roomObj
            local children = roomObj:GetComponentsInChildren(typeof(CS.UnityEngine.Transform))   
            for j = 0, children.Length - 1 do
                local go = children[j]    
                if string.find(go.name, "PDTeleport") then
                    table.insert(self.PD_teleports, netRoom)
                end
            end
        end

        for i = 0, 7 do    
            local escapes_count = CS.Config.GetInt("pd_exit_count", 2)

            local colliderObj = GameObject("PD_Collider")
            colliderObj.transform:SetParent(self.main.netEvent.transform)
            colliderObj.transform.localPosition = Vector3.zero
            colliderObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 45 * i, 0)

            local boxCollider = colliderObj:AddComponent(typeof(CS.UnityEngine.BoxCollider))
            boxCollider.center = Vector3(16, 1, 0)
            boxCollider.size = Vector3(1, 2, 1)
            boxCollider.isTrigger = true  

            local trigger = colliderObj:AddComponent(typeof(CS.Trigger))
            trigger.onEnterFunc = function(collider) 
                local player = collider:GetComponent(typeof(CS.Player))
                if player ~= nil then                         
                    local random = math.random(1, 8)
                    if random <= escapes_count then
                        local teleportId = math.random(1, #self.PD_teleports)
                        player:Teleport(self.PD_teleports[teleportId].roomObj.transform:Find("PDTeleport").transform.position + Vector3.up, self.PD_teleports[teleportId])
                    else
                        if player.godMode == false and player.playerClass:GetTeamID() ~= "SCP" then                            
                            local damage_h = CS.DamageHandler()
                            damage_h.ignoreResist = true
                            damage_h.deathReason = "Потерялся в карманном измерении."
                            damage_h.killID = "PD"
                            damage_h.damage = player.health
                            player:ChangeHealth(damage_h)
                        end
                    end
                end
            end
        end
    end
end

function PD_event:Update()
    if self.main.netEvent.isServer then    
        if self.dt <= 0 then
            self:dtUpdate()
        else
            self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        end
    end
end

--SERVER

function PD_event:dtUpdate()
    self.dt = const_dt
    self.time = self.time - const_dt

    local players = GameObject.FindObjectsOfType(typeof(CS.Player))

    if players ~= nil then
        for i = 0, players.Length - 1 do
            player = players[i]
            if player ~= nil then    
                local distance = Vector3.Distance(player.transform.position, self.main.netEvent.transform.position)
                if distance <= 17 then
                    local damage_h = CS.DamageHandler()
                    damage_h.ignoreResist = true
                    damage_h.deathReason = "Сгнил в карманном измерении."
                    damage_h.killID = "PD"
                    damage_h.damage = CS.Config.GetInt("pd_damage_per_second", 3)
                    player:ChangeHealth(damage_h)
                end
            end
        end
    end

    if self.time <= 0  and self.round_started then
        self.time = const_time

        local itemsInPD = {}
        local items = GameObject.FindObjectsOfType(typeof(CS.ItemPickup))
        if items ~= nil then
            for i = 0, items.Length - 1 do
                item = items[i]
                local distance = Vector3.Distance(item.transform.position, self.main.netEvent.transform.position)
                if distance <= 17 then
                   table.insert(itemsInPD, item)
                end
            end
        end
        if #itemsInPD > 0 then
            local randomItemId = math.random(1, #itemsInPD)
            local teleportId = math.random(1, #self.PD_teleports)              
            itemsInPD[randomItemId].transform.position = self.PD_teleports[teleportId].roomObj.transform:Find("PDTeleport").transform.position + Vector3.up
            self.main:SendToEveryone("SetItem", itemsInPD[randomItemId], self.PD_teleports[teleportId])
        end
    end
end

--CLIENT
function PD_event:SetItem(item, parent)
    item.transform:SetParent(parent.transform)
end

return PD_event