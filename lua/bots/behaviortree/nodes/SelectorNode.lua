--- Goes through its children in order until one succeeds, then does that.
-- Unlike some variations of selector nodes, a result of 'Running' does NOT
-- cause the previous nodes to be reevaluated next tick. It will simply
-- continue running that node until it gets success/failure, then continue
-- from there.
--
-- The reason this is done is because it's not so much previous things becoming
-- good to do that makes it a good idea to change what your doing, it's what
-- you are doing suddenly becoming not good to do. If I'm biting a resource node,
-- it really doesn't matter if my hive is getting attacked, but if a marine
-- walks in that would be salient. Thus the only one that should be able to
-- cancel an action is the action itself
--
-- Some would say that means this is a finite state machine. Maybe so, bite me.

class 'SelectorNode' (BTNode)

function SelectorNode:Setup(children)
  self.children = children
  self.active_index = nil
  return self
end

function SelectorNode:Initialize()
  BTNode.Initialize(self)

  for _, child in ipairs(self.children) do
    child:Initialize()
  end
end

function SelectorNode:Run(context)
  local index = 1
  if self.active_index then
    local active = self.children[self.active_index]
    local res = active:Run(context)
    if res == self.Running then return res end

    if context.debug then Log('SelectorNode active index finished; res = ' .. tostring(res)) end
    active:Finish(context, true, res)

    if self.active_index < #self.children then
      index = self.active_index + 1
    end

    self.active_index = nil
    if res == self.Success then return self.Success end
  end

  for ind = index, #self.children do
    local child = self.children[ind]
    child:Start(context)
    local res = child:Run(context)

    if res == self.Running then
      self.active_index = ind
      if context.debug then Log('SelectorNode child %s (%s) returned running', child, ind) end
      return res
    else
      child:Finish(context, true, res)
      if res == self.Failure and context.debug then Log('SelectorNode child %s (%s) returned failure', child, ind) end
      if res == self.Success then
        if context.debug then Log('SelectorNode child %s (%s) returned success', child, ind) end
        return res
      end
    end
  end

  if context.debug then Log('SelectorNode all children failed') end
  return self.Failure
end

function SelectorNode:Finish(context, natural, result)
  if self.active_index then
    local active = self.children[self.active_index]
    active:Finish(context, false)
    self.active_index = nil
  end
end
