--[[
%% properties
146 energy 
148 energy
%% weather
%% events
%% globals
--]]

------------------------------------------------------------------------------------------------
-- Scene will be triggerd every time one of devices in scene header report new energy reading --
------------------------------------------------------------------------------------------------

--- configuration ---

local energyDevicesIds = {146, 148,150,170} -- IDs of all devices with energy metering which will be sumed to total energy consumption, add them also in scene header

local firstStepDevicesToTurnOff = {148} -- IDs of all devices which should be turned off after crossing first upper bound of total energy consumption threshold
local secondStepDevicesToTurnOff = {146} -- IDs of all devices which should be turned off after crossing second upper bound of total energy consumption threshold

local autoResetEnergy = true -- "true" if after crossing energy threshold all accumulated energy readings need to be cleared
-- Two steps Max Upper Bound Threshold
local accumulatedEnergyFirstMaxThreshold = 2.8 -- accumulated energy first upper bound threshold in kWh
local accumulatedEnergySecondMaxThreshold = 2.3 -- accumulated energy second upper bound threshold in kWh
-- Two steps Min Upper Bound Threshold
local accumulatedEnergyFirstMinThreshold = 2 -- accumulated energy first lower bound threshold in kWh
local accumulatedEnergySecondMinThreshold = 1.5 -- accumulated energy second lower bound threshold in kWh
local userIdToSendNotification = 1 

--- functions ---

function getAccumulatedEnergy(IDs) -- sums up accumulated energy from all devices
    local energy = 0
        for i = 1, #IDs do
            energy = energy + fibaro:getValue(IDs[i], "energy")
        end
    return energy
end

function turnOffDevices(IDs)
	for i = 1, #IDs do
		fibaro:call(IDs[i], "turnOff")
		fibaro:call(userIdToSendNotification,"sendEmail", "Fibaro, device turned Off","Fibaro device: "+fibaro:getName(IDs[i])+" was turned off by scene")
	end    
end

function turnOnDevices(IDs)
	for i = 1, #IDs do
		fibaro:call(IDs[i], "turnOn")
		fibaro:call(userIdToSendNotification,"sendEmail", "Fibaro, device turned On","Fibaro device: "+fibaro:getName(IDs[i])+" was turned on by scene")
	end
end

function resetEnergy(IDs)
	if autoResetEnergy then
		for i = 1, #IDs do
        	fibaro:call(IDs[i], "reset")
    	end   
	end 
end

--- main code ---
local accumulatedEnergy = tonumber(getAccumulatedEnergy(energyDevicesIds)) 

if accumulatedEnergy == accumulatedEnergyFirstMaxThreshold then  -- Turn Off first step devices when accumulated energy is greater then first Max Threshold
	if fibaro:getGlobal("isFirstStepTurnedOn") then
		turnOffDevices(firstStepDevicesToTurnOff)
		fibaro:setGlobal("isFirstStepTurnedOn",false)
		resetEnergy(firstStepDevicesToTurnOff) -- Reset local energy within first step devices
	end
else
	if accumulatedEnergy == accumulatedEnergySecondMaxThreshold then -- Turn Off second step devices when accumulated energy is in between of second and first Max Thresholds
		if fibaro:getGlobal("isSecondStepTurnedOn") then
			turnOffDevices(secondStepDevicesToTurnOff)
			fibaro:setGlobal("isSecondStepTurnedOn",false)
			resetEnergy(secondStepDevicesToTurnOff) -- Reset local energy within first step devices
		end 
	else 
		if accumulatedEnergy == accumulatedEnergyFirstMinThreshold then -- Turn On first step devices when accumulated energy is is in between of second and first Min Thresholds
			if not fibaro:getGlobal("isFirstStepTurnedOn") then
				turnOnDevices(firstStepDevicesToTurnOff)
				fibaro:setGlobal("isFirstStepTurnedOn",true)

			end 
		else
			if accumulatedEnergy == accumulatedEnergySecondMinThreshold then -- Turn On second step devices when accumulated energy is lower then first Min Threshold
				if not fibaro:getGlobal("isSecondStepTurnedOn") then
					turnOnDevices(secondStepDevicesToTurnOff)
					fibaro:setGlobal("isSecondStepTurnedOn",true)
				end
			end 
		end
	end
end 


