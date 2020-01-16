Terrasoft.HtmlPageContainer = Ext.extend(Ext.LayoutControl, {
	sourceUrl: '',
	width: 400,
	height: 50,

	initComponent: function () {
		Terrasoft.HtmlPageContainer.superclass.initComponent.call(this);
		this.loadMaskLoadingMessage = Ext.StringList('WC.Common').getValue('LoadMask.Loading');
	},

	setSourceUrl: function (sourceUrl) {
		this.sourceUrl = sourceUrl;
		if (!this.rendered || this.designMode) {
			return;
		}
		this.body.mask(this.loadMaskLoadingMessage, 'x-mask-loading blue', true, false, true, null, true);
		this.iframe.dom.setAttribute("src", sourceUrl);
	},

	onRender: function (ct, position) {
		Terrasoft.HtmlPageContainer.superclass.onRender.call(this, ct, position);
		if (!this.el) {
			var el = this.el = ct.createChild({
				tag: 'div',
				cls: 'x-htmlpagecontainer',
				id: this.id || this.getId()
			});
			if (!Ext.isEmpty(this.cls)) {
				el.addClass(this.cls);
			}
			this.body = Ext.getBody();
			var src = this.sourceUrl;
			if (!this.designMode) {
				el.dom.innerHTML = "<iframe src='" + src + "' frameborder='no' security='unrestricted'></iframe>";
				var iframe = this.iframe = el.child('iframe');
				if (iframe) {
					iframe.addListener('load', this.onFrameLoad, this);
					iframe.setWidth(this.getWidth() - el.getFrameWidth('lr'));
					iframe.setHeight(this.getHeight() - el.getFrameWidth('tb'));
				}
			}
			this.setEdges(this.edges);
		}
	},

	onFrameLoad: function () {
		this.body.unmask();
	},

	getEditorBody: function () {
		var doc = this.getDoc();
		return doc.body || doc.documentElement;
	},

	getWin: function () {
		return this.iframe.dom.contentWindow;
	},

	getDoc: function () {
		return Ext.isIE ? this.getWin().document : (this.iframe.dom.contentDocument || this.getWin().document);
	},

	setSize: function (w, h) {
		w = this.processSizeUnit(w);
		h = this.processSizeUnit(h);
		Terrasoft.HtmlPageContainer.superclass.setSize.call(this, w, h);
		if (!this.rendered) {
			return;
		}
		var el = this.el;
		if (w != undefined) {
			el.setWidth(w);
			if (!this.designMode) {
				this.iframe.setWidth(this.getWidth() - el.getFrameWidth('lr'));
			}
		}
		if (h != undefined) {
			el.setHeight(h);
			if (!this.designMode) {
				this.iframe.setHeight(this.getHeight() - el.getFrameWidth('tb'));
			}
		}
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
	}
});

Ext.reg("htmlpagecontainer", Terrasoft.HtmlPageContainer);