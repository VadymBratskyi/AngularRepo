/* jshint ignore:start */
Ext.menu.Menu = function (config) {
	if (Ext.isArray(config)) {
		config = { items: config };
	}
	Ext.apply(this, config);
	this.id = this.id || Ext.id();
	this.addEvents(
		"prepare",
		"beforeshow",
		"beforehide",
		"show",
		"add",
		"hide",
		"click",
		"mouseover",
		"mouseout",
		"itemclick",
		"itemcheckchange",
		"toggle"
	);
	Ext.menu.MenuMgr.register(this);
	Ext.menu.Menu.superclass.constructor.call(this);
	this.items = new Ext.util.MixedCollection();
	if (this.menuConfig && this.menuConfig.length > 0) {
		this.owner = this;
		this.createItemsFromConfig(this.menuConfig);
	}
};

Ext.extend(Ext.menu.Menu, Ext.util.Observable, {
	minWidth: 120,
	shadow: "simple",
	subMenuAlign: "tl-tr?",
	defaultAlign: "tl-bl?",
	allowOtherMenus: false,
	ignoreParentClicks: true,
	hidden: true,
	isInPreparing: false,
	collapseMode: "multiple",
	enableScroll: true,
	markerValue: "",

	getMenu: function() {
		return this;
	},

	createEl: function() {
		return new Ext.Layer({
			cls: "x-menu x-menu-no-hide-all",
			shadow: this.shadow,
			constrain: false,
			parentEl: this.parentEl || document.body,
			zindex: 15000,
			dh: {
				"data-item-marker": this.markerValue || this.id
			}
		});
	},

	recursiveMenuItemsPass: function(items, callback, context) {
		Ext.each(items, function(item) {
			if (callback(items, item, context) === false) {
				return false;
			}
			if (item.menu && item.menu.items && item.menu.items.items.length > 0) {
				if (this.recursiveMenuItemsPass(item.menu.items.items, callback, context) === false) {
				}
			}
		}, this);
		return false;
	},

	checkSeparator: function(items, item, context) {
		var prevItem;
		var index = items.indexOf(item);
		if (index > 0) {
			while (true) {
				if (items[index - 1].visible && !items[index - 1].hidden) {
					prevItem = items[index - 1];
					break;
				}
				index = index - 1;
				if (index - 1 < 0) {
					break;
				}
			}
		}
		if (!prevItem) {
			if (item.getXType() == "menuseparator" && 
				(!item.caption || item.caption == "") && !item.collapsible) {
				item.setVisible(false);
			}
			return true;
		}
		if (item.getXType() == "menuseparator") {
			if (prevItem.getXType() == "menuseparator" && item.visible && !item.hidden && prevItem.visible && !prevItem.hidden) {
				prevItem.setVisible(false);
				if (context.checkIsLastSeparatorVisible(items, item) === true) {
					item.setVisible(false);
				}
				return true;
			} else {
				var isSeparatorLastVisible = context.checkIsLastSeparatorVisible(items, item);
				if (isSeparatorLastVisible) {
					item.setVisible(false);
					return true;
				}
			}
		}
	},

	checkIsLastSeparatorVisible: function(items, item) {
		var isSeparatorLastVisible = true;
		var cindex = items.indexOf(item);
		while (true) {
			cindex = cindex + 1;
			if (cindex > items.length-1) {
				break;
			}
			var nextItem = items[cindex];
			if (nextItem.visible === true && nextItem.hidden != true) {
				isSeparatorLastVisible = false;
				break;
			}
		}
		return isSeparatorLastVisible;
	},

	checkSuccessivelySeparators: function() {
		this.recursiveMenuItemsPass(this.items.items, this.checkSeparator, this);
	},

	render: function() {
		if (this.el) {
			return;
		}
		var el = this.el = this.createEl();
		if (this.enableScroll) {
			el.scrollBar = Ext.ScrollBar.insertScrollBar(this.el.id, {
				useHScroll: false
			});
			this.innerEl = el.scrollBar.contentWrap;
			this.innerEl.setWidth(el.getWidth() - el.getFrameWidth("lr"));
		}
		if (!this.keyNav) {
			this.keyNav = new Ext.menu.MenuNav(this);
		}
		if (this.plain) {
			el.addClass("x-menu-plain");
		}
		if (this.cls) {
			el.addClass(this.cls);
		}
		if (this.enableScroll) {
			el = this.innerEl;
		}
		this.focusEl = el.createChild({
			tag: "a",
			cls: "x-menu-focus",
			href: "#",
			onclick: "return false;",
			tabIndex: "-1"
		});
		var ul = el.createChild({
			tag: "ul",
			cls: "x-menu-list"
		});
		if (!this.designMode) {
			ul.on("click", this.onClick, this);
		}
		ul.on("mouseover", this.onMouseOver, this);
		ul.on("mouseout", this.onMouseOut, this);
		this.on("show", this.onShow, this);
		this.on("beforeshow", this.onBeforeShow, this);
		this.on("toggle", this.onToggle, this);
		this.items.each(function(item) {
			var li = document.createElement("li");
			li.className = "x-menu-list-item";
			ul.dom.appendChild(li);
			item.designMode = this.designMode;
			item.render(li, this);
		}, this);
		this.ul = ul;
		this.toggleProcess();
		this.autoWidth();
	},

	onToggle: function() {
		if (!this.enableScroll) {
			return;
		}
		this.restrictHeight();
		this.restrictWidth();
	},

	onBeforeShow: function() {
		if (!this.enableScroll) {
			return;
		}
		var list = this.el;
		var innerListHeight = this.getListHeight();
		var borderHeight = list.getBorderWidth("tb");
		var listHeight = innerListHeight + borderHeight;
		list.setHeight(listHeight);
		var scrollBar = list.scrollBar;
		var vScrollWidth = scrollBar.vScroll.getWidth();
		var frameWidth = list.getFrameWidth("lr");
		var maxItemWidth = this.getListWidth();
		var listItemPaddings = 0;
		maxItemWidth = maxItemWidth + frameWidth + listItemPaddings + vScrollWidth;
		list.setWidth(maxItemWidth);
	},

	onShow: function() {
		if (!this.enableScroll) {
			return;
		}
		this.restrictHeight();
		this.restrictWidth();
		var parentMenu = this.parentMenu;
		if (parentMenu) {
			var parentMenuActiveItem = parentMenu.activeItem;
			if (parentMenuActiveItem) {
				var list = this.el;
				var xy = list.getAlignToXY(parentMenuActiveItem.el, parentMenu.subMenuAlign || "tl-tr?");
				list.setXY(xy);
			}
		}
	},
	
	restrictHeight: function() {
		this.innerEl.dom.style.height = "";
		var list = this.el;
		list.beginUpdate();
		var innerListHeight = this.getListHeight();
		var borderHeight = list.getBorderWidth("tb");
		var listHeight = innerListHeight + borderHeight;
		list.setHeight(listHeight);
		list.endUpdate(false);
		list.scrollBar.update();
		var scrollBar = list.scrollBar;
		var vScrollWidth = scrollBar.getVScrollWidth();
		var frameWidth = list.getFrameWidth("lr");
		var newListWidth = list.getWidth() - frameWidth - vScrollWidth;
		this.innerEl.setWidth(newListWidth);
	},

	restrictWidth: function() {
		var list = this.el;
		var scrollBar = list.scrollBar;
		var vScrollWidth = scrollBar.getVScrollWidth();
		var frameWidth = list.getFrameWidth("lr");
		var maxItemWidth = this.getListWidth();
		var listItemPaddings = 0;
		maxItemWidth = maxItemWidth + frameWidth + listItemPaddings + vScrollWidth;
		list.setWidth(maxItemWidth);
		scrollBar.update();
		this.innerEl.setWidth(maxItemWidth - frameWidth - vScrollWidth);
	},

	getListWidth: function() {
		var maxItemWidth = 0;
		var items = this.items.items;
		for (var i = 0, itemsLength = items.length; i < itemsLength; i++) {
			var item = items[i];
			var itemWidth = item.getWidth();
			if (itemWidth > maxItemWidth) {
				maxItemWidth = itemWidth;
			}
		}
		return maxItemWidth;
	},

	getListHeight: function() {
		var height = 0;
		var items = this.items.items;
		for (var i = 0, itemsLength = items.length; i < itemsLength; i++) {
			var item = items[i];
			height += item.container.getHeight();
		}
		var clientHeight = Ext.lib.Dom.getViewHeight();
		return Math.min(height, clientHeight);
	},

	toggleProcess: function() {
		var el = this.getEl();
		if (!el) {
			return;
		}
		var items = this.items.items;
		var hideItem = false;
		var firstGroup = true;
		var singleMode = this.collapseMode != "multiple";
		for (var i = 0; i < items.length; i++) {
			var checkItem = items[i];
			if (checkItem instanceof Ext.menu.Separator) {
				if (checkItem.visible == false) {
					continue;
				}
				if (checkItem.collapsible == false) {
					checkItem.groupCollapsed = hideItem;
					checkItem.actualizeIsVisible();
					continue;
				}
				if (checkItem.groupCollapsed == true) {
					hideItem = true;
					continue;
				}
				if (firstGroup && !checkItem.collapsed) {
					hideItem = false;
					checkItem.setCollapsed(false);
					firstGroup = false;
				} else {
					hideItem = singleMode == true ? true : checkItem.collapsed;
					checkItem.setCollapsed(hideItem);
				}
				continue;
			}
			checkItem.groupCollapsed = hideItem;
			checkItem.actualizeIsVisible();
		}
		if (el.shadow) {
			el.shadow.show(el);
		}
		this.fireEvent("toggle", this);
	},

	autoWidth: function() {
		var el = this.el;
		if (!el) {
			return;
		}
		var w = this.width;
		if (w) {
			el.setWidth(w);
		}
		if (Ext.isIE7) {
			this.items.each(function(item) {
				if (item.xtype == "menuseparator") {
					item.doAutoWidth(item);
					return false;
				}
			}, this);
		}
	},

	getVisibleItems: function() {
		var item;
		var items = this.items.items;
		var visibleMenuItems = [];
		for (var i = 0, length = items.length; i < length; i++) {
			item = items[i];
			if (!item.hidden) {
				visibleMenuItems.push(item);
			}
		}
		return visibleMenuItems;
	},

	delayAutoWidth: function() {
		if (this.el) {
			if (!this.awTask) {
				this.awTask = new Ext.util.DelayedTask(this.autoWidth, this);
			}
			this.awTask.delay(20);
		}
	},

	findTargetItem: function(e) {
		var t = e.getTarget(".x-menu-list-item", this.ul, true);
		if (t && t.menuItemId) {
			return this.items.get(t.menuItemId);
		}
	},

	onClick: function(e) {
		var t;
		if (t = this.findTargetItem(e)) {
			if (!t.enabled) {
				return;
			}
			if (t.menu && this.ignoreParentClicks) {
				t.expandMenu();
			} else {
				t.onClick(e);
				this.fireEvent("click", this, t, e);
			}
			if (t instanceof Ext.menu.Separator) {
				this.toggle(t);
				if (Ext.isIE7) {
					t.fireEvent("collapsedchange", t);
				}
			}
		}
	},

	toggle: function(item, dontCollapse) {
		var el = this.getEl();
		if (!el || !item || !item.collapsible) {
			return;
		}
		var items = this.items.items;
		var itemIndex = items.indexOf(item);
		var hideItem = false;
		var singleMode = this.collapseMode != "multiple";
		for (var i = 0; i < items.length; i++) {
			var checkItem = items[i];
			if (checkItem instanceof Ext.menu.Separator) {
				if (checkItem.collapsible == false) {
					checkItem.groupCollapsed = hideItem;
					checkItem.actualizeIsVisible();
					continue;
				}
				if (itemIndex == i) {
					hideItem = checkItem.collapsed == false;
				} else {
					hideItem = singleMode == false ? checkItem.collapsed : true;
				}
				if (dontCollapse !== true) {
					checkItem.setCollapsed(hideItem);
				}
				continue;
			}
			checkItem.groupCollapsed = hideItem;
			checkItem.actualizeIsVisible();
		}
		if (el.shadow) {
			el.shadow.show(el);
		}
		this.fireEvent("toggle", this);
	},

	collapseAllGroups: function (collaspe) {
		var items = this.items.items;
		for (var i = 0; i < items.length; i++) {
			var checkItem = items[i];
			if (checkItem instanceof Ext.menu.Separator) {
				if (checkItem.collapsible == false) {
					checkItem.groupCollapsed = collaspe;
					checkItem.actualizeIsVisible();
					continue;
				}
				checkItem.setCollapsed(collaspe);
				continue;
			}
			checkItem.groupCollapsed = collaspe;
			checkItem.actualizeIsVisible();
		}
		this.fireEvent("toggle", this);
	},

	setActiveItem: function(item, autoExpand) {
		if (item != this.activeItem) {
			if (this.activeItem) {
				this.activeItem.deactivate();
			}
			this.activeItem = item;
			item.activate(autoExpand);
		} else if (autoExpand) {
			item.expandMenu();
		}
	},

	tryActivate: function(start, step) {
		var items = this.items;
		for (var i = start, len = items.length; i >= 0 && i < len; i += step) {
			var item = items.get(i);
			if (!item.disabled && item.canActivate) {
				this.setActiveItem(item, false);
				return item;
			}
		}
		return false;
	},

	onMouseOver: function(e) {
		var t;
		if (t = this.findTargetItem(e)) {
			if (t.canActivate && !t.disabled) {
				this.setActiveItem(t, true);
			}
		}
		this.over = true;
		this.fireEvent("mouseover", this, e, t);
	},

	onMouseOut: function(e) {
		var t;
		if (t = this.findTargetItem(e)) {
			if (t == this.activeItem && t.shouldDeactivate(e)) {
				this.activeItem.deactivate();
				delete this.activeItem;
			}
		}
		this.over = false;
		this.fireEvent("mouseout", this, e, t);
	},

	isVisible: function() {
		return this.el && !this.hidden;
	},

	createItemsFromConfig: function(menuConfig) {
		var items = this.items;
		if (items) {
			if (Ext.isArray(menuConfig)) {
				this.add.apply(this, menuConfig);
			} else {
				this.add(menuConfig);
			}
			this.visibleItems = this.getVisibleItems();
		}
	},

	prepareCallback: function() {
		var cache = this.prepareCache;
		if (this.prepareCache.showAt) {
			this.doShowAt(cache.xy, cache.parentMenu, cache._e);
		} else {
			this.doShow(cache.el, cache.pos, cache.parentMenu, cache.xyPosition);
		}
		this.isInPreparing = false;
	},

	prepareFailure: function() {
		this.isInPreparing = true;
	},

	show: function(el, pos, parentMenu, xyPosition) {
		if (this.isInPreparing) {
			return;
		}
		if (this.hasListener("prepare")) {
			this.isInPreparing = true;
			document.body.style.cursor = "wait";
			this.fireEvent("prepare", this);
			this.prepareCache = {showAt: false, el: el, pos: pos, parentMenu: parentMenu, xyPosition: xyPosition};
			return;
		}
		this.doShow(el, pos, parentMenu, xyPosition);
	},

	doShow: function(el, pos, parentMenu, xyPosition) {
		document.body.style.cursor = "default";
		this.parentMenu = parentMenu;
		if (!this.el) {
			this.render();
		}
		this.fireEvent("beforeshow", this);
		var xy = xyPosition || [0, 0];
		this.showAt(this.el.getAlignToXY(el || this.el, pos || this.defaultAlign, xy), parentMenu, false);
	},

	showAt: function(xy, parentMenu, _e) {
		if (this.isInPreparing) {
			return;
		}
		if (this.hasListener("prepare")) {
			this.isInPreparing = true;
			document.body.style.cursor = "default";
			this.fireEvent("prepare", this);
			this.prepareCache = {
				showAt: true,
				xy: xy,
				parentMenu: parentMenu,
				_e: _e
			};
			return;
		}
		this.doShowAt(xy, parentMenu, _e);
	},

	doShowAt: function(xy, parentMenu, _e) {
		document.body.style.cursor = "default";
		this.parentMenu = parentMenu;
		if (!this.el) {
			this.render();
		}
		if (_e !== false) {
			this.fireEvent("beforeshow", this);
			xy = this.el.adjustForConstraints(xy);
		}
		this.checkSuccessivelySeparators();
		this.el.setXY(xy);
		if (this.fxFunction) {
			this.el[this.fxFunction]();
		} else {
			this.el.show();
		}
		this.hidden = false;
		this.focus();
		this.fireEvent("show", this);
	},

	focus: function() {
		if (!this.hidden) {
			this.doFocus.defer(50, this);
		}
	},

	doFocus: function() {
		if (!this.hidden) {
			this.focusEl.focus();
		}
	},

	hide: function(deep) {
		if (this.el && this.isVisible()) {
			var items = this.items.items;
			this.fireEvent("beforehide", this);
			if (this.activeItem) {
				this.activeItem.deactivate();
				this.activeItem = null;
			}
			this.el.hide();
			this.hidden = true;
			Ext.each(items, function(item) {
				delete item.firePrepareMenuEvent;
			}, this);
			this.fireEvent("hide", this);
		}
		if (deep === true && this.parentMenu) {
			this.parentMenu.hide(true);
		}
	},

	add: function() {
		var a = arguments;
		var l = a.length;
		var item;
		for (var i = 0; i < l; i++) {
			var el = a[i];
			if (el == null) {
				continue;
			}
			if (el.render) {
				item = this.addItem(el);
			} else if (typeof el == "string") {
				if (el == "separator" || el == "-") {
					item = this.addSeparator();
				} else {
					item = this.addCaption(el);
				}
			} else if (el.tagName || el.el) {
				item = this.addElement(el);
			} else if (typeof el == "object") {
				Ext.applyIf(el, this.defaults);
				item = this.addMenuItem(el);
			}
			if (el.menuConfig) {
				item.menu = new Ext.menu.Menu({
					id:Ext.id()
				});
				item.menu.createItemsFromConfig(el.menuConfig);
			}
			item.parentMenu = this;
		}
		return item;
	},

	getEl: function() {
		if (!this.el) {
			this.render();
		}
		return this.el;
	},

	addSeparator: function(cfg) {
		return this.addItem(new Ext.menu.Separator(cfg));
	},

	addCaptionSeparator: function(caption, cfg) {
		var item = new Ext.menu.Separator({caption: caption});
		Ext.apply(item, cfg);
		return this.addItem(item);
	},

	addElement: function(el) {
		return this.addItem(new Ext.menu.BaseItem(el));
	},

	addItem: function(item) {
		this.items.add(item);
		if (this.ul) {
			var li = document.createElement("li");
			li.className = "x-menu-list-item";
			this.ul.dom.appendChild(li);
			var menuItems = this.items;
			var previousItem = menuItems.itemAt(menuItems.length - 1);
			if (previousItem) {
				item.groupCollapsed = previousItem.groupCollapsed;
			}
			item.designMode = this.designMode;
			item.render(li, this);
			this.delayAutoWidth();
			this.fireEvent("add", this, item);
		}
		var container = this.owner && this.owner.container;
		if (container && this.owner.isMenuitem) {
			var containerEl = Ext.get(container);
			if (!containerEl.child("img.x-menu-item-arrow")) {
				containerEl.insertHtml("beforeEnd", String.format('<img src="{0}" class="x-menu-item-arrow"/>', Ext.BLANK_IMAGE_URL));
			}
		}
		return item;
	},

	addMenuItem: function(config) {
		if (!(config instanceof Ext.menu.Item)) {
			if (typeof config.checked == "boolean") {
				config = new Ext.menu.CheckItem(config);
			} else {
				config = new Ext.menu.Item(config);
			}
		}
		return this.addItem(config);
	},

	addCaption: function(caption) {
		return this.addItem(new Ext.menu.CaptionItem(caption));
	},

	addCaptionItem: function(itemId, caption, cfg) {
		var id = itemId || Ext.id();
		var item = new Ext.menu.Item({
			id: id,
			caption: caption
		});
		Ext.apply(item, cfg);
		item = this.addItem(item);
		return item;
	},

	addCaptionItemTag: function(caption, cfg, tag) {
		var item = this.addCaptionItem(tag +"_id", caption, cfg);
		item.tag = tag;
		return item;
	},

	addCheckItem: function(itemId, caption, cfg) {
		var id = itemId || Ext.id();
		var item = new Ext.menu.CheckItem({
			id: id,
			caption: caption
		});
		Ext.apply(item, cfg);
		return this.addItem(item);
	},

	insert: function(index, item) {
		var items = this.items;
		if (index == -1) {
			items.add(item);
		} else {
			items.insert(index, item);
		}
		if (this.ul) {
			var li = document.createElement("li");
			li.className = "x-menu-list-item";
			if (this.ul.dom.childNodes[index]) {
				this.ul.dom.insertBefore(li, this.ul.dom.childNodes[index]);
			} else {
				this.ul.dom.insertBefore(li, null);
			}
			var previousItem = items.itemAt(index - 1);
			if (!previousItem) {
				previousItem = items.itemAt(items.length - 1);
			}
			if (previousItem) {
				item.groupCollapsed = previousItem.groupCollapsed;
			}
			item.designMode = this.designMode;
			item.render(li, this);
			this.delayAutoWidth();
			this.fireEvent("add", this, item);
		}
		return item;
	},

	remove: function(item, leave) {
		this.items.removeKey(item.id);
		if (!leave) {
			item.destroy();
		} else if (item.rendered) {
			item.remove();
		}
	},

	removeByIndex: function(index) {
		var item = this.items.get(index);
		if (item) {
			this.remove(item);
		}
	},
	
	setVisibleByIndex: function(index, isVisible) {
		var item = this.items.get(index);
		if (!item) {
			return;
		}
		item.visible = isVisible;
		item.actualizeIsVisible();
	},

	removeAll: function() {
		if (this.items) {
			var f;
			while (f = this.items.first()) {
				this.remove(f);
			}
		}
	},

	destroy: function() {
		this.beforeDestroy();
		Ext.menu.MenuMgr.unregister(this);
		if (this.keyNav) {
			this.keyNav.disable();
		}
		this.removeAll();
		if (this.ul) {
			this.ul.removeAllListeners();
		}
		if (this.el) {
			this.el.destroy();
		}
	},

	beforeDestroy: Ext.emptyFn
});

Ext.menu.MenuNav = function(menu) {
	Ext.menu.MenuNav.superclass.constructor.call(this, menu.el);
	this.scope = this.menu = menu;
};

Ext.extend(Ext.menu.MenuNav, Ext.KeyNav, {
	doRelay: function(e, h) {
		var k = e.getKey();
		if (!this.menu.activeItem && e.isNavKeyPress() && k != e.SPACE && k != e.RETURN) {
			this.menu.tryActivate(0, 1);
			return false;
		}
		return h.call(this.scope || this, e, this.menu);
	},
	up: function(e, m) {
		if (!m.tryActivate(m.items.indexOf(m.activeItem) - 1, -1)) {
			m.tryActivate(m.items.length - 1, -1);
		}
	},
	down: function(e, m) {
		if (!m.tryActivate(m.items.indexOf(m.activeItem) + 1, 1)) {
			m.tryActivate(0, 1);
		}
	},
	right: function(e, m) {
		if (m.activeItem) {
			m.activeItem.expandMenu(true);
		}
	},
	left: function(e, m) {
		m.hide();
		if (m.parentMenu && m.parentMenu.activeItem) {
			m.parentMenu.activeItem.activate();
		}
	},
	enter: function(e, m) {
		if (m.activeItem) {
			e.stopPropagation();
			m.activeItem.onClick(e);
			m.fireEvent("click", this, m.activeItem);
			return true;
		}
	},
	forceKeyDown: true
});

Ext.menu.MenuMgr = function() {
	var menus, active, groups = {}, attached = false, lastShow = new Date();

	function init() {
		menus = {};
		active = new Ext.util.MixedCollection();
		Ext.getDoc().addKeyListener(27, function() {
			if (active.length > 0) {
				hideAll();
			}
		});
	}

	function hideAll() {
		if (active && active.length > 0) {
			var c = active.clone();
			c.each(function(m) {
				m.hide();
			});
		}
	}

	function onHide(m) {
		active.remove(m);
		if (active.length < 1) {
			Ext.getDoc().un("mousedown", onMouseDown);
			attached = false;
		}
	}

	function onShow(m) {
		var last = active.last();
		lastShow = new Date();
		active.add(m);
		if (!attached) {
			Ext.getDoc().on("mousedown", onMouseDown);
			attached = true;
		}
		if (m.parentMenu) {
			m.getEl().setZIndex(parseInt(m.parentMenu.getEl().getStyle("z-index"), 10) + 3);
			m.parentMenu.activeChild = m;
		} else if (last && last.isVisible()) {
			m.getEl().setZIndex(parseInt(last.getEl().getStyle("z-index"), 10) + 3);
		}
	}

	function onBeforeHide(m) {
		if (m.activeChild) {
			m.activeChild.hide();
		}
		if (m.autoHideTimer) {
			clearTimeout(m.autoHideTimer);
			delete m.autoHideTimer;
		}
	}

	function onBeforeShow(m) {
		var pm = m.parentMenu;
		if (!pm && !m.allowOtherMenus) {
			hideAll();
		} else if (pm && pm.activeChild) {
			pm.activeChild.hide();
		}
	}

	function onMouseDown(e) {
		if (lastShow.getElapsed() > 50 && active.length > 0 && !e.getTarget(".x-menu-no-hide-all")) {
			hideAll();
		}
	}

	function onBeforeCheck(mi, state) {
		if (state) {
			var g = groups[mi.group];
			var contextItems = (mi.parentMenu != undefined ) ? mi.parentMenu.items.items : null;
			for (var i = 0, l = g.length; i < l; i++) {
				var isContextItem = (contextItems == null);
				if (contextItems != null) {
					for (var j = 0, k = contextItems.length; j < k; j++) {
						if (contextItems[j] == g[i]) {
							isContextItem = true;
							break;
						}
					}
				}
				if (g[i] != mi && isContextItem == true) {
					g[i].setChecked(false);
				}
			}
		}
	}

	return {
		hideAll: function() {
			hideAll();
		},

		register: function(menu) {
			if (!menus) {
				init();
			}
			menus[menu.id] = menu;
			menu.on("beforehide", onBeforeHide);
			menu.on("hide", onHide);
			menu.on("beforeshow", onBeforeShow);
			menu.on("show", onShow);
			var g = menu.group;
			if (g && menu.events["checkchange"]) {
				if (!groups[g]) {
					groups[g] = [];
				}
				groups[g].push(menu);
				menu.on("checkchange", onCheck);
			}
		},

		get: function(menu) {
			if (typeof menu == "string") {
				if (!menus) {
					return null;
				}
				return menus[menu];
			} else if (menu.events) {
				return menu;
			} else if (typeof menu.length == "number") {
				return new Ext.menu.Menu({ items: menu });
			} else {
				return new Ext.menu.Menu(menu);
			}
		},

		unregister: function(menu) {
			delete menus[menu.id];
			menu.un("beforehide", onBeforeHide);
			menu.un("hide", onHide);
			menu.un("beforeshow", onBeforeShow);
			menu.un("show", onShow);
			var g = menu.group;
			if (g && menu.events["checkchange"]) {
				groups[g].remove(menu);
				menu.un("checkchange", onCheck);
			}
		},

		registerCheckable: function(menuItem) {
			var g = menuItem.group;
			if (g) {
				if (!groups[g]) {
					groups[g] = [];
				}
				groups[g].push(menuItem);
				menuItem.on("beforecheckchange", onBeforeCheck);
			}
		},

		unregisterCheckable: function(menuItem) {
			var g = menuItem.group;
			if (g) {
				groups[g].remove(menuItem);
				menuItem.un("beforecheckchange", onBeforeCheck);
			}
		},

		getCheckedItem: function(groupId) {
			var g = groups[groupId];
			if (g) {
				for (var i = 0, l = g.length; i < l; i++) {
					if (g[i].checked) {
						return g[i];
					}
				}
			}
			return null;
		},

		setCheckedItem: function(groupId, itemId) {
			var g = groups[groupId];
			if (g) {
				for (var i = 0, l = g.length; i < l; i++) {
					if (g[i].id == itemId) {
						g[i].setChecked(true);
					}
				}
			}
			return null;
		}
	};
} ();

Ext.menu.BaseItem = function(config) {
	Ext.menu.BaseItem.superclass.constructor.call(this, config);
	this.addEvents(
		"menuitemclick",
		"click",
		"activate",
		"deactivate",
		"nameChanged"
	);
	this.on("nameChanged", this.onItemNameChanged, this);
	if (this.handler) {
		this.on("click", this.handler, this.scope);
	}
};

Ext.extend(Ext.menu.BaseItem, Ext.Component, {
	isMenuitem: true,
	visible: true,
	groupCollapsed: false,
	canActivate: false,
	activeClass: "x-menu-item-active",
	hideOnClick: true,
	hideParentsMenuOnClick: true,
	hideDelay: 100,
	ctype: "Ext.menu.BaseItem",
	actionMode: "container",
	captionColor: "#024D9C",

	initComponent: function() {
		Ext.menu.BaseItem.superclass.initComponent.call(this);
		this.startVisible = this.visible;
		this.startGroupCollapsed = this.groupCollapsed;
	},

	getImageWidth: function() {
		var image = this.el.child("img.x-menu-item-icon");
		return image == null ? 0 : image.getWidth();
	},

	getMargins: function() {
		return this.el.getMargins("lr");
	},

	getPaddings: function() {
		return this.container.getPadding("lr") + this.el.getPadding("lr");
	},

	getWidth: function (){
		var width = 0;
		var textEl = this.captionEl || this.titleEl;
		if (textEl) {
			width = textEl.getTextWidth();
		} else if (this.editor) {
			width = this.editor.getWidth();
		}
		return width + this.getImageWidth() + this.getPaddings() + this.getMargins();
	},

	onItemNameChanged: function(el, oldName, name) {
		var items = this.parentMenu.items;
		items.remove(el);
		items.add(name, el);
		if (this.container) {
			this.container.menuItemId = name;
		}
	},

	insert: function(index, item) {
		if (!this.rendered) {
			return;
		}
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id()
			});
			this.menu.owner = this;
		}
		return this.menu.insert(index, item);
	},

	onContentChanged: function() {
		this.actualizeIsVisible();
	},

	removeControl: function(item) {
		if (!this.rendered) {
			return;
		}
		this.menu.remove(item);
		return item;
	},

	add: function() {
		if (!this.rendered) {
			return;
		}
		var menu = this.menu;
		if (!menu) {
			menu = this.menu = new Ext.menu.Menu({id:Ext.id()});
			menu.owner = this;
		}
		return menu.add.apply(menu, arguments);
	},

	render: function(container, parentMenu) {
		this.parentMenu = parentMenu;
		Ext.menu.BaseItem.superclass.render.call(this, container);
		this.container.menuItemId = this.id;
	},

	onRender: function(container, position) {
		this.el = Ext.get(this.el);
		container.dom.appendChild(this.el.dom);
		this.actualizeIsVisible();
		if (this.draggable) {
			this.dragSourceDD =
				new Ext.menu.BaseItem.ControlDragSource(this, {ddGroup: this.ddGroup, stopDragOnMouseDown: false});
		}
	},
	
	actualizeIsVisible: function() {
		if (!this.rendered) {
			return;
		}
		this.container.dom.style.display = (this.visible && !this.groupCollapsed) ? "" : "none";
	},

	setHandler: function(handler, scope) {
		if (this.handler) {
			this.un("click", this.handler, this.scope);
		}
		this.on("click", this.handler = handler, this.scope = scope);
	},

	onClick: function(e) {
		if (!this.enabled) {
			return;
		}
		if (this.fireEvent("click", this, e, this.tag) === false) {
			e.stopEvent();
		}
		var parentMenu = this.parentMenu;
		var itemId = this.id;
		var itemIndex = parentMenu.items.items.indexOf(this);
		var itemTag = this.tag;
		while (true) {
			this.handled = false;
			if (parentMenu.fireEvent("itemclick", this, e, itemId, itemIndex) !== false) {
				this.handleClick(e);
				this.handled = true;
			} else {
				e.stopEvent();
				break;
			}
			if (parentMenu.owner && parentMenu.owner.fireEvent("menuitemclick", this, e, itemId, itemIndex, itemTag) !== false) {
				if (!this.handled) {
					this.handleClick(e);
				}
			}
			if (!parentMenu.parentMenu) {
				break;
			}
			parentMenu = parentMenu.parentMenu;
		}
	},

	activate: function() {
		if (!this.enabled) {
			return false;
		}
		var li = this.container;
		li.addClass(this.activeClass);
		this.region = li.getRegion();
		if (!Ext.isIE) {
			this.region = this.region.adjust(2, 2, -2, -2);
		}
		this.fireEvent("activate", this);
		return true;
	},

	deactivate: function() {
		this.container.removeClass(this.activeClass);
		this.fireEvent("deactivate", this);
	},

	shouldDeactivate: function(e) {
		return !this.region || !this.region.contains(e.getPoint());
	},

	handleClick: function(e) {
		if (this.hideOnClick) {
			this.parentMenu.hide.defer(this.hideDelay, this.parentMenu, [this.hideParentsMenuOnClick]);
		}
	},

	expandMenu: function(autoActivate) {
	},

	hideMenu: function() {
	}
});

Ext.menu.CaptionItem = function(cfg) {
	if (typeof cfg == "string") {
		cfg = {
			caption: cfg
		};
	}
	Ext.menu.CaptionItem.superclass.constructor.call(this, cfg);
};

Ext.extend(Ext.menu.CaptionItem, Ext.menu.BaseItem, {
	tag: "",
	hideOnClick: false,
	itemCls: "x-menu-text",

	onRender: function() {
		var s = document.createElement("span");
		s.className = this.itemCls;
		s.innerHTML = this.caption;
		this.el = s;
		Ext.menu.CaptionItem.superclass.onRender.apply(this, arguments);
	}
});

Ext.menu.Separator = function(config) {
	Ext.menu.Separator.superclass.constructor.call(this, config);
};

Ext.extend(Ext.menu.Separator, Ext.menu.BaseItem, {
	tag: "",
	xtype: "menuseparator",
	itemCls: "x-menu-sep",
	captionSelector: "span.x-menu-sep-title",
	imageSelector: "span.x-menu-sep-img",
	hideOnClick: false,
	collapsible: false,
	collapsed : false,

	initComponent: function() {
		Ext.menu.Separator.superclass.initComponent.call(this);
		if (Ext.isIE7) {
			this.addEvents(
				"collapsedchange"
			);
		}
	},

	setImage: function(value) {
		this.imageConfig = value;
		var imageSrc = this.getImageSrc();
		var elImage = this.image;
		if (!this.image) {
			this.setCaption(this.caption);
		}
		if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
			elImage.setStyle("background-image", imageSrc);
			this.isImageVisible = true;
		} else {
			this.image.remove();
			delete this.image;
			if (this.collapsible) {
				this.image = Ext.get(this.el).createChild({
					tag: "span",
					cls: "x-menu-sep-img"
				}, this.titleEl);
			} else {
				this.isImageVisible = false;
			}
		}
	},

	setCaptionColor: function(color) {
		this.captionColor = color;
		if (!this.rendered) {
			return;
		}
		var captionEl = this.el.child(this.captionSelector);
		if (captionEl) {
			captionEl.setStyle("color", color);
		}
	},

	setCollapsible: function(collapsible) {
		this.collapsible = collapsible;
		if (!this.rendered) {
			return;
		}
		var li = this.li;
		if (collapsible) {
			li.addClass("x-sep-li-collapsible");
			li.removeClass("x-sep-li-not-collapsible");
		} else {
			li.removeClass("x-sep-li-collapsible");
			li.addClass("x-sep-li-not-collapsible");
		}
		this.setCaption(this.caption);
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (!this.rendered) {
			return;
		}
		if (caption != "") {
			this.el.innerHTML = "";
			this.el.removeClass("x-menu-sep-without-title");
		} else {
			if (this.el.hasClass("x-menu-sep-without-title")) {
				this.el.addClass("x-menu-sep-without-title");
			}
		}
		var captionEl = this.el.child(this.captionSelector);
		if (this.caption && !captionEl) {
			var title = Ext.get(this.el).createChild({ tag: "span", cls: "x-menu-sep-title" });
			title.dom.innerHTML = caption;
			this.titleEl = title;
			if (this.captionColor && this.captionColor != Ext.menu.BaseItem.prototype.captionColor) {
				title.setStyle("color", this.captionColor);
			}
		} else {
			if (captionEl) {
				captionEl.update(caption);
			}
		}
		if ((this.caption && this.imageConfig && this.imageConfig.source != "None") || this.collapsible) {
			var imageEl = this.el.child(this.imageSelector);
			if (!imageEl) {
				this.image = Ext.get(this.el).createChild({ tag: "span", cls: "x-menu-sep-img" }, this.titleEl);
			}
			this.setImage(this.imageConfig);
		} else {
			if (this.image && !this.collapsible) {
				this.image.remove();
				delete this.image;
			}
		}
	},

	doAutoWidth: function(separator) {
		var menu = separator.parentMenu;
		if (menu.owner && menu.owner.getXType && menu.owner.getXType() == "menupanel") {
			return;
		}
		var items = separator.parentMenu.items.items;
		var elMaxWidth = 0;
		var item;
		for (var i = 0; i < items.length; i++) {
			item = items[i];
			if (!item.rendered) {
				continue;
			}
			if (item.xtype == "menuseparator") {
				item.li.child(".x-menu-sep").setStyle("width","100%");
			}
			if (elMaxWidth < item.el.getWidth() && item.visible && !item.hidden && !item.groupCollapsed) {
				elMaxWidth = item.el.getWidth();
			}
		}
		for (i = 0; i < items.length; i++) {
			item = items[i];
			if (item.xtype == "menuseparator") {
				if (elMaxWidth < menu.minWidth) {
					elMaxWidth = menu.minWidth;
				}
				if (item.rendered) {
					item.li.child(".x-menu-sep").setStyle("width", elMaxWidth + "px");
				}
			}
		}
		var menuShadowEl = separator.parentMenu.el.shadow.el;
		if (menuShadowEl) {
			menuShadowEl.setWidth((elMaxWidth + 15) + "px");
		}
	},

	onRender: function(li) {
		this.li = li;
		var s = document.createElement("div");
		s.className = this.itemCls;
		this.el = s;
		if (Ext.isIE7) {
			this.on("collapsedchange", function(el) {
				this.doAutoWidth(this);
			}, this);
		}
		if (this.caption) {
			var title = Ext.get(this.el).createChild({ tag: "span", cls: "x-menu-sep-title" });
			title.dom.innerHTML = this.caption;
			this.titleEl = title;
		} else {
			var el = Ext.get(this.el);
			el.addClass("x-menu-sep-without-title");
			this.el.innerHTML = "&#160;";
		}
		li.addClass("x-menu-sep-li");
		if ((this.caption && this.imageConfig && this.imageConfig.source != "None") || this.collapsible) {
			this.image = Ext.get(this.el).createChild({ tag: "span", cls: "x-menu-sep-img" }, this.titleEl);
			this.setImage(this.imageConfig);
		} else {
			if (this.image && !this.collapsible) {
				this.image.remove();
				delete this.image;
			}
		}
		if (this.collapsible) {
			li.addClass("x-sep-li-collapsible");
		} else {
			li.addClass("x-sep-li-not-collapsible");
		}
		if (this.collapsed) {
			li.addClass("x-sep-collapsed");
		} else {
			li.removeClass("x-sep-collapsed");
		}
		li.addClass("x-unselectable");
		this.checkForLastSeparator(li);
		Ext.menu.Separator.superclass.onRender.apply(this, arguments);
		if (this.captionColor && this.captionColor != Ext.menu.BaseItem.prototype.captionColor) {
			var captionEl = this.el.child(this.captionSelector);
			captionEl.setStyle("color", this.captionColor);
		}
	},

	checkForLastSeparator: function(li) {
		if (!li) {
			return;
		}
		var lastSeparator;
		if (this.parentMenu && this.collapsed) {
			var items = this.parentMenu.items.items;
			var index = items.indexOf(this);
			var found = false;
			for (var i = index+1; i<items.length; i++) {
				if (items[i].xtype == "menuseparator" && items[i].collapsible) {
					found = true;
					break;
				}
			}
			if (!found) {
				lastSeparator = this.parentMenu.lastSeparator;
				if (lastSeparator) {
					lastSeparator.removeClass("x-sep-last");
				}
				this.parentMenu.lastSeparator = li;
				li.addClass("x-sep-last");
			} 
			else {
				li.removeClass("x-sep-last");
			}
		} else {
			lastSeparator = this.parentMenu.lastSeparator;
			if (lastSeparator) {
				lastSeparator.removeClass("x-sep-last");
			}
			li.removeClass("x-sep-last");
		}
	},

	setCollapsed: function(collapsed) {
		if (this.designMode && (this.collapsed != collapsed || collapsed)) {
			this.parentMenu.toggle(this, true);
		}
		this.collapsed = collapsed;
		if (!this.rendered) {
			return;
		}
		if (this.li) {
			if (this.collapsed) {
				this.li.addClass("x-sep-collapsed");
			} else {
				this.li.removeClass("x-sep-collapsed");
			}
		}
		this.checkForLastSeparator(this.li);
		this.setProfileData("collapsed", collapsed);
	},

	getMargins: function() {
		var margins = this.el.getMargins("lr");
		var titleEl = this.titleEl;
		if (titleEl) {
			margins += titleEl.getMargins("lr");
		}
		return margins;
	},

	getPaddings: function() {
		var paddings = this.container.getPadding("lr") + this.el.getPadding("lr");
		var titleEl = this.titleEl;
		if (titleEl) {
			paddings += titleEl.getPadding("lr");
		}
		return paddings;
	}
});

Ext.reg("menuseparator", Ext.menu.Separator);

Ext.menu.Item = function(config) {
	Ext.menu.Item.superclass.constructor.call(this, config);
	if (this.menu) {
		this.menu.owner = this;
		this.menu = Ext.menu.MenuMgr.get(this.menu);
	}
};

Ext.extend(Ext.menu.Item, Ext.menu.BaseItem, {
	tag: "",
	captionSelector: "span",
	itemCls: "x-menu-item",
	canActivate: true,
	showDelay: 200,
	hideDelay: 200,
	defaultRightPadding: 21,
	shortcutSpacing: 20,
	ctype: "Ext.menu.Item",

	initComponent: function() {
		Ext.menu.Item.superclass.initComponent.call(this);
		this.addEvents("preparemenu");
	},

	insert: function(index, item) {
		Ext.menu.Item.superclass.insert.call(this, index, item);
		var container = this.container;
		if (container) {
			Ext.get(container).insertHtml("beforeEnd",
					String.format('<img src="{0}" class="x-menu-item-arrow"/>', Ext.BLANK_IMAGE_URL));
		}
	},

	getMenu: function() {
		this.ensureMenuCreated();
		return this.menu;
	},

	onContentChanged: function() {
		var menu = this.menu;
		if (menu) {
			var imageArrow;
			if (menu.items.items.length == 0) {
				imageArrow = this.el.parent().child("img.x-menu-item-arrow");
				if (imageArrow) {
					imageArrow.remove();
					menu.destroy();
					delete this.menu;
				}
			}
			else {
				imageArrow = this.el.parent().child("img.x-menu-item-arrow");
				if (menu.items.items.length != 0 && !imageArrow) {
					var container = this.container;
					if (container) {
						Ext.get(container).insertHtml("beforeEnd", String.format('<img src="{0}" class="x-menu-item-arrow"/>', Ext.BLANK_IMAGE_URL));
					}
				}
			}
		}
	},

	ensureMenuCreated: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id()
			});
			this.menu.owner = this;
		}
	},

	removeControl: function(item) {
		Ext.menu.Item.superclass.removeControl.call(this, item);
		if (this.menu.items.items.length == 0) {
			var imageArrow = this.el.parent().child("img.x-menu-item-arrow");
			if (imageArrow) {
				imageArrow.remove();
				this.menu.destroy();
				delete this.menu;
			}
		}
	},

	onRender: function(container, position) {
		this.container = container;
		var el = document.createElement("a");
		el.hideFocus = true;
		el.unselectable = "on";
		el.href = this.href || "#";
		if (this.hrefTarget) {
			el.target = this.hrefTarget;
		}
		
		el.className = this.itemCls + (this.cls ? " " + this.cls : "");
		var src = this.icon || Ext.BLANK_IMAGE_URL;
		var dataItemMarker = this.id ? String.format('data-item-marker="{0}"', this.id) : '';
		var caption = this.itemCaption || this.caption || '';
		el.innerHTML = String.format(
			'<img src="{0}" class="x-menu-item-icon"{1}/><span>{2}</span>',
			src, dataItemMarker, caption);
		this.el = el;
		Ext.menu.Item.superclass.onRender.call(this, container, position);
		this.captionEl = this.el.child(this.captionSelector);
		if (this.captionColor && this.captionColor != Ext.menu.BaseItem.prototype.captionColor) {
			this.el.setStyle('color', this.captionColor);
		}
		this.el.setStyle('paddingRight', this.el.addUnits(this.defaultRightPadding));
		this.setImageClass(this.imageCls);
		if (this.menu) {
			this.menu.owner = this;
			Ext.get(container).insertHtml("beforeEnd",
				String.format('<img src="{0}" class="x-menu-item-arrow"/>', Ext.BLANK_IMAGE_URL));
			return;
		}
		if (this.shortcut) {
			var htmlText = String.format('<span class="x-menu-item-shortcut">{0}<span/>', this.shortcut);
			var htmlElement = Ext.get(container).insertHtml("beforeEnd", htmlText);
			var shortcutSize = Ext.util.TextMetrics.measure(htmlElement, this.shortcut);
			var rightPosition = parseInt(Ext.get(htmlElement).getStyle("right")) || 0;
			var paddingRight = shortcutSize.width + rightPosition + this.shortcutSpacing;
			if (paddingRight > 0) {
				this.el.setStyle("paddingRight", this.el.addUnits(paddingRight));
			}
		}
	},

	setImage: function(value) {
		this.imageConfig = value;
		this.setImageClass();
	},

	getImageList: function() {
		if (this.imageList) {
			return this.imageList;
		}
		var parentMenu = this.parentMenu;
		while (true) {
			if (!parentMenu) {
				return undefined;
			}
			if (parentMenu.imageList) {
				return parentMenu.imageList;
			} else if (parentMenu.owner && parentMenu.owner.imageList) {
				return parentMenu.owner.imageList;
			} else {
				parentMenu = parentMenu.parentMenu;
			}
		}
	},

	setImageClass: function(value) {
		var oldCls = this.imageCls;
		this.imageCls = value;
		if (!this.rendered) {
			return;
		}
		var imageSrc;
		var image = this.el.child("img.x-menu-item-icon");
		if (value == undefined && (this.imageConfig == undefined || this.imageConfig.source == "None")) {
				var imageCfg = this.imageCfg || {
					resourceManager: this.imageList,
					resourceId: this.imageId,
					resourceName: this.imageName
				};
				imageCfg.resourceManager = imageCfg.resourceManager || this.getImageList();
		}
		imageSrc = this.getImageSrc(imageCfg);
		if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
			image.setStyle("background-image", imageSrc);
		} else {
			if (imageSrc == Ext.BLANK_IMAGE_URL && this.checked == undefined) {
				image.setStyle("background-image", "none");
			} else {
				image.replaceClass(oldCls, this.imageCls);
			}
		}
	},

	handleClick: function(e) {
		if (!this.href) {
			e.stopEvent();
		}
		Ext.menu.Item.superclass.handleClick.apply(this, arguments);
	},

	activate: function(autoExpand) {
		if (Ext.menu.Item.superclass.activate.apply(this, arguments)) {
			this.focus();
			if (!this.firePrepareMenuEvent) {
				this.firePrepareMenuEvent = true;
				this.fireEvent("preparemenu", this);
			}
			if (autoExpand) {
				this.expandMenu();
			}
		}
		return true;
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (!this.rendered) {
			return;
		}
		this.captionEl.update(caption);
	},

	setCaptionColor: function(color) {
		this.captionColor = color;
		if (!this.rendered) {
			return;
		}
		this.el.setStyle("color", color);
	},

	shouldDeactivate: function(e) {
		if (Ext.menu.Item.superclass.shouldDeactivate.call(this, e)) {
			if (this.menu && this.menu.isVisible()) {
				return !this.menu.getEl().getRegion().contains(e.getPoint());
			}
			return true;
		}
		return false;
	},

	deactivate: function() {
		Ext.menu.Item.superclass.deactivate.apply(this, arguments);
		if (this.captionColor && this.captionColor != Ext.menu.Item.prototype.captionColor) {
			this.el.setStyle("color", this.captionColor);
		}
		this.hideMenu();
	},

	expandMenu: function(autoActivate) {
		if (this.enabled && this.menu) {
			clearTimeout(this.hideTimer);
			delete this.hideTimer;
			if (!this.menu.isVisible() && !this.showTimer) {
				this.showTimer = this.deferExpand.defer(this.showDelay, this, [autoActivate]);
			} else if (this.menu.isVisible() && autoActivate) {
				this.menu.tryActivate(0, 1);
			}
		}
	},

	deferExpand: function(autoActivate) {
		delete this.showTimer;
		this.menu.show(this.container, this.parentMenu.subMenuAlign || "tl-tr?", this.parentMenu);
		if (autoActivate) {
			this.menu.tryActivate(0, 1);
		}
	},

	hideMenu: function() {
		clearTimeout(this.showTimer);
		delete this.showTimer;
		if (!this.hideTimer && this.menu && this.menu.isVisible()) {
			this.hideTimer = this.deferHide.defer(this.hideDelay, this);
		}
	},

	deferHide: function() {
		delete this.hideTimer;
		if (this.menu.over) {
			this.parentMenu.setActiveItem(this, false);
		} else {
			this.menu.hide();
		}
	},

	addSeparator: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({id:Ext.id()});
			this.menu.owner = this;
		}
		return this.menu.addSeparator();
	},

	addCaptionSeparator: function(caption, cfg) {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({id:Ext.id()});
			this.menu.owner = this;
		}
		return this.menu.addCaptionSeparator(caption, cfg);
	},

	removeAll: function() {
		if (!this.menu) {
			return;
		}
		this.menu.removeAll();
	},

	remove: function(item) {
		if (!this.menu) {
			return;
		}
		this.menu.remove(item);
	},

	addCaptionItem: function(id, caption, cfg) {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id()
			});
			this.menu.owner = this;
		}
		return this.menu.addCaptionItem(id, caption, cfg);
	},

	addCaptionItemTag: function(caption, cfg, tag) {
		this.tag = tag;
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({id:Ext.id()});
			this.menu.owner = this;
		}
		return this.menu.addCaptionItemTag(caption, cfg, tag);
	}
});

Ext.menu.CheckItem = function(config) {
	Ext.menu.CheckItem.superclass.constructor.call(this, config);
	this.addEvents(
		"beforecheckchange",
		"checkchange"
	);
	if (this.checkHandler) {
		this.on("checkchange", this.checkHandler, this.scope);
	}
	Ext.menu.MenuMgr.registerCheckable(this);
};

Ext.extend(Ext.menu.CheckItem, Ext.menu.Item, {
	itemCls: "x-menu-item x-menu-check-item",
	groupClass: "x-menu-group-item",
	checked: false,
	ctype: "Ext.menu.CheckItem",

	onRender: function(c) {
		Ext.menu.CheckItem.superclass.onRender.apply(this, arguments);
		this.hiddenFieldName = this.id + "_Checked";
		var formEl = Ext.get(document.forms[0]);
		this.hiddenFieldCheckedEl = Ext.get(formEl.createChild({
			tag: "input",
			type: "hidden",
			name: this.hiddenFieldName,
			id: this.hiddenFieldName
		}, undefined, true));
		if (this.group) {
			this.el.addClass(this.groupClass);
		}
		if (this.checked) {
			this.checked = false;
			this.setChecked(true, true);
		}
	},

	destroy: function() {
		Ext.destroy(this.hiddenFieldCheckedEl);
		Ext.menu.MenuMgr.unregisterCheckable(this);
		Ext.menu.CheckItem.superclass.destroy.apply(this, arguments);
	},

	setChecked: function(state, suppressEvent) {
		if (this.checked != state && this.fireEvent("beforecheckchange", this, state) !== false) {
			if (this.container) {
				this.container[state ? "addClass" : "removeClass"]("x-menu-item-checked");
			}
			this.checked = state;
			if (this.hiddenFieldCheckedEl) {
				this.hiddenFieldCheckedEl.dom.value = state ? "true" : "false";
			}
			if (suppressEvent !== true && (this.checked || !this.group || this.group == "")) {
				this.fireEvent("checkchange", this, state, this.tag);
				var parentMenu = this.parentMenu;
				var itemId = this.id;
				var itemIndex = parentMenu.items.items.indexOf(this);
				while (true) {
					this.handled = false;
					if (parentMenu.fireEvent("itemcheckchange", this, this, itemId, itemIndex) !== false) {
						this.handled = true;
					} else {
						break;
					}
					if (!parentMenu.parentMenu) {
						break;
					}
					parentMenu = parentMenu.parentMenu;
				}
			}
		}
	},

	handleClick: function(e) {
		if (this.enabled && !(this.checked && this.group)) {
			this.setChecked(!this.checked);
		}
		Ext.menu.CheckItem.superclass.handleClick.apply(this, arguments);
	}
});

Ext.menu.Adapter = function(component, config) {
	Ext.menu.Adapter.superclass.constructor.call(this, config);
	this.component = component;
};

Ext.extend(Ext.menu.Adapter, Ext.menu.BaseItem, {
	canActivate: true,

	onRender: function(container, position) {
		this.component.render(container);
		this.el = this.component.getEl();
	},

	activate: function() {
		if (!this.enabled) {
			return false;
		}
		this.component.focus();
		this.fireEvent("activate", this);
		return true;
	},

	deactivate: function() {
		this.fireEvent("deactivate", this);
	},

	disable: function() {
		this.component.disable();
		Ext.menu.Adapter.superclass.disable.call(this);
	},

	enable: function() {
		this.component.enable();
		Ext.menu.Adapter.superclass.enable.call(this);
	},

	destroy: function() {
		var component = this.component;
		if (component && component.destroy) {
			component.destroy();
		}
		Ext.menu.Adapter.superclass.destroy.call(this);
	},

	getPaddings: function() {
		return this.container.getPadding("lr");
	}

});

Ext.menu.ColorItem = function(config) {
	Ext.menu.ColorItem.superclass.constructor.call(this, new Terrasoft.ColorPalette(config), config);

	this.palette = this.component;
	this.relayEvents(this.palette, ["select"]);
	if (this.selectHandler) {
		this.on("select", this.selectHandler, this.scope);
	}
};

Ext.extend(Ext.menu.ColorItem, Ext.menu.Adapter);

Ext.menu.ColorMenu = function(config) {
	Ext.menu.ColorMenu.superclass.constructor.call(this, config);
	this.plain = true;
	var ci = new Ext.menu.ColorItem(config);
	this.add(ci);

	this.palette = ci.palette;

	this.relayEvents(ci, ["select"]);
};

Ext.extend(Ext.menu.ColorMenu, Ext.menu.Menu, {
	cls: "x-color-menu",
	enableScroll: false
});

Terrasoft.CalcMenu = function(config) {
	Terrasoft.CalcMenu.superclass.constructor.call(this, config);
	this.plain = true;
	this.allowOtherMenus = true;
	var calcMenuItem = new Terrasoft.CalcMenuItem(config);
	this.add(calcMenuItem);
	this.calculator = calcMenuItem.calculator;
	this.calculator.menu = this;
	this.on("hide", this.onHide);
};

Ext.extend(Terrasoft.CalcMenu, Ext.menu.Menu, {
	cls: "x-calc-menu",
	enableScroll: false,

	onHide: function() {
		if (this.calculator.inputBox) {
			if (!this.calculator.readOnly) {
				if (this.calculator.oldNumber != this.calculator.number) {
					this.calculator.oldNumber = this.calculator.number;
					this.calculator.inputBox.setValue(this.calculator.number, undefined, true);
				}
			}
			this.calculator.inputBox.focus.defer(10, this.calculator.inputBox);
		}
	}
});

Terrasoft.CalcMenuItem = function(config) {
	Terrasoft.CalcMenuItem.superclass.constructor.call(this, new Terrasoft.Calculator(config), config);
	this.calculator = this.component;
	this.calculator.on("render", function(calculator) {
		calculator.getEl().swallowEvent("click");
		calculator.container.addClass("x-menu-calc-item");
	});
};

Ext.extend(Terrasoft.CalcMenuItem, Ext.menu.Adapter, {
	hideOnClick: false,
	canActivate: false
});

Terrasoft.ColorItem = function(config) {
	Terrasoft.ColorItem.superclass.constructor.call(this, new Terrasoft.ColorPalette(config.palette), config);
	this.palette = this.component;
	this.relayEvents(this.palette, ["select"]);
	if (this.selectHandler) {
		this.on("select", this.selectHandler, this.scope);
	}
};

Ext.extend(Terrasoft.ColorItem, Ext.menu.Adapter);

Terrasoft.ColorMenu = function(config) {
	Terrasoft.ColorMenu.superclass.constructor.call(this, config);
	this.plain = true;
	var ci = new Terrasoft.ColorItem(config);
	this.add(ci);
	this.palette = ci.palette;
	//this.relayEvents(ci, ["select"]);
};

Ext.extend(Terrasoft.ColorMenu, Ext.menu.Menu);

Ext.override(Ext.menu.Menu, {

	lastTargetIn: function(cmp) {
		var el = cmp.getEl ? cmp.getEl() : cmp;
		return Ext.fly(el).contains(this.trg);
	}

	//TODO
	//Перекрытие этого метода ломает отображение меню,
	//но возможно он нужен, зачем пока не определили
	/*createEl: function() {
	var frm = document.body;
	if (document.forms.length > 0) {
	frm = document.forms[0];
	}
	return new Ext.Layer({
	cls: "x-menu",
	shadow: this.shadow,
	shim: this.shim || true,
	constrain: false,
	parentEl: this.parentEl || frm,
	zindex: 15000
	});
	}*/
});

Terrasoft.ElementMenuItem = function(cfg) {
	this.target = cfg.target;
	Terrasoft.ElementMenuItem.superclass.constructor.call(this, cfg);
};

Ext.extend(Terrasoft.ElementMenuItem, Ext.menu.BaseItem, {
	hideOnClick: false,
	itemCls: "x-menu-item",
	shift: true,

	getComponent: function() {
		if (Ext.isEmpty(this.el.id)) {
			return null;
		}
		var cmp = Ext.getCmp(this.el.id);
		if (Ext.isEmpty(cmp)) {
			return null;
		}
		return cmp;
	},

	// private

	onRender: function(container) {
		if (this.target.getEl) {
			this.el = this.target.getEl();
		} else {
			this.el = Ext.get(this.target);
		}
		var cmp = Ext.getCmp(this.el.id);
		this.parentMenu.on("show", function() {
			if (!Ext.isEmpty(cmp)) {
				if (cmp.doLayout) {
					cmp.doLayout();
				}
				if (cmp.syncSize) {
					cmp.syncSize();
				}
			}
		});
		if (Ext.isIE) {
			this.parentMenu.shadow = false;
			this.parentMenu.el.shadow = false;
			if (!Ext.isEmpty(cmp)) {
				cmp.shadow = false;
				cmp.el.shadow = false;
			}
		}
		if (this.shift) {
			this.el.applyStyles({ "margin-left": "23px" });
		}
		this.el.swallowEvent(["keydown", "keypress"]);
		Ext.each(["keydown", "keypress"], function(eventName) {
			this.el.on(eventName, function(e) {
				if (e.isNavKeyPress()) {
					e.stopPropagation();
				}
			}, this);
		}, this);
		if (Ext.isGecko) {
			container.removeClass("x-menu-list-item");
			container.setStyle({ width: "", height: "" });
			if (this.shift) {
				this.el.applyStyles({ "margin-left": "24px" });
			}
		}
		Terrasoft.ElementMenuItem.superclass.onRender.apply(this, arguments);
	},

	activate: function() {
		if (!this.enabled) {
			return false;
		}

		var cmp = this.getComponent();
		if (Ext.isEmpty(cmp)) {
			return false;
		}

		this.cmp.focus();
		this.fireEvent("activate", this);
		return true;
	},

	// private

	deactivate: function() {
		this.fireEvent("deactivate", this);
	},

	// private

	disable: function() {
		var cmp = this.getComponent();
		if (Ext.isEmpty(cmp)) {
			return;
		}
		this.cmp.disable();
		Terrasoft.ElementMenuItem.superclass.disable.call(this);
	},

	// private

	enable: function() {
		var cmp = this.getComponent();
		if (Ext.isEmpty(cmp)) {
			return;
		}
		this.cmp.enable();
		Terrasoft.ElementMenuItem.superclass.enable.call(this);
	}
});

Terrasoft.ComboMenuItem = function(config) {
	Terrasoft.ComboMenuItem.superclass.constructor.call(this, new Terrasoft.ComboBox(config.combobox), config);
	this.combo = this.component;
	this.addEvents("select");
	this.combo.on("render", function(combo) {
		combo.getEl().swallowEvent("click");
		combo.list.applyStyles("z-index:99999");
		combo.list.on("mousedown", function(e) {
			Ext.lib.Event.stopPropagation(e);
		});
	});
};

Ext.extend(Terrasoft.ComboMenuItem, Ext.menu.Adapter, {
	hideOnClick: false,

	onSelect: function(combo, record) {
		this.fireEvent("select", this, record);
		Terrasoft.ComboMenuItem.superclass.handleClick.call(this);
	},

	onRender: function(container) {
		Terrasoft.ComboMenuItem.superclass.onRender.call(this, container);
		if (Ext.isIE) {
			this.combo.list.shadow = false;
		}
		this.el.swallowEvent(["keydown", "keypress"]);
		Ext.each(["keydown", "keypress"], function(eventName) {
			this.el.on(eventName, function(e) {
				if (e.isNavKeyPress()) {
					e.stopPropagation();
				}
			}, this);
		}, this);
		if (Ext.isGecko) {
			container.setOverflow("auto");
			var containerSize = container.getSize();
			this.combo.wrap.setStyle("position", "fixed");
			container.setSize(containerSize);
		}
	}
});

Terrasoft.EditMenuItem = function(cfg) {
	cfg = cfg || {};
	var xtype = cfg.xtype || "textedit";
	var editor = Ext.ComponentMgr.create(cfg.config, xtype);
	if (cfg.value) {
		editor.setValue(cfg.value);
	}
	Terrasoft.EditMenuItem.superclass.constructor.call(this, editor, cfg);
	this.editor = this.component;
	this.editor.on("render", this.addEditorEvents, this);
};

Ext.extend(Terrasoft.EditMenuItem, Ext.menu.Adapter, {
	onRender: function(container) {
		Terrasoft.EditMenuItem.superclass.onRender.call(this, container);
		this.el.swallowEvent(["keydown", "keypress"]);
	},
	
	addEditorEvents: function(editor) {
		var el = editor.getEl();
		this.prepareEditor(editor);
		var primaryTrigger = editor.primaryToolButton;
		if (primaryTrigger) {
			var primaryTriggerEl = primaryTrigger.getEl();
			primaryTriggerEl.swallowEvent("click");
		}
		editor.keyNav = new Ext.KeyNav(el, {
			"esc": function(e) {
				this.parentMenu.hide();
			},
			"enter": function(e) {
				if (this.editor.validate()) {
					this.onClick(e);
				}
			},
			scope: this
		});
	},
	
	prepareEditor: function(editor) {
		if (editor instanceof Terrasoft.DateTimeEdit && (editor.kind == "date" || editor.kind == "datetime")) {
			editor.date.config = {
				parentMenu: this.parentMenu,
				hideParentsMenuOnClick: false
			};
		} else if (editor instanceof Terrasoft.IntegerEdit) {
			editor.el.on("click", this.onNumberEditClick, editor);
			editor.config = {
				parentMenu: this.parentMenu
			};
		} else if (editor instanceof Terrasoft.ColorEdit) {
			editor.el.on("click", this.onColorEditClick, editor);
			editor.config = {
				hideParentsMenuOnClick: false,
				parentMenu: this.parentMenu
			};
		}
	},
	
	onNumberEditClick: function(e) {
		if (this.calcMenu) {
			this.calcMenu.hide();
		}
	},
	
	onColorEditClick: function(e) {
		if (this.menu) {
			this.menu.hide();
		}
	}
	
});

Terrasoft.DateItem = function(config) {
	Terrasoft.DateItem.superclass.constructor.call(this, new Terrasoft.DatePicker(config), config);
	this.picker = this.component;
	this.picker.isMenu = true;
	this.addEvents("select");
	this.picker.on("render", function(picker) {
		picker.getEl().swallowEvent("click");
		picker.container.addClass("x-menu-date-item");
	});
	this.picker.on("select", this.onSelect, this);
};

Ext.extend(Terrasoft.DateItem, Ext.menu.Adapter, {
	onSelect: function(picker, date) {
		this.fireEvent("select", this, date, picker);
		Terrasoft.DateItem.superclass.handleClick.call(this);
	}
});

Terrasoft.DateMenu = function(config) {
	Terrasoft.DateMenu.superclass.constructor.call(this, config);
	this.plain = true;
	var di = new Terrasoft.DateItem(config);
	this.add(di);
	this.picker = di.picker;
	this.relayEvents(di, ["select"]);
};

Ext.extend(Terrasoft.DateMenu, Ext.menu.Menu, {
	cls: "x-date-menu",
	enableScroll: false,

	beforeDestroy: function() {
		this.picker.destroy();
	}
});

Terrasoft.DateMenuItem = function(config) {
	Terrasoft.DateMenuItem.superclass.constructor.call(this, new Terrasoft.Date(config.dateField), config);
	this.dateField = this.component;
	this.dateField.menu = new Terrasoft.DateMenu({
		allowOtherMenus: true
	});

	this.dateField.on("render", function(dateField) {
		dateField.getEl().swallowEvent("click");
	});
};

Ext.extend(Terrasoft.DateMenuItem, Ext.menu.Adapter, {
	hideOnClick: false,
	canActivate: false,

	onRender: function(container) {
		Terrasoft.DateMenuItem.superclass.onRender.call(this, container);
		this.el.swallowEvent(["keydown", "keypress"]);
		Ext.each(["keydown", "keypress"], function(eventName) {
			this.el.on(eventName, function(e) {
				if (e.isNavKeyPress()) {
					e.stopPropagation();
				}
			}, this);
		}, this);
		if (Ext.isGecko) {
			container.setOverflow("auto");
			var containerSize = container.getSize();
			this.dateField.wrap.setStyle("position", "fixed");
			container.setSize(containerSize);
		}
	}
});

Ext.menu.BaseItem.ControlDragSource = function (menuItem, cfg) {
	var el = menuItem.el;
	Ext.menu.BaseItem.ControlDragSource.superclass.constructor.call(this, el, cfg);
	if (menuItem.tag != "") {
		this.dragData.nodes = Ext.decode(menuItem.tag);
	}
	this.setHandleElId(el.id);
	this.invalidHandleTypes = {};
};

Ext.extend(Ext.menu.BaseItem.ControlDragSource, Ext.dd.DragSource);
/* jshint ignore:end */