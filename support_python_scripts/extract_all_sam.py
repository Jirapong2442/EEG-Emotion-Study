import tkinter as tk
from tkinter import filedialog
import os
import re

# THIS FILE SCANS TSV FILES AND OUTPUT TWO CSV FILES (SAM1, SAM2)

def select_file():
    """Open a file dialog to select a TSV file"""
    root = tk.Tk()
    root.withdraw()  # Hide the main window
    
    file_path = filedialog.askopenfilename(
        title="Select TSV file",
        filetypes=[("TSV files", "*.tsv"), ("All files", "*.*")]
    )
    
    root.destroy()
    return file_path

def generate_row_labels(filename, num_rows):
    """
    Generate row labels based on filename pattern
    For G2P files: g1,g2,...g13,p1,p2,...p14 (if 27 rows)
    For P2G files: p1,p2,...,p14,g1,g2,...g13 (if 27 rows)
    """
    # Extract the prefix from filename (before the last underscore)
    basename = os.path.splitext(os.path.basename(filename))[0]
    
    # Determine if it's G2P or P2G based on filename
    is_g2p = '_g' in basename.lower() or basename.lower().startswith('g')
    
    labels = []
    
    if is_g2p:
        # G2P pattern: g1-g13 first, then p1-p14
        g_count = min(13, num_rows)
        p_count = max(0, num_rows - 13)
        
        # Add g labels first
        for i in range(1, g_count + 1):
            labels.append(f"g{i}")
            
        # Add p labels
        for i in range(1, p_count + 1):
            labels.append(f"p{i}")
    else:
        # P2G pattern: p labels first, then g labels
        p_count = max(0, num_rows - 13)
        g_count = min(13, num_rows)
        
        # Add p labels first
        for i in range(1, p_count + 1):
            labels.append(f"p{i}")
            
        # Add g labels
        for i in range(1, g_count + 1):
            labels.append(f"g{i}")
    
    return labels

def generate_sam1_indices(filename):
    """
    Generate 4 indices for SAM1 based on filename pattern
    For G2P files: g1, g2, p1, p2
    For P2G files: p1, p2, g1, g2
    """
    # Extract the prefix from filename (before the last underscore)
    basename = os.path.splitext(os.path.basename(filename))[0]
    
    # Determine if it's G2P or P2G based on filename
    is_g2p = '_g' in basename.lower() or basename.lower().startswith('g')
    
    if is_g2p:
        # G2P pattern: g1, g2, p1, p2
        return ['g1', 'g2', 'p1', 'p2']
    else:
        # P2G pattern: p1, p2, g1, g2
        return ['p1', 'p2', 'g1', 'g2']

def extract_sam1_values(file_path, lines):
    """
    Extract SAM1 values and return CSV data with new 4-index format
    """
    # Define target columns for SAM1
    target_columns = {
        'Start': ['SAM1Start.Valence.Value', 'SAM1Start.Arousal.Value', 'SAM1Start.Sleepy.Value'],
        'Next': ['SAM1Next.Valence.Value', 'SAM1Next.Arousal.Value', 'SAM1Next.Sleepy.Value'],
        'End': ['SAM1End.Valence.Value', 'SAM1End.Arousal.Value', 'SAM1End.Sleepy.Value']
    }
    
    # Get the second row (index 1) which contains column names
    column_names = lines[1].split('\t')
    
    # Find the column indices for our target columns
    column_indices = {}
    for phase, cols in target_columns.items():
        for col in cols:
            for i, column_name in enumerate(column_names):
                if column_name.strip() == col:
                    column_indices[col] = i
                    break
    
    # Look for values in all data rows (starting from index 2)
    results = {}
    for phase, cols in target_columns.items():
        results[phase] = {}
        for col in cols:
            results[phase][col] = "N/A"
    
    for row_index in range(2, len(lines)):
        data_row = lines[row_index].split('\t')
        
        # Check each target column for a value in this row
        for phase, cols in target_columns.items():
            for col in cols:
                if col in column_indices:
                    col_index = column_indices[col]
                    if col_index < len(data_row):
                        value = data_row[col_index].strip()
                        # If we haven't found a value for this column yet and this cell is not empty
                        if results[phase][col] == "N/A" and value != "":
                            results[phase][col] = value
    
    # Generate the new 4-index format
    indices = generate_sam1_indices(file_path)
    
    # Create CSV data with new format
    csv_data = []
    
    # Header row
    csv_data.append(['', 'Valence', 'Arousal', 'Sleepy'])
    
    # Data rows - map Start->first index, Next->second & third indices, End->fourth index
    # Index 0: Start values
    row0 = [indices[0]]
    start_cols = target_columns['Start']
    for col in start_cols:
        row0.append(results['Start'][col])
    csv_data.append(row0)
    
    # Index 1: Next values
    row1 = [indices[1]]
    next_cols = target_columns['Next']
    for col in next_cols:
        row1.append(results['Next'][col])
    csv_data.append(row1)
    
    # Index 2: Next values (again)
    row2 = [indices[2]]
    for col in next_cols:
        row2.append(results['Next'][col])
    csv_data.append(row2)
    
    # Index 3: End values
    row3 = [indices[3]]
    end_cols = target_columns['End']
    for col in end_cols:
        row3.append(results['End'][col])
    csv_data.append(row3)
    
    return csv_data

def extract_sam2_values(file_path, lines):
    """
    Extract SAM2 values and return CSV data
    """
    # Define target columns for SAM2
    target_columns = [
        'SAM2.emotion.Value',
        'SAM2.Valence.Value', 
        'SAM2.Arousal.Value',
        'SAM2.interest.Value', 
        'SAM2.Immersion.Value', 
        'SAM2.visual.Value', 
        'SAM2.Auditory.Value'
    ]
    

    # Get the second row (index 1) which contains column names
    column_names = lines[1].split('\t')
    
    # Find the column indices for our target columns
    column_indices = {}
    for col in target_columns:
        for i, column_name in enumerate(column_names):
            if column_name.strip() == col:
                column_indices[col] = i
                break
    
    # Collect all rows that have at least one non-empty value in the target columns
    valid_rows = []
    
    for row_index in range(2, len(lines)):  # Start from row 2 (first data row)
        data_row = lines[row_index].split('\t')
        
        # Check if this row has any non-empty values in our target columns
        has_data = False
        row_values = {}
        
        for col in target_columns:
            col_index = column_indices.get(col)
            if col_index is not None and col_index < len(data_row):
                value = data_row[col_index].strip()
                row_values[col] = value if value != "" else "N/A"
                if value != "":
                    has_data = True
            else:
                row_values[col] = "N/A"
        
        if has_data:
            valid_rows.append({
                'row_index': row_index,
                'values': row_values
            })
    
    if not valid_rows:
        return []
    
    # Generate row labels
    row_labels = generate_row_labels(file_path, len(valid_rows))
    
    # Create CSV data
    csv_data = []
    
    # Header row
    csv_data.append(['', 'Dominating', 'Valence', 'Arousal', 'Interest', 'Immersion', 'Visual', 'Auditory'])
    
    # Data rows
    for i, row_data in enumerate(valid_rows):
        if i < len(row_labels):
            label = row_labels[i]
        else:
            label = f"Row{i+1}"
            
        row = [label]
        # Map values in the correct order
        value_mapping = [
            'SAM2.emotion.Value',
            'SAM2.Valence.Value', 
            'SAM2.Arousal.Value',
            'SAM2.interest.Value', 
            'SAM2.Immersion.Value', 
            'SAM2.visual.Value', 
            'SAM2.Auditory.Value'
        ]
        
        for col in value_mapping:
            if col in row_data['values']:
                row.append(row_data['values'][col])
            else:
                row.append("N/A")
                
        csv_data.append(row)
    
    return csv_data

def extract_all_sam_values():
    """
    Read a selected TSV file and extract both SAM1 and SAM2 values,
    then output to separate CSV files.
    """
    
    # Select file
    file_path = select_file()
    if not file_path:
        print("No file selected.")
        return
    
    print(f"Selected file: {file_path}")
    
    # Read the file as UTF-16 little-endian
    try:
        with open(file_path, 'r', encoding='utf-16-le') as f:
            lines = f.read().splitlines()
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    # Check if we have enough lines
    if len(lines) < 3:  # Need at least 3 lines (header, column names, and data)
        print("Insufficient data")
        return
    
    # Extract SAM1 values
    print("Extracting SAM1 values...")
    sam1_csv_data = extract_sam1_values(file_path, lines)
    
    # Generate SAM1 output file path
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    output_dir = os.path.dirname(file_path)
    sam1_output_file = os.path.join(output_dir, f"{base_name}_SAM1.csv")
    
    # Write SAM1 CSV file
    try:
        with open(sam1_output_file, 'w', newline='', encoding='utf-8') as f:
            for row in sam1_csv_data:
                f.write(','.join(row) + '\n')
        print(f"SAM1 CSV file saved to: {sam1_output_file}")
    except Exception as e:
        print(f"Error writing SAM1 CSV file: {e}")
    
    # Print SAM1 results to console
    print("\nSAM1 Extracted values:")
    for row in sam1_csv_data:
        print(','.join(row))
    
    # Extract SAM2 values
    print("\nExtracting SAM2 values...")
    sam2_csv_data = extract_sam2_values(file_path, lines)
    
    if not sam2_csv_data:
        print("No SAM2 data found")
        return
    
    # Generate SAM2 output file path
    sam2_output_file = os.path.join(output_dir, f"{base_name}_SAM2.csv")
    
    # Write SAM2 CSV file
    try:
        with open(sam2_output_file, 'w', newline='', encoding='utf-8') as f:
            for row in sam2_csv_data:
                f.write(','.join(row) + '\n')
        print(f"SAM2 CSV file saved to: {sam2_output_file}")
    except Exception as e:
        print(f"Error writing SAM2 CSV file: {e}")
    
    # Print SAM2 results to console (first 10 rows + header)
    print("\nSAM2 Extracted values (first 10 rows):")
    for i, row in enumerate(sam2_csv_data):
        if i < 11:  # Header + first 10 data rows
            print(','.join(row))
        else:
            print("... (more rows in output file)")
            break
    
    print(f"\nCompleted! Both SAM1 and SAM2 CSV files have been generated.")

if __name__ == "__main__":
    extract_all_sam_values()