package screens 
{
	import br.com.stimuli.loading.BulkLoader;
	import display.Butonizer;
	import display.DisplayUtils;
	import engine.models.CarParams;
	import engine.models.Player;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.ShaderParameter;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;
	import utils.CustomEvent;

	/**
	 * ...
	 * @author João Costa
	 */
	public class MenuScreen extends Sprite
	{
		static public const EVT_SELECTION_READY:String = "evtSelectionReady";
		
		//classes
		private var SelectionScreen:Class;
		private var CarBtn:Class;
		private var TrackBtn:Class;
		
		private var assetMC:Sprite;
		private var carsData:XML;
		private var tracksData:XML;
		private var imagesLoader:BulkLoader;
		
		private var players:Vector.<Player>;
		private var numPlayers:int = 0;
		private var curPlayerPick:int = 0;
		
		private var selectionScreen:Sprite;
		
		public function MenuScreen(assetMC:Sprite,carsData:XML, tracksData:XML,imgsLoader:BulkLoader) {
			super();
			this.assetMC = assetMC;
			this.carsData = carsData;
			this.tracksData = tracksData;
			this.imagesLoader = imgsLoader;
			
			addChild(assetMC);
			SelectionScreen = getDefinitionByName("ext.menu.SelectionScreen") as Class;
			CarBtn = getDefinitionByName("ext.menu.CarBtn") as Class;
			TrackBtn = getDefinitionByName("ext.menu.TrackBtn") as Class;
			
			selectionScreen = new SelectionScreen() as Sprite;
			
	
			var btn:Sprite;
			for (var i:int; i < 4; i++) {
				btn = Sprite(DisplayUtils.getChildByName( assetMC, 'playBtn' + (i + 1)));
				Butonizer.getInstance().makeBtn(btn , onNumPlayersPick);
			}
			//Butonizer.getInstance().makeBtn(DisplayUtils.getChildByName(assetMC, 'megaLogo') as Sprite);
		}
		
		
		
		private function onNumPlayersPick(e:MouseEvent):void {
			players = new Vector.<Player>;
			
			numPlayers = parseInt(e.currentTarget.name.replace('playBtn',''));
			trace("PLAYERS SELECTED:", numPlayers, e.currentTarget.name);
			curPlayerPick = 0;
			
			showCarSelectionScreen();
			
		}
		
		private function showCarSelectionScreen(refill:Boolean = true):void {
			TextField(selectionScreen.getChildByName('titleTxt')).text = "Player "+ (curPlayerPick + 1)+" select your car!";
			if (!refill) {
				return;
			}
			clearSelectionScreen()
			this.addChild(selectionScreen);
			
			//build car btns 
			var carBtns:Vector.<DisplayObject> = new Vector.<DisplayObject>;
			var carBtn:MovieClip;
			var carInfo:TextField;
			var i:int = 0;
			for each (var car:XML in carsData.car) {
				
				carBtn = new CarBtn() as MovieClip;
				carBtns.push(carBtn);
				
				var carMC:MovieClip = imagesLoader.getMovieClip(car.swf);
				carMC.y = - carBtn.height * .26;
				carMC.scaleX = carMC.scaleY = 1.7;
				carBtn.addChild(carMC);
				carBtn.name = 'btn' + i;
				carBtn.id = i;
				
				carInfo = TextField(carBtn.getChildByName('infoTxt'));
				carInfo.mouseEnabled = false;
				carInfo.text = car.swf + "\npower: " + car.horsepower+ "\nstability: " + car.stability;
				
				Butonizer.getInstance().makeBtn(carBtn, onCarSelected);
				
				i++;
			}
			DisplayUtils.distributeElements(carBtns,
											selectionScreen,
											new Rectangle(selectionScreen.width * .11,
											68,
											selectionScreen.width * (1 - 0.22),
											selectionScreen.height));
		}
		
		
		private function onCarSelected(e:MouseEvent):void {
			var curTarget:* = e.currentTarget;
			curTarget.visible = false;
			
			var carData:XML = carsData.car[e.currentTarget.id];
			var carParam:CarParams = new CarParams(carData);
			var player:Player = new Player(imagesLoader.getMovieClip(carData.swf), carParam);
			players.push(player);
			
			curPlayerPick++;
			
			if(curPlayerPick < numPlayers){
				showCarSelectionScreen(false);
			}else {
				showTrackSelectionScreen();
			}
		}
		
		private function showTrackSelectionScreen():void {
			TextField(selectionScreen.getChildByName('titleTxt')).text = "Select Track!";
			clearSelectionScreen()
			this.addChild(selectionScreen);
			
			//build track btns 
			var trackBtns:Vector.<DisplayObject> = new Vector.<DisplayObject>;
			var trackBtn:MovieClip;
			var trackInfo:TextField;
			var i:int = 0;
			for each (var track:XML in tracksData.track) {
				
				trackBtn = new TrackBtn() as MovieClip;
				trackBtns.push(trackBtn);
				var trackThumb:Bitmap = imagesLoader.getBitmap(track.thumb);
				trackThumb.scaleX = trackThumb.scaleY = Math.min((trackBtn.width*.9)/trackThumb.width,(trackBtn.height*.45)/trackThumb.height)
				trackThumb.y = - trackBtn.height * .20 - trackThumb.height*.5;
				trackThumb.x = - trackThumb.width*.5;
				trackBtn.addChild(trackThumb);
				trackBtn.name = 'btn' + i;
				trackBtn.id = i;
				
				trackInfo = TextField(trackBtn.getChildByName('infoTxt'));
				trackInfo.mouseEnabled = false;
				trackInfo .text = track.name + "\nsize: "+track.size;
	
				Butonizer.getInstance().makeBtn(trackBtn, onTrackSelected);
				
				i++;
			}
			DisplayUtils.distributeElements(trackBtns,
											selectionScreen,
											new Rectangle(selectionScreen.width * .09,
											120,
											selectionScreen.width * (1 - 0.18),
											selectionScreen.height));
		}
		
		private function onTrackSelected(e:Event):void {
			var trackID:int = e.currentTarget.name.replace('trackBtn', '');
			var selectedTrack:XML = tracksData.track[trackID];
			clearSelectionScreen();
			
			dispatchEvent(new CustomEvent(EVT_SELECTION_READY, { track:selectedTrack, players:players } ));
		}
		
		private function clearSelectionScreen():void {
			var btn:MovieClip;
			var i:int = 0;
			while (btn = MovieClip(selectionScreen.getChildByName('btn' + i))) {
				selectionScreen.removeChild(btn);
				Butonizer.getInstance().unmakeBtn(btn);
				i++;
			}
		}
		
		
	}

}