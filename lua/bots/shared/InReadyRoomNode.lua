--- Returns success if not in the game, false otherwise

class 'InReadyRoomNode' (BTNode)

function InReadyRoomNode:Run(context)
  local bot = context.bot
  local player = bot:GetPlayer()

  local team = player:GetTeamNumber()

  if team == kSpectatorIndex or team == kTeamReadyRoom then
    return self.Success
  end
  local gameInfo = GetGameInfoEntity()
  if not gameInfo then return self.Success end
  local state = gameInfo:GetState()
  if state == kGameState.Countdown then return self.Success end

  return self.Failure
end
