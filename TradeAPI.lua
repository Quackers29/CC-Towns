local TradeAPI = {}
local Utility = require("Utility")


function TradeAPI.AppendArray(FilePath,Array)
-- table.insert(parsedResponses[item1],{destination=item2,timeResponded=item3,bidPrice=item4})
    for i,v in pairs(Array) do
        for a,b in ipairs(v) do
            -- Add response
            local response = i.."\t"..b.destination.."\t"..b.timeResponded.."\t"..b.bidPrice.."\t"..b.bidQuantity.."\n"
            Utility.appendToFile(FilePath,response)
        end
    end
end

function TradeAPI.SellerCheckResponses(tradeFile,townFolder,resFile) -- You are the seller
    --Auction deadline ended?
    --Is there a BuyNow response?   #FUTURE ADDITION
    --Are there any acceptable responses?
    --local response = itemString.."\t"..townFolder.."\t"..tostring(offer.timeResponded).."\t"..tostring(offer.bidPrice)..tostring(offer.needed).."\n"

    --Auction deadline ended?
    local currentTime = os.epoch("utc") -- milliseconds
    local trades = Utility.readJsonFile(tradeFile)
    local ResponsesFile = "Towns\\"..townFolder.."\\".."Responses.txt"

    local deletedRepsonseFile = false

    if trades and trades.selling then
        for itemString,offer in pairs(trades.selling) do
            --print(itemString)
            if itemString ~= "" and offer.timeCloses < currentTime then
                -- Auction has ended
                local auctionStatus
                print("Auction has ended for: "..itemString)

                --Moved reading responses here so to update per item
                local Responses = Utility.readTextFileToArray(ResponsesFile)
                --parse responses file and gather per item
                local parsedResponses = {}
                for i,v in ipairs(Responses) do
                    -- Define a pattern to capture each item (assuming they are alphanumeric)
                    local parts = {}
                    for part in string.gmatch(v, "([^\t]+)") do
                        table.insert(parts, part)
                    end
                    local item1, item2, item3, item4, item5 = parts[1], parts[2], parts[3], parts[4], parts[5]
                    if item1 and item2 and item3 and item4 then
                        if parsedResponses[item1] == nil then
                            parsedResponses[item1] = {}
                        end
                        table.insert(parsedResponses[item1],{destination=item2,timeResponded=tonumber(item3),bidPrice=tonumber(item4),bidQuantity=tonumber(item5)})
                    else
                        print("Reading Reposonse file,One or more parts are nil on line: "..tostring(i))
                    end
                end

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

                    -- Calculates scores for each bid based on a weighted combination of unit price and fulfillment of sell quantity.
                    local function scoreBids(array, sellQuantity, unitPriceWeight, fulfillmentWeight)
                        for _, item in ipairs(array) do
                            local unitPrice = item.bidPrice / item.bidQuantity
                            local fulfillment = math.min(item.bidQuantity, sellQuantity) / sellQuantity
                            item.score = unitPrice * unitPriceWeight + (1 - fulfillment) * fulfillmentWeight
                        end
                    end

                    local sellQuantity = offer.maxQuantity
                    local unitPriceWeight = 0.5  -- Adjust this value as needed
                    local fulfillmentWeight = 0.5  -- Adjust this value as needed

                    scoreBids(currentItemResponses, sellQuantity, unitPriceWeight, fulfillmentWeight)
                    Utility.sortArrayByKey(currentItemResponses, "score")

                    local bestResponse = currentItemResponses[1]
                    print("item, bestBid, minprice: "..itemString..","..bestResponse.bidPrice..","..offer.minPrice)

                    --Check Seller still has quantity to sell
                    local resTable = Utility.readJsonFile(resFile)
                    local hasQuantity = Utility.GetMcItemCount(itemString,resTable) > (offer.maxQuantity * 1.0) --0% error margin

                    if bestResponse.bidPrice > offer.minPrice and hasQuantity then --#ADD check for resources still available
                        --Best Response is acceptable

                        --Move info from Buyers trades.proposal to Sellers trades.accepted
                        local buyerX, buyerY, buyerZ = string.match(bestResponse.destination, "X(-?%d+)Y(-?%d+)Z(-?%d+)")
                        local buyerTradeFile = "Towns\\"..bestResponse.destination.."\\".."TRD_X"..buyerX.."Y"..buyerY.."Z"..buyerZ..".json"
                        local buyerTrades = Utility.readJsonFile(buyerTradeFile)
                        local PreTransportTimer = 60 -- seconds #FUTURE configure
                        if buyerTrades then
                            local accepted = buyerTrades.proposal[itemString]
                            accepted.timeAccepted = currentTime
                            accepted.transportStartTime = currentTime + (PreTransportTimer * 1000)  -- Wait for PreTransportTimer
                            trades.sold[tostring(accepted.timeOffered)] = accepted

                            --Remove required resources for the trade
                            resTable = Utility.AddMcItemToTable(itemString,resTable,(accepted.needed*-1))
                            resTable = Utility.AddMcItemToTable("minecraft:emerald",resTable,bestResponse.bidPrice)
                            print("Selling Res, Removed res: "..itemString..","..accepted.needed)
                            print("Selling for, Total Bids: "..bestResponse.bidPrice..","..#currentItemResponses)
                            auctionStatus = "Sold to: "..bestResponse.destination..", for: "..bestResponse.bidPrice
                            Utility.writeJsonFile(resFile,resTable)
                        end

                        --Delete response section and Seller offer
                        parsedResponses[itemString] = nil
                        TradeAPI.AppendArray(ResponsesFile, parsedResponses)

                        trades.selling[itemString] = nil
                        Utility.writeJsonFile(tradeFile,trades)
                        commands.say(auctionStatus)
                    else
                        --Not acceptable, just delete the response table and Seller offer
                        if not hasQuantity then
                            print("Seller did not have enough resource")
                            --commands.say("Seller did not have enough resource")
                        end
                        print("No acceptable trades for: "..itemString.." Bids: "..#currentItemResponses)
                        auctionStatus = "No acceptable trades for: "..itemString.." Bids: "..#currentItemResponses
                        parsedResponses[itemString] = nil
                        TradeAPI.AppendArray(ResponsesFile, parsedResponses)
                        
                        trades.selling[itemString] = nil
                        Utility.writeJsonFile(tradeFile,trades)
                    end
                else
                    print("No responses to Auction")
                    auctionStatus = "No responses to Auction"
                    trades.selling[itemString] = nil
                    Utility.writeJsonFile(tradeFile,trades)
                end
                --commands.say("Auction for "..itemString.." x"..offer.maxQuantity.." has ended. ")
                --commands.say(auctionStatus)
            end
        end
    end
end

function TradeAPI.BuyerMonitorAuction(tradeFile,resFile)
    --Has proposal been accepted by Seller?
    --Has the proposal expired?

    --Wait for Sellers PreTransport timer to pass
    --Is transport Automated

    --Wait for transport complete time to elapse
    --Add resources from the trade
    --Move trade.accepted to .sold

    local trades = Utility.readJsonFile(tradeFile)
    local resTable = Utility.readJsonFile(resFile)
    local currentTime = os.epoch("utc")
    --Has proposal been accepted by Seller?
    --Has the proposal expired?
    if trades and trades.proposal then
        for i,v in pairs(trades.proposal) do
            local sellerX, sellerY, sellerZ = string.match(v.origin, "X(-?%d+)Y(-?%d+)Z(-?%d+)")
            local sellerTradeFile = "Towns\\"..v.origin.."\\".."TRD_X"..sellerX.."Y"..sellerY.."Z"..sellerZ..".json"
            print(sellerTradeFile)
            local sellerTrades = Utility.readJsonFile(sellerTradeFile)

            --search Seller sold history
            local acceptedBuyer = false
            if sellerTrades and sellerTrades.sold and sellerTrades.sold[tostring(v.timeOffered)] then
                if sellerTrades.sold[tostring(v.timeOffered)] then
                    -- Seller has accepted a response
                    if sellerTrades.sold[tostring(v.timeOffered)].destination == v.destination then
                        --Seller has accepted the Buyers response
                        acceptedBuyer = true
                    else
                        --Seller has not accepted offer
                    end
                end
            end
            if acceptedBuyer and sellerTrades then
                --Move proposal to accepted
                trades.accepted[i] = sellerTrades.sold[tostring(v.timeOffered)]
                trades.proposal[i] = nil
                --commands.say("Seller Accepted trade")
            else
                --Has the proposal expired?
                if currentTime > (v.timeCloses + 30000) then -- 30 seconds after the auction has ended
                    --Seller has not accepted offer
                    --Delete the proposal and return the stored cost
                    resTable = Utility.readJsonFile(resFile)
                    resTable = Utility.AddMcItemToTable("minecraft:emerald",resTable,(v.bidPrice))
                    Utility.writeJsonFile(resFile,resTable)
                    trades.proposal[i] = nil
                    --commands.say("Trade not accepted by Seller")
                end
            end
        end
    end
    Utility.writeJsonFile(tradeFile,trades)
end

function TradeAPI.BuyerMonitorAccepted(tradeFile,resFile)
    --Wait for Sellers PreTransport timer to pass
    --#ADD Is transport Automated

    local trades = Utility.readJsonFile(tradeFile)
    local resTable = Utility.readJsonFile(resFile)
    local currentTime = os.epoch("utc")
    --Has proposal been accepted by Seller?
    --Has the proposal expired?
    if trades and trades.accepted then
        for i,v in pairs(trades.accepted) do
            if currentTime > v.transportStartTime then
                if not v.transportEndTime then
                    --No end time set, add one
                    v.transportEndTime = v.transportStartTime + (v.distance * 10000) -- 10 seconds per block distance
                    trades.accepted[i] = v
                    commands.say("Transportation started to: "..v.destination)
                end
                if currentTime > v.transportEndTime then
                    --Item delivered
                    --Add resources from the trade
                    --Move trade.accepted to .bought
                    resTable = Utility.readJsonFile(resFile)
                    resTable = Utility.AddMcItemToTable(v.item,resTable,v.needed)
                    resTable = Utility.AddMcItemToTable("minecraft:emerald",resTable,(v.transportCost*-1))
                    Utility.writeJsonFile(resFile,resTable)
                    trades.bought[tostring(v.timeOffered)] = trades.accepted[i]
                    trades.accepted[i] = nil
                    commands.say("Items delivered to: "..v.destination..", "..v.item.." x"..v.needed..", For: "..v.transportCost.."emerald")
                end
            end
        end
    end
    Utility.writeJsonFile(tradeFile,trades)
end

function TradeAPI.BuyerSearchOffers(NearbyTowns,townFolder,tradeFile,SettingsFile,resFile)
    local trades = Utility.readJsonFile(tradeFile)
    local settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(resFile)
    local currentTime = os.epoch("utc")
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
                elseif trades.accepted and trades.accepted[i] then
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
                if nearbyOffers and nearbyOffers.selling then
                    --check if the sold item is needed
                    for itemstring,itemdata in pairs(nearbyOffers.selling) do
                        if possibleBids[itemstring] and currentTime < itemdata.timeCloses then
                            --resource is in possibleBids and the sellers auction has not ended already
                            local needed = possibleBids[itemstring].needed
                            print("BuyerSearch, Found town, item, quantity"..v.folderName..itemstring..tostring(itemdata.maxQuantity))
                            if needed <= itemdata.maxQuantity then
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
                                    maxQuantity = itemdata.maxQuantity,
                                    minQuantity = itemdata.minQuantity,
                                    timeOffered = itemdata.timeOffered,
                                    timeCloses = itemdata.timeCloses,
                                    item = itemdata.item
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
                    quantity_weight = 1, -- The closer the match of Seller quantity and Buyer needed, the better, out of 100% for now.
                    distance_weight = -1, -- Negative because less distance is better
                    bids_weight = -0.5, -- Assuming fewer bids are better
                    minPrice_weight = -1, -- Negative because a lower price is better
                    maxPrice_weight = -1, -- Negative because a lower 'buy it now' price is better
                }

                -- Function to calculate the score for an offer
                function calculate_offer_score(offer, weights)
                    local score = 0
                    score = score + (((offer.needed / offer.maxQuantity) * 100) * weights.quantity_weight)
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


        local transportRate = 0.5 -- 50 emerald per 100 blocks, roundUP
        -- 5. Check best is acceptable (resources etc) 
        for itemString, offer in pairs(bestBids) do
            -- is there enough emeralds for a bid
            -- #FUTURE is there enough storage for the purchased items

            offer.transportCost = math.ceil(offer.distance * transportRate)

            -- Make a bid price
            local minPricePerUnit = offer.minPrice / offer.minQuantity
            local bidPricePerUnit = minPricePerUnit * (math.random(1,1.2) + offer.urgencyFactor) --random 0 to 20% + urgencyFactor(0 to 1) or 0 to 100%
            local bidPrice = math.ceil(bidPricePerUnit * offer.needed)

            offer.bidPrice = bidPrice
            offer.buyerTotalCost = bidPrice + offer.transportCost
            --update offer with new info
            bestBids[itemString] = offer
        end

        -- 6. Add to Buyers trade.proposal and to Sellers Responses.txt
        -- go for as many bids as possible for available emeralds
        

        for itemString, offer in pairs(bestBids) do
            resTable = Utility.readJsonFile(resFile)
            local emeraldsForTrading = Utility.ResCount(resTable,"minecraft:emerald")
            if emeraldsForTrading > (offer.buyerTotalCost * 1.1) then -- 10% extra error margin
                --Have enough emeralds for bid, make the bid
                --1. X Remove Resources
                --2. X Add to trade.proposal with extra data, time etc
                --3. X Add to Responses.txt

                resTable = Utility.AddMcItemToTable("minecraft:emerald",resTable,(offer.bidPrice*-1))
                --Update Resources
                Utility.writeJsonFile(resFile,resTable)
                print("Previous emeralds, Removed emeralds: "..emeraldsForTrading..", "..offer.bidPrice)

                offer.timeResponded = os.epoch("utc") -- unix time for timestamping, milliseconds
                offer.destination = townFolder
                offer.timeToDestination = nil

                trades.proposal[itemString] = offer

                -- Add response
                local ResponsesFile = "Towns\\"..offer.origin.."\\".."Responses.txt"
                local response = itemString.."\t"..townFolder.."\t"..tostring(offer.timeResponded).."\t"..tostring(offer.bidPrice).."\t"..tostring(offer.needed).."\n"
                Utility.appendToFile(ResponsesFile,response)
            end
        end
        --Update trades
        Utility.writeJsonFile(tradeFile,trades)
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
        if Utility.getArraySize(trades.selling) < trades.settings.limit then
            -- make a list of all current selling offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.selling and trades.selling[i] ~= nil then
                    continue = false
                end
                if trades.accepted and trades.accepted[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in sell list, check resources
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        print("SellCount: "..count.." > "..(v*settings.resources.excessThreshold))
                        if count > (v*settings.resources.excessThreshold) then
                            -- Add to selling
                            local quantityToTrade = count - v
                            if not trades.selling[i] then
                                trades.selling[i] = {}
                            end
                            local currentTime = os.epoch("utc") -- milliseconds

                            trades.selling[i] = {
                                item = i,
                                minQuantity = quantityToTrade * 0.4, --40% min quantity, #static for now
                                maxQuantity = quantityToTrade,
                                minPrice = math.abs((quantityToTrade * 0.4) * 0.8),
                                maxPrice = math.abs((quantityToTrade) * 2),
                                timeOffered = currentTime,
                                timeCloses = currentTime + (1000*trades.settings.deadline)
                            }
                            --commands.say("Auction has started for: "..i.." x"..quantityToTrade)
                            os.sleep(0.001) --sleep 1 milliseconds to change timeOffered between items (reference code)
                        end
                    end
                end
            end
        end
        if Utility.getArraySize(trades.buying) < trades.settings.limit then
            -- make a list of all current buying offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.buying[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in buy list, check resources
                    --local itemShort = string.match(i,":(.+)")
                    --print("Searching: "..i)
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        if count < (v*settings.resources.restockThreshold) then
                            print("BuyCount: "..i..", "..count.." < "..(v*settings.resources.restockThreshold))
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
                            if not trades.buying[i] then
                                --trades.buying[i] = {}
                            end
                            --trades.buying[i] = resTable[i]
                        end
                    end
                end
            end
        end
        Utility.writeJsonFile(tradeFile,trades)
    end
end

return TradeAPI
