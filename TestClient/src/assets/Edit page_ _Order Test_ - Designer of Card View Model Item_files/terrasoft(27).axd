Terrasoft.NumberEdit = Ext.extend(Terrasoft.BaseEdit, {
	fieldClass: "x-form-field x-form-num-field",
	allowDecimals: true,
	decimalSeparator: ".",
	thousandSeparator: ' ',
	numericSize: 18,
	decimalPrecision: 2,
	allowNegative: true,
	minValue: Terrasoft.MIN_VALUE,
	maxValue: Terrasoft.MAX_VALUE,
	defaultMinValue: Terrasoft.MIN_VALUE,
	defaultMaxValue: Terrasoft.MAX_VALUE,
	baseChars: "0123456789",
	allowEmpty: false,
	useThousandSeparator: true,
	selectOnFocus: true,
	validationEvent: false,
	showThousandsSeparator: true,
	valueAlign: 'right',

	initComponent: function() {
		Terrasoft.NumberEdit.superclass.initComponent.call(this);
		var stringList = Ext.StringList('WC.NumberEdit');
		this.minText = stringList.getValue('NumberEdit.MinValueMessage');
		this.maxText = stringList.getValue('NumberEdit.MaxValueMessage');
		this.nanText = stringList.getValue('NumberEdit.NanValueMessage');
		this.numericSizeText = stringList.getValue('NumberEdit.NumericSizeMessage');
		this.decimalPrecisionText = stringList.getValue('NumberEdit.DecimalPrecisionMessage');
		this.primaryToolButtonConfig = {
			id: this.primaryToolButtonId(),
			imageCls: 'numberedit-ico-btn-calculator'
		};
		this.decimalSeparator = Terrasoft.CultureInfo.decimalSeparator;
		this.thousandSeparator = Terrasoft.CultureInfo.numberGroupSeparator;
		this.decimalPrecision = Terrasoft.CultureInfo.decimalPrecision;
		this.numericRe = new RegExp('[^' + this.baseChars + ']', 'gi');
		var allowed = this.baseChars;
		if (this.allowDecimals) {
			allowed += ',.';
		}
		if (this.allowNegative) {
			allowed += "-";
		}
		this.maskRe = new RegExp('[' + allowed + ']','i');
		this.stripCharsRe = new RegExp('[^' + allowed + ']', 'gi');
	},

	onPrimaryToolButtonClick: function() {
		if (!this.enabled || this.designMode) {
			return;
		}
		var el = this.el;
		Terrasoft.NumberEdit.superclass.onPrimaryToolButtonClick.call(this, null, el, {
			t: this.primaryToolButton
		});
		var calcMenu = this.calcMenu ? this.calcMenu : this.calcMenu = new Terrasoft.CalcMenu(this.config);
		var calculator = calcMenu.calculator;
		Ext.apply(calculator, {
			inputBox: this,
			roundToInt: (!this.allowDecimals)
		});
		calculator.reset();
		var currentValue = this.parseValue(el.dom.value || '');
		if (!isNaN(currentValue)) {
			calculator.number = currentValue;
			calculator.addToNum = 'yes';
		} 
		calcMenu.show(this.wrap, 'bl?', calcMenu.parentMenu, [0, -1]);
	},

	onKeyUp: function () {
		var value = this.el.dom.value;
		var numericValue = this.parseValue(value);
		if (this.validateValue(numericValue) === true) {
			this.clearInvalid();
		}
	},

	onKeyPress: function (e) {
		function processInputValue(startValue) {
			var domEl = this.el.dom;
			var value = domEl.value || '';
			if (value === startValue) {
				return;
			}
			var needUpdateValue = false;
			var stripValue = value.replace(this.stripCharsRe, '');
			if (isNaN(stripValue.replace(this.decimalSeparator, "."))) {
				domEl.value = startValue;
				return;
			}
			var numericValue = this.parseValue(value);
			if (this.validateValue(numericValue) === false) {
				value = startValue;
				needUpdateValue = true;
			}
			this.clearInvalid();
			var separatorToReplace = this.getSeparatorToReplace(value);
			if (separatorToReplace) {
				needUpdateValue = true;
				if (!this.allowDecimals) {
					value = startValue;
				} else {
					value = value.replace(separatorToReplace, this.decimalSeparator);
				}
			}
			if (needUpdateValue) {
				domEl.value = value;
			}
		}

		if (e.getKey() == e.ENTER) {
			this.setValue(this.el.dom.value);
		} else {
			processInputValue.defer(50, this, [this.el.dom.value]);
		}
	},

	onRender: function(ct, position) {
		Terrasoft.NumberEdit.superclass.onRender.call(this, ct, position);
		this.applyValueAlignCss();
		this.hiddenName = this.id + '_Value';
		if (this.hiddenName) {
			this.hiddenField = this.el.insertSibling({
				tag: 'input',
				type: 'hidden',
				name: this.hiddenName,
				id: (this.hiddenId || this.hiddenName)
			}, 'before', true);
			this.hiddenField.value = this.value ? this.value : '';
			this.el.dom.value = this.getDisplayValue();
		}
	},
	
	setValueAlign: function(align) {
		align = align.toLowerCase();
		this.valueAlign = align;
		if (this.rendered) {
			this.applyValueAlignCss();
		}
	},
	
	applyValueAlignCss: function() {
		if (this.valueAlign != 'left') {
			this.el.removeClass('value-align-left');
			this.el.addClass('value-align-right');
		} else {
			this.el.removeClass('value-align-right');
			this.el.addClass('value-align-left');
		}
	},
	
	getValidationResult: function() {
		return {
			type: this.validationType,
			message: this.getValidationMessage()
		};
	},

	validateValue: function(value) {
		this.validationType = 'required';
		if (!Terrasoft.NumberEdit.superclass.validateValue.call(this, value)) {
			return false;
		}
		this.validationType = 'custom';
		var stringValue = String(value).replace(this.decimalSeparator, '.');
		if (stringValue.length < 1) {
			return true;
		}
		if (isNaN(stringValue)) {
			this.markInvalid(this.getValidationMessage(this.nanText, this.id, stringValue));
			return false;
		}
		if (this.allowDecimals) {
			var numericSize = this.getNumericSize(stringValue);
			if (numericSize > this.numericSize) {
				this.markInvalid(this.getValidationMessage(this.numericSizeText, this.id, this.numericSize));
				return false;
			}
			/*
   TODO Доработать CR 96821
   var decimalSeparatorIndex = value.indexOf('.');
   if (decimalSeparatorIndex != -1) {
    if (value.slice(decimalSeparatorIndex + 1).length > this.decimalPrecision) {
     this.markInvalid(this.getValidationMessage(this.decimalPrecisionText, this.id, this.decimalPrecision));
     return false;
    }
   }*/
		}
		var minValue = this.minValue;
		var defaultMinValue = this.defaultMinValue;
		var validationValue;
		if (value < minValue || value < defaultMinValue) {
			validationValue = value < minValue ? minValue : defaultMinValue;
			this.markInvalid(this.getValidationMessage(this.minText, this.id, validationValue));
			return false;
		}
		var maxValue = this.maxValue;
		var defaultMaxValue = this.defaultMaxValue;
		if (value > maxValue || value > defaultMaxValue) {
			validationValue = value > maxValue ? maxValue : defaultMaxValue;
			this.markInvalid(this.getValidationMessage(this.maxText, this.id, validationValue));
			return false;
		}
		return true;
	},

	getValue: function() {
		var value;
		if (!this.rendered) {
			value = this.value;
		} else {
			value = this.hiddenField ? this.hiddenField.value : this.value;
		}
		if (value === this.emptyText || value === undefined) {
			value = '';
		}
		return this.fixPrecision(this.parseValue(value));
	},

	getRawValue: function() {
		return this.getValue() + '';
	},

	getDisplayValue: function() {
		var value = this.getValue();
		return this.getFormattedFieldValue(value);
	},

	getFormattedFieldValue: function(value) {
		if (this.allowDecimals && !Ext.isEmpty(value)) {
			value = value.toFixed(this.decimalPrecision);
		}
		if (typeof value === 'number') {
			value = String(value);
		}
		var formattedValue = this.decimalSeparator !== '.' ? value.replace(".", this.decimalSeparator) : value;
		if (!this.showThousandsSeparator) {
			return formattedValue;
		}
		return Terrasoft.Math.separateThousands(formattedValue, this.decimalSeparator, this.thousandSeparator || ' ');
	},

	checkChange: function () {
		var value = this.parseValue(this.getRawValue());
		var oldValue = this.fixPrecision(this.parseValue(this.startValue));
		var stringValue = this.getFormattedFieldValue(this.fixPrecision(value));
		var oldStringValue = this.getFormattedFieldValue(oldValue);
		if (stringValue !== oldStringValue) {
			value = (value === '' && !this.allowEmpty) ? 0 : value;
			if (this.validateValue(value) === false) {
				return;
			}
			this.fireEvent('change', this, stringValue, oldStringValue);
			this.startValue = value;
		}
	},

	getSeparatorToReplace: function(value) {
		var separatorToReplace = undefined;
		var comma =  ',';
		var dot = '.';
		var allowDecimals = this.allowDecimals;
		if (value.indexOf(comma) !== -1 && (this.decimalSeparator !== comma || !allowDecimals)) {
			separatorToReplace = comma;
		} else if (value.indexOf(dot) !== -1 && (this.decimalSeparator !== dot || !allowDecimals)) {
			separatorToReplace = dot;
		}
		return separatorToReplace;
	},

	preFocus: function() {
		var value = this.getValue();
		var el = this.el;
		el.on("keypress", this.onKeyPress, this);
		el.on("keyup", this.onKeyUp, this);
		if (this.validateValue(value) === false) {
			return;
		}
		var stringValue = this.parseValue(value);
		stringValue = String(stringValue).replace(this.decimalSeparator, '.');
		var domEl = el.dom;
		domEl.value = stringValue;
		if (!this.allowEmpty) {
			if(this.allowDecimals) {
				var separatorToReplace = this.getSeparatorToReplace(stringValue);
				if (separatorToReplace) {
					stringValue = stringValue.replace(separatorToReplace, this.decimalSeparator);
				}
				domEl.value = stringValue;
			}
			if (parseFloat(value) === 0) {
				Terrasoft.NumberEdit.superclass.preFocus.call(this);
			}
		}
	},

	setValue: function(value, isInitByEvent, forceChangeEvent) {
		value = typeof value == 'number' ? value : this.parseValue(value);
		var formattedValue = this.getFormattedFieldValue(value);
		var oldValue = this.getValue();
		value = (value === '' && !this.allowEmpty) ? 0 : value;
		this.value = value;
		var el = this.el;
		if (!el) {
			return;
		}
		this.hiddenField.value = value;
		el.dom.value = formattedValue;
		if ((value != oldValue && forceChangeEvent !== false) || forceChangeEvent === true) {
			this.fireChangeEvent(value, oldValue, isInitByEvent);
		}
	},

	setRawValue: function (v) {
		this.setValue(v);
	},

	parseValue: function(value) {
		var thousandSeparatorRe = new RegExp('[' + this.thousandSeparator + ']', 'gi');
		var stripValue = String(value).replace(this.stripCharsRe, '').replace(thousandSeparatorRe, '');
		var numericValue = parseFloat(stripValue.replace(this.decimalSeparator, "."));
		return isNaN(numericValue) ? '' : numericValue;
	},

	fixPrecision: function(value) {
		value = String(value).replace(this.decimalSeparator, '.');
		if (isNaN(value) || Ext.isEmpty(value, false)) {
			if (this.allowEmpty) {
				return '';
			}
			value = '0';
		}
		var decimalPrecision = this.decimalPrecision;
		if (!this.allowDecimals) {
			return parseFloat(parseFloat(value).toFixed(0));
		}
		if (decimalPrecision == -1) {
			return parseFloat(value);
		}
		return parseFloat(parseFloat(value).toFixed(decimalPrecision));
	},

	getNumericSize: function(value) {
		var stripValue = value.replace(this.numericRe, '');
		return stripValue.length;
	},

	validateBlur: function(e) {
		var calcMenu = this.calcMenu;
		if (!calcMenu || !calcMenu.calculator) {
			return true;
		} 
		return !calcMenu.calculator.el.contains(e.target);
	},

	beforeBlur: function() {
		var el = this.el;
		el.un("keypress", this.onKeyPress, this);
		el.un("keyup", this.onKeyUp, this);
		var value = this.parseValue(el.dom.value);
		if (value < this.minValue || value < this.defaultMinValue || value > this.maxValue ||
			value > this.defaultMaxValue) {
			return;
		}
		value = (value === '' && !this.allowEmpty) ? 0 : value;
		if (value !== '' && this.allowDecimals) {
			value = this.fixPrecision(value);
			value = this.getFormattedFieldValue(value);
		}
		this.setRawValue(value);
	},

	setDecimalPrecision : function(precision) {
		this.decimalPrecision = precision;
		this.setValue(this.getValue(), true);
	},

	setUseThousandSeparator : function(useThousandSeparator) {
		this.useThousandSeparator = useThousandSeparator;
	},

	setPropertiesByColumn: function (column) {
		if (!column) {
			return;
		}
		Terrasoft.NumberEdit.superclass.setPropertiesByColumn.call(this, column);
		var dataValueType = column.dataValueType;
		if (this.isDefaultPropertyValue('minValue') && dataValueType.minValue !== undefined) {
			this.minValue = dataValueType.minValue;
		}
		if (this.isDefaultPropertyValue('maxValue') && dataValueType.maxValue !== undefined) {
			this.maxValue = dataValueType.maxValue;
		}
		if (this.isDefaultPropertyValue('numericSize') && dataValueType.numericSize !== undefined) {
			this.numericSize = dataValueType.numericSize;
		}
		if (this.allowDecimals) {
			var decimalPrecision = (this.isDefaultPropertyValue('precision')
				&& dataValueType.precision !== undefined) ? dataValueType.precision : this.decimalPrecision;
			this.setDecimalPrecision(decimalPrecision);
		}
	}
});

Ext.reg('numberedit', Terrasoft.NumberEdit);