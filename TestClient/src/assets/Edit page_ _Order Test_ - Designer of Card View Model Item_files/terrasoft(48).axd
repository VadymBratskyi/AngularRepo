Terrasoft.DateEdit = Ext.extend(Terrasoft.BaseEdit, {
	altFormats: null,
	showToday: true,
	validator: null,
	width: 'auto',
	defaultAutoCreate: { tag: "input", type: "text", autocomplete: "off" },

	initComponent: function() {
		Terrasoft.DateEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = { 
			id: this.primaryToolButtonId(),
			imageCls: 'datetimeedit-ico-btn-date'
		};
		if (typeof this.minValue == "string") {
			this.minValue = this.parseDate(this.minValue);
		}
		if (typeof this.maxValue == "string") {
			this.maxValue = this.parseDate(this.maxValue);
		}
		this.ddMatch = null;
		this.initDisabledDays();
	},

	getFormat: function() {
		return Ext.util.Format.getDateFormat();
	},

	initDisabledDays: function() {
		if (this.disabledDates) {
			var dd = this.disabledDates;
			var re = "(?:";
			for (var i = 0; i < dd.length; i++) {
				re += dd[i];
				if (i != dd.length - 1) re += "|";
			}
			this.disabledDatesRE = new RegExp(re + ")");
		}
	},

	setDisabledDates: function(dd) {
		this.disabledDates = dd;
		this.initDisabledDays();
		if (this.menu) {
			this.menu.picker.setDisabledDates(this.disabledDatesRE);
		}
	},

	setDisabledDays: function(dd) {
		this.disabledDays = dd;
		if (this.menu) {
			this.menu.picker.setDisabledDays(dd);
		}
	},

	setMinValue: function(dt) {
		this.minValue = (typeof dt == "string" ? this.parseDate(dt) : dt);
		if (this.menu) {
			this.menu.picker.setMinDate(this.minValue);
		}
	},

	setMaxValue: function(dt) {
		this.maxValue = (typeof dt == "string" ? this.parseDate(dt) : dt);
		if (this.menu) {
			this.menu.picker.setMaxDate(this.maxValue);
		}
	},

	validateValue: function(value) {
		value = this.formatDate(value);
		if (!Terrasoft.DateEdit.superclass.validateValue.call(this, value)) {
			return false;
		}
		if (value.length < 1) {
			if (!this.required) {
				return true;
			} else {
				this.markInvalid(this.blankText);
				return false;
			}
		}
		value = this.parseDate(value);
		if (!value) {
			this.markInvalid();
			return false;
		}
		var time = value.getTime();
		if (this.minValue && time < this.minValue.getTime()) {
			this.markInvalid();
			return false;
		}
		if (this.maxValue && time > this.maxValue.getTime()) {
			this.markInvalid();
			return false;
		}
		if (this.disabledDays) {
			var day = value.getDay();
			for (var i = 0; i < this.disabledDays.length; i++) {
				if (day === this.disabledDays[i]) {
					this.markInvalid();
					return false;
				}
			}
		}
		var fvalue = this.formatDate(value);
		this.ddMatch = this.disabledDatesRE;
		if (this.ddMatch && this.ddMatch.test(fvalue)) {
			this.markInvalid();
			return false;
		}
		return true;
	},

	validateBlur: function() {
		return !this.menu || !this.menu.isVisible();
	},

	getValue: function() {
		return this.parseDate(Terrasoft.DateEdit.superclass.getValue.call(this));
	},

	setValue: function(date, isInitByEvent) {
		if (isInitByEvent) {
			this.startValue = date;
		}
		Terrasoft.DateEdit.superclass.setValue.call(this, this.formatDate(this.parseDate(date)));
	},

	parseDate: function(value) {
		if (!value || Ext.isDate(value)) {
			return value;
		}
		var v = Date.parseDate(value, this.getFormat());
		if (!v && this.altFormats) {
			if (!this.altFormatsArray) {
				this.altFormatsArray = this.altFormats.split("|");
			}
			for (var i = 0, len = this.altFormatsArray.length; i < len && !v; i++) {
				v = Date.parseDate(value, this.altFormatsArray[i]);
			}
		}
		return v;
	},

	onDestroy: function() {
		if (this.menu) {
			this.menu.destroy();
		}
		if (this.wrap) {
			this.wrap.remove();
		}
		Terrasoft.DateEdit.superclass.onDestroy.call(this);
	},

	formatDate: function(date) {
		return Ext.isDate(date) ? Ext.util.Format.date(date, this.getFormat()) : date;
	},

	menuListeners: {
		select: function(m, d) {
			this.setValue(d);
			this.checkChange();
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
		if (!this.enabled || !this.primaryToolButton || !this.primaryToolButton.enabled) {
			return;
		}
		if (!this.menu) {
			this.menu = new Terrasoft.DateMenu(this.config);
		}
		var config = {
			minDate: this.minValue,
			maxDate: this.maxValue,
			disabledDatesRE: this.ddMatch,
			disabledDays: this.disabledDays,
			disabledDates: this.disabledDates,
			format: Ext.util.Format.getDateFormat(),
			showToday: this.showToday,
			startDay: this.startDay
		};
		if (this.dayNames) {
			config.dayNames = this.dayNames;
		}
		if (this.monthNames) {
			config.monthNames = this.monthNames;
		}
		if (this.todayText) {
			config.todayText = this.todayText;
		}
		if (this.tomorrowText) {
			config.tomorrowText = this.tomorrowText;
		}
		if (this.yesterdayText) {
			config.yesterdayText = this.yesterdayText;
		}
		Ext.apply(this.menu.picker, config);
		this.menu.picker.initDisabledDays();
		this.menu.on(Ext.apply({}, this.menuListeners, {
			scope: this
		}));
		this.menu.picker.setValue(this.getValue() || new Date());
		this.menu.show(this.wrap, "tl-bl?", this.menu.parentMenu, [0, -1]);
	},

	fireChangeEvent: Ext.emptyFn,

	checkChange: function() {
		var v = this.getRawValue();
		var startValue = !Ext.isDate(this.startValue) ? this.startValue :
			Ext.util.Format.dateFormat(this.startValue);
		if (String(v) !== startValue) {
			this.fireEvent('change', this, v, this.startValue);
			this.startValue = v;
		}
	},

	clear: function() {
		this.setRawValue('');
		if (!this.required) {
			this.clearInvalid();
		}
	}
});

Ext.reg('dateedit', Terrasoft.DateEdit);

Terrasoft.TimeEdit = Ext.extend(Terrasoft.ComboBox, {
	minValue: null,
	maxValue: null,
	altFormats: null,
	increment: 15,
	width: 'auto',
	validator: null,
	strictedToItemsList: false,
	typeAhead: false,
	itemCls: 'x-menu',

	initComponent: function() {
		Terrasoft.TimeEdit.superclass.initComponent.call(this);
		if (typeof this.minValue == "string") {
			this.minValue = this.parseDate(this.minValue);
		}
		if (typeof this.maxValue == "string") {
			this.maxValue = this.parseDate(this.maxValue);
		}
		var min = this.parseDate(this.minValue);
		if (!min) {
			min = new Date().clearTime();
		}
		var max = this.parseDate(this.maxValue);
		if (!max) {
			max = new Date().clearTime().add('mi', (24 * 60) - 1);
		}
		var times = [];
		while (min <= max) {
			times.push([Ext.util.Format.timeFormat(min), Ext.util.Format.timeFormat(min)]);
			min = min.add('mi', this.increment);
		}
		this.store = new Ext.data.SimpleStore({
			fields: ['text', 'value'],
			data: times
		});
		this.displayField = 'text';
		this.checkDataProperties();
	},

	expand: function() {
		var value = this.getValue();
		var increment = this.increment;
		var today = Ext.isEmpty(value) ? new Date() : this.parseDate(value);
		if (!today) {
			today = new Date();
		}
		var minutes = today.getMinutes();
		var minutesDiff = minutes % increment;
		var incrementCount = (minutes - minutesDiff) / increment;
		var selectionMinutes = incrementCount * increment + (minutesDiff > increment/2 ? increment : 0);
		today.setMinutes(selectionMinutes);
		value = Ext.util.Format.timeFormat(today);
		Terrasoft.TimeEdit.superclass.expand.call(this);
		var timeEdit = this;
		// In comboboxEdit, after expanding, the first record is immediately allocated
		setTimeout(function() {
			var record = timeEdit.findRecord(timeEdit.valueField || timeEdit.displayField, value);
			if (record) {
				var selectionIndex = timeEdit.store.indexOf(record);
				timeEdit.select(selectionIndex, false);
				var el = timeEdit.view.getNode(selectionIndex);
				timeEdit.list.dom.scrollToElement(el, false);
				timeEdit.oldIndexForScroll = selectionIndex;
			}
		}, 5);
	},

	getFormat: function() {
		return Ext.util.Format.getTimeFormat();
	},

	getValue: function() {
		if (!this.el) {
			return '';
		}
		return this.el.dom.value;
	},

	setValue: function(value, isInitByEvent) {
		if (isInitByEvent) {
			this.startValue = value;
		}
		this.value = value;
		if (this.el) {
			this.el.dom.value = Ext.value(this.formatDate(this.parseDate(value)), '');
		}
		this.validate(true);
	},

	validateValue: Terrasoft.DateEdit.prototype.validateValue,	
	parseDate: Terrasoft.DateEdit.prototype.parseDate,
	formatDate: Terrasoft.DateEdit.prototype.formatDate,
	fireChangeEvent: Ext.emptyFn,

	checkChange: function() {
		var v = this.getRawValue();
		var startValue = !Ext.isDate(this.startValue) ? this.startValue :
			Ext.util.Format.dateFormat(this.startValue);
		if (String(v) !== startValue) {
			this.fireEvent('change', this, v, this.startValue);
		}
	},

	onBlur: function() {
	}
});

Ext.reg('timeedit', Terrasoft.TimeEdit);

Terrasoft.DateTimeEdit = Ext.extend(Terrasoft.CompositeLayoutControl, {
	supportsCaption: true,
	isContainer: false,
	supportsCaptionNumber: true,
	isFormField: true,
	kind: 'datetime',
	width: 200,
	timeControlWidth: 80,
	controlsSpacingWidth: 4,
	dateValidator: null,
	timeValidator: null,
	dateAltFormats: null,
	timeAltFormats: null,
	enableKeyEvents: false,
	increment: 15,
	valueInit: true,

	initComponent: function() {
		Terrasoft.DateTimeEdit.superclass.initComponent.call(this);
		var stringList = Ext.StringList('WC.Common');
		this.requiredText = stringList.getValue('FormValidator.RequiredFieldMessage');
		this.valueInit = false;
		this.setValue(this.value);
		this.valueInit = true;
	},

	handleNameChanging: function(oldName, name) {
		Terrasoft.DateTimeEdit.superclass.handleNameChanging.call(this, oldName, name, true);
		this.date.primaryToolButton.handleNameChanging(this.date.primaryToolButton.id,this.date.id + '_Date', true);
		this.time.primaryToolButton.handleNameChanging(this.time.primaryToolButton.id, this.time.id + '_Time', true);
		this.date.handleNameChanging(this.date.id, name + '_Date', true);
		this.time.handleNameChanging(this.time.id, name + '_Time', true);
		this.fireEvent("nameChanged", this, oldName, name);
	},

	initItems: function() {
		var toolsConfig = this.toolsConfig;
		var kind = this.kind;
		if (toolsConfig) {
			this.dateToolsConfig = [];
			this.timeToolsConfig = [];
			Ext.each(toolsConfig, function(toolButton) {
				if (toolButton.controlType == 'time' || kind == 'time') {
					this.timeToolsConfig.push(toolButton);
				} else {
					this.dateToolsConfig.push(toolButton);
				}
			}, this);
		}
		this.items = [];
		if (kind == 'datetime' || kind == 'date') {
			var dateItemConfig = this.getDateItemConfig();
			var dateEl = this.date = new Terrasoft.DateEdit(dateItemConfig);
			/*
			dateEl.on('change', function(o, value, oldValue) {
				this.checkChange();
				var newValue = Date.parseDate(value, this.date.getFormat());
				if (this.time) {
					var formattedTime = this.time.getValue();
					var time = Date.parseDate(formattedTime, this.getTimeFormat());
					if (time) {
						newValue.setMilliseconds(time.getMilliseconds());
						newValue.setSeconds(time.getSeconds());
						newValue.setMinutes(time.getMinutes());
						newValue.setHours(time.getHours());
					}
				}
				this.startValue = Ext.util.Format.date(newValue, this.getFormat());
			}, this);
			*/
		}
		if (kind == 'datetime' || kind == 'time') {
			var timeItemConfig = this.getTimeItemConfig();
			this.time = new Terrasoft.TimeEdit(timeItemConfig);
		}
		if (dateEl) {
			this.items.push(dateEl);
		}
		if (this.time) {
			this.items.push(this.time);
		}
	},

	getDateItemConfig: function() {
		var config = {
			id: this.id + '_Date',
			designMode: this.designMode,
			format: this.getDateFormat(),
			altFormats: this.dateAltFormats,
			startDay: this.getStartDay(),
			disabledDays: this.disabledDays,
			validator: this.dateValidator,
			enableKeyEvents: this.enableKeyEvents,
			disabledDates: this.disabledDates,
			allowEmpty: this.allowEmpty,
			required: this.required,
			listClass: this.listClass,
			width: '100%'
		};
		var dateToolsConfig = this.dateToolsConfig;
		if (dateToolsConfig && dateToolsConfig.length > 0) {
			config.toolsConfig = dateToolsConfig;
		}
		if (this.datePrimaryToolButtonConfig) {
			config.primaryToolButtonConfig = this.datePrimaryToolButtonConfig;
		}
		if (this.dayNames) {
			config.dayNames = this.dayNames;
		}
		if (this.monthNames) {
			config.monthNames = this.monthNames;
		}
		if (this.todayText) {
			config.todayText = this.todayText;
		}
		if (this.tomorrowText) {
			config.tomorrowText = this.tomorrowText;
		}
		if (this.yesterdayText) {
			config.yesterdayText = this.yesterdayText;
		}
		return config;
	},

	getTimeItemConfig: function() {
		var config = {
			id: this.id + '_Time',
			designMode: this.designMode,
			format: this.getTimeFormat(),
			altFormats: this.timeAltFormats,
			increment: this.increment,
			validator: this.timeValidator,
			enableKeyEvents: this.enableKeyEvents,
			allowEmpty: this.allowEmpty,
			required: this.required,
			listClass: this.listClass,
			width: (this.kind == 'time') ? '100%' : this.timeControlWidth
		};
		var timeToolsConfig = this.timeToolsConfig;
		if (timeToolsConfig && timeToolsConfig.length > 0) {
			config.toolsConfig = timeToolsConfig;
		}
		if (this.timePrimaryToolButtonConfig) {
			config.primaryToolButtonConfig = this.timePrimaryToolButtonConfig;
		}
		return config;
	},

	onChange: function(o, columnValue, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		columnValue = !Ext.isEmpty(columnValue) ? Ext.util.JSON.decodeDate(columnValue) : '';
		if ((!opt || !opt.isInitByEvent) && this.validate(true)) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, columnValue);
			}
		}
	},
	
	moveControl: function(item, position) {
		this.items[0].moveControl(item, position);
	},

	insert: function(index, toolBtn, force) {
		this.items[0].insert(index, toolBtn, force);
	},

	onContentChanged: function() {
		this.items[0].actualizeSize();
	},

	checkChange: function() {
		if (!this.enabled) {
			return;
		}
		var value = this.getFormattedValue();
		var startValue = this.startValue;
		if (value !== startValue) {
			var format = this.getFormat();
			var oldValue = Date.parseDate(startValue, format) || '';
			var newValue = Date.parseDate(value, format) || '';
			this.fireEvent('change', this, Ext.util.JSON.encode(newValue),
				 Ext.util.JSON.encode(oldValue));
			this.startValue = Ext.util.Format.date(newValue, this.getFormat());
		}
	},

	getDateFormat: function() {
		if (this.dateFormat != undefined) {
			return this.dateFormat;
		}
		return Ext.util.Format.getDateFormat();
	},

	getTimeFormat: function() {
		if (this.timeFormat != undefined) {
			return this.timeFormat;
		}
		return Ext.util.Format.getTimeFormat();
	},

	getDateTimeFormat: function() {
		return this.getDateFormat() + ' ' + this.getTimeFormat();
	},

	getStartDay: function() {
		if (this.startDay != undefined) {
			return this.startDay;
		}
		this.startDay = parseInt(Terrasoft.CultureInfo.startDay);
		return this.startDay;
	},

	getValue: function() {
		var date = (this.date) ? this.date.getValue() : '';
		if (this.time) {
			var formattedTime = this.time.getValue();
			var time = Date.parseDate(formattedTime, this.getTimeFormat());
		}
		if ((!date) && (!time)) {
			return '';
		}
		if (this.kind == 'datetime' && (!date || !time)) {
			return '';
		}
		if (this.kind == 'time') {
			date = new Date();
			date.clearTime();
		}
		if (time) {
			date.setMilliseconds(time.getMilliseconds());
			date.setSeconds(time.getSeconds());
			date.setMinutes(time.getMinutes());
			date.setHours(time.getHours());
		}
		return date;
	},

	getDisplayValue: function() {
		return this.getFormattedValue();
	},

	getFormattedValue: function() {
		var value = this.getValue();
		return Ext.util.Format.date(value, this.getFormat());
	},
	
	validate: function(preventMark) {
		if (!this.enabled) {
			return true;
		}
		var result = this.validateValue(this.processValue(this.getRawValue()));
		if (result == false) {
			return false;
		}
		return Terrasoft.DateEdit.prototype.validate.call(this, preventMark);
	},
	
	validateValue: function(value) {
		var required = this.required;
		var date = this.date;
		var time = this.time;
		if (!value) {
			return !required;
		}
		if (time && date && required) {
			if (Ext.isEmpty(date.el.getValue()) || Ext.isEmpty(time.el.getValue())) {
				this.markInvalid(this.getValidationMessage(this.requiredText, this.id, null));
				return false;
			}
		}
		var isValid = this.parseDate(value) != null;
		if (!isValid) {
			this.markInvalid();
		}
		return isValid;
	},

	parseDate: Terrasoft.DateEdit.prototype.parseDate,

	getRawValue: function() {
		var date = '', time = '';
		var separator = (this.kind == 'datetime') ? ' ' : '';
		if(this.rendered) {
			date = (this.date && this.date.el.getValue()) || '';
			time = (this.time && this.time.el.getValue()) || '';
		}
		return (date || time) ? (date + separator + time) : Ext.value(this.value, '');
	},

	getStartValue: function () {
		return this.getFormattedValue();
	},

	setValue: function(value, isInitByEvent) {
		var newValue = value;
		if (!Ext.isDate(value)) {
			value = Date.parseDate(newValue, this.getFormat()) || '';
		}
		var oldValue = this.getFormattedValue();
		var formattedValue = Ext.util.Format.date(value, this.getFormat());
		if (formattedValue == oldValue && formattedValue == this.getRawValue()) {
			return;
		}
		if (this.kind == 'datetime' || this.kind == 'time') {
			if (Ext.isDate(value)) {
				if (this.kind == 'datetime') {
					var date = new Date(value).clearTime();
				}
				var time = new Date();
				time.clearTime();
				time.setMilliseconds(value.getMilliseconds());
				time.setSeconds(value.getSeconds());
				time.setMinutes(value.getMinutes());
				time.setHours(value.getHours());
			}
			if (this.kind == 'datetime') {
				this.date.setValue(date || '', isInitByEvent);
			}
			this.time.setValue(time || '', isInitByEvent);
		}
		if (this.kind == 'date') {
			if (Ext.isDate(value)) {
				value.clearTime();
			}
			this.date.setValue(value || '', isInitByEvent);
		}
		this.value = value;
		this.validate(true);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.fireEvent("change", this,
				Ext.isDate(value) ? Ext.util.JSON.encodeDate(value) : Ext.util.JSON.encode(''),
				Ext.isDate(oldValue) ? Ext.util.JSON.encodeDate(oldValue) : Ext.util.JSON.encode(''), opt);
		}
	},

	getFormat: function() {
		if (this.kind == 'datetime') {
			return this.getDateTimeFormat();
		}
		if (this.kind == 'date') {
			return this.getDateFormat();
		}
		if (this.kind == 'time') {
			return this.getTimeFormat();
		}
	},
	
	validateBlur: function(e) {
		var datePickerEl = (this.date && this.date.menu && this.date.menu.isVisible()) ?
			this.date.menu.el : null;
		if (datePickerEl && datePickerEl.contains(e.target)) {
			return false;
		}
		var timeListEl = (this.time && this.time.list && this.time.list.isVisible()) ?
			this.time.list : null;
		if (timeListEl && timeListEl.contains(e.target)) {
			return false;
		}
		return true;
	},
	
	setKind: function(kind) {
		if (this.kind === kind) {
			return;
		}
		this.kind = kind;
		if (kind === 'datetime' || kind === 'date') {
			if (kind === 'date' && this.time) {
				this.items.remove(this.time);
				this.time.destroy();
				delete this.time;
			}
			if (!this.date) {
				var dateItemConfig = this.getDateItemConfig();
				this.date = new Terrasoft.DateEdit(dateItemConfig);
				var itemsNew = [];
				itemsNew[0] = this.date;
				if (kind === 'datetime') {
					itemsNew[1] = this.items[0];
					itemsNew[1].width = this.timeControlWidth;
				}
				this.items = itemsNew;
			}
		}
		if (kind === 'datetime' || kind === 'time') {
			var timeWidth = (kind == 'time') ? '100%' : this.timeControlWidth;
			if (!this.time){
				var timeItemConfig = this.getTimeItemConfig();
				this.time = new Terrasoft.TimeEdit(timeItemConfig);
				this.time.width = timeWidth;
				this.items.push(this.time);
			}
			if (kind === 'time' && this.date) {
				this.items.remove(this.date);
				this.date.destroy();
				delete this.date;
				this.time.width = timeWidth;
			}
		}
		this.renderItems(this.el);
		this.layoutItems();
	},

	clear: function() {
		var date = this.date;
		if (date) {
			date.clear();
		}
		var time = this.time;
		if (time) {
			time.setValueAndText('','');
		}
	}
});

Ext.reg('datetimeedit', Terrasoft.DateTimeEdit);
