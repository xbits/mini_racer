package utils 
{
	import flash.events.Event;
	/**
	 * ...
	 * @author João Costa
	 */
	public class CustomEvent extends Event
	{
		
		// this is the object you want to pass through your event.
		public var data:Object;
	
		public function CustomEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}

		// always create a clone() method for events in case you want to redispatch them.
		public override function clone():Event
		{
			return new CustomEvent(type, data, bubbles, cancelable);
		}
	
	}

}
