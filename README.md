# TrackWorkout

Data field for Garmin Forerunner watches designed for interval track workouts.

When I do interval workouts on the track, I usually want the lap distance to be rounded to 200 or 400 meters. It's common that GPS doesn't work well on short tracks (nevermind the indoor tracks!),
so when you press the Lap button after a lap it can be counted as 370 or 420 meters. So you can't tell the pace. Also I'm used to forget how many laps I've done when the interval is longer than 5-6 laps.
So I've made this field to help myself to overcome the track workouts.

Main features:
- Rounds the lap distance to the nearest 200x meters and displays pace and distance according to that rounded value.
- Automatically counts the laps in the interval. Interval is detected according to the threshold pace. Anything faster is workout interval, slower is the rest.

Displays:
- Current lap time
- Last lap time
- Last lap pace
- Number of laps done in the current interval (red - workout interval, green - rest)
- Last lap HR (HR at the end of the lap / avg HR / max HR)
- Current interval distance rounded to the 200x meters
- Current interval time
- Current interval pace
- Current heart rate
