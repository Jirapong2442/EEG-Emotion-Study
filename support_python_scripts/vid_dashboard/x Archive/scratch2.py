
x = "11:24"
y = "11:22"

def time_to_seconds(time_str):
    """Convert time string (MM:SS) to total seconds"""
    minutes, seconds = map(int, time_str.split(':'))
    return minutes * 60 + seconds

def seconds_to_time(total_seconds):
    """Convert total seconds to time string (MM:SS)"""
    minutes = total_seconds // 60
    seconds = total_seconds % 60
    return f"{minutes}:{seconds:02d}"

# Calculate difference
x_seconds = time_to_seconds(x)
y_seconds = time_to_seconds(y)
difference_seconds = abs(x_seconds - y_seconds)
difference_time = seconds_to_time(difference_seconds)

print(f"x = {x}")
print(f"y = {y}")
print(f"Time difference = {difference_time}")