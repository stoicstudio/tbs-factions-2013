package engine.battle
{
	import flash.utils.Dictionary;

	public class SceneListDef
	{
		public var items : Vector.<SceneListItemDef> = new Vector.<SceneListItemDef>;
		private var _id2item : Dictionary = new Dictionary;

		private var skus : Dictionary = new Dictionary;

		public function SceneListDef()
		{

		}

		public function fetch(id : String) : SceneListItemDef
		{
			return _id2item[id];
		}

		protected function addItem(item : SceneListItemDef) : void
		{
			if (item.id in _id2item)
			{
				throw new ArgumentError("Don't double-add");
			}

			_id2item[item.id] = item;
			if (!item.test)
			{
				items.push(item);
			}
		}

		private function removeItem(item : SceneListItemDef) : void
		{
			delete _id2item[item.id];
			const index : int = items.indexOf(item);
			if (index >= 0)
			{
				items.splice(index, 1);
			}
		}

		public function mergeSku(sku : String, rhs : SceneListDef) : void
		{
			purgeSku(sku);
			
			if (!rhs)
			{
				return;
			}
			
			skus[sku] = rhs;
			for each (var i : SceneListItemDef in rhs._id2item)
			{
				addItem(i);
			}
		}

		public function purgeSku(sku : String) : void
		{
			const rhs : SceneListDef = skus[sku];

			if (!rhs)
			{
				return;
			}

			delete skus[sku];

			for each (var i : SceneListItemDef in rhs._id2item)
			{
				removeItem(i);
			}
		}
	}
}
