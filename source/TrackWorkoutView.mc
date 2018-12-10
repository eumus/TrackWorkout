using Toybox.WatchUi;
using Toybox.Graphics;

class TrackWorkoutView extends WatchUi.DataField {
	private var zones;
	private var settings;
	
	private var lastLapHr;
	private var avgHrCnt;
	private var maxHr;
	private var avgHr;
	
	private var prevTimerTime;
	private var prevElapsedDistance;
	
	private var lapCnt;
	private var lastLapTime;
	private var lastLapDistance;
	private var lastLapPace;
	
	private var intervalCnt;
	private var intervalTime;
	private var intervalDistance;
	private var intervalPace;
	
	private var isWorkoutLap;

    function initialize() {
        DataField.initialize();
        zones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
        settings = new Settings();
        prevTimerTime = 0;
        prevElapsedDistance = 0;
        lastLapHr = "--";
        avgHrCnt = 0;
        avgHr = 0;
        maxHr = 0;
        lapCnt = 0;
        lastLapTime = 0;
        lastLapDistance = 0;
        intervalCnt = 0;
        intervalTime = 0;
        intervalDistance = 0;
        isWorkoutLap = false;
        lastLapPace = 0;
        intervalPace = 0;
    }

    function onLayout(dc) {
    }

    function compute(info) {
    	if (prevElapsedDistance == null || prevElapsedDistance == 0) {
    		prevElapsedDistance = info.elapsedDistance;
    	}
    	var currentHr = info.currentHeartRate;
    	if (currentHr != null) {
    		if (currentHr > maxHr) {
    			maxHr = currentHr;
			}
			if (avgHrCnt == 0) {
				avgHr = currentHr;
			} else {
				avgHr = (avgHr * avgHrCnt + currentHr) / (avgHrCnt + 1);
			}
			avgHrCnt++;
    	}
    }
    
    function onSettingsChanged() {
    	settings = new Settings();
    }
        
    function onTimerLap() {
		var info = Activity.getActivityInfo();
		var timerTime = info.timerTime;
		var elapsedDistance = info.elapsedDistance;
		lastLapTime = timerTime - prevTimerTime;
		if (lastLapTime < 0) {
			lastLapTime = 0;
		}
		if (elapsedDistance != null) {
			// Round Lap distance the nearest 200m
			lastLapDistance = ((elapsedDistance - ((prevElapsedDistance == null) ? 0 : prevElapsedDistance) + 100) / 200).toLong() * 200;
			if (lastLapDistance > 0) {
				lastLapPace = lastLapTime / lastLapDistance;
				var isCurrentLapWorkout = lastLapPace < settings.restThresholdPace;
//				System.println("time=" + lastLapTime + "; dist=" + lastLapDistance + " (real=" + (elapsedDistance - prevElapsedDistance) + "); pace=" + lastLapPace + "; isWk=" + isCurrentLapWorkout);
				if (isCurrentLapWorkout && !isWorkoutLap) { // Workout after rest
					lapCnt = 0;
					intervalCnt++;
					intervalTime = 0;
					intervalDistance = 0;
				} else if(!isCurrentLapWorkout && isWorkoutLap) { // Rest after workout
					lapCnt = 0;
					intervalTime = 0;
					intervalDistance = 0;
				}
				isWorkoutLap = isCurrentLapWorkout;
				intervalDistance += lastLapDistance;
				intervalPace = (intervalTime + lastLapTime) / intervalDistance;
			}
			prevElapsedDistance = elapsedDistance;
		}
		intervalTime += lastLapTime;
		prevTimerTime = timerTime;
		switch(settings.lastLapHrType) {
			case Settings.MAX_HR:
				lastLapHr = maxHr;
				break;
			case Settings.AVERAGE_HR:
				lastLapHr = avgHr;
				break;
			default:
				lastLapHr = info.currentHeartRate;											
		}
		if (lastLapHr == null || lastLapHr == 0) {
			lastLapHr = "--";
		}
		maxHr = 0;
    	avgHr = 0;
    	avgHrCnt = 0;
    	lapCnt++;
    }
    
    function onUpdate(dc) {
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
	    dc.clear();

	    var info = Activity.getActivityInfo();	    	    
		drawTopField(dc, info);
		drawMiddleFields(dc);
	    drawBottomField(dc, info);
    }
    
    function drawMiddleFields(dc) {
    	var width = dc.getWidth();
    	var fieldTop = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) + 18;
		var fieldBottom = dc.getHeight() - dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) - 6;
    	// First row: lap time, lap pace
    	var y = fieldTop + 2;
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	dc.drawText(20, y, Graphics.FONT_NUMBER_MEDIUM, toMinSec(lastLapTime), Graphics.TEXT_JUSTIFY_LEFT);
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    	dc.drawText(width - 20, y, Graphics.FONT_NUMBER_MEDIUM, toMinSec(lastLapPace * 1000), Graphics.TEXT_JUSTIFY_RIGHT);		
		y += dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) + 6;
    	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    	dc.drawLine(2, y, width - 2, y);
    	dc.drawLine(width / 2, fieldTop, width / 2, fieldBottom);
    	// Second row: lap number, interval number, interval distance
    	var rowTop = y;
    	y += 6;
		dc.setColor((isWorkoutLap ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_GREEN), Graphics.COLOR_TRANSPARENT);
		dc.drawText(6, y, Graphics.FONT_NUMBER_MEDIUM, lapCnt, Graphics.TEXT_JUSTIFY_LEFT);
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		dc.drawText(width / 2 - 4, y, Graphics.FONT_NUMBER_MEDIUM, lastLapHr, Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(width - 6, y, Graphics.FONT_NUMBER_MEDIUM, intervalDistance, Graphics.TEXT_JUSTIFY_RIGHT);
    	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		y += dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) + 6;
    	dc.drawLine(2, y, width - 2, y);
    	dc.drawLine(width / 5 + 4, rowTop, width / 5 + 4, y);		
    	// Third row: interval time, interval pace
    	y += 6;
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	dc.drawText(24, y, Graphics.FONT_NUMBER_MEDIUM, toMinSec(intervalTime), Graphics.TEXT_JUSTIFY_LEFT);   	
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    	dc.drawText(width - 24, y, Graphics.FONT_NUMBER_MEDIUM, toMinSec(intervalPace * 1000), Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function drawTopField(dc, info) {
	    // Draw the current lap time in the top
	    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_WHITE);
	    dc.drawText(dc.getWidth() / 2, 8, Graphics.FONT_NUMBER_MEDIUM, toMinSec(info.timerTime - prevTimerTime), Graphics.TEXT_JUSTIFY_CENTER); 
    }
    
    function drawBottomField(dc, info) {
    	var val = info.currentHeartRate;
	    var bottomBgColor = getColorByHr(val);
		if (val == null || val == 0) {
			val = "--";
		}
	    var y = dc.getHeight() - dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) - 6;
	    dc.setColor(bottomBgColor, bottomBgColor);
	    dc.fillRectangle(0, y, dc.getWidth(), dc.getHeight() - y);
	    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
	    
	    dc.drawText(dc.getWidth() / 2, y + 1, Graphics.FONT_NUMBER_MEDIUM, val, Graphics.TEXT_JUSTIFY_CENTER); 
    }
    
    function getColorByHr(hr) {
    	if (hr == null) {
    		return Graphics.COLOR_LT_GRAY;
    	} else if (hr > zones[1] && hr <= zones[2]) { // Zone 2
			return Graphics.COLOR_BLUE;
		} else if (hr > zones[2] && hr <= zones[3]) { // Zone 3
			return Graphics.COLOR_GREEN;
		} else if (hr > zones[3] && hr <= zones[4]) { // Zone 4
			return Graphics.COLOR_YELLOW;
		} else if (hr > zones[4]){ // Zone 5 and higher
			return Graphics.COLOR_RED;
		}
		return Graphics.COLOR_LT_GRAY; // Default to Zone 1 and below
    }
    
    function toMinSec(msValue) {
    	if (msValue <= 0) {
    		return "00:00";
    	}
    	var mins = (msValue / 1000 / 60) % 60;
    	var secs = (msValue / 1000) % 60;    	
	    return Lang.format("$1$:$2$", [mins.format("%02d"), secs.format("%02d")]);
    }
}
