local a, b = 0, false

local ref = Menu.SliderInt("AA", "Mode", 0, 0, 1, "0 - static, 1 - dynamic")
local function lol(cmd)
    local lp = EntityList.GetLocalPlayer()
    if not lp then
        return
    end
    if lp:GetProp("m_vecVelocity"):Length2D() > 5 then
        return
    end
    if ref:Get() == 0 then
        cmd.viewangles.roll = AntiAim.GetInverterState() and 60 or -60
    end

    if ref:Get() == 1 then
        if b == false then
            a = a + 1
            if a >= 60 then
                b = true
            end
        else
            if b == true then
                a = a - 1
                if a <= -60 then
                    b = false
                end
            end
        end
        cmd.viewangles.roll = a
    end
end
Cheat.RegisterCallback("prediction", lol)
