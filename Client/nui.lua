RegisterNUICallback("exitMenu", function() 
    TriggerEvent("exter-banking:Client:BankMenu:Hide")
end)

RegisterNUICallback("deposit", function(modalData, cb) 
    Exter.TriggerServerCallback(
        "exter-banking:Server:DepositMoney", 
        { accountId = modalData.account.id, amount = modalData.action.amount, description = modalData.action.description  },
        function(data) 
            if data then
                SendNUIMessage({
                    action = "updateAccounts",
                    accounts = data
                }) 
            else
                cb(nil)
            end
        end
    )
end)

RegisterNUICallback("transfer", function(modalData, cb) 
    Exter.TriggerServerCallback(
        "exter-banking:Server:TransferMoney", 
        { accountId = modalData.account.id, amount = modalData.action.amount, description = modalData.action.description, targetId = modalData.action.targetId  },
        function(data) 
            if data then 
                SendNUIMessage({
                    action = "updateAccounts",
                    accounts = data
                }) 
            else
                cb(nil)
            end
        end
    )
end)

RegisterNUICallback("withdraw", function(modalData, cb) 
    Exter.TriggerServerCallback(
        "exter-banking:Server:WithdrawMoney", 
        { accountId = modalData.account.id, amount = modalData.action.amount, description = modalData.action.description  },
        function(data) 
            if data then 
                SendNUIMessage({
                    action = "updateAccounts",
                    accounts = data
                }) 
            else
                cb(nil)
            end
        end
    )
end)

RegisterNUICallback("create-account", function(modalData, cb) 
    Exter.TriggerServerCallback(
        "exter-banking:Server:CreateAccount", 
        {  accountName = modalData.action.name },
        function(data) 
            if data then 
                SendNUIMessage({
                    action = "addAccount",
                    account = data
                }) 
            else
                cb(nil)
            end
        end
    )
end)

RegisterNUICallback("delete-account", function(modalData, cb) 
    Exter.TriggerServerCallback(
        "exter-banking:Server:DeleteAccount", 
        {  accountId = modalData.account.id },
        function(success) 
            if success then 
                SendNUIMessage({
                    action = "deleteAccount",
                    account = modalData.account
                })
            else
                cb(false)
            end
        end
    )
end)