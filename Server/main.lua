Exter = exports["exter_core"]:getSharedObject()

Exter.RegisterServerCallback("exter-banking:Server:GetUserAccounts", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)
    local xPlayer = Exter.GetPlayer(source)

    local accounts = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE identifier = @id", { ["@id"] = identifier })

    for k,v in ipairs(accounts) do 
        accounts[k].transactions = json.decode(v.transactions)
    end

    table.insert(accounts, {
        identifier = identifier,
        id = "si:" .. source,
        name = "Personal Account",
        balance = xPlayer.getBank(),
        transactions = {}
    })

    cb({playerName = xPlayer.name, accounts = accounts})
end)

Exter.RegisterServerCallback("exter-banking:Server:CreateAccount", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)

    if not data.accountName then 
        return cb(nil)
    end

    local account = {
        identifier = identifier,
        id = GenerateAccountId(),
        name = data.accountName,
        balance = 0,
        transactions = {}
    }

    Exter.MySQL.Sync.Execute("INSERT INTO accounts (identifier, id, name, balance, transactions) VALUES (?, ?, ?, ?, ?)", {
        account.identifier,
        account.id,
        account.name,
        account.balance,
        json.encode(account.transactions)
    })

    cb(account)
end)

Exter.RegisterServerCallback("exter-banking:Server:DeleteAccount", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)

    if string.find(data.accountId, "si:") then 
        cb(false)
        return
    end

    local result = Exter.MySQL.Sync.Execute("DELETE FROM accounts WHERE identifier = ? and id = ?", { identifier, data.accountId })

    if result.affectedRows >= 1 then 
        cb(true)
    else
        cb(false)
    end   
end)

Exter.RegisterServerCallback("exter-banking:Server:DepositMoney", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)
    local xPlayer = Exter.GetPlayer(source)

    if not data.accountId or not xPlayer then 
        return cb(nil)
    end

    if string.find(data.accountId, "si:") then 
        if xPlayer.getMoney() >= tonumber(data.amount) then 
            xPlayer.removeMoney(data.amount)
            xPlayer.addBank(data.amount)
    
            cb({{
                identifier = identifier,
                id = "si:" .. source,
                name = "Personal Account",
                balance = xPlayer.getBank(),
                transactions = {}
            }})
        else
            cb(nil)
        end
    else
        local accounts = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE identifier = ? and id = ?", { identifier, data.accountId })

        if accounts[1] and tonumber(data.amount) <= xPlayer.getMoney() then 
            xPlayer.removeMoney(data.amount)
    
            accounts[1].balance = accounts[1].balance + data.amount
            accounts[1].transactions = json.decode(accounts[1].transactions)
            table.insert(accounts[1].transactions, { type = "deposit", amount = data.amount, description = data.description or nil })
    
            Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE identifier = ? and id = ?", { accounts[1].balance, json.encode(accounts[1].transactions), identifier, data.accountId })
    
            accounts[1].playerName = xPlayer.name
    
            cb({accounts[1]})
        else 
            cb(nil)
        end
    end
end)

Exter.RegisterServerCallback("exter-banking:Server:WithdrawMoney", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)
    local xPlayer = Exter.GetPlayer(source)

    if not data.accountId or not xPlayer then 
        return cb(nil)
    end

    if string.find(data.accountId, "si:") then
        if xPlayer.getBank() >= tonumber(data.amount) then 
            xPlayer.removeBank(data.amount)
            xPlayer.addMoney(data.amount)
    
            cb({{
                identifier = identifier,
                id = "si:" .. source,
                name = "Personal Account",
                balance = xPlayer.getBank(),
                transactions = {}
            }})
        else
            cb(nil)
        end 
    else
        local accounts = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE identifier = ? and id = ?", { identifier, data.accountId })

        if accounts[1] then 
            if accounts[1].balance >= tonumber(data.amount) then 
                accounts[1].balance = accounts[1].balance - data.amount
    
                accounts[1].transactions = json.decode(accounts[1].transactions)
                table.insert(accounts[1].transactions, { type = "withdraw", amount = data.amount, description = data.description or nil })
    
                Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE identifier = ? and id = ?", { accounts[1].balance, json.encode(accounts[1].transactions), identifier, data.accountId })
        
                xPlayer.addMoney(data.amount)
    
                accounts[1].playerName = xPlayer.name
    
                cb({accounts[1]})
            else
                cb(nil)
            end
        end
    end
end)

Exter.RegisterServerCallback("exter-banking:Server:TransferMoney", function(source, data, cb) 
    local identifier = Exter.GetCharacterIdentifier(source)

    if string.find(data.accountId, "si:") then 
        local xPlayer = Exter.GetPlayer(source)

        if xPlayer.getBank() >= tonumber(data.amount) then
            if string.find(data.targetId, 'si:') then 
                local targetSource = tonumber(string.match(data.targetId, "%d+"))

                if targetSource == source then
                    cb(nil) 
                else
                    local targetXPlayer = Exter.GetPlayer(targetSource)

                    if targetXPlayer then 
                        xPlayer.removeBank(data.amount)
                        targetXPlayer.addBank(data.amount)
    
                        cb({{
                            identifier = identifier,
                            id = "si:" .. source,
                            name = "Personal Account",
                            balance = xPlayer.getBank(),
                            transactions = {}
                        }})
                    else
                        cb(nil)
                    end
                end
            else
                local targetAccountFetch = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE id = ?", { data.targetId })

                if targetAccountFetch[1] then
                    local targetAccount = targetAccountFetch[1]
    
                    targetAccount.balance = targetAccount.balance + data.amount
    
                    targetAccount.transactions = json.decode(targetAccount.transactions)
                    table.insert(targetAccount.transactions, { type = "transfer_recieved", amount = data.amount, description = data.description, targetId = "si:" .. source })
    
                    xPlayer.removeBank(data.amount)

                    Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE id = ?", { targetAccount.balance, json.encode(targetAccount.transactions), targetAccount.id })
    
                    if targetAccount.identifier == identifier then 
                        cb({ 
                            {
                                identifier = identifier,
                                id = "si:" .. source,
                                name = "Personal Account",
                                balance = xPlayer.getBank(),
                                transactions = {} 
                            }, 
                            targetAccount 
                        })
                    else
                        cb({{ 
                            identifier = identifier,
                            id = "si:" .. source,
                            name = "Personal Account",
                            balance = xPlayer.getBank(),
                            transactions = {} 
                        }})
                    end
                else 
                    cb(nil)
                end
            end
        else
            cb(nil)
        end
    else
        local accountFetch = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE identifier = ? and id = ?", { identifier, data.accountId })

        if accountFetch[1] then 
            local senderAccount = accountFetch[1]
    
            if senderAccount.balance >= tonumber(data.amount) then 
    
                if string.find(data.targetId, 'si:') then 
                    local targetSource = tonumber(string.match(data.targetId, "%d+"))
                    local targetXPlayer = Exter.GetPlayer(targetSource)

                    if targetXPlayer then 
                        senderAccount.balance = senderAccount.balance - data.amount
                        senderAccount.transactions = json.decode(senderAccount.transactions)
                        table.insert(senderAccount.transactions, { type = "transfer_sent", amount = data.amount, description = data.description, targetId = "si:" .. targetSource })

                        Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE id = ?", { senderAccount.balance, json.encode(senderAccount.transactions), senderAccount.id })

                        targetXPlayer.addBank(data.amount)

                        if targetSource == source then 
                            cb({ 
                                senderAccount,  
                                { 
                                    identifier = identifier,
                                    id = "si:" .. source,
                                    name = "Personal Account",
                                    balance = targetXPlayer.getBank(),
                                    transactions = {} 
                                }
                            })
                        else
                            cb({ senderAccount })
                        end
                    else
                        cb(nil)
                    end
                else
                    local targetAccountFetch = Exter.MySQL.Sync.Fetch("SELECT * FROM accounts WHERE id = ?", { data.targetId })
    
                    if targetAccountFetch[1] then
                        local targetAccount =targetAccountFetch[1]
        
                        senderAccount.balance = senderAccount.balance - data.amount
        
                        senderAccount.transactions = json.decode(senderAccount.transactions)
                        table.insert(senderAccount.transactions, { type = "transfer_sent", amount = data.amount, description = data.description, targetId = data.targetId })
        
                        targetAccount.balance = targetAccount.balance + data.amount
        
                        targetAccount.transactions = json.decode(targetAccount.transactions)
                        table.insert(targetAccount.transactions, { type = "transfer_recieved", amount = data.amount, description = data.description, targetId = senderAccount.id })
        
                        Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE id = ?", { senderAccount.balance, json.encode(senderAccount.transactions), senderAccount.id })
                        Exter.MySQL.Sync.Execute("UPDATE accounts SET balance = ?, transactions = ? WHERE id = ?", { targetAccount.balance, json.encode(targetAccount.transactions), targetAccount.id })
        
                        if targetAccount.identifier == senderAccount.identifier then 
                            cb({ senderAccount, targetAccount })
                        else
                            cb({ senderAccount })
                        end
                    else 
                        cb(nil)
                    end
                end
            else 
                cb(nil)
            end
        end
    end
end)