--- Try to evolve, in order, carapace, celerity, focus

class 'LerkSetEvolveTargetNode' (BTNode)

function LerkSetEvolveTargetNode:Run(context)
  local bot = context.bot
  local player = bot:GetPlayer()

  if not player:GetIsAllowedToBuy() then return self.Failure end

  local pres = player:GetPersonalResources()

  if pres < kLerkUpgradeCost then return self.Failure end

  local existing = player:GetUpgrades()

  local needFixSpurs = true
  local needFixShells = true
  local needFixVeils = true

  for _, upg in ipairs(existing) do
    if upg == kTechId.Celerity then
      needFixSpurs = false
    elseif upg == kTechId.Carapace then
      needFixShells = false
    elseif upg == kTechId.Focus then
      needFixVeils = false
    end
  end

  if needFixSpurs then
    local _, spurs = player:GetSpurLevel()
    needFixSpurs = spurs > 0
  end

  if needFixShells then
    local _, shells = player:GetShellLevel()
    needFixShells = shells > 0
  end

  if needFixVeils then
    local _, veils = player:GetVeilLevel()
    needFixVeils = veils > 0
  end

  if not needFixSpurs and not needFixShells and not needFixVeils then return self.Failure end

  local upgrades = {}
  if needFixShells then
    pres = pres - kLerkUpgradeCost
    table.insert(upgrades, kTechId.Carapace)
  end

  if needFixSpurs and pres >= kLerkUpgradeCost then
    pres = pres - kLerkUpgradeCost
    table.insert(upgrades, kTechId.Celerity)
  end

  if needFixVeils and pres >= kLerkUpgradeCost then
    pres = pres - kLerkUpgradeCost
    table.insert(upgrades, kTechId.Focus)
  end

  context.evolveTargetTechIds = upgrades
  return self.Success
end

function LerkSetEvolveTargetNode:Finish(context, natural, res)
  if natural and res == self.Failure then
    context.evolveTargetTechIds = nil
  end
end
