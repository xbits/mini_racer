package screens 
{
	import br.com.stimuli.loading.BulkLoader;
	import com.greensock.TweenLite;
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
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.utils.getDefinitionByName;
	import treefortress.sound.SoundAS;
	import utils.CustomEvent;

	/**
	 * This class controls the displays and event flow of all off game views except for the splash screen.
	 * Not a brilliant set up, but couldn't be bothered to further break it down.
	 * The selection panel is instanced, the main menu and are permanent.
	 * 
	 * 
	 * @author João Costa
	 */
	public class MenuScreen extends Sprite
	{
		static public const EVT_SELECTION_READY:String = "evtSelectionReady";
		
		static private const CARDINALS:Vector.<String> = Vector.<String>(['1st','2nd','3rd','4th'])
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
		private var gameOverScreen:Sprite;
		private var soundBtn:Sprite;
		
		/**
		 * Constructor extracts the needed asses from the loaded swf and inits some buttons. 
		 * Not that many btns and events so I found no need to improve memory management.
		 * 
		 * @param	assetMC
		 * @param	carsData
		 * @param	tracksData
		 * @param	imgsLoader
		 */
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

			gameOverScreen = Sprite(DisplayUtils.getChildByName(assetMC,'gameOverScreen'));
			
			gameOverScreen.parent.removeChild(gameOverScreen);
			
			var btn:Sprite;
			for (var i:int; i < 4; i++) {
				btn = Sprite(DisplayUtils.getChildByName( assetMC, 'playBtn' + (i + 1)));
				Butonizer.getInstance().makeBtn(btn , onNumPlayersPick);
			}
			DisplayUtils.traceChildrenNames(assetMC);
			soundBtn = DisplayUtils.getChildByName(assetMC, 'soundBtn') as Sprite;
			soundBtn.addEventListener(MouseEvent.CLICK, toggleSound);
			
			//Butonizer.getInstance().makeBtn(DisplayUtils.getChildByName(assetMC, 'megaLogo') as Sprite);
		}
		
		/**
		 * Soudn on/off
		 * @param	e
		 */
		private function toggleSound(e:MouseEvent):void {
				SoundAS.mute = !SoundAS.mute;
				soundBtn.getChildByName('soundOn').visible = !SoundAS.mute;
		}
		/**
		 * builds game over from players data and adds it to display
		 * @param	players
		 */
		public function showGameOver(players:Vector.<Player>):void 
		{
			var poleTxt:TextField;
			for (var i: int = 0; i < players.length; i++){
				poleTxt = TextField(gameOverScreen.getChildByName('pole' + players[i].polePosition));
				poleTxt.text = CARDINALS[i] + " : player " + (i + 1) + ' time : ';
				if (players[i].disqualified) {
					poleTxt.text += 'disqulified!';
				}else {
					poleTxt.text += DisplayUtils.milisToStr(players[i].curRaceTime);
				}
			}
			while (i < 4) {
				i++;
				poleTxt = TextField(gameOverScreen.getChildByName('pole' + i));
				poleTxt.text = '';	
			}
			addChild(gameOverScreen);
			TweenLite.fromTo(gameOverScreen, 1, { y: -gameOverScreen.height }, { y:0 } );
			addEventListener(MouseEvent.CLICK, hideGameOver);
		}
		
		private function hideGameOver(e:MouseEvent):void {
			removeEventListener(MouseEvent.CLICK, hideGameOver);
			removeChild(gameOverScreen)
		}
		
		/**
		 * 
		 * @param	e
		 */
		private function onNumPlayersPick(e:MouseEvent):void {
			if (gameOverScreen.parent) { return; }//lazy mouse input blocker...too tired
			players = new Vector.<Player>;
			numPlayers = parseInt(e.currentTarget.name.replace('playBtn',''));
			curPlayerPick = 0;
			
			showCarSelectionScreen();
			
		}
		
		/**
		 * Builds car selection menu from cars XML and loaded graphical assets
		 * @param	refill
		 */
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
				carMC.rotation = 0; 
				carMC.scaleX = carMC.scaleY = 1; 
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
		
		/**
		 * Moves flow to either select next player car or select track
		 * @param	e
		 */
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
		
		/**
		 * Same as cars but for tracks
		 */
		private function showTrackSelectionScreen():void {
			TextField(selectionScreen.getChildByName('titleTxt')).text = "Select Track!";
			clearSelectionScreen();
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
				trackThumb.rotation = 0;
				trackThumb.scaleX = trackThumb.scaleY = 1;
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
		
		/**
		 * 
		 * @param	e MouseEvent
		 */
		private function onTrackSelected(e:Event):void {
			var trackID:int = parseInt(e.currentTarget.name.replace('btn', ''));
			var selectedTrack:XML = tracksData.track[trackID];
			clearSelectionScreen();
			removeChild(selectionScreen);
			
			dispatchEvent(new CustomEvent(EVT_SELECTION_READY, { track:selectedTrack, players:players } ));
		}
		
		/**
		 * Removes selection screen buttons and events
		 */
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