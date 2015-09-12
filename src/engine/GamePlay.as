package engine 
{
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2DebugDraw;
	import Box2D.Dynamics.b2World;
	import engine.models.Player;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author João Costa
	 */
	public class GamePlay extends Sprite 
	{
		
		public var worldBuilder:RacingWorld;
		
		public var worldSprite:Sprite;
		public var launcherContainer:Sprite = new Sprite();
		
		private var isDebugActive:Boolean = false;
		
		private var players:Vector.<Player>
		
		public function GamePlay() {
			super();
			
			launcherContainer.mouseEnabled = false;
			
		}
		
		public function loadTrack(trackSprite:Sprite, players:Vector.<Player>):void {
			this.worldSprite = trackSprite;
			this.players = players;
			
			worldBuilder = new RacingWorld();
			worldBuilder.build(trackSprite, players);
			
			addChild(trackSprite);
			addChild(launcherContainer);
			initPhysicsDebug(worldBuilder.oracleWorld);
			initPhysicsDebug(worldBuilder.world);
		}
		
		public function startGame():void {
			
			
		//	stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed_handler);
		//	stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased_handler);
			stage.addEventListener(Event.ENTER_FRAME, update, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, startLaunch);
			stage.addEventListener(MouseEvent.MOUSE_UP, endLaunch);
		}
		
		
		
		private function startLaunch(e:MouseEvent):void{
			trace('MOUSE UP');
			updateLaunch();
			addEventListener(MouseEvent.MOUSE_MOVE, updateLaunch);
		}
		
		private function endLaunch(e:MouseEvent):void {
			
			removeEventListener(MouseEvent.MOUSE_MOVE, updateLaunch);	
			
			launcherContainer.graphics.clear();//TODO proper graphics
		
			var clickedPoint:Point = new Point(worldSprite.mouseX, worldSprite.mouseY);
			
			worldBuilder.launchFrom(clickedPoint);
			
		}
		
		private function updateLaunch(e:MouseEvent=null):void {
			
			var carSprite:Sprite = worldBuilder.activeCar.carSprite;
			var carPos:Point = worldSprite.localToGlobal(new Point(carSprite.x,carSprite.y));
			var gr:Graphics = launcherContainer.graphics;
			gr.clear();
			gr.beginFill(0xff0000,0.4);
			gr.drawCircle(carPos.x, carPos.y, 10);
			gr.endFill();
			
			gr.lineStyle(3, 0xff0000, 1, true);
			gr.moveTo(carPos.x, carPos.y);
			gr.lineTo(mouseX, mouseY);
			
			var clickedPoint:Point = new Point(worldSprite.mouseX, worldSprite.mouseY);
			var predictionPath:Array = worldBuilder.predictLaunchFrom(clickedPoint);
	
			// draw prediction
			gr.lineStyle();
			for each(var p:Point in predictionPath) {
				gr.beginFill(0xff4444, 0.7);
				carPos = worldSprite.localToGlobal(p);
				gr.drawCircle(carPos.x, carPos.y, 3);
				gr.endFill();
			}
		}
		
		
		
		public function initPhysicsDebug(world:b2World):void{
			var m_sprite:Sprite;
			m_sprite = new Sprite();
			worldBuilder.worldSprite.addChild(m_sprite);
			//worldBuilder.worldSprite.alpha = 0;
			//addChild(m_sprite);
			var dbgDraw:b2DebugDraw = new b2DebugDraw();
			var dbgSprite:Sprite = new Sprite();
			m_sprite.addChild(dbgSprite);
			dbgDraw.SetSprite(m_sprite);
			dbgDraw.SetDrawScale(RacingWorld.SCALE);
			//dbgDraw.SetAlpha(1);
			dbgDraw.SetFillAlpha(0.5);
			dbgDraw.SetLineThickness(1);
			dbgDraw.SetFlags(b2DebugDraw.e_shapeBit);
			world.SetDebugDraw(dbgDraw);
			
			isDebugActive = true;
		}

		public function update(e:Event):void
		{
			//trace('update gameplay');
			worldBuilder.update();
			
			//camera
			cameraFollow(worldBuilder.activeCar.carSprite);
			
			//debug 
			if (isDebugActive) {
				worldBuilder.oracleWorld.DrawDebugData();
				worldBuilder.world.DrawDebugData();
			}
		
		}
		
		protected function cameraFollow(dispObjToFollow:DisplayObject):void{
			//TODO create a class for fancy smooth camera follow
			worldSprite.x = stage.stageWidth / 2 - dispObjToFollow.x;
			worldSprite.y = stage.stageHeight / 2 - dispObjToFollow.y;
		}
	}

}