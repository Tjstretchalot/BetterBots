--- BehaviorTree Node root class

class 'BTNode'

function BTNode:Initialize()
  self.Success = 1
  self.Failure = 2
  self.Running = 3
end

function BTNode:Debug()
  Log('self = ' .. ToString(self))

  if self.child then
    Log('child = ')
    self.child:Debug()
  end

  if self.children then
    Log('children (' .. #self.children .. ') (active_index = ' .. tostring(self.active_index) .. ')= ')

    if self.active_index ~= nil then
      Log('children[' .. self.active_index .. '] =')
      self.children[self.active_index]:Debug()
    end
  end

  if self.doer and self.doer:isa('BTNode') then
    Log('doer = ')
    self.doer:Debug()
  end
end

--- Called when this node becomes active and is about to be run.
-- @tparam object context the tree context (arbitrary object)
function BTNode:Start(context)
end

--- Called until it returns either success (self.Success) or failure (self.Failure)
-- @tparam object context the tree context (arbitrary object)
-- @treturn number either self.Success, self.Failure, or self.Running
function BTNode:Run(context)
  return self.Success
end

--- Called when this node is no longer active.
-- @tparam object context the tree context (arbitrary object)
-- @tparam boolean natural true if Run returned Success/Failure, false otherwise
-- @tparam number result if natural then either Success/Failure, the return of Run
function BTNode:Finish(context, natural, result)
end
