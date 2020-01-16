Terrasoft.ControlLayout = Ext.extend(Ext.Container, {
	direction: 'vertical',
	captionVerticalAlign: undefined,
	alignSupports: {
		vertical: {top: true, middle:true, bottom: true},
		horizontal: {left: true, center:true, right: true}
	},
	displayStyle: 'none',
	defaultMargins: '0 0 0 0',
	hasHeader: false,
	captionPosition: 'none',
	isViewPort: false,
	dontShowLoadMask: false,
	autoScroll: false,
	dragDropMode: 'none',
	collapsedCls: 'x-control-layout-collapsed',
	width: 400,
	height: 50,
	fitHeightByContent: false,
	footerClass: 'x-control-layout-footer',
	topbarClass: 'x-control-layout-topbar',
	sidebarClass: 'x-control-layout-sidebar',
	cls: '',

	initComponent: function() {
		this.layout = 'box';
		this.layoutConfig = this.layoutConfig || {};
		var layoutConfig = {};
		layoutConfig.direction = this.direction;
		layoutConfig.align = (this.direction == 'vertical') ? 'left' : 'top';
		if (this.caption && this.hasHeader != undefined) {
			this.hasHeader = true;
		}
		if (this.isCollapsible === true && this.hasHeader != undefined) {
			this.hasHeader = true;
		}
		if (!this.isAlignSupports(this.layoutConfig.align)) {
			delete this.layoutConfig.align;
		}
		Ext.applyIf(this.layoutConfig, layoutConfig);
		this.setDisplayStyle(this.displayStyle);
		this.on('add', this.onItemAdd, this);
		Terrasoft.ControlLayout.superclass.initComponent.call(this);
		this.addEvents(
			'collapse',
			'expand',
			'beforecollapse',
			'beforeexpand',
			'controlselect',
			'itemsdrop',
			'beforecontrolmove',
			'controlmove',
			'directionchange'
		);
		if (this.isViewPort) {
			this.isCollapsible = false;
			this.monitorResize = true;
			document.getElementsByTagName('html')[0].className += ' x-viewport';
			this.formEl = Ext.get(document.getElementsByTagName('form')[0]);
			this.el = Ext.getBody();
			this.el.setHeight = Ext.emptyFn;
			this.el.setWidth = Ext.emptyFn;
			this.el.setSize = Ext.emptyFn;
			this.el.dom.scroll = 'no';
			this.allowDomMove = false;
			this.autoWidth = true;
			this.autoHeight = true;
			this.renderTo = this.formEl;
		}
		this.on('remove', this.onItemRemove, this);
		if (!this.items) {
			return;
		}
	},

	applyDesignConfig: function(designConfig) {
		Terrasoft.ControlLayout.superclass.applyDesignConfig.apply(this, arguments);
		Ext.apply(this, designConfig);
		if (this.listenersConfig) {
			this.on(this.listenersConfig);
		}
	},

	onRender: function(ct, position) {
		Terrasoft.ControlLayout.superclass.onRender.call(this, ct, position);
		if (!this.isViewPort) {
			this.el = ct.createChild({
				id: this.id
			}, position);
		}
		this.el.addClass('x-control-layout');
		if (this.displayStyle == 'footer') {
			this.el.addClass(this.footerClass);
		} else if (this.displayStyle == 'topbar') {
			var height = 34;
			if (!this.edges || this.edges == '') {
				this.el.setStyle('border','1px solid #D2D7DC');
			} else {
				var edges = this.edges.split(" ");
				var style = this.el.dom.style;
				style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
				style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
				style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
				style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
				if (edges[0] == 0) {
					height--;
				}
				if (edges[2] == 0) {
					height--;
				}
				if (edges[0] == 1 && edges[2] == 1) {
					height += 2;
				}
				if (edges[0] == 0 && edges[2] == 0) {
					height -= 2;
				}
			}
			this.el.addClass(this.topbarClass);
			this.el.setStyle('padding','1px');
			this.height = height;
			this.layoutConfig.direction = 'horizontal';
			this.layoutConfig.padding = "0 4 0 4";
			this.layoutConfig.align = 'middle';
		} else if (this.displayStyle == 'sidebar') {
			this.el.addClass(this.sidebarClass);
			this.el.setStyle('padding','1px');
			this.width = 34;
			this.layoutConfig.direction = 'vertical';
			this.layoutConfig.padding = "4 0 4 0";
			this.layoutConfig.align = 'center';
		}
		if (this.hasHeader) {
			var header = this.header = this.el.createChild({
				cls: "x-control-layout-header x-unselectable"
			});
			if (Ext.isIE9) {
				this.getHeaderHeight = this.getHeaderHeightIE9;
			}
			if (this.isCollapsible) {
				this.headerTool = header.createChild({
					tag: 'img',
					src: Ext.BLANK_IMAGE_URL,
					cls: 'x-tool x-tool-toggle'
				});
				this.headerTool.on('click', this.toggleCollapse, this);
			}
			if (this.caption) {
				this.setCaption(this.caption);
			}
		}
		if (!Ext.isEmpty(this.cls)) {
			this.el.addClass(this.cls);
		}
		this.setImage();
	},

	getHeaderHeight: function(contentHeight) {
		return this.header ? this.header.getHeight(contentHeight) : 0;
	},

	getHeaderHeightIE9: function(contentHeight) {
		if (!this.header) {
			return 0;
		}
		var height = this.header.dom.offsetHeight;
		var h = height ? height + 1 : 0;
		h = contentHeight !== true ? h : h - this.header.getBorderWidth("tb") - this.header.getPadding("tb");
		return h < 0 ? 0 : h;
	},

	afterRender: function(ct) {
		Terrasoft.ControlLayout.superclass.afterRender.call(this);
	},

	setEdges: function(edgesValue) {
		if (!this.designMode) {
			Terrasoft.ControlLayout.superclass.setEdges.call(this, edgesValue);
			return;
		}
		if (Ext.isEmpty(edgesValue)) {
			return;
		}
		var edges = edgesValue.split(" ");
		var resizeEl = this.getResizeEl();
		if (edges[0] == 1) {
			resizeEl.addClass("x-container-border-top");
		} else {
			resizeEl.removeClass("x-container-border-top");
		}
		if (edges[1] == 1) {
			resizeEl.addClass("x-container-border-right");
		} else {
			resizeEl.removeClass("x-container-border-right");
		}
		if (edges[2] == 1) {
			resizeEl.addClass("x-container-border-bottom");
		} else {
			resizeEl.removeClass("x-container-border-bottom");
		}
		if (edges[3] == 1) {
			resizeEl.addClass("x-container-border-left");
		} else {
			resizeEl.removeClass("x-container-border-left");
		}
	},

	setImage: function (value) {
		if (value !== undefined) {
			this.imageConfig = value;
		}
		var imageSrc = this.getImageSrc();
		imageSrc = (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) ? imageSrc : 'none';
		this.imageSrc = imageSrc;
		var layout = this.layout;
		if (layout) {
			var innerCt = layout.innerCt;
			if (innerCt) {
				innerCt.setStyle('background-image', imageSrc);
			}
		}
	},

	adjustInnerCtHeight: function(h) {
		if (this.header) {
			h = h - this.getHeaderHeight() || 0;
		}
		return h;
	},

	getMinSize: function() {
		return (this.collapsed) ? (this.header) ? this.getHeaderHeight() : 0 : 0;
	},

	isAlignSupports: function(align) {
		var alignDirection = (this.direction == 'vertical') ? 'horizontal' : 'vertical';
		return this.alignSupports[alignDirection][align] === true;
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (!this.header) {
			return;
		}
		if (!this.captionEl) {
			this.captionEl = this.header.createChild({
				tag: 'span',
				cls: 'x-panel-header-text'
			});
			if (this.isCollapsible) {
				this.captionEl.on('click', this.toggleCollapse, this);
				this.captionEl.setStyle('cursor', 'pointer');
			}
		}
		this.captionEl.update(caption);
		return this;
	},

	getCollapsedStyleHeight: function() {
		return (this.header) ? this.getHeaderHeight() : 0;
	},

	beginContentUpdate: function() {
		var beginContentUpdateCallCounter = this.beginContentUpdateCallCounter;
		if (beginContentUpdateCallCounter == undefined) {
			beginContentUpdateCallCounter = 0;
		}
		this.beginContentUpdateCallCounter = ++beginContentUpdateCallCounter;
		this.contentUpdating = true;
		if (!this.isContainerWithItems()) {
			return;
		}
		var items = this.items.items;
		var itemsLength = items.length;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.isContainerWithItems() && item.beginContentUpdate) {
				item.beginContentUpdate();
			}
		}
	},

	endContentUpdate: function(lazyUpdate) {
		if (!this.isContainerWithItems()) {
			return;
		}
		var items = this.items.items;
		var itemsLength = items.length;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.isContainerWithItems() && item.endContentUpdate) {
				item.endContentUpdate(true);
			}
		}
		var beginContentUpdateCallCounter = this.beginContentUpdateCallCounter;
		if (beginContentUpdateCallCounter > 0) {
			beginContentUpdateCallCounter--;
		}
		this.beginContentUpdateCallCounter = beginContentUpdateCallCounter;
		if (beginContentUpdateCallCounter > 0) {
			return;
		}
		this.contentUpdating = false;
		if (lazyUpdate !== true) {
			if (this.needUpdateControlsCaptionWidth === true) {
				this.updateControlsCaptionWidth();
			} else if (this.needDeepDoLayout === true) {
				this.doLayout();
			} if (this.needOnContentChanged === true) {
				this.onContentChanged();
			} else if (this.needShallowDoLayout === true) {
				this.doLayout(false);
			}
		} else {
			var ownerCt = this.ownerCt;
			if (ownerCt) {
				ownerCt.needUpdateControlsCaptionWidth =
					ownerCt.needUpdateControlsCaptionWidth === true ? true : this.needUpdateControlsCaptionWidth;
				ownerCt.needDeepDoLayout = ownerCt.needDeepDoLayout === true ? true : this.needDeepDoLayout;
				ownerCt.needOnContentChanged = ownerCt.needOnContentChanged === true ? true : this.needOnContentChanged;
				ownerCt.needShallowDoLayout = ownerCt.needShallowDoLayout === true ? true : this.needShallowDoLayout;
			}
		}
		delete this.needUpdateControlsCaptionWidth;
		delete this.needDeepDoLayout;
		delete this.needOnContentChanged;
		delete this.needShallowDoLayout;
	},

	onItemAdd: function(container, item) {
		item.on('nameChanged', this.onItemNameChanged, this);
		item.on('show', this.onItemShow, this);
		item.on('rendercomplete', this.onItemRenderComplete, this);
	},

	onItemRemove: function(container, item) {
		if (this.rendered) {
			var splitBar = this.layout.splitBars[item.id];
			if (splitBar) {
				splitBar.el.dom.parentNode.removeChild(splitBar.el.dom);
				this.layout.splitBars[item.id] = null;
			}
		}
		item.un('rendercomplete', this.onItemRenderComplete, this);
		item.un('show', this.onItemShow, this);
		item.un('hide', this.onItemHide, this);
	},

	onItemRenderComplete: function(item) { 
		item.on('hide', this.onItemHide, this);
	},

	onItemNameChanged: function(el, oldName, name) {
		var items = this.items;
		items.remove(el);
		items.add(name, el);
	},

	onItemShow: function(component) {
		if (!this.rendered) {
			return;
		}
		var splitBar = this.layout.splitBars[component.id];
		if (splitBar) {
			splitBar.el.show();
		}
		component.needUpdateSize = true;
		if (component.supportsCaption === true || component.isContainerWithItems()) {
			this.updateControlsCaptionWidth();
		} else {
			this.doLayout(false);
		}
	},

	onItemHide: function(cmp) {
		var splitBar = this.layout.splitBars[cmp.id];
		if (splitBar) {
			splitBar.el.hide();
		}
		this.updateControlsCaptionWidth();
	},

	beginAjustItemsHeight: function() {
		this.itemsHeightAjusting = true;
	},

	endAjustItemsHeight: function() {
		this.itemsHeightAjusting = false;
		this.doLayout(false);
	},

	adjustItemsHeight: function(expandedItem) {
		this.doLayout(false);
		this.onContentChanged();
	},

	moveControl: function(control, position, force, targetControlId, movePosition) {
		if (typeof control == 'string') {
			control = Ext.getCmp(control);
		}
		if (!control || position < 0) {
			return false;
		}
		var isInsideMoving = (this == control.ownerCt);
		var maxPosition = (isInsideMoving) ? this.items.length - 1 : this.items.length;
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
		if (force !== true && this.fireEvent('beforecontrolmove', this.id, control.id, position, targetControlId, 
				movePosition) === false) {
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
		}
		this.fireEvent('controlmove', this.id, control.id, position, targetControlId, movePosition);
		return true;
	},

	setDirection: function(direction) {
		direction = direction.toLowerCase();
		if (this.direction == direction) {
			return;
		}
		this.direction = direction;
		var align = (this.rendered) ? this.layout.align : this.layoutConfig.align;
		if (!this.isAlignSupports(align)) {
			align = (direction == 'vertical') ? 'left' : 'top';
		}
		if (this.rendered) {
			this.layout.align = align;
			this.layout.direction = direction;
			this.fireEvent('directionchange', this.direction);
			this.onContentChanged();
		} else {
			this.layoutConfig.align = align;
			this.layoutConfig.direction = direction;
		}
	},

	setFitHeightByContent: function(fitHeightByContent) {
		if (typeof fitHeightByContent == 'string') {
			fitHeightByContent = Ext.decode(fitHeightByContent);
		}
		this.fitHeightByContent = fitHeightByContent;
		if (this.rendered) {
			var forceOwnerNotification = this.isSizeInPercent(this.height);
			this.onContentChanged(forceOwnerNotification);
		}
	},

	setAlign: function(align) {
		align = align.toLowerCase();
		if (this.rendered) {
			this.layout.align = align;
			this.onContentChanged();
		} else {
			this.layoutConfig.align = align;
		}
	},

	setPadding: function(padding) {
		var isEmptyValue = Ext.isEmpty(padding);
		if (this.rendered) {
			if (isEmptyValue) {
				this.layout.padding = this.layout.parseMargins('0');
			} else {
				this.layout.padding = this.layout.parseMargins(padding);
			}
			this.onContentChanged();
		} else if (!isEmptyValue) {
			this.layoutConfig.padding = padding;
		}
	},
	
	setDefaultMargins: function(defaultMargins, isStartLayout) {
		if (this.rendered) {
			var defaultMargins = this.layout.parseMargins(defaultMargins);
			this.layout.defaultMargins = defaultMargins;
			this.items.each(function(item) {
				if (!item.presetMargins) {
					item.margins = Ext.apply({}, defaultMargins);
				}
			});
			if (isStartLayout !== false) {
				this.onContentChanged();
			}
		} else {
			this.layoutConfig.defaultMargins = defaultMargins;
		}
	},

	setDisplayStyle: function(displayStyle) {
		var displayStyle = displayStyle.toLowerCase();
		this.displayStyle = displayStyle;
		var oldDirection = this.direction;
		if (!this.rendered) {
			var layoutConfig = {};
			if (displayStyle == 'controls') {
				layoutConfig.defaultMargins =
					(this.direction == 'vertical') ? '0 0 5 0' : '0 10 0 0';
				if (this.hasHeader) {
					layoutConfig.padding = '8 0 0 0';
				}
			} else if (displayStyle == 'footer') {
				this.direction = 'horizontal';
				this.layoutConfig.direction = 'horizontal';
				this.fitHeightByContent = true;
				layoutConfig.align = 'middle';
				layoutConfig.padding = '5';
				layoutConfig.defaultMargins = '0 3 0 0';
			} else if (displayStyle == 'topbar') {
				this.direction = 'horizontal';
				this.layoutConfig.direction = 'horizontal';
				this.fitHeightByContent = false;
				layoutConfig.align = 'middle';
				layoutConfig.defaultMargins = "0 3 0 0";
				layoutConfig.padding = "0 4 0 4";
			} else if (displayStyle == 'sidebar') {
				this.direction = 'vertical';
				this.layoutConfig.direction = 'vertical';
				this.fitHeightByContent = false;
				layoutConfig.align = 'center';
				layoutConfig.defaultMargins = '0 0 3 0';
				layoutConfig.padding = "4 0 4 0";
			}
			Ext.applyIf(this.layoutConfig, layoutConfig);
		} else {
			this.el[(displayStyle == 'footer') ? 'addClass' : 'removeClass'](this.footerClass);
			this.el[(displayStyle == 'topbar') ? 'addClass' : 'removeClass'](this.topbarClass);
			this.el[(displayStyle == 'sidebar') ? 'addClass' : 'removeClass'](this.sidebarClass);
			if (displayStyle == 'controls') {
				var layout = this.layout;
				var defaultMargins = (this.direction == 'vertical') ? '0 0 5 0' : '0 10 0 0';
				this.setDefaultMargins(defaultMargins, false);
				if (this.hasHeader) {
					layout.padding = '8 0 0 0';
				}
				if (this.restoredWidth) {
					this.setWidth(this.restoredWidth);
					delete this.restoredWidth;
				}
				if (this.restoredHeight) {
					this.setHeight(this.restoredHeight);
					delete this.restoredHeight;
				}
			} else if (displayStyle == 'footer') {
				var layout = this.layout;
				this.direction = 'horizontal';
				this.setSpacerDirection(oldDirection);
				layout.direction = 'horizontal';
				this.fitHeightByContent = true;
				layout.align = 'middle';
				layout.padding = this.layout.parseMargins('5');
				this.setDefaultMargins('0 3 0 0', false);
				if (this.restoredWidth) {
					this.setWidth(this.restoredWidth);
					delete this.restoredWidth;
				}
			} else if (displayStyle == 'topbar') {
				var layout = this.layout;
				this.direction = 'horizontal';
				this.setSpacerDirection(oldDirection);
				layout.direction = 'horizontal';
				this.fitHeightByContent = false;
				layout.align = 'middle';
				this.setDefaultMargins('0 3 0 0', false);
				this.el.setStyle('padding','1px');
				layout.padding = {top:0, right:4, bottom: 0, left: 4};
				this.restoredHeight = this.el.getHeight();
				this.el.setHeight(34);
				if (this.restoredWidth) {
					this.setWidth(this.restoredWidth);
					delete this.restoredWidth;
				}
			} else if (displayStyle == 'sidebar') {
				var layout = this.layout;
				this.direction = 'vertical';
				this.setSpacerDirection(oldDirection);
				layout.direction = 'vertical';
				this.fitHeightByContent = false;
				layout.align = 'center';
				this.setDefaultMargins('0 0 3 0', false);
				this.el.setStyle('padding','1px');
				layout.padding = {top:4, right:0, bottom: 4, left: 0};
				this.restoredWidth = this.el.getWidth();
				this.el.setWidth(34);
				if (this.container) {
					this.restoredHeight = this.el.getHeight();
					this.setHeight(this.container.getHeight());
				}
				Ext.each(this.items.items, function(item, i) {
					if (item.getWidth() > 25) {
						item.restoredWidth = item.getWidth();
						item.setWidth(25);
					}
				}, this);
			} else {
				var layout = this.layout;
				var defaultMargins = '0 0 0 0';
				this.setDefaultMargins(defaultMargins, false);
				layout.padding = {top:0, right:0, bottom: 0, left: 0};
				if (this.restoredWidth) {
					this.setWidth(this.restoredWidth);
					delete this.restoredWidth;
				}
				if (this.restoredHeight) {
					this.setHeight(this.restoredHeight);
					delete this.restoredHeight;
				}
			}
			Ext.each(this.items.items, function(item, i) {
				if (displayStyle != 'sidebar') {
					if (item.restoredWidth) {
						if (item.xtype != 'spacer') {
							item.setWidth(item.restoredWidth);
						}
						delete item.restoredWidth;
					}
				}
			}, this);
			this.onContentChanged();
		}
	},

	setSpacerDirection: function(oldDirection) {
		if (!this.rendered) {
			return;
		}
		Ext.each(this.items.items, function(item, i) {
			if (item.xtype == 'spacer' && oldDirection != this.direction) {
				item.switchDirection(this.direction);
			}
		}, this);
	}
});

Ext.reg('controllayout', Terrasoft.ControlLayout);

Terrasoft.ControlLayout.ControlProxy = function(control, cfg) {
	this.control = control;
	this.id = this.control.id + '-ddproxy';
	Ext.apply(this, cfg);
};

Terrasoft.ControlLayout.ControlProxy.prototype = {
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
			this.ghost.remove();
			delete this.ghost;
		}
		this.isVisible = false;
	},

	show: function() {
		if (!this.ghost) {
			var controlDomCopy = this.control.getResizeEl().dom.cloneNode(true);
			var flyControlDomCopy = Ext.fly(controlDomCopy);
			flyControlDomCopy.setLeftTop(0,0);
			flyControlDomCopy.dom.id = Ext.id();
			flyControlDomCopy.addClass('x-layout-control-proxy');
			var nodes = Ext.DomQuery.select('[id]', flyControlDomCopy);
			var node;
			for (var i = 0; i < nodes.length; i++) {
				node = nodes[i];
				node.id = Ext.id();
			}
			this.el = new Ext.Layer({ shadow: false, useDisplay: true, constrain: false });
			this.el.appendChild(flyControlDomCopy);
			this.ghost = this.el;
			this.el.show();
		}
		this.isVisible = true;
	}
	
};

Terrasoft.ControlLayout.DropTarget = function(controlLayout, cfg) {
	this.controlLayout = controlLayout;
	cfg = cfg || {};
	if (!cfg.groups) {
		cfg.groups = {};
		cfg.groups['DesignerDD'] = true;
		cfg.groups['ControlLayoutDD'] = true;
	}
	if (this.controlLayout.layout.contentTarget) {
		this.controlLayout.layout.contentTarget.ddScrollConfig = {
			contentWrap: this.controlLayout.layout.contentWrap,
			frequency: 300,
			vthresh: 50,
			hthresh: 50,
			animate: false,
			increment: 50
		}
		Ext.dd.ScrollManager.register(this.controlLayout.layout.contentTarget);
	}
	var DropTargetEl = this.controlLayout.innerCt || this.controlLayout.el;
	Terrasoft.ControlLayout.DropTarget.superclass.constructor.call(this, DropTargetEl, cfg);
};

Ext.extend(Terrasoft.ControlLayout.DropTarget, Ext.dd.DropTarget, {
	notifyEnter: function(dd, e, data) {
		Terrasoft.ControlLayout.DropTarget.superclass.notifyEnter.apply(this, arguments);
	},

	showDropMarker: function(targetCl, position) {
		if (!targetCl.dropMarkerEl) {
			var body = Ext.getBody();
			var style = 'position:absolute;z-index:20000;'
			style = style + ((targetCl.direction == 'vertical') ? 
				'border-top:1px dotted #fd8000;' : 'border-left:1px dotted #fd8000;');
			targetCl.dropMarkerEl = body.createChild({style: style});
			targetCl.dropMarkerEl.visibilityMode = Ext.Element.DISPLAY;
		}
		var leftPosition;
		var topPosition;
		var width;
		var height;
		if (targetCl.direction == 'vertical') {
			leftPosition = targetCl.layout.innerCt.getLeft();
			topPosition = position;
			width = targetCl.layout.innerCt.getWidth();
		} else {
			topPosition = targetCl.layout.innerCt.getTop();
			leftPosition = position;
			height = targetCl.layout.innerCt.getHeight();
		}
		targetCl.dropMarkerEl.setSize(width, height);
		targetCl.dropMarkerEl.setLeftTop(leftPosition, topPosition);
		targetCl.dropMarkerEl.show();
	},

	hideDropMarker: function(targetCl) {
		if (targetCl.dropMarkerEl) {
			targetCl.dropMarkerEl.hide();
		}
	},

	notifyOver: function(dd, e, data) {
		data.dropStatus = false;
		if (this.controlLayout == data.control) {
			return;
		}
		var isInsideDragging = (this.controlLayout == dd.controlLayout);
		var targetCl = this.controlLayout;
		var dropMarkerSize = 1;
		var items = targetCl.layout.getItems(targetCl);
		var item, r, nextR, nextItem;
		var index = (items.length > 0) ? -1 : 0;
		var isBefore;
		data.index = -1;
		var oldIndex = (isInsideDragging) ? this.controlLayout.items.indexOf(data.control) : -1;
		var markerPosition = 0;
		if (targetCl.direction == 'vertical') {
			var y = Ext.lib.Event.getPageY(e);
			for (var i = 0; i < items.length - 1; i++) {
				item = items[i];
				nextItem = items[i + 1]
				r = Ext.lib.Dom.getRegion(item.getResizeEl());
				nextR = Ext.lib.Dom.getRegion(nextItem.getResizeEl());
				if (i == 0 && y < r.top) {
					index = 0;
					markerPosition = item.getPosition()[1] - 2;
					break;
				}
				if (r.top < y && y < nextR.top) {
					isBefore = (y <= ((nextR.top + r.top) / 2));
					index = isBefore ? i : i + 1;
					var topPosition = (isBefore) ? 
						item.getPosition()[1] : nextItem.getPosition()[1];
					var margins;
					if (isBefore) {
						margins = (i - 1 >= 0) ? items[i-1].margins.bottom + item.margins.top : 4;
					} else {
						margins = item.margins.bottom + nextItem.margins.top;
					}
					markerPosition = topPosition - ((margins + dropMarkerSize) / 2);
					break;
				}
				if (i == items.length - 2 && y > nextR.top) {
					isBefore = (y <= (nextR.top + (nextItem.getHeight() / 2)));
					index = isBefore ? i + 1 : i + 2;
					if (isBefore) {
						markerPosition = nextItem.getPosition()[1] -
						((item.margins.bottom + nextItem.margins.top + 1) / 2);
					} else {
						markerPosition = 
							nextItem.getPosition()[1] + nextItem.getHeight() - 1;
					}
					break;
				}
			}
			if (items.length == 1) {
				item = items[0];
				r = Ext.lib.Dom.getRegion(item.getResizeEl());
				if (y < r.top) {
					index = 0;
					markerPosition = item.getPosition()[1] - 2;
				} else {
					index = 1;
					markerPosition = item.getPosition()[1] + item.getHeight() + 1;
				}
			}
		} else {
			var x = Ext.lib.Event.getPageX(e);
			for (var i = 0; i < items.length - 1; i++) {
				item = items[i];
				nextItem = items[i + 1]
				r = Ext.lib.Dom.getRegion(item.getResizeEl());
				nextR = Ext.lib.Dom.getRegion(nextItem.getResizeEl());
				if (i == 0 && x < r.left) {
					index = 0;
					markerPosition = 0;
					break;
				}
				if (r.left < x && x < nextR.left) {
					isBefore = (x <= ((nextR.left + r.left) / 2));
					index = isBefore ? i : i + 1;
					var position = (isBefore) ? 
						item.getPosition()[0] : nextItem.getPosition()[0];
					var margins;
					if (isBefore) {
						margins = (i - 1 >= 0) ? items[i-1].margins.right + item.margins.left : 4;
					} else {
						margins = item.margins.right + nextItem.margins.left;
					}
					markerPosition = position - ((margins + dropMarkerSize) / 2);
					break;
				}
				if (i == items.length - 2 && x > nextR.left) {
					isBefore = (x <= (nextR.left + (nextItem.getWidth() / 2)));
					index = isBefore ? i + 1 : i + 2;
					if (isBefore) {
						markerPosition = nextItem.getPosition()[0] -
						((item.margins.right + nextItem.margins.left + 1) / 2);
					} else {
						markerPosition = 
							nextItem.getPosition()[0] + nextItem.getWidth() - 1;
					}
					break;
				}
			}
			if (items.length == 1) {
				item = items[0];
				r = Ext.lib.Dom.getRegion(item.getResizeEl());
				if (x < r.left) {
					index = 0;
					markerPosition = 0;
				} else {
					index = 1;
					markerPosition = item.getPosition()[0] + item.getWidth() - 1;
				}
			}
		}
		if (isInsideDragging && index > oldIndex) {
			index = index - 1;
		}
		if (index > -1) {
				markerPosition = (markerPosition > 0) ? markerPosition : 0;
				this.showDropMarker(targetCl, markerPosition);
				data.index = index;
				data.dropStatus = true;
		}
		return data.dropStatus ? this.dropAllowed : this.dropNotAllowed;
	},

	notifyOut: function(dd, e, data) {
		this.hideDropMarker(this.controlLayout);
	},
	
	notifyDrop: function(dd, e, data) {
		this.hideDropMarker(this.controlLayout);
		if (data.dropStatus !== true) {
			return;
		}
		var movePosition = '';
		var targetControlId = '';
		var items = this.controlLayout.items.items;
		if (dd.ddGroup == 'DesignerDD' && data.nodes) {
			var nodes = [];
			for(var i = 0; i < data.nodes.length; i++) {
				nodes.push(data.nodes[i].row);
			}
			if (data.index == items.length) {
				if (data.index == 0) {
					movePosition = 'Append';
				} else {
					movePosition = 'Below';
					targetControlId = items[data.index-1].id;
				}
			} else {
				movePosition = 'Above';
				targetControlId = items[data.index].id;
			}
			this.controlLayout.fireEvent('itemsdrop', this.controlLayout.id, Ext.util.JSON.encode(nodes, 2), data.index,
				targetControlId, movePosition);
			return true;
		}
		var oldIndex = -1;
		if (dd.ddGroup == 'ControlLayoutDD' && data.index != undefined && data.index != -1) {
			oldIndex = data.control.ownerCt.items.indexOf(data.control);
			if (oldIndex < data.index) {
				if (oldIndex == -1) {
					movePosition = 'Above';
				} else {
					movePosition = 'Below';
				}
			} else {
				movePosition = 'Above';
			}
			if (oldIndex != -1) {
				if (data.control.ownerCt.id != this.controlLayout.id) {
					var destinationControlCount = items.length;
					if (data.index == destinationControlCount) {
						movePosition = 'Below';
					}
				}
				if (movePosition == 'Below') {
					if (data.control.ownerCt.id != this.controlLayout.id) {
						if (data.index != 0) {
							targetControlId = items[data.index - 1].id;
						} else {
							movePosition = 'Append';
						}
					} else {
						targetControlId = items[data.index].id;
					}
				} else if (movePosition == 'Above') {
					targetControlId = items[data.index].id;
				}
			}
			targetControlId = targetControlId || '';
			var controlMoved = this.controlLayout.moveControl(data.control, data.index, false, targetControlId,
				movePosition);
			return controlMoved;
		}
		return false;
	}
})

Terrasoft.ControlLayout.ControlDragSource = function(controlLayout, control, cfg) {
	this.controlLayout = controlLayout;
	this.control = control;
	this.dragData = {control: control};
	this.proxy = new Terrasoft.ControlLayout.ControlProxy(control);
	Terrasoft.ControlLayout.ControlDragSource.superclass.constructor.call(
		this, control.getResizeEl(), cfg);
	this.invalidHandleTypes = {};
	if (control) {
		this.setHandleElId(control.getResizeEl().id);
	}
	this.scroll = false;
};

Ext.extend(Terrasoft.ControlLayout.ControlDragSource, Ext.dd.DragSource, {
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
		this.hideProxy();
	},

	autoOffset: function(x, y) {
		x -= this.startPageX;
		y -= this.startPageY;
		this.setDelta(x, y);
	}
});

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}