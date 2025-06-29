    % MIT License
    % 
    % Copyright (c) 2025 Roman
    % 
    % Permission is hereby granted, free of charge, to any person obtaining a copy
    % of this software and associated documentation files (the "Software"), to deal
    % in the Software without restriction, including without limitation the rights
    % to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    % copies of the Software, and to permit persons to whom the Software is
    % furnished to do so, subject to the following conditions:
    % 
    % The above copyright notice and this permission notice shall be included in all
    % copies or substantial portions of the Software.
    % 
    % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    % IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    % OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    % SOFTWARE.

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

