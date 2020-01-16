Ext.Panel = Ext.extend(Ext.Container, {
	baseCls: 'x-panel',
	collapsedCls: 'x-panel-collapsed',
	maskDisabled: true,
	animCollapse: false,
	headerAsText: true,
	buttonAlign: 'right',
	collapseFirst: true,
	minButtonWidth: 75,
	elements: 'body',
	toolTarget: 'header',
	collapseEl: 'bwrap',
	slideAnchor: 't',
	disabledClass: '',
	deferHeight: true,
	expandDefaults: {
		duration: .25
	},
	collapseDefaults: {
		duration: .25
	},
	
	moveControl: function(control, position, force) {
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
			oldOwner.remove(control, false);
			this.insert(position, control);
			this.onContentChanged();
			oldOwner.onContentChanged();
		}
		this.fireEvent('controlmove', this.id, control.id, position);
		return true;
	},

	initComponent: function() {
		if (this.useDefaultLayout !== false) {
			this.initDefaultLayout();
		}
		Ext.Panel.superclass.initComponent.call(this);
		this.addEvents(
			'bodyresize',
			'captionchange',
			'collapse',
			'expand',
			'beforecollapse',
			'beforeexpand',
			'beforeclose',
			'close',
			'activate',
			'deactivate'
		);
		this.appearCls = this.baseCls;
		if (this.appearance) {
			this.appearCls = this.appearance != 'panel' ? 'ts-window' : 'x-panel';
		}

		if (this.tbar) {
			this.elements += ',tbar';
			if (typeof this.tbar == 'object') {
				this.topToolbar = this.tbar;
			}
			delete this.tbar;
		}
		if (this.bbar) {
			this.elements += ',bbar';
			if (typeof this.bbar == 'object') {
				this.bottomToolbar = this.bbar;
			}
			delete this.bbar;
		}

		if (this.header === true) {
			this.elements += ',header';
			delete this.header;
		} else if (this.caption && this.header !== false) {
			this.elements += ',header';
		}

		if (this.footer === true) {
			this.elements += ',footer';
			delete this.footer;
		}

		if (this.buttons) {
			var btns = this.buttons;
			this.buttons = [];
			for (var i = 0, len = btns.length; i < len; i++) {
				if (btns[i].render) {
					btns[i].ownerCt = this;
					this.buttons.push(btns[i]);
				} else {
					this.addButton(btns[i]);
				}
			}
		}
		if (this.autoLoad) {
			this.on('render', this.doAutoLoad, this, { delay: 10 });
		}
	},

	initDefaultLayout: function() {
		this.layout = 'box';
		this.layoutConfig = {align: 'left'};
	},

	createElement: function(name, pnode) {
		if (this[name]) {
			pnode.appendChild(this[name].dom);
			return;
		}

		if (name === 'bwrap' || this.elements.indexOf(name) != -1) {
			if (this[name + 'Cfg']) {
				this[name] = Ext.fly(pnode).createChild(this[name + 'Cfg']);
			} else {
				var el = document.createElement('div');
				el.className = this[name + 'Cls'];
				this[name] = Ext.get(pnode.appendChild(el));
			}
		}
	},

	onRender: function(ct, position) {
		Ext.Panel.superclass.onRender.call(this, ct, position);
		this.createClasses();
		if (this.el) {
			this.el.addClass(this.baseCls);
			this.header = this.el.down('.' + this.headerCls);
			this.bwrap = this.el.down('.' + this.bwrapCls);
			var cp = this.bwrap ? this.bwrap : this.el;
			this.tbar = cp.down('.' + this.tbarCls);
			this.body = cp.down('.' + this.bodyCls);
			this.bbar = cp.down('.' + this.bbarCls);
			this.footer = cp.down('.' + this.footerCls);
			this.fromMarkup = true;
		} else {
			this.el = ct.createChild({
				id: this.id,
				cls: this.appearCls
			}, position);
		}
		var el = this.el, d = el.dom;

		if (this.cls) {
			this.el.addClass(this.cls);
		}

		if (this.buttons) {
			this.elements += ',footer';
		}

		if (this.frame) {
			var boxMarkup = '<div class="{0}-tc"></div><div class="{1}-mc"></div><div class="{1}-bc"></div>';
			el.insertHtml('afterBegin', String.format(boxMarkup, this.appearCls, this.baseCls));

			this.createElement('header', d.firstChild);
			this.createElement('bwrap', d);

			var bw = this.bwrap.dom;
			var ml = d.childNodes[1], bl = d.childNodes[2];
			bw.appendChild(ml);
			bw.appendChild(bl);

			var mc = bw.firstChild;
			if (this.frameStyle) {
				Ext.fly(mc).applyStyles(this.frameStyle);
			}
			this.createElement('tbar', mc);
			this.createElement('body', mc);
			this.createElement('bbar', mc);
			this.createElement('footer', bw.lastChild);

			if (!this.footer) {
				this.bwrap.dom.lastChild.className += ' x-panel-nofooter';
			}
		} else {
			this.createElement('header', d);
			this.createElement('bwrap', d);

			var bw = this.bwrap.dom;
			this.createElement('tbar', bw);
			this.createElement('body', bw);
			this.createElement('bbar', bw);
			this.createElement('footer', bw);

			if (!this.header) {
				this.body.addClass(this.bodyCls + '-noheader');
				if (this.tbar) {
					this.tbar.addClass(this.tbarCls + '-noheader');
				}
			}
		}

		if (!this.header) {
			this.el.dom.firstChild.className += ' x-panel-noheader';
		}

		if (this.border === false) {
			this.el.addClass(this.baseCls + '-noborder');
			this.body.addClass(this.bodyCls + '-noborder');
			if (this.header) {
				this.header.addClass(this.headerCls + '-noborder');
			}
			if (this.footer) {
				this.footer.addClass(this.footerCls + '-noborder');
			}
			if (this.tbar) {
				this.tbar.addClass(this.tbarCls + '-noborder');
			}
			if (this.bbar) {
				this.bbar.addClass(this.bbarCls + '-noborder');
			}
		}

		if (this.bodyBorder === false) {
			this.body.addClass(this.bodyCls + '-noborder');
		}

		if (this.bodyStyle) {
			this.body.applyStyles(this.bodyStyle);
		}

		this.bwrap.addClass(this.bodyWrapClass);
		this.body.addClass(this.bodyClass);

		this.bwrap.enableDisplayMode('block');

		if (this.header) {
			this.header.unselectable();
			if (this.headerAsText) {
				this.headerCaptionEl = this.header.insertHtml("afterBegin",
					'<span class="' + this.headerTextCls + '">' + this.header.dom.innerHTML + '</span>', true);
			}
		}
		if (this.floating) {
			this.makeFloating(this.floating);
		}
		if (this.collapsible) {
			this.tools = this.tools ? this.tools.slice(0) : [];
			if (!this.hideCollapseTool) {
				this.tools[this.collapseFirst ? 'unshift' : 'push']({
					id: 'toggle',
					handler: this.toggleCollapse,
					scope: this
				});
			}
			if (this.captionCollapse && this.header) {
				this.header.child('span').on('click', this.toggleCollapse, this);
				this.header.child('span').setStyle('cursor', 'pointer');
			}
		}

		if (this.tools) {
			var ts = this.tools;
			this.tools = {};
			this.addTool.apply(this, ts);
		} else {
			if (this.headerCaptionEl) {
				this.headerCaptionEl.setStyle('margin-left', '13px');
			}
			this.tools = {};
		}

		if (this.buttons && this.buttons.length > 0) {
			var tb = this.footer.createChild({ cls: "x-panel-btns x-panel-btns-" + this.buttonAlign }, null, true);
			for (var i = 0, len = this.buttons.length; i < len; i++) {
				var b = this.buttons[i];
				var td = document.createElement('div');
				td.className = 'x-panel-btn';
				b.render(tb.appendChild(td));
			}
		}

		if (this.tbar && this.topToolbar) {
			this.body.addClass('x-toolbar');
			if (Ext.isArray(this.topToolbar)) {
				this.topToolbar = new Terrasoft.ControlLayout(this.topToolbar);
			}
			this.topToolbar.render(this.tbar);
			this.topToolbar.ownerCt = this;
		}
		if (this.bbar && this.bottomToolbar) {
			if (Ext.isArray(this.bottomToolbar)) {
				this.bottomToolbar = new Terrasoft.ControlLayout(this.bottomToolbar);
			}
			this.bottomToolbar.render(this.bbar);
			this.bottomToolbar.ownerCt = this;
		}
		this.isOwnerTabPanel = (this.ownerCt && this.ownerCt.xtype == 'tabpanel');
		if (this.enableDrop) {
			this.initializeDropZone();
			if (this.dockSite && !this.isOwnerTabPanel) {
				this.ddDocking = new Ext.Panel.DropTarget(this);
			}
		}
		if (this.customBgCls) {
			if (this.bwrap) {
				this.bwrap.addClass(this.customBgCls);
			}
			if (this.body) {
				this.body.addClass(this.customBgCls);
			}
		}
	},

	afterRender: function() {
		if (this.fromMarkup && this.height === undefined && !this.autoHeight) {
			this.height = this.el.getHeight();
		}
		if (this.floating && !this.hidden && !this.initHidden) {
			this.el.show();
		}
		if (this.caption) {
			this.setCaption(this.caption);
		}
		this.setAutoScroll();
		if (this.html) {
			this.body.update(typeof this.html == 'object' ?
							Ext.DomHelper.markup(this.html) :
							this.html);
			delete this.html;
		}
		if (this.contentEl) {
			var ce = Ext.getDom(this.contentEl);
			if (!ce) {
				this.autoCreateContentElement(this.contentEl);
				ce = Ext.getDom(this.contentEl);
			}
			Ext.fly(ce).removeClass(['x-hidden', 'x-hide-display']);
			this.body.dom.appendChild(ce);
		}
		Ext.Panel.superclass.afterRender.call(this);
		this.initEvents();
	},

	initEvents: function() {
		if (this.keys) {
			this.getKeyMap();
		}
		if (this.draggable && !this.isOwnerTabPanel) {
			this.initDraggable();
		}
	},

	initTools: Ext.emptyFn,

	initializeDropZone: function() {
		this.dropZone = new Ext.dd.DropZone(this.getDropZoneElement(),
		{
			ddGroup: this.ddGroup,
			notifyOver: function(src, e, data) {
				return src.dropAllowed;
			} .createDelegate(this),
			notifyDrop: function(src, e, data) {
				return true;
			} .createDelegate(this)
		});
	},

	getDropZoneElement: function() {
		return Ext.get(this.contentEl || this.body);
	},

	makeFloating: function(cfg) {
		this.floating = true;
		this.el = new Ext.Layer(
        typeof cfg == 'object' ? cfg : {
        	shadow: this.shadow !== undefined ? this.shadow : 'sides',
        	shadowOffset: this.shadowOffset,
        	constrain: false,
        	shim: this.shim === false ? false : undefined
        }, this.el
    );
	},

	getTopToolbar: function() {
		return this.topToolbar;
	},

	getBottomToolbar: function() {
		return this.bottomToolbar;
	},

	addButton: function(config, handler, scope) {
		var bc = {
			handler: handler,
			scope: scope,
			minWidth: this.minButtonWidth,
			hideParent: true
		};
		if (typeof config == "string") {
			bc.text = config;
		} else {
			Ext.apply(bc, config);
		}
		var btn = this.createPanelButton(bc);
		btn.ownerCt = this;
		if (!this.buttons) {
			this.buttons = [];
		}
		this.buttons.push(btn);
		return btn;
	},

	createPanelButton: function(bc) {
		return new Ext.Button(bc);
	},

	addTool: function() {
		if (!this[this.toolTarget]) {
			return;
		}
		if (!this.toolTemplate) {
			var tt = new Ext.Template('<img class="x-tool x-tool-{id}" src="' + Ext.BLANK_IMAGE_URL + '"/>');
			tt.disableFormats = true;
			tt.compile();
			Ext.Panel.prototype.toolTemplate = tt;
		}
		for (var i = 0, a = arguments, len = a.length; i < len; i++) {
			var tc = a[i], overCls = 'x-tool-' + tc.id + '-over';
			var clickCls = 'x-tool-' + tc.id + '-click';
			var t = this.toolTemplate.insertFirst((tc.align !== 'left') ? this[this.toolTarget] : this[this.toolTarget].child('span'), tc, true);
			this.tools[tc.id] = t;
			//t.enableDisplayMode('inline');
			t.on('click', this.createToolHandler(t, tc, overCls, this));
			if (tc.on) {
				t.on(tc.on);
			}
			if (tc.hidden) {
				t.hide();
			}
			if (tc.qtip) {
				if (typeof tc.qtip == 'object') {
					Ext.QuickTips.register(Ext.apply({
						target: t.id
					}, tc.qtip));
				} else {
					t.dom.qtip = tc.qtip;
				}
			}
			t.addClassOnOver(overCls);
			t.addClassOnClick(clickCls);
		}
	},

	onShow: function() {
		if (this.floating) {
			return this.el.show();
		}
		Ext.Panel.superclass.onShow.call(this);
	},

	onHide: function() {
		if (this.floating) {
			return this.el.hide();
		}
		Ext.Panel.superclass.onHide.call(this);
	},

	createToolHandler: function(t, tc, overCls, panel) {
		return function(e) {
			t.removeClass(overCls);
			e.stopEvent();
			if (tc.handler) {
				tc.handler.call(tc.scope || t, e, t, panel);
			}
		};
	},

	setAutoScroll: function() {
		if (this.rendered && this.autoScroll) {
			var el = this.body || this.el;
			if (el) {
				el.setOverflow('auto');
			}
		}
	},

	getKeyMap: function() {
		if (!this.keyMap) {
			this.keyMap = new Ext.KeyMap(this.el, this.keys);
		}
		return this.keyMap;
	},

	initDraggable: function() {
		this.dd = new Ext.Panel.DD(this, this.initialConfig);
	},

	beforeEffect: function() {
		if (this.floating) {
			this.el.beforeAction();
		}
		this.el.addClass('x-panel-animated');
	},

	afterEffect: function() {
		this.syncShadow();
		this.el.removeClass('x-panel-animated');
	},

	createEffect: function(a, cb, scope) {
		var o = {
			scope: scope,
			block: true
		};
		if (a === true) {
			o.callback = cb;
			return o;
		} else if (!a.callback) {
			o.callback = cb;
		} else {
			o.callback = function() {
				cb.call(scope);
				Ext.callback(a.callback, a.scope);
			};
		}
		return Ext.applyIf(o, a);
	},

	onDisable: function() {
		if (this.rendered && this.maskDisabled) {
			this.el.mask();
		}
		Ext.Panel.superclass.onDisable.call(this);
	},

	onEnable: function() {
		if (this.rendered && this.maskDisabled) {
			this.el.unmask();
		}
		Ext.Panel.superclass.onEnable.call(this);
	},

	onResize: function(w, h) {
		if (w !== undefined || h !== undefined) {
			var mc = this.bwrap.dom.firstChild;
			if (typeof w == 'number') {
				this.body.setWidth(
					this.adjustBodyWidth(w - Ext.fly(mc).getFrameWidth('lr')));
			} else if (w == 'auto') {
				this.body.setWidth(w);
			}
			if (typeof h == 'number') {
				this.body.setHeight(
					this.adjustBodyHeight(h - this.getFrameHeight()));
			} else if (h == 'auto') {
				this.body.setHeight(h);
			}
			if (this.disabled && this.el._mask) {
				this.el._mask.setSize(this.el.dom.clientWidth, this.el.getHeight());
			}
			if (this.collapsed && this.isXType('panel', false)) {
				this.queuedBodySize = { width: w, height: h };
				if (!this.queuedExpand && this.allowQueuedExpand !== false) {
					this.queuedExpand = true;
					this.on('expand', function() {
						delete this.queuedExpand;
						this.onResize(this.queuedBodySize.width, this.queuedBodySize.height);
						this.doLayout();
					}, this, { single: true });
				}
			}
			this.fireEvent('bodyresize', this, w, h);
		}
		this.syncShadow();
	},

	adjustBodyHeight: function(h) {
		return h;
	},

	adjustBodyWidth: function(w) {
		return w;
	},

	onPosition: function() {
		this.syncShadow();
	},

	getFrameWidth: function() {
		var w = this.el.getFrameWidth('lr');

		if (this.frame) {
			var l = this.bwrap.dom.firstChild;
			w += (Ext.fly(l).getFrameWidth('l') + Ext.fly(l.firstChild).getFrameWidth('r'));
			var mc = this.bwrap.dom.firstChild;
			w += Ext.fly(mc).getFrameWidth('lr');
		}
		return w;
	},

	getFrameHeight: function() {
		var h = this.el.getFrameWidth('tb');
		h += (this.tbar ? this.tbar.getHeight() : 0) +
         (this.bbar ? this.bbar.getHeight() : 0);

		if (this.frame) {
			var hd = this.el.dom.firstChild;
			var ft = this.bwrap.dom.lastChild;
			h += (hd.offsetHeight + ft.offsetHeight);
			var mc = this.bwrap.dom.firstChild;
			h += Ext.fly(mc).getFrameWidth('tb');
		} else {
			h += (this.header ? this.header.getHeight() : 0) +
            (this.footer ? this.footer.getHeight() : 0);
		}
		return h;
	},

	getInnerWidth: function() {
		return this.getSize().width - this.getFrameWidth();
	},

	getInnerHeight: function() {
		return this.getSize().height - this.getFrameHeight();
	},

	syncShadow: function() {
		if (this.floating) {
			this.el.sync(true);
		}
	},

	getLayoutTarget: function() {
		return this.body;
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (this.header && this.headerAsText) {
			this.header.child('span').update(caption);
		}
		this.fireEvent('captionchange', this, caption);
		return this;
	},

	getUpdater: function() {
		return this.body.getUpdater();
	},

	load: function() {
		var um = this.body.getUpdater();
		um.update.apply(um, arguments);
		return this;
	},

	beforeDestroy: function() {
		Ext.Element.uncache(
        this.header,
        this.tbar,
        this.bbar,
        this.footer,
        this.body
    );
		if (this.tools) {
			for (var k in this.tools) {
				Ext.destroy(this.tools[k]);
			}
		}
		if (this.buttons) {
			for (var b in this.buttons) {
				Ext.destroy(this.buttons[b]);
			}
		}
		Ext.destroy(
        this.topToolbar,
        this.bottomToolbar
    );
		Ext.Panel.superclass.beforeDestroy.call(this);
	},

	createClasses: function() {
		this.headerCls = this.appearCls + '-header';
		this.headerTextCls = this.appearCls + '-header-text';
		this.bwrapCls = this.baseCls + '-bwrap';
		this.tbarCls = this.baseCls + '-tbar';
		this.bodyCls = this.baseCls + '-body';
		this.bbarCls = this.baseCls + '-bbar';
		this.footerCls = this.baseCls + '-footer';
	},

	createGhost: function(cls, useShim, appendTo) {
		var el = document.createElement('div');
		el.className = 'x-panel-ghost ' + (cls ? cls : '');
		if (this.header) {
			el.appendChild(this.el.dom.firstChild.cloneNode(true));
		}
		Ext.fly(el.appendChild(document.createElement('ul'))).setHeight(this.bwrap.getHeight());
		el.style.width = this.el.dom.offsetWidth + 'px'; ;
		if (!appendTo) {
			this.container.dom.appendChild(el);
		} else {
			Ext.getDom(appendTo).appendChild(el);
		}
		if (useShim !== false && this.el.useShim !== false) {
			var layer = new Ext.Layer({ shadow: false, useDisplay: true, constrain: false }, el);
			layer.show();
			return layer;
		} else {
			return new Ext.Element(el);
		}
	},

	doAutoLoad: function() {
		this.body.load(
        typeof this.autoLoad == 'object' ?
            this.autoLoad : { url: this.autoLoad });
	}
});

Ext.Panel.DD = function(panel, cfg) {
	this.panel = panel;
	this.dragData = { panel: panel };
	this.proxy = new Ext.dd.PanelProxy(panel, cfg);
	Ext.Panel.DD.superclass.constructor.call(this, panel.el, cfg);
	var h = panel.header;
	if (h) {
		this.setHandleElId(h.id);
	}
	this.scroll = false;
};

Ext.extend(Ext.Panel.DD, Ext.dd.DragSource, {
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
	createFrame: Ext.emptyFn,
	getDragEl: function(e) {
		return this.proxy.ghost.dom;
	},
	endDrag: function(e) {
		this.proxy.hide();
		this.panel.saveState();
	},

	autoOffset: function(x, y) {
		x -= this.startPageX;
		y -= this.startPageY;
		this.setDelta(x, y);
	}
});

Ext.Panel.DropTarget = function(panel, cfg) {
	this.panel = panel;
	cfg = cfg || {};
	if (!cfg.groups) {
		cfg.groups = {};
		cfg.groups['DockingDD'] = true;
		cfg.groups['TabPanelTabs'] = true;
	}
	cfg.priority = 1;
	Ext.Panel.DropTarget.superclass.constructor.call(this, panel.el, cfg);
};

Ext.extend(Ext.Panel.DropTarget, Ext.dd.DropTarget, {

	notifyDrop: function(dd, e, data) {
		if (dd.ddGroup == 'TabPanelTabs') {
			var item = dd.tabPanel.getItemByStripTab(data.stripTab);
			if (item.allowDraggingOutside !== true) {
				return false;
			}
			if (item.menu && item.useMenuItemCaptionAsSubCaption) {
				item.menu.un("itemclick", dd.tabPanel.onMenuItemClick, dd.tabPanel);
			}
			dd.tabPanel.strip.dom.removeChild(data.stripTab);
			dd.tabPanel.remove(item, false);
			var tabPanelConfig = {};
			tabPanelConfig.allowDraggingTabs = dd.tabPanel.allowDraggingTabs || false;
			tabPanelConfig.collapsible = dd.tabPanel.collapsible || false;
			tabPanelConfig.draggable = true;
			tabPanelConfig.closable = true;
			tabPanelConfig.dockSite = dd.tabPanel.dockSite || false;
			var tabPanel = new Terrasoft.TabPanel(tabPanelConfig);
			tabPanel.addTab(item, 0, true);
			this.panel.add(tabPanel);
			this.panel.doLayout();
			if (dd.tabPanel.items.length == 0) {
				if (dd.tabPanel.ownerCt) {
					dd.tabPanel.ownerCt.remove(dd.tabPanel, true);
				}
			}
			return true;
		}
		if (this.panel.validDockSiteSourceIds &&
				Ext.isArray(this.panel.validDockSiteSourceIds) && data.panel) {
			var isValidDockSiteSource =
				(this.panel.validDockSiteSourceIds.indexOf(data.panel.id) != -1);
			if (!isValidDockSiteSource) {
				return false;
			}
		}
		if (data.panel.ownerCt) {
			if (data.panel.ownerCt.id == this.panel.id) {
				return true;
			}
			data.panel.ownerCt.remove(data.panel, false);
		}
		this.panel.add(data.panel);
		this.panel.doLayout();
		return true;
	}

});

Terrasoft.Panel = Ext.extend(Ext.Panel, {
	captionCollapse: true,

	createPanelButton: function(bc) {
		return new Terrasoft.Button(bc);
	},

	maximize: function() {
		if (!this.container.collapsed) {
			var vs = Ext.getBody().getViewSize();
			this.setSize(vs.width, vs.height);
		}
	}
});

Ext.reg('panel', Terrasoft.Panel);