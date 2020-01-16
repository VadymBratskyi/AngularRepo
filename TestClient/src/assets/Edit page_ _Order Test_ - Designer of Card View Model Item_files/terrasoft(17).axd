Ext.layout.FitLayout = Ext.extend(Ext.layout.ContainerLayout, {
	monitorResize: true,

	onLayout: function(ct, target) {
		if (!this.container.collapsed) {
			Ext.layout.FitLayout.superclass.onLayout.call(this, ct, target);
			this.setItemSize(this.activeItem || ct.items.itemAt(0), target.getStyleSize());
		}
	},

	setItemSize: function(item, size) {
		if (item && size.height > 0) {
			item.setSize(size);
		}
	}
});

Ext.Container.LAYOUTS['fit'] = Ext.layout.FitLayout;

// TODO Вынести CardLayout в отдельный JS

Ext.layout.CardLayout = Ext.extend(Ext.layout.FitLayout, {
	deferredRender: false,
	renderHidden: true,

	getItems: function(ct) {
		var items = [];
		items.push(this.activeItem);
		return items;
	},

	setActiveItem: function(item, isDeepLayout) {
		item = this.container.getComponent(item);
		if (this.activeItem != item) {
			if (this.activeItem) {
				this.activeItem.hide();
			}
			this.activeItem = item;
			item.show();
			if (isDeepLayout !== false) {
				isDeepLayout = (this.activeItem.rendered === false) ? true : false;
			}
			this.layout();
			if (isDeepLayout) {
				item.doLayout(isDeepLayout);
			}
		}
	},

	renderAll: function(ct, target) {
		if (this.deferredRender) {
			this.renderItem(this.activeItem, undefined, target);
		} else {
			Ext.layout.CardLayout.superclass.renderAll.call(this, ct, target);
		}
	}
});

Ext.Container.LAYOUTS['card'] = Ext.layout.CardLayout;

// TODO Вынести Accordion в отдельный JS

Ext.layout.Accordion = Ext.extend(Ext.layout.FitLayout, {
	fill: true,
	autoWidth: true,
	titleCollapse: true,
	hideCollapseTool: false,
	collapseFirst: false,
	animate: false,
	sequence: false,
	activeOnTop: false,

	renderItem: function(c) {
		if (this.animate === false) {
			c.animCollapse = false;
		}
		c.collapsible = true;
		if (this.autoWidth) {
			c.autoWidth = true;
		}
		if (this.titleCollapse) {
			c.titleCollapse = true;
		}
		if (this.hideCollapseTool) {
			c.hideCollapseTool = true;
		}
		if (this.collapseFirst !== undefined) {
			c.collapseFirst = this.collapseFirst;
		}
		if (!this.activeItem && !c.collapsed) {
			this.activeItem = c;
		} else if (this.activeItem) {
			c.collapsed = true;
		}
		Ext.layout.Accordion.superclass.renderItem.apply(this, arguments);
		c.header.addClass('x-accordion-hd');
		c.on('beforeexpand', this.beforeExpand, this);
	},

	beforeExpand: function(p, anim) {
		var ai = this.activeItem;
		if (ai) {
			if (this.sequence) {
				delete this.activeItem;
				if (!ai.collapsed) {
					ai.collapse({ callback: function() {
						p.expand(anim || true);
					}, scope: this
					});
					return false;
				}
			} else {
				ai.collapse(this.animate);
			}
		}
		this.activeItem = p;
		if (this.activeOnTop) {
			p.el.dom.parentNode.insertBefore(p.el.dom, p.el.dom.parentNode.firstChild);
		}
		this.layout();
	},

	setItemSize: function(item, size) {
		if (this.fill && item) {
			var items = this.container.items.items;
			var hh = 0;
			for (var i = 0, len = items.length; i < len; i++) {
				var p = items[i];
				if (p != item) {
					hh += (p.getSize().height - p.bwrap.getHeight());
				}
			}
			size.height -= hh;
			item.setSize(size);
		}
	}
});

Ext.Container.LAYOUTS['accordion'] = Ext.layout.Accordion;