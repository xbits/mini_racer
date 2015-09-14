package utils 
{
	import flash.events.Event;
	/**
	 * Standard event extension to hold some extra data
	 * @author João Costa
	 */
	public class CustomEvent extends Event
	{
		
		public var data:Object;
	
		public function CustomEvent(type:String, data:Object = null, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
			this.data = data;
		}

		public override function clone():Event{
			return new CustomEvent(type, data, bubbles, cancelable);
		}
	
	}

}
