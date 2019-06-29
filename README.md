# This script tries to determine the time when you woke up.
# Of course, it only applies if you turn your computer on not too long ago after getting out of bed.
# If not, it might still be useful as an indicator of when you turned your computer on.
# It works by getting information from journalctrl, sleep-resume dates and boot dates.
# It then loops through them and tries to find when the difference is above a certain gap (5 hours by default, it can be configured with the -g flag).
# Then it prints the time and "timeago" information of when you probably woke up.