ESX = exports["es_extended"]:getSharedObject()

local group = nil

Citizen.CreateThread(function()
	while true do 
		group = ESX.GetPlayerData().group
		Citizen.Wait(1500)
	end
end)

local InSpectatorMode	= false
local TargetSpectate	= nil
local LastPosition		= nil
local polarAngleDeg		= 0;
local azimuthAngleDeg	= 90;
local radius			= -3.5;
local cam 				= nil
local PlayerDate		= {}
local ShowInfos			= false

function polar3DToWorld3D(entityPosition, radius, polarAngleDeg, azimuthAngleDeg)
	-- convert degrees to radians
	local polarAngleRad   = polarAngleDeg   * math.pi / 180.0
	local azimuthAngleRad = azimuthAngleDeg * math.pi / 180.0

	local pos = {
		x = entityPosition.x + radius * (math.sin(azimuthAngleRad) * math.cos(polarAngleRad)),
		y = entityPosition.y - radius * (math.sin(azimuthAngleRad) * math.sin(polarAngleRad)),
		z = entityPosition.z - radius * math.cos(azimuthAngleRad)
	}

	return pos
end

function spectate(target)
	ESX.TriggerServerCallback('esx_spectate:getPlayerData', function(player)
		if not InSpectatorMode then
			LastPosition = GetEntityCoords(GetPlayerPed(-1))
		end

		local playerPed = GetPlayerPed(-1)

		SetEntityCollision(playerPed, false, false)
		SetEntityVisible(playerPed, false)
		
		SetEntityCoords(playerPed, player.position, 0.0, 0.0, 0.0, false)

		PlayerData = player
		if ShowInfos then
			SendNUIMessage({
				type = 'infos',
				data = PlayerData
			})	
		end

		Citizen.CreateThread(function()
			if not DoesCamExist(cam) then
				cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
			end

			SetCamActive(cam, true)
			RenderScriptCams(true, false, 0, true, true)

			InSpectatorMode = true
			TargetSpectate  = target

		end)
	end, target)
end

function resetNormalCamera()
	InSpectatorMode = false
	TargetSpectate  = nil
	local playerPed = GetPlayerPed(-1)

	SetCamActive(cam,  false)
	RenderScriptCams(false, false, 0, true, true)

	SetEntityCollision(playerPed, true, true)
	SetEntityVisible(playerPed, true)
	SetEntityCoords(playerPed, LastPosition.x, LastPosition.y, LastPosition.z)
end

function getPlayersList(callback)
	ESX.TriggerServerCallback('esx_spectate:getPlayers', function(players)
		if callback then
			callback(players)
		end
	end)
end

function OpenAdminActionMenu(player)
	TriggerEvent("esx_inventoryhud:openPlayerInventory", GetPlayerServerId(player), GetPlayerName(player))
end

Citizen.CreateThread(function()
	while true do
		Wait(0)
		
		if IsControlJustReleased(1, 56) then
			if group == "mod" or group == "admin" or group == "superadmin" then
				TriggerEvent('esx_spectate:spectate')
			else
				ESX.ShowNotification("Permissões Insuficientes")
			end
		end
	end
end)

RegisterCommand("spectate", function()
	if group == "mod" or group == "admin" or group == "superadmin" then
		TriggerEvent('esx_spectate:spectate')
	else
		ESX.ShowNotification("Permissões Insuficientes")
	end
end)

RegisterNetEvent('esx_spectate:spectate')
AddEventHandler('esx_spectate:spectate', function()
	SetNuiFocus(true, true)

	getPlayersList(function(players)
		SendNUIMessage({
			type = 'show',
			data = players,
			player = GetPlayerServerId(PlayerId())
		})
	end)
end)

RegisterNUICallback('select', function(data, cb)
	spectate(data.id)
	SetNuiFocus(false)
end)

RegisterNUICallback('close', function(data, cb)
	SetNuiFocus(false)
end)

RegisterNUICallback('quit', function(data, cb)
	SetNuiFocus(false)
	resetNormalCamera()
end)

RegisterNUICallback('kick', function(data, cb)
	SetNuiFocus(false)
	TriggerServerEvent('esx_spectate:kick', data.id, data.reason)
	TriggerEvent('esx_spectate:spectate')
end)



Citizen.CreateThread(function()
  	while true do

		Wait(0)

		if InSpectatorMode then

			local targetPlayerId = GetPlayerFromServerId(TargetSpectate)
			local playerPed	  = GetPlayerPed(-1)
			local targetPed	  = GetPlayerPed(targetPlayerId)
			local coords	 = GetEntityCoords(targetPed)

			for i=0, 32, 1 do
				if i ~= PlayerId() then
					local otherPlayerPed = GetPlayerPed(i)
					SetEntityNoCollisionEntity(playerPed,  otherPlayerPed,  true)
					SetEntityVisible(playerPed, false)
				end
			end

			if IsControlPressed(2, 241) then
				radius = radius + 2.0;
			end

			if IsControlPressed(2, 242) then
				radius = radius - 2.0;
			end

			if radius > -1 then
				radius = -1
			end

			local xMagnitude = GetDisabledControlNormal(0, 1);
			local yMagnitude = GetDisabledControlNormal(0, 2);

			polarAngleDeg = polarAngleDeg + xMagnitude * 10;

			if polarAngleDeg >= 360 then
				polarAngleDeg = 0
			end

			azimuthAngleDeg = azimuthAngleDeg + yMagnitude * 10;

			if azimuthAngleDeg >= 360 then
				azimuthAngleDeg = 0;
			end

			local nextCamLocation = polar3DToWorld3D(coords, radius, polarAngleDeg, azimuthAngleDeg)

			SetCamCoord(cam,  nextCamLocation.x,  nextCamLocation.y,  nextCamLocation.z)
			PointCamAtEntity(cam,  targetPed)
			SetEntityCoords(playerPed,  coords.x, coords.y, coords.z + 10)

			if IsControlPressed(2, 47) then
				OpenAdminActionMenu(targetPlayerId)
			end
			
-- taken from Easy Admin (thx to Bluethefurry)  --
			local text = {}
			-- cheat checks
			local targetGod = GetPlayerInvincible(targetPlayerId)
			if targetGod then
				table.insert(text,"Godmode: ~r~Found~w~")
			else
				table.insert(text,"Godmode: ~g~Not Found~w~")
			end
			if not CanPedRagdoll(targetPed) and not IsPedInAnyVehicle(targetPed, false) and (GetPedParachuteState(targetPed) == -1 or GetPedParachuteState(targetPed) == 0) and not IsPedInParachuteFreeFall(targetPed) then
				table.insert(text,"~r~Anti-Ragdoll~w~")
			end
			-- health info
			table.insert(text,"Health"..": "..GetEntityHealth(targetPed).."/"..GetEntityMaxHealth(targetPed))
			table.insert(text,"Armor"..": "..GetPedArmour(targetPed))

			for i,theText in pairs(text) do
				SetTextFont(0)
				SetTextProportional(1)
				SetTextScale(0.0, 0.30)
				SetTextDropshadow(0, 0, 0, 0, 255)
				SetTextEdge(1, 0, 0, 0, 255)
				SetTextDropShadow()
				SetTextOutline()
				SetTextEntry("STRING")
				AddTextComponentString(theText)
				EndTextCommandDisplayText(0.3, 0.7+(i/30))
			end
-- end of taken from easyadmin -- 
		end

  	end
end)
