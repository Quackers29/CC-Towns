-- Seed the random number generator
math.randomseed(os.time())

local filePath = "file.txt"
local writeData = "Computer 2 was here!\n"  -- Change this for the second computer

local function testFileAccess()
    -- Attempt to open the file for reading and appending
    local file = io.open(filePath, "a")

    if file then
        -- Go to the start of the file to read from the beginning
        file:seek("set")

        -- Read the contents of the file
        local contents = file:read("*a")
        print("Before write: ", contents)

        -- Wait for a random time between 0 and 2 seconds
        os.sleep(math.random() * 4)

        -- Go to the end of the file to append data
        file:seek("end")

        -- Write some data to the file
        file:write(writeData)

        -- Flush the written data to the file
        file:flush()

        -- Go to the start of the file to read the new contents
        file:seek("set")
        contents = file:read("*a")
        print("After write: ", contents)

        -- Close the file
        file:close()
    else
        print("Failed to open or create file.")
    end
end

testFileAccess()
