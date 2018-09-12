--- Selects an infested resource point that we want to claim

class 'AlienSelectResourcePointToClaimNode' (BTNode)

function AlienSelectResourcePointToClaimNode:Run(context)
  for _, info in ipairs(context.senses:GetUnclaimedResourcePointInfos()) do
    if info.hasInfestation then
      local rp = Shared.GetEntity(info.id)
      if rp then
        local room = UrgentGetLocationName(rp)
        local enemies = context.senses:GetKnownEnemiesInRoom(room)

        if #enemies == 0 then
          context.targetId = info.id
          return self.Success
        end
      end
    end
  end

  context.targetId = nil
  return self.Failure
end
