local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

---@class EZ_Medibay_event:CS.Akequ.Base.Room

EZ_Medibay_event = {}

function EZ_Medibay_event:Init()       
    self:SpawnLocker()

    if self.main.netEvent.isServer then    
        local items = self.main.netEvent:GetComponentsInChildren(typeof(CS.ItemPickup))
        for i = 0, items.Length - 1 do
            item = items[i]
            GameObject.Destroy(item.gameObject)
            print(item.name)
        end

        for i = 0, 3 do    
            local scp500_obj = CS.ResourcesManager.SpawnItem("SCP500")
            scp500_obj.transform:SetParent(self.main.netEvent.transform)
            scp500_obj.transform.localPosition = Vector3(-6.67, 1.15, -2.75 + 0.15 * i)
        end

        for i = 0, 3 do    
            local scp500_obj = CS.ResourcesManager.SpawnItem("SCP420J")
            scp500_obj.transform:SetParent(self.main.netEvent.transform)
            scp500_obj.transform.localPosition = Vector3(-6.67, 1.15, -2 + 0.15 * i)
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

function EZ_Medibay_event:SpawnLocker()
    local locker1_obj = CS.ResourcesManager.SpawnObject("Locker_Equipment_Horizontal")
    locker1_obj.transform:SetParent(self.main.netEvent.transform)
    locker1_obj.transform.localPosition = Vector3(-6.67, 1.33, -2.08)
    locker1_obj.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 90, 0)

    if self.main.netEvent.isServer then
        local comp = locker1_obj:GetComponent(typeof(CS.LockerEquipment))
        if comp ~= nil then     
            GameObject.Destroy(comp)
        end
    end
end

return EZ_Medibay_event