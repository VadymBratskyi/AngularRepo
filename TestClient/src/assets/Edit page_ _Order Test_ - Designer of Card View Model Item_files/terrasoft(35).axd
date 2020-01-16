Terrasoft.UnitMeasureEdit = Ext.extend(Terrasoft.ComboBox, {
	validator: null,
	strictedToItemsList: true,
	typeAhead: false,
	width: 'auto',
	value: 'px',

	initComponent: function() {
		Terrasoft.UnitMeasureEdit.superclass.initComponent.call(this);
		var measures = [];
		measures.push(['px']);
		measures.push(['%']);
		this.store = new Ext.data.SimpleStore({
			fields: ['text'],
			data: measures
		});
		this.displayField = 'text';
		this.checkDataProperties();
	},

	getValue: function() {
		if (!this.el) {
			return '';
		}
		return Ext.value(this.el.dom.value, '');
	},

	setValue: function(value, isInitByEvent) {
		if (isInitByEvent) {
			this.startValue = value;
		}
		this.value = value;
		if (this.el) {
			this.el.dom.value = value || '';
		}
		this.validate(true);
	},

	fireChangeEvent: Ext.emptyFn,

	checkChange: function() {
		var v = this.getRawValue();
		if (String(v) !== this.startValue) {
			this.fireEvent('change', this, v, this.startValue);
		}
	},

	validateValue: function(value) {
		if (this.findRecordByText('text',value)) {
			return true;
		}
		this.markInvalid();
		return false;
	},

	onBlur: Ext.emptyFn
});

Terrasoft.UnitEdit = Ext.extend(Terrasoft.CompositeLayoutControl, {
	supportsCaption: true,
	supportsCaptionNumber: true,
	isFormField: true,
	width: 200,
	measureControlWidth: 45,
	controlsSpacingWidth: 4,
	enableKeyEvents: false,
	valueInit: true,
	allowEmpty: false,
	valueFocused: false,
	measureFocused: false,

	initComponent: function() {
		Terrasoft.UnitEdit.superclass.initComponent.call(this);
	},

	handleNameChanging: function(oldName, name) {
		Terrasoft.UnitEdit.superclass.handleNameChanging.call(this, oldName, name, true);
		this.valueEdit.primaryToolButton.handleNameChanging(this.valueEdit.primaryToolButton.id, this.valueEdit.id + '_PrimaryToolButton', true);
		this.measure.primaryToolButton.handleNameChanging(this.measure.primaryToolButton.id, this.measure.id + '_PrimaryToolButton', true);
		this.valueEdit.handleNameChanging(this.valueEdit.id, name + '_Value', true);
		this.measure.handleNameChanging(this.measure.id, name + '_Measure', true);
		this.fireEvent("nameChanged", this, oldName, name);
	},

	initItems: function() {
		this.items = new Array(2);
		var config = {
			id: this.id + '_Value',
			designMode: this.designMode,
			allowEmpty : this.allowEmpty,
			enableKeyEvents: this.enableKeyEvents,
			required: this.required,
			width: '100%'
		}
		this.valueEdit = new Terrasoft.IntegerEdit(config);
		config = {
			id: this.id + '_Measure',
			designMode: this.designMode,
			enableKeyEvents: this.enableKeyEvents,
			minListWidth: this.measureControlWidth,
			required: this.required,
			width: this.measureControlWidth
		}
		this.measure = new Terrasoft.UnitMeasureEdit(config);
		this.items[0] = this.valueEdit;
		this.items[1] = this.measure;
	},

	getValue: function() {
		var value = this.valueEdit.getValue();
		var measure = this.measure.getValue();
		return (value !== undefined && measure !== undefined) ? (value + measure) : '';
	},

	setValue: function(value, isInitByEvent) {
		var newValue = value;
		var oldValue = this.getValue();
		if (newValue == oldValue) {
			return;
		}
		if (Ext.isEmpty(newValue)) {
			this.valueEdit.setValue('', isInitByEvent);
			this.measure.setValue(this.measure.value, isInitByEvent);
		} else {
			var parts = Ext.Element.parseUnits(newValue);
			if (parts != null) {
				this.valueEdit.setValue(parts.value, isInitByEvent);
				this.measure.setValue(parts.measure, isInitByEvent);
			}
		}
		this.validate(true);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.fireEvent("change", this, oldValue, newValue, opt);
		}
	},

	validateBlur: function(e) {
		if(this.valueEdit.validateBlur(e)=== false) {
			return false;
		}
		var measureListEl = (this.measure && this.measure.list && this.measure.list.isVisible()) ?
			this.measure.list : null;
		if (measureListEl && measureListEl.contains(e.target)) {
			return false;
		}
		return true;
	}
});

Ext.reg('unitedit', Terrasoft.UnitEdit);