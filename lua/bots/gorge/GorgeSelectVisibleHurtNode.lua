class 'GorgeSelectVisibleHurtNode' (BTNode)

function GorgeSelectVisibleHurtNode:Run(context)
  local player = context.bot:GetPlayer()
  local team = player:GetTeamNumber()

  -- range is pretty small so we can prob see them
  for _, live in ipairs(GetEntitiesWithMixinWithinRange('Live', player:GetOrigin(), 10)) do
    if live ~= player and live:GetTeamNumber() == team and live:GetIsAlive() and (not live.GetIsBuilt or live:GetIsBuilt()) and live:GetHealthScalar() < 0.97 and not live:isa('Clog') then
      context.targetId = live:GetId()
      return self.Success
    end
  end

  return self.Failure
end
