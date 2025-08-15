function data = decrypt_robot_data(encrypted_data, key, iv, stored_hash)
% Process key to ensure proper length
key_bytes = process_encryption_key(key);

% --- to Java byte[] ---
key_bytes_java = typecast(uint8(key_bytes), 'int8');
iv_java = typecast(uint8(iv), 'int8');
encrypted_bytes_java = typecast(uint8(encrypted_data), 'int8');

% Initialize cipher for decryption with GCM parameters
cipher = javax.crypto.Cipher.getInstance('AES/GCM/NoPadding');
gcm_spec = javax.crypto.spec.GCMParameterSpec(128, iv_java);
secret_key = javax.crypto.spec.SecretKeySpec(key_bytes_java, 'AES');
cipher.init(javax.crypto.Cipher.DECRYPT_MODE, secret_key, gcm_spec);

% Perform decryption to get plaintext data
decrypted_bytes_java = cipher.doFinal(encrypted_bytes_java);
decrypted_bytes = typecast(decrypted_bytes_java, 'uint8');

% Compute hash of decrypted data for integrity verification
decrypted_hash_engine = java.security.MessageDigest.getInstance('SHA-256');
computed_hash = typecast(decrypted_hash_engine.digest(decrypted_bytes), 'uint8');

if ~isequal(computed_hash, stored_hash)
    error('SECURITY_ALERT: Data tampering detected!');
end

% Deserialize back to MATLAB structure
data = getStructFromBytes(decrypted_bytes);
end

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

function data = legacy_deserialize(bytes)
% Use MATLAB's native deserialization
temp_file = tempname();
fid = fopen(temp_file, 'wb');
fwrite(fid, bytes, 'uint8');
fclose(fid);
load(temp_file, 'data');
delete(temp_file);
end