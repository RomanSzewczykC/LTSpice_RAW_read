# LTspice Transient Data Loader

## Overview

This MATLAB/Octave package provides functionality to load and analyze transient simulation data from LTspice `.raw` files. The package consists of two main components:

- **`loadLTspiceTransient.m`** - Core function for reading binary LTspice raw files
- **`test_loadLTspiceTransient.m`** - Example script demonstrating usage

## Features

- **Binary Format Support**: Reads LTspice binary `.raw` files efficiently
- **Transient Analysis**: Specifically designed for transient simulation data
- **Metadata Extraction**: Parses simulation parameters and variable information
- **Error Handling**: Comprehensive validation and error reporting
- **Cross-Platform**: Compatible with both MATLAB and Octave

## Quick Start

```matlab
% Load transient simulation data
data = loadLTspiceTransient('your_simulation.raw');

% Plot results
figure;
plot(data.data(:,2), data.data(:,1));
xlabel(data.variables{2});
ylabel(data.variables{1});
grid on;

% Display summary
fprintf('Time points: %d\n', length(data.time));
fprintf('Variables: %s, %s\n', data.variables{1}, data.variables{2});
```

## Function Reference

### `loadLTspiceTransient(filename)`

Loads transient simulation data from LTspice binary raw files.

#### Syntax

```matlab
ltsData = loadLTspiceTransient(filename)
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `filename` | string | Path to LTspice `.raw` file (relative or absolute) |

#### Return Value

Returns a structure `ltsData` containing:

| Field | Type | Description |
|-------|------|-------------|
| `time` | double array | Time vector from simulation |
| `variables` | cell array | Variable names (excluding time) |
| `data` | double matrix | Data matrix where each column corresponds to a variable |
| `metadata` | struct | Simulation metadata and parameters |

#### Metadata Structure

The `metadata` field contains:

| Field | Type | Description |
|-------|------|-------------|
| `plotname` | string | Simulation plot name |
| `flags` | string | Simulation flags |
| `num_vars` | integer | Number of variables (excluding time) |
| `num_points` | integer | Number of data points |
| `offset` | double | Time offset value |
| `var_names` | cell array | Variable names |
| `var_types` | cell array | Variable types |

## Usage Examples

### Basic Data Loading and Plotting

```matlab
clear all; clc; close all;

% Load simulation data
data = loadLTspiceTransient('GC_temp_CSMAG01w.raw');

% Create time-domain plot
figure(1);
plot(data.time, data.data(:,1));
xlabel('Time (s)');
ylabel(sprintf('%s (V)', data.variables{1}));
title('Transient Analysis Results');
grid on;

% Create X-Y plot between variables
figure(2);
plot(data.data(:,2), data.data(:,1));
xlabel(sprintf('%s (V)', data.variables{2}));
ylabel(sprintf('%s (V)', data.variables{1}));
grid on;
```

### Data Analysis and Summary

```matlab
% Load data
data = loadLTspiceTransient('simulation.raw');

% Print comprehensive summary
fprintf('=== LTspice Simulation Analysis ===\n');
fprintf('Plot Name: %s\n', data.metadata.plotname);
fprintf('Simulation Flags: %s\n', data.metadata.flags);
fprintf('Time Points: %d\n', length(data.time));
fprintf('Time Range: %.6f to %.6f seconds\n', min(data.time), max(data.time));

% Variable analysis
for i = 1:length(data.variables)
    var_data = data.data(:,i);
    fprintf('\nVariable: %s (%s)\n', data.variables{i}, data.metadata.var_types{i});
    fprintf('  Range: %.3f to %.3f\n', min(var_data), max(var_data));
    fprintf('  Mean: %.3f\n', mean(var_data));
    fprintf('  Std Dev: %.3f\n', std(var_data));
end
```

### Error Handling Example

```matlab
try
    data = loadLTspiceTransient('simulation.raw');
    fprintf('Successfully loaded %d data points\n', length(data.time));
catch ME
    switch ME.identifier
        case 'MATLAB:load:couldNotReadFile'
            fprintf('Error: File not found or unreadable\n');
        otherwise
            fprintf('Error loading data: %s\n', ME.message);
    end
end
```

## Implementation Details

### File Format Support

- **Binary Format Only**: ASCII `.raw` files are not supported
- **IEEE Little-Endian**: Uses little-endian byte ordering
- **Double Precision**: Time data stored as 64-bit doubles
- **Single Precision**: Variable data stored as 32-bit floats

### Header Parsing

The function parses the following header sections:

1. **Plotname**: Simulation type identification
2. **Flags**: Simulation options and settings
3. **Variables**: Number and definitions of measured variables
4. **Points**: Total number of data points
5. **Offset**: Time offset for the simulation
6. **Variable Definitions**: Names and types of each variable

### Binary Data Reading

The binary data section contains:
- Interleaved time and variable data
- Time vector with specified stride pattern
- Variable data with calculated positioning
- Retry mechanism for robust data reading

## Limitations and Requirements

### Supported Simulations

- ✅ **Transient Analysis** - Primary supported simulation type
- ❌ **AC Analysis** - Not supported
- ❌ **DC Sweep** - Not supported
- ❌ **Noise Analysis** - Not supported

### File Format Limitations

- ✅ **Binary `.raw` files** - Fully supported
- ❌ **ASCII `.raw` files** - Not supported
- ⚠️ **Stepped Simulations** - Only first step loaded (with warning)

### System Requirements

- MATLAB R2014b or later, or GNU Octave 4.0+
- Sufficient memory to load entire dataset
- Read access to `.raw` file location

## Error Handling

The function provides comprehensive error checking:

### File Access Errors
```matlab
% File not found
error('File not found: %s', filename);

% Permission denied
error('Cannot open file: %s', msg);
```

### Format Validation Errors
```matlab
% ASCII format detection
error('ASCII format not supported. Only binary .raw files are supported.');

% Wrong simulation type
error('Only transient simulations are supported. Found: %s', metadata.plotname);
```

### Data Integrity Errors
```matlab
% Insufficient data points
error('Failed to read time data: expected %d points, got %d', num_points, count);

% Variable parsing issues
warning('Variable count mismatch: expected %d, found %d', metadata.num_vars, length(metadata.var_names));
```

## Performance Considerations

### Memory Usage
- **Time Vector**: 8 bytes × number of points
- **Variable Data**: 4 bytes × number of variables × number of points
- **Total Memory**: Approximately `(8 + 4×N_vars) × N_points` bytes

### Reading Strategy
- Uses binary file access for maximum speed
- Implements stride-based reading for efficient data extraction
- Includes retry mechanism for robust operation

### Large File Handling
```matlab
% For very large simulations, consider data decimation
decimation_factor = 10;
time_decimated = data.time(1:decimation_factor:end);
data_decimated = data.data(1:decimation_factor:end, :);
```

## Troubleshooting

### Common Issues

**Problem**: "File not found" error
```
Solution: Check file path and ensure .raw file exists
Verify: exist('filename.raw', 'file') == 2
```

**Problem**: "ASCII format not supported" error
```
Solution: Use LTspice binary output format
Setting: In LTspice, ensure binary format is selected
```

**Problem**: Memory errors with large files
```
Solution: Increase MATLAB/Octave memory or use data decimation
Check: Available system memory before loading
```

**Problem**: Unexpected variable count
```
Solution: Review LTspice simulation setup
Verify: Variables section in .raw file header
```

## Version History

### Current Version
- **Format**: Binary LTspice `.raw` files
- **Compatibility**: MATLAB/Octave cross-platform
- **Features**: Transient analysis with full metadata support

### Future Enhancements
- ASCII format support
- Additional simulation types (AC, DC sweep)

