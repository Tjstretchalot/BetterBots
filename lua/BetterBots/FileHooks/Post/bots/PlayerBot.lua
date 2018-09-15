Script.Load('lua/bots/BotMapUtils.lua')

local oldOnDestroy = PlayerBot.OnDestroy
function PlayerBot:OnDestroy()
    if self.brain and self.brain.OnLoseControl then
      self.brain:OnLoseControl(self)
    end
    oldOnDestroy(self)
end

function PlayerBot:CheckForCountdown()
  if self.seenCountdown then return end

  local rules = GetGamerules()

  if rules.gameState == kGameState.Countdown then
    self.seenCountdown = true
    self.brain = nil
    return
  end

  self.seenCountdown = false
end

function PlayerBot:GenerateMove()
    PROFILE("PlayerBot:GenerateMove")

    if gBotDebug:Get("spam") then
        Log("PlayerBot:GenerateMove")
    end

    self:CheckForCountdown()
    self:_LazilyInitBrain()

    local move = Move()

    -- Brain will modify move.commands and send desired motion to self.motion
    if self.brain then

        -- always clear view each frame
        if not self.suppressBotMotion then self:GetMotion():SetDesiredViewTarget(nil) end

        self.brain:Update(self,  move)

    end

    -- Now do look/wasd

    if not self.suppressBotMotion then
      local player = self:GetPlayer()
      if player then

          local viewDir, moveDir, doJump = self:GetMotion():OnGenerateMove(player)

          move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
          move.pitch = GetPitchFromVector(viewDir)

          moveDir.y = 0
          moveDir = moveDir:GetUnit()
          local zAxis = Vector(viewDir.x, 0, viewDir.z):GetUnit()
          local xAxis = zAxis:CrossProduct(Vector(0, -1, 0))
          local moveZ = moveDir:DotProduct(zAxis)
          local moveX = moveDir:DotProduct(xAxis)

          move.move = Vector(moveX, 0, moveZ)

          if doJump then
              move.commands = AddMoveCommand(move.commands, Move.Jump)
          end

      end
    end

    return move

end
