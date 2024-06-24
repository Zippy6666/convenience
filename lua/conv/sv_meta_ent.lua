local ENT = FindMetaTable("Entity")


-- Call a method for this ent next tick
function ENT:AddonName_CallNextTick( methodname, ... )

    local function func( me, ... )
        if IsValid(me) then
            me[methodname](me, ...)
        end
    end


    conv.callNextTick( func, self, ... )

end


-- Temporarily set a variable on an entity
function ENT:AddonName_TempVar( name, value, duration )

    self[name.."ValBefore"] = self[name.."ValBefore"] or self[name]
    self[name] = value

    -- print(name, "set to", value)


    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = ValBefore
            self[name.."ValBefore"] = nil
            -- print(name, "set back to", ValBefore)
        end
    end)

end


-- Temporarily sets variables created by ENT:NetworkVar()
function ENT:AddonName_TempNetVar( funcName, value, duration )

    local setFuncName = "Set"..funcName
    local getFuncName = "Get"..funcName

    if !self[setFuncName.."NetValBefore"] then
        self[setFuncName](name, value)
    end

    self[setFuncName.."NetValBefore"] = self[setFuncName.."NetValBefore"] or self[getFuncName]()

    timer.Create("TempNetVar"..setFuncName..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[setFuncName](value)
            self[setFuncName.."NetValBefore"] = nil
        end
    end)

end


-- Timer simple for entities with a built-in valid check
function ENT:AddonName_TimerSimple( delay, func, ... )
    local tbl = table.Pack(...)
    timer.Simple(delay, function()
        if IsValid(self) then
            func(unpack(tbl))
        end
    end)
end


-- Check if an entity has the supplied flags
function ENT:AddonName_HasFlags( flags )
    if !IsValid(self) then return false end
    return bit.band(self:GetFlags(), flags)==flags
end