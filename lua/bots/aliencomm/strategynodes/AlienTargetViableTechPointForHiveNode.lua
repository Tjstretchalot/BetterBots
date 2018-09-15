class 'AlienTargetViableTechPointForHiveNode' (BTNode)

function AlienTargetViableTechPointForHiveNode:Run(context)
  local senses = context.senses
  local needIdeal = senses.resources < 100

  for _, tp in ientitylist(Shared.GetEntitiesWithClassname('TechPoint')) do
    if tp.occupiedTeam ~= senses.team and tp.occupiedTeam ~= senses.enemyTeam then
      local viable, _
      if needIdeal then
        viable, _ = AlienCommUtils.IsViableHiveDrop(senses, tp)
      else
        viable, _ = AlienCommUtils.IsDefendedHiveDrop(senses, tp)

        if not viable then
          viable, _ = AlienCommUtils.IsSafeHiveDrop(senses, tp)
        end
      end
      if viable then
        context.targetId = tp:GetId()
        return self.Success
      end
    end
  end

  return self.Failure
end
