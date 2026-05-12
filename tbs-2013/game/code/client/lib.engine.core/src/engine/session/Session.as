package engine.session
{
	import engine.core.http.HttpCommunicator;

	public class Session
	{
		public var communicator : HttpCommunicator;
		public var credentials : Credentials;

		public function Session(communicator : HttpCommunicator, credentials : Credentials)
		{
			this.communicator = communicator;
			this.credentials = credentials;
		}
	}
}
