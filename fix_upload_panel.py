#!/usr/bin/env python3
"""Fix the createUploadPanel function by replacing it with JuanAnalyzer's version"""

# Read both files
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'r') as f:
    eeg_lines = f.readlines()

with open('matlab-main/JuanAnalyzerManual/JuanAnalyzer.m', 'r') as f:
    juan_lines = f.readlines()

# Find the JuanAnalyzer createUploadPanel function (lines 106-188)
juan_upload = juan_lines[105:188]  # Line 106-188 (0-indexed)

# Customize for EEGQualityAnalyzer
juan_upload_str = ''.join(juan_upload)
juan_upload_str = juan_upload_str.replace('Juan Analyzer', 'EEG Quality Analyzer')
juan_upload_str = juan_upload_str.replace(
    'Manual Event Selection | N400, N250, P600 Components',
    'Automated Quality Assessment with Manual Event Selection')

# Split back into lines
juan_upload_lines = juan_upload_str.split('\n')
juan_upload_lines = [line + '\n' for line in juan_upload_lines if line]  # Add newlines back

# Replace in EEGQualityAnalyzer (lines 158-352, which is index 157-351)
new_lines = eeg_lines[:157] + juan_upload_lines + ['\n'] + eeg_lines[352:]

# Write back
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'w') as f:
    f.writelines(new_lines)

print("✅ createUploadPanel function replaced successfully!")
print(f"   Removed {352-157} old lines")
print(f"   Added {len(juan_upload_lines)} new lines")
