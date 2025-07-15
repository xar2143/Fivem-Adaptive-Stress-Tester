--[[
  FiveM Adaptive Stress Tester
  Author: xar2143 © 2025

  Licensed under GNU GPL v3
  See LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html
]]

local StressTester = {}
local isTestRunning = false
local testResults = {}
local testStartTime = 0
local eventCounter = 0
local httpCounter = 0
local activeThreads = 0
local maxThreads = 0

-- Cfg
local Config = {
    maxDuration = 60000, -- max test duration in ms (default 60 seconds)
    minDelay = 50, -- minimum delay between operations (ms)
    maxDelay = 500, -- maximum delay between operations (ms)
    memoryThreshold = 0.8, -- stop if memory usage exceeds (default 80%)
    cpuThreshold = 0.9, -- stop if CPU usage exceeds (default 90%)
    maxConcurrentHttp = 5, -- maximum concurrent HTTP requests (reduced)
    reportInterval = 10000, -- progress report interval (ms)
}

local function getSystemResources()
    local resources = {}
    
    collectgarbage("collect")
    local memBefore = collectgarbage("count")
    local largeTable = {}
    for i = 1, 1000 do
        largeTable[i] = string.rep("test", 100)
    end
    local memAfter = collectgarbage("count")
    largeTable = nil
    collectgarbage("collect")
    
    resources.memoryUsage = memBefore / 1024
    resources.memoryAvailable = math.max(512 - resources.memoryUsage, 64) 
    
    local resourceCount = GetNumResources()
    resources.estimatedCpuLoad = math.min(resourceCount / 100, 0.9)
    resources.cpuAvailable = 1.0 - resources.estimatedCpuLoad
    
    return resources
end

local function calculateAdaptiveLoad()
    local resources = getSystemResources()
    local baseLoad = 50 
    
    local memoryFactor = math.max(0.2, math.min(2.0, resources.memoryAvailable / 256))
    
    local cpuFactor = math.max(0.2, math.min(1.0, resources.cpuAvailable))
    
    local adaptiveLoad = math.floor(baseLoad * memoryFactor * cpuFactor)
    adaptiveLoad = math.max(5, math.min(100, adaptiveLoad))
    maxThreads = math.max(5, math.min(50, adaptiveLoad))
    
    return {
        eventsPerCycle = adaptiveLoad,
        httpPerCycle = math.max(1, math.floor(adaptiveLoad * 0.3)),
        delayBetweenCycles = math.max(Config.minDelay, math.min(Config.maxDelay, math.floor(100 / cpuFactor))),
        memoryFactor = memoryFactor,
        cpuFactor = cpuFactor,
        resources = resources
    }
end

local function simulateComputationalLoad()
    local iterations = math.random(1000, 5000)
    local result = 0
    
    for i = 1, iterations do
        result = result + math.sqrt(i) * math.sin(i) + math.cos(i * 0.5)
    end
    
    return result
end

local function simulateDatabaseOperation()
    local data = {}
    for i = 1, math.random(10, 100) do
        data[tostring(i)] = {
            id = i,
            name = "Player_" .. i,
            score = math.random(100, 9999),
            timestamp = os.time(),
            data = string.rep("x", math.random(50, 200))
        }
    end
    
    local sortedData = {}
    for k, v in pairs(data) do
        table.insert(sortedData, v)
    end
    
    table.sort(sortedData, function(a, b) return a.score > b.score end)
    
    return #sortedData
end

local function simulateEvent(eventName, eventData)
    TriggerEvent(eventName, eventData)
    eventCounter = eventCounter + 1
end

-- THIS PART IS NOT A BACKDOOR IT IS AN HTTP REQUEST SIMULATION
local function simulateHttpRequest()
    if httpCounter >= Config.maxConcurrentHttp then
        return
    end
    
    httpCounter = httpCounter + 1

    PerformHttpRequest("https://httpbin.org/get", function(errorCode, resultData, resultHeaders)
        httpCounter = httpCounter - 1
      
        if errorCode == 200 and resultData then
            local dataLength = string.len(resultData)
        
            for i = 1, math.min(dataLength, 100) do
                local char = string.byte(resultData, i)
                if char then
                 
                    local processed = char * 2
                end
            end
        end
    end, "GET", "", {["Content-Type"] = "application/json"})
end

local function stressTestCycle(loadConfig)
    if not isTestRunning then return end
    
    activeThreads = activeThreads + 1
    
    Citizen.CreateThread(function()
     
        for i = 1, loadConfig.eventsPerCycle do
            if not isTestRunning then break end
            
            local eventTypes = {
                "stress:testEvent",
                "stress:playerAction",
                "stress:serverEvent",
                "stress:databaseQuery",
                "stress:networkEvent"
            }
            
            local eventName = eventTypes[math.random(#eventTypes)]
            local eventData = {
                playerId = math.random(1, 128),
                action = "test_action_" .. math.random(1, 1000),
                timestamp = os.time(),
                payload = simulateComputationalLoad(),
                dbResult = simulateDatabaseOperation()
            }
            
            simulateEvent(eventName, eventData)
            
            if i % 5 == 0 then
                Citizen.Wait(0) 
            end
        end
        
        if math.random(1, 3) == 1 then 
            for i = 1, math.min(3, loadConfig.httpPerCycle) do
                if not isTestRunning then break end
                simulateHttpRequest()
                Citizen.Wait(math.random(100, 300)) 
            end
        end
        
        activeThreads = activeThreads - 1
        
        if isTestRunning then
            Citizen.SetTimeout(loadConfig.delayBetweenCycles, function()
                stressTestCycle(loadConfig)
            end)
        end
    end)
end

local function monitorProgress()
    if not isTestRunning then return end
    
    local elapsed = GetGameTimer() - testStartTime
    local resources = getSystemResources()
    
    print(string.format("^3[STRESS TEST] ^7Progress: %.1fs | Events: %d | HTTP: %d | Threads: %d | Memory: %.1fMB | CPU Est: %.1f%%",
        elapsed / 1000,
        eventCounter,
        httpCounter,
        activeThreads,
        resources.memoryUsage,
        resources.estimatedCpuLoad * 100
    ))
    
    if resources.memoryUsage > (Config.memoryThreshold * 512) or 
       resources.estimatedCpuLoad > Config.cpuThreshold then
        print("^1[STRESS TEST] ^7Stopping due to high resource usage!")
        StressTester.stopTest()
        return
    end
    
    Citizen.SetTimeout(Config.reportInterval, monitorProgress)
end

local function generateReport()
    local endTime = GetGameTimer()
    local totalDuration = endTime - testStartTime
    local resources = getSystemResources()
  
    local safeEventCount = eventCounter or 0
    local safeHttpCount = httpCounter or 0
    local safeDuration = math.max(1, totalDuration or 1)
    
    testResults = {
        duration = safeDuration,
        totalEvents = safeEventCount,
        totalHttp = safeHttpCount,
        eventsPerSecond = (safeEventCount / safeDuration) * 1000,
        httpPerSecond = (safeHttpCount / safeDuration) * 1000,
        avgEventTime = safeEventCount > 0 and (safeDuration / safeEventCount) or 0,
        maxActiveThreads = maxThreads or 0,
        finalMemoryUsage = resources.memoryUsage or 0,
        finalCpuLoad = (resources.estimatedCpuLoad or 0) * 100
    }
    
    print("\n^2========================================")
    print("^2         STRESS TEST REPORT")
    print("^2========================================^7")
    print(string.format("^3Test Duration:^7 %.2f seconds", testResults.duration / 1000))
    print(string.format("^3Total Events:^7 %d", testResults.totalEvents))
    print(string.format("^3Total HTTP Requests:^7 %d", testResults.totalHttp))
    print(string.format("^3Events per Second:^7 %.2f", testResults.eventsPerSecond))
    print(string.format("^3HTTP per Second:^7 %.2f", testResults.httpPerSecond))
    print(string.format("^3Average Event Time:^7 %.2f ms", testResults.avgEventTime))
    print(string.format("^3Max Active Threads:^7 %d", testResults.maxActiveThreads))
    print(string.format("^3Final Memory Usage:^7 %.1f MB", testResults.finalMemoryUsage))
    print(string.format("^3Final CPU Load:^7 %.1f%%", testResults.finalCpuLoad))
    print("^2========================================^7\n")
end

function StressTester.startTest(duration)
    if isTestRunning then
        print("^1[STRESS TEST] ^7Test already running!")
        return
    end
    
    duration = duration or Config.maxDuration
    
    print("^2[STRESS TEST] ^7Initializing adaptive stress test...")
 
    isTestRunning = true
    testStartTime = GetGameTimer()
    eventCounter = 0
    httpCounter = 0
    activeThreads = 0

    local loadConfig = calculateAdaptiveLoad()
    
    print("^2[STRESS TEST] ^7Configuration:")
    print(string.format("^3- Events per cycle:^7 %d", loadConfig.eventsPerCycle))
    print(string.format("^3- HTTP per cycle:^7 %d", loadConfig.httpPerCycle))
    print(string.format("^3- Delay between cycles:^7 %d ms", loadConfig.delayBetweenCycles))
    print(string.format("^3- Memory factor:^7 %.2f", loadConfig.memoryFactor))
    print(string.format("^3- CPU factor:^7 %.2f", loadConfig.cpuFactor))
    print(string.format("^3- Available memory:^7 %.1f MB", loadConfig.resources.memoryAvailable))
    print(string.format("^3- Available CPU:^7 %.1f%%", loadConfig.resources.cpuAvailable * 100))
    print(string.format("^3- Max duration:^7 %d seconds", math.floor(duration / 1000)))
    
    monitorProgress()
    
    for i = 1, math.min(5, maxThreads) do
        Citizen.SetTimeout(i * 100, function()
            stressTestCycle(loadConfig)
        end)
    end

    Citizen.SetTimeout(duration, function()
        if isTestRunning then
            StressTester.stopTest()
        end
    end)
    
    print("^2[STRESS TEST] ^7Started! Use '/stresstest stop' to end manually.")
end

function StressTester.stopTest()
    if not isTestRunning then
        print("^1[STRESS TEST] ^7No test running!")
        return
    end
    
    isTestRunning = false
    print("^2[STRESS TEST] ^7Stopping and generating report...")
    
    Citizen.SetTimeout(1000, function()
        generateReport()
    end)
end

RegisterServerEvent("stress:testEvent")
AddEventHandler("stress:testEvent", function(data)
   
    if data and data.payload then
        local result = data.payload * 0.5
      
        Citizen.Wait(math.random(1, 3))
    end
end)

RegisterServerEvent("stress:playerAction")
AddEventHandler("stress:playerAction", function(data)
   
    if data and data.playerId then
        local processing = string.rep("x", math.random(10, 100))
     
        Citizen.Wait(math.random(1, 5))
    end
end)

RegisterServerEvent("stress:serverEvent")
AddEventHandler("stress:serverEvent", function(data)
    
    if data then
        simulateComputationalLoad()
    end
end)

RegisterServerEvent("stress:databaseQuery")
AddEventHandler("stress:databaseQuery", function(data)
 
    if data and data.dbResult then
        local result = simulateDatabaseOperation()
        Citizen.Wait(math.random(5, 15))
    end
end)

RegisterServerEvent("stress:networkEvent")
AddEventHandler("stress:networkEvent", function(data)
   
    if data then
        local networkLoad = string.rep("data", math.random(20, 200))
        Citizen.Wait(math.random(1, 10))
    end
end)

RegisterCommand("stresstest", function(source, args, rawCommand)
    if source ~= 0 then
        print("^1[STRESS TEST] ^7This command can only be used from the server console!")
        return
    end
    
    local action = args[1] or "start"
    
    if action == "start" then
        local duration = tonumber(args[2]) or Config.maxDuration
        StressTester.startTest(duration)
    elseif action == "stop" then
        StressTester.stopTest()
    elseif action == "status" then
        if isTestRunning then
            local elapsed = GetGameTimer() - testStartTime
            local resources = getSystemResources()
            print(string.format("^2[STRESS TEST] ^7Running for %.1fs | Events: %d | HTTP: %d | Threads: %d | Memory: %.1fMB",
                elapsed / 1000, eventCounter, httpCounter, activeThreads, resources.memoryUsage))
        else
            print("^1[STRESS TEST] ^7No test currently running.")
        end
    else
        print("^3[STRESS TEST] ^7Usage:")
        print("^7- stresstest start [duration_ms] - Start stress test")
        print("^7- stresstest stop - Stop current test")
        print("^7- stresstest status - Show current status")
    end
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName and isTestRunning then
        StressTester.stopTest()
    end
end)

print("^2[STRESS TEST] ^7FiveM Adaptive Stress Tester loaded!")
print("^3Usage: ^7stresstest start [duration_ms] | stresstest stop | stresstest status")
