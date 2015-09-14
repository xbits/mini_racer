package engine.models 
{
	import engine.physics.PlayableCar;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/**
	 * Represents a player troughout a race.
	 * Also does a little hack on the player sprite which shouldn't be here...but....
	 * 
	 * @author João Costa
	 */
	public class Player 
	{
		private var _carSprite:Sprite;
		private var _carGhost:Sprite;
		public var carData:CarParams;
		public var playableCar:PlayableCar;
		
		public var curCheckpoint:int;
		public var curRaceTime:int = 0;
		public var finished:Boolean;
		public var polePosition:int = 0;
		public var disqualified:Boolean = false;
		
		public function Player(carSprite:Sprite = null, carData:CarParams = null) {	
			this.carSprite = carSprite;
			this.carData = carData;
			curCheckpoint = 0;
			curRaceTime = 0;
			finished = false;
		}
		
		public function get carSprite():Sprite {
			return _carSprite;
		}
		
		public function set carSprite(newSprite:Sprite):void {
			
			newSprite.scaleX = newSprite.scaleY = 1.1;
			//all car sprites appear to be tilted 90º so this is a little hack to fix that
			//it assumes a car is always longer than widder...NTS: test all cars!
			if(newSprite.width > newSprite.height){
				var container:Sprite = new Sprite();
				container.rotation = newSprite.rotation;
				newSprite.rotation = -90;
				newSprite.x = 0;
				newSprite.y = 0;
				container.addChild(newSprite);
				var myRect:Rectangle = newSprite.getRect(container);//to account for displaced swf's
				newSprite.x = -myRect.x-myRect.width*.5;
				newSprite.y = -myRect.y -myRect.height*.5 ;
				newSprite = container;
			}
			this._carSprite = newSprite;
			this._carGhost = getCarClone();
		}
		
		/**
		 * This will bug if car is moved...
		 * 
		 * 
		 */
		private function getCarClone():Sprite {
			//FIXME not working
			if (!carSprite) { return null; }
			var targetTransform:Matrix = carSprite.transform.concatenatedMatrix;
			targetTransform.tx = -carSprite.width/2;
			targetTransform.ty = -carSprite.height/2;

			var cloneData:BitmapData = new BitmapData(carSprite.width, carSprite.height, true, 0x00000000);
			cloneData.draw(carSprite, targetTransform);
			
			var bmpClone:Bitmap = new Bitmap(cloneData);
			var container:Sprite = new Sprite();
			container.addChild(bmpClone);
			container.alpha = 0.5;
			return container;
		}
		
		public function get carGhost():Sprite 
		{
			return _carGhost;
		}
		
		private function set carGhost(value:Sprite):void 
		{
			_carGhost = value;
		}
	}

}