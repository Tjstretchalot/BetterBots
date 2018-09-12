--- Inverts the result of the child

class 'InvertDecorator' (BTNode)

function InvertDecorator:Setup(child)
  self.child = child
  return self
end

function InvertDecorator:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function InvertDecorator:Start(context)
  self.child:Start(context)
end

function InvertDecorator:Run(context)
  local res = self.child:Run(context)

  if res == self.Success then
    if context.debug then Log('InvertDecorator decorated child %s success to failure', self.child) end
    return self.Failure end
  if res == self.Failure then
    if context.debug then Log('InvertDecorator decorated child %s failure to success', self.child) end
    return self.Success
  end
  return res
end

function InvertDecorator:Finish(context, natural, res)
  if not natural then
    self.child:Finish(context, false)
  else
    local inverted = res == self.Success and self.Failure or self.Success
    self.child:Finish(context, true, inverted)
  end
end
