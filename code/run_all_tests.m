%% Run All Tests Script
% This script runs all tests to demonstrate the security module's capabilities.

cd('c:\Users\alexw\Desktop\Safeguarding\code');
addpath('c:\Users\alexw\Desktop\Safeguarding\code');

fprintf('==========================================\n');
fprintf('Running All Security Module Tests\n');
fprintf('==========================================\n\n');

%% Test 1: Basic Encryption/Decryption
fprintf('1. Running Basic Encryption/Decryption Test...\n');
robot_security_test;
fprintf('\n');

%% Test 2: Fault Recovery
fprintf('2. Running Fault Recovery Test...\n');
fault_recovery_test;
fprintf('\n');

%% Test 3: Performance and Efficiency
fprintf('3. Running Performance and Efficiency Test...\n');
performance_test;
fprintf('\n');

fprintf('==========================================\n');
fprintf('All Tests Completed\n');
fprintf('==========================================\n');