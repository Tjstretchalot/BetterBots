--- This determines if a skulk wants to evolve by setting the "evolve target"
-- to something (if we want to evolve). Otherwise sets the evolve target to nil
-- Evolve target is saved as context.evolveTargetTechIds = { kTechId, ... }
--
-- Our evolution rules are as follows:
--
-- If we have enough resources for gorge AND
--   we have no gorges
-- THEN evolve gorge. (let gorge decide upgrades)
--
-- If we have enough resources for onos AND
--   we have charge AND
--   we have 3 spurs and/or 3 shells AND
--   we can afford carapace and/or celerity
-- THEN evolve onos. upgrades (in order): celerity, carapace, focus
--
-- If we have enough resources for fade AND
--   (its earlier than 10 minutes OR (we have 3 shells AND can afford carapace)) AND
--   (its earlier than 15 minutes OR we have metabolism) AND
--   (its earlier than 20 minutes OR we have advanced metabolism) AND
--   we have 2 or fewer fades (1 or 0 if fewer than 8 people)
-- THEN evolve fade. upgrades (in order): carapace, adrenaline, focus
--
-- If we have enough resources for lerk AND
--   (its earlier than 6 minutes OR (we have 3 shells OR spurs AND can afford carapace OR celerity)) AND
--   (its earlier than 10 minutes OR we have 3 or fewer resource nodes OR we have no lerks)
--   we have 2 or fewer lerks (1 or 0 if fewer than 6 people)
-- THEN evolve lerk. upgrades (in order): carapace, celerity, focus
--
-- TODO: Gorge
--
-- If we have at least one spur AND we dont have celerity
--   or we have at least one shell AND we dont have carapace
--   or we have at least one veil AND we dont have focus
-- THEN evolve skulk. upgrades: celerity, carapace, camo (focus made them worse)

class 'SkulkSetEvolveTarget' (BTNode)

function SkulkSetEvolveTarget:Initialize()
  BTNode.Initialize(self)

  self.lastCheckedTime = nil
end

function SkulkSetEvolveTarget:Run(context)
  local now = Shared.GetTime()
  if self.lastCheckedTime and now - self.lastCheckedTime < 1 then
    if context.evolveTargetTechIds then return self.Success end
    return self.Failure
  end

  self.lastCheckedTime = now

  local bot = context.bot

  local player = bot:GetPlayer()
  if not player:GetIsAllowedToBuy() then
    return self.Failure
 end

  local pres = player:GetPersonalResources()
  local _, spurs = player:GetSpurLevel()
  local _, shells = player:GetShellLevel()
  local _, veils = player:GetVeilLevel()

  local foundEmbryos = false
  for _, embryo in ientitylist(Shared.GetEntitiesWithClassname('Embryo')) do
    if embryo.gestationTypeTechId ~= kTechId.Skulk then
      foundEmbryos = true
      break
    end
  end

  if foundEmbryos then
    -- avoid too many embryos at once
    if self:TrySetTargetSkulk(context, bot, player, pres, spurs, shells, veils) then return self.Success end
  else
    if self:TrySetTargetGorge(context, bot, player, pres, spurs, shells, veils) then return self.Success
    elseif self:TrySetTargetOnos(context, bot, player, pres, spurs, shells, veils) then return self.Success
    --elseif self:TrySetTargetFade(context, bot, player, pres, spurs, shells, veils) then return self.Success
    elseif self:TrySetTargetLerk(context, bot, player, pres, spurs, shells, veils) then return self.Success
    elseif self:TrySetTargetSkulk(context, bot, player, pres, spurs, shells, veils) then return self.Success end
  end

  return self.Failure
end

function SkulkSetEvolveTarget:TrySetTargetGorge(context, bot, player, pres, tspurs, tshells, tveils)
  if pres < kGorgeCost then return false end
  local gameTimeSecs = self:GetGameTimeSeconds()
  if gameTimeSecs <= 5 then return false end -- give players a chance to gorge

  local foundGorge = false
  local allies = player:GetTeam():GetPlayers()

  for _, ally in ipairs(allies) do
    if ally:isa('Gorge') or (ally:isa('Embryo') and ally.gestationTypeTechId == kTechId.Gorge) then
      foundGorge = true
      break
    end
  end

  if foundGorge then return false end

  context.evolveTargetTechIds = { kTechId.Gorge }
  return true
end

function SkulkSetEvolveTarget:TrySetTargetOnos(context, bot, player, pres, tspurs, tshells, tveils)
  if pres < kOnosCost + kOnosUpgradeCost then return false end
  if not GetIsTechUnlocked(player, kTechId.Charge) then return false end
  if tspurs < 3 and tshells < 3 then return false end

  local upgrades = { kTechId.Onos }
  local remainingPres = pres - kOnosCost
  if tspurs == 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Celerity)
  end

  if tshells == 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Carapace)
  end

  if tveils == 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Focus)
  end

  if tspurs > 0 and tspurs < 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Celerity)
  end

  if tshells > 0 and tshells < 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Carapace)
  end

  if tveils > 0 and tveils < 3 and remainingPres >= kOnosUpgradeCost then
    remainingPres = pres - kOnosUpgradeCost
    table.insert(upgrades, kTechId.Focus)
  end

  context.evolveTargetTechIds = upgrades

  return true
end

function SkulkSetEvolveTarget:TrySetTargetFade(context, bot, player, pres, tspurs, tshells, tveils)
  if pres < kFadeCost then return false end

  local gameTimeSecs = self:GetGameTimeSeconds()
  if (gameTimeSecs >= 600) and ((tshells < 3) or (pres < kFadeCost + kFadeUpgradeCost)) then return false end
  if (gameTimeSecs >= 900) and (not GetIsTechUnlocked(player, kTechId.MetabolizeEnergy)) then return false end
  if (gameTimeSecs >= 1200) and (not GetIsTechUnlocked(player, kTechId.MetabolizeHealth)) then return false end


  local allies = player:GetTeam():GetPlayers()
  local numFades = 0
  for _, ally in ipairs(allies) do
    if ally:isa('Fade') or (ally:isa('Embryo') and ally.gestationTypeTechId == kTechId.Fade) then
      numFades = numFades + 1
    end
  end

  if numFades >= 2 or (#allies < 8 and numFades >= 1) then return false end

  local upgrades = { kTechId.Fade }
  local remainingPres = pres - kFadeCost

  if tshells == 3 and remainingPres >= kFadeUpgradeCost then
    table.insert(upgrades, kTechId.Carapace)
    remainingPres = remainingPres - kFadeUpgradeCost
  end

  if tspurs == 3 and remainingPres >= kFadeUpgradeCost then
    table.insert(upgrades, kTechId.Adrenaline)
    remainingPres = remainingPres - kFadeUpgradeCost
  end

  if tveils == 3 and remainingPres >= kFadeUpgradeCost then
    table.insert(upgrades, kTechId.Focus)
    remainingPres = remainingPres - kFadeUpgradeCost
  end

  context.evolveTargetTechIds = upgrades

  return true
end

function SkulkSetEvolveTarget:TrySetTargetLerk(context, bot, player, pres, tspurs, tshells, tveils)
  if pres < kLerkCost then return false end

  local gameTimeSecs = self:GetGameTimeSeconds()
  if (gameTimeSecs >= 360) and ((tspurs < 3 and tshells < 3) or pres < kLerkCost + kLerkUpgradeCost) then return false end

  local numLerks = 0
  local allies = player:GetTeam():GetPlayers()

  for _, ally in ipairs(allies) do
    if ally:isa('Lerk') or (ally:isa('Embryo') and ally.gestationTypeTechId == kTechId.Lerk) then
      numLerks = numLerks + 1
    end
  end

  if numLerks >= 3 then return false end
  if numLerks >= 2 and #allies < 6 then return false end

  if (gameTimeSecs >= 600) then
    if numLerks > 0 then
      local numResNodes = 0
      local teamInfo = GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())
      if table.icount(teamInfo) > 0 then
        numResNodes = teamInfo[1]:GetNumResourceTowers()
      end

      if numResNodes > 3 then return false end
    end
  end

  local upgrades = { kTechId.Lerk }
  local remainingPres = pres - kLerkCost

  if tshells == 3 and remainingPres >= kLerkUpgradeCost then
    table.insert(upgrades, kTechId.Carapace)
    remainingPres = remainingPres - kLerkUpgradeCost
  end

  if tspurs == 3 and remainingPres >= kLerkUpgradeCost then
    table.insert(upgrades, kTechId.Celerity)
    remainingPres = remainingPres - kLerkUpgradeCost
  end

  if tveils == 3 and remainingPres >= kLerkUpgradeCost then
    table.insert(upgrades, kTechId.Focus)
    remainingPres = remainingPres - kLerkUpgradeCost
  end

  context.evolveTargetTechIds = upgrades
  return true
end

function SkulkSetEvolveTarget:TrySetTargetSkulk(context, bot, player, pres, tspurs, tshells, tveils)
  local existing = player:GetUpgrades()

  local needFixSpurs = tspurs > 0
  local needFixShells = tshells > 0
  local needFixVeils = tveils > 0

  for _, upg in ipairs(existing) do
    if upg == kTechId.Celerity then
      needFixSpurs = false
    elseif upg == kTechId.Carapace then
      needFixShells = false
    elseif upg == kTechId.Camouflage then
      needFixVeils = false
    end
  end

  if not needFixSpurs and not needFixShells and not needFixVeils then return false end

  local upgrades = {}
  if needFixSpurs then
    table.insert(upgrades, kTechId.Celerity)
  end
  if needFixShells then
    table.insert(upgrades, kTechId.Carapace)
  end
  if needFixVeils then
    table.insert(upgrades, kTechId.Camouflage)
  end
  context.evolveTargetTechIds = upgrades

  return true
end

function SkulkSetEvolveTarget:GetGameTimeSeconds()
  local gameInfo = GetGameInfoEntity()
  if not gameInfo then return 0 end

  local state = gameInfo:GetState()
  if state ~= kGameState.Started then return 0 end

  return math.max(0, math.floor(Shared.GetTime()) - gameInfo:GetStartTime())
end

function SkulkSetEvolveTarget:Finish(context, natural, result)
  if natural and result == self.Failure then
    context.evolveTargetTechIds = nil
  end
end
