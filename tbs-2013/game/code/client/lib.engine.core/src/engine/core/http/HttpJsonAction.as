package engine.core.http
{
	import engine.core.logging.ILogger;

	import flash.errors.IllegalOperationError;

	/**
	 * An action which decodes its response as a JSON object
	 * @author johnwatson
	 *
	 */
	public class HttpJsonAction extends HttpAction
	{
		protected var m_jsonObject : Object;
		public var message : String;

		public function HttpJsonAction(url : String, method : HttpRequestMethod, body : Object, callback : Function, logger : ILogger)
		{
			super(url, method, body, callback, logger);
		}

		public function get jsonObject() : Object
		{
			return m_jsonObject;
		}

		override protected function handleResponseProcessing() : void
		{
			if (response)
			{
				var f : String = response.charAt(0);

				//logger.debug("HttpJsonAction " + this + " handleResponseProcessing " + response);

				if (f == "{" || f == "[")
				{
					try
					{
						m_jsonObject = JSON.parse(response);
					}
					catch (e : Error)
					{
						logger.error("HttpJsonAction " + this + " Failed to process JSON response: " + response + "\n" + e.message);
					}
				}
				else
				{
					message = response;

					if (!success)
					{
						logger.error("HttpJsonAction " + this + " Server Error: " + responseCode + ": " + message);
					}
					else
					{
						logger.error("HttpJsonAction " + this + " Server Response: " + responseCode + ": " + message);
					}
				}
			}

			try
			{
				handleJsonResponseProcessing();
			}
			catch (e : Error)
			{
				logger.error("HttpJsonAction " + this + " Failed to handle JSON processing: " + e + ": " + e.getStackTrace());
			}
		}

		/**
		 * Subclasses should override this to provide special JSON object interpretation
		 * @param code
		 * @param response
		 *
		 */
		protected function handleJsonResponseProcessing() : void
		{

		}
	}
}
