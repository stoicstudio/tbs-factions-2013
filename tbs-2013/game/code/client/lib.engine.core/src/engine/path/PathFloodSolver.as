package engine.path
{
	import flash.utils.Dictionary;

	public class PathFloodSolver
	{
		private var open : Dictionary = new Dictionary();
		public var closed : Dictionary = new Dictionary();
		private var nodes : Dictionary = new Dictionary();
		public var resultSet : Dictionary = new Dictionary;
		private var openQueue : Array = new Array();
		public var complete : Boolean;
		public var success : Boolean;
		public var steps : int;
		public var invalidated : Boolean;
		public var nodeBlockedFunc : Function;
		public var src : IPathGraphNode;
		public var costLimit : Number;
		private var heuristic : Function;

		public function PathFloodSolver(src : IPathGraphNode, heuristic : Function, nodeBlockedFunc : Function, costLimit : Number)
		{
			this.costLimit = costLimit;
			this.src = src;
			this.nodeBlockedFunc = nodeBlockedFunc;
			this.heuristic = heuristic;

			var n0 : PathFloodSolverNode = getNode(src);
			this.openQueue.push(n0);
			this.open[n0] = n0;
		}

		public function hasNode(node : IPathGraphNode) : Boolean
		{
			return (nodes[node] != null);
		}

		public function getNode(node : IPathGraphNode) : PathFloodSolverNode
		{
			if (!node)
			{
				return null;
			}

			var psn : PathFloodSolverNode = nodes[node];

			if (!psn)
			{
				psn = new PathFloodSolverNode(node);
				nodes[node] = psn;
			}

			return psn;
		}

		public function update(limitMs : int, timingFunction : Function) : void
		{
//			path.status = PathStatus.WORKING;

			var start : int = (null != timingFunction) ? timingFunction() : 0;

			while (!complete)
			{
				complete = step();
				++steps;

				if (timingFunction != null)
				{
					var delta : int = timingFunction() - start;

					if (!complete)
					{
						if (limitMs >= 0 && delta > limitMs)
						{
							// stop for now and we will continue later on
							return;
						}
					}
				}
			}

			complete = true;

//			path.status = success ? PathStatus.COMPLETE : PathStatus.FAILED;
		}

		public function step() : Boolean
		{
			if (openQueue.length == 0)
			{
				return true;
			}

			// back of the open queue is the highest priority (e.g. the lowest 'f' heuristic)
			var current : PathFloodSolverNode = openQueue.pop();
			delete open[current];

			// current is now closed 
			closed[current] = current;

			// measure traversal costs from current to each of its neighbors			
			for each (var link : IPathGraphLink in current.node.links)
			{
				var next : PathFloodSolverNode = getNode(link.dst);

				if (nodeBlockedFunc != null)
				{
					// blocked node in the path (for this solver anyway.. other solvers may be able to use it)
					if (nodeBlockedFunc(next.node))
					{
						continue;
					}
				}

				if (!next.node.enabled)
				{
					// blocked for _all_ pathfinding
					continue;
				}

				// a loop back to ourselves, is generally due to invalid data
				if (next == current)
				{
					continue;
				}

				// neighbor has already been investigated and closed, so just ignore it
				if (closed[next])
				{
					continue;
				}

				// compute the actual traversal cost from the start node all the way to the neighbor
				var g : Number = current.g + 1 + link.cost + link.dst.cost;

				if (g > costLimit)
				{
					// too expensive, along this route anyway
					continue;
				}

				resultSet[next.node.key] = next;

				var firstVisit : Boolean = false;
				var better : Boolean = false;

				if (!open[next])
				{
					// if the neighbor isn't already open it, we need to open it for future investigation
					open[next] = next;
					openQueue.push(next);
					firstVisit = true;
				}
				else
				{
					// neighbor is already open, let's see if this route to the open neighbor is better than what is already recorded
					if (g < next.g)
					{
						// in this case we found a cheaper way to get from the start to this neighbor 'next', so let's record that
						better = true;
					}
				}

				if (better || firstVisit)
				{
					// we know that we've either found the first path to 'next', or a better path to 'next', so record that here
					next.parentLink = link;
					next.parent = current;
					next.g = g;

					if (firstVisit)
					{
						if (heuristic != null)
						{
							// we only need to compute the heuristic to the goal once for each node
							next.h = heuristic(src.key, next.node.key);
						}
					}
				}
			}

			// now sort the priority queue such that the lowest cost goes to the back
			openQueue.sortOn('f', Array.NUMERIC | Array.DESCENDING);
			return false;
		}

		public function reconstructPathTo(dst : IPathGraphNode) : IPath
		{
			// start with the goal
			var n : PathHeuristicSolverNode = getNode(dst);
			var v : Vector.<IPathGraphLink> = new Vector.<IPathGraphLink>();

			while (n && n.node != src)
			{
				var link : IPathGraphLink = n.parentLink;

				if (!link)
				{
					return null;
				}

				v.push(link);
				n = n.parent;
			}

			v.reverse();

			var path : Path = new Path(src, dst);
			path.links = v;
			path.status = PathStatus.COMPLETE;
			return path;
		}

		public function inResultSet(key : Object) : Boolean
		{
			return resultSet[key] != null;
		}
	}
}
