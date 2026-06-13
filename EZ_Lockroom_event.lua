local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

local function findInactiveObj(name, type, id)
    local objs = CS.UnityEngine.Resources.FindObjectsOfTypeAll(typeof(type))
    for i = 0, objs.Length - 1 do
        local obj = objs[i]
        if obj ~= nil then    
            if string.find(obj.name, name) then
                if id <= 0 then
                    return obj
                else
                    id = id - 1
                end
            end
        end
    end
    return nil
end

local function findInObject(parent, obj_name, i)
    if i == nil then i = 1 end
    local children = parent:GetComponentsInChildren(typeof(CS.UnityEngine.Transform))
    for j = 0, children.Length - 1 do    
        local child = children[j]
        if child.name == obj_name then
            if i <= 1 then    
                return child.gameObject
            else
                i = i - 1
            end
        end
    end
    return nil
end

---@class EZ_Lockroom_event:CS.Akequ.Base.Room
EZ_Lockroom_event = {}

local const_time = 8.5
local const_dt = 0.5

EZ_Lockroom_event.dt = 0
EZ_Lockroom_event.time = const_time
EZ_Lockroom_event.closed = true
EZ_Lockroom_event.enabled = false

EZ_Lockroom_event.door1 = nil
EZ_Lockroom_event.door2 = nil
EZ_Lockroom_event.particle = nil

EZ_Lockroom_event.players = {}

function EZ_Lockroom_event:Init()    
    local parent = self.main.netEvent.transform
    
    --SPAWNING SMOKE with SOUND
    if self.main.netEvent.isClient then        
        if CS.UnityEngine.PlayerPrefs.GetInt("LightType") == 0 then    
            local particle_pref = findInactiveObj("Dust", CS.UnityEngine.ParticleSystem, 0)
            if particle_pref ~= nil then
                self.particle = GameObject.Instantiate(particle_pref)
                self.particle.transform:SetParent(parent)
                self.particle.transform.localScale = Vector3(0.2, 0.2, 0.2)
                self.particle.transform.localPosition = Vector3(0.4, 1, -0.4)
                self.particle.gameObject:SetActive(true)
                self.particle.emission.enabled = false
            end
        else
            local particle_pref = findInactiveObj("Smoke", CS.UnityEngine.ParticleSystem, 0)
            if particle_pref ~= nil then
                CS.GameConsole.Log("Particle found")
                self.particle = GameObject.Instantiate(particle_pref)
                self.particle.transform:SetParent(parent)
                self.particle.transform.localScale = Vector3(0.3, 0.3, 0.3)
                self.particle.transform.localPosition = Vector3(0.4, 2.5, -3.5)
                self.particle.transform.localRotation = CS.UnityEngine.Quaternion.identity
                self.particle.gameObject:SetActive(true)
                self.particle.emission.enabled = false
                self.particle.emission.rateMultiplier = 225
            end
        end

        CS.ScriptHelper.LoadClip("smoke.ogg", CS.UnityEngine.AudioType.OGGVORBIS, function(clip)
            if clip ~= nil then
                local audioSource = self.particle.gameObject:AddComponent(typeof(CS.UnityEngine.AudioSource))
                audioSource.clip = clip
                audioSource.loop = true
                audioSource.spatialBlend = 1
                audioSource.rolloffMode = CS.UnityEngine.AudioRolloffMode.Linear
                audioSource.minDistance = 4
                audioSource.maxDistance = 15
                audioSource.volume = 0.25
                audioSource:Play()
            end
        end)
    end

    --SPAWNING COLLIDER with TRIGGER
    if self.main.netEvent.isServer then    
        local empty = GameObject()
        empty.transform:SetParent(parent)
        empty.transform.localPosition = Vector3(0.5, 1, -0.5)

        local triggerBox = empty:AddComponent(typeof(CS.UnityEngine.BoxCollider))     
        triggerBox.isTrigger = true  
        triggerBox.size = Vector3(7, 2.5, 7)

        local trigger = empty:AddComponent(typeof(CS.Trigger))
        trigger.onEnterFunc = function(collider) 
            local player = collider:GetComponent(typeof(CS.Player))
            if player ~= nil then          
                if self.players[player] == nil then
                    self.players[player] = 2.5
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

    --SPAWNING DOORS
    local doorObj = CS.ResourcesManager.SpawnObject("Door")

    doorObj.transform:SetParent(parent)
    doorObj.transform.localPosition = Vector3(2.601, 0, 3.473)
    doorObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
    doorObj.transform.localScale = Vector3(0.85, 1, 1)

    self.door1 = doorObj:GetComponent(typeof(CS.Door))
    if self.door1 ~= nil then
        CS.DoorManager.Add(self.door1)
    end

    doorObj = CS.ResourcesManager.SpawnObject("Door")

    doorObj.transform:SetParent(parent)
    doorObj.transform.localPosition = Vector3(-3.484, 0, -2.757)
    doorObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 90, 0)
    doorObj.transform.localScale = Vector3(0.85, 1, 1)

    findInObject(doorObj, "Door2").transform.localScale = Vector3(1.2, 1, 1)

    self.door2 = doorObj:GetComponent(typeof(CS.Door))
    if self.door2 ~= nil then
        CS.DoorManager.Add(self.door2)
    end
    
    --SPAWNING BUTTONS
    local buttonObj = CS.ResourcesManager.SpawnObject("DoorButton")
    
    if buttonObj ~= nil then
        buttonObj.transform:SetParent(parent)
        buttonObj.transform.localPosition = Vector3(4.42, 1, 0.16)
        buttonObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, -90, 0)
        
        local button = buttonObj:GetComponent(typeof(CS.Button))
        if button ~= nil then
            button.call = function()
                self.main:SendToServer("onButtonPressed")
            end
        end
    end
    
    buttonObj = CS.ResourcesManager.SpawnObject("DoorButton")
    
    if buttonObj ~= nil then
        buttonObj.transform:SetParent(parent)
        buttonObj.transform.localPosition = Vector3(3.758, 1, 3.295)
        buttonObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
        
        local button = buttonObj:GetComponent(typeof(CS.Button))
        if button ~= nil then
            button.call = function()
                self.main:SendToServer("onButtonPressed")
            end
        end
    end

    buttonObj = CS.ResourcesManager.SpawnObject("DoorButton")
    
    if buttonObj ~= nil then
        buttonObj.transform:SetParent(parent)
        buttonObj.transform.localPosition = Vector3(-0.1, 1, -4.426)
        buttonObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
        
        local button = buttonObj:GetComponent(typeof(CS.Button))
        if button ~= nil then
            button.call = function()
                self.main:SendToServer("onButtonPressed")
            end
        end
    end

    buttonObj = CS.ResourcesManager.SpawnObject("DoorButton")
    
    if buttonObj ~= nil then
        buttonObj.transform:SetParent(parent)
        buttonObj.transform.localPosition = Vector3(-3.3, 1, -3.8)
        buttonObj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, -90, 0)
        
        local button = buttonObj:GetComponent(typeof(CS.Button))
        if button ~= nil then
            button.call = function()
                self.main:SendToServer("onButtonPressed")
            end
        end
    end
end

function EZ_Lockroom_event:Update()
    if self.main.netEvent.isServer then    
        if self.dt <= 0 then
            self:dtUpdate()
        else
            self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        end
        if self.time > 0 then
            self.time = self.time - CS.UnityEngine.Time.deltaTime
        end
        if self.time < const_time / 2 and not self.closed and GameObject.FindObjectOfType(typeof(CS.AlphaWarhead)):GetStatus() ~= CS.AlphaWarhead.AlphaWarheadStatus.ACTIVE then
            self.door1:ForceState(false)
            self.door2:ForceState(false)
            self.closed = true
        end
    end
    if self.main.netEvent.isClient then
        if self.particle ~= nil then    
            if CS.UnityEngine.Camera.main ~= nil then    
                local distance = Vector3.Distance(CS.UnityEngine.Camera.main.transform.position, self.particle.transform.position)
                if distance > 10 and self.enabled then
                    self.particle.emission.enabled = false
                    self.enabled = false
                elseif distance <= 10 and not self.enabled then
                    self.particle.emission.enabled = true
                    self.enabled = true
                end
            end
        end
    end
end

--SERVER

function EZ_Lockroom_event:dtUpdate()
    self.dt = const_dt

    if self.players ~= nil then
        for player, time in pairs(self.players) do
            if player ~= nil then    
                if time > 0 then    
                    time = time - const_dt
                    self.players[player] = time
                else 
                    local damage = CS.DamageHandler()
                    damage.ignoreResist = true
                    damage.deathReason = "Отравление ядовитым газом."
                    damage.killID = "Smoke"
                    damage.damage = math.floor(CS.Config.GetInt("pd_damage_per_second", 3) / 2) + 1
                    player:ChangeHealth(damage)
                end
            else
                self.player[player] = nil
            end
        end
    end
end

function EZ_Lockroom_event:onButtonPressed()
    if self.time <= 0 and GameObject.FindObjectOfType(typeof(CS.AlphaWarhead)):GetStatus() ~= CS.AlphaWarhead.AlphaWarheadStatus.ACTIVE then
        self.door1:ForceState(true)
        self.door2:ForceState(true)

        self.time = const_time
        self.closed = false
    end
end

return EZ_Lockroom_event