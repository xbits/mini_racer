package engine.models 
{
	import engine.physics.PlayableCar;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author João Costa
	 */
	public class Player 
	{
		private var _carSprite:Sprite;
		public var carData:CarParams;
		public var playableCar:PlayableCar;
		
		public function Player(carSprite:Sprite = null, carData:CarParams = null) {	
			this.carSprite = carSprite;
			this.carData = carData;
		}
		
		public function get carSprite():Sprite {
			return _carSprite;
		}
		
		public function set carSprite(newSprite:Sprite):void {
			
			//all car sprites appear to be tilted 90º so this is  a little hack to fix that
			//it assumes a car is allways longer than widder...NTS: test all cars!
			if(newSprite.width > newSprite.height){
				var container:Sprite = new Sprite();
				container.rotation = newSprite.rotation;
				newSprite.rotation = -90;
				newSprite.x = 0;
				newSprite.y = 0;
				container.addChild(newSprite);
			//	var myRect:Rectangle = newSprite.getRect(container);//to account for displaced swf's
			//	newSprite.x = -myRect.x-myRect.width*.5;
			//	newSprite.y = -myRect.y -myRect.height ;
				newSprite = container;
			}
			this._carSprite = newSprite;
		}
	}

}