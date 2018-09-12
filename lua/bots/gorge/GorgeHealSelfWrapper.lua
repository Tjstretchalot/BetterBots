class 'GorgeHealSelfWrapper' (BTNode)

function GorgeHealSelfWrapper:Setup(child)
  self.child = child
  return self
end

function GorgeHealSelfWrapper:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function GorgeHealSelfWrapper:Start(context)
  self.child:Start(context)
end

function GorgeHealSelfWrapper:Run(context)
  local res = self.child:Run(context)

  local player = context.bot:GetPlayer()
  if player:GetHealthScalar() < 0.97 then
    context.move.commands = AddMoveCommand(context.move.commands, Move.SecondaryAttack)
  end

  return res
end

function GorgeHealSelfWrapper:Finish(context, natural, res)
  self.child:Finish(context, natural, res)
end
