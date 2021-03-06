class Settings {
	const LAST_HR = 0;
	const MAX_HR = 10;
	const AVERAGE_HR = 20;
	
	var lastLapHrType;
	var restThresholdPace;
	var isSimpleMode;

	function initialize() {
        if ( Toybox.Application has :Properties ) {
			lastLapHrType = Application.Properties.getValue("lastLapHrType");
			restThresholdPace = Application.Properties.getValue("restThresholdPace");
			isSimpleMode = Application.Properties.getValue("isSimpleMode");
		} else {
			lastLapHrType = Application.AppBase.getProperty("lastLapHrType");
			restThresholdPace = Application.AppBase.getProperty("restThresholdPace");
			isSimpleMode = Application.AppBase.getProperty("isSimpleMode");
		}
    }
}