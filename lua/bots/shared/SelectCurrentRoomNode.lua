--- Selects the current room and plots it in context.selectedRoomName

class 'SelectCurrentRoomNode' (BTNode)

function SelectCurrentRoomNode:Run(context)
  local bot = context.bot
  local player = bot:GetPlayer()

  local loc = GetLocationForPoint(player:GetOrigin()) -- for some reason this works a lot better than player:GetLocationName()
  local locNm = loc and loc:GetName() or nil
  if not locNm then return self.Failure end
  context.selectedRoomName = locNm
  return self.Success
end
