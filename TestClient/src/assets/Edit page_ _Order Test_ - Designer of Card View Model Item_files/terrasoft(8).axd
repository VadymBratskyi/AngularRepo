Terrasoft.Label = Ext.extend(Ext.LayoutControl, {
	autoWidth: false,
	bold: false,
	supportsCaption: false,
	supportsCaptionNumber: true,
	caption: this.designMode ? 'label' : '',
	cls: 'x-label',
	autoEl: 'div',
	allowDomMove: true,
	displayStyle: 'label',

	initComponent: function() {
		Terrasoft.Label.superclass.initComponent.call(this);
		this.addEvents('linkclick', 'linkFocused');
	},

	getLinkCaption: function() {
		var caption = this.caption || '';
		var links = this.linksCfg;
		if (links == undefined) {
			return caption;
		}
		for (var i = 0; i < links.length; i++) {
			var link = links[i];
			var re = new RegExp('\\{' + link.linkId + '\\}', 'ig');
			caption = caption.replace(re, link.caption);
		}
		return caption;
	},

	setDisplayStyle: function (displayStyle) {
		if (!this.designMode) {
			return;
		}
		displayStyle = this.displayStyle = displayStyle.toLowerCase();
		if (!this.rendered) {
			return;
		}
		var el = this.el;
		if (displayStyle == 'groupheader') {
			el.addClass('x-control-layout-header x-unselectable');
			this.captionEl.addClass('x-panel-header-text');
		} else if (displayStyle == 'label') {
			el.removeClass('x-control-layout-header x-unselectable');
			this.captionEl.removeClass('x-panel-header-text');
		}
		var ownerCt = this.ownerCt;
		if (ownerCt && ownerCt.onContentChanged) {
			ownerCt.onContentChanged();
		}
	},

	onRender: function(ct, position) {
		Terrasoft.Label.superclass.onRender.call(this, ct, position);
		if (!this.el) {
			return;
		}
		var el = this.el;
		var caption = this.getCaption();
		var captionEl = this.captionEl = el.createChild({
			tag: 'span'
		});
		if (this.displayStyle == 'groupheader') {
			el.addClass('x-control-layout-header x-unselectable');
			captionEl.addClass('x-panel-header-text');
		}
		captionEl.update(caption);
		var links = Ext.DomQuery.select('a', el.dom);
		for (var i = 0; i < links.length; i++) {
			var link = links[i];
			if (link.tagName == 'A') {
				Ext.fly(link).on("focus", Ext.Link.onFocus, this);
			}
		}
		el.setStyle('overflow', 'hidden');
		if (this.forId) {
			el.setAttribute("htmlFor", this.forId);
		}
		el.on("click", Ext.Link.onClick, this);
		if (this.bold) {
			el.setStyle("font-weight", "bold");
		}
		this.doAutoWidth();
	},

	getCaption: function () {
		var caption = this.caption || '';
		if (this.displayStyle != 'label') {
			return caption;
		}
		return this.linksCfg ? Ext.Link.applyLinks(caption, this.linksCfg) : caption;
	},

	setCaption: function(caption) {
		this.caption = caption = this.linksCfg ? Ext.Link.applyLinks(caption, this.linksCfg) : caption;
		var captionEl = this.captionEl;
		if (captionEl) {
			captionEl.update(caption);
		}
		this.doAutoWidth();
		return this;
	},
	
	setCaptionColor: function(color) {
		if (!this.el) {
			return;
		}
		if (this.numberLabelEl) {
			this.numberLabelEl.dom.style.color = color || '#000';
		}
		this.el.dom.style.color = color || '#000';
	},

	setSize: function(w, h) {
		Terrasoft.Label.superclass.setSize.call(this, w, h);
		this.doAutoWidth();
	},

	setWidth: function(width) {
		Terrasoft.Label.superclass.setWidth.call(this, width);
		this.doAutoWidth(width);
	},

	doAutoWidth: function() {
		if (!this.autoWidth) {
			return;
		}
		var el = this.el;
		if (!el) {
			return;
		}
		var caption = this.getCaption();
		var width = this.getRawTextWidth(caption);
		this.lastSize = undefined;
		this.width = width;
		this.getResizeEl().setWidth(width);
	},

	getRawTextWidth: function(text) {
		if (text == undefined) {
			return 0;
		}
		var el = Ext.getLabelRawTextWidthEl;
		if (!el) {
			el = Ext.get(document.createElement('div'));
			Ext.getLabelRawTextWidthEl = el;
			var styles = {
				fontFamily: 'tahoma',
				fontSize: '11px'
			};
			el.applyStyles(styles);
		}
		var newText = this.linksCfg ? Ext.Link.applyLinks(text, this.linksCfg) : text;
		el.dom.innerHTML = newText;
		return el.getTextWidth();
	}

});

Ext.reg('label', Terrasoft.Label);
