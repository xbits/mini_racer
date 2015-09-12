package display 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	/**
	 * ...
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
		
		static public function getChildByName(dsObject:DisplayObjectContainer, childName:String):DisplayObject
		{
			 var i:int = 0;
			 var sDummyTabs:String = "";
			 var dsoChild:DisplayObject;
			 var subChild:DisplayObject;
			 
			 for (i = 0; i < dsObject.numChildren ; ++i)
			 {
				 dsoChild = dsObject.getChildAt(i);
				 if (dsObject.name == childName) {
					return dsObject; 
				 } else if (dsoChild is DisplayObjectContainer && 0 < DisplayObjectContainer(dsoChild).numChildren){
					 subChild = getChildByName(dsoChild as DisplayObjectContainer,childName);
					 if (subChild) {
						return subChild; 
					 }
				 }
			 }
			 return null;
		}
		
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
		
	}

}