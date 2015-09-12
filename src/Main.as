package  
{
	import engine.GamePlay;
	import engine.models.Player;
	import flash.display.DisplayObject;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.setTimeout;
	import screens.MenuScreen;
	import utils.CustomEvent;
	//import engine.WorldBuilder;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	//import engine.RacerEngine;
	import br.com.stimuli.loading.BulkLoader;
	import br.com.stimuli.loading.BulkProgressEvent;
	
	/**
	 * ...
	 * @author João Costa
	 */
	public class Main extends Sprite
	{
		private var loaderScreen:Sprite;
		private var splashScreen:Sprite;
		private var menuScreen:MenuScreen;
		private var resultsScreen:Sprite;
		private var gameplay:GamePlay;
		
		private var gamePlayLoader:BulkLoader;
		private var dataLoader:BulkLoader;
		private var assetsLoader:BulkLoader;
		
		private var carsData:XML;
		private var tracksData:XML;
		
		private var players:Vector.<Player>;
		
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			trace('main');
		}
		
		protected function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			loadData();
			
		}
		
		private function loadData():void {
			dataLoader = new BulkLoader("data");
			dataLoader.add("assets/data/cars.xml", { id:"cars" } );
			dataLoader.add("assets/data/tracks.xml", { id:"tracks" } );
			dataLoader.addEventListener(BulkLoader.COMPLETE, onDataLoaded);
			//dataLoader.addEventListener(BulkLoader.PROGRESS, onAllProgress);
			//dataLoader.addEventListener(BulkLoader.ERROR,bulkError);
			dataLoader.start();	
		}
		
		private function onDataLoaded(e:Event):void {
			dataLoader.removeEventListener(BulkLoader.COMPLETE, onDataLoaded);
			carsData = dataLoader.getXML("cars");
			tracksData = dataLoader.getXML("tracks");
			
			loadAssets();
		}
		
		private function loadAssets():void {
			 var context:LoaderContext = new LoaderContext();
			context.applicationDomain = ApplicationDomain.currentDomain;
			
			assetsLoader = new BulkLoader("assets");
			assetsLoader.add("assets/main_menu.swf", { id:'main_menu',context:context } );
			var i:int;
			for (i = 0; i < carsData.car.length(); i++) { 
				var carName:String = carsData.car[i].swf;
				trace("loading:",carName);
				if(carName){
					assetsLoader.add("assets/cars/" + carName + ".swf", { id:carName } );
				}
			}
			trace(tracksData.track);
			for (i = 0; i < tracksData.track.length(); i++) { 
				var trackName:String = tracksData.track[i].thumb;
				trace("loading:",trackName);
				if(trackName){
					assetsLoader.add("assets/tracks/thumbs/" + trackName, { id:trackName } );
				}
			}
			
			
			assetsLoader.addEventListener(BulkLoader.COMPLETE, onAssetsLoaded);
			assetsLoader.start();	
		}


		private function onAssetsLoaded(e:BulkProgressEvent = null):void {
	
			var menuAsset:Sprite = assetsLoader.getContent("main_menu", true);
			assetsLoader.removeEventListener(BulkLoader.COMPLETE, onAssetsLoaded);
			menuScreen = new MenuScreen(menuAsset,carsData,tracksData,assetsLoader);
			gotoMenuScreen();
			
		}
		
		private function gotoMenuScreen():void {
			menuScreen.addEventListener(MenuScreen.EVT_SELECTION_READY, onGameSelected);
			addChild(menuScreen);
		}
		
		private function onGameSelected(e:CustomEvent):void {
			removeChild(menuScreen);
			players = e.data.players;
			loadTrack(e.data.track, players);
		}
		
		private function loadTrack(track:XML, players:Vector.<Player>):void{
			//----ALL VALUES HAVE BEEN READ--------------------
			gamePlayLoader = new BulkLoader("gameplay");
			var trackName:String = track.swf;
			gamePlayLoader.add("assets/tracks/" + trackName + ".swf", {id:"gamesprite"});

			gamePlayLoader.addEventListener(BulkLoader.COMPLETE, onGameplayLoaded);
			//gamePlayLoader.addEventListener(BulkLoader.PROGRESS, onAllProgress);
			//gamePlayLoader.addEventListener(BulkLoader.ERROR,bulkError);
			gamePlayLoader.start();

		}
		private function onGameplayLoaded(e:BulkProgressEvent):void {

			gamePlayLoader.removeEventListener(BulkLoader.COMPLETE, onGameplayLoaded);
			var trackSprite:Sprite = gamePlayLoader.getContent("gamesprite",true);
			gameplay = new GamePlay();
			trace(carsData.car.(attribute('default') == true))
		//	var car1:Sprite = assetsLoader.getSprite(carsData.car.(attribute('default') == true).swf);
		//	var car2:DisplayObject = assetsLoader.getSprite(carsData.cars[0]);
		//	var player1:Player = new Player(car1);
			
			gameplay.loadTrack(trackSprite,players);
			
			addChild(gameplay);
			gameplay.startGame();

		}
		
	}

}