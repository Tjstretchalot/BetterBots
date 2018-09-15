class 'AlienRunStrategyNode' (BTNode)

function AlienRunStrategyNode:Run(context)
  if not context.strategy then return self.Failure end

  context.strategy.context.bot = context.bot
  context.strategy.context.move = context.move
  context.strategy.context.senses = context.senses
  context.strategy.context.debug = context.debug

  if context.debug then Log('Running strategy %s', context.strategy) end
  context.strategy:Run()
  return self.Success
end
