%% generate_sensor_data.m
% Generates a realistic synthetic sensor dataset for the Smart Irrigation
% project. Simulates 5 days of data at 10-minute intervals.
% Run this FIRST. It saves data/sensor_data.csv for the rest of the project.

clear; clc;

%% Settings
days = 5;
interval_minutes = 10;
samples_per_day = (24*60) / interval_minutes;     % 144 samples/day
total_samples = days * samples_per_day;

t = (0:total_samples-1)';                          % sample index
time_hours = mod(t * interval_minutes / 60, 24);    % hour-of-day, 0-24

%% --- Solar irradiance (W/m^2) ---
% Bell curve centered at noon, zero at night, with some cloud noise.
solar = 800 * max(0, sin(pi * (time_hours - 6) / 12));   % daylight 6am-6pm
solar = solar + randn(size(solar)) * 15;                 % sensor noise
solar(solar < 0) = 0;

%% --- Ambient temperature (deg C) ---
% Warmest mid-afternoon, coolest before dawn.
temperature = 27 + 6 * sin(pi * (time_hours - 9) / 12);
temperature = temperature + randn(size(temperature)) * 0.5;

%% --- Humidity (%) ---
% Inversely related to temperature, roughly.
humidity = 75 - (temperature - 27) * 2.5;
humidity = humidity + randn(size(humidity)) * 2;
humidity = min(max(humidity, 30), 95);

%% --- Soil moisture (%) with irrigation feedback loop ---
% Decreases over time (evaporation + plant uptake), pump kicks in below
% threshold and raises it back up. This makes Step 6 (irrigation logic)
% meaningful when you re-run it on this data.
moisture = zeros(total_samples, 1);
pump_state = zeros(total_samples, 1);
moisture(1) = 55;

moisture_threshold_low = 35;   % pump ON below this
moisture_threshold_high = 55;  % pump OFF at/above this
evap_rate = 0.15;               % % moisture lost per sample (heat-dependent)
pump_recharge_rate = 1.8;       % % moisture gained per sample while pump ON

for i = 2:total_samples
    % heat increases evaporation
    heat_factor = max(0.5, temperature(i)/27);
    loss = evap_rate * heat_factor;

    if pump_state(i-1) == 1
        % pump was on last step
        moisture(i) = moisture(i-1) + pump_recharge_rate - loss;
        if moisture(i) >= moisture_threshold_high
            pump_state(i) = 0;
        else
            pump_state(i) = 1;
        end
    else
        moisture(i) = moisture(i-1) - loss;
        if moisture(i) <= moisture_threshold_low
            pump_state(i) = 1;
        else
            pump_state(i) = 0;
        end
    end
end
moisture = min(max(moisture, 0), 100);

%% --- Battery voltage (V), nominal 12V lead-acid style system ---
% Charges when solar > 0, discharges slowly when pump or load draws power.
battery_voltage = zeros(total_samples, 1);
battery_voltage(1) = 12.4;
charge_rate = 0.0015;   % V gained per sample per (solar/800) when charging
discharge_rate = 0.004; % V lost per sample when pump running, no charge

for i = 2:total_samples
    charging = solar(i) > 50;
    if charging
        battery_voltage(i) = battery_voltage(i-1) + charge_rate * (solar(i)/800);
    elseif pump_state(i) == 1
        battery_voltage(i) = battery_voltage(i-1) - discharge_rate;
    else
        battery_voltage(i) = battery_voltage(i-1) - discharge_rate * 0.3;
    end
    battery_voltage(i) = min(max(battery_voltage(i), 10.5), 14.4);
end

%% --- Assemble table ---
sensorData = table(t, time_hours, temperature, humidity, moisture, solar, ...
    pump_state, battery_voltage, ...
    'VariableNames', {'SampleIndex','TimeHour','Temperature','Humidity', ...
                      'SoilMoisture','SolarIrradiance','PumpState','BatteryVoltage'});

%% --- Save ---
if ~exist('data', 'dir')
    mkdir('data');
end
writetable(sensorData, fullfile('data','sensor_data.csv'));

disp('sensor_data.csv created successfully.');
disp(sensorData(1:8,:));
