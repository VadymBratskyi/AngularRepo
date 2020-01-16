Terrasoft.TabPanel = Ext.extend(Ext.Panel, {
	deferredRender: true,
	layoutOnTabChange: false,
	height: 200,
	width: 200,
	tabWidth: 200,
	minTabWidth: 30,
	resizeTabs: false,
	enableTabScroll: true,
	scrollIncrement: 0,
	scrollRepeatInterval: 400,
	scrollDuration: .35,
	animScroll: true,
	wheelIncrement: 20,
	tabPosition: 'top',
	baseCls: 'x-tab-panel',
	autoTabs: false,
	autoTabSelector: 'div.x-tab',
	activeTab: null,
	tabMargin: 3,
	plain: false,
	idDelimiter: '__',
	itemCls: 'x-tab-item',
	elements: 'body',
	collapsedStyleHeight: 35,
	headerAsText: false,
	frame: false,
	toolTarget: 'stripUlEl',
	hideCollapseTool: false,
	hideBorders: true,
	defaultType: 'tab',
	useDefaultLayout: false,
	displayStyle: 'standart',
	isCollapsible: true,
	closeable: false,
	hasOptionsButton: true,
	hotKeyTabChangeDelayEvent: 300,
	tabsGroupsOrderPosition: "default",
	nextTabHotKeysCombination: {
		shift: true,
		ctrl: false,
		alt: true,
		key: Ext.EventObject.RIGHT
	},
	prevTabHotKeysCombination: {
		shift: true,
		ctrl: false,
		alt: true,
		key: Ext.EventObject.LEFT
	},

	initComponent: function () {
		this.frame = false;
		Terrasoft.TabPanel.superclass.initComponent.call(this);
		this.addEvents(
			'addtabclick',
			'beforetabchange',
			'tabchange'
		);
		this.setLayout(new Ext.layout.CardLayout({
			deferredRender: this.deferredRender
		}));
		if (this.tabPosition == 'top') {
			this.elements += ',header';
			this.stripTarget = 'header';
		} else {
			this.elements += ',footer';
			this.stripTarget = 'footer';
		}
		if (!this.stack) {
			this.stack = Terrasoft.TabPanel.AccessStack();
		}
		this.initItems();
		this.items.each(function (item) {
			item.customBgCls = 'x-tab-bg';
		});
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.ensureMenuCreated();
			this.menu.createItemsFromConfig(this.menuConfig);
		}
		delete this.menuConfig;
	},

	render: function () {
		Terrasoft.TabPanel.superclass.render.apply(this, arguments);
		if (this.activeTab !== undefined) {
			var item = this.activeTab;
			if (item != undefined || item != null) {
				var multiLevelTabs = this.multiLevelTabs;
				var tabHeaders = multiLevelTabs.tabs;
				if (!tabHeaders[item] || tabHeaders[item].hidden === true) {
					item = multiLevelTabs.getFirstVisibleTab();
					item = tabHeaders.indexOf(item);
				}
			}
			delete this.activeTab;
			this.setActiveTab(item, true, false);
		}
	},

	onRender: function (ct, position) {
		Terrasoft.TabPanel.superclass.onRender.call(this, ct, position);
		var el = this.el;
		this.focusEl = el.createChild({
			tag: "a", cls: '', href: "#", onclick: "return false;", tabIndex: "-1", id: this.id + '_focusEl'
		});
		if (this.header) {
			var topHeaderLine = new Ext.Element(document.createElement("div"));
			topHeaderLine.addClass('x-tab-panel-header-top-line');
			topHeaderLine.insertBefore(this.header);
			this.topHeaderLine = topHeaderLine;
		}
		if (this.displayStyle === 'primary') {
			this.setDisplayStyle(this.displayStyle);
		} else if (this.hasImportantTabs()) {
			this.setImportant(true);
		}
		if (this.isFirstTabImportant()) {
			if (!el.hasClass('x-tab-panel-important-first')) {
				el.addClass('x-tab-panel-important-first');
			}
		}
		if (this.plain) {
			var pos = this.tabPosition == 'top' ? 'header' : 'footer';
			this[pos].addClass('x-tab-panel-' + pos + '-plain');
		}
		var tabsConfig = [];
		Ext.each(this.items.items, function (item, i) {
			tabsConfig.push({
				hidden: item.hidden,
				caption: item.caption,
				menu: item.menu,
				tag: item,
				groupName: item.groupName
			});
		}, this);
		this.multiLevelTabs = new Terrasoft.MultiLevelTabs({
			tabChangeDelay: this.tabChangeDelay,
			hasAddTabButton: this.hasAddTabButton,
			collapsible: this.collapsible,
			closeable: this.closeable,
			hasOptionsButton: this.hasOptionsButton,
			width: this['header'].getWidth(),
			tabsConfig: tabsConfig,
			multiLevelMode: false,
			tabsGroupsOrderPosition: this.tabsGroupsOrderPosition
		});
		Ext.each(this.multiLevelTabs.tabs, function (t, i) {
			t.showMenuItemCaption = t.tag.showMenuItemCaption,
			t.tag.tabHeader = t;
			t.on('click', function() {
				Ext.fly(this.focusEl).focus();
			}, this);
		}, this);
		this.multiLevelTabs.render(this[this.stripTarget]);
		Ext.each(this.multiLevelTabs.tabs, function (t, i) {
			t.el[t.tag.isImportant === true ? 'addClass' : 'removeClass']('x-tab-panel-highlight-important');
		}, this);
		this.multiLevelTabs.on('tabchange', function (mlt, item) {
			this.setActiveTab(item.tag);
		}, this);
		this.multiLevelTabs.on('collapsetoolclick', this.toggleCollapse, this);
		this.multiLevelTabs.on('closetoolclick', this.closeToolClick, this);
		this.multiLevelTabs.on('optionstoolclick', this.optionsToolClick, this);
		this.multiLevelTabs.on('addtabclick', this.onAddTabClick, this);
		var clickEl = el.child('.x-tab-strip-first-level .x-tab-strip-wrap');
		if (this.collapsible) {
			clickEl.on('dblclick', this.toggleCollapse, this);
		}
		this.body.addClass('x-tab-panel-body-' + this.tabPosition);
		var formEl = Ext.get(document.forms[0]);
		this.hiddenFieldActiveTabIndexName = this.id + '_ActiveTab';
		this.hiddenFieldActiveTabIndexEl = Ext.get(formEl.createChild({
			tag: 'input',
			type: 'hidden',
			name: this.hiddenFieldActiveTabIndexName,
			id: this.hiddenFieldActiveTabIndexName
		}, undefined, true));
	},

	afterRender: function () {
		Terrasoft.TabPanel.superclass.afterRender.call(this);
		if (this.autoTabs) {
			this.readTabs(false);
		}

		var resizeEl = this.getResizeEl();
		resizeEl.on("keyup", function(e, c) {
			this.onHotKeyPressed(e);
		}, this);
		/*
		var kn = new Ext.KeyNav(resizeEl, {
		"right": function(e) {
		var tabItems = this.items;
		var newActiveTabIndex;
		var currentActiveTabIndex = tabItems.indexOf(this.activeTab);
		if (tabItems.length <= currentActiveTabIndex + 1) {
		newActiveTabIndex = 0;
		} else {
		newActiveTabIndex = currentActiveTabIndex + 1;
		}
		var multiLevelTabs = this.multiLevelTabs;
		if (multiLevelTabs.setActiveTab) {
		var tab = multiLevelTabs.tabs[newActiveTabIndex];
		multiLevelTabs.setActiveTab(tab, true);
		}
		var item = tabItems.itemAt(newActiveTabIndex);
		this.setActiveTab(item, false, false, true);
		},
		scope: this,
		forceKeyDown: true
		});
		*/
	},

	isValidKeysCombination: function(e, keysCombination) {
		if (e.keyCode != keysCombination.key) {
			return false;
		}
		if (keysCombination.alt && keysCombination.alt === true && e.altKey !== true) {
			return false;
		}
		if (keysCombination.shift && keysCombination.shift === true && e.shiftKey !== true) {
			return false;
		}
		if (keysCombination.ctrl && keysCombination.ctrl === true && e.ctrlKey !== true) {
			return false;
		}
		return true;
	},

	onHotKeyPressed: function(e) {
		if (!this.isValidKeysCombination(e, this.nextTabHotKeysCombination)
			&& !this.isValidKeysCombination(e, this.prevTabHotKeysCombination)) {
			return;
		}
		var tabItems = this.items;
		var currentActiveTabIndex = tabItems.indexOf(this.activeTab);
		var tabItemsLength = tabItems.length;
		var step = tabItemsLength + (this.isValidKeysCombination(e, this.nextTabHotKeysCombination) ? 1 : -1);
		var newActiveTabIndex = (currentActiveTabIndex + step) % tabItemsLength;
		var multiLevelTabs = this.multiLevelTabs;
		var item = tabItems.itemAt(newActiveTabIndex);
		while (item.tabHeader.hidden === true) {
			newActiveTabIndex = (newActiveTabIndex + step) % tabItemsLength;
			item = tabItems.itemAt(newActiveTabIndex);
		}
		if (multiLevelTabs.setActiveTab) {
			var tab = multiLevelTabs.tabs[newActiveTabIndex];
			multiLevelTabs.setActiveTab(tab, true);
		}
		this.setActiveTab(item, false, false, true);
		e.stopEvent();
		Ext.fly(this.focusEl).focus();
	},

	initEvents: function () {
		Terrasoft.TabPanel.superclass.initEvents.call(this);
	},

	createCloseToolButton: function () {
		this.closeButton = this.header.insertFirst({
			cls: 'x-tool-tab-panel-close'
		});
		this.closeButton.addClassOnOver('x-tool-tab-panel-close-over');
		this.closeButton.addClassOnClick('x-tool-tab-panel-close-click');
		this.closeButton.setStyle('right', this.toolsWidth.toString() + 'px');
		this.closeButton.on('click', function () { this.hide(true); }, this);
		this.toolsWidth += this.closeButton.getWidth();
	},

	createOptionsToolButton: function () {
		this.optionsButton = this.header.insertFirst({
			cls: 'x-tool-tab-panel-options'
		});
		this.optionsButton.addClassOnOver('x-tool-tab-panel-options-over');
		this.optionsButton.addClassOnClick('x-tool-tab-panel-options-click');
		this.optionsButton.setStyle('right', this.toolsWidth.toString() + 'px');
		this.optionsButton.on('click', this.onOptionsButtonClick, this);
		this.toolsWidth += this.optionsButton.getWidth();
	},

	createCollapsibleToolButton: function () {
		this.stripWrap.on('dblclick', this.toggleCollapse, this);
		this.toggleCollapseButton = this.header.insertFirst({
			cls: 'x-tool-tab-panel-collapse'
		});
		this.toggleCollapseButton.addClassOnOver('x-tool-tab-panel-collapse-over');
		this.toggleCollapseButton.addClassOnClick('x-tool-tab-panel-collapse-click');
		this.toggleCollapseButton.setStyle('right', this.toolsWidth.toString() + 'px');
		this.toggleCollapseButton.on('click', this.toggleCollapse, this);
		this.toolsWidth += this.toggleCollapseButton.getWidth();
	},

	recreateToolButtons: function () {
		//this.stripWrap.dom.scrollLeft = 0;
		if (this.closeButton) {
			this.closeButton.remove();
			this.closeButton = undefined;
		}
		if (this.optionsButton) {
			this.optionsButton.remove();
			this.optionsButton = undefined;
		}
		if (this.toggleCollapseButton) {
			this.toggleCollapseButton.remove();
			this.toggleCollapseButton = undefined;
		}
		this.initTabPanelTools();
		if (this.scrollRight) {
			this.scrollRight.setStyle('right', this.toolsWidth.toString() + 'px');
		}
		this.delegateUpdates();
	},

	setCloseable: function (closable) {
		var strip = this.multiLevelTabs.strips[this.multiLevelTabs.id];
		this.closeable = closable;
		this.multiLevelTabs.closeable = closable;
		this.multiLevelTabs.recreateToolButtons(strip);
	},

	setHasAddTabButton: function (hasAddTabButton) {
		var strip = this.multiLevelTabs.strips[this.multiLevelTabs.id];
		this.hasAddTabButton = hasAddTabButton;
		this.multiLevelTabs.hasAddTabButton = hasAddTabButton;
		this.multiLevelTabs.recreateToolButtons(strip);
	},

	setHasOptionsButton: function (hasOptionsButton) {
		var strip = this.multiLevelTabs.strips[this.multiLevelTabs.id];
		this.hasOptionsButton = hasOptionsButton;
		this.multiLevelTabs.hasOptionsButton = hasOptionsButton;
		this.multiLevelTabs.recreateToolButtons(strip);
	},

	setCollapsible: function (collapsible) {
		var strip = this.multiLevelTabs.strips[this.multiLevelTabs.id];
		this.collapsible = collapsible;
		this.multiLevelTabs.collapsible = collapsible;
		this.multiLevelTabs.recreateToolButtons(strip);
	},

	initTabPanelTools: function () {
		this.toolsWidth = 5;
		this.header.addClass('x-tab-header');
		if (this.collapsible) {
			this.createCollapsibleToolButton();
		}
		if (this.closeable) {
			this.createCloseToolButton();
		}
		if (this.hasOptionsButton !== false) {
			this.createOptionsToolButton();
		}
	},
	
	setCollapsedState: function (collapsed) {
		if (this.collapsed == collapsed) {
			return;
		}
		this.toggleCollapse();
	},

	onCollapse: function () {
		Terrasoft.TabPanel.superclass.onCollapse.call(this);
		if (this.activeTab) {
			this.activeTab.hide();
		}
	},

	onExpand: function (doAnim, animArg) {
		Terrasoft.TabPanel.superclass.onExpand.call(this);
		var activeTab = this.activeTab;
		this.activeTab = null;
		this.layout.activeItem = null;
		this.setActiveTab(activeTab);
		if (activeTab) {
			if (activeTab.doLayout) {
				activeTab.doLayout();
			}
		}
	},

	setDisplayStyle: function (displayStyle) {
		this.displayStyle = displayStyle.toLowerCase();
		this.el[this.displayStyle === 'primary' ?
			'addClass' : 'removeClass']('x-tab-panel-mark-main');
		if (this.designMode) {
			this.updateDisplayStyle();
		}
	},

	setImportant: function (isImportant) {
		this.el[isImportant === true ?
			'addClass' : 'removeClass']('x-tab-panel-highlight-important');
	},

	hasImportantTabs: function () {
		for (var i = 0; i < this.items.length; i++) {
			var item = this.items.items[i];
			if (item.isImportant === true) {
				return true;
			}
		}
		return false;
	},

	isFirstTabImportant: function () {
		var items = this.items;
		if (items.length < 1) {
			return false;
		} else {
			return items.items[0].isImportant === true;
		}
	},

	updateDisplayStyle: function () {
		this.setImportant(this.displayStyle);
	},

	getCollapsedStyleHeight: function () {
		return this.collapsedStyleHeight;
	},

	close: function () {
		this.hide();
	},

	getItemByStripTab: function (stripTabEl) {
		return this.getComponent(stripTabEl.id.split(this.idDelimiter)[1]);
	},

	isStripTab: function (stripTabEl) {
		return (stripTabEl.id.split(this.idDelimiter).length == 2);
	},

	findTargets: function (e) {
		var item = null;
		var itemEl = e.getTarget('li', this.strip);
		if (itemEl) {
			item = this.getItemByStripTab(itemEl);
			if (item.disabled) {
				return {
					close: null,
					menuEl: null,
					item: null,
					el: null
				};
			}
		}

		return {
			close: e.getTarget('.x-tab-strip-close', this.strip),
			menuEl: e.getTarget('.x-tab-strip-icon-menu', this.strip) || e.getTarget('.x-tab-strip-subtext', this.strip),
			item: item,
			el: itemEl
		};
	},

	onStripClick: function (e) {
		e.preventDefault();
		var t = this.findTargets(e);
		if (t.close) {
			this.remove(t.item);
			return;
		}
		if (t.item && t.menuEl && t.item.menu) {
			this.showMenu(t.item, t.menuEl);
			return;
		}
		if (t.item && t.item != this.activeTab) {
			this.setActiveTab(t.item);
		}
	},

	showContextMenu: function (e) {
		var menu = this.multiLevelTabs.generateContextMenuItems(this.getActiveTab());
		var x = Ext.lib.Event.getPageX(e);
		var y = Ext.lib.Event.getPageY(e);
		menu.showAt([x, y]);
	},

	optionsToolClick: function (e, tool, panel) {
		if (this.enabled) {
			this.showContextMenu(e);
		}
	},

	onAddTabClick: function (e) {
		this.fireEvent('addtabclick', e);
	},

	closeToolClick: function () {
		this.el.setStyle('display', 'none');
	},

	showTabFromMenu: function (menuItem) {
		this.setActiveTab(menuItem.tabToShow);
	},

	showMenu: function (item, el) {
		if (item.enabled && !item.menu.isVisible()) {
			item.menu.tab = item;
			item.menu.show(el, 'tl-bl?');
		}
	},

	readTabs: function (removeExisting) {
		if (removeExisting === true) {
			this.items.each(function (item) {
				this.remove(item);
			}, this);
		}
		var tabs = this.el.query(this.autoTabSelector);
		for (var i = 0, len = tabs.length; i < len; i++) {
			var tab = tabs[i];
			var caption = tab.getAttribute('title');
			tab.removeAttribute('title');
			this.add({
				caption: caption,
				el: tab
			});
		}
	},

	onMenuItemClick: function (menuItem) {
		if (menuItem.caption) {
			if (menuItem.parentMenu && menuItem.parentMenu.tab) {
				this.setTabSubCaption(menuItem.parentMenu.tab, menuItem.caption);
			}
		}
	},

	initTab: function (item, index) {
		var before;
		if (index >= 0 && index < this.strip.dom.childNodes.length) {
			before = this.strip.dom.childNodes[index];
		}
		var cls = '';
		// TODO Нужны ли нам closable табы
		// var cls = item.closable ? 'x-tab-strip-closable' : '';
		if (item.disabled) {
			cls += ' x-item-disabled';
		}
		if (item.imageCls) {
			cls += ' x-tab-with-icon';
		}
		if (item.tabCls) {
			cls += ' ' + item.tabCls;
		}
		if (item.menu) {
			cls += ' x-tab-with-menu';
			item.on('beforedestroy', this.onBeforeTabDestroy);
			if (item.showMenuItemCaption) {
				item.menu.on("itemclick", this.onMenuItemClick, this);
			}
		}
		if (item.subCaption) {
			cls += ' x-tab-with-subtitle';
		}
		if (!item.caption) {
			item.caption = 'Tab';
		}
		var p = {
			id: this.id + this.idDelimiter + item.getItemId(),
			text: item.caption,
			cls: cls,
			subText: item.subCaption || '',
			menuImageCls: 'x-tab-strip-icon-menu',
			imgSrc: Ext.BLANK_IMAGE_URL,
			imageCls: item.imageCls || ''
		};
		var el = before ? this.itemTpl.insertBefore(before, p) : this.itemTpl.append(this.strip, p);
		var flyEl = Ext.fly(el);
		flyEl.addClassOnOver('x-tab-strip-over');
		if (item.tabTip) {
			flyEl.child('span.x-tab-strip-text', true).qtip = item.tabTip;
		}
		if (item.draggable && this.allowDraggingTabs === true) {
			el.dd = new Terrasoft.TabPanel.TabDragSource(this, el, { ddGroup: "TabPanelTabs" });
		}
		if (item.visible === false) {
			this.hideTabStripItem(item);
		}
		item.on('disable', this.onItemDisabled, this);
		item.on('enable', this.onItemEnabled, this);
		item.on('captionchange', this.onItemCaptionChanged, this);
		item.on('beforeshow', this.onBeforeShowItem, this);
	},

	closeTab: function (tab, closeAction) {
		if (typeof tab == 'string') {
			tab = this.getItem(tab);
		} else if (typeof tab == 'number') {
			tab = this.items.get(tab);
		}
		if (Ext.isEmpty(tab)) {
			return;
		}
		var eventName = tab.closeAction || closeAction || 'close';
		var destroy = eventName == 'close';
		if (tab.fireEvent('before' + eventName, tab) === false) {
			return;
		}
		this.hideTabStripItem(tab);
		tab.addClass('x-hide-display');
		tab.fireEvent('close', tab);
		this.remove(tab, destroy);
	},

	removeControl: function (item) {
		if (item.isMenuitem) {
			var menu = this.menu;
			if (!menu) {
				return;
			}
			menu.remove(item);
			var multiLevelTabs = this.multiLevelTabs;
			if (multiLevelTabs) {
				var strip = multiLevelTabs.strips[multiLevelTabs.id];
				multiLevelTabs.recreateToolButtons(strip, menu.items.length > 0);
			}
			return item;
		} else {
			Terrasoft.TabPanel.superclass.removeControl.call(this, item);
			this.multiLevelTabs.removeControl(item.tabHeader);
			if (this.items && this.items.items.length == 0 && this.hiddenFieldActiveTabIndexEl) {
				this.hiddenFieldActiveTabIndexEl.dom.value = -1;
			}
		}
	},

	ensureMenuCreated: function () {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id()
			});
			this.menu.owner = this;
		}
	},

	getMenu: function () {
		this.ensureMenuCreated();
		return this.menu;
	},

	onContentChanged: function () {
		var multiLevelTabs = this.multiLevelTabs;
		if (!multiLevelTabs) {
			return;
		}
		var strip = multiLevelTabs.strips[multiLevelTabs.id];
		var menu = this.menu;
		multiLevelTabs.recreateToolButtons(strip, menu ? menu.items.length > 0 : false);
	},

	insert: function (index, item, activate) {
		var multiLevelTabs = this.multiLevelTabs;
		if (item.isMenuitem) {
			var menu = this.getMenu();
			this.ensureMenuCreated();
			item.parentMenu = menu;
			var strip = multiLevelTabs.strips[multiLevelTabs.id];
			multiLevelTabs.recreateToolButtons(strip, true);
			item = menu.insert(index, item);
			return item;
		}
		var config = {};
		if (!Ext.isEmpty(index)) {
			if (typeof index == 'object') {
				config = index;
			} else if (typeof index == 'number') {
				config.index = index;
			} else {
				config.activate = index;
			}
		}
		if (!Ext.isEmpty(activate)) {
			config.activate = activate;
		}
		if (this.items.getCount() === 0) {
			this.activeTab = null;
		}
		var index = this.items.getCount();
		if (!Ext.isEmpty(config.index) && config.index >= 0) {
			index = config.index;
		} else {
			index = this.items.getCount();
		}
		Ext.Panel.superclass.insert.call(this, index, item);
		var tabHeaderConfig = {
			caption: item.caption,
			tag: item
		};
		var tabHeader = Ext.ComponentMgr.create(Ext.apply(tabHeaderConfig, {
			ownerCt: multiLevelTabs
		}), 'tabheader');
		multiLevelTabs.insert(index, tabHeader, activate);
		item.tabHeader = tabHeader;
		if (config.activate === true) {
			this.setActiveTab(item);
		}
		item.on('nameChanged', this.onItemNameChanged, this);
	},

	addTab: function (tab, index, activate) {
		var config = {};
		if (!Ext.isEmpty(index)) {
			if (typeof index == 'object') {
				config = index;
			} else if (typeof index == 'number') {
				config.index = index;
			} else {
				config.activate = index;
			}
		}
		if (!Ext.isEmpty(activate)) {
			config.activate = activate;
		}
		if (this.items.getCount() === 0) {
			this.activeTab = null;
		}
		if (!Ext.isEmpty(config.index) && config.index >= 0) {
			this.insert(config.index, tab);
		} else {
			this.add(tab);
			tab.on('nameChanged', this.onItemNameChanged, this);
		}
		if (config.activate === true) {
			this.setActiveTab(tab);
		}
	},

	onAdd: function (tp, item, index) {
		this.updateDisplayStyle();
		this.initTab(item, index);
		if (this.items.getCount() == 1) {
			this.syncSize();
			this.setActiveTab(item);
		}
		this.delegateUpdates();
	},

	onItemNameChanged: function (el, oldName, name) {
		var items = this.items;
		items.remove(el);
		items.add(name, el);
	},

	onBeforeAdd: function (item) {
		var existing = item.events ? (this.items.containsKey(item.getItemId()) ? item : null) : this.items.get(item);
		if (existing) {
			this.setActiveTab(item);
			return false;
		}
		Terrasoft.TabPanel.superclass.onBeforeAdd.apply(this, arguments);
		var es = item.elements;
		item.elements = es ? es.replace(',header', '') : es;
		item.border = (item.border === true);
	},

	onRemove: function (tp, item) {
		this.updateDisplayStyle();
		Ext.removeNode(this.getTabEl(item));
		this.stack.remove(item);
		item.un('disable', this.onItemDisabled, this);
		item.un('enable', this.onItemEnabled, this);
		item.un('captionchange', this.onItemCaptionChanged, this);
		item.un('beforeshow', this.onBeforeShowItem, this);
		if (item == this.activeTab) {
			var next = this.stack.next();
			if (next) {
				this.setActiveTab(next);
			} else {
				var multiLevelTabs = this.multiLevelTabs;
				var tabHeaders = multiLevelTabs.tabs;
				var firstVisibleTab = multiLevelTabs.getFirstVisibleTab();
				var activeTabIndex = tabHeaders.indexOf(firstVisibleTab);
				this.setActiveTab(activeTabIndex);
			}
		}
		this.delegateUpdates();
	},

	selectControl: function (control, fireEvent) {
		this.setActiveTab(control);
	},

	onBeforeShowItem: function (item) {
		if (item != this.activeTab) {
			this.setActiveTab(item);
			return false;
		}
	},

	onItemDisabled: function (item) {
		var el = this.getTabEl(item);
		if (el) {
			Ext.fly(el).addClass('x-item-disabled');
		}
		this.stack.remove(item);
	},

	onItemEnabled: function (item) {
		var el = this.getTabEl(item);
		if (el) {
			Ext.fly(el).removeClass('x-item-disabled');
		}
	},

	onItemCaptionChanged: function (item) {
		this.setTabCaption(item, item.caption);
	},

	setTabCaption: function (item, caption, isActive) {
		var el = this.getTabEl(item);
		if (!el) {
			return;
		}
		if (isActive == undefined) {
			isActive = (item.id == (this.activeTab ? this.activeTab.id : ''));
		}
		if (caption != undefined) {
			item.caption = caption;
		}
		var tabStripTextEl = Ext.fly(el).child('span.x-tab-strip-text', true);
		tabStripTextEl.firstChild.nodeValue = (item.subCaption && isActive) ? item.caption + ':' : item.caption;
		this.delegateUpdates();
	},

	setTabSubCaption: function (item, caption) {
		var el = this.getTabEl(item);
		if (!el) {
			return;
		}
		item.subCaption = caption || '';
		this.setTabCaption(item);
		var tabStripTextEl = Ext.fly(el).child('span.x-tab-strip-subtext', true);
		tabStripTextEl.innerHTML = caption || '';
		this.delegateUpdates();
	},

	getTabEl: function (item) {
		var itemId = (typeof item === 'number') ? this.items.items[item].getItemId() : item.getItemId();
		return document.getElementById(this.id + this.idDelimiter + itemId);
	},

	onResize: function () {
		var topStripTabs = this.multiLevelTabs;
		Terrasoft.TabPanel.superclass.onResize.apply(this, arguments);
		if (topStripTabs != this.el.getWidth()) {
			topStripTabs.setWidth(this.el.getWidth());
		}
		/*
		if (!this.nr) {
		var pos = this.getScrollPos();
		var sw = this.getScrollWidth() - this.getScrollArea();
		var s = Math.max(0, Math.min(sw, pos));
		if (s != pos) {
		this.scrollTo(s, false);
		}
		this.delegateUpdates();
		}
		*/
		/*
		if (!this.collapsed) {
		this.toggleCollapse(true);
		}
		*/
	},

	beginUpdate: function () {
		this.suspendUpdates = true;
	},

	endUpdate: function () {
		this.suspendUpdates = false;
		this.delegateUpdates();
	},

	hideTabStripItem: function (item) {
		item = this.getComponent(item);
		var el = this.getTabEl(item);
		if (el) {
			el.style.display = 'none';
			this.delegateUpdates();
		}
		this.stack.remove(item);
	},

	unhideTabStripItem: function (item) {
		item = this.getComponent(item);
		var el = this.getTabEl(item);
		if (el) {
			el.style.display = '';
			this.delegateUpdates();
		}
	},

	delegateUpdates: function () {
		if (this.suspendUpdates) {
			return;
		}
		if (this.resizeTabs && this.rendered) {
			this.autoSizeTabs();
		}
		if (this.enableTabScroll && this.rendered) {
			this.autoScrollTabs();
		}
	},

	autoSizeTabs: function () {
		var count = this.items.length;
		var ce = this.tabPosition != 'bottom' ? 'header' : 'footer';
		var ow = this[ce].dom.offsetWidth;
		var aw = this[ce].dom.clientWidth;

		if (!this.resizeTabs || count < 1 || !aw) {
			return;
		}

		var each = Math.max(Math.min(Math.floor((aw - 4) / count) -
					this.tabMargin, this.tabWidth), this.minTabWidth);
		this.lastTabWidth = each;
		var lis = this.stripWrap.dom.getElementsByTagName('li');
		for (var i = 0, len = lis.length - 1; i < len; i++) {
			var li = lis[i];
			var inner = li.childNodes[1].firstChild.firstChild;
			var tw = li.offsetWidth;
			var iw = inner.offsetWidth;
			inner.style.width = (each - (tw - iw)) + 'px';
		}
	},

	adjustBodyWidth: function (w) {
		if (this.header) {
			w = w + this.header.getFrameWidth('lr');
			this.header.setWidth(w);
		}
		if (this.footer) {
			w = w + this.footer.getFrameWidth('lr');
			this.footer.setWidth(w);
		}
		return w;
	},

	adjustBodyHeight: function (h) {
		if (this.topHeaderLine) {
			h = h - this.topHeaderLine.getHeight();
		}
		return h;
	},

	getMinSize: function () {
		return this.collapsedStyleHeight;
	},

	setActiveTabIndex: function (index) {
		var item = this.items.itemAt(index);
		this.setActiveTab(item);
		if (this.designMode && this.activeTab) {
			this.activeTab.onContentChanged();
		}
		if (!this.rendered) {
			return;
		}
		this.hiddenFieldActiveTabIndexEl.dom.value = index;
		this.setProfileData('activetabindex', index);
	},

	applyStyles: function (item) {
		var el = this.el;
		el.removeClass('x-tab-panel-highlight-important');
		el.removeClass('x-tab-panel-highlight-important-active');
		if (item.isImportant) {
			el.addClass('x-tab-panel-highlight-important-active');
		} else {
			if (el.hasClass('x-tab-panel-important-first')) {
				el.addClass('x-tab-panel-highlight-important');
			}
		}
	},

	setActiveTab: function (item, forceTabChange, isDeepLayout, deferTabChange) {
		if (typeof (item) == "number") {
			this.multiLevelTabs.setActiveTabIndex(item);
		} else {
			var tab;
			Ext.each(this.multiLevelTabs.tabs, function (t, i) {
				if (t.tag == item) {
					tab = t;
					return false;
				}
			}, this);
			if (tab) {
				this.multiLevelTabs.setActiveTab(tab);
			}
		}
		item = this.getComponent(item);
		if (!item || this.fireEvent('beforetabchange', this, item, this.activeTab) === false) {
			return;
		}
		if (!this.rendered) {
			this.activeTab = item;
			return;
		}
		this.applyStyles(item);
		if (this.activeTab != item) {
			if (this.activeTab) {
				if (this.activeTab.subCaption != undefined) {
					this.setTabCaption(this.activeTab, undefined, false);
				}
			}
			this.activeTab = item;
			if (this.activeTab.subCaption != undefined) {
				this.setTabCaption(this.activeTab, undefined, true);
			}
			this.stack.add(item);
			if (this.collapsed) {
				this.layout.activeItem = item;
				return;
			}
			this.layout.setActiveItem(item, isDeepLayout);
			if (this.layoutOnTabChange && item.doLayout) {
				item.doLayout();
			}
			if (this.scrolling) {
				this.scrollToTab(item, this.animScroll);
			}
			var itemIndex = this.items.indexOf(item);
			var hiddenFieldActiveTabIndexEl = this.hiddenFieldActiveTabIndexEl;
			hiddenFieldActiveTabIndexEl.dom.value = itemIndex;
			this.setProfileData('activetabindex', itemIndex);
			if (deferTabChange) {
				this.deferTabChangeEvent(this.fireTabChangeEvent, this, item, itemIndex, forceTabChange, this.hotKeyTabChangeDelayEvent);
			} else {
				this.fireTabChangeEvent(this, item, itemIndex, forceTabChange);
			}
		}
	},

	deferTabChangeEvent: function(fn, tabPanel, tab, tabIndex, forceTabChange, delay) {
		if (tabPanel.timeoutId) {
			clearTimeout(tabPanel.timeoutId);
		}
		tabPanel.timeoutId = setTimeout(function() {
			fn(tabPanel, tab, tabIndex, forceTabChange);
			delete tabPanel.timeoutId;
		},
			delay);
	},

	fireTabChangeEvent: function(tabPanel, tab, tabIndex, forceTabChange) {
		tab.fireEvent('activate', tab);
		if (forceTabChange !== true) {
			tabPanel.fireEvent('tabchange', tabPanel, tab, tabIndex);
		}
		if (!tab.tabHiddenFieldActivated) {
			tab.tabHiddenFieldActivatedName = tab.id + '_TabActivated';
			var formEl = Ext.get(document.forms[0]);
			tab.tabHiddenFieldActivated = Ext.get(formEl.createChild({
				tag: 'input',
				type: 'hidden',
				name: tab.tabHiddenFieldActivatedName,
				id: tab.tabHiddenFieldActivatedName
			}, undefined, true));
			tab.tabHiddenFieldActivated.dom.value = 'true';
		}
	},

	getActiveTab: function () {
		return this.activeTab || null;
	},

	getActiveTabId: function () {
		var activeTab = this.getActiveTab();
		return (activeTab == null) ? null : activeTab.id;
	},

	getItem: function (item) {
		return this.getComponent(item);
	},

	autoScrollTabs: function () {
		var count = this.items.length;
		var ow = this.header.dom.offsetWidth;
		var tw = this.header.dom.clientWidth - this.toolsWidth - this.tabMargin;
		var wrap = this.stripWrap;
		var marginRight = 18;
		if (this.scrolling) {
			tw = tw - wrap.getLeft(true) - marginRight;
		}
		var wd = wrap.dom;
		var cw = wd.offsetWidth;
		var pos = this.getScrollPos();
		var l = this.edge.getOffsetsTo(this.stripWrap)[0] + pos;

		if (!this.enableTabScroll || count < 1 || cw < 20) {
			if (this.scrollLeft) {
				this.scrollLeft.hide();
				this.scrollRight.hide();
			}
			return;
		}
		if (l <= tw) {
			//wd.scrollLeft = 0;
			if (this.scrolling) {
				this.scrolling = false;
				tw = tw + wrap.getLeft(true) + marginRight;
				this.header.removeClass('x-tab-scrolling');
			}
			wrap.setWidth(tw);
			if (this.scrollLeft) {
				this.scrollLeft.hide();
				this.scrollRight.hide();
			}
		} else {
			if (!this.scrolling) {
				this.header.addClass('x-tab-scrolling');
				tw = tw - wrap.getLeft(true) - marginRight;
			}
			// TODO: зачем это было сделано?
			// tw -= wrap.getMargins('lr');
			wrap.setWidth(tw > 20 ? tw : 20);
			if (!this.scrolling) {
				if (!this.scrollLeft) {
					this.createScrollers();
				} else {
					this.scrollLeft.show();
					this.scrollRight.show();
				}
			}
			this.scrolling = true;
			this.scrollToTab(this.activeTab, true);
			this.updateScrollButtons();
		}
	},

	createScrollers: function () {
		var sl = this.header.insertFirst({
			cls: 'x-tab-scroller-left'
		});
		sl.addClassOnOver('x-tab-scroller-left-over');
		this.leftRepeater = new Ext.util.ClickRepeater(sl, {
			interval: this.scrollRepeatInterval,
			handler: this.onScrollLeft,
			scope: this
		});
		this.scrollLeft = sl;
		var sr = this.header.insertFirst({
			cls: 'x-tab-scroller-right'
		});
		sr.addClassOnOver('x-tab-scroller-right-over');
		this.rightRepeater = new Ext.util.ClickRepeater(sr, {
			interval: this.scrollRepeatInterval,
			handler: this.onScrollRight,
			scope: this
		});
		sr.setStyle('right', this.toolsWidth.toString() + 'px');
		this.scrollRight = sr;
	},

	getScrollWidth: function () {
		return this.edge.getOffsetsTo(this.stripWrap)[0] + this.getScrollPos();
	},

	getScrollPos: function () {
		return parseInt(this.stripWrap.dom.scrollLeft, 10) || 0;
	},

	getScrollArea: function () {
		return parseInt(this.stripWrap.dom.clientWidth, 10) || 0;
	},

	getScrollAnim: function () {
		return { duration: this.scrollDuration, callback: this.updateScrollButtons, scope: this };
	},

	getScrollIncrement: function () {
		return this.scrollIncrement || (this.resizeTabs ? this.lastTabWidth + 2 : 100);
	},

	scrollToTab: function (item, animate) {
		if (!item) { return; }
		var el = this.getTabEl(item);
		var pos = this.getScrollPos(), area = this.getScrollArea();
		var left = Ext.fly(el).getOffsetsTo(this.stripWrap)[0] + pos;
		var addScroll = false;
		if (this.items.length > 0 && item.id == this.items.items[this.items.length - 1].id) {
			addScroll = true;
			left += this.tabMargin;
		}
		var right = left + el.offsetWidth;
		if (left < pos) {
			left -= this.tabMargin;
			this.scrollTo(left, animate);
		} else if (right > (pos + area)) {
			if (this.items.length > 0 && !addScroll) {
				right += this.tabMargin - 1;
			}
			this.scrollTo(right - area, animate);
		}
	},

	scrollTo: function (pos, animate) {
		this.stripWrap.scrollTo('left', pos, animate ? this.getScrollAnim() : false);
		if (!animate) {
			this.updateScrollButtons();
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

	onScrollRight: function () {
		var sw = this.getScrollWidth() - this.getScrollArea();
		var pos = this.getScrollPos();
		var s = Math.min(sw, pos + this.getScrollIncrement()) + this.tabMargin;
		if (s != pos) {
			this.scrollTo(s, this.animScroll);
		}
	},

	onScrollLeft: function () {
		var pos = this.getScrollPos();
		var s = Math.max(0, pos - this.getScrollIncrement());
		if (s != pos) {
			this.scrollTo(s, this.animScroll);
		}
	},

	setEnabled: function (enabled) {
		this.enabled = enabled;
		if (this.optionsButton) {
			this.optionsButton[!enabled ? 'addClass' : 'removeClass']('x-tool-tab-panel-options-disabled');
		}
		if (this.closeButton) {
			this.closeButton[!enabled ? 'addClass' : 'removeClass']('x-tool-tab-panel-close-disabled');
		}
		if (this.toggleCollapseButton) {
			this.toggleCollapseButton[!enabled ? 'addClass' : 'removeClass']('x-tool-tab-panel-collapse-disabled');
		}
		if (!this.items) {
			return;
		}
		var items = this.items.items;
		if (items) {
			Ext.each(items, function (item) {
				item.setEnabled(enabled);
			});
		}
	},

	updateScrollButtons: function () {
		var pos = this.getScrollPos();
		this.scrollLeft[pos == 0 ? 'addClass' : 'removeClass']('x-tab-scroller-left-disabled');
		this.scrollRight[pos >= (this.getScrollWidth() - this.getScrollArea()) ? 'addClass' : 'removeClass']('x-tab-scroller-right-disabled');
	},

	initDraggable: function () {
		this.dd = new Ext.Panel.DD(this, { ddGroup: "DockingDD" });
	},

	moveControl: function (item, position) {
		if (item.isMenuitem) {
			position = position - this.items.length;
			var menu = this.getMenu();
			item.parentMenu.remove(item, true);
			if (item.parentMenu.owner && item.parentMenu.owner.onContentChanged) {
				item.parentMenu.owner.onContentChanged();
			}
			this.insert(position, item);
			return;
		}
		this.multiLevelTabs.removeControl(item.tabHeader);
		item.ownerCt.remove(item, false);
		this.addTab(item, position, false);
		this.setActiveTab(item);
	},

	onBeforeTabDestroy: function () {
		if (this.menu) {
			Ext.destroy(this.menu);
		}
	}

});

Ext.reg('tabpanel', Terrasoft.TabPanel);

Terrasoft.Tab = Ext.extend(Terrasoft.ControlLayout, {
	edges: '0 0 0 0',
	height: '100%',
	width: '100%',
	groupName: "default",
	startNewAlignGroup: true,
	hasHeader: undefined,
	isImportant: false,

	initComponent: function () {
		Terrasoft.Tab.superclass.initComponent.call(this);
		this.addEvents('menuitemclick');
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.menu = new Ext.menu.Menu({ id: Ext.id() });
			this.menu.owner = this;
			this.menu.createItemsFromConfig(this.menuConfig);
		}
	},

	forceFocus: function () {
		var ownerCt = this.ownerCt;
		if (ownerCt.activeTab != this) {
			if (this.tabHeader.hidden == true) {
				return;
			}
			ownerCt.setActiveTab(this);
		}
	},

	getMenu: function () {
		return this.tabHeader.getMenu();
	},

	setImportant: function (isImportant) {
		this.isImportant = isImportant;
		var tabHeader = this.tabHeader;
		if (!tabHeader.rendered) {
			return;
		}
		tabHeader.el[isImportant === true ? 'addClass' : 'removeClass']('x-tab-panel-highlight-important');
		if (this.ownerCt.isFirstTabImportant()) {
			if (!this.ownerCt.el.hasClass('x-tab-panel-important-first')) {
				this.ownerCt.el.addClass('x-tab-panel-important-first');
			}
		} else {
			this.ownerCt.removeClass('x-tab-panel-important-first');
			if (this.ownerCt.hasImportantTabs()) {
				this.ownerCt.removeClass('x-tab-panel-important');
			}
		}
		if (this.designMode) {
			this.ownerCt.updateDisplayStyle();
		}
		this.ownerCt.applyStyles(this);
	},

	setHidden: function (hidden) {
		Terrasoft.Tab.superclass.setHidden.call(this, hidden);
		if (this.tabHeader) {
			this.tabHeader.setHidden(hidden);
		}
	},

	setImage: function (value) {
		if (value) {
			this.imageConfig = value;
		}
		if (this.tabHeader) {
			this.tabHeader.setImage(value);
		}
	},

	ensureMenuCreated: function () {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({ id: Ext.id() });
			this.menu.owner = this;
		}
	},

	setAutowidth: function (autoWidth) {
		this.autoWidth = autoWidth;
		this.setWidth(this.width);
	},

	insert: function (index, item) {
		if (item.isMenuitem) {
			this.ensureMenuCreated();
			this.tabHeader.insert(index, item, false, this);
			return item;
		}
		return Terrasoft.Tab.superclass.insert.call(this, index, item);
	},

	removeControl: function (item) {
		if (item.isMenuitem) {
			this.tabHeader.removeControl(item);
			return item;
		}
		Terrasoft.Tab.superclass.removeControl.call(this, item);
	},

	moveControl: function (control, position, force) {
		if (control.isMenuitem) {
			this.tabHeader.moveControl(control, position);
			return true;
		}
		if (typeof control == 'string') {
			control = Ext.getCmp(control);
		}
		if (!control || position < 0) {
			return false;
		}
		var isInsideMoving = (this == control.ownerCt);
		var maxPosition = 0;
		if (this.items) {
			maxPosition = (isInsideMoving) ? this.items.length - 1 : this.items.length;
		}
		if (position > maxPosition) {
			return false;
		}
		var oldPosition;
		if (isInsideMoving) {
			oldPosition = this.items.indexOf(control);
			if (oldPosition == position) {
				return false;
			}
		}
		if (force !== true &&
				this.fireEvent('beforecontrolmove', this.id, control.id, position) === false) {
			return false;
		}
		if (isInsideMoving) {
			this.items.removeAt(oldPosition);
			this.items.insert(position, control);
			this.onContentChanged();
		} else {
			var oldOwner = control.ownerCt;
			control.margins = Ext.apply({}, this.layout.defaultMargins);
			oldOwner.remove(control, false, true);
			this.insert(position, control);
			this.onContentChanged();
			oldOwner.onContentChanged();
			this.ownerCt.setActiveTab(this);
		}
		this.fireEvent('controlmove', this.id, control.id, position);
		return true;
	},

	setSubCaption: function (subCaption) {
		this.ownerCt.setTabSubCaption(this, subCaption);
	},

	initDefaultLayout: function () {
		Terrasoft.Tab.superclass.initDefaultLayout.apply(this, arguments);
		this.layoutConfig.direction = 'vertical';
	},

	setCaption: function (caption) {
		this.tabHeader.setCaption(caption);
	},

	onContentChanged: function () {
		this.tabHeader.onContentChanged();
	},

	applyDesignConfig: function (designConfig) {
		/*var designLayout = new Terrasoft.ControlLayout({id:this.id+'SubLayout',designMode:true,designConfig:designConfig});
		this.add(designLayout);*/
	}
});

Ext.reg('tab', Terrasoft.Tab);

Terrasoft.ScriptEditTab = Ext.extend(Terrasoft.Tab, {
	width: '100%',
	height: '100%',
	editingItem: null,
	serviceName: 'Services/DataService',
	getSignatureMethodName: 'GetSchemaMethodSignature',
	checkForModificationsBeforeClose: true,
	waringMessageCaption: '',
	waringMessage: '',
	designModeManager: null,
	schemaDataSource: null,
	caption: '',

	initComponent: function() {
		Terrasoft.ScriptEditTab.superclass.initComponent.call(this);
		var stringList = Ext.StringList('WebApp.ProcessSchemaDesigner');
		this.waringMessageCaption = stringList.getValue('Messages.CloseScriptEditTab.Caption');
		this.waringMessage = stringList.getValue('Messages.CloseScriptEditTab.Msg');
		this.saveCaption = stringList.getValue('ScriptEditTab.Save.Caption');
		this.saveAndCloseCaption = stringList.getValue('ScriptEditTab.SaveAndClose.Caption');
		this.closeCaption = stringList.getValue('ScriptEditTab.Close.Caption');
		var mainLayput = new Terrasoft.ControlLayout({
			id: this.id + '_mainLayout',
			direction: 'vertical',
			width: '100%',
			height: '100%'
		});
		var toolsLayout = this.toolsLayout = this.createToolsLayout();
		var signatureLayout = this.signatureLayout = this.createSignatureLayout();
		var silverlightContainer = this.silverlightContainer = this.createSilverlightContainer();
		mainLayput.add(toolsLayout);
		mainLayput.add(signatureLayout);
		mainLayput.add(silverlightContainer);
		this.add(mainLayput);
	},

	initEvents: function() {
		var schemaDataSource = this.schemaDataSource;
		if (schemaDataSource) {
			schemaDataSource.on('rowloaded', this.onSchemaDataSourceRowLoaded, this);
		}
		this.silverlightContainer.on('onpluginloaded', this.onSilverlightContainerPluginLoaded, this);
		var tabPanel = this.ownerCt;
		if (!tabPanel) {
			return;
		}
		tabPanel.on('beforetabchange', this.onBeforeTabChange, this);
	},

	onSchemaDataSourceRowLoaded: function(dataSource, rows) {
		var row = rows[0];
		var primaryColumnName = dataSource.getPrimaryColumnName();
		var primaryColumnValue = row[primaryColumnName];
		if (primaryColumnValue != this.itemUId) {
			return;
		}
		var primaryDisplayColumnName = dataSource.structure.primaryDisplayColumnName || "";
		var primaryDisplayColumnValue = row[primaryDisplayColumnName];
		this.setCaption(primaryDisplayColumnValue);
		var methodSignature = this.editingItem.signature;
		methodSignature.name = primaryDisplayColumnValue;
		var signatureContainer = this.signatureLayout.el.dom.firstChild;
		var methodSignatureString = this.getMethodSignatureString(methodSignature);
		signatureContainer.innerHTML = methodSignatureString;
	},

	clearEvents: function() {
		var schemaDataSource = this.schemaDataSource;
		if (schemaDataSource) {
			schemaDataSource.un('rowloaded', this.onSchemaDataSourceRowLoaded, this);
		}
		this.silverlightContainer.un('onpluginloaded', this.onSilverlightContainerPluginLoaded, this);
		var tabPanel = this.ownerCt;
		if (!tabPanel) {
			return;
		}
		tabPanel.un('beforetabchange', this.onBeforeTabChange, this);
	},

	onBeforeTabChange: function(tabPanel, activeTab) {
		if (activeTab === this || this.hidden == true) {
			return;
		}
		this.saveScriptToTab();
	},

	afterRender: function() {
		Terrasoft.ScriptEditTab.superclass.afterRender.call(this);
		this.initEvents();
	},

	onSilverlightContainerPluginLoaded: function() {
		var editingItem = this.editingItem;
		this.silverlightContainer.scriptableObject.SetText(editingItem.value);
		this.silverlightContainer.scriptableObject.SetText(editingItem.value);
		if (editingItem.headerText && editingItem.footerText) {
			this.silverlightContainer.scriptableObject.SetHeaderAndFooterText(editingItem.headerText, editingItem.footerText);
		}
		editingItem.startValue = this.silverlightContainer.scriptableObject.GetText();
	},

	setEditingItem: function(editingItemConfig) {
		this.itemUId = editingItemConfig.itemUId;
		this.editingItem = editingItemConfig;
		var url = Terrasoft.getWebServiceUrl(this.serviceName, this.getSignatureMethodName);
		Ext.Ajax.request({
			url: url,
			success: this.onSuccessResponse,
			failure: this.onFailureResponse,
			scope: this,
			params: this.getParams()
		});
	},

	getParams: function () {
		var buf = [];
		var designModeManager = this.designModeManager;
		var isEmbedded = designModeManager.isEmbedded === true;
		var managerName = isEmbedded ? designModeManager.ownerSchemaManagerName : designModeManager.managerName;
		var schemaUId = isEmbedded ? designModeManager.parentSchemaUId : designModeManager.schemaUId;
		var filters = [];
		filters.push(["managerName", managerName]);
		filters.push(["schemaUId", schemaUId]);
		filters.push(["itemUId", this.editingItem.itemUId]);
		filters.push(["isEmbedded", isEmbedded]);
		buf.push("filters=", Ext.encode(filters));
		return buf.join("");
	},

	onSuccessResponse: function (response) {
		var xmlData = response.responseXML;
		var root = xmlData.documentElement || xmlData;
		var data = root.text || root.textContent;
		var signatureLayout = this.signatureLayout;
		if (Ext.isEmpty(data)) {
			signatureLayout.setVisible(false);
			return;
		}
		var result = Ext.decode(data);
		var value = result.value;
		var editingItem = this.editingItem || {};
		editingItem.value = value;
		editingItem.startValue = value;
		editingItem.propertyName = result.propertyName;
		editingItem.signature = result.signature;
		editingItem.headerText = result.headerText;
		editingItem.footerText = result.footerText;
		if (this.silverlightContainer.isPluginLoaded()) {
			this.onSilverlightContainerPluginLoaded();
		}
		var methodInfo = result.signature;
		var signatureContainer = signatureLayout.el.dom.firstChild;
		Ext.get(signatureContainer).addClass('signatureclass');
		signatureLayout.setVisible(methodInfo.visible);
		var methodSignatureString = this.getMethodSignatureString(methodInfo);
		signatureContainer.innerHTML = methodSignatureString;
	},

	getMethodSignatureString: function(methodInfo) {
		var override = (methodInfo.isOverride) ? 'override ' : '';
		var retVal = this.highlight(methodInfo.retType) + ' ';
		var args = '';
		var methodArgs = methodInfo.args;
		var needComma = false;
		var methodName = methodInfo.name + methodInfo.nameSuffix;
		for (var i = 0, argsLength = methodArgs.length; i < argsLength; i++) {
			var argument = methodArgs[i];
			var argType = this.highlight(argument.type);
			var params = (argument.isParams) ? 'params ' : '';
			args += (needComma ? ', ' : '') + params + argType + ' ' + argument.name;
			needComma = true;
		}
		args = '(' + args + ')';
		var methodSignatureString = override + retVal + methodName + args;
		return methodSignatureString;
	},

	highlight: function(text) {
		return '<span style="color:blue">' + Ext.util.Format.htmlEncode(text) + '</span>';
	},

	onFailureResponse: function () {
		var signatureLayout = this.signatureLayout;
		if (signatureLayout.rendered) {
			signatureLayout.setVisible(false);
		} else {
			signatureLayout.hidden = true;
		}
	},

	saveScriptToTab: function() {
		this.editingItem.value = this.silverlightContainer.scriptableObject.GetText();
	},

	saveScript: function() {
		this.saveScriptToTab();
		var editingItem = this.editingItem;
		var propertyValue = this.silverlightContainer.scriptableObject.GetText();
		this.designModeManager.setPropertyValue(editingItem.itemUId, editingItem.propertyName, propertyValue);
		editingItem.startValue = propertyValue;
	},

	saveAndClose: function() {
		this.saveScript();
		this.close();
	},

	cloaseTabUserAction: function(button) {
		switch (button) {
			case 'no':
				this.close(true);
				break;
			case 'yes':
				this.saveAndClose();
				break;
			case 'cancel':
				return;
		}
	},

	close: function(force) {
		if (this.checkForModificationsBeforeClose && force !== true) {
			var editingItem = this.editingItem;
			var value = this.silverlightContainer.scriptableObject.GetText();
			if (editingItem.startValue !== value) {
				Ext.MessageBox.message(
					this.waringMessageCaption,
					this.waringMessage,
					Ext.MessageBox.YESNOCANCEL,
					Ext.MessageBox.WARNING,
					this.cloaseTabUserAction,
					this);
				return;
			}
		}
		this.clearEvents();
		var tabPanel = this.ownerCt;
		if (!tabPanel) {
			return;
		}
		tabPanel.removeControl(this);
	},

	createSilverlightContainer: function() {
		var silverlightContainer = new Terrasoft.SilverlightContainer({
			id: this.id + '_silverlightContainer',
			width: '100%',
			height: '100%',
			parameters: {
				source: '/ClientBin/Terrasoft.UI.WindowsControls.SyntaxMemo.xap'
			},
			scriptableEvents: ["FocusChanged"]
		});
		return silverlightContainer;
	},

	createSignatureLayout: function () {
		var signatureLayout = new Terrasoft.ControlLayout({
			id: this.id + '_signatureLayout',
			width: '100%',
			height: '20px'
		});
		return signatureLayout;
	},

	createToolsLayout: function () {
		var toolsLayout = new Terrasoft.ControlLayout({
			id: this.id + '_toolsLayout',
			width: '100%',
			displayStyle: 'topbar',
			margins: '0 0 0 0',
			edges: '0 0 1 0'
		});
		var searchToolButton = new Terrasoft.Button({
			id: toolsLayout.id + '_searchButton',
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.WebApp',
				resourceItemName: 'common-ico-outline.png'
			}
		});
		var showWhiteSpacesToolButton = new Terrasoft.Button({
			id: toolsLayout.id + '_showWhiteSpacesButton',
			toggleGroup: toolsLayout.id + '_showWhiteSpacesButton_group',
			allowDepress: true,
			imageAsSprite: false,
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.WebApp',
				resourceItemName: 'syntaxmemoedit-switchwhitespacevisible.png'
			}
		});
		var saveToolButton = new Terrasoft.Button({
			id: toolsLayout.id + '_saveButton',
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.WebApp.BaseDesigner',
				resourceItemName: 'commondesigner-save.png'
			},
			menuConfig:[
				{
					caption: this.saveCaption ,
					action: 'save',
					imageConfig: {
						source: 'ResourceManager',
						resourceManagerName: 'Terrasoft.WebApp.BaseDesigner',
						resourceItemName: 'commondesigner-save.png'
					}
				},
				{
					caption: this.saveAndCloseCaption,
					action: 'saveAndClose',
					imageConfig: {
						source: 'ResourceManager',
						resourceManagerName: 'Terrasoft.WebApp.BaseDesigner',
						resourceItemName: 'commondesigner-save.png'
					}
				}
			]
		});
		var closeToolButton = new Terrasoft.Button({
			id: toolsLayout.id + '_closeButton',
			caption: this.closeCaption
		});
		searchToolButton.on('click', this.onSearchToolClick, this);
		showWhiteSpacesToolButton.on('click', this.onShowWhiteSpacesToolClick, this);
		closeToolButton.on('click', this.onCloseToolButton, this);
		saveToolButton.on('menuitemclick', this.onSaveToolButtonMenuClick, this);
		toolsLayout.add(saveToolButton);
		toolsLayout.add(new Ext.Spacer({
			size: '100%',
			stripeVisible: true
		}));
		toolsLayout.add(searchToolButton);
		toolsLayout.add(showWhiteSpacesToolButton);
		toolsLayout.add(new Ext.Spacer({
			size: '100%'
		}));
		toolsLayout.add(closeToolButton);
		return toolsLayout;
	},

	onSaveToolButtonMenuClick: function(menuItem) {
		var action = menuItem.action;
		switch (action) {
			case 'save':
				this.saveScript();
				break;
			case 'saveAndClose':
				this.saveAndClose();
				break;
		}
	},

	onCloseToolButton: function() {
		this.close();
	},

	onSearchToolClick: function() {
		this.silverlightContainer.scriptableObject.SwitchSearchViewVisible();
	},

	onShowWhiteSpacesToolClick: function() {
		this.silverlightContainer.scriptableObject.SwitchWhitespaceVisible();
	}

});

Terrasoft.TabPanel.TabProxy = function(tabPanel, stripTab, panel, config) {
	this.tabPanel = tabPanel;
	this.panel = panel;
	this.stripTab = stripTab;
	this.id = this.panel.id + '-ddproxy';
	Ext.apply(this, config);
};

Terrasoft.TabPanel.TabProxy.prototype = {
	insertProxy: true,
	setStatus: Ext.emptyFn,
	reset: Ext.emptyFn,
	update: Ext.emptyFn,
	stop: Ext.emptyFn,
	sync: Ext.emptyFn,
	repair: Ext.emptyFn,

	getEl: function() {
		return this.ghost;
	},

	getGhost: function() {
		return this.ghost;
	},

	getProxy: function() {
		return this.proxy;
	},

	hide: function() {
		if (this.ghost) {
			if (this.proxy) {
				this.proxy.remove();
				delete this.proxy;
			}
			this.ghost.remove();
			delete this.ghost;
		}
	},

	show: function() {
		if (!this.ghost) {
			var bordersWidth = 2;
			var panel = this.panel;
			if (!panel.rendered || !panel.isVisible()) {
				panel = panel.ownerCt || null;
			}
			var el = new Ext.Element(document.createElement('div'));
			el.addClass('x-tab-proxy');
			var stripEl = el.createChild({
				tag: 'ul',
				cls: 'x-tab-strip x-tab-strip-' + this.tabPanel.tabPosition
			});
			if (panel) {
				var height = panel.bwrap.getHeight();
				var width = panel.el.dom.offsetWidth;
				if (height > 0 && width > 0) {
					el.dom.style.width = el.addUnits(width + bordersWidth);
					var tabHeight = Ext.get(this.stripTab).getHeight();
					stripEl.dom.style.width = el.addUnits(width);
					stripEl.dom.style.height = el.addUnits(tabHeight);
					var panelEl = el.createChild({ tag: 'div' });
					panelEl.dom.style.height = el.addUnits(height);
					panelEl.dom.style.width = el.addUnits(width);
					panelEl.addClass('x-tab-proxy-panel');
				}
			}
			var stripTabEl = Ext.get(this.stripTab.cloneNode(true));
			stripTabEl.addClass(['x-tab-strip-' + this.tabPanel.tabPosition, 'x-tab-strip', 'x-tab-strip']);
			stripTabEl.id = Ext.id();
			stripEl.appendChild(stripTabEl);
			this.el =
				new Ext.Layer({ shadow: false, useDisplay: true, constrain: false });
			this.el.appendChild(el);
			this.ghost = this.el;
			this.el.show();
		}
	}
	
};

Terrasoft.TabPanel.TabDragSource = function(tabPanel, stripTab, cfg) {
	this.tabPanel = tabPanel;
	this.stripTab = stripTab;
	this.dragData = { stripTab: stripTab };
	var item = this.tabPanel.getItemByStripTab(stripTab);
	this.proxy = new Terrasoft.TabPanel.TabProxy(tabPanel, stripTab, item, cfg);
	Terrasoft.TabPanel.TabDragSource.superclass.constructor.call(this, stripTab, cfg);
	var h = stripTab;
	if (h) {
		this.setHandleElId(h.id);
	}
	this.scroll = false;
};

Ext.extend(Terrasoft.TabPanel.TabDragSource, Ext.dd.DragSource, {
	showFrame: Ext.emptyFn,
	startDrag: Ext.emptyFn,

	b4StartDrag: function(x, y) {
		this.proxy.show();
	},

	b4MouseDown: function(e) {
		var x = e.getPageX();
		var y = e.getPageY();
		this.autoOffset(x, y);
	},

	onInitDrag: function(x, y) {
		this.onStartDrag(x, y);
		return true;
	},

	getRepairXY: function(e, data) {
		return null;
	},

	createFrame: Ext.emptyFn,

	getDragEl: function(e) {
		return this.proxy.el.dom;
	},

	endDrag: function(e) {
		this.proxy.hide();
	},

	autoOffset: function(x, y) {
		x -= this.startPageX;
		y -= this.startPageY;
		this.setDelta(x, y);
	}
});

Terrasoft.TabPanel.DropTarget = function(tabPanel, strip, cfg) {
	this.strip = strip;
	this.tabPanel = tabPanel;
	cfg = cfg || {};
	cfg.ddGroup = cfg.ddGroup || "TabPanelTabs";
	cfg.priority = 0;
	Terrasoft.TabPanel.DropTarget.superclass.constructor.call(this, strip, cfg);
};

Ext.extend(Terrasoft.TabPanel.DropTarget, Ext.dd.DropTarget, {

	notifyDrop: function(dd, e, data) {
		var isInsideDragging = (this.tabPanel == dd.tabPanel);
		if (!isInsideDragging && this.tabPanel.validDragSourceIds &&
				Ext.isArray(this.tabPanel.validDragSourceIds)) {
			var isValidDragSource =
				(this.tabPanel.validDragSourceIds.indexOf(dd.tabPanel.id) != -1);
			if (!isValidDragSource) {
				return false;
			}
		}
		var item = dd.tabPanel.getItemByStripTab(data.stripTab);
		if (!isInsideDragging && item.allowDraggingOutside !== true) {
			return false;
		}
		var x = Ext.lib.Event.getPageX(e);
		var nodes = this.strip.dom.childNodes;
		var tabsSpaceWidth = 4;
		var index = -1;
		var lastTabIndex = -1;
		var lastLeft = -1;
		var oldIndex = -1;
		for (var i = 0; i < nodes.length; i++) {
			if (nodes[i].tagName != 'LI' || !this.tabPanel.isStripTab(nodes[i])) {
				continue;
			}
			if (nodes[i].id == data.stripTab.id) {
				oldIndex = i;
			}
			var r = Ext.lib.Dom.getRegion(nodes[i]);
			lastLeft = r.left;
			lastTabIndex = i;
			if (r.left - tabsSpaceWidth < x && x < r.right) {
				var isBefore = (x - r.left) <= ((r.right - r.left) / 2);
				index = isBefore ? i : i + 1;
				break;
			}
		}
		if (index == -1) {
			if (x > lastLeft) {
				index = lastTabIndex + 1;
			} else {
				return false;
			}
		}
		if (isInsideDragging) {
			if (oldIndex != -1 && oldIndex < index) {
				index = index - 1;
			}
			if (index == oldIndex) {
				return true;
			}
			dd.tabPanel.strip.dom.removeChild(data.stripTab);
			this.tabPanel.initTab(item, index);
			if (this.tabPanel.activeTab == item) {
				this.tabPanel.activeTab = null;
				this.tabPanel.setActiveTab(item);
			}
		} else {
			dd.tabPanel.strip.dom.removeChild(data.stripTab);
			dd.tabPanel.remove(item, false);
			this.tabPanel.addTab(item, index, false);
			this.tabPanel.setActiveTab(item);
		}
		if (dd.tabPanel.items.length == 0) {
			if (dd.tabPanel.ownerCt) {
				dd.tabPanel.ownerCt.remove(dd.tabPanel, true);
			}
		}
		return true;
	}
});

Terrasoft.TabPanel.prototype.activate = Terrasoft.TabPanel.prototype.setActiveTab;

Terrasoft.TabPanel.AccessStack = function() {
	var items = [];
	return {
		add: function(item) {
			items.push(item);
			if (items.length > 10) {
				items.shift();
			}
		},

		remove: function(item) {
			var s = [];
			for (var i = 0, len = items.length; i < len; i++) {
				if (items[i] != item) {
					s.push(items[i]);
				}
			}
			items = s;
		},

		next: function() {
			return items.pop();
		}
	};
};
