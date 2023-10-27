local tradeAPI = {}
local Utility = require("Utility")

function tradeAPI.Offer(tradeFile)
    --This Updates a Towns current Offers list 
    --1. Check if there is space for another offer in the list
    --2. Checks what could be a new offer and adds its
    local trades = Utility.readJsonFile(tradeFile)

    if tradeFile and tradeFile.offers.buying then
        if Utility.getArraySize(tradeFile.offers.buying) < tradeFile.offers.limit then
            local alreadyOffered = {}
            for i,v in ipairs(tradeFile.offers.buying) do
                table.insert(alreadyOffered,v.string)
            end




            
        end
    end

end













function tradeAPI.Unity(tradeFile)
    --This Updates a Towns current Offers list 
    --1. Check if there is space for another offer in the list
    --2. Checks what could be a new offer and adds its
    local trades = Utility.readJsonFile(tradeFile)

    if tradeFile and tradeFile.offers.buying then
        local deadlineTime = (os.epoch("utc")/60000)
        for i,v in pairs(tradeFile.offers.buying) do
            if v.timeOffered < deadlineTime then
                --do Unifyed
            end
        end
    end

    if tradeFile and tradeFile.offers.selling then
        local deadlineTime = (os.epoch("utc")/60000)
        for i,v in pairs(tradeFile.offers.selling) do
            if v.timeOffered < deadlineTime then
                --do Unifyed
            end
        end
    end
end




return tradeAPI