@echo off
REM Simple environment setup script for Windows Command Prompt

echo Creating new conda environment...
conda create -n alan-eee-general python=3.9 -y

echo Activating environment...
conda activate alan-eee-general

echo Installing required packages...
conda install FFmpeg -y
pip install opencv-python

echo Done.
pause