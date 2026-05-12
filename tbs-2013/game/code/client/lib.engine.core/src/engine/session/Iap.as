package engine.session
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import engine.core.logging.ILogger;

	import tbs.srv.util.InAppPurchaseItemDef;

	public class Iap extends EventDispatcher
	{
		public static const EVENT_POST_INIT : String = "Iap.EVENT_POST_INIT";

		public var item : InAppPurchaseItemDef;
		public var orderid : int;
		public var transid : int;

		public var error : Boolean;
		public var complete : Boolean;
		public var init : Boolean;
		public var unauthorized : Boolean;
		public var authorized : Boolean;

		public var errorMsg : String;

		public var logger : ILogger;

		private var man : IIapManager;

		public function Iap(man : IIapManager, logger : ILogger)
		{
			this.logger = logger;
			this.man = man;
		}

		override public function toString() : String
		{
			return "Iap[" + item.id + " " + orderid + " " + transid + "]";
		}

		public function setUnauthorized() : void
		{
			unauthorized = true;
			authorized = false;
			var msg : String = "Iap.setUnauthorized " + this;
			logger.info(msg);
			man.sendInfo(msg);
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function setAuthorized() : void
		{
			unauthorized = false;
			authorized = true;
			var msg : String = "Iap.setAuthorized " + this;
			logger.info(msg);
			man.sendInfo(msg);
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function setInit(orderid : int, transid : int) : void
		{
			init = true;
			this.orderid = orderid;
			this.transid = transid;

			var msg : String = "Iap.setInit " + this;
			logger.info(msg);
			man.sendInfo(msg);

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function handlePostInit() : void
		{
			var msg : String = "Iap.handlePostInit " + this;
			logger.info(msg);
			man.sendInfo(msg);

			dispatchEvent(new Event(EVENT_POST_INIT));
		}

		public function setError(errorMsg : String) : void
		{
			this.errorMsg = errorMsg;
			error = true;
			var msg : String = "Iap.setError " + this + ": " + errorMsg;
			logger.error(msg);
			man.sendInfo(msg);
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function setComplete() : void
		{
			complete = true;
			var msg : String = "Iap.setComplete " + this;
			logger.info(msg);
			man.sendInfo(msg);
			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
