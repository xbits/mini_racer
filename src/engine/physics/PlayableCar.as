package engine.physics 
{
	import Box2D.Collision.*; 
	import Box2D.Common.Math.*; 
	import Box2D.Dynamics.*; 
	import Box2D.Dynamics.Joints.*;
	import Box2D.Collision.Shapes.*; 
	import engine.models.CarParams;
	import engine.models.LaunchParams;
	import engine.RacingWorld;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	/**
	 * Bridges a player's car to the physics world.
	 * TODO: Too tighly coupled with CarParams
	 * 
	 * @author João Costa
	 */
	public class PlayableCar
	{

		public static const TWO_PI:Number = Math.PI * 2;
		
		public var body:b2Body;
		public var frontWheel:b2Body;
		public var rearWheel:b2Body;
		public var frontJoint:b2RevoluteJoint;
		public var rightJoint:b2RevoluteJoint;
		
		public var world:b2World;
		
		public var carSprite:Sprite;
		public var carParams:CarParams;
		
		/**
		 * Build a new physics car from the sprite dimensions and car data definitions
		 * @param	carSprite
		 * @param	carParams
		 * @param	world
		 * @param	isOracle
		 */
		public function PlayableCar(carSprite:Sprite,carParams:CarParams,world:b2World, isOracle:Boolean = false) 
		{
			this.world = world;
			this.carSprite = carSprite;
			this.carParams = carParams;
			//world.addEventListener(WorldBuilder.EVT_UPDATE, )
			
			var carInitialPosition:b2Vec2 = new b2Vec2(carSprite.x / RacingWorld.SCALE, carSprite.y / RacingWorld.SCALE);
			
			var oldRotation:Number = carSprite.rotation;
			carSprite.rotation = 0;
			var boundingRec:Rectangle = carSprite.getBounds(carSprite.parent)
			//carSprite.rotation = oldRotation;
					
			var carHeight:Number = boundingRec.height/RacingWorld.SCALE;
			var carWidth:Number = boundingRec.width/RacingWorld.SCALE;
			var bumpersOffset:Number = carHeight * .5 - carWidth * .3;
				
			var boxShape:b2PolygonShape = new b2PolygonShape();//boxDef factory-ish for use in all boxes def
			var fixtureDef:b2FixtureDef = new b2FixtureDef();//fixture factory-ish
			
			if (isOracle) {
				fixtureDef.filter.groupIndex = -1;
			}
			
			// define car body
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.userData = {sprite: carSprite};
			
			bodyDef.linearDamping = 1;
			bodyDef.angularDamping = 0.8;
			bodyDef.position = carInitialPosition.Copy();
			bodyDef.type = b2Body.b2_dynamicBody;
			bodyDef.allowSleep = true;
			
			body = world.CreateBody(bodyDef);
	
			//---chassis---
			boxShape.SetAsBox(carWidth * .5,  bumpersOffset);
			fixtureDef.shape = boxShape;
			fixtureDef.friction = 1;
			fixtureDef.density = 2;//TODO this will affect power...
			fixtureDef.restitution = 0.3;
			body.CreateFixture(fixtureDef);
			
			//---rear bumper
			var circleShape:b2CircleShape = new b2CircleShape(carWidth*.5);
			circleShape.SetLocalPosition(new b2Vec2(0, bumpersOffset));
			fixtureDef.shape = circleShape;
			fixtureDef.friction = 0.1;
			fixtureDef.density = 0.5 + 2.5/carParams.stability;
			fixtureDef.restitution = 0.3;
			body.CreateFixture(fixtureDef);
			
			//---front bumper
			circleShape = new b2CircleShape(carWidth*.5);
			circleShape.SetLocalPosition(new b2Vec2(0, -bumpersOffset));
			fixtureDef.shape = circleShape;
			fixtureDef.friction = 0.1;
			fixtureDef.density = 0.5 + 2.5/carParams.stability;
			fixtureDef.restitution = 0.3;
			body.CreateFixture(fixtureDef);
			
			//---define front wheel---
			var frontWheelPosition:b2Vec2 = new b2Vec2(0, -carHeight * .5 * CarParams.FRONT_WHEEL_OFFSET);
			var frontWheelDef:b2BodyDef = new b2BodyDef();
			frontWheelDef.type = b2Body.b2_dynamicBody;
			frontWheelDef.position = carInitialPosition.Copy();
			frontWheelDef.position.Add(frontWheelPosition);
			
			boxShape.SetAsBox(0.2, 0.5);
			fixtureDef.shape = boxShape;
			fixtureDef.friction = 0.4;
			fixtureDef.density = 1*carParams.stability;
			frontWheel = world.CreateBody(frontWheelDef);
			frontWheel.CreateFixture(fixtureDef);
			
			//---define rear wheel---
			var rearWheelPosition:b2Vec2 = new b2Vec2(0, carHeight * .5 * CarParams.REAR_WHEEL_OFFSET);
			var rearWheelDef:b2BodyDef = new b2BodyDef();
			rearWheelDef.type = b2Body.b2_dynamicBody;
			rearWheelDef.position = carInitialPosition.Copy();
			rearWheelDef.position.Add(rearWheelPosition);
			
			boxShape.SetAsBox(0.2, 0.5);
			fixtureDef.shape = boxShape;
			fixtureDef.friction = 0.4;
			fixtureDef.density = 1*carParams.stability;
			rearWheel = world.CreateBody(rearWheelDef);
			rearWheel.CreateFixture(fixtureDef);
			
			//---front wheel joint---
			var fronJointDef:b2RevoluteJointDef = new b2RevoluteJointDef();
			fronJointDef.Initialize(body, frontWheel, frontWheel.GetWorldCenter());
			fronJointDef.enableMotor = true;
			fronJointDef.maxMotorTorque = 100;
			
			frontJoint = b2RevoluteJoint(world.CreateJoint(fronJointDef));
			
			//---rear wheel joint---
			var rearJointDef:b2PrismaticJointDef = new b2PrismaticJointDef();
			rearJointDef.Initialize(body, rearWheel, rearWheel.GetWorldCenter(), new b2Vec2(1, 0));
			rearJointDef.enableLimit = true;
			rearJointDef.lowerTranslation = rearJointDef.upperTranslation = 0;
	
			world.CreateJoint(rearJointDef);
			body.SetAngle((carSprite.rotation) * (Math.PI / 180));// + Math.PI * .5;

		}
		
		public function onWorldUpdate(e:Event = null):void {
			killOrthogonalVelocity(frontWheel);
			killOrthogonalVelocity(rearWheel);
			
			//steer
			var mspeed:Number = -frontJoint.GetJointAngle();
			frontJoint.SetMotorSpeed(mspeed * CarParams.STEER_SPEED);
		}
		
		/**
		 * restricts angle to -PI..PI
		 * @param	a
		 * @return
		 */
		private function normalizeAngle(a:Number):Number{
			return a - TWO_PI * Math.floor((a + Math.PI) / TWO_PI);
		}
			
		/**
		 * This function applies a "friction" in a direction orthogonal to the body's axis.
		 * It applies 100% friction in reality but since it is only applied to the wheels 
		 * it results in being only friction because the car body keeps its momentum
		 * @param	targetBody
		 */
		public function killOrthogonalVelocity(targetBody:b2Body):void{
			var localPoint:b2Vec2 = new b2Vec2(0, 0);
			var velocity:b2Vec2 = targetBody.GetLinearVelocityFromLocalPoint(localPoint);
			var sidewaysAxis:b2Vec2 = targetBody.GetTransform().R.col2.Copy();
			sidewaysAxis.Multiply(b2Math.Dot(velocity, sidewaysAxis));
			
			targetBody.SetLinearVelocity(sidewaysAxis); //targetBody.GetWorldPoint(localPoint));
		}
		
		/**
		 * Applies an impulse to the car body.
		 * @param	launchP Expected to have 'from' attribute set. 
		 * @return LaunchParams same instance that came in parameters
		 */
		public function launchFrom(launchP:LaunchParams):LaunchParams {
			//tranform vector to represent CAR->mousePos
			launchP.from.Subtract(body.GetWorldCenter().Copy());
			
			var newWheelAngle:Number = Math.atan2(-launchP.from.x, launchP.from.y) - (body.GetAngle());
			newWheelAngle = normalizeAngle(newWheelAngle); // normalize angle to [-PI,PI]
			
			var mSteerA:Number = carParams.maxSteerAngle;
			//confine the wheel angle to the allowed steering angle, it get little dense because of angle shift from -halfCircle to +halfCircle
			// I suspect there is a fancier way to do this by shifting quadrants of something...
			launchP.backwards = false;
			if(newWheelAngle > Math.PI*.5){
				launchP.backwards = true;
				newWheelAngle = Math.max( Math.PI - mSteerA, Math.min(mSteerA-Math.PI, newWheelAngle)) ;
			}else if(newWheelAngle < - Math.PI * .5){
				 launchP.backwards = true;
				 newWheelAngle = Math.max( -Math.PI, Math.min(mSteerA-Math.PI, newWheelAngle)) ;
			}else{
				newWheelAngle = Math.max( -mSteerA, Math.min(mSteerA, newWheelAngle)) ;
			}
			frontWheel.SetPositionAndAngle(frontWheel.GetPosition().Copy(), newWheelAngle + body.GetAngle());
			
			//fill launchParams with new angle
			launchP.angle = newWheelAngle + body.GetAngle();
			
			//apply the calculated force in the car axis
			var forwardVec:b2Vec2 = body.GetTransform().R.col2.Copy();
			var dirMult:int = launchP.backwards ? -1 : 1;
			forwardVec.Multiply( -launchP.power * dirMult);
			
			body.ApplyImpulse(forwardVec, body.GetPosition().Copy());
			
			return launchP;
		}
		
		/**
		 * For oracle cars duplication of the real car physics status 
		 * 
		 * @param	targetCar the car from which the properties will be extracted
		 */
		public function imitateStatus(targetCar:PlayableCar):void {
			body.SetLinearVelocity(new b2Vec2());//it's setting to zero cuz we expect the target car to allways be stopped when this is run
			body.SetAngularVelocity(0);//idem
			body.SetPositionAndAngle(targetCar.body.GetPosition().Copy(), targetCar.body.GetAngle());
		}
		
	}

}