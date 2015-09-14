package engine.models 
{
	import Box2D.Common.Math.b2Vec2;
	import engine.RacingWorld;
	import flash.geom.Point;
	
	/**
	 * Holds the launch params to be shared between display and physics calcs 
	 * 
	 * This class is terribly tightly coupled with PlayableCar
	 * Point objs refer to pixels. b2vec2 refer to physical coords.
	 * Rotations to degrees. Angles to radians.
	 * 
	 * @author João Costa
	 */
	public class LaunchParams 
	{
		
		private var _mousePos:Point;
		public var player:Player;
		public var angle:Number;
		public var backwards:Boolean = false;
		public var projectedWheelsAngle:Number;
		public var projectedCarPos:Point = new Point();
		public var projectedCarRotation:Number;
		public var projectedPath:Vector.<Point>;
		private var _from:b2Vec2;
		private var _carPos:Point;
		
		private var scale:Number = 1;
		
		public function LaunchParams(player:Player,mousePos:Point, scale:Number) 
		{
			this.player = player;
			this.scale = scale;
			this.mousePos = mousePos;
			this.projectedPath = new Vector.<Point>;
			_carPos = player.carSprite.parent.localToGlobal(new Point(player.carSprite.x, player.carSprite.y));
			
		}
		
		/**
		 * Adds a point to preddiction path
		 * @param	x
		 * @param	y
		 */
		public function addPathPoint(x:Number, y:Number):void {
			projectedPath.push(new Point(x * scale, y * scale));
		}
		
		public function get mousePos():Point 
		{
			return _mousePos;
		}
	
		public function set mousePos(value:Point):void 
		{
			_from = new b2Vec2(value.x / scale, value.y / scale);
			_mousePos = value;
		}
		
		public function get from():b2Vec2 
		{
			return _from;
		}
		
		public function set from(value:b2Vec2):void 
		{
			//_mousePos = new Point(value.x * scale, value.y * scale);
			_from = value;
		}
		
		public function get carPos():Point 
		{
			return _carPos;
		}
		
		/**
		 * 
		 * @return number in [0.0 .. 1.0]
		 */
		public function get strength():Number {
				//limit strength to match the launcher display...shouldnt be here >.<
			var distance:Number = (from.Length()*scale -RacingWorld.MIN_LAUNCH_DIST)/(RacingWorld.MAX_LAUNCH_DIST-RacingWorld.MIN_LAUNCH_DIST);
			
			return Math.max(0, Math.min(1, distance));
		}
		
		/**
		 * Launch strength multiplied by car params
		 */
		public function get power():Number {
			return strength * player.carData.horsepower*20;
		}
	}

}