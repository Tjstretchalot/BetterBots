class 'AlienSelectIdleEvoChamberNode' (BTNode)

function AlienSelectIdleEvoChamberNode:Run(context)
  for _, chamber in ientitylist(Shared.GetEntitiesWithClassname('EvolutionChamber')) do
    if chamber.ownerId ~= Entity.invalidId then
      local owner = Shared.GetEntity(chamber.ownerId)
      if owner and owner:GetIsAlive() and owner:GetIsBuilt() then
        if not AlienCommUtils.IsResearching(context.senses, chamber) then
          context.targetId = chamber:GetId()
          return self.Success
        end
      end
    end
  end

  return self.Failure
end
