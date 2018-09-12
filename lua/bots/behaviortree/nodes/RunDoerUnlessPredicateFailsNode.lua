--- Takes two children, a predicate and a doer.
-- Runs the doer to completion or until the predicate fails. This does NOT
-- run the doer more than once

class 'RunDoerUnlessPredicateFailsNode' (BTNode)

function RunDoerUnlessPredicateFailsNode:Setup(predicate, doer)
  self.predicate = predicate
  self.doer = doer

  self.doerStarted = false
  return self
end

function RunDoerUnlessPredicateFailsNode:Initialize()
  BTNode.Initialize(self)

  self.predicate:Initialize()
  self.doer:Initialize()
end

function RunDoerUnlessPredicateFailsNode:Run(context)
  self.predicate:Start(context)

  local res = self.predicate:Run(context)
  if res == self.Running then error('Predicate cannot return running!') end

  self.predicate:Finish(context, true, res)

  if res == self.Failure then
    if context.debug then Log('RunDoerUnlessPredicateFailsNode predicate %s returned failure -> returning failure', self.predicate) end
    return self.Failure
  end
  if res ~= self.Success then error('Predicate returned bad result: ' .. tostring(res)) end
  if context.debug then Log('RunDoerUnlessPredicateFailsNode predicate %s returned success', self.predicate) end

  if not self.doerStarted then
    self.doerStarted = true
    self.doer:Start(context)
  end

  res = self.doer:Run(context)

  if res ~= self.Running then
    if context.debug then Log('RunDoerUnlessPredicateFailsNode doer %s returned %s -> doer finished', self.doer, (res == self.Success and 'success' or 'failure')) end
    self.doer:Finish(context, true, res)
    self.doerStarted = false
  end

  return res
end

function RunDoerUnlessPredicateFailsNode:Finish(context, natural, res)
  if self.doerStarted then
    self.doer:Finish(context, false)
    self.doerStarted = false
  end
end
