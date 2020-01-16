Ext.form.Checkbox = Ext.extend(Ext.form.Field, {
	supportsCaption: true,
	supportsCaptionNumber: true,
	captionVerticalAlign: 'middle',
	captionPosition: 'right',
	captionPositionSupports: { left: true, right: true },
	checkedCls: 'x-form-check-checked',
	focusCls: 'x-form-check-focus',
	overCls: 'x-form-check-over',
	mouseDownCls: 'x-form-check-down',
	tabIndex: 0,
	checked: false,
	defaultAutoCreate: { tag: 'input', type: 'checkbox', autocomplete: 'off' },
	baseCls: 'x-form-check',

	initComponent: function () {
		Ext.form.Checkbox.superclass.initComponent.call(this);
		this.addEvents(
			'check'
		);
		this.setCaptionPosition(this.captionPosition);
	},

	initEvents: function () {
		Ext.form.Checkbox.superclass.initEvents.call(this);
		this.initCheckEvents();
	},

	initCheckEvents: function () {
		this.wrap.removeAllListeners();
		this.wrap.addClassOnOver(this.overCls);
		this.wrap.addClassOnClick(this.mouseDownCls);
		this.wrap.on('click', this.onClick, this);
		this.wrap.on('keyup', this.onKeyUp, this);
		this.getFocusEl().on('focus', this.onFocus, this);
		this.wrap.on('blur', this.onBlur, this);
		this.wrap.on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.fireKey, this);
	},

	initDataChangeEvent: function () {
		this.on('check', this.onChange, this);
	},

	onRender: function (ct, position) {
		Ext.form.Checkbox.superclass.onRender.call(this, ct, position);
		if (this.inputValue !== undefined) {
			this.el.dom.value = this.inputValue;
		}
		this.el.addClass('x-hidden');
		this.addWrapper(ct);
		if (this.caption && this.captionPosition === 'right') {
			var labelElWrap = this.wrap.createChild({
				tag: 'label',
				htmlFor: this.el.id,
				cls: 'x-form-cb-label'
			});
			this.rightLabelEl = labelElWrap.createChild({
				tag: 'span',
				cls: 'x-form-cb-span',
				tabIndex: this.tabIndex,
				html: this.caption || ''
			});
		}
		var imageElCfg = {
			tag: 'img',
			src: Ext.BLANK_IMAGE_URL,
			cls: this.baseCls
		}
		if (this.caption && this.captionPosition === 'left') {
			//if (this.captionPosition === 'left') {
			imageElCfg.tabIndex = this.tabIndex;
		}
		if (this.caption == undefined || this.caption === '') {
			this.wrap.dom.tabIndex = 0;
		}
		this.imageEl = this.wrap.createChild(imageElCfg, this.el);
		if (this.checked) {
			this.setChecked(true);
		} else {
			this.checked = this.el.dom.checked;
		}
		this.originalValue = this.checked;
	},

	addWrapper: function (container) {
		var wrapCfg = {
			style: 'overflow:hidden',
			cls: this.baseCls + '-wrap'
		}
		this.wrap = this.el.wrap(wrapCfg);
		this.wrap.getHeight = this.getWrapHeight.createDelegate(this, []);
	},

	renderCaption: function () {
		if (this.captionPosition === 'right' && !this.rightLabelEl && !Ext.isEmpty(this.caption)) {
			var labelElWrap = this.wrap.createChild({
				tag: 'label',
				htmlFor: this.el.id,
				cls: 'x-form-cb-label'
			});
			this.rightLabelEl = labelElWrap.createChild({
				tag: 'span',
				cls: 'x-form-cb-span',
				tabIndex: this.tabIndex,
				html: this.caption || ''
			});
		} else {
			Ext.form.Checkbox.superclass.renderCaption.call(this);
		}
	},

	getWrapHeight: function () {
		var wrapHeight = (this.wrap.getWidth() > this.getWrapWidth()) ?
			Ext.Element.prototype.getHeight.call(this.wrap) : 0;
		var imageElHeight = this.imageEl.getHeight();
		var radioButtonImageHeight = (this.image) ? this.image.getHeight() : 0;
		return Math.max(wrapHeight, imageElHeight, radioButtonImageHeight);
	},

	getWrapWidth: function () {
		var imageElWidth = this.imageEl.getWidth();
		var radioButtonImageWidth = (this.image) ? this.image.getWidth() : 0;
		var rightLabelElWidth = (this.rightLabelEl) ? this.rightLabelEl.getWidth() : 0;
		return imageElWidth + radioButtonImageWidth + rightLabelElWidth;
	},

	onDestroy: function () {
		if (this.rendered) {
			Ext.destroy(this.imageEl, this.rightLabelEl, this.wrap);
		}
		Ext.form.Checkbox.superclass.onDestroy.call(this);
	},

	onFocus: function (e) {
		Ext.form.Checkbox.superclass.onFocus.call(this, e);
		this.el.addClass(this.focusCls);
	},

	getFocusEl: function () {
		if (this.imageEl.dom.tabIndex != -1) {
			return this.rightLabelEl || this.imageEl;
		}
		return this.wrap;
	},

	onCaptionClick: function () {
		this.focus();
		this.onClick();
	},

	startEditing: function () {
		this.focus();
	},

	endEditing: function () {
	},

	onBlur: function (e) {
		Ext.form.Checkbox.superclass.onBlur.call(this, e);
		this.el.removeClass(this.focusCls);
	},

	onResize: function () {
		Ext.form.Checkbox.superclass.onResize.apply(this, arguments);
		if (!this.rightLabelEl) {
			this.el.alignTo(this.wrap, 'c-c');
		}
	},

	onKeyUp: function (e) {
		if (e.getKey() == Ext.EventObject.SPACE) {
			this.onClick(e);
		}
	},

	onClick: function (e) {
		if (this.enabled) {
			this.toggleValue();
		}
		if (e) {
			e.stopEvent();
		}
	},

	onEnable: function () {
		Ext.form.Checkbox.superclass.onEnable.call(this);
		var disabledClass = this.disabledClass;
		var wrap = this.wrap;
		if (wrap.hasClass(disabledClass)) {
			wrap.removeClass(disabledClass);
		}
	},

	onDisable: function() {
		Ext.form.Checkbox.superclass.onDisable.call(this);
	},

	toggleValue: function () {
		this.setValue(!this.checked);
	},

	setSize: function (w, h) {
		h = undefined;
		Ext.form.Checkbox.superclass.setSize.call(this, w, h);
	},

	getResizeEl: function () {
		return this.captionWrap || this.wrap;
	},

	getPositionEl: function () {
		return this.captionWrap || this.wrap;
	},

	getActionEl: function () {
		return this.captionWrap || this.wrap;
	},

	markInvalid: Ext.emptyFn,

	clearInvalid: Ext.emptyFn,

	getValue: function () {
		if (this.rendered) {
			return this.el.dom.checked;
		}
		return false;
	},

	onChange: function (o, value, opt) {
		if (!this.dataSource) {
			return;
		}
		var columnValue = !Ext.isEmpty(value) ? value : false;
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, columnValue);
			}
		}
	},

	initValue: function () {
		try {
			this.valueInit = false;
			var column = this.getColumn();
			if (column) {
				var value = this.getColumnValue();
				value = (String(value).toLowerCase() == "true");
				this.setValue(value || "");
				return;
			}
			if (this.value !== undefined) {
				this.setValue(this.value);
			}
		} finally {
			this.valueInit = true;
		}
	},

	setChecked: function (checked) {
		this.checked = checked;
		if (this.el && this.el.dom) {
			this.el.dom.checked = this.checked;
			this.el.dom.defaultChecked = this.checked;
		}
		if (this.rendered) {
			if (Ext.isIE && this.setForceFocus) {
				this.onFocus();
			}
			this.wrap[this.checked ? 'addClass' : 'removeClass'](this.checkedCls);
		}
	},

	setValue: function (v, isInitByEvent) {
		var previousValue = this.checked;
		var value = (v === true || String(v).toLowerCase() === 'true'
			|| v == '1' || String(v).toLowerCase() == 'on');
		if ((value == previousValue) && (!this.rendered || previousValue == this.el.dom.checked)) {
			return;
		}
		this.setChecked(value);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.fireEvent('check', this, this.checked, opt);
		}
		if (this.handler) {
			this.handler.call(this.scope || this, this, this.checked);
		}
	},

	getLabelEl: function () {
		return (this.captionPosition === 'right') ? this.rightLabelEl : this.labelEl;
	},

	setCaptionPosition: function (position) {
		position = position.toLowerCase();
		var labelEl = this.getLabelEl();
		this.captionPosition = position;
		if (!this.rendered) {
			return;
		}
		if (this.designMode && this.caption !== undefined) {
			labelEl.dom.innerHTML = '';
			this.setCaption(this.caption);
		}
	},

	updateSizeAfterCaptionChange: function (width) {
		if (!this.captionWrap) {
			return;
		}
		if (this.ownerCt && this.ownerCt.direction === 'horizontal') {
			var controlWidth = this.wrap.getWidth();
			var controlElPaddingLeft = width + this.labelMargin;
			this.captionWrap.setStyle('padding-left', Ext.Element.addUnits(controlElPaddingLeft));
			this.captionWrap.setWidth(controlElPaddingLeft + controlWidth);
			if (this.captionPosition == 'left') {
				this.setCaptionVerticalAlign(this.captionVerticalAlign);
			}
		} else {
			Ext.form.Checkbox.superclass.updateSizeAfterCaptionChange.call(this, width);
		}
	},

	unFocus: function () {
		//TODO: разобраться с ошибкой вызова метода CR 94574
		this.hasFocus = false;
	}

});

Terrasoft.CheckBox = Ext.form.Checkbox;

Ext.reg('checkbox', Terrasoft.CheckBox);