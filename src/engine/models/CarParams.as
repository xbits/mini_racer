package engine.models 
{
	/**
	 * ...
	 * @author João Costa
	 */
	public class CarParams 
	{
		public var name:String;
		
		public var horsepower:Number = 90;
		public var stability:Number = 3;
		public var  maxSteerAngle:Number = Math.PI / 3;
		public static const FRONT_WHEEL_OFFSET:Number = 0.9;
		public static const REAR_WHEEL_OFFSET:Number = 0.9;
		public static const STEER_SPEED:Number = 1.5;
		
		
		public function CarParams(rawParams:XML = null) 
		{
			if(rawParams)
				setParams(rawParams);
		}
		
		public function setParams(rawParams:XML):void {
			this.horsepower = rawParams.horsepower;
			this.stability = rawParams.stability;
			this.name = rawParams.name;	
		}
		
	}

}