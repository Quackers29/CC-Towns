local TradeAPI = {}
local Utility = require("Utility")


function TradeAPI.AppendArray(FilePath,Array)
-- table.insert(parsedResponses[item1],{destination=item2,timeResponded=item3,bidPrice=item4})
    for i,v in pairs(Array) do
        for a,b in ipairs(v) do
            -- Add response
            local response = i.."\t"..b.destination.."\t"..b.timeResponded.."\t"..b.bidPrice
            Utility.appendToFile(FilePath,response)
        end
    end
end

function TradeAPI.SellerCheckResponses(tradeFile,townFolder,resFile) -- You are the seller
    --Auction deadline ended?
    --Is there a BuyNow response?   #FUTURE ADDITION
    --Are there any acceptable responses?
    --local response = itemString.."\t"..townFolder.."\t"..tostring(offer.timeResponded).."\t"..tostring(offer.bidPrice)

    --Auction deadline ended?
    local currentTime = os.epoch("utc") -- milliseconds
    local trades = Utility.readJsonFile(tradeFile)
    local ResponsesFile = "Towns\\"..townFolder.."\\".."Responses.txt"
    local Responses = Utility.readTextFileToArray(ResponsesFile)

    --parse responses file and gather per item
    local parsedResponses = {}
    for i,v in ipairs(Responses) do
        -- Define a pattern to capture each item (assuming they are alphanumeric)
        local parts = {}
        for part in string.gmatch(v, "([^\t]+)") do
            table.insert(parts, part)
        end
        local item1, item2, item3, item4 = parts[1], parts[2], parts[3], parts[4]
        if item1 and item2 and item3 and item4 then
            if parsedResponses[item1] == nil then
                parsedResponses[item1] = {}
            end
            table.insert(parsedResponses[item1],{destination=item2,timeResponded=tonumber(item3),bidPrice=tonumber(item4)})
        else
            print("Reading Reposonse file,One or more parts are nil on line: "..tostring(i))
        end
    end

    local deletedRepsonseFile = false

    if trades and trades.offers.selling then
        for itemString,offer in pairs(trades.offers.selling) do
            --print(itemString)
            if itemString ~= "" and (offer.timeOffered + (1000*trades.offers.deadline)) < currentTime then
                -- Auction has ended
                local auctionStatus
                print("Auction has ended for: "..itemString)
                -- Delete all response file first (add other auctions after)
                -- Are there any acceptable responses?
                -- Gather by itemString
                if deletedRepsonseFile == false then
                    deletedRepsonseFile = true
                    --delete response file
                    Utility.deleteFile(ResponsesFile) -- default 10 attempts
                end

                local currentItemResponses = parsedResponses[itemString]
                -- If there is a response at all
                if currentItemResponses then
                    local function compare(a, b)
                        return a.bidPrice > b.bidPrice
                    end
                    table.sort(currentItemResponses,compare)
                    local bestResponse = currentItemResponses[1]
                    print("item, bestBid, minprice: "..itemString..","..bestResponse.bidPrice..","..offer.minPrice)
                    if bestResponse.bidPrice > offer.minPrice then --#ADD check for resources still available
                        --Best Response is acceptable

                        --Move info from Buyers trades.proposal to trades.accepted
                        local buyerX, buyerY, buyerZ = string.match(bestResponse.destination, "X(-?%d+)Y(-?%d+)Z(-?%d+)")
                        local buyerTradeFile = "Towns\\"..bestResponse.destination.."\\".."TRD_X"..buyerX.."Y"..buyerY.."Z"..buyerZ..".json"
                        local buyerTrades = Utility.readJsonFile(buyerTradeFile)
                        local PreTransportTimer = 60 -- seconds #FUTURE configure
                        if buyerTrades then
                            local accepted = buyerTrades.proposal[itemString]
                            accepted.timeAccepted = currentTime
                            accepted.transportStartTime = currentTime + (PreTransportTimer * 1000)  -- Wait for PreTransportTimer
                            trades.accepted[itemString] = accepted

                            --Remove required resources for the trade
                            local resTable = Utility.readJsonFile(resFile)
                            resTable = Utility.AddMcItemToTable(itemString,resTable,(offer.quantity*-1))
                            print("Selling Res, Removed res: "..itemString..","..offer.quantity)
                            print("Selling for, Total Bids: "..bestResponse.bidPrice..","..#currentItemResponses)
                            auctionStatus = "Sold to: "..bestResponse.destination..", for: "..bestResponse.bidPrice
                            Utility.writeJsonFile(resFile,resTable)
                        end

                        --Delete response section and Seller offer
                        parsedResponses[itemString] = nil
                        TradeAPI.AppendArray(ResponsesFile, parsedResponses)

                        trades.offers.selling[itemString] = nil
                        Utility.writeJsonFile(tradeFile,trades)

                    else
                        --Not acceptable, just delete the response table and Seller offer
                        print("No acceptable trades for: "..itemString.." Bids: "..#currentItemResponses)
                        auctionStatus = "No acceptable trades for: "..itemString.." Bids: "..#currentItemResponses
                        parsedResponses[itemString] = nil
                        TradeAPI.AppendArray(ResponsesFile, parsedResponses)
                        
                        trades.offers.selling[itemString] = nil
                        Utility.writeJsonFile(tradeFile,trades)
                    end
                else
                    print("No responses to Auction")
                    auctionStatus = "No responses to Auction"
                    trades.offers.selling[itemString] = nil
                    Utility.writeJsonFile(tradeFile,trades)
                end
                commands.say("Auction for "..itemString.." x"..offer.quantity.." has ended. ")
                commands.say(auctionStatus)
            end
        end
    end
end

function TradeAPI.BuyerSearchOffers(NearbyTowns,townFolder,tradeFile,SettingsFile,resFile)
    local trades = Utility.readJsonFile(tradeFile)
    local settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(resFile)
    --Searches from Nearby to Far Towns for Offers

    --#Buyer can collect to save from the cost of delivery
    --#Could setup ~a auto transport company per X spawned towns that vary their prices over time, maybe even based on location, bulk transport price, etc
    --#Buyer weighs in how many bids there are already for that item of the Seller, lowering bid chance

    --Make a list of town, sort by nearest   --table.insert(NearbyTowns,{folderName = v,x = ax,y = ay,z = az, distance = CalcDist(x, z, ax, az)})
    if trades and settings and resTable then
        local maxTradeDistance = 2000 --blocks,meters -- can be set in future
        local function compare(a, b)
            return a.distance > b.distance
        end
        table.sort(NearbyTowns,compare)

        --X 1. Make a list of all the keepinstock items that are needed so resource count low
        --X 2. Check is bid is already out for that item
        --~ 3. Search towns against this list, adding potenial town offerings to this list
        --X 4. Choose best offering per item (closest to count needed, nearest etc)
        --X 5. Check best is acceptable (resources etc) 
        --X 6. Add to Buyers trade.proposal and to Sellers Responses.txt

        -- 1. make a list of all the keepinstock items that are needed so resource count low
        local possibleBids = {}
        for i,v in pairs(settings.resources.keepInstock) do
            local add = false
            local keepStock = v
            local urgencyFactor = 0 
            local count = 0
            local needed = 0
            if resTable then
                --its in resources as well
                count = Utility.ResCount(resTable,i)
                local restockAt = keepStock*settings.resources.restockThreshold
                if count < restockAt then
                    -- needed
                    needed = keepStock - count
                    urgencyFactor = (restockAt - count)/restockAt--Between 0 and 1 depending on if there is any of that resource
                    add = true
                end
            else
                --add if not in res table
                add = true
            end
            if add then
                --2. Check if bid is already out for that item
                if trades.proposal and trades.proposal[i] then
                    add = false
                else
                    --not in bids, add to possibleBids
                    print("BuyerSearch, needs and Unrgency: "..i..","..tostring(needed)..","..tostring(urgencyFactor))
                    possibleBids[i] = {needed = needed, urgencyFactor = urgencyFactor}
                end
            end
        end

        -- 3. Search towns against this list, adding potenial town offerings to this list
        for i,v in ipairs(NearbyTowns) do
            if v.distance < maxTradeDistance then
                --within trade distance
                --access there offers file
                local nearbyOffersFile = "Towns\\"..v.folderName.."\\".."TRD_X"..v.x.."Y"..v.y.."Z"..v.z..".json"
                local nearbyResponsesFile = "Towns\\"..v.folderName.."\\".."Responses.txt"
                local nearbyOffers = Utility.readJsonFile(nearbyOffersFile)
                if nearbyOffers and nearbyOffers.offers.selling then
                    --check if the sold item is needed
                    for itemstring,itemdata in pairs(nearbyOffers.offers.selling) do
                        if possibleBids[itemstring] then
                            --resource is in possibleBids
                            local needed = possibleBids[itemstring].needed
                            print("BuyerSearch, Found town, item, quantity"..v.folderName..itemstring..tostring(itemdata.quantity))
                            if needed < itemdata.quantity then
                                --they are selling more than needed, add to list
                                --add important info with it from the seller
                                --Account for: market price (not here), X transportation distance, #past trades, X current bids made, min price, buy now price,

                                local data = {
                                    origin = v.folderName,
                                    distance = v.distance, --transportation distance
                                    bids = Utility.countDataLines(nearbyResponsesFile), -- gets how many bids there are already
                                    minPrice = itemdata.minPrice, -- starting bid
                                    maxPrice = itemdata.maxPrice, -- buy it now
                                    needed = needed,
                                    urgencyFactor = possibleBids[itemstring].urgencyFactor,
                                    quantity = itemdata.quantity
                                }

                                if not possibleBids[itemstring].offers then
                                    possibleBids[itemstring].offers = {}
                                end
                                table.insert(possibleBids[itemstring].offers,data) --this table will be ordered in nearest. 
                            end
                        end
                    end
                end
            end
        end

        -- 4. Choose best offering (closest to count needed, nearest etc)
        local bestBids = {}
        for itemString,itemBids in pairs(possibleBids) do
            if itemBids.offers then
                -- for each item to bid
                -- each offer for that item
                -- Account for: market price (not here), X transportation distance, #past trades, X current bids made
                
                -- Weights (these could be dynamically adjusted based on buyer's preferences)
                local weights = {
                    distance_weight = -1, -- Negative because less distance is better
                    bids_weight = -0.5, -- Assuming fewer bids are better
                    minPrice_weight = -1, -- Negative because a lower price is better
                    maxPrice_weight = -1, -- Negative because a lower 'buy it now' price is better
                }

                -- Function to calculate the score for an offer
                function calculate_offer_score(offer, weights)
                    local score = 0
                    score = score + (offer.distance * weights.distance_weight)
                    score = score + (offer.bids * weights.bids_weight)
                    score = score + (offer.minPrice * weights.minPrice_weight)
                    score = score + (offer.maxPrice * weights.maxPrice_weight)
                    return score
                end

                -- Function to find the best offer
                function find_best_offer(possibleBids, weights)
                    local bestScore = -math.huge
                    local bestOffer = nil
                    for _, offer in ipairs(possibleBids) do
                        local score = calculate_offer_score(offer, weights)
                        if score > bestScore then
                            bestScore = score
                            bestOffer = offer
                        end
                    end
                    return bestOffer
                end

                -- Assuming possibleBids is an array of offers with their respective data
                local bestSellerOption = find_best_offer(itemBids.offers, weights)
                if bestSellerOption then
                    bestBids[itemString] = bestSellerOption
                end
            end
        end


        local transportRate = 0.01 -- 1 emerald per 100 blocks, roundUP
        -- 5. Check best is acceptable (resources etc) 
        for itemString, offer in pairs(bestBids) do
            --per item
            -- is there enough emeralds for a bid
            -- #FUTURE is there enough storage for the purchased items

            offer.transportCost = math.ceil(offer.distance * transportRate)

            -- Make a bid price
            -- offer 20% extra * by random factor (0.5 to 1) * (urgencyFactor(0 to 1) * 2)
            local bidExtra = (offer.minPrice*0.2) * math.random(0.5,1) * (offer.urgencyFactor * 2)
            local bidPrice = math.ceil(offer.minPrice + bidExtra)

            -- if the bid is over max price, use max price
            if bidPrice > offer.maxPrice then
                bidPrice = offer.maxPrice
            end

            offer.bidPrice = bidPrice
            offer.buyerTotalCost = bidPrice + offer.transportCost
            --update offer with new info
            bestBids[itemString] = offer
        end

        -- 6. Add to Buyers trade.proposal and to Sellers Responses.txt
        -- go for as many bids as possible for available emeralds
        local emeraldsForTrading = Utility.ResCount(resTable,"minecraft:emerald")

        for itemString, offer in pairs(bestBids) do
            if emeraldsForTrading > (offer.buyerTotalCost * 1.1) then -- 10% extra error margin
                --Have enough emeralds for bid, make the bid
                --1. X Remove Resources
                --2. X Add to trade.proposal with extra data, time etc
                --3. X Add to Responses.txt

                resTable = Utility.AddMcItemToTable("minecraft:emerald",resTable,(offer.buyerTotalCost*-1))
                print("Previous emeralds, Removed emeralds: "..emeraldsForTrading..offer.buyerTotalCost)

                offer.timeResponded = os.epoch("utc") -- unix time for timestamping, milliseconds
                offer.destination = townFolder
                offer.timeToDestination = nil

                trades.proposal[itemString] = offer

                -- Add response
                local ResponsesFile = "Towns\\"..offer.origin.."\\".."Responses.txt"
                local response = itemString.."\t"..townFolder.."\t"..tostring(offer.timeResponded).."\t"..tostring(offer.bidPrice)
                Utility.appendToFile(ResponsesFile,response)
            end
        end
        --Update trades
        Utility.writeJsonFile(tradeFile,trades)
        --Update Resources
        Utility.writeJsonFile(resFile,resTable)
    end
end


function TradeAPI.SellerUpdateOffers(tradeFile,SettingsFile,resFile)

    --This Updates a Towns current Offers list 
    --1. Check if there is space for another offer in the list
    --2. Checks what could be a new offer and adds its
    local trades = Utility.readJsonFile(tradeFile)
    local settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(resFile)

    if trades and settings and resTable then
        -- check if there is room for an offer, only add one
        if Utility.getArraySize(trades.offers.selling) < trades.offers.limit then
            -- make a list of all current selling offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.offers.selling and trades.offers.selling[i] ~= nil then
                    continue = false
                end
                if trades.offers.accepted and trades.offers.accepted[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in sell list, check resources
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        print("SellCount: "..count.." > "..(v*settings.resources.excessThreshold))
                        if count > (v*settings.resources.excessThreshold) then
                            -- Add to selling
                            if not trades.offers.selling[i] then
                                trades.offers.selling[i] = {}
                            end

                            trades.offers.selling[i] = {
                                quantity = count-v,
                                minPrice = math.abs((count-v)*0.8),
                                maxPrice = math.abs((count-v)*1.2),
                                timeOffered = os.epoch("utc") -- milliseconds
                            }
                            os.sleep(0.001) --sleep 1 milliseconds to change timeOffered between items (reference code)
                        end
                    end
                end
            end
        end
        if Utility.getArraySize(trades.offers.buying) < trades.offers.limit then
            -- make a list of all current buying offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.offers.buying[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in buy list, check resources
                    --local itemShort = string.match(i,":(.+)")
                    print("Searching: "..i)
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        print("BuyCount: "..count.." < "..(v*settings.resources.restockThreshold))
                        if count < (v*settings.resources.restockThreshold) then
                            -- attempt add the buying
                            resTable[i].count = v - count
                            resTable[i].price = {
                                emerald = {
                                string = "minecraft:emerald",
                                attributes = "",
                                key = "emerald",
                                quantity = resTable[i].count
                                }
                                }
                            if not trades.offers.buying[i] then
                                --trades.offers.buying[i] = {}
                            end
                            --trades.offers.buying[i] = resTable[i]
                        end
                    end
                end
            end
        end
        Utility.writeJsonFile(tradeFile,trades)
    end
end

return TradeAPI
