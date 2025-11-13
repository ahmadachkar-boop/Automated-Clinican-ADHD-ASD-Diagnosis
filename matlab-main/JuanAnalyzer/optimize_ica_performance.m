function optimize_ica_performance()
% Optimize ICA performance for MacBook
% Run this once to configure MATLAB for faster runica

    fprintf('\n=== ICA Performance Optimization ===\n\n');

    % 1. Check current threading
    currentThreads = maxNumCompThreads();
    fprintf('Current BLAS threads: %d\n', currentThreads);

    % 2. Get system info
    if ismac
        [~, cpuInfo] = system('sysctl -n hw.ncpu');
        numCores = str2double(cpuInfo);
        fprintf('System CPU cores: %d\n', numCores);

        [~, memInfo] = system('sysctl -n hw.memsize');
        totalMemGB = str2double(memInfo) / 1024^3;
        fprintf('System RAM: %.1f GB\n', totalMemGB);
    end

    % 3. Enable optimal threading
    if currentThreads < 4
        fprintf('\n⚠️  Threading is not optimized!\n');
        fprintf('Setting to automatic threading...\n');
        maxNumCompThreads('automatic');
        fprintf('✓ BLAS threads now: %d\n', maxNumCompThreads());
    else
        fprintf('✓ Threading is already optimized\n');
    end

    % 4. Check for Parallel Computing Toolbox
    hasParallel = license('test', 'Distrib_Computing_Toolbox');
    if hasParallel
        fprintf('\nParallel Computing Toolbox: Yes\n');
    else
        fprintf('\nParallel Computing Toolbox: No\n');
    end

    if hasParallel
        try
            poolobj = gcp('nocreate');
            if isempty(poolobj)
                fprintf('  No parallel pool active\n');
                fprintf('  To enable: parpool(4)  %% or desired number of workers\n');
            else
                fprintf('  ✓ Parallel pool active with %d workers\n', poolobj.NumWorkers);
            end
        catch
            fprintf('  Parallel pool not started\n');
        end
    end

    % 5. ICA Speed Recommendations
    fprintf('\n--- ICA Speed Recommendations ---\n\n');
    fprintf('For 128-channel EEG on MacBook:\n\n');

    fprintf('1. FASTEST (~5x speedup):\n');
    fprintf('   EEG = pop_runica(EEG, ''icatype'', ''runica'', ''pca'', 30);\n');
    fprintf('   • PCA reduces to 30 components\n');
    fprintf('   • Non-extended ICA (faster)\n');
    fprintf('   • Good for artifact removal\n\n');

    fprintf('2. BALANCED (~3x speedup):\n');
    fprintf('   EEG = pop_runica(EEG, ''icatype'', ''runica'', ''extended'', 1, ''pca'', 40);\n');
    fprintf('   • PCA reduces to 40 components\n');
    fprintf('   • Extended ICA (handles sub/super-gaussian)\n');
    fprintf('   • Best quality/speed tradeoff\n\n');

    fprintf('3. HIGH QUALITY (~2x speedup):\n');
    fprintf('   EEG = pop_runica(EEG, ''icatype'', ''runica'', ''extended'', 1, ''pca'', 60);\n');
    fprintf('   • PCA reduces to 60 components\n');
    fprintf('   • Extended ICA\n');
    fprintf('   • Nearly full quality\n\n');

    fprintf('4. CURRENT (SLOWEST):\n');
    fprintf('   EEG = pop_runica(EEG, ''icatype'', ''runica'', ''extended'', 1);\n');
    fprintf('   • Full 128 components\n');
    fprintf('   • Extended ICA\n');
    fprintf('   • ~10-30 minutes on MacBook\n\n');

    % 6. Memory considerations
    fprintf('--- Memory Usage ---\n\n');
    fprintf('128 channels, full ICA: ~2-4 GB RAM\n');
    fprintf('128 channels, PCA to 40: ~0.5-1 GB RAM\n');
    fprintf('PCA reduction also speeds up ICLabel!\n\n');

    % 7. Add to startup
    fprintf('--- Make Permanent ---\n\n');
    fprintf('To apply threading on every MATLAB startup:\n');
    fprintf('1. Edit ~/Documents/MATLAB/startup.m\n');
    fprintf('2. Add: maxNumCompThreads(''automatic'');\n\n');

    % 8. Benchmark option
    fprintf('--- Benchmark Test ---\n\n');
    fprintf('Want to test ICA speed with your data?\n');
    fprintf('Run: benchmark_ica_speed(EEG)\n\n');

    fprintf('=== Optimization Complete ===\n\n');
end
