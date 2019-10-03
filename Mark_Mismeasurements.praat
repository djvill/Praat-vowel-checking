####
#### Mark_Mismeasurements.praat
####
#### Dan Villarreal
#### daniel.j.villarreal-at-gmail.com; github.com/djvill
####
#### Provides an interface for rapidly checking vowel tokens for measurement 
#### error and recording error data. Includes lots of advanced settings to
#### customize display, input data structure, etc.
####
#### Requires, at minimum, a csv file with at least four columns (in any order):
#### paths to sound files, vowel start times, vowel end times, and genders; plus
#### the sound files themselves.
####


####USER-INPUT SETTINGS####-----------------------------------------------------

form Mark mismeasurements
	sentence Base_directory
	sentence csv_file_path Female_DRESS.csv
	natural Starting_row 1
	boolean Reverse_rows 0
	boolean Save_output_table 1
	word Output_table_suffix _checked
	boolean Play_sound 1
endform

##Ensure base_directory$ ends in "/"
if not endsWith(base_directory$, "/") or not endsWith(base_directory$, "\")
	base_directory$ = base_directory$ + "/"
endif

####ADVANCED SETTINGS####-------------------------------------------------------

####COLUMN NAMES

##N.B. if column names show up in table surrounded by double-quotes, use three
##  sets of double-quotes here.

##Columns may be in any order in the table.

##Mismeasurements: Should contain only TRUE, FALSE, or blank
mismeas_col$ = """Mismeas_Hand"""
##F1 measurements in Hz: If table doesn't have F1, set to ""
f1_col$ = """F1"""
##F2 measurements in Hz: If table doesn't have F2, set to ""
f2_col$ = """F2"""
##cursor_col: Where should the horizontal cursor end up after toggling between 
##  F1 & F2?
cursor_col$ = """F2"""
##Textgrid file paths
tg_col$ = """TG"""
##Sound file paths
sound_col$ = """Sound"""
##Vowel start times, relative to times in tgStart_col$
vowelStart_col$ = """VowelStart"""
##Vowel end times, relative to times in tgStart_col$
vowelEnd_col$ = """VowelEnd"""
##Textgrid start times: If all Textgrids start at 0, set to ""
tgStart_col$ = """Line"""
##Gender: To use standard settings, should contain only "Female", "F", "Male",
##  or "M"
gender_col$ = """Gender"""
##Subtable: For the purposes of counting consecutive/total responses, treat the
##  table as having subtables split by different values of this column. To treat
##  the table as having no subtables, set to ""
# subtable_col$ = """Speaker"""
subtable_col$ = ""


####SOUND CLIP SETTINGS

##Zoom factor: How zoomed-out should the displayed clip be? E.g., a zoom factor
##  of 2 is equivalent to zooming into the token then hitting "out" twice
zoom_factor = 2
##Number of pauses: How many times should the horizontal cursor pause over each
##  formant after playing the sound?
num_pauses = 2
##Cursor pause time: How long should the horizontal cursor pause over each
##  formant after playing the sound?
cursor_pause_time = 0.2
##Convert to mono (boolean)
convert_mono = 0
##Scale intensity (dB): To what intensity should the clip be scaled? To disable,
##  set to undefined
scale_intensity = 70
# scale_intensity = undefined
##No warning (boolean): When reading sound file, don't show "Warning: File too 
##  small...Missing samples were set to zero" popup window
no_warning = 1
##Cursor to midpoint (boolean): If 1, vertical cursor will be placed at 
##  vowel midpoint; if 0, the whole vowel will be selected
cursor_midpoint = 1

####EARLY STOPPING REMINDERS

##You can set reminders for which the script gives you the option to exit early.
##  For example, you might decide that if at least 25% of a speaker's tokens are
##  mismeasured, you'll stop checking that speaker; or if at least 3 consecutive
##  tokens are not mismeasured, you'll assume that the rest are not mismeasured.

##If you've specified a subtable_col$, these reminders operate over subtables.

##There are three types of early stopping reminders (total, consec, pct) apiece
##  for both types of response (mismeas, notMismeas). To disable a reminder, set
##  it to undefined.

no_total_rem = undefined
no_consec_rem = 3
no_pct_rem = undefined
yes_total_rem = undefined
yes_consec_rem = undefined
yes_pct_rem = undefined


####OTHER MISCELLANEOUS SETTINGS

## !!TODO: Add comments
mismeasured_button_text$ = "Yes"
not_mismeasured_button_text$ = "No"
if save_output_table
	exit_button_text$ = "Save and exit"
else
	exit_button_text$ = "Exit"
endif

default_button = 2

##Formants from table (boolean): Should formant measurements that are displayed
##  onscreen come from the table? If 0, measurements will come from a Formant
##  object instead

## !!TODO: Fill in

##Check tokens for which mismeas_col$ is blank (boolean)
check_blank = 1

##Check tokens for which mismeas_col$ is TRUE (boolean)
check_TRUE = 0

##Check tokens for which mismeas_col$ is FALSE (boolean)
check_FALSE = 0

####SET UP TABLE####------------------------------------------------------------

##Load table, bring it into focus, and get dimensions
table = Read Table from comma-separated file: base_directory$ + csv_file_path$
View & Edit
numRow = object[table].nrow
numCol = object[table].ncol

##Ensure that all columns specified in advanced settings are in the table

## !!TODO: Fill in

##If starting from the bottom, reverse rows
if reverse_rows
	Reflect rows
endif

## !!TODO: Start subtable stuff here-ish

##Initialize variables
row = starting_row
no_total = 0
no_consec = 0
no_pct = 0
yes_total = 0
yes_consec = 0
yes_pct = 0
exit_early = 0

##Add up existing yes_total in case the "Mismeasured" column is not empty
selectObject: table
for yesRow from 1 to numRow
	mismeasured$ = Get value: yesRow, mismeas_col$
	if mismeasured$ = "TRUE"
		yes_total += 1
	endif
endfor

####CHECK TOKENS####------------------------------------------------------------

repeat
	selectObject: table
	mismeasured$ = Get value: row, mismeas_col$
	##Check tokens according to settings for which ones to check
	if (check_blank and mismeasured$ = "") or (check_TRUE and mismeasured$ = "TRUE") or (check_FALSE and mismeasured$ = "FALSE")
		##Initialize variables
		click_mismeas = 0
		
		##Get info
		tgName$ = Get value: row, tg_col$
		soundName$ = Get value: row, sound_col$
		vowelStart = Get value: row, vowelStart_col$
		vowelEnd = Get value: row, vowelEnd_col$
		vowelDur = vowelEnd - vowelStart
		vowelMid = vowelDur/2 + vowelStart
		lineStart = Get value: row, tgStart_col$
		gender$ = Get value: row, gender_col$
		cursorFreq = Get value: row, cursor_col$
		f1 = Get value: row, f1_col$
		f2 = Get value: row, f2_col$
		if gender$ = "Female" or gender$ = "F"
			maxForm = 5500
			minPitch = 100
		elsif gender$ = "Male" or gender$ = "M"
			maxForm = 5000
			minPitch = 75
		else
			exitScript: "Unknown gender 'gender$' in row 'row'."
		endif
		
		# ##If there's a change in reset_counters_by$ column, reset counters
		# counterVal$ = Get value: row, reset_counters_by$
		# if counterVal$ <> prevCounterVal$
			# yes_total = 0
			# no_consec = 0
		# endif
		# prevCounterVal$ = counterVal$
		
		##Read files
		tg = Read from file: base_directory$ + tgName$
		Shift times by: lineStart
		if no_warning
			sound = nowarn Read from file: base_directory$ + soundName$
		else
			sound = Read from file: base_directory$ + soundName$
		endif
		Shift times by: lineStart
		soundDur = Get total duration
		
		##Get clip timing
		clipStart = max(vowelMid - vowelDur * zoom_factor, lineStart)
		clipEnd = min(vowelMid + vowelDur * zoom_factor, lineStart + soundDur)
		
		##Optionally convert to mono
		if convert_mono
			selectObject: sound
			soundMono = Convert to mono
			removeObject: sound
			sound = soundMono
		endif
		
		##Optionally scale intensity
		if scale_intensity <> undefined
			selectObject: sound
			intens = To Intensity: minPitch, 0, 1
			intensAll = Get mean: 0, 0, "energy"
			intensClip = Get mean: clipStart, clipEnd, "energy"
			removeObject: intens
			selectObject: sound
			##Scale intensity of overall sound such that the clip is at scale_intensity
			Scale intensity: scale_intensity * intensAll / intensClip
		endif
		
		##Open in editor
		selectObject: tg, sound
		View & Edit
		editor: tg
			##Show just spectrogram and formants
			Show analyses: 1, 0, 0, 1, 0, 10.0
		
			##Zoom into vowel, with context
			Zoom: clipStart, clipEnd
			Formant settings: maxForm, 5, 0.025, 30, 1
			##Move cursor to midpoint/selection
			if cursor_midpoint
				Move cursor to: vowelMid
			else
				Select: vowelStart, vowelEnd
			endif
			
			##Optionally play the window
			if click_mismeas = 0 and play_sound
				Play window
			endif
			
			##Toggle the frequency cursor between f1 & f2
			for toggle from 1 to num_pauses
				Move frequency cursor to: f1
				sleep(cursor_pause_time)
				Move frequency cursor to: f2
				sleep(cursor_pause_time)
			endfor
			if cursorFreq <> f2
				Move frequency cursor to: cursorFreq
				sleep(cursor_pause_time)
			endif
			
			##Ask whether the vowel is mismeasured
			beginPause: "Is this mismeasured?"
				comment: "F1: " + fixed$(f1, 0)
				comment: "F2: " + fixed$(f2, 0)
			click_mismeas = endPause: mismeasured_button_text$, not_mismeasured_button_text$, exit_button_text$, default_button
			Close
		endeditor
		
		removeObject: tg, sound
		
		##Write value to table and increment counters
		if click_mismeas = 1 or click_mismeas = 2
			if click_mismeas = 1
				misMeas$ = "TRUE"
				no_consec = 0
				yes_consec += 1
				yes_total += 1
				yes_pct = yes_total / numRow
			elsif click_mismeas = 2
				misMeas$ = "FALSE"
				yes_consec = 0
				no_consec += 1
				no_total += 1
				no_pct = no_total / numRow
			endif
			
			selectObject: table
			Set string value: row, mismeas_col$, misMeas$
		endif
		
		if click_mismeas = 3
			exit_early = 1
		endif
	endif
	
	##Increment row
	row += 1
	
	##If bottom row hasn't been reached, check early stopping reminders
	if row <= numRow
		no_more_rems = 0
		
		if no_total >= no_total_rem and not no_more_rems
			beginPause: "At least 'no_total_rem' total ""No""s"
				comment: "That's 'no_total' total ""No""s. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				no_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif
		
		if no_consec >= no_consec_rem and not no_more_rems
			beginPause: "At least 'no_consec_rem' consecutive ""No""s"
				comment: "That's 'no_consec' ""No""s in a row. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				no_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif
		
		if no_pct >= no_pct_rem and not no_more_rems
			beginPause: "More than " + fixed$(100 * no_pct, 1) + "% ""No""s"
				comment: "That's " + fixed$(100 * no_pct, 1) + "% ""No""s. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				no_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif
		
		if yes_total >= yes_total_rem and not no_more_rems
			beginPause: "At least 'yes_total_rem' total ""Yes""s"
				comment: "That's 'yes_total' total ""Yes""s. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				yes_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif
		
		if yes_consec >= yes_consec_rem and not no_more_rems
			beginPause: "At least 'yes_consec_rem' consecutive ""Yes""s"
				comment: "That's 'yes_consec' ""Yes""s in a row. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				yes_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif

		if yes_pct >= yes_pct_rem and not no_more_rems
			beginPause: "More than " + fixed$(100 * yes_pct, 1) + "% ""Yes""s"
				comment: "That's " + fixed$(100 * yes_pct, 1) + "% ""Yes""s. Save and exit?"
			click_rem = endPause: "Don't exit", "Ignore reminders", "Save and exit", 1
			if click_rem = 2
				no_more_rems = 1
			elsif click_rem = 3
				exit_early = 1
			endif
		endif
	endif
	
until row > numRow or exit_early


####FINISH UP####---------------------------------------------------------------

##If starting from the bottom, un-reverse rows
selectObject: table
if reverse_rows
	Reflect rows
endif

##Warn the user if potentially overwriting an existing file
if save_output_table
	selectObject: table
	##create output file path
	output_file$ = replace$(csv_file_path$, ".csv", output_table_suffix$ + ".csv", 1)
	##If table already exists, make sure user wants to overwrite
	if fileReadable(base_directory$ + output_file$)
		beginPause: "Output file already exists"
			comment: "Output file 'output_file$' already exists. Overwrite?"
		clikt = endPause: "Overwrite", "Don't save", 1
		if clikt = 2
			save_output_table = 0
		endif
	endif
endif
##Save
if save_output_table
	Save as comma-separated file: base_directory$ + output_file$
endif

####TODO
## - Implement parameterized stuff listed above
## - Move indiv-token stuff into a procedure
## - Create mismeas_col$ if it doesn't exist
## - Don't re-read files each time, in case files are large (instead, store new files' IDs so they can be re-referenced, and remove all files at the end); also, before any token-checking, ensure all files are readable
## - Implement subtables, probably by creating another procedure; change "Save [and exit]" button on reminder pause windows to "Continue to next 'subtable_col$' group"; add subtable_col$ to main pause window above F1 & F2
## - Make textgrid optional
## - More buttons on main pause window: Re-toggle button, (maybe) "Skip for now"