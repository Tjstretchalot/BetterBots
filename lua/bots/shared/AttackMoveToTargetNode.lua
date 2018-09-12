--- Generic attack move. Uses a specific attack node, move node, and set
-- target node

class 'AttackMoveToTargetNode' (BTNode)

function AttackMoveToTargetNode:Initialize()
  BTNode.Initialize(self)

  if not self.attackTargetNodeClass then error('Missing attack node') end
  if not self.moveNodeClass then error('Missing move node') end
  if not self.setTargetNodeClass then error('Missing set target node class') end
  if not self.scanDelay then error('Missing scan delay') end

  self.setTargetNode = self.setTargetNodeClass()
  self.setTargetNode:Initialize()
  self.attackTargetNode = self.attackTargetNodeClass()
  self.attackTargetNode:Initialize()
  self.attacking = false
  self.attackContext = nil

  self.lastScan = 0

  self.moveNode = self.moveNodeClass()
  self.moveNode:Initialize()
  self.moveNodeStarted = false
end

function AttackMoveToTargetNode:Run(context)
  if context.debug then Log('attack move node!') end

  if self.attacking then
    self.attackContext.bot = context.bot
    self.attackContext.move = context.move

    local res = self.attackTargetNode:Run(self.attackContext)
    if res == self.Running then return self.Running end

    self.attackTargetNode:Finish(self.attackContext, true, res)
    self.attacking = false
    self.attackContext = nil
  end

  local time = Shared.GetTime()
  local timeSinceScan = time - self.lastScan

  if timeSinceScan >= self.scanDelay then
    self.lastScan = time

    local newContext = { bot = context.bot, move = context.move }
    self.setTargetNode:Start(newContext)
    local res = self.setTargetNode:Run(newContext)
    if res == self.Success then
      if self.moveNodeStarted then
        self.moveNode:Finish(context, false)
        self.moveNodeStarted = false
      end

      self.setTargetNode:Finish(newContext, true, res)
      self.attacking = true
      self.attackContext = newContext
      self.attackTargetNode:Start(self.attackContext)
      return self.Running
    elseif res == self.Failure then
      self.setTargetNode:Finish(newContext, true, res)
    else
      error('we dont expect setTargetNode to return Running! res=' .. tostring(res))
    end
  end

  if not self.moveNodeStarted then
    self.moveNode:Start(context)
    self.moveNodeStarted = true
  end

  local res = self.moveNode:Run(context)
  if res == self.Success or res == self.Failure then
    self.moveNode:Finish(context, true, res)
    self.moveNodeStarted = false
    if context.debug then Log('AttackMoveToTargetNode move node finished, res = %s', res == self.Success and 'success' or 'failure') end
    return res
  end

  if context.debug then Log('AttackMoveToTargetNode still moving with %s (res = %s)', self.moveNode, res) end
  return res
end

function AttackMoveToTargetNode:Finish(context, natural, res)
  if self.attacking then
    self.attackTargetNode:Finish(self.attackContext, false)
    self.attacking = false
    self.attackContext = nil
  end

  if self.moveNodeStarted then
    self.moveNode:Finish(context, false)
    self.moveNodeStarted = false
  end

  self.lastScan = 0
end
