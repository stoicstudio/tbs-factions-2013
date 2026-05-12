package engine.path
{
	import flash.events.EventDispatcher;

	public class Path extends EventDispatcher implements IPath
	{
		private var m_dst : IPathGraphNode;
		private var m_elapsed : int;
		private var m_links : Vector.<IPathGraphLink> = new Vector.<IPathGraphLink>();
		private var m_nodes : Vector.<IPathGraphNode>;
		private var m_src : IPathGraphNode;
		private var m_status : PathStatus = PathStatus.WAITING;
		private var m_id : int;
		private static var m_lastId : int;

		public function Path(src : IPathGraphNode, dst : IPathGraphNode)
		{
			m_id = ++m_lastId;

			if (!src || !dst)
			{
				throw new ArgumentError("bad nodes!");
			}

			m_src = src;
			m_dst = dst;
		}

		public function get dispatcher() : EventDispatcher
		{
			return this;
		}

		public function get dst() : IPathGraphNode
		{
			return m_dst;
		}

		public function get elapsed() : int
		{
			return m_elapsed;
		}

		public function set elapsed(e : int) : void
		{
			m_elapsed = e;
		}

		public function get links() : Vector.<IPathGraphLink>
		{
			return m_links;
		}

		public function set links(rhs : Vector.<IPathGraphLink>) : void
		{
			m_nodes = null;
			m_links = rhs;
		}

		public function get nodes() : Vector.<IPathGraphNode>
		{
			cacheNodes();
			return m_nodes;
		}

		public function get src() : IPathGraphNode
		{
			return m_src;
		}

		public function get status() : PathStatus
		{
			return m_status;
		}

		public function set status(s : PathStatus) : void
		{
			if (s != m_status)
			{
				m_status = s;
				dispatchEvent(new PathEvent(PathEvent.EVENT_PATH_STATUS_CHANGED));
			}
		}

		private function cacheNodes() : void
		{
			if (status != PathStatus.COMPLETE)
			{
				return;
			}

			if (!m_nodes && links)
			{
				m_nodes = new Vector.<IPathGraphNode>(links.length + 1);
				for (var i : int = 0; i < links.length; ++i)
				{
					var link : IPathGraphLink = links[i];
					m_nodes[i] = link.src;
				}

				m_nodes[links.length] = links[links.length - 1].dst;
			}
		}

		private function simplify(simplificationVisitor : Function) : void
		{
			for (var i : int = 1; i < links.length; )
			{
				var prev : IPathGraphLink = links[i - 1];
				var link : IPathGraphLink = links[i];
				if (simplificationVisitor(prev.src, link.src, link.dst))
				{
					links.splice(i, 1);
				}
				else
				{
					++i;
				}
			}
		}

		override public function toString() : String
		{
			return "[Path " + m_id + " status=" + m_status.name + " len=" + (links ? links.length : 0) + "]";
		}
	}
}
