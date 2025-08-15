%% ==================== ROBOT DATA SECURITY MODULE ====================
% Fully compatible encryption/decryption system
% Uses standard MATLAB functions for serialization
%% ==================== KEY PROCESSING FUNCTIONS ====================
function key_bytes = process_encryption_key(key)
% PROCESS_ENCRYPTION_KEY - Ensures valid 256-bit key length
if ischar(key) || isstring(key)
    key_bytes = unicode2native(char(key), 'UTF-8');
elseif isnumeric(key)
    key_bytes = typecast(key, 'uint8');
else
    error('Invalid key type: must be string or numeric array');
end

% Derive consistent 32-byte key using SHA-256
if length(key_bytes) ~= 32
    hash_engine = java.security.MessageDigest.getInstance('SHA-256');
    hash_engine.update(typecast(key_bytes, 'int8'));
    key_bytes = typecast(hash_engine.digest(), 'uint8');
end
end
%% ==================== MEMORY-BASED SERIALIZATION ====================
% Completely eliminate file operations and use pure in-memory serialization
function bytes = getByteArray(data)
% Use MATLAB's built-in serialize if available, otherwise use legacy method
if exist('serialize', 'builtin') == 5
    % Modern in-memory serialization (R2019a+)
    bytes = uint8(serialize(data));
else
    % Legacy file-based serialization for older MATLAB versions
    bytes = legacy_serialize(data);
end
end
function data = getStructFromBytes(bytes)
% Use MATLAB's built-in deserialize if available, otherwise use legacy method
if exist('deserialize', 'builtin') == 5
    % Modern in-memory deserialization (R2019a+)
    data = deserialize(uint8(bytes));
else
    % Legacy file-based deserialization for older MATLAB versions
    data = legacy_deserialize(bytes);
end
end
%% ==================== LEGACY COMPATIBILITY FUNCTIONS ====================
% For older versions of MATLAB that do not support built-in serialization functions
function bytes = legacy_serialize(data)
% Create unique temporary filename in system temp directory with enhanced error handling
temp_file = fullfile(tempdir(), sprintf('legacy_temp_%d.mat', randi([10000, 99999])));

% Save data with extended error handling
try
    save(temp_file, 'data', '-v7');
    pause(1.0); % Longer delay to ensure file write completion
catch e
    error('Failed to save temporary file: %s\nError: %s', temp_file, e.message);
end

% Verify file exists and is accessible
file_status = exist(temp_file, 'file');
if file_status == 0
    error('Temporary file not found after save: %s', temp_file);
elseif file_status ~= 2
    error('Temporary file access issue (status %d): %s', file_status, temp_file);
end

% Retry opening file with increased delays between attempts
max_attempts = 5;
attempt = 1;
fid = -1;
err_msg = '';
while fid == -1 && attempt <= max_attempts
    [fid, err_msg] = fopen(temp_file, 'rb');
    if fid == -1
        pause(0.5 * attempt); % Increasing delay with each attempt
        attempt = attempt + 1;
    end
end
if fid == -1
    error('Failed to open temporary file for reading: %s\nError: %s', temp_file, err_msg);
end
bytes = fread(fid, inf, 'uint8');
fclose(fid);
delete(temp_file);
end

function java_obj = matlabToJava(matlab_data)
import java.util.HashMap;
import java.util.ArrayList;

if isstruct(matlab_data)
    java_obj = HashMap;
    fields = fieldnames(matlab_data);
    for i = 1:numel(fields)
        java_obj.put(java.lang.String(char(fields(i))), matlabToJava(matlab_data.(fields(i))));
    end
elseif iscell(matlab_data)
    java_obj = ArrayList;
    for i = 1:numel(matlab_data)
        java_obj.add(matlabToJava(matlab_data{i}));
    end
elseif isnumeric(matlab_data)
    % Convert MATLAB array to Java primitive array
    if isscalar(matlab_data)
        java_obj = matlab_data;
    else
        % Convert to Java array based on data type
        if isdouble(matlab_data)
            java_obj = javaArray('double', numel(matlab_data));
            for i = 1:numel(matlab_data)
                java_obj(i) = matlab_data(i);
            end
        elseif isfloat(matlab_data)
            java_obj = javaArray('float', numel(matlab_data));
            for i = 1:numel(matlab_data)
                java_obj(i) = matlab_data(i);
            end
        elseif isinteger(matlab_data)
            java_obj = javaArray('int', numel(matlab_data));
            for i = 1:numel(matlab_data)
                java_obj(i) = matlab_data(i);
            end
        else
            java_obj = matlab_data;
        end
    end
elseif ischar(matlab_data)
    java_obj = java.lang.String(matlab_data);
else
    % Default conversion
    java_obj = matlab_data;
end
end

function data = legacy_deserialize(bytes)
% Use MATLAB's native deserialization
temp_file = tempname();
fid = fopen(temp_file, 'wb');
fwrite(fid, bytes, 'uint8');
fclose(fid);
load(temp_file, 'data');
delete(temp_file);
end
%% ==================== USAGE EXAMPLE ====================
clc,clear
addpath(fileparts(which('robot_security_module')));
% Load robot data
data = load('robot_motion_data_2025-07-21_21-17-35.mat');
robot_data = data.robot_data;

%  Create an encryption key (32 bytes）
encryption_key = 'My32ByteSuperSecureKey1234567890!';

% Encrypt data
[encrypted_bytes, iv, hash] = encrypt_robot_data(robot_data, encryption_key);

% Save the encrypted data as raw bytes (without MATLAB format)
fid = fopen('encrypted_data.bin', 'wb');
encrypted_bytes = encrypted_bytes(:); % Make sure it is a column vector
fwrite(fid, length(encrypted_bytes), 'uint32', 'ieee-be'); % input length (big-endian)
fwrite(fid, encrypted_bytes, 'uint8');
fwrite(fid, iv, 'uint8');
fwrite(fid, hash, 'uint8');
fclose(fid);

% Load the raw byte data
fid = fopen('encrypted_data.bin', 'rb');
len = fread(fid, 1, 'uint32=>uint32', 'ieee-be'); % output length (big-endian)
encrypted_bytes = fread(fid, len, 'uint8');
iv = fread(fid, 12, 'uint8');
hash = fread(fid, 32, 'uint8');
fclose(fid);

% Decrypt the data
decrypted_data = decrypt_robot_data(encrypted_bytes, encryption_key, iv, hash);

% ========= FAULT RECOVERY MECHANISM =========
% Function to simulate data corruption at a random position
function [corrupted_data, corruption_index] = simulate_corruption(data)
    corrupted_data = data;
    % Randomly select a position to corrupt (not the first timestamp)
    corruption_index = randi([2, length(data.time)]);
    % Corrupt the timestamp at the selected position
    corrupted_data.time(corruption_index) = data.time(corruption_index) + 1e6;
    fprintf('Data corrupted at timestamp index: %d\n', corruption_index);
end