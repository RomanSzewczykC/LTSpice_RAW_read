function ltsData = loadLTspiceTransient(filename)
    % LOADLTSPICETRANSIENT Load transient simulation data from LTspice raw files
    %
    % Usage: ltsData = loadLTspiceTransient('simulation.raw')
    %
    % Input:
    %   filename - Path to LTspice .raw file
    %
    % Output:
    %   ltsData - Structure containing:
    %     .time       - Time vector
    %     .variables  - Cell array of variable names
    %     .data       - Matrix where each column corresponds to a variable
    %     .metadata   - Structure with simulation info

    % Input validation
    if exist(filename, 'file') != 2
        error('File not found: %s', filename);
    end

    % Open file in binary mode
    [fid, msg] = fopen(filename, 'rb');
    if fid == -1
        error('Cannot open file: %s', msg);
    end

    try
        % Check if file is binary format
        header_check = fread(fid, 10, 'char', 0, 'ieee-le');
        if header_check(2) ~= 0
            error('ASCII format not supported. Only binary .raw files are supported.');
        end

        % Reset to beginning and read header
        fseek(fid, 0, 'bof');
        [header_str, header_len] = readHeader(fid);

        % Parse header information
        metadata = parseHeader(header_str);

        % Validate this is a transient simulation
        if length(strfind(lower(metadata.plotname), 'transient')) < 1
            error('Only transient simulations are supported. Found: %s', metadata.plotname);
        end

        % Check for stepped simulations
        if length(strfind(lower(metadata.flags), 'stepped')) > 0
            warning('Stepped simulation detected. Only first step will be loaded.');
        end

        % Calculate binary data start position (exactly like reference)
        bin_start = header_len * 2;

        % Read binary data
        [time_data, var_data] = readBinaryData(fid, metadata, bin_start);

        % Close file
        fclose(fid);

        % Prepare output structure
        ltsData.time = time_data;
        ltsData.variables = metadata.var_names;
        ltsData.data = var_data;
        ltsData.metadata = metadata;

    catch ME
        if fid ~= -1
            fclose(fid);
        end
        rethrow(ME);
    end
end

function [header_str, header_len] = readHeader(fid)
    % Read header until 'Binary:' marker - following reference code exactly
    header_str = '';

    while true
        chunk = fread(fid, 100, 'uint16=>char', 0, 'ieee-le')';
        header_str = [header_str chunk];

        % Look for 'inary' marker (like reference code)
        bin_idx = strfind(header_str, 'inary');
        if ~isempty(bin_idx)
            % Follow reference: len_header = idx_str_Bin + 6
            header_len = bin_idx + 6;
            header_str = header_str(1:header_len);
            break;
        end

        % Safety check to prevent infinite loop
        if length(header_str) > 10000
            error('Header too long or Binary marker not found');
        end
    end
end

function metadata = parseHeader(header_str)
    % Parse header string to extract metadata
    metadata = struct();

    % Extract plot name
    tokens = regexp(header_str, 'Plotname:\s*(.+)', 'tokens');
    if ~isempty(tokens)
        metadata.plotname = strtrim(tokens{1}{1});
    else
        metadata.plotname = 'Unknown';
    end

    % Extract flags
    tokens = regexp(header_str, 'Flags:\s*(.+)', 'tokens');
    if ~isempty(tokens)
        metadata.flags = strtrim(tokens{1}{1});
    else
        metadata.flags = '';
    end

    % Extract number of variables
    tokens = regexp(header_str, 'No\.\s*Variables:\s*(\d+)', 'tokens');
    if ~isempty(tokens)
        metadata.num_vars = str2double(tokens{1}{1}) - 1; % Subtract 1 for time
    else
        error('Could not parse number of variables');
    end

    % Extract number of points
    tokens = regexp(header_str, 'No\.\s*Points:\s*(\d+)', 'tokens');
    if ~isempty(tokens)
        metadata.num_points = str2double(tokens{1}{1});
    else
        error('Could not parse number of points');
    end

    % Extract offset
    tokens = regexp(header_str, 'Offset:\s*([\d\.\-e\+]+)', 'tokens');
    if ~isempty(tokens)
        metadata.offset = str2double(tokens{1}{1});
    else
        metadata.offset = 0;
    end

    % Extract variable definitions
    var_section = regexp(header_str, 'Variables:\s*\n(.+?)Binary:', 'tokens', 'dotall');
    if isempty(var_section)
        error('Could not find Variables section');
    end

    % Split variable section into lines (Octave-compatible)
    var_text = var_section{1}{1};
    var_lines = {};
    start_idx = 1;
    for i = 1:length(var_text)
        if var_text(i) == sprintf('\n')
            if i > start_idx
                var_lines{end+1} = var_text(start_idx:i-1);
            end
            start_idx = i + 1;
        end
    end
    if start_idx <= length(var_text)
        var_lines{end+1} = var_text(start_idx:end);
    end

    metadata.var_names = {};
    metadata.var_types = {};

    for i = 1:length(var_lines)
        line = strtrim(var_lines{i});
        if isempty(line)
            continue;
        end

        % Parse variable line: number name type
        tokens = regexp(line, '^\s*(\d+)\s+(\S+)\s+(\S+)', 'tokens');
        if ~isempty(tokens)
            var_num = str2double(tokens{1}{1});
            var_name = tokens{1}{2};
            var_type = tokens{1}{3};

            % Skip time variable (usually index 0)
            if var_num > 0
                metadata.var_names{end+1} = var_name;
                metadata.var_types{end+1} = var_type;
            end
        end
    end

    % Validate variable count
    if length(metadata.var_names) ~= metadata.num_vars
        warning('Variable count mismatch: expected %d, found %d', ...
                metadata.num_vars, length(metadata.var_names));
    end
end

function [time_data, var_data] = readBinaryData(fid, metadata, bin_start)
    % Read binary data section - exactly following reference code

    num_vars = metadata.num_vars;
    num_points = metadata.num_points;

    % Seek to binary data start
    fseek(fid, bin_start, 'bof');

    % Read time data exactly like reference: fread(fid, noPts, 'double', 4*noVars, 'ieee-le')
    [time_data, count] = fread(fid, num_points, 'double', 4*num_vars, 'ieee-le');
    time_data = abs(time_data) + metadata.offset;

    if count ~= num_points
        error('Failed to read time data: expected %d points, got %d', num_points, count);
    end

    % Initialize variable data matrix
    var_data = zeros(num_points, num_vars);

    % Read each variable data exactly like reference
    for l = 1:num_vars
        % Position calculation: bin_start + 8 + 4*(l-1)
        % (k=1 for first step, so the (k-1) term is 0)
        rpos = bin_start + 8 + 4*(l-1);
        fseek(fid, rpos, 'bof');

        % Read with retry mechanism like reference
        count = 0;
        max_attempts = 5;
        for m = 1:max_attempts
            [var_data(:, l), cnt] = fread(fid, num_points, 'float', 4*(num_vars-1)+8, 'ieee-le');
            count = count + cnt;
            if count == num_points
                break;
            elseif count ~= num_points && m == max_attempts
                error('Not enough points read for variable %d: expected %d, got %d', l, num_points, count);
            end
        end
    end
end
