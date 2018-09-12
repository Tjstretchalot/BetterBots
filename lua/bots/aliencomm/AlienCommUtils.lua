AlienCommUtils = {}

function AlienCommUtils.ExecuteTechId(commander, techId, pos, hostEntity, targetId)
  local techNode = commander:GetTechTree():GetTechNode( techId )

  local allowed, canAfford = hostEntity:GetTechAllowed(techId, techNode, commander)
  if not (allowed and canAfford) then return end

  -- We should probably use ProcessTechTreeAction instead here...
  commander.isBotRequestedAction = true -- Hackapalooza...
  local success, keepGoing = commander:ProcessTechTreeActionForEntity(
          techNode,
          position,
          Vector(0,1,0),  -- normal
          true,   -- isCommanderPicked
          0,  -- orientation
          hostEntity,
          nil, -- trace
          targetId
          )

  return success
end
