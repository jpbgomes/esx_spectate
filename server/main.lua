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
        TriggerEvent('bans:giveBan', source, 'spectate', nil)
	end
end)

ESX.RegisterServerCallback('esx_spectate:getPlayers', function(source, cb)
    local playerTrigger = ESX.GetPlayerFromId(source)
    if playerTrigger.getGroup() == 'user' then
        TriggerEvent('bans:giveBan', source, 'spectate', nil)
    else
        local xPlayers = ESX.GetPlayers()
        local data = {}

        for _, playerId in ipairs(xPlayers) do
            local xPlayer = ESX.GetPlayerFromId(playerId)

            if xPlayer then
                local _data = {
                    id = tonumber(playerId),
                    name = GetPlayerName(playerId)
                }

                table.insert(data, _data)
            end
        end

        table.sort(data, function(a, b)
            return a.id < b.id
        end)

        cb(data)
    end
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