package engine 
{
	import Box2D.Collision.*; // bounding box of our world
	import Box2D.Common.Math.*; // for vector(define gravity)
	import Box2D.Dynamics.*; // define bodies and define world
	import Box2D.Dynamics.Joints.*;
	import Box2D.Collision.Shapes.*; // define our shapes
	import engine.models.CarParams;
	import engine.models.LaunchParams;
	import engine.models.Player;
	import engine.physics.PlayableCar;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flash.display.Sprite;
	
	/**
	 * Controls the track and physics 
	 * Bridges between gameplay and physics worlds
	 * 
	 * @author João Costa
	 */
	public class RacingWorld 
	{
		public static const EVT_UPDATE:String = 'worldUpdate';
		public static const CAR_INSTANCE_NAME:String = "playerCar";//TODO this is for one player only
		public static const SCALE:Number = 10;
		static private const ORACLE_DEPTH:uint = 8;
		
		public static const MIN_LAUNCH_DIST:Number = 8.5;//this is dependent on the launcher drawing...should be set dynamically and somewhere else...
		public static const MAX_LAUNCH_DIST:Number = 158;//Idem
		
		
		public var world:b2World;
		public var oracleWorld:b2World;
	
		public var worldSprite:Sprite;
		private var projectionSprite:Sprite;//oracle debug container currently used for launcher display...to be removed 
		
		private var cars:Vector.<PlayableCar>;
		private var oracleCars:Vector.<PlayableCar>;
		private var players:Vector.<Player>;
		public var activePlayerIndex:int;
		
		public var checkPoints:Array;//
		
		
		public function RacingWorld() {

		}
		/**
		 * Build launch params and cycles the oracle world for a path prediction 
		 * @param	fromPoint
		 * @return LaunchParams
		 */
		public function predictLaunchFrom(fromPoint:Point):LaunchParams {
			
			var oracleCar:PlayableCar = activeOracleCar;
			var car:PlayableCar = activeCar;
			//---reset oracle and set its positions
			hideOracles();//hack to show prediction with the box2d debug draw...TODO replace with proper ghost
			oracleCar.imitateStatus(car);
			
			var launchP:LaunchParams = new LaunchParams(players[activePlayerIndex], fromPoint, SCALE);
			oracleCar.launchFrom(launchP);
			
			var curPos:b2Vec2;
			oracleWorld.ClearForces();
			while(oracleCar.body.IsAwake() && launchP.projectedPath.length < ORACLE_DEPTH){
				oracleWorld.Step(1 /30, 8, 8);
				oracleWorld.ClearForces();
				oracleCar.onWorldUpdate();
				curPos = oracleCar.body.GetPosition();
				//launchP.addPathPoint(curPos.x - worldSprite.x , curPos.y-worldSprite.y);
				launchP.projectedPath.push(worldSprite.localToGlobal(new Point(curPos.x*SCALE , curPos.y*SCALE)));
			}
			
			oracleWorld.DrawDebugData();
			world.DrawDebugData();//validation of active is inside
			
			//TODO draw ghost stuff
		//	launchP.projectedCarPos = new Point(curPos.x * SCALE, curPos.y * SCALE);
		//	launchP.projectedCarRotation = oracleCar.body.GetAngle() / (Math.PI / 180);
		//	launchP.projectedWheelsAngle = oracleCar.frontWheel.GetAngle() / (Math.PI / 180) - launchP.projectedCarRotation;
				
			return launchP;
		}
		
		/**
		 * Launch the active car
		 * @param	fromPoint
		 */
		public function launchFrom(fromPoint:Point ):void {
			projectionSprite.graphics.clear()//TODO replace this hack with proper ghost
			var car:PlayableCar = activeCar;
			var launchP:LaunchParams = new LaunchParams(players[activePlayerIndex], fromPoint, SCALE);
			car.launchFrom(launchP);
		}
		/**
		 * Physics step
		 * @return
		 */
		public function update():Boolean {
			world.Step(1 / 30, 8, 8);
			world.ClearForces();
			//world.DrawDebugData();
			
			var curCar:PlayableCar;
			for (var i:int = 0; i < cars.length; i++) {
				curCar = cars[i];
				curCar.onWorldUpdate();
			}
			var body:b2Body = world.GetBodyList();
			var userData:Object;
			var allSleeping:Boolean = false;
			var maxAngularVel:Number = 0;
			var maxVel:Number = 0;
			//update all displayObjects with the position from physics world
			while (body) {
				userData = body.GetUserData();
				if (userData && userData.sprite) {
					userData.sprite.x = body.GetPosition().x * SCALE;
					userData.sprite.y = body.GetPosition().y * SCALE;
					userData.sprite.rotation = body.GetAngle() * (180 / Math.PI) ;
					
					if (body.IsAwake()) {
						maxAngularVel = Math.max(maxAngularVel, body.GetAngularVelocity());
						maxVel = Math.max(maxVel, body.GetLinearVelocity().Copy().Length());
					}
				}
				body = body.GetNext();
			}
			
			allSleeping = maxAngularVel < 0.05 && maxVel < 0.4;
			
			return allSleeping;
		}
		
		public function get activeCar():PlayableCar {
			return cars[activePlayerIndex];
		}
		public function get activeOracleCar():PlayableCar {
			return oracleCars[activePlayerIndex];
		}
		
		/**
		 * Helper for hack to show box2d debug for path prediction. 
		 * Can be removed when proper ghosts are added
		 */
		private function hideOracles():void {
			for each(var oracle:PlayableCar in oracleCars) {
				if(activeOracleCar != oracle){
					oracle.body.SetPosition(new b2Vec2( -5000, -5000));
				}
			}
		}
		
		/**
		 * prepare for GC un-needed...i think...a simples racingWorld = null; at the right loaction will do
		 */
		public function unload():void {
			players = null;
			worldSprite = null;
			checkPoints = null;
			projectionSprite = null;
			world = null;
			oracleWorld = null;
			cars = null;
			oracleCars = null;
		}
		
		//-------------track building stuff....could maybe go to another class-----------------------------
		//---------------------------------------------------------------------------------------------
		
		/**
		 * Builds the physical and logical world from a custom formated track swf
		 * @param	sourceTrack
		 * @param	players
		 */
		public function build(sourceTrack:Sprite,players:Vector.<Player>):void {
			this.players = players;
			this.worldSprite = sourceTrack;
			this.checkPoints = [];
			
			cars = new Vector.<PlayableCar>();
			oracleCars = new Vector.<PlayableCar>();
			
			world = new b2World(new b2Vec2(0, 0.0), true);
			oracleWorld = new b2World(new b2Vec2(0, 0.0), true);
			
			projectionSprite = initWorldDebug(oracleWorld);//leave this on  to show ghost
			
			var dispObj:DisplayObject
			var carIndex:int;
			var i:int;
			for (i = 0; i < worldSprite.numChildren; i++ ) {
				dispObj = worldSprite.getChildAt(i);
				
			}
			
			var boundingRec:Rectangle;
			var boxShape:b2PolygonShape = new b2PolygonShape();//boxDef factory-ish for use in all boxes def
			var fixtureDef:b2FixtureDef = new b2FixtureDef();//fixture factory-ish
			var circleShape:b2CircleShape;
			var body:b2Body;
			var bodyDef:b2BodyDef;
			
			var garbageFromBullet:Array = [];
			
			//This could use some factory class instead...to reduce method size
			for (i = 0; i < worldSprite.numChildren; i++ ) {
				
				dispObj = worldSprite.getChildAt(i);
				
				if (dispObj.name== CAR_INSTANCE_NAME){
					buildCars(dispObj);
				}else if (dispObj.name.search("CP")==0){
					checkPoints.push(dispObj)
					trace("TrackBuilder-- Found checkpoint :", dispObj.name)
				}else if (dispObj.name.search("FINISH")==0){
					checkPoints.push(dispObj)
					trace("TrackBuilder-- Found finish :", dispObj.name)
				}else if (dispObj.name == "moneyBox") {
					trace("TrackBuilder-- Found money box :", dispObj.name)
					//	moneyInstance.moneyBox = childObj;
						dispObj.visible=false;
					//moneyInstance.moneyBox.visible = false;
				}else if (dispObj.name == "SBmoney") {
					trace("TrackBuilder-- Found money drawing :", dispObj.name)
					//	moneyInstance.moneyMovie = childObj;
					MovieClip(dispObj).gotoAndStop(1)
				}else if (dispObj.name == "moneyArea") {
					trace("TrackBuilder-- Found money Area:", dispObj.name)
					//	moneyInstance.moneyArea = childObj;
				}else if (dispObj.name.search("SB") == 0) {
					trace("TrackBuilder-- Found static circle :", dispObj.name)
					
					boundingRec = getAlignedRect(dispObj);
					
					bodyDef = new b2BodyDef();
					//bodyDef.userData = { sprite: dispObj };
					bodyDef.position.Set(dispObj.x/SCALE, dispObj.y/SCALE);
					
					boxShape.SetAsBox(boundingRec.width/SCALE * .5,boundingRec.height/SCALE * .5);
					fixtureDef.shape = boxShape;
					fixtureDef.friction = 0.8;
					fixtureDef.restitution = 0.3;
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);// + Math.PI * .5;
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);

				}else if (dispObj.name.search("DB") == 0 ||  (dispObj.name.search("TRcar") == 0) ) {//set moving traffic from bullet drive as dumb boxes
					trace("TrackBuilder-- Found dynamic box :", dispObj.name)
					
					boundingRec = getAlignedRect(dispObj);
					
					bodyDef = new b2BodyDef();
					bodyDef.userData = { sprite: dispObj };
					bodyDef.linearDamping = 0.99;
					bodyDef.angularDamping = 0.9;
					bodyDef.position.Set(dispObj.x/SCALE, dispObj.y/SCALE);
					bodyDef.allowSleep = true;
					bodyDef.type = b2Body.b2_dynamicBody;
					
					boxShape.SetAsBox(boundingRec.width/SCALE * .5,boundingRec.height/SCALE * .5);
					fixtureDef.shape = boxShape;
					fixtureDef.friction = 0.7;
					fixtureDef.density = 6;
					fixtureDef.restitution = 0.4;
					
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
					
				}else if (dispObj.name.search("SC") == 0) {
					//STATIC CIRCLES
					trace("TrackBuilder-- Found static circle :", dispObj.name)
					
					bodyDef = new b2BodyDef();
					//bodyDef.userData = { sprite: dispObj };
					bodyDef.position.Set(dispObj.x / SCALE, dispObj.y / SCALE);
					
					circleShape = new b2CircleShape(dispObj.width/ SCALE*.5);
					fixtureDef.shape = circleShape;
					fixtureDef.friction = 0.7;
					fixtureDef.restitution = 0.3;
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
					
					
				}else if (dispObj.name.search("DC") == 0) {
					//dynamic circle
					trace("TrackBuilder-- Found dynamic circle :", dispObj.name)

					bodyDef = new b2BodyDef();
					
					bodyDef.userData = { sprite: dispObj };
					bodyDef.linearDamping = 1;
					bodyDef.angularDamping = 0.9;
					bodyDef.position.Set(dispObj.x / SCALE, dispObj.y / SCALE);
					bodyDef.allowSleep = true;
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);
					bodyDef.type = b2Body.b2_dynamicBody;
					
					circleShape = new b2CircleShape(dispObj.width/ SCALE*.5);
					fixtureDef.shape = circleShape;
					fixtureDef.friction = 1;
					fixtureDef.density = 6;
					fixtureDef.restitution = 0.4;
					
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
				}else if (dispObj.name.search("TRlane") == 0 || dispObj.name.search("TRcross") == 0) {//garbage from bulletdrive
					trace("TrackBuilder-- Found traffic stuff :", dispObj.name)
					garbageFromBullet.push(dispObj);
				}
			}
			
			checkPoints.sortOn("name");
			//throw out the garbage
			for (var j:int = 0; j < garbageFromBullet.length; j++) {
				garbageFromBullet[j].parent.removeChild(garbageFromBullet[j]);
			}
		}
		
		/**
		 * Builds one car for each player on the players list
		 * @param	trashCar
		 */
		private function buildCars(trashCar:DisplayObject):void {
			
			var radians:Number = (trashCar.rotation + 90) * (Math.PI / 180);
			var startLineAxis:b2Vec2 = new b2Vec2(Math.cos(radians), Math.sin(radians));
			var axisCenter:b2Vec2 = new b2Vec2(trashCar.x, trashCar.y);
			startLineAxis.Normalize();
			var carIndex:uint = worldSprite.getChildIndex(trashCar);
			var carsDistance:Number = 50;
			
			for (var i:int = 0; i < players.length; i++) {
				trace('adding car:', i);
				var carSprite:Sprite = players[i].carSprite;
				var carPos:b2Vec2 = axisCenter.Copy();
				var axisOffset:b2Vec2 = startLineAxis.Copy();
				axisOffset.Multiply(carsDistance * (i -  (players.length - players.length % 2) / 2 ));
				carPos.Add(axisOffset);
				carSprite.x = carPos.x;
				carSprite.y = carPos.y;
				carSprite.rotation = trashCar.rotation;
				worldSprite.addChild(carSprite);
				worldSprite.setChildIndex(carSprite, carIndex)
						
				cars.push(new PlayableCar(carSprite, players[i].carData, world));
				oracleCars.push(new PlayableCar(carSprite, players[i].carData, oracleWorld, true));
			}
			worldSprite.removeChild(trashCar);
			//trashCar.visible = false;//remove is better buth meh...we might need it for later
		}
		
		/**
		 * For world building
		 * Returns a rectangle of the display object at zero rotation
		 * @param	dObj
		 * @return 
		 */
		private function getAlignedRect(dObj:DisplayObject):Rectangle {
			var origRot:Number = dObj.rotation;
			dObj.rotation = 0;
			var rec:Rectangle = dObj.getBounds(worldSprite)
			dObj.rotation = origRot;
			return rec;
		}
		
		/**
		 * Creates box2d drawble sprite
		 * @param	world
		 * @return the sprite that will be drawn upon
		 */
		public function initWorldDebug(world:b2World):Sprite{
			var m_sprite:Sprite;
			m_sprite = new Sprite();
			worldSprite.addChild(m_sprite);
			var dbgDraw:b2DebugDraw = new b2DebugDraw();
			dbgDraw.SetSprite(m_sprite);
			dbgDraw.SetDrawScale(RacingWorld.SCALE);
			//dbgDraw.SetAlpha(1);
			dbgDraw.SetFillAlpha(0.5);
			dbgDraw.SetLineThickness(1);
			dbgDraw.SetFlags(b2DebugDraw.e_shapeBit);
			world.SetDebugDraw(dbgDraw);
			
			return m_sprite;
		}
	}

}