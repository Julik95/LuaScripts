local devicesToBeTurnedOff = {
	runnable=true,
	id_277={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_273={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_223={
		maxPower=2900,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2500
	},
	id_252={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_241={
		maxPower=2900,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/light/light100.png",
		state="ON",
		minPower=2500
	},
	id_255={
		maxPower=2900,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/light/light100.png",
		state="ON",
		minPower=2500
	},
	id_245={
		maxPower=2900,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/light/light100.png",
		state="ON",
		minPower=2500
	},
	id_250={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_236={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_275={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_271={
		maxPower=3200,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=2900
	},
	id_343={
		maxPower=2900,
		oldSate="EMRGCY",
		time=nil,
		icon="assets/icon/fibaro/onoff/onoff100.png",
		state="ON",
		minPower=200
	}
}

local energyDevicesIds = {223, 236, 238, 241, 245, 250, 252, 255, 271, 273, 275, 277,343}
local conf = json.decode(tostring(fibaro.getGlobalVariable("PowerConsumption")))
local devicesOff = {}
local devicesOn = {}
local usersToBeNotified = {171,172,173,290}
local offset = 0 -- in sec.
local maxConsumption = 85 -- Value espressed in %

--TEST START
local testUsers = {171}
local firstEmergencyDevices = {}
--TEST END

--FUNCTIONS:
function getPowerSum(IDs)
    local power = 0
        for i = 1, #IDs do
            power = power + fibaro.getValue(IDs[i], "power")
        end
        for i = 1, #IDs do
            local currDeviceConsumption = (tonumber(fibaro.getValue(IDs[i], "power"))*100)/tonumber(power)
            --fibaro.debug("Power Consumption",fibaro.getName(IDs[i]).." consuma: "..tostring(currDeviceConsumption))
            if currDeviceConsumption > maxConsumption then
				fibaro.debug("Power Consumption","E' stato rillevato il disposittivo che consuma: "..fibaro.getValue(IDs[i], "power").." Watt.")
                doWarningNotification(IDs[i], power)
            end
        end
    return power
end
function getNotificationOnTurnOff(threshold,devices)
    local result = "É stata raggiunta la soglia di("..tostring(threshold).." W). Pertanto i disposittivi: \n"
    for i = 1, #devices do
		result = result..fibaro.getName(devices[i]).."\n"
	end
    result = result.."verranno disattivati."
    return result
end
function getNotificationOnTurnOn(threshold,devices)
    local result = "É stata raggiunta la soglia di ("..tostring(threshold).." W). Pertanto i disposittivi: \n"
    for i = 1, #devices do
		result = result..fibaro.getName(devices[i]).."\n"
	end
    result = result.."verranno riattivati."
    return result
end
function getTestNotification(threshold,devices)
    local result = "É stata raggiunta la soglia di ("..tostring(threshold).." W). Pertanto i disposittivi: \n"
    for i = 1, #devices do
		result = result..fibaro.getName(devices[i]).."\n"
	end
    result = result.."verranno disattivati tra"..offset.." secondi."
    return result
end
function doWarningNotification(id,consumption)
	local day = os.date("%A")
	local hour = os.date("%H")
	if day ~= "Saturday" and day ~= "Sunday" and tonumber(hour) < 19 then
		api.post("/mobile/push", {
    		["data"] = {
        		["actionName"] = "turnOff", 
        		["deviceId"] = id, 
    		}, 
    		["mobileDevices"] = {
    			[1] = 338, 
    			[2] = 332,
    			[3] = 132,
    			[4] = 157
    		}, 
    		["service"] = "Device", 
    		["action"] = "RunAction", 
    		["title"] = "Consumo elevato prima delle ore 19:00", 
    		["message"] = "É stato rillevato il consumo pari a: "..tostring(consumption).." (W) per il disposittivo - "..fibaro.getName(id).." prima delle ore 19:00. Desideri disattivare "..fibaro.getName(id).."?",
    		["category"] = "YES_NO", 
		})
	end
end
--MAIN
if tostring(conf.runnable) == "true" then
	local currentPowerConsumption = tonumber(getPowerSum(energyDevicesIds)) 
	fibaro.debug("Power Consumption","Consumo attuale: "..tostring(currentPowerConsumption))
	for device, props in pairs(conf) do 
		if tostring(device) ~= "runnable" then 
			local deviceId = tonumber(string.match(tostring(device), "_(.*)"))
		    if currentPowerConsumption >= tonumber(props.maxPower) then
		    	if props.time == "nil" then
		    		props.time = tonumber(os.time())
		    		table.insert(firstEmergencyDevices, deviceId)
		    	else
		    		if (tonumber(os.time()) - tonumber(props.time)) > offset then
				    	if fibaro.getValue(deviceId, "state") then
				    		props.state = "EMRGCY"
				    		props.oldSate = "ON"
				    		props.time = "nil"
				    		table.insert(devicesOff, deviceId)
				    		fibaro.call(deviceId, "turnOff")
				    		fibaro.debug("Power Consumption","Il disposittivo: "..fibaro.getName(deviceId).." è stato disattivato.")
				    	end
				    end
			    end
		    end
		    if currentPowerConsumption <= tonumber(props.minPower) then
                props.time = "nil"
		    	if tostring(props.state) == "EMRGCY" then 
		    		if (not fibaro.getValue(deviceId, "state")) and tostring(props.oldSate) == "ON" then
		    			props.state = "ON"
		    			table.insert(devicesOn, deviceId)
		    			fibaro.call(deviceId, "turnOn")
		    			fibaro.debug("Power Consumption","Il disposittivo: "..fibaro.getName(deviceId).." è stato riattivato.")
		    		else
		    			props.state = "OFF"
		    		end
		    		props.oldSate = "EMRGCY"
		    	end
		    end
		end
	end
    fibaro.setGlobalVariable("PowerConsumption",tostring(json.encode(conf)))
	if next(devicesOff) ~= nil then
	   fibaro.alert("push",usersToBeNotified,getNotificationOnTurnOff(currentPowerConsumption,devicesOff))
	end
	if next(devicesOn) ~= nil then
	   fibaro.alert("push",usersToBeNotified,getNotificationOnTurnOn(currentPowerConsumption,devicesOn))
	end

	--TEST START
	if next(firstEmergencyDevices) ~= nil then
	   fibaro.alert("push",testUsers,getTestNotification(currentPowerConsumption,firstEmergencyDevices))
	end
	--TEST END
end

