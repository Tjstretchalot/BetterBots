-- Takes in a node, runs it. If it succeeds, this fails. If it returns running,
-- this returns running. If it fails, this fails.

class 'AlwaysFailDecorator' (BTNode)

function AlwaysFailDecorator:Setup(child)
  self.child = child
  return self
end

function AlwaysFailDecorator:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function AlwaysFailDecorator:Start(context)
  self.child:Start(context)
end

function AlwaysFailDecorator:Run(context)
  local res = self.child:Run(context)
  if res == self.Running then return res end

  -- we want to preserve the actual result so we do this here
  self.child:Finish(context, true, res)
  if context.debug then Log('AlwaysFailDecorator decorated %s of %s to failure', res == self.Success and 'success' or 'failure', self.child) end
  return self.Failure
end
