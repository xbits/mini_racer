package engine 
{
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2World;
	import com.greensock.TweenLite;
	import engine.models.LaunchParams;
	import engine.models.Player;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import screens.HUD;
	import utils.CustomEvent;
	
	/**
	 * Controls the gameplay.
	 * Handles in game flow and graphics
	 * 
	 * @author João Costa
	 */
	public class GamePlay extends Sprite 
	{
		static public const EVT_GAME_OVER:String = "evtGameOver";
		static private const MAX_MOVE_TIME:int = 10000;//ten secs
		
		public var racingWorld:RacingWorld;
		private var hud:HUD;
		
		public var worldSprite:Sprite;
		
		private var players:Vector.<Player>;
		private var curPlayer:int = 0;
		private var curMoveStartTime:uint = 0;
		
		public function GamePlay(hudSprite:Sprite) {
			super();
			
			hud = new HUD(hudSprite);
			racingWorld = new RacingWorld();
		}
		
		/**
		 * Build track from source swf and prepare for new game start
		 * @param	trackSprite
		 * @param	players
		 */
		public function loadTrack(trackSprite:Sprite, players:Vector.<Player>):void {
			this.worldSprite = trackSprite;
			this.players = players;
			
			racingWorld.build(trackSprite, players);
			
			hud.loadGame(players);
			
			addChild(trackSprite);
			addChild(hud);
			
		}
		
		public function startGame():void {
			curPlayer = -1;
			hud.addEventListener(HUD.EVT_PLAYER_QUIT, onPlayerQuit);
			startNewMove();
		}
		
		/**
		 * Goes to next player. Looks for game over status.
		 */
		private function endMove():void {
			if(!players[curPlayer].finished){
				players[curPlayer].curRaceTime += getTimer() - curMoveStartTime;
			}
			
			stage.removeEventListener(Event.ENTER_FRAME, onRaceStep);
			stage.removeEventListener(Event.ENTER_FRAME, updateMoveClock);
			
			var pl:Player;
			var allFinished:Boolean = true;
			for each(pl in players) {
				allFinished &&= pl.finished;
			}
			
			if (allFinished) {
				gameOver();
			}else {
				startNewMove();
			}
			
		}
		
		private function onPlayerQuit(e:Event):void {
			players[curPlayer].finished = true;
			players[curPlayer].curRaceTime = 60 * 60 * 1000;
			players[curPlayer].disqualified = true;
			hud.updatePlayerStatus(curPlayer, players[curPlayer].curRaceTime, true,true);
			
			hud.removeEventListener(HUD.EVT_PLAYER_READY, onPlayerReady);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, startLaunch);
			removeEventListener(MouseEvent.MOUSE_MOVE, updateLaunch);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endLaunch);
			endMove();
		}
		
		private function gameOver():void {
			
			hud.removeEventListener(HUD.EVT_PLAYER_QUIT, onPlayerQuit);
			hud.unload();
			racingWorld.unload();
			
			removeChild(worldSprite);
			removeChild(hud);
			worldSprite = null;
			
			//get ordered race times
			var pl:Player;
			var times:Array = [];
			for each (pl in players) {
				times.push( pl.curRaceTime);
			}
			times.sort();
			
			//set pole positions from ordered times
			for (var i:int; i < times.length; i++) {
				for each(pl in players) {
					//make sure no pole positions r wasted on players already poled, would happen whenn several players were disqualified
					if (pl.polePosition == 0 && pl.curRaceTime == times[i]) {
						pl.polePosition = i + 1;
						break;
					}
				}
			}
			this.dispatchEvent(new CustomEvent(EVT_GAME_OVER,{players:players}));
		}
		
		
		/**
		 * Go to next player and show hud
		 */
		private function startNewMove():void 
		{
			hud.addEventListener(HUD.EVT_PLAYER_READY, onPlayerReady);
			curPlayer++;
			if (curPlayer >= players.length) { curPlayer = 0 };
			while( players[curPlayer].finished){
				curPlayer++;
				if (curPlayer >= players.length) { curPlayer = 0 };
			}
			hud.newMove(curPlayer);
			racingWorld.activePlayerIndex = curPlayer;
			
			TweenLite.to(worldSprite, 1, {x:stage.stageWidth / 2 - players[curPlayer].carSprite.x, y:stage.stageHeight / 2 - players[curPlayer].carSprite.y}); 
		}
		
		/**
		 * New move has started counting
		 * @param	e
		 */
		private function onPlayerReady(e:Event):void {
			hud.removeEventListener(HUD.EVT_PLAYER_READY, onPlayerReady);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, startLaunch);
			stage.addEventListener(Event.ENTER_FRAME, updateMoveClock);
			curMoveStartTime = getTimer();
		}
		
		private function startLaunch(e:MouseEvent):void {
			updateLaunch();
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, startLaunch);
			addEventListener(MouseEvent.MOUSE_MOVE, updateLaunch);
			stage.addEventListener(MouseEvent.MOUSE_UP, endLaunch);
		}
		
		private function endLaunch(e:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_UP, endLaunch);
			removeEventListener(MouseEvent.MOUSE_MOVE, updateLaunch);	
			
			hud.onLaunchComplete()
		
			var clickedPoint:Point = new Point(worldSprite.mouseX, worldSprite.mouseY);
			
			racingWorld.launchFrom(clickedPoint);
			stage.addEventListener(Event.ENTER_FRAME, onRaceStep);
		}
		
		private function updateLaunch(e:MouseEvent=null):void {
			
			var clickedPoint:Point = new Point(worldSprite.mouseX, worldSprite.mouseY);
			var launchParams:LaunchParams = racingWorld.predictLaunchFrom(clickedPoint);
			hud.updateLaunch(launchParams);
		}
		

		private function updateMoveClock(e:Event = null):void {
			hud.updatePlayerStatus(curPlayer, players[curPlayer].curRaceTime + getTimer() - curMoveStartTime);
		}
		
		/**
		 * called on enter frame while the cars are moving
		 * @param	e
		 */
		public function onRaceStep(e:Event):void
		{
			var allSleeping:Boolean = racingWorld.update();
			
			//camera
			cameraFollow(players[curPlayer].carSprite);
			
			//verify checkpoints crossed
			updatePlayersStatus()
			
			if (allSleeping) {
				endMove();
			}
			
		}
		
		/**
		 * Verifies if checkpoints have been reached
		 * all players must be checked in case curPlayer pushes another
		 */
		private function updatePlayersStatus():void {
			var i:int = 0;
			for each (var player:Player in players) {
				if(!player.finished){
					if(player.carSprite.hitTestObject(racingWorld.checkPoints[player.curCheckpoint])){
						player.curCheckpoint++;
						if (player.curCheckpoint == racingWorld.checkPoints.length){
							player.finished = true;
							players[curPlayer].curRaceTime += getTimer() - curMoveStartTime;
							hud.updatePlayerStatus(i,players[curPlayer].curRaceTime,true);
							if(player == players[curPlayer]){
								stage.removeEventListener(Event.ENTER_FRAME, updateMoveClock);
							}
						}
					}
				}
				i++;
			}
		}
		
		/**
		 * Follows car
		 * TODO: smooth follow
		 * @param	dispObjToFollow
		 */
		protected function cameraFollow(dispObjToFollow:DisplayObject):void{
			//TODO create a class for fancy smooth camera follow
			worldSprite.x = stage.stageWidth / 2 - dispObjToFollow.x;
			worldSprite.y = stage.stageHeight / 2 - dispObjToFollow.y;
		}
	}

}