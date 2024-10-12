Citizen.CreateThread(function()
	if Config.ShowBlips then
		for k,v in ipairs(Config.BankLocations) do
            local blip = AddBlipForCoord(v.coords)

            SetBlipSprite(blip, 108)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(tostring("Bank"))
            EndTextCommandSetBlipName(blip)
		end
	end

    RegisterBankTargets() 
    RegisterATMTargets()
end)