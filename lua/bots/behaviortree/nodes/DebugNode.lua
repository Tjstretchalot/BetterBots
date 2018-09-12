--- Node that prints stuff out then returns the child node

class 'DebugNode' (BTNode)

function DebugNode:Setup(identifier, child)
  self.identifier = identifier
  self.child = child

  return self
end

function DebugNode:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function DebugNode:Start(context)
  Log('[DebugNode ' .. self.identifier .. '] Start (I am ' .. context.bot:GetPlayer():GetName() .. ')')

  self.child:Start(context)
end

function DebugNode:Run(context)
  local res = self.child:Run(context)

  if res == self.Running then
  elseif res == self.Success then
    Log('[DebugNode ' .. self.identifier .. '] Run result - Success')
  elseif res == self.Failure then
    Log('[DebugNode ' .. self.identifier .. '] Run result - Failure')
  else
    Log('[DebugNode ' .. self.identifier .. '] Run result - ' .. tostring(res))
  end

  return res
end

function DebugNode:Finish(context, natural, result)
  Log('[DebugNode ' .. self.identifier .. '] Finish(context, natural=' .. tostring(natural) .. ', result=' .. tostring(result) .. ')')

  self.child:Finish(context, natural, result)
end
