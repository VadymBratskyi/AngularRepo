Terrasoft.Window = Ext.extend(Terrasoft.Panel, {
	baseCls: 'ts-window', // baseCls: 'ts-window',
	resizable: true,
	draggable: true,
	closable: true,
	constrain: false,
	constrainHeader: false,
	plain: false,
	minimizable: false,
	maximizable: false,
	minHeight: 100,
	minWidth: 200,
	expandOnShow: true,
	closeAction: 'close',
	elements: 'header,body',
	collapsible: false,
	initHidden: true,
	monitorResize: true,
	frame: true,
	floating: true,
	captionCollapse: false,
	collapsedCls: 'ts-window-collapsed',

	initComponent: function() {
		Terrasoft.Window.superclass.initComponent.call(this);
		this.addEvents(
			'resize',
			'maximize',
			'minimize',
			'restore'
		);
	},

	getState: function() {
		return Ext.apply(Terrasoft.Window.superclass.getState.call(this) || {}, this.getBox());
	},

	onRender: function(ct, position) {
		Terrasoft.Window.superclass.onRender.call(this, ct, position);
		if (this.plain) {
			this.el.addClass('x-window-plain');
		}
		this.focusEl = this.el.createChild({
			tag: "a",
			href: "#",
			cls: "x-dlg-focus",
			tabIndex: "-1",
			html: "&#160;"
		});
		if (this.header) {
			var imageCfg = {
				resourceManager: this.imageList,
				resourceId: this.captionImageId,
				resourceName: this.captionImageName
			};
			this.imageSrc = Ext.ImageUrlHelper.getImageUrl(imageCfg);
			this.headerCaptionEl.setStyle('margin-left', '0');
			if (!Ext.isEmpty(this.imageSrc)) {
				this.headerIcon = this.header.insertHtml("afterBegin", '<img class="window-header-icon" src="' + Ext.BLANK_IMAGE_URL + '"/>', true);
				this.headerIcon.setStyle('background-image', this.imageSrc);
			} else {
				this.setImageClass(this.imageCls);
			}
		}
		this.focusEl.swallowEvent('click', true);
		this.proxy = this.el.createProxy("x-window-proxy");
		this.proxy.enableDisplayMode('block');
		if (this.modal) {
			this.mask = this.container.createChild({
					cls: "ext-el-mask"
				},
				this.el.dom);
			this.mask.enableDisplayMode("block");
			this.mask.hide();
		}
	},

	setImageClass: function(cls) {
		var old = this.imageCls;
		this.imageCls = cls;
		if (this.rendered && this.header && !Ext.isEmpty(this.imageSrc)) {
			this.headerIcon.replaceClass(old, this.imageCls);
		}
	},

	initEvents: function() {
		Terrasoft.Window.superclass.initEvents.call(this);
		if (this.resizable) {
			this.resizer = new Ext.Resizable(this.el, {
				minWidth: this.minWidth,
				minHeight: this.minHeight,
				handles: this.resizeHandles || "all",
				pinned: true,
				resizeElement: this.resizerAction
			});
			this.resizer.window = this;
			this.resizer.on("beforeresize", this.beforeResize, this);
		}

		if (this.draggable) {
			this.header.addClass("x-window-draggable");
		}
		this.initTools();

		this.el.on("mousedown", this.toFront, this);
		this.manager = this.manager || Ext.WindowMgr;
		this.manager.register(this);
		this.hidden = true;
		if (this.maximized) {
			this.maximized = false;
			this.maximize();
		}
		if (this.closable) {
			var km = this.getKeyMap();
			km.on(27, this.onEsc, this);
			km.on(13, this.onEnter, this);
			km.disable();
		}
	},

	setSize: function(w, h) {
		var parts;
		if (typeof w == 'string') {
			parts = Ext.Element.parseUnits(w);
			if (parts != null) {
				if (parts.measure == '%') {
					var width = this.getViewSizeCalculatedPercent(w).width;
					if (width != null) {
						w = width;
					}
					if (this.el.shadow) {
						w = w - this.el.shadow.offset || 0;
					}
				} else {
					w = parseInt(parts.value);
				}
			}
		}
		if (typeof h == 'string') {
			parts = Ext.Element.parseUnits(h);
			if (parts != null) {
				if (parts.measure == '%') {
					var height = this.getViewSizeCalculatedPercent(h).height;
					if (height != null) {
						h = height;
					}
					if (this.el.shadow) {
						h = h - this.el.shadow.offset || 0;
					}
				} else {
					h = parseInt(parts.value);
				}
			}
		}
		return Terrasoft.Window.superclass.setSize.call(this, w, h);
	},

	getPositionOffsets: function() {
		if (this.el.shadow) {
			var offset = this.el.shadow.offset;
			if (offset != undefined) {
				offset = Math.floor((offset / 2) * -1);
				return [offset, offset];
			}
		}
		return undefined;
	},

	getPercentValue: function(size) {
		var percentSignIndex = size.indexOf('%');
		var percent = NaN;
		if (percentSignIndex != -1) {
			var percentStringValue = size.substring(0, percentSignIndex);
			percent = parseFloat(percentStringValue);
		}
		return isNaN(percent) ? null : percent;
	},

	getViewSizeCalculatedPercent: function(percent) {
		var result = {};
		var percentValue = this.getPercentValue(percent);
		if (percentValue != null) {
			var viewSize = Ext.getBody().getViewSize();
			result.width = Math.floor(viewSize.width * percentValue / 100);
			result.height = Math.floor(viewSize.height * percentValue / 100);
		}
		return result;
	},

	setCaption: function(caption, imageCls) {
		Terrasoft.Window.superclass.setCaption.call(this, caption);
		if (imageCls) {
			this.setImageClass(imageCls);
		}
		return this;
	},

	initDraggable: function() {
		this.dd = new Terrasoft.Window.DD(this);
	},

	onEsc: function(keyCode, e) {
		var cancelButton = this.getCancelButton();
		if (cancelButton) {
			e.button = 0;
			cancelButton.onClick(e);
		}
	},

	onEnter: function(keyCode, e) {
		var defaultButton = this.getDefaultButton();
		if (defaultButton) {
			e.button = 0;
			defaultButton.onClick(e);
		}
	},

	findButtonByPropertyValue: function(parentControl, propertyName, propertyValue) {
		var button = null;
		if (parentControl && parentControl.items && (parentControl.isContainer !== false)) {
			for (var i = 0; i < parentControl.items.length; i++) {
				var item = parentControl.items.items[i];
				if ((item instanceof Terrasoft.Button) && (item[propertyName] === propertyValue)) {
					button = item;
				} else {
					button = this.findButtonByPropertyValue(item, propertyName, propertyValue);
				}
				if (button) {
					break;
				}
			}
		}
		return button;
	},

	getCancelButton: function() {
		return this.findButtonByPropertyValue(this, "cancelButton", true);
	},

	getDefaultButton: function() {
		return this.findButtonByPropertyValue(this, "defaultButton", true);
	},

	beforeDestroy: function() {
		Ext.destroy(
			this.resizer,
			this.dd,
			this.proxy,
			this.mask
		);
		Terrasoft.Window.superclass.beforeDestroy.call(this);
	},

	onDestroy: function() {
		if (this.manager) {
			this.manager.unregister(this);
		}
		Terrasoft.Window.superclass.onDestroy.call(this);
	},

	initTools: function() {
		if (this.minimizable) {
			this.addTool({
				id: 'minimize',
				handler: this.minimize.createDelegate(this, [])
			});
		}
		if (this.maximizable) {
			this.addTool({
				id: 'maximize',
				handler: this.maximize.createDelegate(this, [])
			});
			this.tools.maximize.visibilityMode = Ext.Element.DISPLAY;
			this.addTool({
				id: 'restore',
				visibilityMode: Ext.Element.DISPLAY,
				handler: this.restore.createDelegate(this, [])
			});
			this.tools.restore.visibilityMode = Ext.Element.DISPLAY;
			this.tools.restore.hide();
			this.header.on('dblclick', this.toggleMaximize, this);
		}
		if (this.closable) {
			this.addTool({
				id: 'close',
				handler: this['close'].createDelegate(this, [])
			});
		}
	},

	resizerAction: function() {
		var box = this.proxy.getBox();
		this.proxy.hide();
		this.window.handleResize(box);
		return box;
	},

	beforeResize: function() {
		this.resizer.minHeight = Math.max(this.minHeight, this.getFrameHeight() + 40); 
		this.resizer.minWidth = Math.max(this.minWidth, this.getFrameWidth() + 40);
		this.resizeBox = this.el.getBox();
	},

	updateHandles: function() {
		if (Ext.isIE && this.resizer) {
			this.resizer.syncHandleHeight();
			this.el.repaint();
		}
	},

	handleResize: function(box) {
		var rz = this.resizeBox;
		if (rz.x != box.x || rz.y != box.y) {
			this.updateBox(box);
		} else {
			this.setSize(box);
		}
		this.focus();
		this.updateHandles();
		this.saveState();
		if (this.layout) {
			this.doLayout();
		}
		this.fireEvent("resize", this, box.width, box.height);
	},

	focus: function() {
		var f = this.focusEl, db = this.defaultButton, t = typeof db;
		if (t != 'undefined') {
			if (t == 'number') {
				f = this.buttons[db];
			} else if (t == 'string') {
				f = Ext.getCmp(db);
			} else {
				f = db;
			}
		}
		f.focus.defer(10, f);
	},

	beforeShow: function() {
		delete this.el.lastXY;
		delete this.el.lastLT;
		if (this.x === undefined || this.y === undefined) {
			var xy = this.el.getAlignToXY(this.container, 'c-c');
			var pos = this.el.translatePoints(xy[0], xy[1]);
			this.x = this.x === undefined ? pos.left : this.x;
			this.y = this.y === undefined ? pos.top : this.y;
		}
		this.y = (this.y < 0) ? 0 : this.y;
		var viewSize = this.getViewSizeCalculatedPercent('100%');
		var size = this.getSize();
		var needResize = false;
		if (size.width > viewSize.width) {
			this.x = 0;
			needResize = true;
			size.width = viewSize.width;
			size.height = (size.height > viewSize.height) ? viewSize.height : size.height;
		} else if (size.height > viewSize.height) {
			this.y = 0;
			needResize = true;
			size.height = viewSize.height;
		}
		if (needResize) {
			this.setSize(size.width, size.height);
			this.setPagePosition(this.x, this.y);
		} else {
			this.el.setLeftTop(this.x, this.y);
		}
		if (this.expandOnShow) {
			this.expand(false);
		}
		if (this.modal) {
			Ext.getBody().addClass("x-body-masked");
			this.mask.setSize(Ext.lib.Dom.getViewWidth(true), Ext.lib.Dom.getViewHeight(true));
			this.mask.show();
		}
	},

	show: function(cb, scope) {
		if (!this.rendered) {
			this.render(Ext.getBody());
		}
		if (this.hidden === false) {
			this.toFront();
			return;
		}
		if (this.fireEvent("beforeshow", this) === false) {
			return;
		}
		if (cb) {
			this.on('show', cb, scope, { single: true });
		}
		this.hidden = false;
		this.beforeShow();
		this.afterShow();
		this.syncShadow();
	},

	afterShow: function() {
		this.proxy.hide();
		this.el.setStyle('display', 'block');
		this.el.show();
		if (this.maximized) {
			this.fitContainer();
		}
		if (Ext.isMac && Ext.isGecko) {
			this.cascade(this.setAutoScroll);
		}
		if (this.monitorResize || this.modal || this.constrain || this.constrainHeader) {
			Ext.EventManager.onWindowResize(this.onWindowResize, this);
		}
		this.doConstrain();
		if (this.layout) {
			this.doLayout();
		}
		if (this.keyMap) {
			this.keyMap.enable();
		}
		this.toFront();
		this.updateHandles();
		this.fireEvent("show", this);
		if (this.buttons && this.buttons.length > 0) {
			var bcWidth = 0;
			var bCount = 0;
			for (var i = 0, len = this.buttons.length; i < len; i++) {
				var b = this.buttons[i];
				if (b.container.isVisible()) {
					bcWidth += b.width == 0 ? b.minWidth : b.width;
					bCount++;
				}
			}
			bcWidth = bcWidth + bCount * 3 + "px";
			Ext.get(this.footer.dom.firstChild).setStyle("width", bcWidth);
		}
	},

	hide: function(cb, scope) {
		if (this.activeGhost) {
			this.hide.defer(100, this, [cb, scope]);
			return;
		}
		if (this.hidden || this.fireEvent("beforehide", this) === false) {
			return;
		}
		if (cb) {
			this.on('hide', cb, scope, { single: true });
		}
		this.hidden = true;
		this.el.hide();
		this.afterHide();
	},

	afterHide: function() {
		this.proxy.hide();
		if (this.monitorResize || this.modal || this.constrain || this.constrainHeader) {
			Ext.EventManager.removeResizeListener(this.onWindowResize, this);
		}
		if (this.modal) {
			this.mask.hide();
			Ext.getBody().removeClass("x-body-masked");
		}
		if (this.keyMap) {
			this.keyMap.disable();
		}
		this.fireEvent("hide", this);
	},

	adjustBodyWidth: function(w) {
		w = w - this.el.getFrameWidth('lr');
		return w;
	},

	onWindowResize: function() {
		if (this.maximized) {
			this.fitContainer();
		}
		if (this.modal) {
			this.mask.setSize('100%', '100%');
			this.mask.setSize(Ext.lib.Dom.getViewWidth(true), Ext.lib.Dom.getViewHeight(true));
		}
		this.doConstrain();
	},

	doConstrain: function() {
		if (this.constrain || this.constrainHeader) {
			var offsets;
			if (this.constrain) {
				offsets = {
					right: this.el.shadowOffset,
					left: this.el.shadowOffset,
					bottom: this.el.shadowOffset
				};
			} else {
				var s = this.getSize();
				offsets = {
					right: -(s.width - 100),
					bottom: -(s.height - 25)
				};
			}

			var xy = this.el.getConstrainToXY(this.container, true, offsets);
			if (xy) {
				this.setPosition(xy[0], xy[1]);
			}
		}
	},

	ghost: function(cls) {
		var ghost = this.createGhost(cls);
		var box = this.getBox(true);
		ghost.setLeftTop(box.x, box.y);
		ghost.setWidth(box.width);
		this.el.hide();
		this.activeGhost = ghost;
		return ghost;
	},

	unghost: function(show, matchPosition) {
		if (show !== false) {
			this.el.show();
			this.focus();
			if (Ext.isMac && Ext.isGecko) {
				this.cascade(this.setAutoScroll);
			}
		}
		if (matchPosition !== false) {
			this.setPosition(this.activeGhost.getLeft(true), this.activeGhost.getTop(true));
		}
		this.activeGhost.hide();
		this.activeGhost.remove();
		delete this.activeGhost;
	},

	minimize: function() {
		this.fireEvent('minimize', this);
	},

	close: function(closeResult) {
		if (this.fireEvent("beforeclose", this) !== false) {
			this.hide(function() {
				this.fireEvent('close', this, closeResult || "None");
				if (this.closeAction == 'close') {
					this.destroy();
				}
			}, this);
		}
	},

	maximize: function() {
		if (!this.maximized) {
			this.expand(false);
			this.restoreSize = this.getSize();
			this.restorePos = this.getPosition(true);
			if (this.maximizable) {
				this.tools.maximize.hide();
				this.tools.restore.show();
			}
			this.maximized = true;
			this.el.disableShadow();

			if (this.dd) {
				this.dd.lock();
			}
			if (this.collapsible) {
				this.tools.toggle.hide();
			}
			this.el.addClass('x-window-maximized');
			this.container.addClass('x-window-maximized-ct');

			this.setPosition(0, 0);
			this.fitContainer();
			this.fireEvent('maximize', this);
		}
	},

	restore: function() {
		if (this.maximized) {
			this.el.removeClass('x-window-maximized');
			this.tools.restore.hide();
			this.tools.maximize.show();
			this.setPosition(this.restorePos[0], this.restorePos[1]);
			this.setSize(this.restoreSize.width, this.restoreSize.height);
			delete this.restorePos;
			delete this.restoreSize;
			this.maximized = false;
			this.el.enableShadow(true);

			if (this.dd) {
				this.dd.unlock();
			}
			if (this.collapsible) {
				this.tools.toggle.show();
			}
			this.container.removeClass('x-window-maximized-ct');

			this.doConstrain();
			this.fireEvent('restore', this);
		}
	},

	toggleMaximize: function() {
		this[this.maximized ? 'restore' : 'maximize']();
	},

	fitContainer: function() {
		var vs = this.container.getViewSize();
		this.setSize(vs.width, vs.height);
	},

	setZIndex: function(index) {
		if (this.modal) {
			this.mask.setStyle("z-index", index);
		}
		this.el.setZIndex(++index);
		index += 5;

		if (this.resizer) {
			this.resizer.proxy.setStyle("z-index", ++index);
		}

		this.lastZIndex = index;
	},

	alignTo: function(element, position, offsets) {
		var xy = this.el.getAlignToXY(element, position, offsets);
		this.setPagePosition(xy[0], xy[1]);
		return this;
	},

	anchorTo: function(el, alignment, offsets, monitorScroll, _pname) {
		var action = function() {
			this.alignTo(el, alignment, offsets);
		};
		Ext.EventManager.onWindowResize(action, this);
		var tm = typeof monitorScroll;
		if (tm != 'undefined') {
			Ext.EventManager.on(window, 'scroll', action, this,
                { buffer: tm == 'number' ? monitorScroll : 50 });
		}
		action.call(this);
		this[_pname] = action;
		return this;
	},

	toFront: function() {
		if (this.manager.bringToFront(this)) {
			this.focus();
		}
		return this;
	},

	setActive: function(active) {
		if (active) {
			if (!this.maximized) {
				this.el.enableShadow(true);
			}
			this.fireEvent('activate', this);
		} else {
			this.el.disableShadow();
			this.fireEvent('deactivate', this);
		}
	},

	toBack: function() {
		this.manager.sendToBack(this);
		return this;
	},

	center: function() {
		var xy = this.el.getAlignToXY(this.container, 'c-c');
		this.setPagePosition(xy[0], xy[1]);
		return this;
	}
});

Ext.reg('window', Terrasoft.Window);

Terrasoft.Window.DD = function(win) {
	this.win = win;
	Terrasoft.Window.DD.superclass.constructor.call(this, win.el.id, 'WindowDD-' + win.id);
	this.setHandleElId(win.header.id);
	this.scroll = false;
};

Ext.extend(Terrasoft.Window.DD, Ext.dd.DD, {
	moveOnly: true,
	headerOffsets: [100, 25],
	startDrag: function() {
		var w = this.win;
		this.proxy = w.ghost();
		if (w.constrain !== false) {
			var so = w.el.shadowOffset;
			this.constrainTo(w.container, { right: so, left: so, bottom: so });
		} else if (w.constrainHeader !== false) {
			var s = this.proxy.getSize();
			this.constrainTo(w.container, { right: -(s.width - this.headerOffsets[0]), bottom: -(s.height - this.headerOffsets[1]) });
		}
	},

	b4Drag: Ext.emptyFn,

	onDrag: function(e) {
		this.alignElWithMouse(this.proxy, e.getPageX(), e.getPageY());
	},

	endDrag: function(e) {
		this.win.unghost();
		this.win.saveState();
	}
});