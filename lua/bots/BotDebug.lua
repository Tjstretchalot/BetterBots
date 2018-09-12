
Script.Load("lua/bots/BotUtils.lua")

if Server then

------------------------------------------
--  Convenience class for debugging facilities. Nothing bot-specific here
------------------------------------------

class "BotDebug"

function BotDebug:Initialize()
    self.vars = {}
end

function BotDebug:Get(varName)
    return self.vars[varName]
end

function BotDebug:AddBoolean(varName, defaultVal)

    if self.vars[varName] ~= nil then
        -- do not re-add, ie. when hotloading
        return
    end

    self.vars[varName] = defaultVal

    Event.Hook( string.format("Console_bot_%s", varName),
            function(client, value)
                if value == nil then
                    -- toggle
                    self.vars[varName] = not self.vars[varName]
                else
                    self.vars[varName] = (value == "true" or value == "1")
                end
                Print("%s = %s", varName, ToString(self.vars[varName]))
            end)
end

function BotDebug:AddFloat(varName, defaultVal)

    if self.vars[varName] ~= nil then
        -- do not re-add, ie. when hotloading
        return
    end

    self.vars[varName] = defaultVal

    Event.Hook( string.format("Console_bot_%s", varName),
            function(client, value)
                if tonumber(value) ~= nil then
                    self.vars[varName] = tonumber(value)
                end
                Print("%s = %s", varName, ToString(self.vars[varName]))
            end)
end

gBotDebug = BotDebug()
gBotDebug:Initialize()

gBotDebug:AddBoolean("spam", false)

------------------------------------------
--  Console commands
------------------------------------------

gDebugSelectedBots = false

Event.Hook("Console_bot_target",
        function(client, name)

            if name then
              name = '[BOT] ' .. name
              for _, bot in ipairs(gServerBots) do
                if bot:GetPlayer():GetName() == name then
                  if not bot.brain then
                    Log('found bot! but no brain to debug :(')
                  else
                    bot.brain.targettedForDebug = not bot.brain.targettedForDebug
                    Log('found bot %s; now targetted = %s', name, bot.brain.targettedForDebug)
                  end
                  return
                end
              end

              Log('found no bot with the name %s', name)
              return
            end

            Log("shooting ray..")
            local player = client:GetControllingPlayer()
            local viewDirection = player:GetViewCoords().zAxis
            local lineStart = player:GetEyePos()
            local lineEnd = lineStart + viewDirection*999
            local trace = Shared.TraceRay( lineStart, lineEnd, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, player:GetActiveWeapon()) )

            if trace.fraction < 1 then

                local hitBot = false

                if trace.entity ~= nil and trace.entity:isa("Player") then
                    local targetPlayer = trace.entity
                    if targetPlayer.botBrain then
                        hitBot = true
                        targetPlayer.botBrain.targettedForDebug = not targetPlayer.botBrain.targettedForDebug

                        Log("hit bot!; targettedForDebug = %s", targetPlayer.botBrain.targettedForDebug)
                    else
                      Log("target is not a bot (player name = %s, botBrain = %s)", trace.entity:GetName(), trace.entity.botBrain)
                    end
                end

                if not hitBot then
                    Log("did not hit bot, hit %s or %s", trace.entity, trace.surface)
                end

            else
                Log("did not hit anything")
            end

        end)

Event.Hook("Console_bot_clear",
        function(client)
            for i,bot in ipairs(gServerBots) do
                if bot.brain ~= nil then
                    bot.brain.targettedForDebug = false
                end
            end
        end)

Event.Hook("Console_bot_teamdump",
        function(client, team)

            local teamNum = team ~= nil and tonumber(team) or kMarineTeamType
            GetTeamBrain(teamNum):DebugDump()

        end)

Event.Hook("Console_bot_debugselected",
        function()

            gDebugSelectedBots = not gDebugSelectedBots
            Print("Debug selected = %s", ToString(gDebugSelectedBots) )

        end)

Event.Hook("Console_bot_hotload", function()
        Script.Load("lua/bots/MarineBrain_Data.lua", true)
        Script.Load("lua/bots/SkulkBrain_Data.lua", true)
        Script.Load("lua/bots/MarineCommanderBrain_Data.lua", true)
        Script.Load("lua/bots/AlienCommanderBrain_Data.lua", true)
        -- TODO team brain, etc.
        end)

end

Event.Hook('Console_bot_dodebug',
  function()
    for _, bot in ipairs(gServerBots) do
      if bot.brain and bot.brain:GetShouldDebug(bot) and bot.brain.Debug then
        bot.brain:Debug(bot)
      end
    end
  end)

Event.Hook('Console_bot_clearbrains',
  function()
    local count = 0
    for _, bot in ipairs(gServerBots) do
      if bot.brain ~= nil then
        bot.brain = nil
        bot:GetPlayer().botBrain = nil
        count = count + 1
      end
    end

    Log('cleared %s brains', count)
  end
)
