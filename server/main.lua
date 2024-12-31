ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('esx_spectate:getPlayerData', function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(id)
    if xPlayer ~= nil then
        cb(xPlayer)
    end
end)

RegisterServerEvent('esx_spectate:kick')
AddEventHandler('esx_spectate:kick', function(target, msg)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getGroup() ~= 'user' then
		DropPlayer(target, msg)
	else
		print(('esx_spectate: %s attempted to kick a player!'):format(xPlayer.identifier))
		DropPlayer(source, "esx_spectate: you're not authorized to kick people dummy.")
	end
end)

ESX.RegisterServerCallback('esx_spectate:getPlayers', function(source, cb)
	local xPlayers = ESX.GetPlayers()

    local data = {}

	for i=1, #xPlayers, 1 do
 		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        local _data = {
			id = xPlayers[i],
			name = xPlayer.name
		}

		table.insert(data, _data)
	end

    cb(data)
end)

ESX.RegisterServerCallback("esx_spectate:getPlayerData", function(source, cb, target)
    local xPlayer = ESX.GetPlayerFromId(target)

    cb({
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        loadout = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
        position = xPlayer.getCoords(true),
        metadata = xPlayer.getMeta(),
    })
end)