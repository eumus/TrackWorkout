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
	private var screenWidth;
	private var tinyHeight;
	private var mediumHeight;
	private var bigHeight;
	private var numberFont;
	private var vertTextOffset;

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
    	screenWidth = dc.getWidth();
		if (dc.getHeight() <= 220) {
	    	tinyHeight = 24;
			mediumHeight = 32;
			bigHeight = 54;
			numberFont = Graphics.FONT_NUMBER_MEDIUM;
			vertTextOffset = 0;
		} else if (dc.getHeight() <= 240) {
	    	tinyHeight = 26;
			mediumHeight = 36;
			bigHeight = 58;
			numberFont = Graphics.FONT_NUMBER_MEDIUM;
			vertTextOffset = 0;
		} else if (dc.getHeight() <= 260) {
	    	tinyHeight = 10;
			mediumHeight = 40;
			bigHeight = 88;
			numberFont = Graphics.FONT_NUMBER_MILD;
			vertTextOffset = -8;
		} else {
	    	tinyHeight = 10;
			mediumHeight = 44;
			bigHeight = 96;
			numberFont = Graphics.FONT_NUMBER_MILD;
			vertTextOffset = -8;
		}
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
		if (settings.isSimpleMode) {
			drawTopFieldsSimpleMode(dc, info);
		} else {
			drawTopFields(dc, info);
		}
	    drawBottomField(dc, info);
    }
    
    function drawTopFields(dc, info) {
	    // Draw the current lap time in the top
	    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_WHITE);
	    drawText(dc, screenWidth / 2, 8, numberFont, toMinSec(info.timerTime - prevTimerTime), Graphics.TEXT_JUSTIFY_CENTER); 
    
    	var fieldTop = mediumHeight + 18;
		var fieldBottom = dc.getHeight() - mediumHeight - 6;
    	var y = fieldTop + 2;
    	// First row: lap time, lap pace
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, 20, y, numberFont, toMinSec(lastLapTime), Graphics.TEXT_JUSTIFY_LEFT);
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, screenWidth - 20, y, numberFont, toMinSec(lastLapPace * 1000), Graphics.TEXT_JUSTIFY_RIGHT);		
		y += mediumHeight + 6;
    	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    	dc.drawLine(2, y, screenWidth - 2, y);
    	dc.drawLine(screenWidth / 2, fieldTop, screenWidth / 2, y);
    	// Second row: lap number, interval number, interval distance
    	var rowTop = y;
    	y += 6;
		dc.setColor((isWorkoutLap ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_GREEN), Graphics.COLOR_TRANSPARENT);
		drawText(dc, 6, y, numberFont, lapCnt, Graphics.TEXT_JUSTIFY_LEFT);
		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
		
		var smallerFontVertOffset = 4;
		if (numberFont == Graphics.FONT_NUMBER_MILD) {
			smallerFontVertOffset = 0;
		}
		drawText(dc, screenWidth * 2 / 5 - 10, y + smallerFontVertOffset, Graphics.FONT_NUMBER_MILD, intervalCnt, Graphics.TEXT_JUSTIFY_RIGHT);
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		drawText(dc, screenWidth * 3 / 5 + 8, y, numberFont, lastLapHr, Graphics.TEXT_JUSTIFY_RIGHT);
		drawText(dc, screenWidth - 6, y + smallerFontVertOffset, Graphics.FONT_NUMBER_MILD, intervalDistance, Graphics.TEXT_JUSTIFY_RIGHT);
    	
    	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		y += mediumHeight + 6;
    	dc.drawLine(2, y, screenWidth - 2, y);
    	dc.drawLine(screenWidth / 5 + 4, rowTop, screenWidth / 5 + 4, y);		
    	dc.drawLine(screenWidth * 2 / 5 - 6, rowTop, screenWidth * 2 / 5 - 6, y);		
    	dc.drawLine(screenWidth * 3 / 5 + 12, rowTop, screenWidth * 3 / 5 + 12, y);		
    	// Third row: interval time, interval pace
    	y += 6;
    	dc.drawLine(screenWidth / 2, y, screenWidth / 2, fieldBottom);
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, 24, y, numberFont, toMinSec(intervalTime), Graphics.TEXT_JUSTIFY_LEFT);   	
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, screenWidth - 24, y, numberFont, toMinSec(intervalPace * 1000), Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    function drawTopFieldsSimpleMode(dc, info) {
	    // Draw the current lap time in the top
	    dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_WHITE);
	    drawText(dc, screenWidth / 2, 16, Graphics.FONT_NUMBER_THAI_HOT, toMinSec(info.timerTime - prevTimerTime), Graphics.TEXT_JUSTIFY_CENTER); 

    	var fieldTop = bigHeight + 13;
		var fieldBottom = dc.getHeight() - mediumHeight - 6;
    	var titleHeight = tinyHeight - 1;
    	
    	// Second row: lap number, interval number, interval distance
    	var y = fieldTop;
    	var rowTop = y;
    	y += titleHeight;
		dc.setColor((isWorkoutLap ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_GREEN), Graphics.COLOR_TRANSPARENT);
		drawText(dc, 6, y, numberFont, lapCnt, Graphics.TEXT_JUSTIFY_LEFT);
		dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
		drawText(dc, screenWidth / 2 + 4, y, numberFont, intervalCnt, Graphics.TEXT_JUSTIFY_RIGHT);
		dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		drawText(dc, screenWidth - 6, y, numberFont, intervalDistance, Graphics.TEXT_JUSTIFY_RIGHT);
    	
    	dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		drawText(dc, 8, rowTop, Graphics.FONT_XTINY, "Lap", Graphics.TEXT_JUSTIFY_LEFT);
		drawText(dc, screenWidth / 2 + 4, rowTop, Graphics.FONT_XTINY, "Interval", Graphics.TEXT_JUSTIFY_RIGHT);
		drawText(dc, screenWidth - 8, rowTop, Graphics.FONT_XTINY, "Distance", Graphics.TEXT_JUSTIFY_RIGHT);
    	
		y += mediumHeight + 4;
    	dc.drawLine(2, y, screenWidth - 2, y);
    	dc.drawLine(screenWidth / 4 - 10, rowTop + 6, screenWidth / 4 - 10, y);		
    	dc.drawLine(screenWidth / 2 + 8, rowTop + 6, screenWidth / 2 + 8, y);	
    		
    	// Third row: interval time, interval pace
    	if (numberFont == Graphics.FONT_NUMBER_MILD) {
    		rowTop = y + 8;
    		y += titleHeight + 4;	
    	} else {
	    	rowTop = y - 3;
    		y += titleHeight - 5;	
    	}
    	dc.drawLine(screenWidth / 2, rowTop + 8, screenWidth / 2, fieldBottom - 4);
		drawText(dc, 24, rowTop, Graphics.FONT_XTINY, "Time", Graphics.TEXT_JUSTIFY_LEFT);
		drawText(dc, screenWidth - 24, rowTop, Graphics.FONT_XTINY, "Pace", Graphics.TEXT_JUSTIFY_RIGHT);

    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, 24, y, numberFont, toMinSec(intervalTime), Graphics.TEXT_JUSTIFY_LEFT);   	
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    	drawText(dc, screenWidth - 24, y, numberFont, toMinSec(intervalPace * 1000), Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
   
    function drawBottomField(dc, info) {
    	var val = info.currentHeartRate;
	    var bottomBgColor = getColorByHr(val);
		if (val == null || val == 0) {
			val = "--";
		}
	    var y = dc.getHeight() - mediumHeight - 6;
	    dc.setColor(bottomBgColor, bottomBgColor);
	    dc.fillRectangle(0, y, screenWidth, dc.getHeight() - y);
	    dc.setColor(getForegroundColorFor(bottomBgColor), Graphics.COLOR_TRANSPARENT);
	    
	    drawText(dc, screenWidth / 2, y + 1, numberFont, val, Graphics.TEXT_JUSTIFY_CENTER); 
    }

    function drawText(dc, x, y, font, text, justification) {
    	dc.drawText(x, y + vertTextOffset, font, text, justification);
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
    
    function getForegroundColorFor(backgroundColor) {
    	if (backgroundColor == Graphics.COLOR_RED) {
    		return Graphics.COLOR_WHITE;
		} else {
			return Graphics.COLOR_BLACK;
		}
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
