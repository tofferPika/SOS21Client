package ddgame.triggers {

	import flash.events.IEventDispatcher;
	import flash.display.Stage;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import com.sos21.observer.Notifier;
	import com.sos21.helper.AbstractHelper;
	import com.sos21.tileengine.structures.UPoint;
	import com.sos21.tileengine.core.AbstractTile;
	import com.sos21.tileengine.events.TileEvent;
	import com.sos21.events.BaseEvent;
	
	import ddgame.events.EventList;
	import ddgame.events.TriggerEvent;
	import ddgame.triggers.ITrigger;
	import ddgame.scene.IsosceneHelper;

	
	/**
	 *	Class description.
	 *	
	 *	@langversion ActionScript 3.0
	 *	@playerversion Flash 9.0
	 *
	 *	@author toffer
	 */
	public class AbstractTrigger extends Notifier implements ITrigger {
		
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------

		public static const CLASS_ID:int = -1;

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------
		
		protected var _id:int;
		protected var _properties:Object;
		protected var _starget:Object;
		protected var _differer:Object;
		protected var _canceled:Boolean = false;
		
		//--------------------------------------
		//  GETTER/SETTERS
		//--------------------------------------
		
		public function get classID () : int
		{
			trace("!! le getter classID doit être implémenter dans la classe concrète ", this);
			return CLASS_ID;
		}
		
		public function set sourceTarget (val:Object) : void
		{
			_starget = val;
		}
		
		public function get sourceTarget () : Object
		{
			return _starget;
		}
		
		public function set properties (val:Object) : void
		{ 
			_properties = val;
		}
		
		public function get properties () : Object 
		{ 
			return _properties;
		}
		
		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------
		
		public function isPropertie (prop:String) : Boolean
		{ return _properties.arguments[prop] != null; }
		
		/**
		 *	Retourne une propriété
		 *	@return 
		 */
		public function getPropertie (prop:String) : *
		{ return _properties.arguments[prop]; }
		
		/**
		 * Définit une propriété
		 *	@param prop String
		 *	@param val *
		 */
		public function setPropertie (prop:String, val:*) : void
		{ _properties.arguments[prop] = val; }
		
		/**
		 *	@param event Event
		 */
		public function execute (event:Event = null) : void
		{ trace(".execute() should be implemented in your subClass@" + toString()); }
	
		/**
		 *	@private
		 */
		public function initialize () : void
		{
			// TODO, passer ça dans AbstractExternalTrigger
			var evtType:String = properties.fireType == -1 ? "chained" : properties.fireEventType;
			if (evtType != null)
			{
				var tevent:TriggerEvent = new TriggerEvent(evtType, this, true, true);
				sendEvent(tevent);
				if (tevent.isDefaultPrevented())
				{
					cancel();
					return;
				}
			}
			else
			{
				// TODO eventType est null ou non existant, on envoi une erreur / notifiation ?
				cancel();
			}
		
			if (!_differer)
			{
				// on regarde si il faut attendre que le joueur soit déplacé
				if (!waitPlayerMove()) _execute();
			} else {
				onDiffer();
			}
		}
	
		/**
		 *	Annule l'execution du trigger
		 */
		public function cancel () : void
		{
			if (getPropertie("_mb"))
			{
				var bob:AbstractTile = AbstractTile.getTile("bob");
				if (bob)
				{
					bob.removeEventListener(TileEvent.MOVE_COMPLETE, onMoveBob);
					bob.removeEventListener(TileEvent.MOVE_CANCELED, onMoveBob);
					bob.stop();
					bob.gotoAndStop("stand");					
				}
			}

			if (getPropertie("_fs")) {
				sendEvent(new Event(EventList.UNFREEZE_SCENE));
			}

			_canceled = true;
			sendEvent(new TriggerEvent(TriggerEvent.CANCELED, this));
		}
		
		/**
		 * @private
		 * Nettoyage
		 */
		public function release () : void
		{
			_properties = null;
			_starget = null;
			_differer = null;
		}
		
		/**
		 * Retourne la référence du stage
		 */
		public function get stage() : Stage
		{  return AbstractHelper.stage.stage; }
		
		/**
		 * TODO à supprimer ?
		 *	@param evtType String
		 */
		public function differ (evtType:String) : void
		{
//			_differer = new TriggerDifferer(evtType, channel, this);
		}
		
		//--------------------------------------
		//  EVENT HANDLERS
		//--------------------------------------
		
		/**
		 *	@param e Event
		 */
		protected function onMoveBob (e:Event) : void
		{
			// abonnement clique sur ecène annule, pour annuler le déplacement
			IsosceneHelper(facade.getObserver(IsosceneHelper.NAME)).component.removeEventListener(MouseEvent.MOUSE_DOWN, onMoveBob);
			// abonnement sur bob pour lancer réelement le trigger
			// AbstractTile.getTile("bob").removeEventListener(TileEvent.MOVE_COMPLETE, onMoveBob);
			
			switch (e.type)
			{
				// joueur à cliqué dans la scène, on annule ce trigger
				case MouseEvent.MOUSE_DOWN :
					cancel();
					break;
				case TileEvent.MOVE_CANCELED :
					cancel();
					break;
				// fin du déplacement de bob
				case TileEvent.MOVE_COMPLETE :
					// abonnement sur bob pour lancer réelement le trigger
					AbstractTile.getTile("bob").removeEventListener(TileEvent.MOVE_COMPLETE, onMoveBob);
					_execute();
					break;
			}
		}
		
		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------
		
		/**
		 * TODO implémnter tout ça dans AbstractExternalTrigger
		 *	@private
		 *	@return Boolean
		 */
		protected function waitPlayerMove () : Boolean
		{
			var mb:String = getPropertie("_mb");
			if (mb == null) return false;
			
			// format x/y/z/attendre fin du déplacement
			var tar:Array = mb.split("/");
			// check option attendre fin du déplacement ou pas
			var w:Boolean = tar[3] == 1;
			// le tile à bouger, bob
			var bob:AbstractTile = AbstractTile.getTile("bob");
			// target est une céllule
			var tpoint:UPoint = new UPoint(tar[0], tar[1], tar[2]);
			// on test savoir si le tile est déjà à cette place
			if (!bob.upos.isMatchPos(tpoint))
			{
//				trace(this, tpoint.posToString(), bob.upos.posToString());
				if (w) {
					// abonnement clique sur scène annule, pour annuler le déplacement
					IsosceneHelper(facade.getObserver(IsosceneHelper.NAME)).component.addEventListener (MouseEvent.MOUSE_DOWN, onMoveBob);
					// abonnement sur bob pour lancer réelement le trigger
					bob.addEventListener(TileEvent.MOVE_COMPLETE, onMoveBob);
					bob.addEventListener(TileEvent.MOVE_CANCELED, onMoveBob);
				}
				sendEvent(new BaseEvent(EventList.MOVE_TILE, {tile:bob, cellTarget:tpoint}));
				
			} else { w = false; }

			return w;
//			sendEvent(new Event(EventList.FREEZE_SCENE));
		}
				
		/**
		 *	@param event Event
		 */
		protected function complete (event:Event = null) : void
		{
			if (getPropertie("_fs")) {
				sendEvent(new Event(EventList.UNFREEZE_SCENE));
			}

			// Experimental, écriture de variables comme option commune
			var tw:Array = getPropertie("_wv");
			if (tw)
			{
				for each (var o:Object in tw)
					sendEvent(new BaseEvent(EventList.WRITE_ENV, o));
			}
			
			// Experimental bonus intégrés en options commune
			var bonus:Object = getPropertie("completeBonus");
			if (bonus)
			{
				for (var p:String in bonus)
				{
					lastBonus = (p == "plev") 	? {level:bonus[p]}
														: {index:bonusIndexs[p], value:bonus[p]};

					sendEvent(new BaseEvent(EventList.ADD_BONUS, lastBonus));
				}
			}
			
			sendEvent(new TriggerEvent(TriggerEvent.COMPLETE, this));
		}
		
		protected static var lastBonus:Object;
		protected static var bonusIndexs:Object = {ppir:0,psoc:1,peco:2,penv:3};
		
		protected function onDiffer () : void
		{
			trace(".onDiffer() should be implemented in your subClass@" + toString());
		}
		
		private function _execute () : void
		{
			if (_canceled) return;
			
			// on regarde si il faut freezer les interactions souris dans
			// la scène
			if (getPropertie("_fs")) {
				sendEvent(new Event(EventList.FREEZE_SCENE));
			}
			
			// on regarde si il faut stopper bob
			if (getPropertie("_sb"))
			{
				var bob:AbstractTile = AbstractTile.getTile("bob");
				bob.removeEventListener(TileEvent.MOVE_COMPLETE, onMoveBob);
				bob.stop(true);
			}
			
			sendEvent(new TriggerEvent(TriggerEvent.EXECUTE, this));
			execute();
		}
		
		
	}
	
}
