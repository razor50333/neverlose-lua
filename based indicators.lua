local indi = Menu.MultiCombo("Skeet Indicators", "Select to display", {"Fake With Circle", "FL With Circle", "AA With Line", "Shot/Miss Percent", "FL Text indicator", "FOV", "AW (Autowall)", "BUY (Buy Zone Indicator)", "Body Aim", "Safe Points", "Damage", "Hitchance", "Freestand", "At Targets", "Hide Shots", "Dormant Aimbot", "Fake Ping", "Lag Compensation", "Fake Duck", "Bomb Info", "Double Tap"}, 0)
local da_style = Menu.Switch("Skeet Indicators", "Show Dormant Aimbot Indicator Always", false)
local hs_style = Menu.Combo("Skeet Indicators", "Hide Shots Indicator Style", {"ONSHOT", "HS", "OSAA", "HIDE"}, 0)
local fs_style = Menu.Combo("Skeet Indicators", "Freestand Indicator Style", {"FREESTAND", "FS"}, 0)
local dmg_style = Menu.Combo("Skeet Indicators", "Damage Indicator Style", {"Damage: ", "DMG: ", "DMG", "Damage Value", ": DMG"}, 0)
local dmgs = Menu.Switch("Skeet Indicators", "Show Damage Indicator Always", false)
local hc_style = Menu.Combo("Skeet Indicators", "Hitchance Indicator Style", {"Hitchance: ", "HC: ", "HC", "Hitchance Value", ": HC%"}, 0)
local hcs = Menu.Switch("Skeet Indicators", "Show Hitchance Indicator Always", false)
local ba_style = Menu.Combo("Skeet Indicators", "Body Aim Indicator Style", {"BODY", "BAIM", "FB", "BA"}, 0)
local sp_style = Menu.Combo("Skeet Indicators", "Safe Points Indicator Style", {"SAFE", "SP"}, 0)
local hit_style = Menu.Combo("Skeet Indicators", "Shot/Miss Percent Style", {"Style 1", "Style 2", "Style 3"}, 0)
local fake_style = Menu.Combo("Skeet Indicators", "Fake With Circle Style", {"DSY", "FAKE", "AA"}, 1)
local fl_style = Menu.Combo("Skeet Indicators", "FL With Circle Style", {"Choke Value", "FL"}, 1)
local aa_color = Menu.ColorEdit("Skeet Indicators", "AA With Line Color", Color.RGBA(154, 176, 250, 255))
Menu.Button("Skeet Indicators", "Load Skeet Default Indicators", "Load Skeet Default Indicators",function() indi:SetInt(2031616) end)

local font = 
{
    calibrib = Render.InitFont("Calibri Bold", 30),
    pixel9 = Render.InitFont("Smallest Pixel-7", 9)
}

local HC = Menu.FindVar("Aimbot","Ragebot","Accuracy","Hit Chance")
local DMG = Menu.FindVar("Aimbot","Ragebot","Accuracy","Minimum Damage")
local AW = Menu.FindVar("Aimbot","Ragebot","Accuracy","Autowall")
local FOV = Menu.FindVar("Aimbot","Ragebot","Main","FOV")
local BA = Menu.FindVar("Aimbot","Ragebot","Misc","Body Aim")
local SP = Menu.FindVar("Aimbot","Ragebot","Misc","Safe Points")
local DT = Menu.FindVar("Aimbot","Ragebot","Exploits","Double Tap")
local SW = Menu.FindVar("Aimbot","Anti Aim","Misc","Slow Walk")
local HS = Menu.FindVar("Aimbot","Ragebot","Exploits","Hide Shots")
local YAW = Menu.FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
local PING = Menu.FindVar("Miscellaneous", "Main", "Other", "Fake Ping")
local FD = Menu.FindVar("Aimbot","Anti Aim","Misc","Fake Duck")

local velocity = function(ent)
    local speed_x = ent:GetProp("DT_BasePlayer","m_vecVelocity[0]")
    local speed_y = ent:GetProp("DT_BasePlayer","m_vecVelocity[1]")
    local speed = math.sqrt(speed_x * speed_x + speed_y * speed_y)
    return speed
end

local curTime = GlobalVars.curtime
local interface_ptr = ffi.typeof('void***')
local rawivengineclient = Utils.CreateInterface('engine.dll', 'VEngineClient014')
local ivengineclient = ffi.cast(interface_ptr, rawivengineclient)
local get_net_channel_info, net_channel = ffi.cast('void*(__thiscall*)(void*)', ivengineclient[0][78]), nil
local INetChannelInfo = ffi.cast('void***', get_net_channel_info(ivengineclient)) 
local GetNetChannel = function(INetChannelInfo)
    if INetChannelInfo == nil then
        return end

    return {
        latency = {
            crn = function(flow) return INetChannelInfo:GetLatency(flow) end,
            average = function(flow) return INetChannelInfo:GetAvgLatency(flow) end,
        }
    }
end
local outgoing, incoming, incoming_latency

local id, OldChoke, toDraw0, toDraw1, toDraw2, toDraw3, toDraw4, hitted, reg_shot, on_plant_time, fill, text, planting_site, planting = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "", "", false

Cheat.RegisterCallback('registered_shot', function(shot) 
    if shot.reason == 0 then hitted = hitted + 1 end 
    reg_shot = reg_shot + 1 
end)

local calcDist = function(pos1, pos2)
	local lx = pos1.x
	local ly = pos1.y
	local lz = pos1.z
	local tx = pos2.x
	local ty = pos2.y
	local tz = pos2.z
	local dx = lx - tx
	local dy = ly - ty
	local dz = lz - tz
	return math.sqrt(dx * dx + dy * dy + dz * dz);
end

local normalize_yaw = function(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

Cheat.RegisterCallback("draw", function()
    fake_style:SetVisible(indi:GetBool(1))
    fl_style:SetVisible(indi:GetBool(2))
    aa_color:SetVisible(indi:GetBool(3))
    hit_style:SetVisible(indi:GetBool(4))
    ba_style:SetVisible(indi:GetBool(9))
    sp_style:SetVisible(indi:GetBool(10))
    dmg_style:SetVisible(indi:GetBool(11))
    dmgs:SetVisible(indi:GetBool(11))
    hc_style:SetVisible(indi:GetBool(12))
    hcs:SetVisible(indi:GetBool(12))
    fs_style:SetVisible(indi:GetBool(13))
    hs_style:SetVisible(indi:GetBool(15))
    da_style:SetVisible(indi:GetBool(16))

    local lp = EntityList.GetClientEntity(EngineClient.GetLocalPlayer())
    if not lp then return end 
    
    local delta_to_draw = math.abs(normalize_yaw(AntiAim.GetCurrentRealRotation() % 360 - AntiAim.GetFakeRotation() % 360)) / 2

    local chocking, invert, fake = ClientState.m_choked_commands, AntiAim.GetInverterState() == false, string.format("%.1f", delta_to_draw)

    local sc = EngineClient.GetScreenSize()
    local x, y = sc.x/100 + 2, sc.y/1.48 - 5
    local ay = 0
    local binds = Cheat.GetBinds()
    local dmg = false
    local hc = false
	local da = false
    for i = 1, #binds do
        local bind = binds[i]
        if bind:GetName() == 'Minimum Damage' and bind:IsActive() then
            dmg = true
            cur_dmg = bind:GetValue()
        end
        if bind:GetName() == 'Hit Chance' and bind:IsActive() then
            hc = true
            cur_hc = bind:GetValue()
        end
		if bind:GetName() == 'Dormant Aimbot' and bind:IsActive() then
            da = true
        end
    end

    local Render_Indicators = function(text, ay, color, size, fonts)
        ts = Render.CalcTextSize(text, size, fonts)
        Render.GradientBoxFilled(Vector2.new(13, y + ay), Vector2.new(13 + (ts.x) / 2, y + ay + 28), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65))
        Render.GradientBoxFilled(Vector2.new(13 + (ts.x) / 2, y + ay), Vector2.new(13 + (ts.x), y + ay + 28), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0), Color.RGBA(0, 0, 0, 65), Color.RGBA(0, 0, 0, 0))
        Render.Text(text, Vector2.new(x, y + 5 + ay), Color.new(0, 0, 0, 255), size, fonts)
        Render.Text(text, Vector2.new(x, y + 4 + ay), color, size, fonts)
    end

    if indi:GetBool(1) and lp:GetPlayer():IsAlive() then
        text = {"DSY", "FAKE", "AA"}
        id = fake_style:GetInt()+1
        ts = Render.CalcTextSize(text[id], 22, font.calibrib)
        clr = Color.RGBA(math.floor(255 - (fake * 2.29824561404)), math.floor(fake * 3.42105263158), math.floor(fake * 0.22807017543), 255)
        Render_Indicators(text[id], ay, clr, 22, font.calibrib)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(0, 0, 0, 255), 5, 0, 365)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, clr, 4, 0, (fake/60)*360)
        ay = ay - 35
    end

    if indi:GetBool(2) and lp:GetPlayer():IsAlive() then
        text = {chocking, "FUHRERLAG"}
        id = fl_style:GetInt()+1
        ts = Render.CalcTextSize(tostring(text[id]), 22, font.calibrib)
        Render_Indicators(tostring(text[id]), ay, Color.RGBA(135, 147, 255, 255), 22, font.calibrib)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(0, 0, 0, 255), 5, 0, 365)
        Render.Circle(Vector2.new(x + ts.x+13, y+ay+ts.y/2+3), 7, 32, Color.RGBA(135, 147, 255, 255), 4, 0, (chocking/14)*360)
        ay = ay - 35
    end

    if indi:GetBool(3) and lp:GetPlayer():IsAlive() then
        ts = Render.CalcTextSize("AA", 22, font.calibrib)
        clr = Color.new(aa_color:GetColor().r, aa_color:GetColor().g, aa_color:GetColor().b, 1)
        Render_Indicators("AA", ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        Render.BoxFilled(Vector2.new(x, y + ts.y + ay - 1), Vector2.new(x + ts.x, y + 4 + ts.y + ay), Color.RGBA(0, 0, 0, 255))
        Render.BoxFilled(invert and Vector2.new(x+ts.x/2, y+ts.y+ay) or Vector2.new(x+ts.x/2-fake/4.4, y+ts.y+ay), invert and Vector2.new(x+ts.x/2+fake/4.4, y+3+ts.y+ay) or Vector2.new(x+ts.x/2, y+3+ts.y+ay), clr)
        ay = ay - 35
    end

    if indi:GetBool(4) and lp:GetPlayer():IsAlive() then
        local percent = hitted > 0 and reg_shot > 0 and (hitted/reg_shot)*100 or 100
        local miss = reg_shot-hitted
        text = {hitted.." / "..reg_shot.." ("..string.format("%.1f", percent)..")", miss.."/"..math.floor(percent).."%", hitted.." / "..reg_shot.." = "..math.floor(percent).."%"}
        id = hit_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        if hit_style:GetInt() == 2 then
            ay = ay - 35
            Render_Indicators("hit: "..hitted, ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
            ay = ay - 35
            Render_Indicators("miss: "..miss, ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        end
        ay = ay - 35
    end

    if indi:GetBool(5) and lp:GetPlayer():IsAlive() then
        if chocking < OldChoke then
            toDraw0 = toDraw1
            toDraw1 = toDraw2
            toDraw2 = toDraw3
            toDraw3 = toDraw4
            toDraw4 = OldChoke
        end
        OldChoke = chocking
        Render_Indicators(string.format('%i-%i-%i-%i-%i',toDraw4,toDraw3,toDraw2,toDraw1,toDraw0), ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(6) and lp:GetPlayer():IsAlive() then
        Render_Indicators("FOV: "..FOV:GetInt().."°", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(7) and lp:GetPlayer():IsAlive() then
        Render_Indicators("AW", ay, AW:GetBool() and Color.RGBA(132, 195, 16, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if lp:GetProp("m_bInBuyZone") and indi:GetBool(8) and lp:GetPlayer():IsAlive() then
        Render_Indicators("BUY", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibri)
        Render.Text("YOU HAVE: "..lp:GetProp("m_iAccount"), Vector2.new(x-8, y + 20 + ay), Color.RGBA(235 ,235, 235, 255), 9, font.pixel9, true)
        ay = ay - 35
    end

    if BA:GetInt() == 2  then
        text = {"XANE MONKEY MODE", "BAIM", "FB", "BA"}
        id = ba_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if SP:GetInt() == 2 then
        text = {"SHOOT FIRST AND DIE NIGGER", "SP"}
        id = sp_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
	end

   
        if dmg == true or dmgs:GetBool() then
            if dmgs:GetBool() then dmg_val = DMG:GetInt() else dmg_val = cur_dmg end
            dmg_val = math.floor(dmg_val)
            text = {"TOE RAPE: " .. dmg_val, "NIGGER DAMAGE MODE: " .. dmg_val, "DMG", dmg_val, dmg_val < 101 and ": "..dmg_val or ": HP+"..(dmg_val-100)}
            clr = {Color.RGBA(235, 235, 235, 255), Color.RGBA(255, 255, 255, 150), Color.RGBA(132, 195, 16, 255), Color.RGBA(235, 235, 235, 255), Color.RGBA(80, 255, 80, 255)}
            id = dmg_style:GetInt()+1
            Render_Indicators(tostring(text[id]), ay, clr[id], 22, font.calibrib)
            ay = ay - 35
        end
  

    if indi:GetBool(12) then
        if hc == true or hcs:GetBool() then
            if hcs:GetBool() then hc_val = HC:GetInt() else hc_val = cur_hc end
            hc_val = math.floor(hc_val)
            text = {"Hitchance: " .. hc_val, "HC: " .. hc_val, "HC", hc_val, ": "..hc_val.."%"}
            clr = {Color.RGBA(235, 235, 235, 255), Color.RGBA(200, 185, 255, 255), Color.RGBA(132, 195, 16, 255), Color.RGBA(235, 235, 235, 255), Color.RGBA(80, 255, 80, 255)}
            id = hc_style:GetInt()+1
            Render_Indicators(tostring(text[id]), ay, clr[id], 22, font.calibrib)
            ay = ay - 35
	    end
    end

	if YAW:GetInt() == 5 then
        text = {"FUHRERSTANDING", "FS"}
        id = fs_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(235 ,255, 235, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if YAW:GetInt() == 4 then
        Render_Indicators("AIMED AT NEAREST NIGGER", ay, Color.RGBA(255, 255, 255, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if HS:GetBool() then
        text = {"NO ONSHOT FOR YOU NIGGER", "HS", "OSAA", "HIDE"}
        id = hs_style:GetInt()+1
        Render_Indicators(text[id], ay, Color.RGBA(132, 195, 16, 255), 22, font.calibrib)
        ay = ay - 35
	end

    if da == true and indi:GetBool(16) or da_style:GetBool() and indi:GetBool(16) then
        Render_Indicators("DA", ay, Color.RGBA(132, 195, 16, 255), 22, font.calibri)
        ay = ay - 35
    end   

    if PING:GetInt() > 0 then
        INetChannelInfo = EngineClient.GetNetChannelInfo()
        net_channel = GetNetChannel(INetChannelInfo)
        outgoing, incoming = net_channel.latency.crn(0), net_channel.latency.crn(1)
        ping = math.max(0, (incoming-outgoing)*1000)
        Render_Indicators("PING", ay, Color.RGBA(math.floor(255 - ((ping / 189 * 60) * 2.29824561404)), math.floor((ping / 189 * 60) * 3.42105263158), math.floor((ping / 189 * 60) * 0.22807017543), 255), 22, font.calibrib)
        ay = ay - 35
	end

    if bit.band(lp:GetPlayer():GetProp("m_fFlags"), bit.lshift(1,0)) == 0 and indi:GetBool(18) and lp:GetPlayer():IsAlive() then  
        Render_Indicators("NO BACKTRACK FOR YOU MONKEY", ay, DT:GetBool() and Exploits.GetCharge() == 1 and Color.RGBA(32, 195, 16, 255) or velocity(lp)/chocking >= 20.84 and Color.RGBA(255, 0, 0, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end  

    if FD:GetBool() and indi:GetBool(19) then
        Render_Indicators("INVISIBLE CHOKE CROUCH", ay, Color.RGBA(0 ,100, 235, 255), 22, font.calibrib)
        ay = ay - 35
    end

    if indi:GetBool(20) then 
        local c4 = EntityList.GetEntitiesByClassID(129)[1];
        if c4 ~= nil then
            local time = ((c4:GetProp("m_flC4Blow") - GlobalVars.curtime)*10) / 10
            local timer = string.format("%.1f", time)
            local defused = c4:GetProp("m_bBombDefused")
            if math.floor(timer) > 0 and not defused then
                local defusestart = c4:GetProp("m_hBombDefuser") ~= 4294967295
                local defuselength = c4:GetProp("m_flDefuseLength")
                local defusetimer = defusestart and math.floor((c4:GetProp("m_flDefuseCountDown") - GlobalVars.curtime)*10) / 10 or -1
                if defusetimer > 0 then
                    local color = math.floor(timer) > defusetimer and Color.RGBA(58, 191, 54, 160) or Color.RGBA(252, 18, 19, 125)
                    
                    local barlength = (((sc.y - 50) / defuselength) * (defusetimer))
                    Render.BoxFilled(Vector2.new(0.0, 0.0), Vector2.new(16, sc.y), Color.RGBA(25, 25, 25, 160))
                    Render.Box(Vector2.new(0.0, 0.0), Vector2.new(16, sc.y), Color.RGBA(25, 25, 25, 160))
                    
                    Render.BoxFilled(Vector2.new(0, sc.y - barlength), Vector2.new(16, sc.y), color)
                end
                
                local bombsite = c4:GetProp("m_nBombSite") == 0 and "A" or "B"
                local health = lp:GetProp("m_iHealth")
                local armor = lp:GetProp("m_ArmorValue")
                local willKill = false
                local eLoc = c4:GetProp("m_vecOrigin")
                local lLoc = lp:GetProp("m_vecOrigin")
                local distance = calcDist(eLoc, lLoc)
                local a = 450.7
                local b = 75.68
                local c = 789.2
                local d = (distance - b) / c;

                local damage = a * math.exp(-d * d)
                if armor > 0 then
                    local newDmg = damage * 0.5;
    
                    local armorDmg = (damage - newDmg) * 0.5
                    if armorDmg > armor then
                        armor = armor * (1 / .5)
                        newDmg = damage - armorDmg
                    end
                    damage = newDmg;
                end
                local dmg = math.ceil(damage)
                    if dmg >= health then
                    willKill = true
                else 
                    willKill = false
                end
                Render_Indicators(bombsite.." - "..string.format("%.1f", timer).."s", ay, Color.RGBA(235 ,235, 235, 255), 22, font.calibrib)
                ay = ay - 35
                if lp then
                    if willKill == true then
                        Render_Indicators("FATAL", ay, Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
                        ay = ay - 35
                    elseif damage > 0.5 then
                        Render_Indicators("-"..dmg.." HP", ay, Color.RGBA(210, 216, 112, 255), 22, font.calibrib)
                        ay = ay - 35
                    end
                end
            end
        end
        if planting then
            Render_Indicators(planting_site, ay, Color.RGBA(210, 216, 112, 255), 22, font.calibrib)
            fill = 3.125 - (3.125 + on_plant_time - GlobalVars.curtime)
            if(fill > 3.125) then
                fill = 3.125
            end
            ts = Render.CalcTextSize(planting_site, 22, font.calibrib)
            Render.Circle(Vector2.new(x + ts.x+18, y+ay+ts.y/2+3), 8, 32, Color.RGBA(0, 0, 0, 255), 4, 0, 360)
            Render.Circle(Vector2.new(x + ts.x+18, y+ay+ts.y/2+3), 8, 32, Color.RGBA(235 ,235, 235, 255), 3, 0, (fill/3.3)*360)
            ay = ay - 35
        end
    end        
		
	if DT:GetBool() and indi:GetBool(21) then
        Render_Indicators("MENTAL ILLNESS", ay, Exploits.GetCharge() == 1 and Color.RGBA(235 ,235, 235, 255) or Color.RGBA(255, 0, 0, 255), 22, font.calibrib)
        ay = ay - 35
    end
end)

Cheat.RegisterCallback("events", function(e)
	local player_resource = EntityList.GetPlayerResource()
	if e:GetName() == "bomb_abortplant" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "bomb_defused" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "bomb_planted" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	if e:GetName() == "round_prestart" then
		planting = false
		fill = 0
		on_plant_time = 0
		planting_site = ""
	end
	
	if e:GetName() == "bomb_beginplant" then
		on_plant_time = GlobalVars.curtime
		planting = true
		local m_bombsiteCenterA = player_resource:GetProp("DT_CSPlayerResource", "m_bombsiteCenterA")
		local m_bombsiteCenterB = player_resource:GetProp("DT_CSPlayerResource", "m_bombsiteCenterB")
		
		local player = EntityList.GetPlayerForUserID(e:GetInt("userid", 0))
		local localPos = player:GetRenderOrigin()
		local dist_to_a = localPos:DistTo(m_bombsiteCenterA)
		local dist_to_b = localPos:DistTo(m_bombsiteCenterB)
		
		planting_site = dist_to_a < dist_to_b and "Bombsite A" or "Bombsite B"
	end
end)
