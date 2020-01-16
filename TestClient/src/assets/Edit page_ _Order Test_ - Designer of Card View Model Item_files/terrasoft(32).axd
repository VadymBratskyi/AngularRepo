Terrasoft.MultiLevelTabs = Ext.extend(Ext.LayoutControl, {
	autoEl: 'div',
	isContainer: false,
	enableTabScroll: true,
	tabMargin: 3,
	resizeTabs: false,
	scrollIncrement: 0,
	width: 300,
	scrollRepeatInterval: 400,
	scrollDuration: .35,
	animScroll: true,
	firstLevelStripHeight: 33,
	wheelIncrement: 20,
	multiLevelMode: true,
	tabPosition: 'top',
	tabsGroupsOrderPosition: "default",
	collapsible: true,
	closeable: true,
	toolsLayout: null,
	hasOptionsButton: true,
	hasSettingsButton: true,
	hasHelpButton: true,

	setActiveTabId: function (activeTabId) {
		this.activeTabId = activeTabId;
	},

	getActiveTabId: function () {
		if (!this.rendered) {
			return this.activeTabId;
		}
		return this.hiddenField.value;
	},

	initComponent: function () {
		Terrasoft.MultiLevelTabs.superclass.initComponent.call(this);
		this.addEvents(
			'itemclick',
			'toollinkclick',
			'beforetabchange',
			'tabchange',
			'firstleveltabchange',
			'addtabclick',
			'optionstoolclick',
			'collapsetoolclick',
			'closetoolclick',
			'settingstoolclick',
			'helptoolclick'
		);
		this.strips = {};
		if (this.tabsConfig) {
			this.tabs = this.initTabs(this.tabsConfig, this);
			Ext.each(this.tabs, this.initTab, this);
			delete this.tabsConfig;
		} else {
			this.tabs = [];
		}
	},

	initTab: function (tab, i) {
		this.convertTabToMenu(tab, 0);
		if (tab.menu && (!tab.menu.hasListener('itemclick') || (tab.showMenuItemCaption && this.multiLevelMode))) {
			tab.menu.on("itemclick", tab.onMenuItemClick, tab);
		}
	},

	checkForCheckedMenuItem: function (tab, items) {
		Ext.each(items, function (item, i) {
			if (item.checked) {
				tab.onMenuItemClick(item);
				return false;
			}
			if (item.menu && item.menu.items && item.menu.items.items.length > 0) {
				var menuItems = item.menu.items.items;
				if (!this.checkForCheckedMenuItem(tab, menuItems)) {
					return false;
				}
			}
		}, this);
	},

	checkTabsForCheckedMenuItems: function (tabs) {
		Ext.each(tabs, function (tab, i) {
			if (tab.showMenuItemCaption) {
				if (tab.menu && tab.menu.items && tab.menu.items.items.length > 0) {
					var menuItems = tab.menu.items.items;
					if (this.checkForCheckedMenuItem(tab, menuItems)) {
						this.resetTabCaption(tab);
					}
				}
				if (tab.tabs && tab.tabs.length > 0) {
					this.checkTabsForCheckedMenuItems(tab.tabs);
				}
			}
		}, this);
		return true;
	},

	initTabs: function (tabsConfig, parent) {
		var tabs = [];
		tabsConfig = tabsConfig || [];
		var ownerCt = parent;
		Ext.each(tabsConfig, function (tab, i) {
			var initializedTab =
				Ext.ComponentMgr.create(Ext.apply(tab, { ownerCt: ownerCt }), 'tabheader');
			initializedTab.imageConfig = tab.imageConfig || (tab.tag ? tab.tag.imageConfig : undefined);
			tabs.push(initializedTab);
			initializedTab.ownerCt = parent;
			initializedTab.tabs = this.initTabs(initializedTab.tabsConfig, initializedTab);
			delete initializedTab.tabsConfig;
		}, this);
		return tabs;
	},

	onOptionsButtonClick: function (e, tab) {
		if (this.enabled) {
			this.showContextMenu(e, tab);
		}
	},
	
	showContextMenu: function (e, tab) {
		var menu = this.generateContextMenuItems(tab);
		var x = Ext.lib.Event.getPageX(e);
		var y = Ext.lib.Event.getPageY(e);
		menu.showAt([x, y]);
		e.stopEvent();
	},

	generateContextMenuItems: function (targetTab) {
		var activeTabId = this.getActiveTabId();
		var items;
		var targetMenu = new Ext.menu.Menu({ id: Ext.id() });
		var i;
		if (targetTab.isFirstLevel == false) {
			items = targetTab.strip.tabs.slice(0);
		} else {
			items = this.tabs.slice(0);
			var tabCount = items.length;
			for (i = 0; i < tabCount; ++i) {
				if (items[i].isActive()) { 
					activeTabId = items[i].id;
					break;
				}
			}
		}
		var compare = function(a, b) {
			if (a.caption > b.caption) {
				return 1;
			}
			if (a.caption < b.caption) {
				return -1;
			}
			return 0;
		};
		items.sort(compare);
		var orderedGroups = this.tabsGroupsOrderPosition.split(';');
		for (var j = 0; j < orderedGroups.length; j++) {
			var groupItemsCount = 0;
			for (i = 0; i < items.length; i++) {
				var item = items[i];
				if (item.visible === false || item.groupName != orderedGroups[j]) {
					continue;
				}
				var cfg = {};
				cfg.id = Ext.id();
				var itemCaption = item.caption;
				var captionLength = itemCaption.length;
				cfg.caption = (itemCaption.substring(captionLength - 1, captionLength) == ":") ? 
					itemCaption.substring(0, captionLength - 1) :
					itemCaption;
				cfg.disabled = item.disabled;
				cfg.tabToShow = item;
				cfg.scope = this;
				cfg.group = 'tabs';
				cfg.isVirtual = true;
				if ((item.tabHeader && item.tabHeader.hidden === true) || (item.hidden === true)) {
					cfg.hidden = true;
				}
				cfg.checked = (item.id == activeTabId);
				targetMenu.addItem(new Ext.menu.CheckItem(cfg));
				groupItemsCount++;
			}
			if (groupItemsCount > 0) {
				targetMenu.addSeparator({isVirtual: true});
			}
		}
		targetMenu.on('click', function(menu, menuitem, event) { 
			this.showTabFromMenu(menuitem);
		}, this);
		return targetMenu;
	},

	showTabFromMenu: function (menuItem) {
		this.setActiveTab(menuItem.tabToShow);
	},

	insertTab: function (index, tab, activate) {
		var strip = this.strips[this.id];
		if (index == -1) {
			if (!this.tabs) {
				this.tabs = [];
				strip.tabs = this.tabs;
			}
			this.tabs.push(tab);
		} else {
			this.tabs.splice(index, 0, tab);
			if (index + 1 < this.tabs.length) {
				tab.beforeTab = this.tabs[index + 1].el;
			}
		}
		tab.strip = strip;
		tab.ownerCt = this;
		tab.isFirstLevel = true;
		tab.on('click', this.onTabClick, this);
		if (!tab.tabs) {
			tab.tabs = [];
		}
		if (!strip.edge) {
			tab.render(strip.stripUlEl);
			strip.edge = strip.stripUlEl.createChild({
				tag: 'li',
				cls: 'x-tab-edge'
			});
			strip.rendered = true;
		} else {
			tab.render(strip.stripUlEl);
			var clickEl = tab.el;
			clickEl.on('contextmenu', function (e) {
				if (e.button == 2 || (Ext.isIE && e.button == -1)) {
					if (e.ctrlKey === true) {
						return;
					}
					e.preventDefault();
					this.onOptionsButtonClick(e, tab);
				}
			}, this);
		}
		this.resizeStripUlEl();
		if (activate === true) {
			this.setActiveTab(tab, false);
		}
		if (!this.multiLevelMode) {
			this.recreateToolButtons(strip);
		}
	},

	insert: function (index, item, activate) {
		if (item instanceof Terrasoft.TabHeader) {
			this.insertTab(index, item, activate);
		} else {
			var toolsLayout = this.toolsLayout;
			if (index == -1) {
				toolsLayout.add(item, activate);
			} else {
				toolsLayout.insert(index, item, activate);
			}
			this.delegateUpdates(toolsLayout.strip);
		}
	},

	resizeStripUlEl: function () {
		for (var stripEl in this.strips) {
			var strip = this.strips[stripEl];
			if (strip.stripWrap.dom.scrollLeft != 0) {
				strip.stripWrap.dom.scrollLeft = 0;
			}
			if (strip.isActive == true || strip.el.hasClass('x-tab-strip-first-level')) {
				var width = 0;
				Ext.each(strip.tabs, function (tab, i) {
					width += tab.el.getWidth();
					width += this.tabMargin;
				}, this);
				width += this.tabMargin * 2 + 200;
				strip.stripUlEl.setStyle('width', width + 'px');
				this.delegateUpdates(strip);
			}
		}
	},

	insertInnerTab: function (index, tabOwner, tab, activate) {
		if (!tab.tabs) {
			tab.tabs = [];
		}
		if (tabOwner.strip && tabOwner.strip.activeTab != tabOwner) {
			this.setActiveTab(tabOwner, false);
		}
		var createStrip = false;
		if (tabOwner.tabs.length == 0) {
			createStrip = true;
			tabOwner.tabs = [];
		}
		if (index == -1) {
			tabOwner.tabs.push(tab);
		} else {
			tabOwner.tabs.splice(index, 0, tab);
			if (index + 1 < tabOwner.tabs.length) {
				tab.beforeTab = tabOwner.tabs[index + 1].el;
			}
		}
		tab.ownerCt = tabOwner;
		tab.isFirstLevel = (tabOwner == this);
		this.setFirstLevelActive(tab);
		if (tabOwner.isFirstLevel || tab.isFirstLevel) {
			this.recreateMenu(tab);
			var strip;
			if (createStrip) {
				strip = this.strips[tabOwner.id] = {};
				strip.tabs = tabOwner.tabs;
				strip.isActive = true;
				this.renderStrip(strip, false);
			} else {
				strip = this.strips[tabOwner.id];
				tab.strip = strip;
				strip.isActive = true;
				strip.tabs = tabOwner.tabs;
				tab.render(strip.stripUlEl);
				tab.on('click', this.onTabClick, tabOwner.ownerCt);
				if (tab.isFirstLevel && tab.tabs.length > 0) {
					strip.isActive = false;
					var innerStrip = this.strips[tab.id] = {};
					Ext.each(tab.tabs, function (t, i) {
						t.rendered = false;
					}, this);
					innerStrip.tabs = tab.tabs;
					innerStrip.isActive = true;
					this.renderStrip(innerStrip, false);
				}
			}
		} else {
			this.recreateMenu(tabOwner);
		}
		this.resizeStripUlEl();
		if (tab.isFirstLevel) {
			this.setActiveTab(tab, false);
		}
	},

	moveControl: function (tab, position) {
		tab.ownerCt.tabs.remove(tab);
		if (tab.ownerCt.isFirstLevel !== true && tab.ownerCt.menuEl && tab.ownerCt.tabs.length == 0) {
			Ext.destroy(tab.ownerCt.menuEl);
			tab.ownerCt.el.removeClass('x-tab-with-menu');
		}
		if (!tab.isFirstLevel) {
			if (tab.strip && tab.strip.tabs.length == 0) {
				Ext.destroy(tab.strip.el);
			}
		}
		var el = tab.el ? Ext.getDom(tab.el) : undefined;
		tab.rendered = false;
		if (tab.isFirstLevel) {
			this.insert(position, tab, false);
		} else {
			this.insertInnerTab(position, this, tab, true);
		}
		var newEl = Ext.getDom(tab.el);
		if (newEl && el && newEl.parentNode) {
			newEl.parentNode.removeChild(el);
		}
		if (!this.multiLevelMode) {
			this.recreateToolButtons(tab.strip);
		}
	},

	clearMenu: function (menu) {
		if (!menu) {
			return;
		}
		var items = menu.items.items;
		var length = items.length;
		var k = 0, i = 0;
		while (true) {
			if (i >= length) {
				break;
			}
			var item = items[k];
			if (item.menu && item.menu.items.items && item.menu.items.items.length > 0) {
				this.clearMenu(item.menu);
			}
			if (!item.realmenu) {
				items.remove(item);
			} else {
				k = k + 1;
			}
			i = i + 1;
		};
	},

	recreateMenu: function (t) {
		var tabs = this.tabs;
		for (var i = 0, length = tabs.length; i < length; i++) {
			var tab = tabs[i];
			this.clearMenu(tab.menu);
			this.convertTabToMenu(tab, 0);
			if (tab.menu && !tab.menu.hasListener('itemclick')) {
				tab.menu.on("itemclick", tab.onMenuItemClick, tab);
			}
		}
		t.createMenu();
	},

	onContentChanged: function () {
		this.onResize();
	},

	setVirtualCheck: function (item, items) {
		Ext.each(items, function (it) {
			if (it.checked) {
				it.checked = false;
				return false;
			}
			if (it.menu && it.menu.items && it.menu.items.lenght > 0) {
				if (!this.setVirtualCheck(null, it.menu.items)) {
					return false;
				}
			}
		}, this);
		if (item) {
			item.checked = true;
		}
	},

	fillMenuFromTabs: function (tab, tabs) {
		var menu = new Ext.menu.Menu({ id: Ext.id(), shadow: 'simple x-header' });
		// if (this.multiLevelMode) {
		//	 menu.fxFunction = 'slideIn';
		// }
		Ext.each(tabs, function (itab, i) {
			itab.isTab = true;
			var menuitems = this.fillMenuFromTabs(itab, itab.tabs);
			if (itab.menu && itab.menu.items && itab.menu.items.length > 0) {
				Ext.each(itab.menu.items.items, function (iTabMenuItem, i) {
					var menuItem;
					if (iTabMenuItem.menu && iTabMenuItem.menu.items && iTabMenuItem.menu.items.length > 0) {
						menuItem = new Ext.menu.Item({
							caption: iTabMenuItem.caption,
							menu: iTabMenuItem.menu,
							realmenu: true
						});
					}
					else {
						menuItem = new Ext.menu.Item({
							caption: iTabMenuItem.caption,
							realmenu: true
						});
					}
					menuitems.addItem(menuItem);
				});
			}
			var options = {
				caption: itab.caption,
				id: itab.id,
				tag: itab.tag,
				imageConfig: itab.imageConfig
			};
			if (menuitems.items.length > 0) {
				options.menu = menuitems;
			}
			menu.addItem(new Ext.menu.Item(options));
		}, this);
		if (menu.items.length > 0) {
			Ext.each(menu.items.items, function (item) {
				item.on('click', function (it) {
					this.setVirtualCheck(it, menu.items.items);
					menu.tab.onMenuItemClick(it);
					this.resizeStripUlEl();
				}, this);
			}, this);
		}
		menu.on("itemclick", function (el, e) {
			this.fireEvent('itemclick', this, el, el.tag);
		}, this);
		return menu;
	},

	setMultiLevelMode: function (isMultiLevel) {
		this.multiLevelMode = isMultiLevel;
	},

	convertTabToMenu: function (tab, level) {
		var tabs = tab.tabs;
		if (level == 0) {
			for (var i = 0, length = tabs.length; i < length; i++) {
				this.convertTabToMenu(tabs[i], level + 1);
			}
		} else {
			tab.menu = this.fillMenuFromTabs(tab, tabs);
			tab.menu.tab = tab;
		}
	},

	recreateToolButtons: function (strip, forceOptionsToolbuttonVisible) {
		strip.toolsWidth = 5;
		if (strip.closeButton) {
			strip.closeButton.remove();
			delete strip.closeButton;
		}
		if (strip.optionsButton) {
			strip.optionsButton.remove();
			delete strip.optionsButton;
		}
		if (strip.toggleCollapseButton) {
			strip.toggleCollapseButton.remove();
			delete strip.toggleCollapseButton;
		}
		if (strip.addTabButton) {
			strip.addTabButton.remove();
			delete strip.addTabButton;
		}
		this.initOneLevelTabsTools(strip, forceOptionsToolbuttonVisible);
		this.delegateUpdates(strip);
	},

	initOneLevelTabsTools: function (strip, forceOptionsToolbuttonVisible) {
		if (this.closeable) {
			this.createCloseToolButton(strip);
		}
		if (this.collapsible) {
			this.createCollapsibleToolButton(strip);
		}
		if (this.hasOptionsButton && (forceOptionsToolbuttonVisible === true || strip.tabs.length > 1)) {
			this.createOptionsToolButton(strip);
		}
		if (this.hasAddTabButton) {
			this.createAddTabButton(strip);
		}
	},

	onToolsLayoutChange: function () {
		var toolsLayout = this.toolsLayout;
		var strip = toolsLayout.strip;
		var toolsWidth = this.getToolsLayoutWidth();
		strip.toolsWidth = toolsWidth;
		var scrollRight = toolsLayout.strip.scrollRight;
		scrollRight && scrollRight.setStyle('right', toolsWidth + 'px');
		toolsLayout.setWidth(toolsWidth);
		if (this.rendered) {
			this.onContentChanged();
		}
	},

	getToolsLayoutWidth: function() {
		var toolsLayout = this.toolsLayout;
		var toolsItems = toolsLayout.items.items;
		var itemsLength = toolsItems.length;
		var lastItem;
		for (var i = itemsLength - 1; i >=0; i--) {
			var item = toolsItems[i];
			if (item.hidden != true) {
				lastItem = item;
				break;
			}
		}
		var toolsWidth = 0;
		if (lastItem) {
			var lastItemWidth = lastItem.getWidth();
			var lastItemLeft = lastItem.processSizeUnit(lastItem.getResizeEl().getStyle('left'));
			var layoutRightPadding = toolsLayout.layout.padding.right;
			var toolsEl = toolsLayout.getResizeEl();
			var toolsLayoutPaddingLeft = lastItem.processSizeUnit(toolsEl.getStyle('paddingLeft'));
			var toolsLayoutPaddingRight = lastItem.processSizeUnit(toolsEl.getStyle('paddingRight'));
			var toolsLayoutPaddings = toolsLayoutPaddingRight + toolsLayoutPaddingLeft;
			toolsWidth = lastItemWidth + lastItemLeft + layoutRightPadding + toolsLayoutPaddings;
		}
		return toolsWidth;
	},

	renderStrip: function (strip, isFirstLevel) {
		var levelCls = (isFirstLevel === true) ? 'x-tab-strip-first-level' :
			'x-tab-strip-second-level';
		var stabStrip = this.stabStrip;
		if (stabStrip) {
			stabStrip.remove();
			delete this.stabStrip;
		}
		var el = this.el.createChild({
			cls: 'x-strip ' + levelCls
		});
		strip.el = el;
		strip.toolsWidth = 5;
		if (this.multiLevelMode) {
			if (isFirstLevel) {
				var toolsConfig = this.toolsConfig;
				var i;
				if (toolsConfig) {
					for (i = 0; i < toolsConfig.length; i++) {
						var control = toolsConfig[i];
						if (control.xtype == 'label') {
							control.autoWidth = true;
						}
					}
				}
				var toolsLayout = this.toolsLayout = new Terrasoft.ControlLayout({
					id: this.id + '_tools',
					edges: '0 0 0 0',
					style: 'right: 0px; position: absolute',
					displayStyle: 'topbar',
					items: toolsConfig,
					startNewAlignGroup: true
				});
				toolsLayout.strip = strip;
				toolsLayout.render(strip.el);
				var toolsEl = toolsLayout.getResizeEl();
				var toolsWidth = this.getToolsLayoutWidth();
				strip.toolsWidth = toolsWidth;
				toolsLayout.suspendEvents();
				toolsLayout.setWidth(toolsWidth);
				toolsEl.setStyle('padding', '0px');
				toolsEl.setStyle('background', 'transparent');
				toolsLayout.layout.innerCt.setStyle('background', 'transparent');
				toolsLayout.resumeEvents();
				toolsLayout.setHeight('32px');
				toolsLayout.on('contentchanged', this.onToolsLayoutChange, this);
				toolsLayout.on('afterlayout', this.onToolsLayoutChange, this);
				toolsLayout.on('add', function () {
					toolsLayout.doLayout();
				}, this);
			}
		} else {
			this.initOneLevelTabsTools(strip);
		}
		strip.stripWrap = el.createChild({
			cls: 'x-tab-strip-wrap'
		});
		strip.stripUlEl = strip.stripWrap.createChild({
			tag: 'ul',
			cls: 'x-tab-strip x-tab-strip-' + this.tabPosition
		});
		var beforeEl = (this.tabPosition == 'bottom' ? strip.stripWrap : null);
		strip.stripSpacer = el.createChild({
			cls: 'x-tab-strip-spacer'
		}, beforeEl);
		strip.stripUlEl.createChild({ cls: 'x-clear' });
		if (!strip.tabs) {
			return;
		}
		Ext.each(strip.tabs, function (tab) {
			tab.strip = strip;
			tab.isFirstLevel = isFirstLevel;
			tab.on('click', this.onTabClick, this);
			tab.on('hide', this.onTabHide, this);
			tab.render(strip.stripUlEl);
			var clickEl = tab.el;
			clickEl.on('contextmenu', function (e) {
				if (e.button == 2 || (Ext.isIE && e.button == -1)) {
					if (e.ctrlKey === true) {
						return;
					}
					e.preventDefault();
					this.onOptionsButtonClick(e, tab);
				}
			}, this);
		}, this);
		strip.edge = strip.stripUlEl.createChild({
			 tag: 'li',
			 cls: 'x-tab-edge'
		});
		strip.rendered = true;
	},

	onTabHide: function (tab) {
		if (tab == tab.strip.activeTab) {
			var tabs = this.tabs;
			var tabIndex = tabs.indexOf(tab);
			tabIndex++;
			if (tabIndex < tabs.length) {
				this.setActiveTabIndex(tabIndex);
			} else {
				var activeTab = this.getLastVisibleTab();
				if (activeTab) {
					this.setActiveTab(activeTab);
				}
			}
		}
	},

	closeToolClick: function () {
		this.fireEvent('closetoolclick', this, {});
	},

	createCloseToolButton: function (strip) {
		strip.closeButton = strip.el.insertFirst({
			cls: 'x-tool-tab-panel-close'
		});
		strip.closeButton.addClassOnOver('x-tool-tab-panel-close-over');
		strip.closeButton.setStyle('right', strip.toolsWidth.toString() + 'px');
		strip.closeButton.on('click', this.closeToolClick, this);
		strip.toolsWidth += strip.closeButton.getWidth();
	},

	collapseToolClick: function () {
		this.fireEvent('collapsetoolclick', this, {});
	},

	createCollapsibleToolButton: function (strip) {
		strip.toggleCollapseButton = strip.el.insertFirst({
			cls: 'x-tool-tab-panel-collapse'
		});
		strip.toggleCollapseButton.addClassOnOver('x-tool-tab-panel-collapse-over');
		strip.toggleCollapseButton.setStyle('right', strip.toolsWidth.toString() + 'px');
		strip.toggleCollapseButton.on('click', this.collapseToolClick, this);
		strip.toolsWidth += strip.toggleCollapseButton.getWidth();
	},

	optionsToolClick: function (e) {
		this.fireEvent('optionstoolclick', e);
	},

	createOptionsToolButton: function (strip) {
		strip.optionsButton = strip.el.insertFirst({
			cls: 'x-tool-tab-panel-options'
		});
		strip.optionsButton.addClassOnOver('x-tool-tab-panel-options-over');
		strip.optionsButton.setStyle('right', strip.toolsWidth.toString() + 'px');
		strip.optionsButton.on('click', this.optionsToolClick, this);
		strip.toolsWidth += strip.optionsButton.getWidth();
	},

	addToolClick: function (e) {
		this.fireEvent('addtabclick', e);
	},

	createAddTabButton: function (strip) {
		strip.addTabButton = strip.el.insertFirst({
			cls: 'x-tool-tab-panel-addtab'
		});
		strip.addTabButton.addClassOnOver('x-tool-tab-panel-addtab-over');
		strip.addTabButton.setStyle('right', strip.toolsWidth.toString() + 'px');
		strip.addTabButton.on('click', this.addToolClick, this);
		strip.toolsWidth += strip.addTabButton.getWidth();
	},

	endUpdate: function () {
		// TODO: разобраться - нуже этот метод?
		this.delegateUpdates();
	},

	onResize: function () {
		Terrasoft.MultiLevelTabs.superclass.onResize.apply(this, arguments);
		for (var stripEl in this.strips) {
			var strip = this.strips[stripEl];
			if (strip.stripWrap.dom.scrollLeft != 0) {
				strip.stripWrap.dom.scrollLeft = 0;
			}
			if (strip.tabs && strip.tabs.length > 0 && (strip.isActive == true || strip.el.hasClass('x-tab-strip-first-level'))) {
				var pos = this.getScrollPos(strip);
				var sw = this.getScrollWidth(strip) - this.getScrollArea(strip);
				var s = Math.max(0, Math.min(sw, pos));
				if (s != pos) {
					this.scrollTo(strip, s, false);
				}
				this.delegateUpdates(strip);
			}
		}
		this.resizeStripUlEl();
	},

	findTabById: function (tabs, id, parent, level) {
		var findTab;
		if (!tabs) {
			return null;
		}
		if (!level) {
			level = 0;
		}
		for (var i = 0; i < tabs.length; i++) {
			var tab = tabs[i];
			if (tab.id == id) {
				if (level > 1) {
					findTab = parent;
					findTab.realTab = tab;
				} else {
					findTab = tab;
				}
				break;
			} else {
				if (level == 1) {
					parent = tab;
				}
				var tabInner = this.findTabById(tab.tabs, id, parent, level + 1);
				if (tabInner) {
					if (level > 1) {
						return tab;
					} else {
						return tabInner;
					}
				}
			}
		}
		return findTab;
	},

	onRender: function (ct, position) {
		Terrasoft.MultiLevelTabs.superclass.onRender.call(this, ct, position);
		var el = this.el;
		el.addClass('x-multi-level-tabs');
		var multiLevelMode = this.multiLevelMode;
		el.addClass(multiLevelMode ? 'x-multi-level-mode' : 'x-one-level-mode');
		var firstLevelStrip = this.strips[this.id] = {};
		firstLevelStrip.tabs = this.tabs;
		this.renderStrip(firstLevelStrip, true);
		if (this.tabs.length == 0 && multiLevelMode) {
			var stabStrip = this.stabStrip = el.createChild({
				cls: 'x-strip x-tab-strip-first-level'
			});
			stabStrip.setHeight(this.firstLevelStripHeight + 'px');
		}
		this.hiddenName = this.id + '_ActiveTab';
		this.hiddenField = this.el.insertSibling({
			tag: 'input',
			type: 'hidden',
			name: this.hiddenName,
			id: (this.hiddenId || this.hiddenName)
		}, 'before', true);
		this.hiddenField.value = '';
		if (this.activeTabId != undefined) {
			this.activeTabId = this.activeTabId.toString();
		}
		var tab;
		if (this.activeTabId && this.activeTabId != '') {
			tab = this.findTabById(this.tabs, this.activeTabId);
			if (tab) {
				if (tab.isFirstLevel) {
					this.setActiveTab(tab);
				} else {
					this.setActiveTab(tab.ownerCt, false, false);
					this.setActiveTab(tab, true, false);
				}
			}
		} else {
			if (this.tabs.length > 0) {
				tab = this.getFirstVisibleTab();
				if (tab) {
					this.setActiveTab(tab);
				}
			}
		}
		if (!multiLevelMode) {
			var isPrimary = this.isPrimary;
			if (isPrimary) {
				this.setPrimary(isPrimary);
			}
			var isImportant = this.isImportant;
			if (isImportant) {
				this.setImportant(isImportant);
			}
		}
		this.delegateUpdates(firstLevelStrip);
		this.checkTabsForCheckedMenuItems(this.tabs);
	},

	getFirstVisibleTab: function () {
		var tabs = this.tabs;
		var tabsLength = tabs.length;
		for (var i = 0; i < tabsLength; i++) {
			var tabHeader = tabs[i];
			if (tabHeader.hidden === false) {
				return tabHeader;
			}
		}
		return null;
	},

	getLastVisibleTab: function () {
		var tabs = this.tabs;
		var tabsLength = tabs.length;
		for (var i = tabsLength - 1; i >= 0; i--) {
			var tabHeader = tabs[i];
			if (tabHeader.hidden === false) {
				return tabHeader;
			}
		}
		return null;
	},

	setImportant: function (isImportant) {
		this.el[isImportant === true ? 'addClass' : 'removeClass']('x-highlight-important');
	},

	setPrimary: function (isPrimary) {
		this.el[isPrimary === true ? 'addClass' : 'removeClass']('x-mark-main');
	},

	deferTabChange: function (fn, scope, delay) {
		this.clearTabInterval(this);
		this.tabInterval = setTimeout(function () { fn(scope); }, delay);
	},

	clearTabInterval: function (scope) {
		clearTimeout(scope.tabInterval);
		scope.tabInterval = 0;
	},

	onTabClick: function (tab, e) {
		e.stopEvent();
		var tabChangeDelay = this.tabChangeDelay;
		var tabInterval = this.tabInterval;
		if (tabChangeDelay > 0 && tabInterval && tabInterval !== 0) {
			return;
		}
		if (this.setActiveTab) {
			this.setActiveTab(tab, this.multiLevelMode && tab.showMenuItemCaption !== false);
		}
		if (tabChangeDelay > 0) {
			this.deferTabChange(this.clearTabInterval, this, tabChangeDelay);
		}
	},

	selectControl: function (item, fireEvent) {
		if (item instanceof Terrasoft.TabHeader) {
			if (item.strip) {
				if (this.setActiveTab) {
					this.setActiveTab(item);
				}
			}
		}
	},

	setActiveTabIndex: function (index) {
		var tab = this.tabs[index];
		if (index < 0 || index >= this.tabs.length) {
			return;
		}
		if (tab.hidden) {
			return;
		}
		this.setActiveTab(tab);
		return tab;
	},

	setActiveTab: function (tab, withoutEvent, isMenuShow) {
		if (tab.hidden === true) {
			return;
		}
		if (tab.strip && tab.strip.activeTab == tab) {
			tab.setActive(true);
			return tab;
		}
		var previousTab = null;
		var strip;
		if (tab.isFirstLevel) {
			for (var stripEl in this.strips) {
				strip = this.strips[stripEl];
				if (strip.isActive == true && strip != this.strips[this.id]) {
					strip.el.setStyle('display', 'none');
					strip.isActive = false;
					break;
				}
			}
		} else {
			if (tab.strip && tab.strip.activeTab) {
				previousTab = tab.strip.activeTab;
			}
			if (!withoutEvent) {
				if (this.fireEvent('beforetabchange', this, tab, previousTab) === false) {
					return tab;
				}
			}
		}
		tab.setActive(true);
		if (tab.strip) {
			if (tab.strip.activeTab != tab) {
				if (tab.strip.activeTab) {
					if (!this.isParentTab(tab, tab.strip.activeTab)) {
						tab.strip.activeTab.setActive(false);
					}
				}
				tab.strip.activeTab = tab;
				this.scrollToTab(tab.strip, tab, withoutEvent ? false : this.animScroll);
			}
		}
		var tabs = tab.tabs;
		if (tabs && tab.isFirstLevel && !this.strips[tab.id] && (tab.tabs.length > 0 || !this.designMode)) {
			if (this.multiLevelMode) {
				strip = this.strips[tab.id] = {};
				strip.tabs = tabs;
				strip.isActive = true;
				this.renderStrip(strip, false);

				// TODO: определить свойства вместо tag для логики активации вкладки
				/*
				if (this.beforeTag) {
				Ext.each(strip.tabs, function(t) {
				if (this.beforeTag == t.tag && t.tag && t.tag != '') {
				this.setActiveTab(t, false);
				return false;
				}
				}, this);
				}
				*/
			}
		} else {
			strip = this.strips[tab.id];
			if (tab.isFirstLevel && strip && strip.el) {
				strip.el.setStyle('display', 'block');
				strip.isActive = true;
				this.scrollToTab(strip, strip.activeTab, false);
			}
		}
		this.delegateUpdates(strip);
		if (this.rendered && (this.beforeTag != tab.tag || !tab.tag)) {
			this.hiddenField.value = tab.id;
		}
		this.beforeTag = tab.tag;
		var firstlevelChange = tab.isFirstLevel && this.multiLevelMode;
		if (!withoutEvent) {
			this.fireEvent(firstlevelChange ? 'firstleveltabchange' : 'tabchange', this, tab, tab.tag);
		}
		if (this.multiLevelMode && tab.showMenuItemCaption) {
			tab.showTabHeaderMenu(isMenuShow);
		}
		return tab;
	},

	isParentTab: function (tabCheck, tabCheckOwner) {
		if (tabCheck.ownerCt && tabCheck.tabs) {
			if (tabCheck.ownerCt == tabCheckOwner) {
				return true;
			} else {
				return this.isParentTab(tabCheck.ownerCt, tabCheckOwner);
			}
		} else {
			return false;
		}
	},

	setFirstLevelActive: function (tab) {
		if (tab.isFirstLevel) {
			return;
		} else {
			if (tab.ownerCt.isFirstLevel) {
				this.setActiveTab(tab.ownerCt, false);
			} else {
				this.setFirstLevelActive(tab.ownerCt);
			}
		}
	},

	createScrollers: function (strip) {
		var h = strip.stripWrap.dom.offsetHeight;
		var sl = strip.el.insertFirst({
			cls: 'x-tab-scroller-left'
		});
		sl.addClassOnOver('x-tab-scroller-left-over');
		strip.leftRepeater = new Ext.util.ClickRepeater(sl, {
			interval: this.scrollRepeatInterval,
			handler: function () { this.onScrollLeft(strip); },
			scope: this
		});
		strip.scrollLeft = sl;
		var sr = strip.el.insertFirst({
			cls: 'x-tab-scroller-right'
		});
		sr.addClassOnOver('x-tab-scroller-right-over');
		strip.rightRepeater = new Ext.util.ClickRepeater(sr, {
			interval: this.scrollRepeatInterval,
			handler: function () { this.onScrollRight(strip); },
			scope: this
		});
		sr.setStyle('right', strip.toolsWidth.toString() + 'px');
		strip.scrollRight = sr;
	},

	getScrollWidth: function (strip) {
		var pos = this.getScrollPos(strip);
		return strip.tabs.length == 0 ? pos : strip.edge.getOffsetsTo(strip.stripWrap)[0] + pos;
	},

	getScrollPos: function (strip) {
		return parseInt(strip.stripWrap.dom.scrollLeft, 10) || 0;
	},

	getScrollArea: function (strip) {
		return parseInt(strip.stripWrap.dom.clientWidth, 10) || 0;
	},

	getScrollAnim: function (strip) {
		return { duration: this.scrollDuration, callback: function () { this.updateScrollButtons(strip); }, scope: this };
	},

	getScrollIncrement: function () {
		return this.scrollIncrement || (this.resizeTabs ? this.lastTabWidth + 2 : 100);
	},

	scrollToTab: function (strip, tab, animate) {
		if (!tab) { return; }
		var el = tab.el;
		var pos = this.getScrollPos(strip), area = this.getScrollArea(strip);
		var left = strip.tabs.length == 0 ? pos : Ext.fly(el).getOffsetsTo(strip.stripWrap)[0] + pos;
		var addScroll = false;
		if (strip.tabs.length > 0 && tab.id == strip.tabs[strip.tabs.length - 1].id) {
			addScroll = true;
			left += this.tabMargin;
		}
		var right = left + el.dom.offsetWidth;
		if (left < pos) {
			left -= this.tabMargin;
			this.scrollTo(strip, left, animate);
		} else if (right > (pos + area)) {
			if (strip.tabs.length > 0 && !addScroll) {
				right += this.tabMargin - 1;
			}
			if (area != 0) {
				this.scrollTo(strip, right - area, animate);
			}
		}
	},

	scrollTo: function (strip, pos, animate) {
		strip.stripWrap.scrollTo('left', pos, animate ? this.getScrollAnim(strip) : false);
		if (!animate) {
			this.updateScrollButtons(strip);
		}
	},

	onWheel: function (e) {
		var d = e.getWheelDelta() * this.wheelIncrement * -1;
		e.stopEvent();

		var pos = this.getScrollPos();
		var newpos = pos + d;
		var sw = this.getScrollWidth() - this.getScrollArea();

		var s = Math.max(0, Math.min(sw, newpos));
		if (s != pos) {
			this.scrollTo(s, false);
		}
	},

	onScrollRight: function (strip) {
		var sw = this.getScrollWidth(strip) - this.getScrollArea(strip);
		var pos = this.getScrollPos(strip);
		var s = Math.min(sw, pos + this.getScrollIncrement(strip)) + this.tabMargin;
		if (s != pos) {
			this.scrollTo(strip, s, this.animScroll);
		}
	},

	onScrollLeft: function (strip) {
		var pos = this.getScrollPos(strip);
		var s = Math.max(0, pos - this.getScrollIncrement(strip));
		if (s != pos) {
			this.scrollTo(strip, s, this.animScroll);
		}
	},

	updateScrollButtons: function (strip) {
		var pos = this.getScrollPos(strip);
		if (!strip.scrollLeft) {
			return;
		}
		strip.scrollLeft[pos == 0 ? 'addClass' : 'removeClass']('x-tab-scroller-left-disabled');
		strip.scrollRight[pos >= (this.getScrollWidth(strip) - this.getScrollArea(strip)) ? 'addClass' : 'removeClass']('x-tab-scroller-right-disabled');
	},

	beginUpdate: function (strip) {
		strip.suspendUpdates = true;
	},

	endUpdate: function (strip) {
		strip.suspendUpdates = false;
		this.delegateUpdates(strip);
	},

	autoScrollTabs: function (strip) {
		var count = strip.tabs.length;
		var ow = strip.el.dom.offsetWidth;
		var tw = ow - strip.toolsWidth - this.tabMargin;
		var wrap = strip.stripWrap;
		var marginRight = 18;
		if (strip.scrolling) {
			tw = tw - wrap.getLeft(true) - marginRight;
		}
		var wd = wrap.dom;
		var cw = wd.offsetWidth;
		var pos = this.getScrollPos(strip);
		var l = count == 0 ? pos : strip.edge.getOffsetsTo(strip.stripWrap)[0] + pos;

		if (!this.enableTabScroll || count < 1 || cw < 20) {
			if (strip.scrollLeft) {
				strip.scrollLeft.hide();
				strip.scrollRight.hide();
			}
			return;
		}
		if (l <= tw) {
			wd.scrollLeft = 0;
			if (strip.scrolling) {
				strip.scrolling = false;
				tw = tw + wrap.getLeft(true) + marginRight;
				strip.el.removeClass('x-tab-scrolling');
			}
			wrap.setWidth(tw);
			if (strip.scrollLeft) {
				strip.scrollLeft.hide();
				strip.scrollRight.hide();
			}
		} else {
			if (!strip.scrolling) {
				strip.el.addClass('x-tab-scrolling');
				tw = tw - wrap.getLeft(true) - marginRight;
			}
			// TODO: зачем это было сделано?
			// tw -= wrap.getMargins('lr');
			wrap.setWidth(tw > 20 ? tw : 20);
			if (!strip.scrolling) {
				if (!strip.scrollLeft) {
					this.createScrollers(strip);
				} else {
					strip.scrollLeft.show();
					strip.scrollRight.show();
				}
			}
			strip.scrolling = true;
			this.scrollToTab(strip, strip.activeTab, false);
			this.updateScrollButtons(strip);
		}
	},

	delegateUpdates: function (strip) {
		if (!strip) {
			return;
		}
		if (strip.suspendUpdates) {
			return;
		}
		// if (this.resizeTabs && strip.rendered) {
		//	TODO: Реализовать resize tab-ов
		//	 this.autoSizeTabs(strip);
		// }
		if (this.enableTabScroll && strip.rendered) {
			this.autoScrollTabs(strip);
		}
	},

	removeTab: function (tab) {
		var tabs = this.tabs;
		var tabIndex = tabs.indexOf(tab);
		tabs.remove(tab);
		tab.strip.tabs.remove(tab);
		if (!this.multiLevelMode) {
			this.recreateToolButtons(tab.strip);
		}
		if (this.tabs.length == 0 && this.multiLevelMode) {
			var stabStrip = this.stabStrip = this.el.createChild({ cls: 'x-strip x-tab-strip-first-level' });
			stabStrip.setHeight(this.firstLevelStripHeight + 'px');
		}
		if (tab.menu) {
			Ext.destroy(tab.menu);
		}
		if (tab.isActive()) {
			tabIndex++;
			if (tabIndex < tabs.length) {
				this.setActiveTabIndex(tabIndex);
			} else {
				var activeTab = this.getLastVisibleTab();
				if (activeTab) {
					this.setActiveTab(activeTab);
				}
			}
		}
		Ext.destroy(tab);
		this.onContentChanged();
	},

	removeControl: function (control) {
		if (control instanceof Terrasoft.TabHeader) {
			this.removeTab(control);
		} else {
			this.toolsLayout.removeControl(control);
			this.toolsLayout.doLayout();
		}
	},

	onDestroy: function () {
		Ext.destroy.apply(this, this.tabs);
		for (var strip in this.strips) {
			var strip = this.strips[strip];
			if (strip.tsLabel) {
				strip.tsLabel.un('linkclick', this.onLinkClick, this);
				Ext.destroy(strip.tsLabel);
			}
			Ext.destroy(strip.closeButton, strip.optionsButton, strip.toggleCollapseButton);
		}
		Terrasoft.MultiLevelTabs.superclass.onDestroy.call(this);
	}
});

Ext.reg('multileveltabs', Terrasoft.MultiLevelTabs);

Terrasoft.TabHeader = Ext.extend(Ext.Component, {
	showMenuItemCaption: false,
	groupName: "default",

	initComponent: function() {
		Terrasoft.TabHeader.superclass.initComponent.call(this);
		this.addEvents('click', 'captionchange', 'menuitemclick');
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.ensureMenuCreated();
			Ext.each(this.menuConfig, function(menuItemConfig) {
				Ext.apply(menuItemConfig, {realmenu: true});
			}, this);
			this.menu.createItemsFromConfig(this.menuConfig);
		}
	},

	ensureMenuCreated: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id:Ext.id()
			});
			this.menu.owner = this;
		}
	},

	getMenu: function() {
		this.ensureMenuCreated();
		return this.menu;
	},

	createMenu: function() {
		var el = this.el;
		var menu = this.menu;
		if (el && !el.hasClass('x-tab-with-menu')) {
			var menuPlaceEl = this.textEl;
			var subTextEl = this.subTextEl;
			var isMenuWithItems = (menu && menu.items.items.length > 0);
			if (isMenuWithItems) {
				el.addClass('x-tab-with-menu');
				var menuEl = this.menuEl = menuPlaceEl.createChild({
					tag: 'img',
					src: Ext.BLANK_IMAGE_URL,
					cls: 'x-tab-strip-icon-menu'
				});
				menuEl.addClassOnOver('x-tab-strip-icon-menu-over');
				menuEl.on("click", this.onMenuElClick, this);
				if (subTextEl) {
					if (this.getTopParent().multiLevelMode) {
						el.on("click", this.onMenuElClick, this);
					}
					subTextEl.on("click", this.onMenuElClick, this);
				}
			}
			el.on("click", this.onElClick, this);
		}
	},

	onRender: function(container, position) {
		Terrasoft.TabHeader.superclass.onRender.call(this, container, position);
		if (this.isFirstLevel) {
			var parent = this.ownerCt;
			if (parent && parent.tabs && parent.tabs.length == 1) {
				var stabStrip = parent.stabStrip;
				if (stabStrip) {
					stabStrip.remove();
					delete parent.stabStrip;
				}
			}
		}
		var el;
		if (this.beforeTab) {
			el = this.el = container.createChild({tag: 'li', id: this.id}, this.beforeTab);
			delete this.beforeTab;
		} else if (this.strip && this.strip.edge) {
			el = this.el = container.createChild({tag: 'li', id: this.id}, this.strip.edge);
		} else {
			if (Ext.fly(container).contains(Ext.getDom(this.id))) {
				this.el.remove();
			}
			el = this.el = container.createChild({tag: 'li', id: this.id});
		}
		el.on('dblclick', function(e) {
			// e.stopEvent();
			return false;
		}, this);
		var topParent = this.getTopParent();
		if (topParent.multiLevelMode && this.showMenuItemCaption) {
			el.addClass('x-header');
		}
		el.addClassOnOver('x-tab-strip-over');
		var leftEdge = el.createChild({tag: 'a', href: "#", cls: 'x-tab-strip-left-edge'});
		var rightEdge = leftEdge.createChild({tag: 'span', cls: 'x-tab-strip-right-edge'});
		var innerEl = rightEdge.createChild({tag: 'span', cls: 'x-tab-strip-bg-center'});
		var textEl = this.textEl = innerEl.createChild({tag: 'span', cls: 'x-tab-strip-text'});
		var captionEl = this.captionEl = textEl.createChild({tag: 'label', cls: 'x-tab-strip-caption'});
		this.setImage();

		var caption = this.caption;
		if (!caption) {
			caption = 'tab';
		}
		captionEl.dom.innerHTML = caption;
		// TODO Разобраться с menuPlaceEl
		if (this.showMenuItemCaption) {
			this.captionEl.addClass('x-tab-strip-with-subtext');
			this.subTextEl = textEl.createChild({
				tag: 'span',
				cls: 'x-empty x-tab-strip-subtext'
			});
		}
		if (this.showMenuItemCaption) {
			el.addClass('x-tab-with-subtitle');
		}
		this.createMenu();
		if (this.hidden) {
			this.hide();
		}
	},

	setImage: function (value) {
		if (value) {
			this.imageConfig = value;
		}
		if (this.imageConfig) {
			if (this.imageConfig.source != "None") {
				var imageSrc = this.getImageSrc();
				if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
					this.textEl.addClass(['x-tab-with-image']);
					this.textEl.setStyle('background-image', imageSrc);
				}
			} else {
				this.textEl.removeClass(['x-tab-with-image']);
				this.textEl.setStyle('background-image', 'none');
			}
		}
		
	},

	onElClick: function(e) {
		this.fireEvent('click', this, e);
	},
	
	onMenuElClick: function(e) {
		e.stopEvent();
		var menu = this.menu;
		if (!menu) {
			return;
		}
		var x, y;
		var topParent = this.getTopParent();
		var subTextEl = this.subTextEl;
		if (!topParent.multiLevelMode) {
			var captionEl = this.captionEl;
			if (subTextEl) {
				if (subTextEl.dom.innerHTML != '') {
					x = subTextEl.getLeft() + 2;
				} else {
					x = captionEl.getLeft() + captionEl.getWidth() + 16;
				}
				y = subTextEl.getTop() + 15;
			} else {
				x = captionEl.getLeft() + captionEl.getWidth() + 10;
				y = captionEl.getTop() + 15;
			}
			menu.showAt([x, y]);
		} else {
			this.showTabHeaderMenu(true);
		}
	},

	showTabHeaderMenu: function (isActivate) {
		if (!this.isActive() && isActivate === true) {
			var topParent = this.getTopParent();
			topParent.setActiveTab(this, true);
		}
		if (!this.rendered) {
			return;
		}
		var el = this.el;
		var menu = this.menu;
		if (menu) {
			if (isActivate !== false) {
				var x = el.getLeft();
				var y = el.getTop() + el.getHeight() - 1;
				if (Ext.isIE) {
					y = y + 1;
				}
				var menuEl = menu.getEl();
				var oldW = menuEl.getWidth();
				if (!menu.oldW){
					menu.oldW = oldW;
				} else {
					menuEl.setWidth(menu.oldW);
				}
				var w = Math.max(el.getWidth(), menuEl.getWidth());
				menuEl.addClass('x-header');
				menuEl.setWidth(w);
				menu.showAt([x, y]);
			} else {
				this.onMenuItemClick(this.realTab);
			}
		}
	},

	getTopParent: function() {
		var topParent = this.topParent;
		if (topParent) {
			return topParent;
		}
		var ownerCt = this.ownerCt;
		if(this.isFirstLevel) {
			this.topParent = ownerCt;
			return ownerCt;
		} else {
			return ownerCt.getTopParent();
		}
	},

	insert: function(index, item, activate, owner) {
		var parent = this.getTopParent();
		if (!item.isMenuitem) {
			parent.insertInnerTab(index, this, item, activate);
		} else {
			if (!this.menu) {
				this.menu = new Ext.menu.Menu({id:Ext.id()});
				this.menu.owner = owner || parent;
			}
			item.realmenu = true;
			if (!this.menu.hasListener('itemclick')) {
				this.menu.on("itemclick", this.onMenuItemClick, this);
			}
			item.parentMenu = this.menu;
			this.menu.addItem(item);
			this.createMenu();
		}
	},

	setShowMenuItemCaption: function(showMenuItemCaption) {
		if (this.showMenuItemCaption == showMenuItemCaption) {
			return;
		}
		this.showMenuItemCaption = showMenuItemCaption;
		if (!this.rendered) {
			return;
		}
		if (!this.showMenuItemCaption) {
			this.captionEl.removeClass('x-tab-strip-with-subtext');
			this.resetTabCaption(this);
		} else {
			this.captionEl.addClass('x-tab-strip-with-subtext');
		}
	},

	resetTabCaption: function(tab) {
		var caption = this.caption;
		var subTextEl = this.subTextEl;
		if (caption) {
			var tabCaptionLength = caption.length;
			if (caption.substring(tabCaptionLength-1) == ':') {
				this.setCaption(caption);
			}
		}
		if (subTextEl) {
			subTextEl.update('');
			subTextEl.addClass('x-empty');
		}
	},

	onMenuItemClick: function(menuItem) {
		if (!this.showMenuItemCaption) {
			return;
		}
		if (menuItem.caption) {
			var textEl = this.textEl;
			var subTextEl = this.subTextEl;
			var caption = this.caption;
			if (caption) {
				var tabCaptionLength = caption.length;
				if (caption.substring(tabCaptionLength-1) != ':') {
					this.setCaption(caption + ':');
				}
			}
			if (Ext.isIE9) {
				subTextEl.update.defer(10, subTextEl, [menuItem.caption]);
			} else {
				subTextEl.update(menuItem.caption);
			}
			subTextEl.removeClass('x-empty');
			var parent = this.getTopParent();
			if (parent.multiLevelMode) {
				if (menuItem.rendered) {
					var menu = this.menu;
					textEl.addClass('x-tab-with-image');
					textEl.setStyle('background-image', menuItem.el.child('img').getStyle('background-image'));
					if (menu) {
						var w = Math.max(this.el.getWidth(), menu.getEl().getWidth());
						menu.getEl().setWidth(w);
					}
				} else {
					this.setImage(menuItem.imageConfig);
				}
			}
		}
	},

	onContentChanged: function() {
		var menu = this.menu;
		if (menu) {
			if (menu.items.length > 0) {
				this.createMenu();
			} else {
				if (menu.items.items.length == 0) {
					Ext.destroy(this.menuEl);
					this.el.removeClass('x-tab-with-menu');
					delete this.menu;
				}
			}
		}
		var parent = this.getTopParent();
		parent.onContentChanged();
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (this.captionEl) {
			this.captionEl.update(caption);
		}
		this.onContentChanged();
		this.fireEvent('captionchange', this, caption);
		return this;
	},

	setActive: function(isActive) {
		if (this.el) {
			this.el[isActive ? 'addClass' : 'removeClass']('x-tab-strip-active');
		}
	},

	isActive: function() {
		if (this.el) {
			return this.el.hasClass('x-tab-strip-active');
		}
		return false;
	},

	selectControl: function(tab, fireEvent) {
		var parent = this.getTopParent();
		parent.selectControl(tab, fireEvent);
	},

	removeControl: function(item, isDestroy) {
		if (item.isMenuitem) {
			if (!this.menu) {
				return;
			}
			this.menu.remove(item);
			if (this.menu.items.items.length == 0) {
				Ext.destroy(this.menuEl);
				this.el.removeClass('x-tab-with-menu');
				delete this.menu;
			}
			return item;
		} else {
			this.tabs.remove(item);
			if (isDestroy !== false) {
				Ext.destroy(item);
				if (item.ownerCt.isFirstLevel !== true && item.ownerCt.menuEl && item.ownerCt.tabs.length == 0) {
					Ext.destroy(item.ownerCt.menuEl);
					item.ownerCt.el.removeClass('x-tab-with-menu');
				}
				if (this.isFirstLevel !== true && item.strip && item.strip.tabs.length == 0) {
					Ext.destroy(item.strip.el);
				}
			}
		}
		this.onContentChanged();
	},

	moveControl: function(tab, position) {
		if (tab.isMenuitem) {
			tab.parentMenu.remove(tab, true);
			if (tab.parentMenu.owner && tab.parentMenu.owner.onContentChanged) {
				tab.parentMenu.owner.onContentChanged();
			}
			this.removeControl(tab);
			this.insert(position, tab);
			return;
		}
		tab.ownerCt.tabs.remove(tab);
		var parent = this.getTopParent();
		if (parent.strips[tab.id] && tab.isFirstLevel) {
			Ext.destroy(parent.strips[tab.id].el);
			Ext.each(tab.tabs, function(t, i) {
				delete t.strip;
			});
			delete parent.strips[tab.id];
		}
		var el = tab.el ? Ext.getDom(tab.el) : undefined;
		if (tab.ownerCt.isFirstLevel !== true && tab.ownerCt.menuEl && tab.ownerCt.tabs.length == 0) {
			Ext.destroy(tab.ownerCt.menuEl);
			tab.ownerCt.el.removeClass('x-tab-with-menu');
		}
		if (tab.strip && tab.strip.tabs.length == 0) {
			if (tab.strip.el) {
				Ext.destroy(tab.strip.el);
			}
		}
		tab.ownerCt = this;
		tab.rendered = false;
		this.insert(position, tab, false);
		var newEl = Ext.getDom(tab.el);
		if (newEl && el && newEl.parentNode) {
			if (Ext.fly(tab.el).parent().contains(el)) {
				newEl.parentNode.removeChild(el);
			}
		}
	},

	onDestroy: function () {
		Ext.destroy.apply(this, this.tabs);
		Ext.destroy(this.menuEl);
		this.ownerCt.tabs.remove(this);
		if (this.isFirstLevel !== true && this.strip && this.strip.tabs.length == 0) {
			Ext.destroy(this.strip.el);
		}
		Terrasoft.TabHeader.superclass.onDestroy.call(this);
	}
});

Ext.reg("tabheader", Terrasoft.TabHeader);