--=============================================================================
--
-- lua\bots\PlayerBot.lua
--
-- AI "bot" functions for goal setting and moving (used by Bot.lua).
--
-- Created by Charlie Cleveland (charlie@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
-- Updated by Dushan, Steve, 2013. The "brain" controls the higher level logic. A lot of this code is no longer used..
--
--=============================================================================

Script.Load("lua/bots/Bot.lua")
Script.Load("lua/bots/BotMotion.lua")
Script.Load("lua/bots/BotMapUtils.lua")
Script.Load("lua/bots/MarineBrain.lua")
Script.Load("lua/bots/SkulkBrain.lua")
Script.Load("lua/bots/GorgeBrain.lua")
Script.Load("lua/bots/LerkBrain.lua")
Script.Load("lua/bots/FadeBrain.lua")
Script.Load("lua/bots/OnosBrain.lua")


local kBotPersonalSettings = {
    { name = "Ashton M", isMale = true },
    { name = "Asraniel", isMale = true },
    { name = "BeigeAlert", isMale = true },
    { name = "Bonkers", isMale = true },
    { name = "Brackhar", isMale = true },
    { name = "Breadman", isMale = true },
    { name = "Chops", isMale = true },
    { name = "Comprox", isMale = true },
    { name = "CoolCookieCooks", isMale = true },
    { name = "Crispix", isMale = true },
    { name = "Darrin F.", isMale = true },
    { name = "Decoy", isMale = false },
    { name = "Explosif.be", isMale = true },
    { name = "Flaterectomy", isMale = true },
    { name = "Flayra", isMale = true },
    { name = "GISP", isMale = true },
    { name = "GeorgiCZ", isMale = true },
    { name = "Ghoul", isMale = true },
    { name = "Hanschuh", isMale = true },
    { name = "Ieptbarakat", isMale = true },
    { name = "Incredulous Dylan", isMale = true },
    { name = "Insane", isMale = true },
    { name = "Ironhorse", isMale = true },
    { name = "Joev", isMale = true },
    { name = "Katzenfleisch", isMale = true },
    { name = "Kouji_San", isMale = true },
    { name = "KungFuDiscoMonkey", isMale = true },
    { name = "Lachdanan", isMale = true },
    { name = "Loki", isMale = true },
    { name = "MGS-3", isMale = true },
    { name = "Matso", isMale = true },
    { name = "Mazza", isMale = true },
    { name = "McGlaspie", isMale = true },
    { name = "Mendasp", isMale = true },
    { name = "Michael D.", isMale = true },
    { name = "MonsieurEvil", isMale = true },
    { name = "Narfwak", isMale = true },
    { name = "Numerik", isMale = true },
    { name = "Obraxis", isMale = true },
    { name = "Ooghi", isMale = true },
    { name = "OwNzOr", isMale = true },
    { name = "Patrick8675", isMale = true },
    { name = "Railo", isMale = true },
    { name = "Rantology", isMale = false },
    { name = "Relic25", isMale = true },
    { name = "Samusdroid", isMale = true },
    { name = "Salads", isMale = true },
    { name = "ScardyBob", isMale = true },
    { name = "Squeal Like a Pig", isMale = true },
    { name = "Steelcap", isMale = true },
	{ name = "SteveRock", isMale = true },
    { name = "Steven G.", isMale = true },
    { name = "Strayan", isMale = true },
    { name = "Sweets", isMale = true },
    { name = "Tex", isMale = true },
    { name = "TychoCelchuuu", isMale = true },
    { name = "Virsoul", isMale = true },
    { name = "WDI", isMale = true },
    { name = "WasabiOne", isMale = true },
    { name = "Zaloko", isMale = true },
    { name = "Zavaro", isMale = true },
    { name = "Zefram", isMale = true },
    { name = "Zinkey", isMale = true },
    { name = "devildog", isMale = true },
    { name = "m4x0r", isMale = true },
    { name = "moultano", isMale = true },
    { name = "puzl", isMale = true },
    { name = "remi.D", isMale = true },
    { name = "sewlek", isMale = true },
    { name = "tommyd", isMale = true },
    { name = "vartija", isMale = true },
    { name = "zaggynl", isMale = true },
}
local availableBotSettings = {}

class 'PlayerBot' (Bot)

function PlayerBot:Initialize(forceTeam, active, tablePosition)
    Bot.Initialize(self, forceTeam, active, tablePosition)
end

function PlayerBot:GetPlayerOrder()
    local order
    local player = self:GetPlayer()
    if player and player.GetCurrentOrder then
        order = player:GetCurrentOrder()
    end
    return order
end

function PlayerBot:GivePlayerOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst, giver)
    local player = self:GetPlayer()
    if player and player.GiveOrder then
        player:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst, giver)
    end
end

function PlayerBot:GetPlayerHasOrder()
    local player = self:GetPlayer()
    if player and player.GetHasOrder then
        return player:GetHasOrder()
    end
    return false
end

function PlayerBot:GetNamePrefix()
    return "[BOT] "
end

function PlayerBot.GetRandomBotSetting()
    if #availableBotSettings == 0 then
        for i = 1, #kBotPersonalSettings do
            availableBotSettings[i] = i
        end

        table.shuffle(availableBotSettings)
    end

    local random = table.remove(availableBotSettings)
    return kBotPersonalSettings[random]
end

function PlayerBot:UpdateNameAndGender()
    PROFILE("PlayerBot:UpdateNameAndGender")

    if self.botSetName then return end

    local player = self:GetPlayer()
    if not player then return end

    local name = player:GetName()
    local settings = self.GetRandomBotSetting()

    self.botSetName = true

    name = self:GetNamePrefix()..TrimName(settings.name)
    player:SetName(name)

    -- set gender
    self.client.variantData = {
        isMale = settings.isMale,
        marineVariant = kMarineVariant[kMarineVariant[math.random(1, #kMarineVariant)]],
        skulkVariant = kSkulkVariant[kSkulkVariant[math.random(1, #kSkulkVariant)]],
        gorgeVariant = kGorgeVariant[kGorgeVariant[math.random(1, #kGorgeVariant)]],
        lerkVariant = kLerkVariant[kLerkVariant[math.random(1, #kLerkVariant)]],
        fadeVariant = kFadeVariant[kFadeVariant[math.random(1, #kFadeVariant)]],
        onosVariant = kOnosVariant[kOnosVariant[math.random(1, #kOnosVariant)]],
        rifleVariant = kRifleVariant[kRifleVariant[math.random(1, #kRifleVariant)]],
        pistolVariant = kPistolVariant[kPistolVariant[math.random(1, #kPistolVariant)]],
        axeVariant = kAxeVariant[kAxeVariant[math.random(1, #kAxeVariant)]],
        shotgunVariant = kShotgunVariant[kShotgunVariant[math.random(1, #kShotgunVariant)]],
        exoVariant = kExoVariant[kExoVariant[math.random(1, #kExoVariant)]],
        flamethrowerVariant = kFlamethrowerVariant[kFlamethrowerVariant[math.random(1, #kFlamethrowerVariant)]],
        grenadeLauncherVariant = kGrenadeLauncherVariant[kGrenadeLauncherVariant[math.random(1, #kGrenadeLauncherVariant)]],
        welderVariant = kWelderVariant[kWelderVariant[math.random(1, #kWelderVariant)]],
        shoulderPadIndex = 0
    }
    self.client:GetControllingPlayer():OnClientUpdated(self.client)

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

function PlayerBot:_LazilyInitBrain()

    local player = self:GetPlayer()
    if not player then return end

    if player.botBrain == nil then
      self.tree = nil
      self.brain = nil
    end

    if self.brain == nil then
        self.tree = nil
        self:GetMotion().suppressBotMotion = false
        if player:isa("Marine") then
            self.brain = MarineBrain()
        elseif player:isa("Skulk") then
            self.brain = SkulkBrain()
        elseif player:isa("Gorge") then
            self.brain = GorgeBrain()
        elseif player:isa("Lerk") then
            self.brain = LerkBrain()
        elseif player:isa("Fade") then
            self.brain = FadeBrain()
        elseif player:isa("Onos") then
            self.brain = OnosBrain()
        end

        if self.brain ~= nil then
            self.brain:Initialize()
            player.botBrain = self.brain
            self.aim = BotAim()
            self.aim:Initialize(self)
        end

    else

        -- destroy brain if we are ready room
        if player:isa("ReadyRoomPlayer") then
            self.brain = nil
            player.botBrain = nil
        end

    end

end

--
-- Responsible for generating the "input" for the bot. This is equivalent to
-- what a client sends across the network.
--
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

function PlayerBot:TriggerAlerts()
    PROFILE("PlayerBot:TriggerAlerts")

    local player = self:GetPlayer()

    local team = player:GetTeam()
    if player:isa("Marine") and team and team.TriggerAlert then

        local primaryWeapon
        local weapons = player:GetHUDOrderedWeaponList()
        if table.icount(weapons) > 0 then
            primaryWeapon = weapons[1]
        end

        -- Don't ask for stuff too often
        if not self.timeOfLastRequest or (Shared.GetTime() > self.timeOfLastRequest + 9) then

            -- Ask for health if we need it
            if player:GetHealthScalar() < .4 and (math.random() < .3) then

                team:TriggerAlert(kTechId.MarineAlertNeedMedpack, player)
                self.timeOfLastRequest = Shared.GetTime()

            -- Ask for ammo if we need it
            elseif primaryWeapon and primaryWeapon:isa("ClipWeapon") and (primaryWeapon:GetAmmo() < primaryWeapon:GetMaxAmmo()*.4) and (math.random() < .25) then

                team:TriggerAlert(kTechId.MarineAlertNeedAmmo, player)
                self.timeOfLastRequest = Shared.GetTime()

            elseif (not self:GetPlayerHasOrder()) and (math.random() < .2) then

                team:TriggerAlert(kTechId.MarineAlertNeedOrder, player)
                self.timeOfLastRequest = Shared.GetTime()

            end

        end

    end

end

function PlayerBot:GetEngagementPointOverride()
    return self:GetModelOrigin()
end

function PlayerBot:GetMotion()

    if self.motion == nil then
        self.motion = BotMotion()
        self.motion:Initialize(self:GetPlayer())
    end

    return self.motion

end

function PlayerBot:OnThink()
    PROFILE("PlayerBot:OnThink")

    Bot.OnThink(self)

    self:_LazilyInitBrain()

    if not self.initializedBot then
        self.prefersAxe = (math.random() < .5)
        self.inAttackRange = false
        self.initializedBot = true
    end

    self:UpdateNameAndGender()
end

-- Avoid doing expensive vis check too often by caching the results
function PlayerBot:GetBotCanSeeTarget(target)
    local targetId = target:GetId()

    if not self.visibleTargets then
        self.visibleTargets = {} --cache for target visibility checks
    end

    if not self.visibleTargets[targetId] or self.visibleTargets[targetId].validTill <= Shared.GetTime() then
        self.visibleTargets[targetId] = {
            visible = GetBotCanSeeTarget(self:GetPlayer(), target),
            validTill = Shared.GetTime() + kPlayerBrainTickFrametime
        }
    end

    return self.visibleTargets[targetId].visible
end

function PlayerBot:OnDestroy()
    Bot.OnDestroy(self)

    if self.brain then
      self.brain:OnLoseControl(self)
    end

    self.aim = nil
    self.brain = nil
    self.motion = nil

end
