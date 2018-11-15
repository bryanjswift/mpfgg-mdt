-- Controls what types of spells this front-end displays
aura_env.types = {
    ["INTERRUPT"] = true,
    ["HARDCC"]    = false,
    ["STHARDCC"]  = false,
    ["SOFTCC"]    = false,
    ["STSOFTCC"]  = false,
    ["DISPEL"]    = false,
    ["EXTERNAL"]  = false,
    ["HEALING"]   = false,
    ["UTILITY"]   = false,
    ["PERSONAL"]  = false,
    ["IMMUNITY"]  = false,
    ["DAMAGE"]    = false,
    ["TANK"]      = false,
}

-- Controls the sorting order for different types of spells
aura_env.typeToPriority = {
    ["INTERRUPT"] = 0,
    ["HARDCC"]    = 1,
    ["STHARDCC"]  = 2,
    ["SOFTCC"]    = 3,
    ["STSOFTCC"]  = 4,
    ["DISPEL"]    = 5,
    ["EXTERNAL"]  = 6,
    ["HEALING"]   = 7,
    ["UTILITY"]   = 8,
    ["PERSONAL"]  = 9,
    ["IMMUNITY"]  = 10,
    ["DAMAGE"]    = 11,
    ["TANK"]      = 12,
}

-- Computes the sort index (Default: Type > SpellID > MemberName)
aura_env.computeSortIndex = function(type, spellID, member)
    return ("%02d%06d%s"):format(aura_env.typeToPriority[type], spellID, member.name)
end
