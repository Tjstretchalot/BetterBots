--- Performs the children in a sequence or until one returns failure.

class 'SequenceNode' (BTNode)

function SequenceNode:Setup(children)
  self.children = children
  self.active_index = nil

  return self
end

function SequenceNode:Initialize()
  BTNode.Initialize(self)

  for _, child in ipairs(self.children) do
    child:Initialize()
  end
end

function SequenceNode:Run(context)
  local index = 1
  if self.active_index then
    local active = self.children[self.active_index]

    local res = active:Run(context)
    if res == self.Running then return res end

    if context.debug then Log('SequenceNode active_index finished; res = %s', res == self.Success and 'success' or 'failure') end
    active:Finish(context, true, res)
    if self.active_index < #self.children then
      index = self.active_index + 1
    end
    self.active_index = nil
    if index == 1 or res == self.Failure then return res end
  end

  for ind = index, #self.children do
    local child = self.children[ind]
    child:Start(context)

    local res = child:Run(context)
    if res == self.Running then
      self.active_index = ind
      if context.debug then Log('SequenceNode child %s (%s) returned running', child, ind) end
      return res
    end

    child:Finish(context, true, res)

    if res == self.Failure then
      if context.debug then Log('SequenceNode child %s (%s) returned failure', child, ind) end
      return res
    elseif context.debug then
      Log('SequenceNode child %s (%s) returned success', child, ind)
    end
  end

  if context.debug then Log('SequenceNode all children succeeded') end
  return self.Success
end

function SequenceNode:Finish(context, natural, result)
  if self.active_index then
    self.children[self.active_index]:Finish(context, false)
    self.active_index = nil
  end
end
