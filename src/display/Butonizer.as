package display 
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	/**
	 * Helper to create buttons lazy bsterd mode.
	 * 
	 * @author João Costa
	 */
	public class Butonizer 
	{
		private static const SCALE_CHANGE:Number = 1.2;
		
		private static var _instance:Butonizer;
		
		private var pairs:Array = [];
		
		public function Butonizer() {
			 if(_instance){throw new Error("Singleton... use getInstance()");} 
			_instance = this;
		}
		
		static public function getInstance():Butonizer {
			if (!_instance) {new Butonizer();}
			return _instance;
		}
		
		public function makeBtn(btn:Sprite, onClick:Function = null):void {
			if (!btn) return;
			
			btn.buttonMode = true;
			//btn.mouseChildren = false;//this is not nice...
			
			btn.addEventListener(MouseEvent.ROLL_OVER, onMouseOver,false,0);
			btn.addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			btn.addEventListener(MouseEvent.CLICK, onMouseClick);
			pairs.push(new BtnPair(btn, onClick));
			
		}
		
		public function unmakeBtn(btn:Sprite):void {
			var pair:BtnPair;
			for ( var i:int = pairs.length -1; i > -1; i-- ) {
				pair = pairs[i];
				if (pair.btn == btn) {
					btn.removeEventListener(MouseEvent.ROLL_OVER, onMouseOver);
					btn.removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
					btn.removeEventListener(MouseEvent.CLICK, onMouseClick);
					pairs.splice(i, 1);
				}
			}
		}
		
		private function onMouseOver(e:MouseEvent):void 
		{
			 e.target.scaleY *= SCALE_CHANGE;
			 e.target.scaleX *= SCALE_CHANGE;
		}
		
		private function onMouseOut(e:MouseEvent):void 
		{
			e.target.scaleY /= SCALE_CHANGE;
			e.target.scaleX /= SCALE_CHANGE; 
		}
		
		/**
		 * this appears to be mostly useless...couldn't teh event be passed directly to the callback....play sounds maybe...I'll leave it
		 * @param	e
		 */
		private function onMouseClick(e:MouseEvent):void 
		{
			for each(var pair:BtnPair in pairs) {
				if ( pair.btn == e.currentTarget) {
					if(pair.callback != null){
						pair.callback(e);
					}
				//	break;
				}
			}
		}
		
	}
	
}

import flash.display.Sprite;
class BtnPair {
	public var btn:Sprite;
	public var callback:Function;
	public function BtnPair(btn:Sprite, callback:Function) {
			this.btn = btn;
			this.callback = callback;
	}
}