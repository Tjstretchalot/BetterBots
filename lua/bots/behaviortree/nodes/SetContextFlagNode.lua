class 'SetContextFlagNode' (BTNode)

function SetContextFlagNode:Setup(flag, newValue)
  self.flag = flag
  self.newValue = newValue
  return self
end

function SetContextFlagNode:Run(context)
  if context.debug then
    Log('[SetContextFlagNode] setting %s to %s (was %s)', self.flag, self.newValue, context[self.flag])
  end
  
  context[self.flag] = self.newValue
  return self.Success
end
