package  
{
	import engine.GamePlay;
	import engine.models.Player;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.setTimeout;
	import screens.MenuScreen;
	import treefortress.sound.SoundAS;
	import utils.CustomEvent;
	//import engine.WorldBuilder;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	//import engine.RacerEngine;
	import br.com.stimuli.loading.BulkLoader;
	import br.com.stimuli.loading.BulkProgressEvent;
	
	/**
	 * Main class
	 * 
	 * Controls views flow and assets loading.
	 * It could maybe be split into 2 or more classes.
	 * 
	 * Splash screen and sound were an afterthought so they are not neatly placed.
	 * 
	 * TODO loader screen. Not important atm, since everything is local it wouldn't show for mora than a frame.
	 * 
	 * @author João Costa
	 */
	public class Main extends Sprite
	{
		//private var loaderScreen:Sprite; TODO
		private var splashScreen:Sprite;
		private var menuScreen:MenuScreen;//all off game views
		private var gameplay:GamePlay;
		
		private var tracksLoader:BulkLoader;//loads tracks
		private var dataLoader:BulkLoader;
		private var assetsLoader:BulkLoader;
		
		private var carsData:XML;
		private var tracksData:XML;
		
		private var players:Vector.<Player>;
		
		
		public function Main() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/**
		 * Starts loading non media data
		 * @param	e
		 */
		protected function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			loadData();
		}
		
		/**
		 * Load XML's with the available tracks and cars
		 */
		private function loadData():void {
			dataLoader = new BulkLoader("data");
			dataLoader.add("assets/data/cars.xml", { id:"cars" } );
			dataLoader.add("assets/data/tracks.xml", { id:"tracks" } );
			dataLoader.addEventListener(BulkLoader.COMPLETE, onDataLoaded);
			//TODO add some error handling
			//dataLoader.addEventListener(BulkLoader.PROGRESS, onAllProgress);
			//dataLoader.addEventListener(BulkLoader.ERROR,bulkError);
			dataLoader.start();	
		}
		
		/**
		 * Assigns data moves flow to load media assets
		 * @param	e
		 */
		private function onDataLoaded(e:Event):void {
			dataLoader.removeEventListener(BulkLoader.COMPLETE, onDataLoaded);
			carsData = dataLoader.getXML("cars");
			tracksData = dataLoader.getXML("tracks");
			
			loadAssets();
		}
		
		/**
		 * Loads media stuff, cars, interface...sound...oh fuck, havent added sound
		 */
		private function loadAssets():void {
			 var context:LoaderContext = new LoaderContext();
			context.applicationDomain = ApplicationDomain.currentDomain;
			
			assetsLoader = new BulkLoader("assets");
			assetsLoader.add("assets/splash.swf", { id:'splash', context:context } );//TODO this should be loaded b4...to tired
			
			assetsLoader.add("assets/main_menu.swf", { id:'main_menu', context:context } );
			assetsLoader.add("assets/HUD.swf", { id:'HUD', context:context } );
			
			var i:int;
			for (i = 0; i < carsData.car.length(); i++) { 
				var carName:String = carsData.car[i].swf;
				trace("loading:",carName);
				if(carName){
					assetsLoader.add("assets/cars/" + carName + ".swf", { id:carName } );
				}
			}

			for (i = 0; i < tracksData.track.length(); i++) { 
				var trackName:String = tracksData.track[i].thumb;
				trace("loading:",trackName);
				if(trackName){
					assetsLoader.add("assets/tracks/thumbs/" + trackName, { id:trackName } );
				}
			}
			
			
			assetsLoader.addEventListener(BulkLoader.COMPLETE, onAssetsLoaded);
			assetsLoader.start();
			
			loadMusic();
		}
		
		/**
		 * Loads music duh!
		 * No idea about whats going on in this SoundAS library, i'll assume it safe.
		 */
		private function loadMusic():void {
			SoundAS.loadSound("assets/sound/space.mp3", 'music', 100);
			SoundAS.playLoop('music', 0.4);
			SoundAS.fadeFrom('music', 0, 0.4,10000);	
		}

		/**
		 * Builds main views from the received assets and shows the main screen.
		 * Shows splash screen.
		 * 
		 * TODO move splash stuff further back in the flow...not sure where to put it(thats what she said! Hah!
		 * 
		 * @param	e
		 */
		private function onAssetsLoaded(e:BulkProgressEvent = null):void {
			
			assetsLoader.removeEventListener(BulkLoader.COMPLETE, onAssetsLoaded);
			var menuAsset:Sprite = assetsLoader.getContent("main_menu", true);
			
			menuScreen = new MenuScreen(menuAsset, carsData, tracksData, assetsLoader);
			gameplay = new GamePlay(assetsLoader.getSprite("HUD",true));
			
			gotoMenuScreen();
			
			var splash:MovieClip = assetsLoader.getMovieClip("splash", true);
			addChild(splash);//TODO this should be loaded b4...too tired
			splash.play();
			
		}
		
		/**
		 * Guess waht this does!?!
		 */
		private function gotoMenuScreen():void {
			menuScreen.addEventListener(MenuScreen.EVT_SELECTION_READY, onGameSelected);
			addChild(menuScreen);
		}
		
		/**
		 * Dispatched from main menu when everything is selected and ready to play
		 * @param	e
		 */
		private function onGameSelected(e:CustomEvent):void {
			menuScreen.removeEventListener(MenuScreen.EVT_SELECTION_READY, onGameSelected);
			removeChild(menuScreen);
			
			players = e.data.players;
			loadTrack(e.data.track, players);
		}
		
		/**
		 * start loading the track swf
		 * @param	track track data description
		 * @param	players
		 */
		private function loadTrack(track:XML, players:Vector.<Player>):void{
			tracksLoader = new BulkLoader("gameplay");
			var trackName:String = track.swf;
			tracksLoader.add("assets/tracks/" + trackName + ".swf", {id:"gamesprite"});

			tracksLoader.addEventListener(BulkLoader.COMPLETE, onGameplayLoaded);
			//gamePlayLoader.addEventListener(BulkLoader.PROGRESS, onAllProgress);
			//gamePlayLoader.addEventListener(BulkLoader.ERROR,bulkError);
			tracksLoader.start();

		}
		
		/**
		 * Called when track.swf is loaded
		 * @param	e
		 */
		private function onGameplayLoaded(e:BulkProgressEvent):void {

			tracksLoader.removeEventListener(BulkLoader.COMPLETE, onGameplayLoaded);
			
			var trackSprite:Sprite = tracksLoader.getContent("gamesprite", true);
			tracksLoader.clear();
			
			gameplay.loadTrack(trackSprite,players);
			
			addChild(gameplay);
			gameplay.addEventListener(GamePlay.EVT_GAME_OVER, onGameOver);
			gameplay.startGame();

		}
		
		/**
		 * Listens to game over event from gameplay, 
		 * @param	e CustomEvent holds the game results data
		 */
		private function onGameOver(e:CustomEvent):void {
			tracksLoader.removeEventListener(GamePlay.EVT_GAME_OVER, onGameOver);
			
			removeChild(gameplay);
			
			gotoMenuScreen();
			var players:Vector.<Player> = e.data.players;
			menuScreen.showGameOver(players);
		}
		
	}

}