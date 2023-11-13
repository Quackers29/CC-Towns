-- Seed the random number generator
math.randomseed(os.time())

local filePath = "file2.txt"
local writeData = "Computer 1 was here!\n"  -- Change this for the second computer

local function testFileAccess()
    -- Attempt to open the file for reading and appending
    local file = io.open(filePath, "r")

    if file then
        -- Go to the start of the file to read from the beginning
        file:seek("set")

        -- Read the contents of the file
        contents = file:read("*a")
        print("Before write: ", contents)

        local lineCount = 0
        for _ in file:lines() do
            lineCount = lineCount + 1
        end
        print("Total lines in the file:", lineCount)
        
        -- Wait for a random time between 0 and 2 seconds
        -- os.sleep(math.random() * 4)

        -- Go to the end of the file to append data
        file:seek("set")

        -- Write some data to the file
        --file:write(writeData)

        -- Flush the written data to the file
        --file:flush()

        -- Go to the start of the file to read the new contents
        --file:seek("set")
        contents = file:read("*a")
        print("After write: ", contents)

        -- Close the file
        file:close()
    else
        print("Failed to open or create file.")
    end
end

local line_count = 0
local file = fs.open(filePath, "r") -- Make sure to replace with your actual file path

-- This function counts the number of lines with actual data (ignoring empty or whitespace-only lines) in a text file.
function countDataLines(filePath)
    local line_count = 0
    local file = fs.open(filePath, "r") -- Open the file in read mode

    if not file then
        --print("Could not open file at " .. filePath)
        return 0 -- Return 0 if the file cannot be opened
    end

    while true do
        local line = file.readLine()
        if line == nil then break end -- End of file
        if string.match(line, "%S") then -- Check if line has non-whitespace characters
            line_count = line_count + 1
        end
    end

    file.close() -- Always close the file when done
    return line_count
end

-- Usage:
-- local numberOfDataLines = countDataLines("path_to_your_file.txt")
-- print("Number of lines with data in the file:", numberOfDataLines)

print(countDataLines(filePath))
testFileAccess()
