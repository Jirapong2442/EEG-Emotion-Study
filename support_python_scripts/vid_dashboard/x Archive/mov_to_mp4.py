#!/usr/bin/env python3

import os
import subprocess
import sys

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
    HAS_TK = True
except Exception:
    HAS_TK = False

def pick_mov_file() -> str:
    if HAS_TK:
        root = tk.Tk()
        root.withdraw()
        path = filedialog.askopenfilename(
            title='Select a .mov file',
            filetypes=[('QuickTime Movie', '*.mov'), ('All files', '*.*')]
        )
        root.update()
        return path or ''
    else:
        print('GUI file dialog unavailable. Enter path to .mov:')
        return input('Path: ').strip()

def ensure_ffmpeg_available() -> bool:
    try:
        subprocess.run(['ffmpeg', '-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        return True
    except FileNotFoundError:
        return False

def propose_output_path(input_path: str) -> str:
    directory, filename = os.path.split(input_path)
    name, _ext = os.path.splitext(filename)
    out_path = os.path.join(directory, f'{name}.mp4')
    if not os.path.exists(out_path):
        return out_path
    # Avoid overwrite
    i = 1
    while True:
        candidate = os.path.join(directory, f'{name}_converted_{i}.mp4')
        if not os.path.exists(candidate):
            return candidate
        i += 1

def convert_mov_to_mp4(input_path: str, output_path: str) -> bool:
    cmd = [
        'ffmpeg', '-y',
        '-i', input_path,
        # Video
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '18',
        '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart',
        # Audio
        '-c:a', 'aac',
        '-b:a', '192k',
        output_path,
    ]
    try:
        print('Running FFmpeg...')
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            print('✅ Conversion complete:')
            print(output_path)
            return True
        else:
            print('❌ FFmpeg error:')
            print(result.stderr)
            return False
    except Exception as e:
        print(f'❌ Failed to run ffmpeg: {e}')
        return False

def main():
    if not ensure_ffmpeg_available():
        print('❌ FFmpeg not found. Please install FFmpeg and try again.')
        sys.exit(1)

    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    else:
        input_path = pick_mov_file()

    if not input_path:
        print('No file selected.')
        sys.exit(1)

    if not os.path.isfile(input_path):
        print(f'File not found: {input_path}')
        sys.exit(1)

    if os.path.splitext(input_path)[1].lower() != '.mov':
        print('Warning: selected file is not .mov, proceeding anyway...')

    output_path = propose_output_path(input_path)
    print(f'Input:  {input_path}')
    print(f'Output: {output_path}')

    ok = convert_mov_to_mp4(input_path, output_path)

    if HAS_TK:
        try:
            if ok:
                messagebox.showinfo('mov_to_mp4', f'Conversion complete:\n{output_path}')
            else:
                messagebox.showerror('mov_to_mp4', 'Conversion failed. Check console for details.')
        except Exception:
            pass

    sys.exit(0 if ok else 2)

if __name__ == '__main__':
    main()
