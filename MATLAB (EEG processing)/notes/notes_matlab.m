

%% {} and []

| Feature              | Square Brackets ([])                   | Curly Braces ({})                 |
|----------------------|----------------------------------------|-----------------------------------|
| Purpose              | Create/concatenate arrays and matrices | Create and manipulate cell arrays |
| Data Type            | Numeric or logical arrays              | Heterogeneous data (cell arrays)  |
| Access               | Not applicable                         | Access cell contents              |
| Empty Representation | Represents an empty matrix             | Not applicable                    |

e.g. DataFolder = [dir '/' ExperimentMode '/' ExperimentNo '/' ParticipantNo];

%% '' and ""

'' are for character vectors
"" are for strings

%% disp(), fprintf()

disp(['Line 1', newline, 'Line 2']);
fprintf('Line 1\nLine 2\n');

These two will both break lines


%% Common pre-defined variables

pi: %Represents the mathematical constant π (pi), approximately equal to 3.1416.
i and j: %These are commonly used to represent the imaginary unit (the square root of -1). They can also be used as regular variables, but it is best to avoid this to prevent confusion.
inf: %Represents infinity. This value is returned in cases such as division by zero.
NaN: %Stands for "Not a Number." It is used to represent undefined or unrepresentable numerical results, such as 0/0.
clock: %Returns the current date and time as a vector containing [year, month, day, hour, minute, second].
date: %Returns a string representing today’s date.
eps: %Represents the smallest increment between distinct floating-point numbers, also known as machine epsilon.
ans: %A default variable that stores the result of calculations that are not assigned to any other variable. For example, if you execute an expression without assigning it, MATLAB automatically assigns the result to ans.
whos: %While not a variable per se, this command lists all variables currently in the workspace along with their sizes and types.
global: %Used to declare variables as global, allowing them to be accessed from different functions or workspaces.

%% just !

!::
use this above for green comments lol (temporary, it affects shell)

%% cell and matrix and others
% TODO need link

% | Data Type                                        | Description                                             |
% |--------------------------------------------------|---------------------------------------------------------|
% | Double                                           | Default numeric data type for storing real numbers      |
% | Single                                           | Single-precision floating-point numbers                 |
% | Integer (int8, int16, int32, int64)              | Signed integers of various sizes                        |
% | Unsigned Integer (uint8, uint16, uint32, uint64) | Unsigned integers of various sizes                      |
% | Logical                                          | Boolean values (true/false)                             |
% | Character Array                                  | Sequence of characters                                  |
% | String Array                                     | Array of text data                                      |
% | Cell Array                                       | Container for storing data of different types and sizes |
% | Structure Array                                  | Groups related data using named fields                  |
% | Table                                            | Tabular data with named variables of different types    |
% | Timetable                                        | Time-stamped tabular data                               |
% | Categorical Array                                | Data with discrete categories                           |
% | Function Handle                                  | Reference to a function                                 |
% | Object                                           | Instance of a MATLAB class                              |
% | Sparse Array                                     | Efficient storage for arrays with mostly zero elements  |
% | gpuArray                                         | Array for GPU computations                              |
% | datetime                                         | Date and time values                                    |
% | duration                                         | Time durations                                          |
% | calendarDuration                                 | Calendar durations                                      |



%
%% "& && | ||"
% | Operator | Type              | Input             | Usage                                               | Behavior                                                      | Example                                               |
% |----------|-------------------|-------------------|-----------------------------------------------------|---------------------------------------------------------------|-------------------------------------------------------|
% | &&       | Short-circuit AND | Scalars only      | Used in conditional statements likeif               | Stops evaluating once the firstfalsecondition is encountered. | if x > 0 && y < 10checks if both conditions are true. |
% | &        | Element-wise AND  | Scalars or arrays | Used for element-wise logical operations on arrays. | Evaluates all elements of the arrays.                         | [1 0 1] & [1 1 0]returns[1 0 0].                      |
% | |        |                   | `                 | Short-circuit OR                                    | Scalars only                                                  | Used in conditional statements likeif                 |
% | ||       | `                 | Element-wise OR   | Scalars or arrays                                   | Used for element-wise logical operations on arrays.           | Evaluates all elements of the arrays.                 |




%% eval()

just realized... if it's too long, then it's literally unusable
