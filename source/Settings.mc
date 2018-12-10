class Settings {
	const LAST_HR = 0;
	const MAX_HR = 10;
	const AVERAGE_HR = 20;
	
	var lastLapHrType;
	var restThresholdPace;

	function initialize() {
        if ( Toybox.Application has :Properties ) {
			lastLapHrType = Application.Properties.getValue("lastLapHrType");
			restThresholdPace = Application.Properties.getValue("restThresholdPace");
		} else {
			lastLapHrType = Application.AppBase.getProperty("lastLapHrType");
			restThresholdPace = Application.AppBase.getProperty("restThresholdPace");
		}
    }
}