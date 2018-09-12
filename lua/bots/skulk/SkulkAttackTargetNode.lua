--- Attempt to attack the target (context.targetId).

class 'SkulkAttackTargetNode' (BTNode)

function SkulkAttackTargetNode:CanXenocide(info)
  return info.energy > kXenocideEnergyCost and GetIsTechUnlocked(info.player, kTechId.Xenocide) and info.target:isa('Player')
end

function SkulkAttackTargetNode:HaveXenocideSelected(info)
  return info.activeWeapon:isa('XenocideLeap')
end

function SkulkAttackTargetNode:IsXenociding(info)
  for _, wep in ipairs(info.weapons) do
    if wep:isa('XenocideLeap') and wep.xenociding then return true end
  end
  return false
end

function SkulkAttackTargetNode:SelectXenocide(info)
  info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon3)
end

function SkulkAttackTargetNode:LeapWontCollideInstantly(info)
  local extents = Vector(0.5, 0.5, 0.5)
  local trace = Shared.TraceBox(extents, info.myOrigin, (info.viewTarget or info.viewCoords).zAxis * 8, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterAll())
  return trace.fraction < 0.9
end

function SkulkAttackTargetNode:CanLeap(info)
  return info.energy >= kLeapEnergyCost and GetIsTechUnlocked(info.player, kTechId.Leap) and self:LeapWontCollideInstantly(info)
end

function SkulkAttackTargetNode:SecondaryAttack(info)
  info.energy = info.energy - kLeapEnergyCost
  info.move.commands = AddMoveCommand(info.move.commands, Move.SecondaryAttack)
end

function SkulkAttackTargetNode:CanSeeTarget(info)
  if info.distanceToTouch < 1 then return true end

  local trace = Shared.TraceRay(info.eyePos, info.engagePoint, CollisionRep.LOS, PhysicsMask.All, EntityFilterOneAndIsa(info.player, 'Babbler'))

  return trace.fraction > 0.9 or trace.entity == info.target or (info.target.GetActiveWeapon and trace.entity == info.target:GetActiveWeapon())
end

function SkulkAttackTargetNode:MoveTowardTarget(info)
  info.bot:GetMotion():SetDesiredMoveTarget(info.engagePoint)
end

function SkulkAttackTargetNode:StopMoving(info)
  info.bot:GetMotion():SetDesiredMoveTarget(nil)
end

function SkulkAttackTargetNode:CanBiteTarget(info)
  return info.distanceToTouch < 1.5 and info.energy > kBiteEnergyCost
end

function SkulkAttackTargetNode:HaveBiteSelected(info)
  return info.activeWeapon:isa('BiteLeap') and not info.activeWeapon:isa('XenocideLeap')
end

function SkulkAttackTargetNode:SelectBite(info)
  info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon1)
end

function SkulkAttackTargetNode:CanParasite(info)
  return info.energy >= kParasiteEnergyCost
end

function SkulkAttackTargetNode:HaveParasiteSelected(info)
  return info.activeWeapon:isa('Parasite')
end

function SkulkAttackTargetNode:SelectParasite(info)
  info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon2)
end

function SkulkAttackTargetNode:ViewTarget(info)
  info.viewTarget = (info.engagePoint - info.myOrigin):GetUnit()
  info.bot:GetMotion():SetDesiredViewTarget(info.engagePoint)
end

function SkulkAttackTargetNode:PrimaryAttack(info)
  info.move.commands = AddMoveCommand(info.move.commands, Move.PrimaryAttack)
  info.energy = info.energy - info.activeWeapon:GetEnergyCost()
end

function SkulkAttackTargetNode:IsTargetStationary(info)
  if info.isTargetStationary == nil then
    info.isTargetStationary = not info.target:isa('Player') and not info.target:isa('MAC') and not info.target:isa('ARC')
  end
  return info.isTargetStationary
end

function SkulkAttackTargetNode:IsTargetParasited(info)
  -- not parasiteable = parasited for our purposes
  return (not HasMixin(info.target, "ParasiteAble")) or info.target:GetIsParasited()
end

function SkulkAttackTargetNode:CanJump(info)
  return info.player:GetIsOnGround()
end

function SkulkAttackTargetNode:Jump(info)
  info.move.commands = AddMoveCommand(info.move.commands, Move.Jump)
end

function SkulkAttackTargetNode:Run(context)
  if not context.targetId then return self.Failure end
  context.lastAttackTime = context.lastAttackTime or 0
  context.lastLeapTime = context.lastLeapTime or 0

  local target = Shared.GetEntity(context.targetId)

  if not target then
    context.targetId = nil
    return self.Success
  end

  if not target:GetIsAlive() then
    context.targetId = nil
    return self.Success
  end

  local bot = context.bot
  local move = context.move
  local player = bot:GetPlayer()

  local myOrigin = player:GetOrigin()
  local eyePos = player:GetEyePos()
  local viewCoords = player:GetViewAngles():GetCoords()
  local engagePoint = target:GetEngagementPoint()
  local targetOrigin = target:GetOrigin()
  local energy = player:GetEnergy()

  local time = Shared.GetTime()
  local timeSinceLastAttack = time - context.lastAttackTime
  local timeSinceLastLeap = time - context.lastLeapTime

  local activeWeapon = player:GetActiveWeapon()
  local weapons = player:GetWeapons()

  local distanceSqd = myOrigin:GetDistanceSquared(engagePoint)
  local distanceToTouch = GetDistanceToTouch(eyePos, target)

  local info = {
    bot = bot,
    move = move,
    player = player,
    target = target,
    myOrigin = myOrigin,
    eyePos = eyePos,
    viewCoords = viewCoords,
    engagePoint = engagePoint,
    targetOrigin = targetOrigin,
    energy = energy,
    time = time,
    timeSinceLastAttack = timeSinceLastAttack,
    timeSinceLastLeap = timeSinceLastLeap,
    activeWeapon = activeWeapon,
    weapons = weapons,
    distanceSqd = distanceSqd,
    distanceToTouch = distanceToTouch
  }

  if self:CanSeeTarget(info) then
    self:ViewTarget(info)

    if not self:CanBiteTarget(info) or not self:IsTargetStationary(info) then
      self:MoveTowardTarget(info)
    else
      self:StopMoving(info)
    end

    if self:CanBiteTarget(info) then
      if not self:IsTargetStationary(info) then
        if self:CanJump(info) then
          self:Jump(info)
        end
      end
      if self:HaveBiteSelected(info) then
        self:PrimaryAttack(info)
      else
        self:SelectBite(info)
      end
    else
      if self:CanXenocide(info) and not self:IsXenociding(info) then
        if self:HaveXenocideSelected(info) then
          self:PrimaryAttack(info)
        else
          self:SelectXenocide(info)
        end
      elseif not self:IsTargetParasited(info) and self:CanParasite(info) then
        if self:HaveParasiteSelected(info) then
          self:PrimaryAttack(info)
        else
          self:SelectParasite(info)
        end
      end

      if not self:IsTargetStationary(info) then
        if self:CanLeap(info) then
          self:SecondaryAttack(info)
        elseif self:CanJump(info) then
          self:Jump(info)
        end
      end
    end
  else
    self:MoveTowardTarget(info)
  end

  return self.Running
end
