class 'AlienSelectHiveToSpawnEggsNode' (BTNode)

function AlienSelectHiveToSpawnEggsNode:Run(context)
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() and hive:GetIsAlive() and not AlienCommUtils.GetHiveHasEggs(hive) then
      context.targetId = hive:GetId()
      return self.Success
    end
  end

  return self.Failure
end
