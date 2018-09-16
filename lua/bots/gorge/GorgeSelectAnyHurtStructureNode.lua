class 'GorgeSelectAnyHurtStructureNode' (BTNode)

function GorgeSelectAnyHurtStructureNode:Run(context)
  for _, struct in ipairs(GetEntitiesWithMixinForTeam('Construct', context.bot:GetPlayer():GetTeamNumber())) do
    if not struct:isa('Clog') and struct:GetHealthScalar() < 0.8 then
      context.targetId = struct:GetId()
      return self.Success
    end
  end

  context.targetId = nil
  return self.Failure
end
