Terrasoft.MessagePanel = Ext.extend(Ext.LayoutControl, {
	width: 400,
	closable: true,
	baseCls: 'x-message-panel',
	defaultMessageType: 'information',
	contentLeftOffset: 0,

	initComponent: function () {
		Terrasoft.MessagePanel.superclass.initComponent.call(this);
		this.addEvents(
			'bodyresize',
			'linkclick',
			'messageclosed'
		);
		this.messages = [];
		this.lazyMessages = [];
	},

	getResizeEl: function () {
		return this.el;
	},

	getPositionEl: function () {
		return this.el;
	},

	getActionEl: function () {
		return this.el;
	},

	onRender: function (ct, position) {
		Terrasoft.MessagePanel.superclass.onRender.call(this, ct, position);
		var el = this.el = ct.createChild({
			id: this.id,
			cls: this.baseCls
		}, position);
		el.on("click", Ext.Link.onClick, this);
		if (this.cls) {
			el.addClass(this.cls);
		}
		if (this.lazyMessages.length > 0) {
			this.messages = this.lazyMessages;
			delete this.lazyMessages;
		}
		this.setEdges(this.edges);
	},

	setEdges: function (edgesValue) {
		if (edgesValue) {
			var resizeEl = this.getResizeEl();
			if (!resizeEl) {
				return;
			}
			resizeEl.addClass("x-container-border");
			var edges = edgesValue.split(" ");
			var style = resizeEl.dom.style;
			style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
			style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
			style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
			style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
		}
	},

	afterRender: function () {
		if (this.html) {
			this.message.update(typeof this.html == 'object' ?
				Ext.DomHelper.markup(this.html) : this.html);
			delete this.html;
		}
		Terrasoft.MessagePanel.superclass.afterRender.call(this);
		if (Ext.isIE7 && !Ext.isEmpty(this.renderTo)) {
			Ext.get(this.renderTo).setStyle('zoom', '1');
		}
		if (this.designMode && this.messages.length == 0) {
			this.messages.push({
				title: Ext.StringList('WC.Common').getValue('MessagePanel.DesignModeMessage'),
				text: ''
			});
		}
		if (this.messages.length == 0 && !this.designMode && this.rendered) {
			if (!this.hidden) {
				this.hide();
			}
		}
		this.initEvents();
		this.refresh();
	},
	
	onLinkClick: function (e, linkId) {
		var cmp = Ext.getCmp(linkId);
		if (cmp && cmp.forceFocus) {
			cmp.forceFocus();
		}
	},

	refresh: function () {
		if (!this.rendered) {
			return;
		}
		var ms = this.el.select('.x-message-panel-item');
		ms.each(function (m, a, i) {
			m.remove();
		});
		Ext.each(this.messages, function (m, a, i) {
			this.createMessageItem(m);
		}, this);
	},

	setClosable: function (closable) {
		this.closable = closable;
		if (!this.rendered) {
			return;
		}
		this.refresh();
	},

	closeMessage: function (item) {
		this.remove(item.id);
		item.remove();
		this.fireEvent('messageclosed', this, item);
		var existingItemEl = this.el.child('.x-message-panel-item');
		if (!existingItemEl) {
			if (!this.hidden) {
				this.hide();
			}
		}
		if (this.ownerCt) {
			this.ownerCt.fireEvent('contentchanged', this);
		}
	},

	createMessageItem: function (m) {
		var el = this.el;
		if (!el) return;
		var item = this.el.createChild({
			cls: 'x-message-panel-item',
			id: m.id || ''
		});
		item.message = m;
		if (m.closable) {
			var closeEl = item.closeEl = item.createChild({
				id: Ext.id(),
				cls: 'x-message-panel-ico-close'
			});
			if (!this.designMode) {
				closeEl.on('click', function () {
					this.closeMessage(item);
				}, this);
			}
		}
		if (this.linksCfg) {
			m.title = Ext.Link.applyLinks(m.title, this.linksCfg);
			m.text = Ext.Link.applyLinks(m.text, this.linksCfg);
		}
		var innerContainerConfig = {
			cls: 'x-message-panel-item-inner'
		};
		if (m.showIcon == false) {
			innerContainerConfig.cn = [{ cls: 'x-message-panel-message-no-icon',
				html: m.title + m.text
			}];
		} else {
			innerContainerConfig.cn = [{ cls: 'x-message-panel-icon' },
				{ cls: 'x-message-panel-message',
					html: m.title + m.text
				}];
		}
		item.innerContainer = item.createChild(innerContainerConfig);
		if (Ext.isIE) {
			item.addClass.defer(1, item, [m.messageType]);
		} else {
			item.addClass(m.messageType);
		}
		if(!m.isFirst) {
			item.addClass("x-message-panel-separator");
		}
		if (this.contentLeftOffset) {
			item.innerContainer.setStyle('margin-left', item.innerContainer.addUnits(this.contentLeftOffset));
		}
		if (this.hidden) {
			this.show();
		} else if (this.ownerCt) {
			this.ownerCt.fireEvent('contentchanged', this);
		}
	},

	addMessage: function (id, title, text, messageType, closable, showIcon) {
		var m = {
			title: (!Ext.isEmpty(title)) ? ('<b>' + title + '</b><br />') : '',
			text: text || '',
			closable: closable !== false,
			showIcon: showIcon,
			messageType: (!Ext.isEmpty(messageType)) ? this.baseCls + '-' + messageType.toLowerCase() : this.defaultMessageType,
			isFirst : (this.messages.length == 0) ? true:false
		};
		if (!Ext.isEmpty(id)) {
			m.id = id;
		}
		if (!this.el) {
			this.lazyMessages.push(m);
			return;
		};
		this.messages.push(m);
		this.createMessageItem(m);
	},

	clear: function () {
		this.messages = [];
		if (this.messages.length == 0) {
			if (!this.hidden) {
				this.hide();
			}
		}
		this.refresh();
	},

	remove: function (id) {
		for (var i = 0; i < this.messages.length; i++) {
			if (this.messages[i].id == id) {
				this.messages.splice(i, 1);
				break;
			}
		}
		var mi = Ext.get(id);
		if (!Ext.isEmpty(mi)) {
			mi.remove();
		}
		if (this.messages.length == 0) {
			if (!this.hidden) {
				this.hide();
			}
		} else if (this.ownerCt) {
			this.ownerCt.fireEvent('contentchanged', this);
		}
	},

	initEvents: function () {
		if (this.keys) {
			this.getKeyMap();
		}
		this.on('linkclick', this.onLinkClick, this);
	},

	getResizeEl: function () {
		return this.el;
	},

	getPositionEl: function () {
		return this.el;
	},

	setSize: function (w, h) {
		var el = this.el;
		w = this.processSizeUnit(w);
		h = this.processSizeUnit(h);
		Terrasoft.MessagePanel.superclass.setSize.call(this, w, h);
		if (w != undefined && this.rendered) {
			var wrapFrameWidth = el.getFrameWidth('lr');
			var elWidth = w - wrapFrameWidth;
			elWidth = elWidth < 0 ? 0 : elWidth;
			el.setWidth(elWidth);
		}
		if (h != undefined && this.rendered) {
			var wrapFrameWidth = el.getFrameWidth('tb');
			var elHeight = h - wrapFrameWidth;
			elHeight = elHeight < 0 ? 0 : elHeight;
			el.setHeight(elHeight);
		}
	},

	onResize: function (w, h) {
		Terrasoft.MessagePanel.superclass.onResize.call(this, w, h);
		this.fireEvent('bodyresize', this, w, h);
	}

});

Ext.reg('messagepanel', Terrasoft.MessagePanel);