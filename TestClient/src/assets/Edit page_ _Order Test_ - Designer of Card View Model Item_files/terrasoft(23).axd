Ext.form.Radio = Ext.extend(Ext.form.Checkbox, {
	inputType: 'radio',
	isContentLoaded: false,
	baseCls: 'x-form-radio',

	onRender: function(ct, position) {
		Ext.form.Radio.superclass.onRender.call(this, ct, position);
		this.setImage();
	},
	
	setImage: function(value) {
		if (value) {
			this.imageConfig = value;
		}
		if (this.imageConfig) {
			this.imageConfig.notWrap = Ext.isIE || Ext.isGecko ? true : false;
		}
		var imageSrc = this.getImageSrc();
		if (Ext.isEmpty(imageSrc) || imageSrc == Ext.BLANK_IMAGE_URL) {
			if (this.image) {
				this.image.un('load', this.onImageLoad, this);
				this.image.remove();
			}
			return;
		}
		if (!this.image) {
			this.image = this.wrap.createChild({
				tag: 'img',
				src: imageSrc,
				cls: 'x-radio-image'
			}, this.el);
		}
		this.image.dom.setAttribute('src', imageSrc);
		this.image.on('load', this.onImageLoad, this);
	},

	onImageLoad: function() {
		this.isContentLoaded = true;
		if (this.labelEl) {
			var containerCaptionWidth = this.ownerCt.getContainerCaptionWidth();
			if (containerCaptionWidth !== undefined && this.labelMargin == 0) {
				if (this.ownerCt.direction == 'vertical' || (this.ownerCt.direction == 'horizontal' &&
							this.ownerCt.items.indexOf(this) === 0)) {
					this.labelMargin = 5;
				}
			}
			var width = this.getCaptionAndNumberWidth();
			this.updateSizeAfterCaptionChange(width);
		}
		if (this.ownerCt) {
			this.ownerCt.fireEvent('contentchanged');
		}
		this.setCaptionVerticalAlign(this.captionVerticalAlign);
	},

	updateSizeAfterCaptionChange: function(width) {
		if (this.designMode !== true && !this.isContentLoaded) {
			return;
		}
		Ext.form.Radio.superclass.updateSizeAfterCaptionChange.call(this, width);
	},

	onDisable: function() {
		Ext.form.Radio.superclass.onDisable.call(this);
		if (this.image) {
			this.image.setOpacity(.1);
		}
	},
	
	onEnable: function() {
		Ext.form.Radio.superclass.onEnable.call(this);
		if (this.image) {
			this.image.setOpacity(1);
		}
	},
	
	onDestroy: function() {
		if (this.image) {
			this.image.un('load', this.onImageLoad, this);
			this.image.remove();
		}
		Ext.form.Radio.superclass.onDestroy.call(this);
	},
	
	getGroupValue: function() {
		var c = this.getParent().child('input[name=' + this.el.dom.name + ']:checked', true);
		return c ? c.value : null;
	},

	getParent: function() {
		return this.el.up('form') || Ext.getBody();
	},

	initDataSource: Ext.emptyFn,

	toggleValue: function() {
		if (!this.checked) {
			var els = this.getParent().select('input[name=' + this.el.dom.name + ']');
			els.each(function(el) {
				if (el.dom.id == this.id) {
					this.setValue(true);
				} else {
					Ext.getCmp(el.dom.id).setValue(false);
				}
			}, this);
		}
	},

	setValue: function(v) {
		if (typeof v == 'boolean') {
			Ext.form.Radio.superclass.setValue.call(this, v);
		} else {
			var r = this.getParent().child('input[name=' + this.el.dom.name + '][value=' + v + ']', true);
			if (r && !r.checked) {
				Ext.getCmp(r.id).toggleValue();
			};
		}
	},

	markInvalid: Ext.emptyFn,

	clearInvalid: Ext.emptyFn

});

Ext.reg('radio', Ext.form.Radio);

Terrasoft.Radio = Ext.form.Radio;

Ext.reg('radio', Terrasoft.Radio);