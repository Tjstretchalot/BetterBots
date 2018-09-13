class 'CheckContextFlagNode' (BTNode)

function CheckContextFlagNode:Setup(flag)
  self.flag = flag
  return self
end

function CheckContextFlagNode:Run(context)
  if context.debug then
    Log('[CheckContextFlagNode] checking %s (value is %s)', self.flag, context[self.flag])
  end
  
  return context[self.flag] and self.Success or self.Failure
end
