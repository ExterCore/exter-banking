function GenerateAccountId() 
    local uniqueIdFound = false
    local accountId = nil

    while not uniqueIdFound do
        math.randomseed(os.time())

        accountId = tostring( math.random(1, 100000) )

        local result = Exter.MySQL.Sync.Fetch('SELECT * FROM accounts WHERE id = ?', { accountId })

        if #result == 0 then
            uniqueIdFound = true
        end

        Citizen.Wait(1)
    end

    return accountId
end