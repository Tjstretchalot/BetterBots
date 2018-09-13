class 'AlienSelectRecystTargetNode' (BTNode)

function AlienSelectRecystTargetNode:Initialize()
  BTNode.Initialize(self)
  self.nextScanTime = 0
end

function AlienSelectRecystTargetNode:Run(context)
  if context.senses.time < self.nextScanTime then
    context.targetId = nil
    return self.Failure
  end

  self.nextScanTime = context.senses.time + 0.9 + math.random() * 0.2
  return self:DoRun(context)
end

function AlienSelectRecystTargetNode:DoRun(context)
  for _, struct in ipairs(GetEntitiesWithMixinForTeam('InfestationTracker', context.senses.team)) do
    if LookupTechData(struct:GetTechId(), kTechDataRequiresInfestation) then
      local hasInfester = struct:GetGameEffectMask(kGameEffect.OnInfestation) or AlienCommUtils.HasNearEnoughInfester(struct)

      if not hasInfester then
        if context.debug then Log('trying to recyst %s in %s', struct, UrgentGetLocationName(struct)) end
        context.targetId = struct:GetId()
        return self.Success
      end
    end
  end

  return self.Failure
end
