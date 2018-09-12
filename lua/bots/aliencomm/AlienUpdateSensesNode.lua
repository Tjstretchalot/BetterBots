class 'AlienUpdateSensesNode' (BTNode)

function AlienUpdateSensesNode:Run(context)
  context.senses:Update(context.bot:GetPlayer())

  return context.senses.state == kGameState.Started and self.Success or self.Failure
end
