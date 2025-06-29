clear all
clc
close all


% Load your data
data = loadLTspiceTransient('GC_temp_CSMAG01w.raw');

% plot the results
figure (1)
plot( data.data(:,2), data.data(:,1));
grid;

% Print data summary
fprintf('Data load summary\n');
fprintf('*** Assumption: two variables of transient simulation ***\n');
fprintf('Time points: %d\n', length(data.time));
fprintf('Time range: %.6f to %.6f seconds\n', min(data.time), max(data.time));
fprintf('Variables: %s, %s\n', data.variables{1}, data.variables{2});
fprintf('%s range: %.3f to %.3f V\n', data.variables{1}, min(data.data(:,1)), max(data.data(:,1)));
fprintf('%s range: %.1f to %.1f V\n', data.variables{2},min(data.data(:,2)), max(data.data(:,2)));

