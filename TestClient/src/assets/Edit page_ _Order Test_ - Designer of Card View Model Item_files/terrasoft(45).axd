Terrasoft.ColorEdit = Ext.extend(Terrasoft.BaseEdit, {
	invalidText: "Not valid color - it must be in a the hex format '#1A2B3C'",
	toolButtonClass: 'x-form-color-toolbutton',
	defaultAutoCreate: { tag: "input", type: "text", size: "10", maxlength: "7", autocomplete: "off" },
	maskRe: /[#a-f0-9]/i,
	regex: /^#([a-f0-9]{3}|[a-f0-9]{6})$/i,
	displayMode: 'Color',
	value: '#FFFFFF',

	initComponent: function() {
		Terrasoft.ColorEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = { 
			id: this.primaryToolButtonId(),
			imageCls: 'coloredit-ico-btn-select'
		};
	},
	
	onRender: function(ct, position) {
		Terrasoft.ColorEdit.superclass.onRender.call(this, ct, position);
		this.hiddenField = this.el.insertSibling({ tag: 'input', type: 'hidden', name: this.id + '_Value',
			id: this.id + '_Value'
		}, 'before', true);
		this.el.dom.readOnly = !this.enabled || (this.displayMode == 'Color');
	},

	getDomValue: function() {
		return this.el.dom.value;
	},

	setDomValue: function(value) {
		this.el.dom.value = value;
	},

	setDisplayMode: function(mode) {
		this.displayMode = mode;
		if (mode == 'HexValue') {
			this.setColor();
		} else {
			if (mode == 'Color') {
				this.setDomValue('');
			} else {
				this.setDomValue(this.getValue());
			}
			this.setColor(this.getValue());
		}
	},

	onEnable: function() {
		if (this.displayMode == 'Color') {
			return;
		}
		Terrasoft.ColorEdit.superclass.onEnable.call(this);
	},

	validateValue: function(value) {
		if (this.displayMode == 'Color') {
			return true;
		}
		if (!Terrasoft.ColorEdit.superclass.validateValue.call(this, value)) {
			return false;
		}
		if (value.length < 1) {
			this.setColor('');
			return true;
		}
		var parseOK = this.isColor(value);
		if (!value || (parseOK == false)) {
			return false;
		}
		var color = this.parseColor(this.getText());
		return true;
	},

	validateBlur: function() {
		return !this.menu || !this.menu.isVisible();
	},

	checkChange: function() {
		if (!this.el) {
			return;
		}
		if (this.displayMode == 'Color') {
			return;
		}
		var v = this.getDomValue().toUpperCase();
		if (String(v) !== String(this.startValue) && v.length >= 6) {
			this.fireEvent('change', this, v, this.startValue);
		}
	},

	getValue: function() {
		if (!this.el) {
			return this.value || '';
		}
		return (this.hiddenField) ? this.hiddenField.value || '' : '';
	},

	getText: function() {
		if (!this.el) {
			return '';
		}
		return this.getDomValue();
	},

	setValue: function(value, isInitByEvent) {
		if (value == '') {
			return;
		}
		this.value = value;
		if (!this.rendered) {
			return;
		}
		var oldValue = this.getValue();
		if (value == oldValue) {
			return;
		}
		if (this.displayMode != 'Color') {
			this.setDomValue(this.formatColor(value));
		}
		this.setColor(this.displayMode == 'HexValue' ? '' : value);
		if (this.hiddenField) {
			this.hiddenField.value = value || '';
		}
		this.validate(true);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.startValue = value;
			this.fireEvent('change', this, value, oldValue, opt);
		}
	},

	isColor: function(value) {
		return (!value || (value.substring(0, 1) != '#')) ?
			false : (value.length == 4 || value.length == 7);
	},

	parseColor: function(value) {
		if (!value || (value.substring(0, 1) != '#')) {
			return '';
		}
		var color = value.substring(1, value.length);
		if (color.length != 6) {
			return '';
		}
		return color;
	},

	setColor: function(color) {
		if (!this.enabled) {
			return;
		}
		if (Ext.isEmpty(color)) {
			color = '#FFF';
		}
		if (this.displayMode != 'HexValue' || this.designMode) {
			this.el.setStyle({ 'background-color': this.formatColor(color) || '#FFF' });
		}
	},

	formatColor: function(value) {
		if (!value || this.isColor(value)) {
			return value || '';
		}
		if (value.length == 3 || value.length == 6) {
			return '#' + value;
		}
		return '';
	},

	menuListeners: {
		select: function(e, c) {
			this.setValue(c, false);
			this.fireEvent('change', this, c, this.getValue(), {isInitByEvent: false});
		},
		show: function() {
			this.onFocus();
		},
		hide: function() {
			this.focus.defer(10, this);
			var ml = this.menuListeners;
			this.menu.un("select", ml.select, this);
			this.menu.un("show", ml.show, this);
			this.menu.un("hide", ml.hide, this);
		}
	},

	onPrimaryToolButtonClick: function() {
		if (!this.enabled) {
			return;
		}
		if (this.menu == null) {
			this.menu = new Ext.menu.ColorMenu(this.config);
		}
		this.menu.on(Ext.apply({}, this.menuListeners, {
			scope: this
		}));
		this.menu.show(this.el, "tl-bl?", this.menu.parentMenu);
	}

});

Ext.reg('coloredit', Terrasoft.ColorEdit);