--- Runs a list of nodes concurrently with the given node

class 'RunConcurrentNode' (BTNode)

function RunConcurrentNode:Setup(concurrent, real)
  self.children = concurrent
  self.child = real
  self.childStarted = false
  return self
end

function RunConcurrentNode:Initialize()
  BTNode.Initialize(self)

  for _, child in ipairs(self.children) do
    child:Initialize()
  end

  self.child:Initialize()
end

function RunConcurrentNode:Run(context)
  for cind, child in ipairs(self.children) do
    local res = child:Run(context)
    if res == self.Running then error('RunConcurrentNode expects concurrent ones are instant') end

    child:Finish(context, true, res)
    if context.debug then Log('RunConcurrentNode conc. child %s (%s) returned %s', child, cind, res == self.Success and 'success' or 'failure') end
  end

  if not self.childStarted then
    self.child:Start(context)
    self.childStarted = true
  end

  local res = self.child:Run(context)
  if res == self.Running then return res end

  if context.debug then Log('RunConcurrentNode child %s returned %s', self.child, res == self.Success and 'success' or 'failure') end
  self.child:Finish(context, true, res)
  self.childStarted = false
  return res
end

function RunConcurrentNode:Finish(context, natural, res)
  if self.childStarted then
    self.child:Finish(context, false)
    self.childStarted = false
  end
end
