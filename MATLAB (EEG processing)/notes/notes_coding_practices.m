
%% only in matlab
nest them in like dev.something if i need to config them directly in there later
else, just the variable itself


%% naming variables
% STILL NOT SURE

camelCase -> combines words without spaces, capitalizes first letter on 2nd word and forward
snake_case -> using undescores to separate words

% use snake_case to separate logical sections and
% and use camelCase in each section (and main section)

e.g. EEG_allMarkers

However, I'll use snake_case for all variables
and camelCase for some backup stuff, or very big, scattered, and non-uniform variables

%% comment labels

FIXME / (FIX) % code need fixing, doesn't work
BUG % seems working but contains bug
UGLY % working code but is not intuitive and really hard to understand what's going on
DEBUG % temporary codes used to track down errors, and troubleshooting purposes. May not be included in the final product
(HACK) % hackable (might not need this)

REVIEW % review for my own notes and knowledge
LEARN / (STUDY) % study and remember them for my own knowledge (exactly one-by-one learning, its beauty of it)

NOTE % key stuff to be noted down. Either for future coding or reviewing purposes
OPTIMIZE % working code but can be optimized even further for speed, efficiency or coding aesthetics
% Don't use "IMPROVE" lol. just a feeling, and yea.

IDEA % an idea to code later



%% prepare several scripts for coding large projects:

1. sandbox % sandbox area, can be discarded in the future. (DON'T CONFUSE WITH test: testing codes related to my project, not discardable)
2. template % codes that I might need again and again
3. quickRun / instantcode % codes to be executed immediately during my coding process
4. notes_... % notes_matlab, notes_analysis (-> related to my project), notes_coding_practices



