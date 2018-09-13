class 'AlienSelectLocationForUpgradeNode' (BTNode)

function AlienSelectLocationForUpgradeNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienSelectLocationForUpgradeNode:Initialize()
  BTNode.Initialize(self)
  assert(self.techId)
end

function AlienSelectLocationForUpgradeNode:Run(context)
  local bestHive, bestHiveApproxEffectiveHealth = nil, nil
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    local health = hive:GetHealth()
    local armor = hive:GetArmor()
    local effectHealth = health + armor * 2 -- good enough

    if not bestHive or effectHealth < bestHiveApproxEffectiveHealth then
      bestHive, bestHiveApproxEffectiveHealth = hive, effectHealth
    end
  end

  if not bestHive then return self.Failure end

  local upgLoc = AlienCommUtils.GetRandomBuildPosition(self.techId, bestHive:GetOrigin(), 10)
  if not upgLoc then return self.Failure end

  context.location = upgLoc
  return self.Success
end
