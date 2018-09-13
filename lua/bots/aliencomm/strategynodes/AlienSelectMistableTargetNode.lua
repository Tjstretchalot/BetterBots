class 'AlienSelectMistableTargetNode' (BTNode)

function AlienSelectMistableTargetNode:Run(context)
  for _, embryo in ientitylist(Shared.GetEntitiesWithClassname('Embryo')) do
    if embryo:GetIsAlive() and embryo.gestationTypeTechId ~= kTechId.Skulk then
      if not AlienCommUtils.IsTargetMisted(context.senses, embryo) then
        context.targetId = embryo:GetId()
        if context.debug then Log('AlienSelectMistableTargetNode - Found mistable embryo') end
        return self.Success
      end
    end
  end

  for _, harvInfo in ipairs(context.senses:GetHarvesterInfos()) do
    if not harvInfo.hasInfestation then
      local harv = Shared.GetEntity(harvInfo.id)
      if harv and not AlienCommUtils.IsTargetMisted(context.senses, harv) then
        context.targetId = harvInfo.id
        if context.debug then Log('AlienSelectMistableTargetNode - Found mistable harvester') end
        return self.Success
      end
    end
  end

  if context.debug then Log('AlienSelectMistableTargetNode - Found no mistables') end
  return self.Failure
end
