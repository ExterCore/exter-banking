Exter = exports["exter_core"]:getSharedObject()

RegisterNetEvent("exter-banking:Client:BankMenu:Show")
AddEventHandler("exter-banking:Client:BankMenu:Show", function() 
    Exter.TriggerServerCallback("exter-banking:Server:GetUserAccounts", {}, function(bankData) 
        if bankData then 
            SetNuiFocus(true, true)

            TriggerScreenblurFadeIn(500)
            
            SendNUIMessage({
                action = "showMenu",
                playerName = bankData.playerName,
                accounts = bankData.accounts
            })
        end
    end)
end)

RegisterNetEvent("exter-banking:Client:BankMenu:Hide")
AddEventHandler("exter-banking:Client:BankMenu:Hide", function() 
    SetNuiFocus(false, false)
    
    TriggerScreenblurFadeOut(500)

    SendNUIMessage({
        action = "hideMenu"
    })
end)