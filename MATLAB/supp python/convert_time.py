def convert_time_to_samples():
    """
    Repeatedly asks the user to input time and converts it to samples at 250 Hz sampling rate.
    Continues until 'done' is entered, then outputs cumulative converted values.
    """
    print("Time to Samples Converter (250 Hz Sampling Rate)")
    print("Enter 'done' to finish and display cumulative converted values.")
    
    # List to store converted values
    converted_values = []
    
    while True:
        user_input = input("\nEnter time in seconds (e.g., 1.2): ")
        
        # Check if user wants to finish
        if user_input.lower() == 'done':
            break
        
        try:
            # Convert input to float
            time_seconds = float(user_input)
            
            # Convert to samplees (time * sampling_rate)
            samples = time_seconds * 250
            
            # Store the converted value
            converted_values.append(samples)
            
            # Display current conversion
            print(f"{time_seconds} seconds = {samples} samples at 250 Hz")
            
        except ValueError:
            print("Invalid input. Please enter a numeric value or 'done'.")
    
    # Calculate and output cumulative values
    cumulative_values = []
    cumulative_sum = 0
    for value in converted_values:
        cumulative_sum += value
        cumulative_values.append(cumulative_sum)
    
    # Output cumulative values
    print("\nCumulative converted values:")
    print(", ".join(str(int(value)) for value in cumulative_values))

if __name__ == "__main__":
    convert_time_to_samples()