-- Parent class for brains that use behavior trees

Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/BotDebug.lua")

Script.Load("lua/bots/behaviortree/BehaviorTree.lua")
Script.Load('lua/bots/shared/LoadAll.lua')

class 'BTBrain'

function BTBrain:Initialize()
end

function BTBrain:GetShouldDebug(bot)
  local player = bot:GetPlayer()
  local isSelected = false

  if player.GetIsSelected then
    isSelected = player:GetIsSelected( kMarineTeamType ) or player:GetIsSelected( kAlienTeamType )
  end

  if isSelected and gDebugSelectedBots then
      return true
  elseif self.targettedForDebug then
      return true
  else
      return false
  end
end

function BTBrain:OnAssumeControl(bot, move)
  bot.tree = self:CreateTree()
  bot.tree.context.bot = bot
  bot.tree.context.move = move
  bot.tree:Start()
  bot.treeStarted = true
  bot.suppressBotMotion = false
end

function BTBrain:OnIsDead(bot)
  if bot.treeStarted then
    bot.tree:Finish()
    bot.treeStarted = false
    bot:GetMotion():SetDesiredMoveTarget(nil)
    bot:GetMotion():SetDesiredViewTarget(nil)
  end
end

function BTBrain:OnRespawn(bot)
  bot.tree:Start()
  bot.treeStarted = true
end

function BTBrain:Debug(bot)
  local player = bot:GetPlayer()
  Log('DEBUGGING ' .. player:GetName())
  if bot.tree then
    bot.tree.root:Debug()
  else
    Log('No tree')
  end
  Log('END DEBUGGING ' .. player:GetName())
end


function BTBrain:OnLoseControl(bot)
  if bot.tree and bot.treeStarted then
    bot.tree:Finish()
  end
  bot.tree = nil
  bot.treeStarted = nil
  bot.brain = nil
  bot:GetMotion():SetDesiredMoveTarget(nil)
  bot:GetMotion():SetDesiredViewTarget(nil)
end

function BTBrain:Update(bot, move)
  PROFILE("BTBrain:Update")

  local player = bot:GetPlayer()

  if not player:isa(self:GetExpectedClass()) then
    self:OnLoseControl(bot)
    return false
  end

  if not player:GetIsAlive() then
    self:OnIsDead(bot)
    return
  end

  if not bot.tree then
    self:OnAssumeControl(bot, move)
  else
    bot.tree.context.bot = bot
    bot.tree.context.move = move

    if not bot.treeStarted then
      self:OnRespawn(bot)
    end
  end

  local debug = self:GetShouldDebug(bot)
  bot.tree.context.debug = debug
  bot.tree:Run()
  if debug then
    self:Debug(bot)
  end
end


-- Console commands
local function GetIsClientAllowedToManage(client)
    return client == nil    -- console command from server
    or Shared.GetCheatsEnabled()
    or Shared.GetDevMode()
    or client:GetIsLocalClient()    -- the client that started the listen server
end

function OnConsoleForceBotEvolve(client, upgrade)
  if not GetIsClientAllowedToManage(client) then return end

  if not gServerBots or #gServerBots == 0 then
    Shared.Message('No bots to evolve!')
    return
  end

  local upgrade = StringToEnum(kTechId, upgrade) or kTechId.Lerk

  Shared.Message('Evolving all to ' .. EnumToString(kTechId, upgrade))
  for _, bot in ipairs(gServerBots) do
    local player = bot:GetPlayer()
    if player:isa('Alien') then
      player:SetResources(100)
      player:ProcessBuyAction({ upgrade })

      if bot.tree and bot.treeStarted then
        bot.tree:Finish({ bot = bot, move = Move() }, false)
      end

      bot.tree = nil
      bot.treeStarted = nil
      bot.brain = nil

      bot:GetMotion():SetDesiredMoveTarget(nil)
      bot:GetMotion():SetDesiredViewTarget(nil)
    end
  end
end

function OnConsoleSetBotRes(client, resources)
  if not GetIsClientAllowedToManage(client) then return end

  if not gServerBots or #gServerBots == 0 then
    Shared.Message('No bots to manage!')
    return
  end

  resources = resources and tonumber(resources) or 15
  for _, bot in ipairs(gServerBots) do
    local player = bot:GetPlayer()
    if player:isa('Alien') then
      player:SetResources(resources)
    end
  end
end

Event.Hook("Console_evolvebots", OnConsoleForceBotEvolve)
Event.Hook("Console_setbotres", OnConsoleSetBotRes)
