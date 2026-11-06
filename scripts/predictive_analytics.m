%% predictive_analytics.m
% Trains a Multiple Linear Regression model to predict future soil moisture.
% Generates 24-hour forecast and saves Actual vs Predicted graph.

clear; clc;

basePath = '/MATLAB Drive/Smart_Irrigation_Project';

%% --- LOAD DATASET ---
data = readtable(fullfile(basePath, 'data', 'sensor_data.csv'));
hours       = data.Hour;
temperature = data.Temperature;
humidity    = data.Humidity;
moisture    = data.SoilMoisture;
solar       = data.Solar;

%% --- FEATURE MATRIX ---
X = [temperature(1:end-1), humidity(1:end-1), solar(1:end-1), moisture(1:end-1)];
Y = moisture(2:end);

%% --- SPLIT 80/20 ---
split    = floor(0.8 * length(Y));
X_train  = X(1:split,:);
Y_train  = Y(1:split);
X_test   = X(split+1:end,:);
Y_test   = Y(split+1:end);

%% --- TRAIN MODEL ---
tbl_train = array2table(X_train, ...
    'VariableNames', {'Temperature','Humidity','Solar','PrevMoisture'});
tbl_train.NextMoisture = Y_train;
model = fitlm(tbl_train, ...
    'NextMoisture ~ Temperature + Humidity + Solar + PrevMoisture');
disp(model);

%% --- PREDICT ---
tbl_test = array2table(X_test, ...
    'VariableNames', {'Temperature','Humidity','Solar','PrevMoisture'});
Y_pred = predict(model, tbl_test);

%% --- METRICS ---
errors = Y_test - Y_pred;
MAE    = mean(abs(errors));
RMSE   = sqrt(mean(errors.^2));
R2     = 1 - sum(errors.^2) / sum((Y_test - mean(Y_test)).^2);

fprintf('\n=== Model Performance ===\n');
fprintf('R-squared : %.4f\n', R2);
fprintf('MAE       : %.4f %%\n', MAE);
fprintf('RMSE      : %.4f %%\n', RMSE);

%% --- PLOT: Actual vs Predicted ---
if ~exist(fullfile(basePath,'figures'), 'dir')
    mkdir(fullfile(basePath,'figures'));
end

figure;
t_test = hours(split+2:end);
plot(t_test, Y_test,  'b-',  'LineWidth', 1.2); hold on;
plot(t_test, Y_pred,  'r--', 'LineWidth', 1.2);
xlabel('Hour'); ylabel('Soil Moisture (%)');
title(sprintf('Predictive Analytics: Actual vs Predicted Soil Moisture (R^2=%.3f)', R2));
legend('Actual','Predicted','Location','best');
grid on;
saveas(gcf, fullfile(basePath,'figures','fig9_predicted_vs_actual.png'));
disp('Graph saved.');

%% --- 24-HOUR FORECAST ---
fprintf('\n=== 24-Hour Forecast ===\n');
fprintf('%-10s %-25s\n', 'Hour', 'Predicted Moisture (%)');
fprintf('%s\n', repmat('-',1,35));

last_moisture = moisture(end);
for h = 1:24
    hour_of_day  = mod(720+h, 24);
    future_temp  = 27 + 6*sin(2*pi*(hour_of_day-9)/24);
    future_hum   = 75 - (future_temp-27)*2.5;
    future_solar = 800 * max(0, sin(pi*hour_of_day/12 - pi/6));
    future_row   = array2table([future_temp, future_hum, future_solar, last_moisture], ...
        'VariableNames', {'Temperature','Humidity','Solar','PrevMoisture'});
    last_moisture = predict(model, future_row);
    fprintf('Hour +%-4d %.2f%%\n', h, last_moisture);
end