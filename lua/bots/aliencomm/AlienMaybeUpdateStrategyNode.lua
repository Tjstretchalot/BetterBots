class 'AlienMaybeUpdateStrategyNode' (BTNode)

function AlienMaybeUpdateStrategyNode:Run(context)
  if context.senses.state ~= kGameState.Started then
    if context.strategy then
      context.strategy:Finish()
      context.strategy = nil
    end
    return self.Failure
  end

  if not context.strategy or context.senses.time > context.nextCheckStrategyTime then
    context.strategyStarted = false
    context.nextCheckStrategyTime = context.senses.time + 10
    return self:DoFullStrategyCheck(context) and self.Success or self.Failure
  end

  return self.Success
end

function AlienMaybeUpdateStrategyNode:DoFullStrategyCheck(context)
  local oldStrategy = context.strategy

  local bestStrategy, bestStrategyScore = nil, nil
  for _, strat in ipairs(context.strategies) do
    local score = strat:GetStrategyScore(context.senses)
    if not bestStrategy or score > bestStrategyScore then
      bestStrategy, bestStrategyScore = strat, score
    end
  end

  if oldStrategy and (not bestStrategy or oldStrategy:GetStrategyScore(context.senses) == bestStrategyScore) then
    return true
  end

  if not bestStrategy then return false end
  if oldStrategy then oldStrategy:Finish() end

  bestStrategy.context.bot = context.bot
  bestStrategy.context.move = context.move
  bestStrategy.context.senses = context.senses
  bestStrategy:Start()
  local msgs = bestStrategy:GetStartMessages()

  local player = context.bot:GetPlayer()
  local playerName = player:GetName()
  local playerLocId = player.locationId
  local playerTeamNum = player:GetTeamNumber()
  local playerTeamTyp = player:GetTeamType()
  for _, msg in ipairs(msgs) do
    Server.SendNetworkMessage('Chat', BuildChatMessage(
      true, -- team only
      playerName,
      playerLocId,
      playerTeamNum,
      playerTeamTyp,
      msg
    ), true)
  end

  context.strategy = bestStrategy
  return true
end
