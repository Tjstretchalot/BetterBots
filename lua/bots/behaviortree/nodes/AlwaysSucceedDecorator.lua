-- Takes in a node, runs it. If it succeeds, this succeeds. If it returns running,
-- this returns running. If it fails, this succeeds.

class 'AlwaysSucceedDecorator' (BTNode)

function AlwaysSucceedDecorator:Setup(child)
  self.child = child
  return self
end

function AlwaysSucceedDecorator:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function AlwaysSucceedDecorator:Start(context)
  self.child:Start(context)
end

function AlwaysSucceedDecorator:Run(context)
  local res = self.child:Run(context)
  if res == self.Running then return res end

  -- we want to preserve the actual result so we do this here
  self.child:Finish(context, true, res)
  if context.debug then Log('AlwaysSucceedDecorator decorated %s of %s to success', res == self.Success and 'success' or 'failure', self.child) end
  return self.Success
end
