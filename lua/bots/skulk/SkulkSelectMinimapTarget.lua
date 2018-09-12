--- Select a marine thats visible on the minimap

class 'SkulkSelectMinimapTarget' (BTNode)

function SkulkSelectMinimapTarget:Run(context)
  local targets = {}

  local bot = context.bot
  local player = bot:GetPlayer()
  local eyePos = player:GetEyePos()

  local bestTarget, bestDistanceSqd = nil, nil
  for _, blip in ientitylist(Shared.GetEntitiesWithClassname('MapBlip')) do
    local ent = Shared.GetEntity(blip:GetOwnerEntityId())

    if ent:isa('Marine') then
      local dist = ent:GetOrigin():GetDistanceSquared(eyePos)
      if bestTarget == nil or dist < bestDistanceSqd then
        bestTarget, bestDistanceSqd = ent, dist
      end
    end
  end

  if bestTarget ~= nil then
    context.targetId = bestTarget:GetId()
    return self.Success
  end

  context.targetId = nil
  return self.Failure
end
