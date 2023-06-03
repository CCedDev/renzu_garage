function AntiDupe(coords, hash,x,y,z,w,prop)
    Wait(10)
    local move_coords = coords
    local vehicle = IsAnyVehicleNearPoint(coords.x,coords.y,coords.z,1.1)
    local nearveh = GetClosestVehicle(vector3(x,y,z), 1.000, 0, 70)
    local model = GetEntityModel(nearveh)
	if not vehicle or vehicle and model ~= hash then 
        v = CreateVehicle(hash,x,y,z,w,true,true) 
        while not DoesEntityExist(v) do Wait(1) end
        private_garages[v] = v 
        SetVehicleProp(v, prop) 
        SetEntityCollision(v,true) 
        FreezeEntityPosition(v, false) 
    end
end

RegisterNetEvent('renzu_garage:ingarage', function(t,garage,garage_id, vehicle_,housing)
    housingcustom = housing
    DoScreenFadeOut(111)
    Wait(111)
    SetEntityCoords(cache.ped,garage.coords.x,garage.coords.y,garage.coords.z,true)
    SetEntityHeading(cache.ped,garage.coords.w)
    Wait(1000)
    DoScreenFadeIn(500)
    currentprivate = garage_id
    local t = json.decode(t ~= nil and t.vehicles or '[]')
	Wait(1500)
    CreateThread(function()
        for k,vehicle in pairs(GetGamePool('CVehicle')) do -- unreliable
            vehicleinarea[GetVehicleNumberPlateText(vehicle)] = true
        end
        for k,v in pairs(vehicle_) do
            if v.vehicle ~= nil and v.taken and vehicleinarea[v.vehicle.plate] == nil then
                local ve = v.vehicle
                local hash = tonumber(ve.model)
                local count = 0
                if not HasModelLoaded(hash) then
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do
                        RequestModel(hash)
                        Citizen.Wait(10)
                    end
                end
                --local vehicle = CreateVehicle(hash,v.coord.x,v.coord.y,v.coord.z,v.coord.w,true,true)
                -- SetEntityCollision(vehicle,false)
                -- FreezeEntityPosition(vehicle, true)
                Wait(10)
                AntiDupe(vector3(v.coord.x,v.coord.y,v.coord.z),hash,v.coord.x,v.coord.y,v.coord.z,v.coord.w,v.vehicle)
            end
        end
        return
    end)
    local garage = garage
    insidegarage = true
    CreateThread(function()
        while insidegarage do
            local distance = #(GetEntityCoords(cache.ped) - vec3(garage.garage_exit.x,garage.garage_exit.y,garage.garage_exit.z))
            if distance < 3 then
                if Config.Oxlib then
                    local msg = '[E] - Exit Garage'
                    lib.showTextUI(msg, {
                        position = "left-center",
                        icon = 'car',
                        style = {
                            borderRadius = 5,
                            backgroundColor = '#212121',
                            color = 'white'
                        }
                    })
                    while #(GetEntityCoords(cache.ped) - vec3(garage.garage_exit.x,garage.garage_exit.y,garage.garage_exit.z)) < 3 do
                        if IsControlJustPressed(0,38) then
                            lib.hideTextUI()
                            local options = {}
                            table.insert(options,{
                                ['title'] = Message[32],
                                ['icon'] = 'garage',
                                ['menu'] = 'confirmout', -- event / export
                                ['description'] = 'Exit Private Garage',
                            })
                            lib.registerContext({
                                id = 'outprivate',
                                title = 'My Private Garage',
                                onExit = function()
                                end,
                                options = options,
                                {
                                    id = 'confirmout',
                                    title = 'Are you Sure?',
                                    menu = 'outprivate',
                                    options = {
                                        {
                                            title = 'Yes',
                                            description = 'Confirm to Enter',
                                            onSelect = function(args)
                                            TriggerEvent('renzu_garage:exitgarage',garage,false)
                                            end
                                        },
                                        {
                                            title = 'No',
                                            description = 'ill Stay',
                                            onSelect = function(args)
                                            end
                                        },
                                    }
                                }
                            })
                            lib.showContext('outprivate')
                            break 
                        end
                        Wait(1) 
                    end
                    lib.hideTextUI()
                else
                    local t = {
                        ['key'] = 'E', -- key
                        ['event'] = 'renzu_garage:exitgarage',
                        ['title'] = Message[7]..' [E] '..Message[11],
                        ['server_event'] = false, -- server event or client
                        ['unpack_arg'] = true, -- send args as unpack 1,2,3,4 order
                        ['fa'] = '<i class="fas fa-garage"></i>',
                        ['invehicle_title'] = 'Exit Garage',
                        ['custom_arg'] = {garage,false}, -- example: {1,2,3,4}
                    }
                    TriggerEvent('renzu_popui:drawtextuiwithinput',t)
                    while distance < 3 do
                        distance = #(GetEntityCoords(cache.ped) - garage.garage_exit)
                        Wait(500)
                    end
                    TriggerEvent('renzu_popui:closeui')
                end
            end
            Wait(1000)
        end
    end)
    CreateThread(function()
        local stats_show = nil
        while insidegarage do
            local nearveh = GetClosestVehicle(GetEntityCoords(cache.ped), 2.000, 0, 70) or GetVehiclePedIsIn(cache.ped)
            if nearveh ~= 0 and not carrymod then
                local name = 'not found'
                for k,v in pairs(vehiclesdb) do
                    if GetEntityModel(nearveh) == GetHashKey(v.model) then
                        name = v.name
                    end
                end
                if name == 'not found' then
                    name = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(nearveh)))
                end
                local vehstats = GetVehicleStats(nearveh)
                local upgrades = GetVehicleUpgrades(nearveh)
                local stats = {
                    topspeed = vehstats.topspeed / 300 * 100,
                    acceleration = vehstats.acceleration * 150,
                    brakes = vehstats.brakes * 80,
                    traction = vehstats.handling * 10,
                    name = name,
                    plate = GetVehicleNumberPlateText(nearveh),
                    engine = upgrades.engine / GetMaxMod(nearveh,11) * 100,
                    transmission = upgrades.transmission / GetMaxMod(nearveh,13) * 100,
                    brake = upgrades.brakes / GetMaxMod(nearveh,12) * 100,
                    suspension = upgrades.suspension / GetMaxMod(nearveh,15) * 100,
                    turbo = upgrades.turbo == 1 and Message[12] or upgrades.turbo == 0 and Message[14]
                }
                if stats_show == nil or stats_show ~= nearveh then
                    SendNUIMessage({
                        type = "stats",
                        perf = stats,
                        public = false,
                        show = true,
                    })
                    stats_show = nearveh
                    CreateThread(function()
                        while nearveh ~= 0 and not IsPedInAnyVehicle(cache.ped) do
                            if IsControlPressed(0,38) then
                                TriggerEvent('renzu_garage:vehiclemod',nearveh)
                                Wait(100)
                                break
                            end
                            Wait(4)                            
                        end
                        return
                    end)
                    while nearveh ~= 0 and not IsPedInAnyVehicle(cache.ped) do
                        nearveh = GetClosestVehicle(GetEntityCoords(cache.ped), 2.000, 0, 70) or GetVehiclePedIsIn(cache.ped)
                        Wait(200)
                    end
                end
            elseif stats_show ~= nil then
                stats_show = nil
                SendNUIMessage({
                    type = "stats",
                    perf = stats,
                    show = false,
                })
            end
            local inv = garage.garage_inventory
            local inventorydis = #(GetEntityCoords(cache.ped) - vector3(inv.x,inv.y,inv.z))
            if inventorydis < 3 and not carrymode and not carrymod then
                if Config.Oxlib then
                    local msg = Message[7]..' [E] '..Message[15]
                    lib.showTextUI(msg, {
                    position = "left-center",
                    icon = 'car',
                        style = {
                            borderRadius = 5,
                            backgroundColor = '#212121',
                            color = 'white'
                        }
                    })
                    CreateThread(function()
                        while inventorydis < 3 and not carrymode do
                            inventorydis = #(GetEntityCoords(cache.ped) - vector3(inv.x,inv.y,inv.z))
                            Wait(500)
                        end
                        return
                    end)
                    while inventorydis < 3 and not carrymode do
                        if IsControlJustPressed(0,38) then
                            TriggerEvent('renzu_garage:openinventory',currentprivate,activeshare)
                            break
                        end
                        Wait(1)
                    end
                    lib.hideTextUI()
                end
            end
            if IsPedInAnyVehicle(cache.ped) then
                local vehicle = GetVehiclePedIsIn(cache.ped)
                local vehicle_prop = GetVehicleProperties(vehicle)
                local ent = Entity(vehicle).state
                vehicle_prop.plate = ent.plate or vehicle_prop.plate
                if Config.Oxlib then
                    local msg = '[E] - Choose Vehicle'
                    lib.showTextUI(msg, {
                        position = "left-center",
                        icon = 'car',
                        style = {
                            borderRadius = 5,
                            backgroundColor = '#212121',
                            color = 'white'
                        }
                    })
                    while IsPedInAnyVehicle(cache.ped) do
                        if IsControlJustPressed(0,38) then
                            DoScreenFadeOut(1)
                            TriggerServerEvent('renzu_garage:exitgarage',garage,vehicle_prop,garage_id,true,activeshare)
                        end
                        if stats_show ~= nil then
                            stats_show = nil
                            SendNUIMessage({
                                type = "stats",
                                perf = stats,
                                show = false,
                            })
                        end
                        Wait(1)
                    end
                    lib.hideTextUI()
                end
                TriggerEvent('renzu_popui:closeui')
            end
            Wait(1000)
        end
    end)
end)

function LoadAnim(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(10)
	end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

RegisterNetEvent('renzu_garage:syncstate', function(plate,sender)
    if GetPlayerServerId(PlayerId()) == sender then return end
    for k,vehicle in pairs(GetGamePool('CVehicle')) do
        if string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper() == plate then
            ReqAndDelete(vehicle)
        end
    end
end)

RegisterNetEvent('renzu_garage:choose', function(t,garage)
    insidegarage = false
    vehicleinarea = {}
    private_garages = {}
	Wait(2000)
    local hash = tonumber(t.model)
    local count = 0
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            RequestModel(hash)
            Citizen.Wait(10)
        end
    end
    local vehicle
    if housingcustom then
        lib.requestModel(t.model)
        local netid = lib.callback.await('renzu_garage:CreateVehicle',false,{
            model = t.model,
            coord = vec3(housingcustom.housing.x,housingcustom.housing.y,housingcustom.housing.z),
            heading = housingcustom.housing.w,
            type = GetVehicleType(t.model),
            prop = t
        })
        vehicle = NetworkGetEntityFromNetworkId(netid)
    else
        lib.requestModel(t.model)
        local netid = lib.callback.await('renzu_garage:CreateVehicle',false,{
            model = t.model,
            coord = vec3(garage.buycoords.x,garage.buycoords.y,garage.buycoords.z),
            heading = garage.buycoords.w,
            type = GetVehicleType(t.model),
            prop = t
        })
        vehicle = NetworkGetEntityFromNetworkId(netid)
    end
    SetVehicleOwned(vehicle)
    SetVehicleProp(vehicle, t)
    NetworkFadeInEntity(vehicle,1)
    SetPedConfigFlag(cache.ped,429,false)
    Wait(10)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    housingcustom = nil
    DoScreenFadeOut(1)
	DoScreenFadeIn(333)
end)

function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = cache.ped
    local plyCoords = GetEntityCoords(ply, 0)

    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(target, 0)
            local distance = #(targetCoords - plyCoords)
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

RegisterNetEvent('renzu_garage:exitgarage', function(t,exit)
    if not exit then
        insidegarage = false
        local closestplayer, dis = GetClosestPlayer()
        if closestplayer == -1 and dis < 33 or closestplayer == -1 and dis == -1 then
            local empty = true
            for k,v in pairs(private_garages) do
                empty = false
                ReqAndDelete(v)
            end
            if empty then
                for k,v in pairs(vehicleinarea) do
                    ReqAndDelete(v)
                end
            end
            vehicleinarea = {}
            private_garages = {}
        end
        TriggerServerEvent('renzu_garage:exitgarage',t)
    else
        local empty = true
        local closestplayer, dis = GetClosestPlayer()
        if closestplayer == -1 and dis > 33 or closestplayer ~= -1 and dis > 33 or closestplayer == -1 and dis == -1 then
            for k,vehicle in pairs(GetGamePool('CVehicle')) do -- unreliable
                vehicleinarea[string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1'):upper()] = vehicle
            end
            if empty then
                for k,v in pairs(vehicleinarea) do
                    ReqAndDelete(v)
                end
            end
        end
        vehicleinarea = {}
        private_garages = {}
        --DoScreenFadeOut(1)
        if housingcustom then
            SetEntityCoords(cache.ped,housingcustom.housing.x,housingcustom.housing.y,housingcustom.housing.z)
        else
            SetEntityCoords(cache.ped,t.buycoords.x,t.buycoords.y,t.buycoords.z)
        end
        Wait(3500)
        housingcustom = nil
        DoScreenFadeIn(100)
    end
end)

RegisterNetEvent('renzu_garage:opengaragemenu', function(garageid,v)
    local garage,t = garageid,v
    if not Config.Oxlib then
        TriggerServerCallback_("renzu_garage:isgarageowned",function(owned,share)
            local multimenu = {}
            if not owned then
                firstmenu = {
                    [Message[27]] = {
                        ['title'] = Message[27]..' - $'..v.cost..'',
                        ['fa'] = '<i class="fad fa-question-square"></i>',
                        ['type'] = 'event', -- event / export
                        ['content'] = 'renzu_garage:buygarage',
                        ['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,t}, arg_unpack = true},
                    },
                }
                multimenu[Message[29]] = firstmenu
                if share and share.garage == garageid then
                    activeshare = share
                    sharing = {
                        [Message[28]] = {
                            ['title'] = Message[28],
                            ['fa'] = '<i class="fad fa-question-square"></i>',
                            ['type'] = 'event', -- event / export
                            ['content'] = 'renzu_garage:gotogarage',
                            ['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,share,true}, arg_unpack = true},
                        },
                    }
                    multimenu[Message[30]] = sharing
                end
                TriggerEvent('renzu_contextmenu:insertmulti',multimenu,Message[29],false,Message[29])
                TriggerEvent('renzu_contextmenu:show')
            elseif not owned and IsPedInAnyVehicle(cache.ped) then
                Config.Notify( 'error',Message[31])
                opened = true
            elseif owned and IsPedInAnyVehicle(cache.ped) then
                local vehicle = GetVehiclePedIsIn(cache.ped)
                local prop = GetVehicleProperties(vehicle)
                local ent = Entity(vehicle).state
                prop.plate = ent.plate or prop.plate
                ReqAndDelete(vehicle)
                TriggerServerEvent('renzu_garage:storeprivate',garageid,v, prop)
                opened = true
            elseif owned then
                secondmenu = {
                    [Message[32]] = {
                        ['title'] = Message[32],
                        ['fa'] = '<i class="fad fa-garage"></i>',
                        ['type'] = 'event', -- event / export
                        ['content'] = 'renzu_garage:gotogarage',
                        ['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,t,false}, arg_unpack = true},
                    },
                }
                multimenu['My Garage'] = secondmenu
                if share and share.garage == garageid then
                    activeshare = share
                    sharing = {
                        [Message[28]] = {
                            ['title'] = Message[28],
                            ['fa'] = '<i class="fad fa-question-square"></i>',
                            ['type'] = 'event', -- event / export
                            ['content'] = 'renzu_garage:gotogarage',
                            ['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,share,true}, arg_unpack = true},
                        },
                    }
                    multimenu[Message[30]] = sharing
                end
                TriggerEvent('renzu_contextmenu:insertmulti',multimenu,Message[29],false,Message[29])
                TriggerEvent('renzu_contextmenu:show')
            end
        end,garageid,v)
    else
        TriggerServerCallback_("renzu_garage:isgarageowned",function(owned,share)
            local multimenu = {}
            --local garage,v = table.unpack(v)
            if not owned then
                local options = {}
                table.insert(options,{
                    ['title'] = Message[27]..' - $'..v.cost..'',
                    ['icon'] = 'square',
                    ['menu'] = 'confirmprivate', -- event / export
                    ['description'] = 'Buy This Private Garage',
                })
                if share and share.garage == garageid then
                    table.insert(options,{
                        ['title'] = Message[28],
                        ['icon'] = 'square',
                        onSelect = function(args)
                            TriggerServerEvent('renzu_garage:gotogarage',garageid,share,true)
                        end,
                        ['description'] = 'Buy This Private Garage',
                    })
                end
                lib.registerContext({
                    id = 'privategarage',
                    title = 'Private Garage',
                    onExit = function()
                    end,
                    options = options,
                    {
                        id = 'confirmprivate',
                        title = 'Are you Sure?',
                        menu = 'privategarage',
                        options = {
                            {
                                title = 'Yes',
                                description = 'Confirm to Buy',
                                onSelect = function(args)
                                  TriggerServerEvent('renzu_garage:buygarage',garageid,t)
                                end
                            },
                            {
                                title = 'No',
                                description = 'ill come back later',
                                onSelect = function(args)
                                end
                            },
                        }
                    }
                })
                lib.showContext('privategarage')
            elseif not owned and IsPedInAnyVehicle(cache.ped) then
                Config.Notify( 'error',Message[31])
                opened = true
            elseif owned and IsPedInAnyVehicle(cache.ped) then
                local vehicle = GetVehiclePedIsIn(cache.ped)
                local prop = GetVehicleProperties(vehicle)
                local ent = Entity(vehicle).state
                prop.plate = ent.plate or prop.plate
                ReqAndDelete(vehicle)
                TriggerServerEvent('renzu_garage:storeprivate',garageid,t, prop)
                opened = true
            elseif owned then
                local options = {}
                table.insert(options,{
                    ['title'] = Message[32],
                    ['icon'] = 'garage',
                    ['menu'] = 'confirmenter', -- event / export
                    ['description'] = 'Enter Private Garage',
                })
                if share and share.garage == garageid then
                    table.insert(options,{
                        ['title'] = Message[28],
                        ['icon'] = 'square',
                        onSelect = function(args)
                            TriggerServerEvent('renzu_garage:gotogarage',garageid,share,true)
                        end,
                        ['description'] = 'Visit Private Garage',
                    })
                end
                lib.registerContext({
                    id = 'gotoprivate',
                    title = 'My Private Garage',
                    onExit = function()
                    end,
                    options = options,
                    {
                        id = 'confirmenter',
                        title = 'Are you Sure?',
                        menu = 'gotoprivate',
                        options = {
                            {
                                title = 'Yes',
                                description = 'Confirm to Enter',
                                onSelect = function(args)
                                  TriggerServerEvent('renzu_garage:gotogarage',garageid,t,false)
                                end
                            },
                            {
                                title = 'No',
                                description = 'ill come back later',
                                onSelect = function(args)
                                end
                            },
                        }
                    }
                })
                lib.showContext('gotoprivate')
            end
        end,garage,v)
    end
end)