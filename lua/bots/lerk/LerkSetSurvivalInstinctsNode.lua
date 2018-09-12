--- This node sets the survival instincts of the lerk. Survival instincts
-- are set in the context and are:
-- context.survivalInstincts = {
--   wantEnergy = boolean,
--   wantHealth = boolean,
--   spooked = boolean,
--   spookedUntilTime = number,
--   lastHealth = number,
--   terrified = boolean
-- }
--
-- Return success if we want nothing and are not spooked, failure otherwise

class 'LerkSetSurvivalInstinctsNode' (BTNode)

local kLerkTerrifiedHealthScalar = 0.4
local kLerkTerrifiedEnergyScalar = 0.1

local kSpookDuration = 1

local kWantHealthScalar = 0.7
local kWantEnergyScalar = 0.3

function LerkSetSurvivalInstinctsNode:Run(context)
  context.survivalInstincts = context.survivalInstincts or {
    wantEnergy = false,
    wantHealth = false,
    spooked = false,
    spookedUntilTime = nil,
    lastHealth = context.bot:GetPlayer():GetHealthScalar(),
    terrified = false
  }

  local instincts = context.survivalInstincts

  local bot = context.bot
  local player = bot:GetPlayer()

  local health = player:GetHealthScalar()
  local energy = player:GetEnergy() / player:GetMaxEnergy()

  if instincts.terrified then
    instincts.wantHealth = health < 0.97
    instincts.wantEnergy = energy < 0.97

    if not instincts.wantHealth and not instincts.wantEnergy then
      instincts.terrified = false
      instincts.spooked = false
      instincts.spookedUntilTime = nil
      return self.Failure
    end

    return self.Success
  end

  if health < kLerkTerrifiedHealthScalar or energy < kLerkTerrifiedEnergyScalar then
    Log('terrified!')
    instincts.terrified = true
    instincts.wantHealth = health < 0.97
    instincts.wantEnergy = energy < 0.97
    return self.Success
  end

  local haveWants = false
  if instincts.wantEnergy then
    if energy < 0.5 then
      haveWants = true
    else
      instincts.wantEnergy = false
    end
  elseif energy < kWantEnergyScalar then
    instincts.wantEnergy = true
    haveWants = true
  end

  if instincts.wantHealth then
    if health < 0.97 then
      haveWants = true
    else
      instincts.wantHealth = false
    end
  elseif health > 0.97 then
    instincts.wantHealth = false
  elseif health < kWantHealthScalar then
    instincts.wantHealth = true
    haveWants = true
  end

  local time = Shared.GetTime()
  if health - instincts.lastHealth < -45 then
    instincts.spooked = true
    instincts.spookedUntilTime = time + kSpookDuration
  end

  if instincts.spooked then
    if time > instincts.spookedUntilTime then
      instincts.spooked = false
    else
      haveWants = true
    end
  end

  return haveWants and self.Success or self.Failure
end
