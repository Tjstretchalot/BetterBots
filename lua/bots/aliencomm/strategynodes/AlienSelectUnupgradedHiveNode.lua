class 'AlienSelectUnupgradedHiveNode' (BTNode)

function AlienSelectUnupgradedHiveNode:Run(context)
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if context.debug then Log('found hive %s; is upgraded = %s, upgrading = %s', hive, AlienCommUtils.IsHiveUpgraded(hive), AlienCommUtils.IsHiveUpgrading(context.senses, hive)) end
    if not AlienCommUtils.IsHiveUpgraded(hive) and not AlienCommUtils.IsHiveUpgrading(context.senses, hive) then
      context.targetId = hive:GetId()
      return self.Success
    end
  end

  context.targetId = nil
  return self.Failure
end
