class 'RepeatUntilFailureNode' (BTNode)

function RepeatUntilFailureNode:Setup(child)
  self.child = child
  self.childStarted = false
  return self
end

function RepeatUntilFailureNode:Initialize()
  BTNode.Initialize(self)
  self.child:Initialize()
end

function RepeatUntilFailureNode:Run(context)
  if not self.childStarted then
    self.child:Start(Context)
    self.childStarted = true
  end

  local res = self.child:Run(context)
  if res == self.Running then
    if context.debug then Log('RepeatUntilFailureNode child %s returned running -> returning running', self.child) end
    return res
  end

  self.childStarted = false
  self.child:Finish(context, true, res)

  if res == self.Success then
    if context.debug then Log('RepeatUntilFailureNode child %s returned success -> returning running', self.child) end
    return self.Running
  end

  if context.debug then Log('RepeatUntilFailureNode child %s returned failure (%s) -> returning failure', self.child, res) end
  return res
end

function RepeatUntilFailureNode:Finish(context, natural, res)
  if self.childStarted then
    self.child:Finish(context, false)
    self.childStarted = false
  end
end
