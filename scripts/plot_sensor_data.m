%% generate_figures.m
% Generates all 10 publication-quality dissertation figures.
% Run generate_sensor_data.m and predictive_analytics.m first.

clear; clc;
basePath = '/MATLAB Drive/Smart_Irrigation_Project';

data        = readtable(fullfile(basePath,'data','sensor_data.csv'));
hours       = data.Hour;
temperature = data.Temperature;
humidity    = data.Humidity;
moisture    = data.SoilMoisture;
solar       = data.Solar;

%% Recompute pump state
pump = zeros(length(moisture),1);
pump(1) = moisture(1) <= 35;
for i = 2:length(moisture)
    if pump(i-1)==1
        pump(i) = moisture(i) < 55;
    else
        pump(i) = moisture(i) <= 35;
    end
end

%% Recompute battery voltage
battery = zeros(length(hours),1);
battery(1) = 12.4;
for i = 2:length(hours)
    if solar(i) > 50
        battery(i) = battery(i-1) + 0.0015*(solar(i)/800);
    elseif pump(i)==1
        battery(i) = battery(i-1) - 0.004;
    else
        battery(i) = battery(i-1) - 0.001;
    end
    battery(i) = min(max(battery(i),10.5),14.4);
end

%% Water consumption
rng(42); n=720;
temp2 = 27 + 6*sin(2*pi*((1:n)'-9)/24) + randn(n,1)*0.8;
hum2  = 75 - (temp2-27)*2.5 + randn(n,1)*2;
hum2  = min(max(hum2,30),95);
moisture2 = zeros(n,1); moisture2(1)=55;
pump2 = zeros(n,1); pump_minutes = zeros(n,1);
for i = 2:n
    hf = max(0.8, temp2(i)/27);
    uf = max(0.8, (100-hum2(i))/25);
    moisture2(i) = moisture2(i-1) - 0.25*hf*uf + randn()*0.2;
    if pump2(i-1)==1
        moisture2(i)=moisture2(i)+6.0;
        pump2(i)=moisture2(i)<55;
        pump_minutes(i)=30;
    else
        pump2(i)=moisture2(i)<=35;
        if pump2(i)==1, pump_minutes(i)=30; end
    end
    moisture2(i)=min(max(moisture2(i),20),70);
end
flow_rate=5; water_per_h=pump_minutes*flow_rate;
cumulative_water=cumsum(water_per_h);
smart_daily=sum(water_per_h)/30;
manual_daily=450;
saving_pct=(manual_daily-smart_daily)/manual_daily*100;
manual_cumulative=(manual_daily/24)*(1:n)';

figPath = fullfile(basePath,'figures');
if ~exist(figPath,'dir'), mkdir(figPath); end

%% Fig 1 — Soil Moisture
figure('Position',[100 100 900 400]);
plot(hours, moisture, 'g-','LineWidth',1.2); hold on;
yline(35,'r--','LineWidth',1.2,'Label','Pump ON threshold (35%)');
yline(55,'b--','LineWidth',1.2,'Label','Pump OFF threshold (55%)');
xlabel('Time (hours)','FontSize',12); ylabel('Soil Moisture (%)','FontSize',12);
title('Figure 1: Soil Moisture vs Time (30 Days)','FontSize',13,'FontWeight','bold');
legend('Soil Moisture','Location','northeast'); grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig1_soil_moisture.png'));
disp('Saved fig1');

%% Fig 2 — Temperature
figure('Position',[100 100 900 400]);
plot(hours, temperature,'r-','LineWidth',1.2);
xlabel('Time (hours)','FontSize',12); ylabel('Temperature (°C)','FontSize',12);
title('Figure 2: Ambient Temperature vs Time (30 Days)','FontSize',13,'FontWeight','bold');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig2_temperature.png'));
disp('Saved fig2');

%% Fig 3 — Humidity
figure('Position',[100 100 900 400]);
plot(hours, humidity,'b-','LineWidth',1.2);
xlabel('Time (hours)','FontSize',12); ylabel('Relative Humidity (%)','FontSize',12);
title('Figure 3: Relative Humidity vs Time (30 Days)','FontSize',13,'FontWeight','bold');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig3_humidity.png'));
disp('Saved fig3');

%% Fig 4 — Solar Irradiance
figure('Position',[100 100 900 400]);
plot(hours, solar,'Color',[0.9 0.6 0],'LineWidth',1.2);
xlabel('Time (hours)','FontSize',12); ylabel('Solar Irradiance (W/m²)','FontSize',12);
title('Figure 4: Solar Irradiance vs Time (30 Days)','FontSize',13,'FontWeight','bold');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig4_solar_irradiance.png'));
disp('Saved fig4');

%% Fig 5 — Battery Voltage
figure('Position',[100 100 900 400]);
plot(hours, battery,'m-','LineWidth',1.2); hold on;
yline(11,'r--','LineWidth',1.2,'Label','Minimum safe voltage (11V)');
yline(14.4,'b--','LineWidth',1.2,'Label','Maximum charge (14.4V)');
xlabel('Time (hours)','FontSize',12); ylabel('Battery Voltage (V)','FontSize',12);
title('Figure 5: Battery Voltage vs Time (30 Days)','FontSize',13,'FontWeight','bold');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig5_battery_voltage.png'));
disp('Saved fig5');

%% Fig 6 — Pump Timeline
figure('Position',[100 100 900 300]);
stairs(1:n, pump2,'k-','LineWidth',1.3);
ylim([-0.2 1.4]); yticks([0 1]); yticklabels({'OFF','ON'});
xlabel('Time (hours)','FontSize',12); ylabel('Pump State','FontSize',12);
title('Figure 6: Pump ON/OFF Timeline — Smart Irrigation (30 Days)','FontSize',13,'FontWeight','bold');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig6_pump_timeline.png'));
disp('Saved fig6');

%% Fig 7 — Cumulative Water
figure('Position',[100 100 900 400]);
plot(1:n, manual_cumulative,'r-','LineWidth',1.4); hold on;
plot(1:n, cumulative_water,'b-','LineWidth',1.4);
xlabel('Time (hours)','FontSize',12); ylabel('Cumulative Water Used (L)','FontSize',12);
title('Figure 7: Cumulative Water Consumption Comparison (30 Days)','FontSize',13,'FontWeight','bold');
legend('Manual Irrigation','Smart Irrigation','Location','northwest');
grid on; xlim([1 720]);
saveas(gcf,fullfile(figPath,'fig7_water_consumption.png'));
disp('Saved fig7');

%% Fig 8 — Water Saving Bar Chart
figure('Position',[100 100 600 450]);
b = bar([manual_daily, smart_daily],0.5);
b.FaceColor='flat'; b.CData=[0.8 0.2 0.2; 0.2 0.6 0.2];
xticks([1 2]); xticklabels({'Manual Irrigation','Smart Irrigation'});
ylabel('Average Daily Water Use (L)','FontSize',12);
title(sprintf('Figure 8: Water Saving Analysis\n(Smart system saves %.1f%% vs fixed-schedule irrigation)',saving_pct),...
    'FontSize',13,'FontWeight','bold');
grid on;
text(1,manual_daily+5,sprintf('%.0f L/day',manual_daily),'HorizontalAlignment','center','FontSize',11,'FontWeight','bold');
text(2,smart_daily+5,sprintf('%.0f L/day',smart_daily),'HorizontalAlignment','center','FontSize',11,'FontWeight','bold');
saveas(gcf,fullfile(figPath,'fig8_water_saving.png'));
disp('Saved fig8');

