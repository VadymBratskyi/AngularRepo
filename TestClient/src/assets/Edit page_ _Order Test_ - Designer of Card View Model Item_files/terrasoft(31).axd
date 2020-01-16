Terrasoft.ImageBox = Ext.extend(Ext.LayoutControl, {
	cls: '',
	stretch: false,

	setStretch: function(stretch) {
		this.stretch = stretch;
		this.updateImage();
	},

	setCenter: function(center) {
		this.center = center;
		this.updateImage();
	},

	onRender: function(ct, position) {
		if (!this.el) {
			this.el = ct.createChild({ 
				tag : 'img',
				cls : 'x-imagebox',
				id  : this.id || this.getId()
			});
			if (this.altText) {
				this.el.dom.setAttribute("alt", this.altText);
			}
			if (this.align && this.align !== "notset") {
				this.el.dom.setAttribute("align", this.align);
			}
			if (!Ext.isEmpty(this.cls)) {
				this.el.addClass(this.cls);
			}
			this.updateImage();
			this.setEdges(this.edges);
		}
		Terrasoft.ImageBox.superclass.onRender.call(this, ct, position);
	},

	setImage: function(value) {
		this.imageConfig = value;
		this.updateImage();
	},

	updateImage: function() {
		if (!this.rendered) {
			return;
		}
		if (!this.initialConfig.cls) {
			if (this.initialConfig.width)
				this.width = this.initialConfig.width;
			else this.width = 300;
		}
		if (!this.initialConfig.cls) {
			if (this.initialConfig.height)
				this.height = this.initialConfig.height;
			else this.height = 100;
		}
		var useBg = !this.stretch;
		var el = this.el;
		if (!useBg) {
			this.imageConfig.notWrap = true;
		}
		var imageSrc = this.getImageSrc();
		if (!useBg) {
			el.dom.setAttribute('src', imageSrc);
			el.setStyle('background-image', '');
		} else {
			el.dom.setAttribute('src', Ext.BLANK_IMAGE_URL);
			el.setStyle('background-image', imageSrc != Ext.BLANK_IMAGE_URL ? imageSrc : '');
			el.setStyle('background-position', this.center ? 'center center' : '');
		}
	},

	setImageUrl: function(imageUrl) {
		this.imageUrl = imageUrl;
		this.updateImage();
	},

	setEdges: function(edgesValue) {
		if (edgesValue && (edgesValue.indexOf("1") != -1)) {
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

	setAlign: function(align) {
		this.align = align;
		if (this.rendered) {
			this.el.dom.setAttribute("align", this.align);
		}
	},

	setAltText: function(altText) {
		this.altText = altText;
		if (this.rendered) {
			this.el.dom.setAttribute("alt", this.altText);
		}
	}
});

Ext.reg("imagebox", Terrasoft.ImageBox);
