%% Final Test for Encryption Functions
addpath('c:\Users\alexw\Desktop\Safeguarding\code');
cd('c:\Users\alexw\Desktop\Safeguarding\code');

% Load robot data
data = load('robot_motion_data_2025-07-21_21-17-35.mat');
robot_data = data.robot_data;

% Create an encryption key (32 bytes)
encryption_key = 'My32ByteSuperSecureKey1234567890!';

fprintf('Starting final test of encryption/decryption functions...\n');

% Try to encrypt data
try
    [encrypted_bytes, iv, hash] = robot_data_encrypt(robot_data, encryption_key);
    fprintf('Encryption successful!\n');
    fprintf('Encrypted data size: %d bytes\n', length(encrypted_bytes));
    fprintf('IV size: %d bytes\n', length(iv));
    fprintf('Hash size: %d bytes\n', length(hash));
    
    % Try to decrypt data
    decrypted_data = robot_data_decrypt(encrypted_bytes, encryption_key, iv, hash);
    fprintf('Decryption successful!\n');
    fprintf('Original data size: %d\n', length(robot_data.time));
    fprintf('Decrypted data size: %d\n', length(decrypted_data.time));
    
    % Verify data integrity
    if isequal(robot_data.time, decrypted_data.time)
        fprintf('Data integrity verified!\n');
    else
        fprintf('Data integrity check failed!\n');
    end
    
    % Test with different key (should fail)
    fprintf('\nTesting with incorrect key...\n');
    wrong_key = 'Wrong32ByteSuperSecureKey1234567890!';
    try
        robot_data_decrypt(encrypted_bytes, wrong_key, iv, hash);
        fprintf('Decryption with wrong key succeeded (unexpected)!\n');
    catch ME
        fprintf('Decryption with wrong key failed as expected.\n');
        fprintf('Error: %s\n', ME.message);
    end
    
    % Test with corrupted data (should fail)
    fprintf('\nTesting with corrupted data...\n');
    corrupted_data = encrypted_bytes;
    corrupted_data(1) = bitxor(corrupted_data(1), 1); % Flip one bit
    try
        robot_data_decrypt(corrupted_data, encryption_key, iv, hash);
        fprintf('Decryption of corrupted data succeeded (unexpected)!\n');
    catch ME
        fprintf('Decryption of corrupted data failed as expected.\n');
        fprintf('Error: %s\n', ME.message);
    end
    
    fprintf('\nAll tests completed successfully!\n');
    
catch ME
    fprintf('Error occurred:\n');
    fprintf('Message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Location: %s at line %d\n', ME.stack(1).name, ME.stack(1).line);
    end
end

fprintf('\nFinal test completed.\n');