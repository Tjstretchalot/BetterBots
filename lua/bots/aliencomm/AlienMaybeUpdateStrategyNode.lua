class 'AlienMaybeUpdateStrategyNode' (BTNode)

function AlienMaybeUpdateStrategyNode:Run(context)
  if context.senses.state ~= kGameState.Started then
    if context.strategy then
      context.strategy:Finish()
      context.strategy = nil
    end
    return self.Failure
  end

  if context.strategy and context.strategy.context.forceRecheckStrategy then
    context.strategy.context.forceRecheckStrategy = false
    context.nextCheckStrategyTime = 0
  end

  if not context.strategy or context.senses.time > context.nextCheckStrategyTime then
    context.strategyStarted = false
    context.nextCheckStrategyTime = context.senses.time + 10
    if context.debug then Log('doing full strategy check') end
    return self:DoFullStrategyCheck(context) and self.Success or self.Failure
  end

  return self.Success
end

function AlienMaybeUpdateStrategyNode:DoFullStrategyCheck(context)
  local oldStrategy = context.strategy
  local oldStrategyScore = oldStrategy and oldStrategy:GetStrategyScore(context.senses) or nil

  context.senses.debug = context.debug
  local bestStrategies, bestStrategyScore = {}, oldStrategyScore or kAlienStrategyScore.NotViable
  for _, strat in ipairs(context.strategies) do
    local score = strat:GetStrategyScore(context.senses)
    if context.debug then Log('score for doing %s is %s', strat, score) end
    if score == bestStrategyScore then
      table.insert(bestStrategies, strat)
    elseif score > bestStrategyScore then
      bestStrategies = { strat }
      bestStrategyScore = score
    end
  end
  context.senses.debug = nil

  if oldStrategy and (oldStrategyScore == bestStrategyScore) then
    if context.debug then Log('old strategy is best with a score of %s', bestStrategyScore) end
    return true
  end
  local bestStrategy = bestStrategies[math.random(1, #bestStrategies)]
  if context.debug then Log('new strategy is %s with a score of %s', bestStrategy, bestStrategyScore) end

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
  local playersForTeam = GetEntitiesForTeam('Player', playerTeamNum)
  for _, msg in ipairs(msgs) do
    Log('\'%s\' said to team: %s', playerName, msg)
    for _, player in ipairs(playersForTeam) do
      Server.SendNetworkMessage(player, 'Chat', BuildChatMessage(
        true, -- team only
        playerName,
        playerLocId,
        playerTeamNum,
        playerTeamTyp,
        msg
      ), true)
    end
  end

  context.strategy = bestStrategy
  return true
end
