class 'GorgeSetSurvivalInstinctsNode' (BTNode)

function GorgeSetSurvivalInstinctsNode:Run(context)
  context.survivalInstincts = context.survivalInstincts or {
    wantHealth = false,
    wantEnergy = false,

    spooked = false,
    spookedUntil = 0,

    lastHealth = 0,

    terrified = false
  }

  local instincts = context.survivalInstincts

  local player = context.bot:GetPlayer()

  local trueHealth = player:GetHealth()
  local deltaHealth = instincts.lastHealth == 0 and 0 or trueHealth - instincts.lastHealth

  instincts.lastHealth = deltaHealth

  local info = {
    instincts = instincts,

    time = Shared.GetTime(),

    health = player:GetHealthScalar(),
    energy = player:GetEnergy() / player:GetMaxEnergy(),

    trueHealth = trueHealth,
    trueEnergy = player:GetEnergy(),

    deltaHealth = deltaHealth
  }

  if instincts.terrified and not self:DoneBeingTerrified(info) then return self.Success end
  if self:SetTerrified(info) then return self.Success end
  if instincts.spooked and not self:DoneBeingSpooked(info) then return self.Success end
  if self:SetSpooked(info) then return self.Success end

  if self:SetWants(info) then return self.Success end

  return self.Failure
end

function GorgeSetSurvivalInstinctsNode:DoneBeingTerrified(info)
  if info.instincts.wantHealth then
    info.instincts.wantHealth = info.health < 0.97
  elseif info.health < 0.7 then
    info.instincts.wantHealth = true
  end

  if info.instincts.wantEnergy then
    info.instincts.wantEnergy = info.energy < 0.97
  elseif info.energy < 0.3 then
    info.instincts.wantEnergy = true
  end

  info.instincts.terrified = info.instincts.wantHealth or info.instincts.wantEnergy
  return info.instincts.terrified
end

function GorgeSetSurvivalInstinctsNode:SetTerrified(info)
  if info.health < 0.4 then
    info.instincts.terrified = true
    info.instincts.wantHealth = true
    info.instincts.wantEnergy = true
    return true
  end

  return false
end

function GorgeSetSurvivalInstinctsNode:DoneBeingSpooked(info)
  if info.deltaHealth < -30 then
    info.instincts.spookedUntil = math.max(info.instincts.spookedUntil, info.time + 1)
    return true
  end

  if info.time < info.instincts.spookedUntil then return true end
  info.instincts.spooked = false
  return false
end

function GorgeSetSurvivalInstinctsNode:SetSpooked(info)
  if info.deltaHealth < -30 then
    Log('spooked! deltaHealth = %s', info.deltaHealth)
    info.instincts.spooked = true
    info.instincts.spookedUntil = info.time + 3
    info.instincts.wantHealth = true

    if info.instincts.wantEnergy then
      info.instincts.wantEnergy = info.energy < 0.97
    else
      info.instincts.wantEnergy = info.energy < 0.3
    end

    return true
  end

  return false
end

function GorgeSetSurvivalInstinctsNode:SetWants(info)
  if info.instincts.wantHealth then
    info.instincts.wantHealth = info.health < 0.97
  elseif info.health < 0.5 then
    info.instincts.wantHealth = true
  end

  if info.instincts.wantEnergy then
    info.instincts.wantEnergy = info.energy < 0.5
  elseif info.energy < 0.3 then
    info.instincts.wantEnergy = true
  end

  return info.instincts.wantHealth or info.instincts.wantEnergy
end
