package display 
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Some helpers for display stuff
	 * @author João Costa
	 */
	public class DisplayUtils 
	{
		
		public function DisplayUtils() 
		{
			
		}
		
		/**
		 * Adds evenely spaced objects to an objectContainer
		 * Height limit is not accounted for... I guess it would need a scroll bar for that
		 * 
		 * @param	els DisplayObjects to add, assumed to be all of same size, assumed to have its content centered...meh,easy to fix but can't be bothered now
		 * @param	container
		 * @param	displayArea
		 */
		static public function distributeElements(els:Vector.<DisplayObject>,container:DisplayObjectContainer, displayArea:Rectangle = null):void {
			if (!els.length) { return; }
			
			displayArea ||= new Rectangle(0, 0, container.width, container.height);
			var elW:int = els[0].width;
			var elH:int = els[0].height;
			var perRow:int = Math.floor( displayArea.width / elW);
			//var perColumn:int = Math.floor( displayArea.height / elH);
			
			var spacing:Number = (displayArea.width - elW*perRow)/(perRow - 1);
			var posX:int;
			for (var i:int = 0; i < els.length; i++ ) {
				
				posX = i % perRow;
				els[i].x =  posX * (elW + spacing) + (elW * .5) + displayArea.x;
				els[i].y =  Math.floor(i / perRow) * (elH + spacing) + (elH * .5) + displayArea.y;
				container.addChild(els[i]);
			}
		}
		
		/**
		 * Tries to get a child from display tree recusivelly
		 * NOTICE: WTF is wrong with flash new preloaders and TFT fields...FUUU
		 * @param	dsObject
		 * @param	childName
		 * @return
		 */
		static public function getChildByName(container:DisplayObjectContainer, childName:String):DisplayObject
		{
			 var i:int = 0;
			 var sDummyTabs:String = "";
			 var dsoChild:DisplayObject;
			 var subChild:DisplayObject;
			 
			 for (i = 0; i < container.numChildren ; ++i)
			 {
				 dsoChild = container.getChildAt(i);
				 if (container.name == childName) {
					return container; 
				 } else if (dsoChild is DisplayObjectContainer && 0 < DisplayObjectContainer(dsoChild).numChildren){
					 subChild = getChildByName(dsoChild as DisplayObjectContainer,childName);
					 if (subChild) {
						return subChild; 
					 }
				 }
			 }
			 return null;
		}
		
		/**
		 * traces displayObjectContainer tree
		 * @param	dsObject
		 * @param	iDepth
		 */
		static public function traceChildrenNames(dsObject:DisplayObjectContainer, iDepth:int = 0):void
		{
			 var i:int = 0;
			 var sDummyTabs:String = "";
			 var dsoChild:DisplayObject;

			 for (i ; i < iDepth ; i++)
				 sDummyTabs += "\t";
			
			 trace(sDummyTabs + dsObject,'name:', dsObject.name);

			 for (i = 0; i < dsObject.numChildren ; ++i)
			 {
				 dsoChild = dsObject.getChildAt(i);
				 if (dsoChild is DisplayObjectContainer && 0 < DisplayObjectContainer(dsoChild).numChildren)
					 traceChildrenNames(dsoChild as DisplayObjectContainer,++iDepth);
				 else
					 trace(sDummyTabs + "\t" + dsoChild,'name:',dsoChild.name);
			 }
		}
		
		/**
		 * Converts miliseconds to string in format mm:ss:nnnn (n for mili?!?)
		 * 
		 * @param	milis
		 * @return
		 */
		static public function milisToStr(milis:int):String {
			var seconds:int = Math.floor((milis/1000) % 60);
			var strSeconds:String = (seconds < 10) ? ("0" + String(seconds)):String(seconds);
			var minutes:int = Math.round(Math.floor(milis/60000));
			var strMinutes:String = (minutes < 10) ? ("0" + String(minutes)):String(minutes);
			var strMilliseconds:String = milis.toString();
			strMilliseconds = strMilliseconds.slice(strMilliseconds.length -3, strMilliseconds.length)
			var timeCode:String = strMinutes + ":" + strSeconds + ':' + strMilliseconds;
			return timeCode;
		}
		

	}

}