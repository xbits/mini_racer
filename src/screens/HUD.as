package screens 
{
	import com.greensock.easing.BounceOut;
	import com.greensock.easing.ElasticOut;
	import com.greensock.TweenLite;
	import display.DisplayUtils;
	import display.TextAnimations;
	import engine.models.LaunchParams;
	import engine.models.Player;
	import engine.RacingWorld;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;
	import utils.CustomEvent;
	
	/**
	 * HUD that shows in race stuff
	 * 
	 * @author João Costa
	 */
	public class HUD extends Sprite 
	{
		static public const EVT_PLAYER_READY:String = "evtPlayerReady";//Dispatched on every turn after car launcher is shown.
		static public const EVT_PLAYER_QUIT:String = "evtPlayerQuit";
		
		private static const NUMBERS_TO_STR:Vector.<String> = Vector.<String>(['One', 'Two', 'Three', 'Four']);
		
		private var PlayerPanel:Class;
		
		private var asset:Sprite;
		
		//interface elements recurently used in display
		private var playerPanels:Array;
		private var activeSign:MovieClip;
		private var infoTxt:TextField;
		private var meter:Sprite;//car launch meter
		private var gauge:Sprite;//the colored bar inside the launch meter to fill up with launch strangth
		private var readyBtn:Sprite;
		private var quitBtn:Sprite;
		private var overCarContainer:Sprite;//holds the car launcher graphics
		
		private var carGhost:Sprite;//active car ghost, unused...TODO
		
		
		
		/**
		 * Constructor
		 * Extracts references to DisplayObjects and Classes from the loaded hudAsset
		 * 
		 * @param	hudAsset swf with the graphics
		 */
		public function HUD(hudAsset:Sprite) 
		{
			super();
			asset = hudAsset;
			
			meter = DisplayUtils.getChildByName(hudAsset, 'meter') as Sprite;
			gauge = DisplayUtils.getChildByName(hudAsset, 'gauge') as Sprite ;
			infoTxt = hudAsset.getChildByName( 'infoTxt') as TextField;
			activeSign = hudAsset.getChildByName( 'activeSign') as MovieClip;
			readyBtn = hudAsset.getChildByName( 'readyBtn') as Sprite;
			quitBtn = hudAsset.getChildByName('quitBtn') as Sprite;
		
			PlayerPanel = getDefinitionByName("ext.hud.PlayerPanel") as Class;
			
			overCarContainer = new Sprite;
			overCarContainer.addChild(meter);
			overCarContainer.mouseEnabled = false;
			
			addChild(hudAsset);
		}
		
		/**
		 * Build player panels and stuff and prepares for game start.
		 * @param	players
		 */
		public function loadGame(players:Vector.<Player>):void {
			
			playerPanels = [];
			for (var i:int = 0; i < players.length; i++) {
				var pl:Player = players[i];
				var plPanel:Sprite = new PlayerPanel() as Sprite;
				plPanel.x = plPanel.width * .5 + 5;
				plPanel.y = (plPanel.height + 10) * i +plPanel.height*.5 + 5;
				addChild(plPanel);
				TextField(plPanel.getChildByName('titleTxt')).text = 'Player ' + NUMBERS_TO_STR[i];
				TextField(plPanel.getChildByName('timeTxt')).text = DisplayUtils.milisToStr(0);
				var finishedTxt:TextField = TextField(plPanel.getChildByName('finishTxt'));
				finishedTxt.visible = false;
				
				playerPanels.push(plPanel);
			}
			quitBtn.addEventListener(MouseEvent.CLICK, onQuitClick);
		}
		
		/**
		 * Player clicked quit button
		 * @param	e
		 */
		private function onQuitClick(e:MouseEvent):void {
			dispatchEvent(new Event(EVT_PLAYER_QUIT));
		}
		
		/**
		 * Prepare for garbage collection.
		 * Likely missing something...possibly un-needed
		 */
		public function unload():void {
			hideOverCar();
			hideReadyScreen();
			for each(var pp:Sprite in playerPanels) {
				pp.parent.removeChild(pp);
			}
			playerPanels = null;
			quitBtn.removeEventListener(MouseEvent.CLICK, onQuitClick);
		}
		
		/**
		 * Shows the car launcher and hides uneeded stuff 
		 * @param	playerNum
		 */
		public function newMove(playerNum:int):void {
			hideOverCar();
			showReadyScreen();
			infoTxt.text = 'Player ' + NUMBERS_TO_STR[playerNum] + "\nready?";
			
			activeSign.x = playerPanels[playerNum].x + playerPanels[playerNum].width * .5;
			activeSign.y = playerPanels[playerNum].y;
			activeSign.play();
		}
		
		/**
		 * Update player info panel
		 * @param	playerNum
		 * @param	time
		 * @param	finished
		 * @param	disqualified
		 */
		public function updatePlayerStatus(playerNum:int, time:int, finished:Boolean = false,disqualified:Boolean = false):void {
			TextField(playerPanels[playerNum].getChildByName('timeTxt')).text = DisplayUtils.milisToStr(time);
			if (finished) {
				//TextField(playerPanels[playerNum].getChildByName('timeTxt')).text =
				var finishedTxt:TextField = TextField(playerPanels[playerNum].getChildByName('finishTxt'));
				finishedTxt.visible = true;
				TweenLite.fromTo(finishedTxt, 1, { scaleX: 0, scaleY:0 }, { scaleX:1.1, scaleY:1.1, ease:BounceOut.ease } );
				if (disqualified) {
						TextField(playerPanels[playerNum].getChildByName('timeTxt')).text = 'disqualified!'
				}
			}
		}
		
		/**
		 * Update car launcher display
		 * @param	launchParams
		 */
		public function updateLaunch(launchParams:LaunchParams ):void {
			if (!overCarContainer.stage) {
				carGhost = launchParams.player.carGhost;
				overCarContainer.addChildAt(carGhost,0);
				showOverCar() 
			};
			
			meter.x = launchParams.carPos.x;
			meter.y = launchParams.carPos.y;

			meter.rotation = launchParams.angle / (Math.PI / 180);
			gauge.graphics.clear();
			gauge.graphics.beginFill(0xFF1123);
			gauge.graphics.drawRect( -gauge.width * .5,
									0,
									gauge.width,
									(RacingWorld.MAX_LAUNCH_DIST ) * launchParams.strength);
			gauge.graphics.endFill();
			
			
			var gr:Graphics = overCarContainer.graphics;
			gr.clear();
			// draw path prediction
			gr.lineStyle();
			for each(var p:Point in launchParams.projectedPath) {
				gr.beginFill(0xff4444, 0.7);
				gr.drawCircle(p.x, p.y, 3);
				gr.endFill();
			}
			
			//TODO draw ghost...
			//carGhost.x = launchParams.projectedCarPos.x;
			//carGhost.y = launchParams.projectedCarPos.y;
			//carGhost.rotation = launchParams.projectedCarRotation;
		}
		
		public function onLaunchComplete():void {
			overCarContainer.graphics.clear();
			hideOverCar();
		}
		
		private function onReadyClick(e:MouseEvent):void {
			hideReadyScreen();
			dispatchEvent(new CustomEvent(EVT_PLAYER_READY,null));
		}
		
		public function showOverCar():void {
			hideReadyScreen();
			addChild(overCarContainer);
		}
		
		public function hideOverCar():void {
			if(overCarContainer.parent){
				removeChild(overCarContainer);
				if (carGhost) {
					if (carGhost.parent) { carGhost.parent.removeChild(carGhost); }
					carGhost = null;
				}
			}
		}
		
		public function showReadyScreen():void {
			addChild(infoTxt);
			addChild(readyBtn);
			TweenLite.fromTo(infoTxt,1, { y: -300 }, { y:85 } );
			TweenLite.fromTo(readyBtn,1, { scaleX: 0,scaleY:0 }, { scaleX:1,scaleY:1,ease:ElasticOut.ease } );
			if (!readyBtn.hasEventListener(MouseEvent.CLICK)) {
				readyBtn.addEventListener(MouseEvent.CLICK, onReadyClick);
			}
		}
		
		public function hideReadyScreen():void {
			hideOverCar();
			if(infoTxt.parent){
				infoTxt.parent.removeChild(infoTxt);
				readyBtn.parent.removeChild(readyBtn);
				if (readyBtn.hasEventListener(MouseEvent.CLICK)) {
					readyBtn.removeEventListener(MouseEvent.CLICK, onReadyClick);
				}
			}
		}
		
	}

}