package ddgame.client.triggers {
	
	import flash.events.Event;		
	import flash.media.Sound;
	import com.sos21.events.BaseEvent;
	import com.sos21.tileengine.core.AbstractTile;
	import ddgame.sound.SoundTrack;
	import ddgame.sound.AudioHelper;	
	import ddgame.client.proxy.LibProxy;
	import ddgame.client.view.PlayerHelper;

	/**
	 *	Trigger jouer un son
	 *
	 * arguments
	 * pload	url du fichier son
	 * 
	 *	@langversion ActionScript 3.0
	 *	@playerversion Flash 9.0
	 *
	 *	@author toffer
	 */
	public class SoundTrigger extends AbstractTrigger {
	
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		public static const CLASS_ID:int = 108;
			
		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------

		/**
		 * @inheritDoc
		 */
		override public function execute (e:Event = null) : void
		{
			// recup son à jouer
			var sndUrl:String = getPropertie("sf");

			if (!sndUrl) {
				complete();
			}
			else {
//				var sndUrl:String = snds[0];
				// on test si le son existe dans la banque
				soundTrack = audioHelper.getSound(sndUrl);
				// le son n'est pas dans la banque
				if (!soundTrack)
				{
					// on regarde dans la lib...
					var sound:Sound = libProxy.lib.getContent(sndUrl) as Sound;
					if (sound) {
						soundTrack = audioHelper.addSound(sound, false);
					}
				}
				
				// On Recheck au cas ou rien n'ai été trouvé dans
				// la lib ou erreur de création du SoundTrack
				if (soundTrack)
				{
					
					var loops:int = getPropertie("lp");
					if (getPropertie("vol")) volume = getPropertie("vol");

					// Lecture !!!
					soundTrack.add(onSoundTrackSignal);
					soundTrack.play(0, loops);
					
					// Option son spatial
					var sp:Object = getPropertie("sp");
					if (sp)
					{						
						// recup poistion de la source déclencheuse
						if (String(sp).indexOf("-") > -1)
						{
							// on est sur une source type définie dans le trigger
							// pour l'instant coordonnées (cf cellule)
							spatialSource = new SpatialSource(String(sp).split("-"));
						}
						else if (sourceTarget is AbstractTile)
						{
							// on est sur une source type objet
							spatialSource = new SpatialSource(sourceTarget);
						}
						else if (String(sourceTarget).indexOf("-") > -1) {
							// on est sur un source type cellule
							spatialSource = new SpatialSource(String(sourceTarget).split("-"));
						}						
					}
					
					if (spatialSource)
					{
						var radius:Number = getPropertie("spr");
						if (!radius) radius = 1;
						spatialSource.radius = radius;
						stage.addEventListener(Event.ENTER_FRAME, onTick);
					}
					else {
						// on définit le volume par defaut
						soundTrack.volume = volume;
					}
				}
				else {
					complete();
				}
			}
		}
		
		//---------------------------------------
		// PRIVATE & PROTECTED INSTANCE VARIABLES
		//---------------------------------------
		
		private var soundTrack:SoundTrack;
		private var spatialSource:SpatialSource;
		private var volume:Number = 1;

		//---------------------------------------
		// EVENT HANDLERS
		//---------------------------------------
		
		/**
		 * Réglage volume si option son spatial
		 *	@param event Event
		 */
		private function onTick (event:Event) : void
		{
			if (soundTrack && spatialSource)
			{
				var ppos:Object = playerHelper.playerPosition;
				// distance entre bob et source du son
				var dist:Number = Math.sqrt(Math.pow(ppos.xu - spatialSource.x, 2) + Math.pow(ppos.yu - spatialSource.y, 2));
				// calcul facteur volume
				var vol:Number = (1 - Math.min(Math.max(dist, 0) / spatialSource.radius, 1)) * volume;

				if (soundTrack.volume != vol) soundTrack.volume = vol;
			}
			else {
				// Au cas ou, on supprime listener
				stage.removeEventListener(Event.ENTER_FRAME, onTick);
			}
		}
		
		/**
		 * Réception event SoundTrack
		 *	@param signal String
		 */
		private function onSoundTrackSignal (signal:String) : void
		{
			// La lecture est terminée ou à été arrêtée
			if (signal == "complete" || signal == "stop")
			{
				// Suppression listener
				soundTrack.remove(onSoundTrackSignal);
				// Suppression ref de l'AudioHelper
				audioHelper.removeSoundTrack(soundTrack);
				soundTrack = null;
				if (spatialSource)
				{
					spatialSource = null;
					stage.removeEventListener(Event.ENTER_FRAME, onTick);					
				}
				complete();
			}
		}
		
		//---------------------------------------
		// PROTECTED METHODS
		//---------------------------------------
		
		/**
		 * Ref Lib
		 */
		protected function get libProxy () : LibProxy
		{ return LibProxy(facade.getProxy(LibProxy.NAME)); }
		
		/**
		 * Ref AudioHelper
		 */
		protected function get audioHelper () : AudioHelper
		{ return AudioHelper(facade.getObserver(AudioHelper.NAME)); }
		
		/**
		 * Ref PlayerHelper
		 */
		protected function get playerHelper () : PlayerHelper
		{ return PlayerHelper(facade.getObserver(PlayerHelper.NAME)); }		
		
	}

}

import com.sos21.tileengine.core.AbstractTile;
internal class SpatialSource {
	
	//---------------------------------------
	// CONSTRUCTOR
	//---------------------------------------
	
	public function SpatialSource (source:Object) : void
	{
		this.source = source;
		this.radius = radius;
	}
	
	//---------------------------------------
	// PRIVATE VARIABLES
	//---------------------------------------
	
	private var source:Object;
	public var radius:Number;
	
	//---------------------------------------
	// GETTER / SETTERS
	//---------------------------------------
	
	/**
	 * Retourne coordonnée x de la source
	 */
	public function get x () : Number
	{
		var px:Number;
		if (source is AbstractTile) {
			px = source.upos.xu;
		}
		else if (source is Array) {
			px = source[0];
		}
		
		return px;
	}
	
	/**
	 * Retourne coordonnée y de la source
	 */
	public function get y () : Number
	{
		var py:Number;
		if (source is AbstractTile) {
			py = source.upos.yu;
		}
		else if (source is Array) {
			py = source[1];
		}
		
		return py;
	}
	
}