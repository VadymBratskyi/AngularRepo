Terrasoft.MenuPanel = Ext.extend(Ext.LayoutControl, {
	autoEl:'div',
	width: 200,
	height: 300,
	// collapseMode: 'multiple',
	savedState: new Ext.util.MixedCollection(false, function (source) { return source; }),
	oneList: false,
	allItems: null,
	allowDraggingMenuItems: false,
	ddGroup: '',
	sortFunction: null,
	sortDirection: null,
	checkItemVisibleFunction: null,
	filterFunction: null,

	initComponent: function() {
		Terrasoft.MenuPanel.superclass.initComponent.call(this);
		this.menu = new Ext.menu.Menu({
			id: Ext.id(),
			enableScroll: false
		});
		this.menu.owner = this;
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.menu.createItemsFromConfig(this.menuConfig);
		}
		this.addEvents(
			'click',
			'menuitemclick'
		);
	},

	getMenu: function() {
		this.ensureMenuCreated();
		return this.menu;
	},

	ensureMenuCreated: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id()
			});
			this.menu.owner = this;
		}
	},

	insert: function(index, item) {
		this.ensureMenuCreated();
		return this.menu.insert(index, item);
	},

	removeControl: function(item) {
		if (!this.menu) {
			return null;
		}
		this.menu.remove(item);
		this.onContentChanged();
		return item;
	},

	add: function() {
		this.ensureMenuCreated();
		return this.menu.add(item);
	},

	onContentChanged: function() {
	},

	onRender: function(ct, position) {
		Terrasoft.MenuPanel.superclass.onRender.call(this, ct, position);
		this.on('resize', this.OnResize, this);
		var scroll = this.scrollBar = Ext.ScrollBar.insertScrollBar(this.el.dom);
		scroll.contentWrap.setWidth('100%');
		scroll.contentWrap.setHeight('100%');
		this.menu.designMode = this.designMode;
		var menu = this.menu;
		if (this.allowDraggingMenuItems) {
			this.setDragDrop(menu, this.ddGroup);
		}
		if (!this.collapseMode) {
			this.collapseMode = 'multiple';
		}
		menu.collapseMode = this.collapseMode;
		var el = this.el;
		el.addClass(['x-menu-panel', 'x-menu']);
		menu.createEl = function() {
			return scroll.contentWrap;
		};
		menu.on('toggle', this.onToggle, this);
		menu.getEl = function() {
			return el;
		};
		menu.checkSuccessivelySeparators();
		menu.render();
		menu.on('add', this.OnItemAdd, this);
		scroll.update({
			useHScroll: false
		});
		this.setEdges(this.edges);
	},

	updateScrollBar: function() {
		if (this.scrollBar) {
			this.scrollBar.update();
		}
	},

	onToggle: function(e) {
		this.updateScrollBar();
	},

	setDragDrop: function(menu, ddGroup) {
		menu.items.each(function(item) {
			if (item instanceof Ext.menu.Separator) {
				return;
			}
			if (item.menu) {
				this.setDragDrop(item.menu, ddGroup);
			}
			item.draggable = true;
			item.ddGroup = ddGroup;
		}, this);
	},

	OnItemAdd: function(menu, item) {
		this.updateScrollBar();
	},

	setCollapseMode: function(value) {
		this.collapseMode = value;
		if (this.menu) {
			//TODO		this.menu.setCollapseMode
			this.menu.collapseMode = value;
		}
		this.updateScrollBar();
	},

	collapseAllGroups: function() {
		var menu = this.menu;
		if (menu) {
			menu.collapseAllGroups(true);
		}
	},

	expandAllGroups: function() {
		var menu = this.menu;
		if (menu) {
			menu.collapseAllGroups(false);
		}
	},

	setEdges: function(edgesValue) {
		if (edgesValue && (edgesValue.indexOf("1") != -1)) {
			var el = this.el;
			if (!el) {
				return;
			}
			el.setStyle('border', '1px none #D2D7DC');
			var edges = edgesValue.split(" ");
			var style = el.dom.style;
			style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
			style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
			style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
			style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
		}
	},

	OnResize: function () {
		this.updateScrollBar();
	},

	saveMenuState: function(menu) {
		if (!menu) {
			return;
		}
		menu.items.each(function(item) {
			var state = new Object();
			if (item instanceof Ext.menu.Separator) {
				state.collapsible = item.collapsible;
				state.collapsed = item.collapsed;
			}
			state.visible = item.visible;
			state.groupCollapsed = item.groupCollapsed;
			this.savedState.add(item.id, state);
			if (item.menu) {
				this.saveMenuState(item.menu);
			}
		}, this);
	},

	getMenuItems: function(menu, itemList, showHidden) {
		if (!menu) {
			return;
		}
		menu.items.each(function(item) {
			if (item instanceof Ext.menu.Separator) {
				return;
			}
			if (item.menu) {
				this.getMenuItems(item.menu, itemList, showHidden);
				return;
			}
			if (showHidden && item.visible == false) {
				item.visible = true;
			}
			item.groupCollapsed = false;
			itemList.add(item);
		}, this);
	},

	prepareMenu: function(menu) {
		if (!menu) {
			return;
		}
		menu.render();
		menu.items.each(function(item) {
			if (item.menu) {
				this.prepareMenu(item.menu);
			}
		}, this);
	},

	buildOneLevelMenu: function(showHiddenItems) {
		var showHidden = showHiddenItems == undefined ? true : false;
		if (this.oneList) {
			return;
		}
		var menu = this.menu;
		if (!menu) {
			return;
		}
		if (!this.allItems) {
			this.allItems = new Ext.util.MixedCollection();
		}
		var allItems = this.allItems;
		this.prepareMenu(menu);
		this.savedState.clear();
		allItems.clear();
		this.saveMenuState(menu);
		this.getMenuItems(menu, allItems, showHidden);
		var sortFunc = this.sortFunction ? this.sortFunction : function (a, b) {
			return a.caption < b.caption ? -1 : 1;
		};
		allItems.sort(this.sortDirection ? this.sortDirection : 'ASC', sortFunc);
		this.renderAllItemsList(menu, allItems);
		this.oneList = !this.oneList;
	},

	destroyItems: function(items) {
		items.each(function(item) {
			var itemMenu = item.menu;
			if (itemMenu) {
				this.destroyItems(itemMenu.items);
			}
			var li = item.el;
			Ext.destroy(item);
			li.remove();
		}, this);
	},

	renderItems: function(menu, items, itemsState) {
		items.each(function(item) {
			var li = menu.ul.createChild({tag:'li', cls: 'x-menu-list-item'});
			item.designMode = this.designMode;
			item.rendered = false;
			if (itemsState) {
				Ext.apply(item, itemsState.get(item.id));
			}
			var itemMenu = item.menu;
			if (itemMenu) {
				this.setItemsParentMenu(itemMenu.items, itemMenu, itemsState);
				this.renderItems(itemMenu, itemMenu.items, itemsState);
				itemMenu.checkSuccessivelySeparators();
			}
			item.render(li, menu);
		}, this);
	},

	renderAllItemsList: function(menu, newItems, itemsState) {
		var menuItems = menu.items;
		this.destroyItems(menuItems);
		this.renderItems(menu, newItems, itemsState);
		this.checkItemVisibleFunction = this.checkItemVisibleFunction || function(item) { return item.visible; };
		this.rebuildItems(newItems, this.checkItemVisibleFunction);
		this.filterItems(newItems, this.filterFunction);
		this.updateScrollBar();
		if (!this.oneList) {
			this.savedItems = menuItems;
		}
		menu.items = newItems;
		menu.autoWidth();
	},

	setItemsParentMenu: function(items, menu, itemsState) {
		this.destroyItems(items);
		items.each(function(item) {
			item.parentMenu = menu;
			if (itemsState) {
				Ext.apply(item, itemsState.get(item.id));
			}
			var itemMenu = item.menu;
			if (itemMenu) {
				this.setItemsParentMenu(itemMenu.items, itemMenu, itemsState);
			}
		});
	},

	restoreMenu: function () {
		if (!this.oneList) {
			return;
		}
		var savedItems = this.savedItems;
		savedItems = this.getSortedItemsCollection(savedItems, this.sortDirection, this.sortFunction);
		this.renderAllItemsList(this.menu, savedItems, this.savedState);
		this.savedItems = savedItems;
		this.oneList = !this.oneList;
	},

	sortItems: function(direction, sortFunc) {
		var menu = this.menu;
		if (!menu) {
			return;
		}
		sortFunc = sortFunc || function (a, b) {
			return a.caption < b.caption ? -1 : 1;
		};
		direction = direction || 'ASC';
		this.sortFunction = sortFunc;
		this.sortDirection = direction;
		this.prepareMenu(menu);
		var sortedItems = this.getSortedItemsCollection(menu.items, this.sortDirection, this.sortFunction);
		this.renderAllItemsList(menu, sortedItems);
	},

	getSortedItemsCollection: function(items, direction, sortFunc) {
		var groupingItems = new Ext.util.MixedCollection();
		var sortedItems = new Ext.util.MixedCollection();
		this.groupItems(items, groupingItems);
		this.sort(groupingItems, direction, sortFunc);
		this.restoreGroupingItems(sortedItems, groupingItems);
		return sortedItems;
	},

	sort: function (items, direction, sortFunc) {
		items.each(function(item) {
			if (item.items) {
				this.sort(item.items, direction, sortFunc);
			}
			if (item.menu) {
				this.sort(item.menu.items, direction, sortFunc);
			}
		}, this);
		items.sort(direction, sortFunc);
	},

	restoreGroupingItems: function(sortedItems, groupingItems) {
		groupingItems.each(function(item) {
			sortedItems.add(item);
			if (item.items) {
				this.restoreGroupingItems(sortedItems, item.items);
				item.items = undefined;
			}
			if (item.menuItems) {
				this.restoreGroupingItems(item.menu.items, item.menuItems);
				item.menuItems = undefined;
			}
		}, this);
	},

	groupItems: function(items, groupingItems) {
		var i;
		var beforeFirstGroup = true;
		for (i = 0; i < items.items.length; i++) {
			var item = items.items[i];
			if (item instanceof Ext.menu.Separator) {
				if (item.collapsible == true) {
					var group = item;
					group.items = new Ext.util.MixedCollection();
					groupingItems.add(group);
					beforeFirstGroup = false;
				} else {
					if (beforeFirstGroup) {
						groupingItems.add(item);
					} else {
						group.items.add(item);
					}
				}
			} else {
				if (item.menu) {
					item.menuItems = new Ext.util.MixedCollection();
					this.groupItems(item.menu.items, item.menuItems);
				}
				if (beforeFirstGroup) {
					groupingItems.add(item);
				} else {
					group.items.add(item);
				}
			}
		}
	},

	rebuild: function(checkFunc) {
		if (!checkFunc) {
			return;
		}
		var items = this.menu.items;
		this.checkItemVisibleFunction = checkFunc;
		this.rebuildItems(items, checkFunc);
		this.filterItems(items, this.filterFunction);
		this.menu.checkSuccessivelySeparators();
		this.updateScrollBar();
	},

	rebuildItems: function(items, checkFunc){
		var lastSeparatorCollapsed;
		var itemXtype;
		items.each(function(item) {
			item.visible = checkFunc(item);
			itemXtype = item.getXType();
			if (item.visible && lastSeparatorCollapsed === true && itemXtype != 'menuseparator') {
				item.groupCollapsed = true;
			} else {
				item.groupCollapsed = !item.visible;
			}
			if (item.menu && item.visible) {
				this.rebuildItems(item.menu.items, checkFunc);
			}
			if (item.visible && itemXtype == 'menuseparator') {
				lastSeparatorCollapsed = item.collapsed;
			} 
			item.startVisible = item.visible;
			item.startGroupCollapsed = item.groupCollapsed;
			item.actualizeIsVisible();
		}, this);
	},

	setFilter: function(filterFunc) {
		if (!filterFunc) {
			return;
		}
		this.filterFunction = filterFunc;
		this.filterItems(this.menu.items, filterFunc);
		this.updateScrollBar();
	},

	removeFilter: function() {
		this.filterFunction = null;
		this.filterItems(this.menu.items);
		this.updateScrollBar();
	},

	filterItems: function(items, filterFunc){
		items.each(function(item) {
			if (!filterFunc) {
				item.visible = item.startVisible;
				item.groupCollapsed = item.startGroupCollapsed;
			} else {
				item.visible = filterFunc(item);
				item.groupCollapsed = !item.visible;
			}
			item.actualizeIsVisible();
		}, this);
	}

});

Ext.reg("menupanel", Terrasoft.MenuPanel);