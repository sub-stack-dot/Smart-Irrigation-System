%% irrigation_logic.m
% Step 6-7: Recomputes pump ON/OFF from soil moisture using a clean
% rule-based controller (independent of the dataset's built-in pump
% column), then calculates water consumption.
%
% This is the part of your dissertation that maps directly to:
% "when soil moisture drops below a threshold, the ESP32 activates the
%  pump, and once the required moisture level is reached, the pump
%  switches off automatically."

clear; clc;

sensorData = readtable(fullfile('data','sensor_data.csv'));
moisture = sensorData.SoilMoisture;
n = height(sensorData);

%% --- Controller parameters ---
threshold_low  = 35;   % % moisture - pump turns ON at/below this
threshold_high = 55;   % % moisture - pump turns OFF at/above this
flow_rate_Lmin = 5;    % L/min, from your proposal's pump spec
interval_min   = 10;   % matches the dataset's sampling interval

%% --- Hysteresis controller (avoids rapid ON/OFF "chattering") ---
pumpState = zeros(n,1);
pumpState(1) = moisture(1) <= threshold_low;

for i = 2:n
    if pumpState(i-1) == 1
        % pump was ON, stays ON until moisture recovers
        pumpState(i) = moisture(i) < threshold_high;
    else
        % pump was OFF, stays OFF until moisture drops too low
        pumpState(i) = moisture(i) <= threshold_low;
    end
end

%% --- Water consumption ---
minutes_on_per_sample = pumpState * interval_min;
water_per_sample_L = minutes_on_per_sample * flow_rate_Lmin;

total_pump_minutes = sum(minutes_on_per_sample);
total_water_L = sum(water_per_sample_L);

fprintf('Total pump ON time: %.1f minutes (%.2f hours)\n', ...
    total_pump_minutes, total_pump_minutes/60);
fprintf('Total water consumed: %.1f L\n', total_water_L);

%% --- Save results back for later steps ---
sensorData.PumpState_computed = pumpState;
sensorData.WaterUsed_L = cumsum(water_per_sample_L);
writetable(sensorData, fullfile('data','sensor_data_with_irrigation.csv'));

disp('Saved data/sensor_data_with_irrigation.csv with pump + water columns.');
