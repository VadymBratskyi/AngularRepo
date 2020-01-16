Ext.layout.BoxLayout = Ext.extend(Ext.layout.ContainerLayout, {
	defaultMargins: { left: 0, top: 0, right: 0, bottom: 0 },
	padding: '0',
	direction: 'vertical',
	monitorResize: true,
	scrollOffset: 0,
	ctCls: 'x-control-layout-ct',
	minSplitterSize: 2,
	defaultSplitterSize: 11,
	innerCls: 'x-control-layout-inner',

	init: function() {
		this.splitBars = [];
		if (typeof this.defaultMargins == 'string') {
			this.defaultMargins = this.parseMargins(this.defaultMargins);
		}
	},

	isValidParent: function(c, target) {
		return c.getEl().dom.parentNode == this.innerCt.dom ||
				c.getResizeEl().dom.parentNode == this.innerCt.dom;
	},

	isScrollable: function() {
		return true;
	},

	onLayout: function(ct, target) {
		var container = this.container;
		var containerEl = container.getResizeEl();
		var isContainerVisible = containerEl && containerEl.isVisible(true);
		if (!isContainerVisible || container.collapsed) {
			return;
		}
		//LayoutManager.start(ct.id);
		if (container.isViewPort) {
			target = container.formEl;
		}
		var cs = ct.items.items, len = cs.length, c, i, last = len - 1, cm;
		if (!this.innerCt) {
			target.addClass(this.ctCls);
			if (container.autoScroll) {
				this.contentTarget = target.createChild();
				this.contentTarget.isScrollable = this.isScrollable;
				this.contentTarget.contentScroll = this.scrollContent;
				container.scrollBar = Ext.ScrollBar.insertScrollBar(this.contentTarget);
				this.contentWrap = container.scrollBar.contentWrap;
				this.contentTarget.contentWrap = this.contentWrap;
				this.contentTarget.scrollBar = container.scrollBar;
				this.innerCt = container.scrollBar.contentWrap;
				this.innerCt.addClass(this.innerCls);
			} else {
				this.innerCt = target.createChild({ cls: this.innerCls });
			}
			this.padding = this.parseMargins(this.padding);
			if (container.dragDropMode === 'drop' || container.dragDropMode === 'dragdrop') {
				container.dropTargetDD = new Terrasoft.ControlLayout.DropTarget(container);
			}
			var imageSrc = container.imageSrc;
			if (!Ext.isEmpty(imageSrc) && imageSrc !== 'none') {
				this.innerCt.setStyle('background-image', imageSrc);
			}
		}
		this.renderAll(ct, this.innerCt);
		if (this.direction == 'vertical') {
			this.onVerticalLayout(ct, target);
		} else {
			this.onHorizontalLayout(ct, target);
		}
		//LayoutManager.stop(ct.id);
		this.isFirstLayout = false;
	},

	renderItem: function(item, index, target) {
		var container = this.container;
		if (typeof item.margins == 'string' && !Ext.isEmpty(item.margins)) {
			item.margins = this.parseMargins(item.margins);
			item.presetMargins = Ext.apply({}, item.margins);
		} else {
			item.margins = {};
			Ext.apply(item.margins, this.defaultMargins);
		}
		Ext.layout.BoxLayout.superclass.renderItem.call(this, item, index, target);
		if (!item.captionWrap && container.ignoreCaption !== true && item.supportsCaption === true) {
			var containerCaptionPosition = container.captionPosition;
			containerCaptionPosition =
				containerCaptionPosition && item.isCaptionPositionSupports(containerCaptionPosition) ?
					containerCaptionPosition : null;
			if (containerCaptionPosition) {
				item.captionPosition = containerCaptionPosition;
			}
			if (item.caption && item.captionPosition !== 'right') {
				var hasLabelEl= !Ext.isEmpty(item.caption);
				var controlEl = item.controlEl = item.getResizeEl();
				var captionWrap = item.captionWrap = controlEl.wrap({});
				var labelConfig = {
					tag: 'label'
				};
				if (!item.onCaptionClick) {
					labelConfig.htmlFor = item.getFocusEl().id;
				}
				labelConfig.style = 'position:absolute;top:0;left:0;';
				labelConfig.cls = 'x-display-name';
				var itemLabelEl = item.labelEl;
				if (item.supportsCaption === true && hasLabelEl) {
					itemLabelEl = item.labelEl = captionWrap.createChild(labelConfig, controlEl);
				}
				if (item.onCaptionClick) {
					if (itemLabelEl) {
						itemLabelEl.on('click', item.onCaptionClick, item);
					}
				}
				var captionEl = item.getLabelEl();
				if (item.supportsCaption === true && captionEl) {
					captionEl.dom.innerHTML = item.caption || "";
				}
				if (item.required) {
					item.markRequired(item.required);
				}
				if (item.captionColor) {
					item.setCaptionColor(item.captionColor);
				}
				item.resizeEl = captionWrap;
				item.positionEl = captionWrap;
				var labelElWidth = 0;
				if (itemLabelEl) {
					itemLabelEl.dom.innerHTML = item.caption.replace(/ /g, '&nbsp;');
					labelElWidth = itemLabelEl.getTextWidth();
					labelElWidth += 1;
					itemLabelEl.dom.innerHTML = item.caption.replace(/&nbsp;/g, '');
				}
				item.labelMargin = (labelElWidth > 0 || (itemLabelEl && !Ext.isEmpty(item.caption))) ? 5 : 0;
				var controlElWidth = controlEl.getWidth();
				if (item.captionPosition === 'top') {
					item.setCaptionWidth(controlElWidth);
					var labelElHeight = itemLabelEl ? itemLabelEl.getHeight() : 0;
					var controlElPaddingTop = labelElHeight + item.labelMargin;
					captionWrap.setStyle('padding-top', captionWrap.addUnits(controlElPaddingTop));
					item.on('resize', this.onLayoutControlResize, item);
				} else if (item.captionPosition === 'left') {
					if (this.maxLabelMarginSize == undefined || this.maxLabelMarginSize < item.labelMargin) {
						this.maxLabelMarginSize = item.labelMargin;
					}
					item.setCaptionWidth(labelElWidth);
					var controlElPaddingLeft = labelElWidth + item.labelMargin;
					captionWrap.setStyle('padding-left', captionWrap.addUnits(controlElPaddingLeft));
					var newControlElSize = controlEl.getWidth() - controlElPaddingLeft;
					if (newControlElSize > 0) {
						controlEl.setWidth(newControlElSize);
					}
					item.captionVerticalAlign = container.captionVerticalAlign || item.captionVerticalAlign || 'middle';
					item.setCaptionVerticalAlign(item.captionVerticalAlign);
					item.on('resize', this.onLayoutControlResize, this);
				}
				if (item.captionPosition === 'right') {
					item.updateSizeAfterCaptionChange(labelElWidth);
				}
			}
		}
		if (item.hidden) {
			if (item.wrap && item.captionWrap) {
				item.wrap.removeClass('x-hide-' + item.hideMode);
			}
			item.suspendEvents();
			item.hide();
			item.resumeEvents();
		}
		if (!item.enabled) {
			item.disable();
		}
		item.getPositionEl().addClass('x-control-layout-item');
		if (container.dragDropMode === 'drag' || container.dragDropMode === 'dragdrop') {
			item.dragSourceDD = new Terrasoft.ControlLayout.ControlDragSource(container, item, {
					ddGroup: 'ControlLayoutDD'
				});
		}
		if (item.designMode) {
			item.getResizeEl().on('mousedown', container.onItemMouseDown, item);
		}
	},

	onLayoutControlResize: function(item, w, h, force) {
		var controlEl = item.controlEl;
		if (item.captionPosition !== 'top') {
			if (force !== true && (w == undefined || w == 'auto')) {
				return;
			}
			var labelElsWidth = item.getCaptionWidth();
			var controlElPaddingLeft = labelElsWidth + item.labelMargin;
			var width = (w == undefined) ? controlEl.getWidth() : w;
			controlEl.setWidth(width - controlElPaddingLeft);
		} else if (item.captionPosition === 'top') {
			var labelElHeight;
			var controlElPaddingTop;
			var labelEl = item.labelEl;
			if (h != undefined && h != 'auto') {
				labelElHeight = labelEl ? labelEl.getHeight() : 0;
				controlElPaddingTop = labelElHeight + item.labelMargin;
				controlEl.setHeight(h - controlElPaddingTop);
			}
			if (w != undefined && w != 'auto') {
				item.setCaptionWidth(w);
				controlEl.setWidth(w);
				labelElHeight = labelEl ? labelEl.getHeight() : 0;
				controlElPaddingTop = labelElHeight + item.labelMargin;
				item.captionWrap.setStyle('padding-top', item.captionWrap.addUnits(controlElPaddingTop));
			}
		}
	},

	scrollContent: function(direction, increment) {
		var x = undefined;
		var y = undefined;
		var sign = 1;
		if (direction == 'left' || direction == 'up') {
			sign = -1;
		}
		if (direction == 'left' || direction == 'right') {
			var oldX = Math.abs(this.contentWrap.getLeft(true));
			x = oldX + increment * sign;
		} else {
			var oldY = Math.abs(this.contentWrap.getTop(true));
			y = oldY + increment * sign ;
		}
		this.dom.contentScroll(x, y, false);
		this.scrollBar.update();
	},

	setControlCaptionWidth: function(item) {
		item.isCaptionWidthChanged = false;
		var containerCaptionWidth = this.container.getContainerCaptionWidth();
		if (containerCaptionWidth) {
			this.maxCaptionWidth = containerCaptionWidth;
		}
		if (this.maxCaptionWidth) {
			var labelEl = item.labelEl;
			if (labelEl && labelEl.getWidth() != this.maxCaptionWidth) {
				item.isCaptionWidthChanged = true;
				var captionWrap = item.captionWrap;
				var captionWrapWidth = captionWrap.getWidth();
				var controlElPaddingLeft = 0;
				var newControlElSize = captionWrapWidth - controlElPaddingLeft;
				if (newControlElSize > 0) {
					item.controlEl.setWidth(newControlElSize);
				}
				captionWrap.setStyle('padding-left', Ext.Element.addUnits(controlElPaddingLeft));
				captionWrap.setWidth(captionWrapWidth);
			}
		}
	},

	alignControlLeft: function(item) {
		var containerCaptionWidth = this.container.getContainerCaptionWidth();
		if (containerCaptionWidth !== undefined) {
			this.maxCaptionWidth = containerCaptionWidth;
		}
		if (this.maxCaptionWidth !== undefined && item.labelEl) {
			var itemCaptionWidth = item.getCaptionWidth();
			if (item.alignedByCaption !== false && item.captionPosition != 'top' &&
					(item.isCaptionWidthChanged === true || itemCaptionWidth != this.maxCaptionWidth) ||
					item.needUpdateSize === true) {
				item.setCaptionWidth(this.maxCaptionWidth);
				item.updateSizeAfterCaptionChange(this.maxCaptionWidth);
				item.needUpdateSize = false;
			}
			if (item.alignedByCaption === false && item.captionPosition != 'top') {
				var captionWidth = 0;
				if (item.captionPosition == 'left') {
					captionWidth = item.getCaptionTextWidth();
					if (captionWidth > 0) {
						item.labelMargin = 5;
					}
				}
				if (itemCaptionWidth != captionWidth) {
					item.setCaptionWidth(captionWidth);
				}
				item.updateSizeAfterCaptionChange(captionWidth);
			}
		}
	},

	alignControlWithoutCaptionLeft: function(item) {
		if (item.supportsCaption && item.captionPosition !== 'top' && !item.labelEl) {
			var leftOffset = item.presetMargins ? item.presetMargins.left : this.defaultMargins.left;
			if (item.alignedByCaption !== false) {
				if (this.maxCaptionWidth !== undefined) {
					leftOffset = leftOffset + this.maxCaptionWidth;
				}
				if (this.maxLabelMarginSize) {
					leftOffset = leftOffset + this.maxLabelMarginSize;
				}
			}
			item.margins.left = leftOffset;
		}
	},

	fitContent: function(items) {
		if (this.direction == 'vertical' && this.container.fitHeightByContent === true) {
			return;
		}
		var hasFlexHeight = false;
		var hasFlexWidth = false;
		var expandedItemByHeight = null;
		var expandedItemByWidth = null;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			if (item.flexHeight && !hasFlexHeight) {
				hasFlexHeight = true;
			}
			if (item.flexWidth && !hasFlexWidth) {
				hasFlexWidth = true;
			}
			var prevItemHasSplitter = (i - 1 >= 0) ? items[i - 1].hasSplitter : false;
			if (!item.collapsed && (item.hasSplitter === true || prevItemHasSplitter === true)) {
				if (!hasFlexHeight) {
					expandedItemByHeight = item;
				}
				if (!hasFlexWidth) {
					expandedItemByWidth = item;
				}
			}
		}
		if (!hasFlexHeight && expandedItemByHeight) {
			expandedItemByHeight.flexHeight = 100;
		}
		if (!hasFlexWidth && expandedItemByWidth) {
			expandedItemByWidth.flexWidth = 100;
		}
	},

	getSplitterSize: function(control) {
		var splitterSize = 0;
		if (control.hasSplitter !== true) {
			return splitterSize;
		}
		splitterSize = (control.splitterSize !== undefined) ?
			Math.max(control.splitterSize, this.minSplitterSize) : this.defaultSplitterSize;
		return splitterSize;
	},

	getSplitBarProxy: function() {
		var proxy = Ext.get('splitBarProxy');
		if (!proxy) {
			var domEl = document.createElement("div");
			domEl.id = 'splitBarProxy';
			proxy = new Ext.Element(domEl);
			proxy.unselectable();
			proxy.addClass('x-splitbar-proxy');
			proxy.setStyle('background-color', '#ccc');
			Ext.getBody().appendChild(proxy.dom);
		}
		return proxy;
	},

	resizeSplitBarProxy: function() {
		var splitBarEl = this.el;
		var width;
		var height;
		if (this.orientation == Ext.SplitBar.VERTICAL) {
			height = 1;
			width = splitBarEl.getWidth();
		} else {
			width = 1;
			height = splitBarEl.getHeight();
		}
		var dragEl = this.dd.getDragEl();
		Ext.fly(dragEl).setSize(width, height);
	},

	onSplitterButtonNextClick: function() {
		var parent = this.parent().parent();
		if (parent.collapseTargetPrev.collapsed === true && !parent.lastTarget) {
			parent.lastTarget = parent.collapseTargetPrev;
		}
		if (parent.collapseTargetNext.collapsed === true && !parent.lastTarget) {
			return;
		}
		if (!parent.lastTarget) {
			parent.collapseTargetNext.splitterMoving = true;
			parent.collapseTargetNext.toggleCollapse();
			parent.collapseTargetNext.splitterMoving = false;
			parent.lastTarget = parent.collapseTargetNext;
		} else {
			parent.lastTarget.splitterMoving = true;
			parent.lastTarget.toggleCollapse();
			parent.lastTarget.splitterMoving = false;
			delete parent.lastTarget;
			if (parent.collapseTargetPrev.collapsed === true) {
				parent.lastTarget = parent.collapseTargetPrev;
			}
			if (parent.collapseTargetNext.collapsed === true) {
				parent.lastTarget = parent.collapseTargetNext;
			}
		}
	},

	onSplitterButtonPrevClick: function() {
		var parent = this.parent().parent();
		if (parent.collapseTargetNext.collapsed === true && !parent.lastTarget) {
			parent.lastTarget = parent.collapseTargetNext;
		}
		if (parent.collapseTargetPrev.collapsed === true && !parent.lastTarget) {
			return;
		}
		if (!parent.lastTarget) {
			parent.collapseTargetPrev.splitterMoving = true;
			parent.collapseTargetPrev.toggleCollapse();
			parent.collapseTargetPrev.splitterMoving = false;
			parent.lastTarget = parent.collapseTargetPrev;
		} else {
			parent.lastTarget.splitterMoving = true;
			parent.lastTarget.toggleCollapse();
			parent.lastTarget.splitterMoving = false;
			delete parent.lastTarget;
			if (parent.collapseTargetPrev.collapsed === true) {
				parent.lastTarget = parent.collapseTargetPrev;
			}
			if (parent.collapseTargetNext.collapsed === true) {
				parent.lastTarget = parent.collapseTargetNext;
			}
		}
	},

	specifyCollapseTarget: function(splitBar, item, nextItem) {
		splitBar.el.collapseTargetNext = nextItem;
		splitBar.el.collapseTargetPrev = item;
	},

	addSplitBar: function (control) {
		var isVerticalDirection = (this.direction == 'vertical');
		var splitterSize = this.getSplitterSize(control);
		var dragElementConfig = {cls: "x-layout-split"};
		var dragElementStyle = {position:'absolute'};
		if (isVerticalDirection) {
			dragElementStyle.left = '0';
			dragElementStyle.width = '100%';
			dragElementStyle.height = Ext.Element.addUnits(splitterSize);
		} else {
			dragElementStyle.top = '0';
			dragElementStyle.height = '100%';
			dragElementStyle.width = Ext.Element.addUnits(splitterSize);
		}
		dragElementConfig.style = dragElementStyle;
		var dragElement = this.innerCt.createChild(dragElementConfig);
		var splitLineConfig = {
			cls: 'x-layout-top-split-line',
			style: {position: 'absolute'}
		};
		splitLineConfig.style[(isVerticalDirection) ? 'height' : 'width'] = '1px';
		splitLineConfig.style['z-index'] = 2;
		var splitLine = dragElement.createChild(splitLineConfig);
		splitLineConfig.style['z-index'] = 1;
		splitLineConfig.style['background-color'] = '#fefefe';
		delete splitLineConfig.cls;
		var shadowSplitLine = dragElement.createChild(splitLineConfig);
		var splitterButtonConfig = {};
		var splitterButtonConfigStyle = {
			position: 'absolute',
			cursor: 'pointer',
			'z-index': 3
		};
		var firstSplitterButtonCls;
		var firstSplitterButtonOnClickCls;
		var secondSplitterButtonCls;
		var secondSplitterButtonOnClickCls;
		if (isVerticalDirection) {
			splitterButtonConfigStyle.width = '56px';
			splitterButtonConfigStyle.height = '8px';
			firstSplitterButtonCls = 'x-layout-splitter-btn-horizontal-up';
			firstSplitterButtonOnClickCls = 'x-layout-splitter-btn-horizontal-up-click';
			secondSplitterButtonCls = 'x-layout-splitter-btn-horizontal-down';
			secondSplitterButtonOnClickCls = 'x-layout-splitter-btn-horizontal-down-click';
		} else {
			splitterButtonConfigStyle.width = '8px';
			splitterButtonConfigStyle.height = '56px';
			firstSplitterButtonCls = 'x-layout-splitter-btn-vertical-left';
			firstSplitterButtonOnClickCls = 'x-layout-splitter-btn-vertical-left-click';
			secondSplitterButtonCls = 'x-layout-splitter-btn-vertical-right';
			secondSplitterButtonOnClickCls = 'x-layout-splitter-btn-vertical-right-click';
		}
		splitterButtonConfig.style = splitterButtonConfigStyle;
		var splitterButton = dragElement.createChild(splitterButtonConfig);
		var firstSplitterButton = splitterButton.createChild({cls: firstSplitterButtonCls});
		var secondSplitterButton = splitterButton.createChild({cls: secondSplitterButtonCls});
		firstSplitterButton.addClassOnClick(firstSplitterButtonOnClickCls);
		secondSplitterButton.addClassOnClick(secondSplitterButtonOnClickCls);
		firstSplitterButton.on('click', this.onSplitterButtonPrevClick);
		secondSplitterButton.on('click', this.onSplitterButtonNextClick);
		var proxy = this.getSplitBarProxy();
		var orientation = (isVerticalDirection) ?
			Ext.SplitBar.VERTICAL : Ext.SplitBar.HORIZONTAL;
		var placement = (isVerticalDirection) ? Ext.SplitBar.TOP : Ext.SplitBar.LEFT;
		var splitBar = new Ext.SplitBar(dragElement, control.getResizeEl(), orientation,
			placement, proxy);
		splitBar.dd.centerFrame = true;
		splitBar.dd._resizeProxy = this.resizeSplitBarProxy.createDelegate(splitBar);
		splitBar.component = control;
		splitBar.splitterButton = splitterButton;
		splitBar.splitLine = splitLine;
		splitBar.shadowSplitLine = shadowSplitLine;
		splitBar.el.visibilityMode = Ext.Element.DISPLAY;
		splitBar.addListener("moved", this.onSplitterMoved, this);
		splitBar.setAdapter(new Ext.SplitBar.AbsoluteLayoutAdapter(this.innerCt));
		splitBar.adapter.setElementSize = Ext.emptyFn;
		this.splitBars[control.id] = splitBar;
		return splitBar;
	},

	layoutSplitBar: function(splitBar) {
		var isVerticalDirection = (this.direction == 'vertical');
		var splitterButton = splitBar.splitterButton;
		var splitBarEl = splitBar.el;
		var splitBarElHeight = splitBarEl.getHeight();
		var splitterButtonHeight = splitterButton.getHeight();
		var splitBarElWidth = splitBarEl.getWidth();
		var splitterButtonWidth = splitterButton.getWidth();
		var splitLine = splitBar.splitLine;
		var shadowSplitLine = splitBar.shadowSplitLine;
		var splitLineTopPosition = (splitBarElHeight - 1) / 2;
		var splitLineLeftPosition = (splitBarElWidth - 1) / 2;
		var requiredClass;
		if (isVerticalDirection) {
			var splitterButtonTopPosition = Ext.isGecko ? 1 : (splitBarElHeight - splitterButtonHeight) / 2;
			splitterButton.setStyle('top', Ext.Element.addUnits(splitterButtonTopPosition));
			var splitterButtonLeftPosition = (splitBarElWidth - splitterButtonWidth) / 2;
			splitterButton.setStyle('left', Ext.Element.addUnits(splitterButtonLeftPosition));
			splitLine.setStyle('top', Ext.Element.addUnits(splitLineTopPosition));
			splitLine.setStyle('width', '100%');
			shadowSplitLine.setStyle('top', Ext.Element.addUnits(splitLineTopPosition + 1));
			shadowSplitLine.setStyle('width', '100%');
			requiredClass = (splitBar.collapseTarget == splitBar.component);
			// requiredClass = (splitBar.collapseTarget.collapsed) ? !requiredClass : requiredClass;
			splitterButton[requiredClass ? 'addClass' : 'removeClass'](
				'x-layout-splitter-btn-horizontal-top');
		} else {
			var splitterButtonTopPosition = (splitBarElHeight - splitterButtonHeight) / 2;
			splitterButton.setStyle('top', Ext.Element.addUnits(splitterButtonTopPosition));
			var splitterButtonLeftPosition = Ext.isGecko ? 1 : (splitBarElWidth - splitterButtonWidth) / 2;
			splitterButton.setStyle('left', Ext.Element.addUnits(splitterButtonLeftPosition));
			splitLine.setStyle('left', Ext.Element.addUnits(splitLineLeftPosition));
			splitLine.setStyle('height', '100%');
			shadowSplitLine.setStyle('left', Ext.Element.addUnits(splitLineLeftPosition + 1));
			shadowSplitLine.setStyle('height', '100%');
			requiredClass = (splitBar.collapseTarget != splitBar.component);
			// requiredClass = (splitBar.collapseTarget.collapsed) ? !requiredClass : requiredClass;
			splitterButton[(requiredClass) ? 'addClass' : 'removeClass'](
				'x-layout-splitter-btn-vertical-right');
		}
	},

	getMaxCaptionWidths: function (items) {
		var itemsLength = items.length;
		var maxCaptionWidth = 0;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.captionPosition != 'top' && item.labelEl) {
				var width = item.getCaptionWidth();
				if (maxCaptionWidth < width) {
					maxCaptionWidth = width;
				}
			}
		}
		return maxCaptionWidth;
	},

	alignControls: function (items) {
		var itemsLength = items.length;
		var containerCaptionWidth = this.container.getContainerCaptionWidth();
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (containerCaptionWidth > 0 || item.captionPosition == 'top') {
				this.maxLabelMarginSize = 5;
			} else {
				this.maxLabelMarginSize = 0;
			}
			if (this.maxLabelMarginSize != undefined) {
				if (item.labelEl && item.alignedByCaption !== false && item.labelMargin != this.maxLabelMarginSize) {
					item.labelMargin = this.maxLabelMarginSize;
				}
			}
			this.setControlCaptionWidth(item);
			this.alignControlLeft(item);
			this.alignControlWithoutCaptionLeft(item);
		}
	},

	calcCaptionWidthsAndAlignItems: function (items) {
		if (this.direction == 'vertical') {
			this.maxCaptionWidth = this.getMaxCaptionWidths(items);
			this.alignControls(items);
		} else {
			var firstItem = items[0];
			if (firstItem && firstItem.supportsCaption === true && firstItem.alignedByCaption === true &&
					firstItem.captionPosition != 'top') {
				this.setControlCaptionWidth(firstItem);
				var containerCaptionWidth = this.container.getContainerCaptionWidth();
				if (containerCaptionWidth != undefined && firstItem.labelMargin == undefined) {
					firstItem.labelMargin = 5;
				}
				if (containerCaptionWidth) {
					if (firstItem.labelEl && firstItem.getCaptionWidth() != containerCaptionWidth) {
						firstItem.setCaptionWidth(containerCaptionWidth);
						firstItem.updateSizeAfterCaptionChange(containerCaptionWidth);
					} else {
						this.maxCaptionWidth = this.container.captionWidth;
						this.maxLabelMarginSize = firstItem.labelMargin;
						this.alignControlWithoutCaptionLeft(firstItem);
					}
				}
			}
		}
	},

	layoutChildContainers: function (items, config) {
		var isFirstLayout = config.isFirstLayout;
		var checkFirstLayout = config.checkFirstLayout && isFirstLayout;
		var itemsLength = items.length;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.fitHeightByContent == true && item.layout) {
				var isFirstItemLayout = item.layout.isFirstLayout != false;
				if (!checkFirstLayout || isFirstItemLayout) {
					item.layout.isFirstLayout = isFirstLayout;
					item.layout.layout();
					item.layout.isFirstLayout = isFirstLayout && isFirstItemLayout;
				}
			}
		}
	},

	getItemsLayoutInfo: function (items, overrideLastItemMargins) {
		var itemsLength = items.length;
		var itemMargins = {};
		var totalFlexHeight = 0;
		var totalFlexWidth = 0;
		var extraHeight = 0;
		var extraWidth = 0;
		var flexHeight = 0;
		var flexWidth = 0;
		var maxWidth = 0;
		var maxHeight = 0;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			Ext.apply(itemMargins, item.margins);
			var isLastItemWithoutSplitter = (i == (itemsLength -1));
			if (isLastItemWithoutSplitter) {
				Ext.apply(itemMargins, overrideLastItemMargins);
			}
			totalFlexHeight += item.flexHeight || 0;
			totalFlexWidth += item.flexWidth || 0;
			var itemHeight = item.getHeight();
			var itemWidth = item.getWidth();
			var splitterSize = isLastItemWithoutSplitter ? 0 : this.getSplitterSize(item);
			var verticalMargin = itemMargins.top + itemMargins.bottom;
			var horizontalMargin = itemMargins.left + itemMargins.right;
			var verticalMarginWithSplitter = verticalMargin + splitterSize;
			var horizontalMarginWithSplitter = horizontalMargin + splitterSize;
			extraHeight += itemHeight + verticalMarginWithSplitter;
			extraWidth += itemWidth + horizontalMarginWithSplitter;
			flexHeight += verticalMarginWithSplitter + (item.flexHeight ? 0 : itemHeight);
			flexWidth += horizontalMarginWithSplitter + (item.flexWidth ? 0 : itemWidth);
			var itemWidthInPercents = this.parsePercent(item.width);
			var itemHeightInPercents = this.parsePercent(item.height);
			var itemCalcWidth = itemWidthInPercents ? 0 : itemWidth + horizontalMargin;
			var itemCalcHeight = itemHeightInPercents ? 0 : itemHeight + verticalMargin;
			maxWidth = Math.max(maxWidth, itemCalcWidth);
			maxHeight = Math.max(maxHeight, itemCalcHeight);
		}
		return {
			totalFlexWidth: totalFlexWidth,
			totalFlexHeight: totalFlexHeight,
			flexWidth: flexWidth,
			flexHeight: flexHeight,
			maxWidth: maxWidth,
			maxHeight: maxHeight,
			extraWidth: extraWidth,
			extraHeight: extraHeight
		};
	},

	updateScroll: function(targetWidth, targetHeight, innerCtWidth, itemsLayoutInfo) {
		var isVerticalDirection = this.direction == 'vertical';
		var paddings = this.padding;
		var verticalPaddings = paddings.top + paddings.bottom;
		var horizontalPaddings = paddings.left + paddings.right;
		var extraHeight = 0;
		var extraWidth = 0;
		var newTargetWidth = targetWidth;
		var newTargetHeight = targetHeight;
		var container = this.container;
		if (container.scrollBar) {
			var vScrollOffset = container.scrollBar.vScroll.getWidth();
			var hScrollOffset = container.scrollBar.hScroll.getHeight();
			this.contentTarget.setSize(targetWidth, targetHeight);
			extraHeight = itemsLayoutInfo.extraHeight + verticalPaddings;
			extraWidth = itemsLayoutInfo.extraWidth + horizontalPaddings;
			var vScrollRequired = (isVerticalDirection ? extraHeight : itemsLayoutInfo.maxHeight) > targetHeight;
			if (isVerticalDirection && vScrollRequired) {
				newTargetWidth = targetWidth - vScrollOffset;
			}
			this.contentTarget.dom.scrollBarData.reqS[0] = vScrollRequired;
			var hScrollRequired = (isVerticalDirection ? innerCtWidth : extraWidth) > newTargetWidth;
			this.contentTarget.dom.scrollBarData.reqS[1] = hScrollRequired;
			if (isVerticalDirection) {
				newTargetHeight = extraHeight;
				extraHeight = 0;
			} else {
				if (hScrollRequired) {
					newTargetHeight = targetHeight - hScrollOffset;
				}
				newTargetWidth = extraWidth;
				extraWidth = 0;
			}
		} else {
			if (isVerticalDirection) {
				extraHeight = targetWidth - extraHeight - verticalPaddings;
			} else {
				extraWidth = targetHeight - extraWidth - horizontalPaddings;
			}
		}
		return {
			targetWidth: newTargetWidth,
			targetHeight: newTargetHeight,
			extraWidth: extraWidth,
			extraHeight: extraHeight
		};
	},

	setItemsSize: function (items, itemsSize) {
		var isFirstLayout = (this.isFirstLayout === true);
		for (var itemIndex in itemsSize) {
			var itemSize = itemsSize[itemIndex];
			var item = items[itemIndex];
			if (isFirstLayout && item.fitHeightByContent != true) {
				item.suspendEvents();
			}
			item.setSize(itemSize.width, itemSize.height);
			if (isFirstLayout && item.fitHeightByContent != true) {
				item.resumeEvents();
			}
		}
	},

	setItemsPosition: function(items, itemsPositions) {
		for (var itemIndex in itemsPositions) {
			var itemPosition = itemsPositions[itemIndex];
			var item = items[itemIndex];
			item.setPosition(itemPosition.x, itemPosition.y);
		}
	},

	calcItemsFlex: function (items, propertyName, flexPropertyName) {
		var itemsLength = items.length;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.layout && item.fitHeightByContent === true && propertyName == 'height') {
				continue;
			}
			if (item[propertyName] && typeof item[propertyName] == 'string') {
				var flex = this.parsePercent(item[propertyName]);
				if (flex !== null) {
					item[flexPropertyName] = flex;
				}
			}
		}
	},

	calcItemsSizeByFlex: function(items, availableSize, totalFlex, flexPropertyName, sizePropertyName) {
		var sezes = [];
		var itemsLength = items.length;
		var itemsSummerySize = 0;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item[flexPropertyName]) {
				var itemSize = Math.floor(availableSize * (item[flexPropertyName] / totalFlex));
				itemsSummerySize += itemSize;
				sezes.push(itemSize);
			}
		}
		var leftOver = availableSize - itemsSummerySize;
		return this.fixleftOver(items, sezes, leftOver, flexPropertyName, sizePropertyName);
	},

	fixleftOver: function(items, sizes, leftOver, flexPropertyName, sizePropertyName) {
		var itemsSize = {};
		var itemsLength = items.length;
		var idx = 0;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item[flexPropertyName]) {
				var itemSize = Math.max(0, sizes[idx++] + (leftOver-- > 0 ? 1 : 0));
				if (itemsSize[i] == undefined) {
					itemsSize[i] = {
						width: undefined,
						height: undefined
					};
				}
				itemsSize[i][sizePropertyName] = itemSize;
			}
		}
		return itemsSize;
	},

	onVerticalLayout: function(ct, target) {
		var isFirstLayout = (this.isFirstLayout === true);
		var items = this.getItems(ct);
		var itemsLength = items.length;
		var item;
		var i;
		this.calcCaptionWidthsAndAlignItems(items);
		this.calcItemsFlex(items, 'height', 'flexHeight');
		this.fitContent(items);
		if (this.container.fitHeightByContent !== true) {
			this.layoutChildContainers(items, {
				checkFirstLayout: true,
				isFirstLayout: isFirstLayout
			});
		}
		var isViewPort = this.container.isViewPort;
		if (isViewPort) {
			target = this.container.el;
		}
		var size = this.getTargetSize(target);
		var targetWidth = size.width;
		var targetHeight = size.height;
		targetHeight =
			this.container.adjustInnerCtHeight ? this.container.adjustInnerCtHeight(targetHeight) : targetHeight;
		var isLastItemWithoutSplitter;
		var splitterSize;
		var itemWidth;
		var itemsLayoutInfo = this.getItemsLayoutInfo(items, {
			bottom: 0
		});
		var totalFlex = itemsLayoutInfo.totalFlexHeight;
		var maxWidth = itemsLayoutInfo.maxWidth;
		var flexHeight = itemsLayoutInfo.flexHeight;
		var paddings = this.padding;
		var paddingLeft = paddings.left;
		var paddingTop = paddings.top;
		var verticalPaddings = paddings.top + paddings.bottom;
		var horizontalPaddings = paddings.left + paddings.right;
		var innerCtWidth = (isViewPort) ? targetWidth : maxWidth + horizontalPaddings;
		var recalcScrollData = this.updateScroll(targetWidth, targetHeight, innerCtWidth, itemsLayoutInfo);
		targetWidth = recalcScrollData.targetWidth;
		targetHeight = recalcScrollData.targetHeight;
		this.innerCt.setSize(targetWidth = Math.max(targetWidth, innerCtWidth), targetHeight);
		var availHeight = Math.max(0, targetHeight - verticalPaddings - flexHeight);
		var availableWidth = Math.max(0, targetWidth - horizontalPaddings);
		var itemMargins = {};
		var itemsSize = this.calcItemsSizeByFlex(items, availHeight, totalFlex, 'flexHeight', 'height');
		var itemsPositions = {};
		for (i = 0; i < itemsLength; i++) {
			item = items[i];
			Ext.apply(itemMargins, item.margins);
			if (i == 0) {
				itemMargins.top = 0;
			}
			if (i == itemsLength - 1) {
				itemMargins.bottom = 0;
			}
			if (item.width && typeof item.width == 'string') {
				var parsedWidth = this.parsePercent(item.width);
				if (parsedWidth !== null) {
					parsedWidth = Math.min(parsedWidth, 100);
					var availableItemWidth = (this.innerCt.getWidth() - (itemMargins.left + itemMargins.right) -
						horizontalPaddings).constrain(item.minWidth || 0, item.maxWidth || 1000000);
					itemWidth = Math.floor(availableItemWidth * parsedWidth / 100);
					if (itemsSize[i] == undefined) {
						itemsSize[i] = {
							width: undefined,
							height: undefined
						};
					}
					itemsSize[i].width = itemWidth;
				}
			}
			if (this.align == 'center' || this.align == 'right') {
				itemWidth = (itemsSize[i] && itemsSize[i].width) || item.getWidth();
				var diff = availableWidth - (itemWidth + itemMargins.left + itemMargins.right);
				var leftPosition = paddingLeft + itemMargins.left;
				if (diff > 0) {
					var alignOffset = (this.align == 'center') ? diff / 2 : diff;
					leftPosition = leftPosition + alignOffset;
				}
				if (itemsPositions[i] == undefined) {
					itemsPositions[i] = {
						x: undefined,
						y: undefined
					};
				}
				itemsPositions[i].x = leftPosition;
				itemsPositions[i].y = item.y;
			}
		}
		//this.layoutChildContainers(items, {
		//	checkFirstLayout: false,
		//	isFirstLayout: isFirstLayout
		//});
		this.setItemsSize(items, itemsSize);
		itemMargins = {};
		for (i = 0; i < itemsLength; i++) {
			item = items[i];
			Ext.apply(itemMargins, item.margins);
			isLastItemWithoutSplitter = (i == (itemsLength - 1));
			if (isLastItemWithoutSplitter) {
				itemMargins.bottom = 0;
			}
			paddingTop += itemMargins.top;
			if (itemsPositions[i] == undefined) {
				itemsPositions[i] = {
					x: undefined,
					y: undefined
				};
			}
			if (this.align == 'left') {
				itemsPositions[i].x = paddingLeft + itemMargins.left;
			}
			itemsPositions[i].y = paddingTop;
			var itemHeight = (itemsSize[i] && itemsSize[i].height) || item.getHeight();
			splitterSize = (isLastItemWithoutSplitter) ? 0 : this.getSplitterSize(item);
			paddingTop += itemHeight + itemMargins.bottom + splitterSize;
		}
		this.setItemsPosition(items, itemsPositions);
		this.updateSplitBars(items);
		this.updateContainerSize(ct, target, items);
	},

	onHorizontalLayout: function(ct, target) {
		var isFirstLayout = this.isFirstLayout && this.isFirstLayout === true;
		var items = this.getItems(ct);
		var item;
		var i;
		var itemsLength = items.length;
		this.calcCaptionWidthsAndAlignItems(items);
		this.calcItemsFlex(items, 'width', 'flexWidth');
		this.fitContent(items);
		var isViewPort = this.container.isViewPort;
		if (isViewPort) {
			target = this.container.el;
		}
		var size = this.getTargetSize(target);
		var targetWidth = size.width;
		var targetHeight = size.height;
		targetHeight = (this.container.adjustInnerCtHeight && targetHeight > 0) ?
			this.container.adjustInnerCtHeight(targetHeight) : targetHeight;
		var itemsLayoutInfo = this.getItemsLayoutInfo(items, {
			right: 0
		});
		var totalFlex = itemsLayoutInfo.totalFlexWidth;
		var maxHeight = itemsLayoutInfo.maxHeight;
		var flexWidth = itemsLayoutInfo.flexWidth;
		var paddings = this.padding;
		var paddingLeft = paddings.left;
		var paddingTop = paddings.top;
		var verticalPaddings = paddings.top + paddings.bottom;
		var horizontalPaddings = paddings.left + paddings.right;
		var recalcScrollData = this.updateScroll(targetWidth, targetHeight, null, itemsLayoutInfo);
		targetWidth = recalcScrollData.targetWidth;
		targetHeight = recalcScrollData.targetHeight;
		var innerCtHeight = isViewPort ? targetHeight : maxHeight + verticalPaddings;
		this.innerCt.setSize(targetWidth, targetHeight = Math.max(targetHeight, innerCtHeight));
		var availWidth = Math.max(0, targetWidth - horizontalPaddings - flexWidth);
		var availableHeight = Math.max(0, targetHeight - verticalPaddings);
		var itemMargins = {};
		var splitterSize;
		var itemsSize = this.calcItemsSizeByFlex(items, availWidth, totalFlex, 'flexWidth', 'width');
		var itemsPositions = {};
		for (i = 0; i < itemsLength; i++) {
			item = items[i];
			Ext.apply(itemMargins, item.margins);
			var isLastItem = (i == itemsLength - 1);
			if (i == 0) {
				itemMargins.left = 0;
			}
			if (isLastItem) {
				itemMargins.right = 0;
			}
			paddingLeft += itemMargins.left;
			if (itemsPositions[i] == undefined) {
				itemsPositions[i] = {
					x: undefined,
					y: undefined
				};
			}
			itemsPositions[i].x = paddingLeft;
			itemsPositions[i].y = paddingTop + itemMargins.top;
			var itemWidth = (itemsSize[i] && itemsSize[i].width) || item.getWidth();
			splitterSize = (isLastItem) ? 0 : this.getSplitterSize(item);
			paddingLeft += itemWidth + itemMargins.right + splitterSize;
		}
		this.layoutChildContainers(items, {
			checkFirstLayout: false,
			isFirstLayout: isFirstLayout
		});
		var itemHeight;
		itemMargins = {};
		for (i = 0; i < itemsLength; i++) {
			item = items[i];
			Ext.apply(itemMargins, item.margins);
			if (i == itemsLength - 1) {
				itemMargins.right = 0;
			}
			if (item.isAlign === false) {
				continue;
			}
			if (item.collapsed === true) {
				continue;
			}
			if (item.height && typeof item.height == 'string' && item.fitHeightByContent !== true) {
				var parsedHeight = this.parsePercent(item.height);
				if (parsedHeight !== null) {
					parsedHeight = Math.min(parsedHeight, 100);
					var availableItemHeight = (this.innerCt.getHeight() - (itemMargins.top + itemMargins.bottom) -
						verticalPaddings).constrain(item.minHeight || 0, item.maxHeight || 1000000);
					itemHeight = Math.floor(availableItemHeight * parsedHeight / 100);
					if (itemsSize[i] == undefined) {
						itemsSize[i] = {
							width: undefined,
							height: undefined
						};
					}
					itemsSize[i].height = itemHeight;
				}
			}
			if (this.align == 'middle' || this.align == 'bottom') {
				itemHeight = (itemsSize[i] && itemsSize[i].height) || item.getHeight();
				var diff = availableHeight - (itemHeight + itemMargins.top + itemMargins.bottom);
				var topPosition = paddingTop + itemMargins.top;
				if (diff > 0) {
					var alignOffset = (this.align == 'middle') ? diff / 2 : diff;
					topPosition = topPosition + alignOffset;
				}
				if (itemsPositions[i] == undefined) {
					itemsPositions[i] = {
						x: undefined,
						y: undefined
					};
				}
				itemsPositions[i].y = topPosition;
			}
		}
		this.setItemsSize(items, itemsSize);
		this.setItemsPosition(items, itemsPositions);
		this.updateSplitBars(items);
		this.updateContainerSize(ct, target, items);
	},

	updateSplitBars: function (items) {
		var itemsLength = items.length;
		var isVerticalLayout = this.direction == 'vertical';
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.hasSplitter !== true) {
				continue;
			}
			var splitBar = this.splitBars[item.id];
			var splitBarEl = splitBar ? splitBar.el : null;
			if (i == itemsLength - 1) {
				if (splitBar) {
					splitBarEl.dom.parentNode.removeChild(splitBarEl.dom);
					this.splitBars[item.id] = null;
					splitBar = null;
				}
				continue;
			}
			var nextItem = ((i + 1) < itemsLength) ? items[i + 1] : null;
			if (!nextItem.toggleCollapse) {
				continue;
			}
			if (!splitBar) {
				splitBar = this.addSplitBar(item);
				splitBarEl = splitBar.el;
			}
			this.specifyCollapseTarget(splitBar, item, nextItem);
			this.layoutSplitBar(splitBar);
			var setPositionFunction;
			var positionValue;
			if (isVerticalLayout) {
				setPositionFunction = 'setY';
				var minSize = (item.getMinSize) ? item.getMinSize() : 0;
				var maxSize = (item.getMaxSize) ? item.getMaxSize() : 0;
				if (nextItem) {
					var nextItemHeight = nextItem.getHeight();
					splitBar.maxSize = maxSize || item.getHeight() + nextItemHeight - minSize;
					var nextItemMaxSize = (nextItem.getMaxSize) ? nextItem.getMaxSize() : 0;
					minSize = (nextItemMaxSize) ? minSize + item.getHeight() : minSize;
					if (nextItemMaxSize != 0) {
						nextItemMaxSize = nextItemHeight - nextItemMaxSize;
					}
					splitBar.minSize = minSize + nextItemMaxSize;
				} else {
					splitBar.maxSize = maxSize || 5000;
					splitBar.minSize = minSize;
				}
				positionValue = splitBar.resizingEl.getBottom();
			} else {
				setPositionFunction = 'setX';
				if (nextItem) {
					splitBar.maxSize = item.getWidth() + nextItem.getWidth();
				}
				positionValue = splitBar.resizingEl.getRight();
			}
			splitBarEl[setPositionFunction](positionValue);
		}
	},

	getItemsHeight: function(items) {
		var itemsLength = items.length;
		var extraHeight = 0;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			var margins = {};
			Ext.apply(margins, item.margins);
			if (i == itemsLength - 1) {
				margins.bottom = 0;
			}
			var verticalMargins = margins.top + margins.bottom;
			var itemHeight;
			if (this.direction == 'vertical') {
				itemHeight = item.getHeight();
				extraHeight += itemHeight + verticalMargins;
			} else {
				var splitterSize = this.getSplitterSize(item);
				var itemHeightInPercents = this.parsePercent(item.height);
				itemHeight = itemHeightInPercents ? 0 : item.getHeight() + verticalMargins + splitterSize;
				extraHeight = Math.max(extraHeight, itemHeight);
			}
		}
		return extraHeight;
	},

	updateContainerSize: function(container, target, items) {
		if (container.fitHeightByContent == true) {
			var headerHeight = (container.header) ? container.getHeaderHeight() : 0;
			var borderWidth = container.getResizeEl().getBorderWidth('tb');
			var targetPaddings = this.padding.top + this.padding.bottom;
			var containerPaddings = target.getPadding('tb');
			var extraHeight = this.getItemsHeight(items);
			var containerHeight = extraHeight + targetPaddings + borderWidth + containerPaddings;
			container.suspendEvents();
			this.innerCt.setHeight(containerHeight);
			container.setHeight(containerHeight + headerHeight);
			container.resumeEvents();
		}
		if (container.scrollBar) {
			container.scrollBar.update();
		}
	},

	getTargetSize: function(target) {
		return target.getStyleSize();
	},

	getItems: function(ct) {
		var items = [];
		ct.items.each(function(c) {
			if (c.rendered && !c.hidden) {
				items.push(c);
			}
		});
		return items;
	},

	onSplitterMoved: function(sb, newSize) {
		var startSize = sb.dragSpecs.startSize;
		var width = undefined;
		var height = undefined;
		if (sb.orientation == Ext.SplitBar.HORIZONTAL) {
			width = newSize;
		} else {
			height = newSize;
		}
		var items = this.getItems(this.container);
		var index = items.indexOf(sb.component);
		if (sb.component.collapsed) {
			sb.component.splitterMoving = true;
			sb.component.expand();
			sb.component.splitterMoving = false;
		}
		sb.component.setSize(width, height);
		var diffSize = startSize - newSize;
		if (sb.component.flexWidth || sb.component.flexHeight) {
			this.clearFlex(sb.component);
		}
		if (sb.orientation == Ext.SplitBar.VERTICAL && index == items.length - 1) {
			var containerHeight = this.container.getHeight();
			this.container.setHeight(containerHeight + (diffSize * -1));
			this.clearFlex(this.container);
			this.container.isAlign = false;
			return;
		}
		var nextItem = (index + 1) < (items.length) ? items[index + 1] : null;
		if (nextItem) {
			var nextItemWidth = undefined;
			var nextItemHeight = undefined;
			nextItem.splitterMoving = true;
			if (nextItem.collapsed) {
				nextItem.expand();
			}
			nextItem.splitterMoving = false;
			if (sb.orientation == Ext.SplitBar.HORIZONTAL) {
				nextItemWidth = nextItem.getWidth() + diffSize;
			} else {
				nextItemHeight = nextItem.getHeight() + diffSize;
			}
			nextItem.setSize(nextItemWidth, nextItemHeight);
			this.clearFlex(items[index + 1]);
		}
		this.layout();
		this.saveSizeToProfile(items, sb.orientation == Ext.SplitBar.VERTICAL);
	},

	saveSizeToProfile: function(items, isVertical) {
		if (isVertical) {
			var allPercentHeight = 0;
			Ext.each(items, function(item) {
				var isFlex = item.isFlex ||
					(item.initialConfig.height && item.initialConfig.height.toString().indexOf('%') != -1);
				if (item.isFlex == undefined) {
					item.isFlex = isFlex;
				}
				if (isFlex) {
					allPercentHeight = allPercentHeight + item.getHeight();
				}
			});
			Ext.each(items, function(item) {
				var height;
				if (item.isFlex && allPercentHeight != 0) {
					height = Math.ceil(100.0 * item.getHeight() / allPercentHeight) + '%';
					item.setProfileData('height', height);
				} else {
					height = item.getHeight() + 'px';
					item.setProfileData('height', height);
				}
			});
		} else {
			var allPercentWidth = 0;
			Ext.each(items, function(item) {
				var isFlex = item.isFlex ||
					(item.initialConfig.width && item.initialConfig.width.toString().indexOf('%') != -1);
				if (item.isFlex == undefined) {
					item.isFlex = isFlex;
				}
				if (isFlex) {
					allPercentWidth = allPercentWidth + item.getWidth();
				}
			});
			Ext.each(items, function(item) {
				var width;
				if (item.isFlex && allPercentWidth != 0) {
					width = Math.ceil(100.0 * item.getWidth() / allPercentWidth) + '%';
					item.setProfileData('width', width);
				} else {
					width = item.getWidth() + 'px';
					item.setProfileData('width', width);
				}
			});
		}
	},

	parsePercent: function(size) {
		return Ext.LayoutControl.prototype.parsePercent.call(this, size);
	},

	clearFlex: function(item) {
		delete item.flexWidth;
		delete item.flexHeight;
		delete item[this.direction == 'horizontal' ? 'width' : 'height'];
	}
});

Ext.Container.LAYOUTS.box = Ext.layout.BoxLayout;

Ext.layout.VBoxLayout = Ext.extend(Ext.layout.BoxLayout, {
	align: 'left',
	direction: 'vertical'
});

Ext.Container.LAYOUTS.vbox = Ext.layout.VBoxLayout;

Ext.layout.HBoxLayout = Ext.extend(Ext.layout.BoxLayout, {
	align: 'top',
	direction: 'horizontal'
});

Ext.Container.LAYOUTS.hbox = Ext.layout.HBoxLayout;
