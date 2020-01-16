Terrasoft.CompositeLayoutControl = Ext.extend(Ext.LayoutControl, {
	isContainer: false,
	supportsCaption: true,
	supportsCaptionNumber: true,
	margin: 4,
	hasFocus: false,
	allowEmpty: true,
	ignoreDataSourceProperties: false,

	initComponent: function() {
		Terrasoft.CompositeLayoutControl.superclass.initComponent.call(this);
		this.initItems();
		this.unregisterItems();
		var stringList = Ext.StringList('WC.Common');
		this.invalidText = stringList ? stringList.getValue('Field.InvalidValueMessage') : '';
		if (this.dataSource) {
			this.initDataEvents();
		}
	},
	
	initItems: Ext.emptyFn,

	unregisterItems: function() {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			Ext.ComponentMgr.unregister(this.items[i]);
		}
	},

	initEvents: function() {
		this.addEvents('focus', 'blur', 'change', 'dblclick');
		this.initItemsEvents();
	},

	initItemsEvents: function() {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			this.items[i].on('focus', this.onFocus, this);
			this.items[i].on('dblclick', this.onDblClick, this);
		}
	},

	initDataEvents: function() {
		this.on("change", this.onChange, this);
		var dataSource = this.dataSource;
		dataSource.on('loaded', this.onDataSourceLoaded, this);
		dataSource.on('activerowchanged', this.onDataSourceActiveRowChanged, this);
		dataSource.on('datachanged', this.onDataSourceDataChanged, this);
		dataSource.on('activerowvalidated', this.onDataSourceActiveRowValidated, this);
		if (this.ignoreDataSourceProperties === false) {
			dataSource.on('structureloaded', this.onDataSourceStructureLoaded, this);
			dataSource.on('onstructureloadedcomplete', this.onStructureLoadedComplete, this);
		}
	},

	initValue: function() {
		try {
			this.valueInit = false;
			var column = this.getColumn();
			if (column) {
				var value = this.getColumnValue();
				value = Ext.isDate(value) ? value.clone() : value;
				this.setValue(value || '');
				return;
			}
			if (this.value !== undefined) {
				this.setValue(this.value);
			}
		} finally {
			this.valueInit = true;
		}
	},

	onRender: function(ct, position) {
		Terrasoft.CompositeLayoutControl.superclass.onRender.call(this, ct, position);
		this.el = ct.createChild({
			tag: 'div',
			id: this.id
		});
		this.el.addClass('x-composite-layout-control');
		this.renderItems(this.el);
		this.setElHeight();
		this.layoutItems();
		this.el.control = this;
		this.el.setWidth = this.setElSize;
		this.el.setSize = this.setElSize;
	},

	setElHeight: function() {
		var firstItem = this.getFirstItem();
		this.el.setHeight(firstItem.getHeight());
	},

	getLabelEl: function() {
		return this.labelEl;
	},

	afterRender: function() {
		Terrasoft.CompositeLayoutControl.superclass.afterRender.call(this);
		if (this.required) {
			this.markRequired(this.required);
		}
		this.initEvents();
		if (this.designMode) {
			return;
		}
		this.initValue();
	},

	renderItems: function(ct) {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			item.isInnerControl = true;
			item.render(ct);
			item.getResizeEl().setStyle('position', 'absolute');
		}
	},

	setElSize: function(width) {
		if (width === undefined || width < 0) {
			return;
		}
		Ext.Element.prototype.setWidth.call(this, width);
		this.control.layoutItems();
	},

	setSize: function(w, h) {
		h = undefined;
		Terrasoft.CompositeLayoutControl.superclass.setSize.call(this, w, h);
	},

	getAvailiableWidth: function() {
		var items = this.items;
		var itemsCount = items.length;
		var elWidth = this.el.getWidth(true);
		var allMargins = 0;
		for (var i = 0; i < itemsCount; i++) {
			var item = items[i];
			var margin = i > 0 ? this.margin : 0;
			if (item.marginLeft !== undefined) {
				margin = item.marginLeft;
			}
			if (i == itemsCount - 1) {
				margin += item.marginRight ? item.marginRight : 0;
			}
			allMargins += margin;
		}
		return elWidth - allMargins;
	},

	layoutItems: function() {
		var items = this.items;
		var flex;
		Ext.each(items, function(item) {
			delete item.flex;
			if (item.width && typeof item.width == 'string') {
				flex = this.getFlexValue(item.width);
				if (flex) {
					item.flex = flex;
				}
			}
		}, this);
		var itemsCount = this.items.length;
		var availiableWidth = this.getAvailiableWidth();
		var leftOver = availiableWidth;
		var fixedWidth = 0;
		var flexWidth = 0;
		var totalFlex = 0;
		var widths = [];
		var itemWidth;
		if (availiableWidth < 0) {
			return;
		}
		for (var i = 0; i < itemsCount; i++) {
			if (items[i].flex) {
				totalFlex += items[i].flex || 0;
			} else {
				fixedWidth += items[i].width;
			}
		}
		availiableWidth = (availiableWidth - fixedWidth);
		for (i = 0; i < itemsCount; i++) {
			if (items[i].flex) {
				itemWidth = Math.floor(availiableWidth * (items[i].flex / totalFlex));
				flexWidth += itemWidth;
			} else {
				itemWidth = items[i].getWidth();
			}
			widths.push(itemWidth);
		}
		leftOver = leftOver - (flexWidth + fixedWidth);
		var leftPosition = 0;
		if (items[0].marginLeft !== undefined) {
			leftPosition = items[0].marginLeft;
		}
		var hasFlaxItem = flexWidth > 0;
		var fixLeftOverItemsIndex = [];
		for (i = 0; i < itemsCount; i++) {
			fixLeftOverItemsIndex.push(hasFlaxItem && items[i].flex);
		}
		for (i = 0; i < itemsCount; i++) {
			var item = items[i];
			if (i > 0) {
				var margin = this.margin;
				if (item.marginLeft !== undefined) {
					margin = item.marginLeft;
				}
				leftPosition = leftPosition + margin;
			}
			var itemResizeEl = item.getResizeEl();
			itemResizeEl.setLeft(leftPosition);
			var width = widths[i];
			if (fixLeftOverItemsIndex[i]) {
				if (leftOver > 0) {
					leftOver = leftOver - 1;
					width = width + 1;
				}
			}
			leftPosition = leftPosition + width;
			item.setWidth(width);
		}
	},

	onFocus: function() {
		if (this.designMode) {
			return;
		}
		if (!this.hasFocus) {
			this.hasFocus = true;
			this.startValue = this.getStartValue();
			Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.checkBlur, this, {delay: 10});
			var firstItem = this.getFirstItem();
			var lastItem = this.getLastItem();
			firstItem.getResizeEl().on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.checkTab,
				this);
			lastItem.getResizeEl().on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress",
				this.checkTab, this);
			Terrasoft.FocusManager.setFocusedControl.defer(10, this, [this]);
			this.fireEvent("focus", this);
		}
	},

	getFirstItem: function() {
		return this.items[0];
	},

	getLastItem: function() {
		var items = this.items;
		return items[items.length - 1];
	},

	checkBlur: function(e) {
		if (!this.el.contains(e.target) && this.validateBlur(e)) {
			this.triggerBlur();
		}
	},

	validateBlur: function(e) {
		return true;
	},

	findFocusedEditor: function() {
		var items = this.items;
		for (var i = 0, itemslength = items.length; i < itemslength; i++) {
			var item = items[i];
			if (!this.customFocusElCondition(item)) {
				continue;
			}
			if (item.hasFocus === true) {
				return item;
			}
		}
		return null;
	},
	
	customFocusElCondition: function(item) {
		return true;
	},

	processFocusedEditor: function(editor) {
		editor.unFocus();
	},

	triggerBlur: function() {
		this.hasFocus = false;
		var focusedEditor = this.findFocusedEditor();
		if (focusedEditor) {
			this.processFocusedEditor(focusedEditor);
		}
		Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.checkBlur, this);
		var firstItem = this.getFirstItem();
		var lastItem = this.getLastItem();
		firstItem.getResizeEl().un(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.checkTab, this);
		lastItem.getResizeEl().un(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress",
			this.checkTab, this);
		this.validate(true);
		this.checkChange();
		this.fireEvent("blur", this);
	},

	checkTab: function(e, c) {
		if (e.getKey() == e.TAB) {
			var firstItem = this.getFirstItem();
			var lastItem = this.getLastItem();
			if ((e.shiftKey === true && (firstItem.getResizeEl().contains(c) || c.id == firstItem.getResizeEl().id)) ||
				(e.shiftKey !== true && (lastItem.getResizeEl().contains(c) || c.id == lastItem.getResizeEl().id))) {
				this.triggerBlur();
			}
		}
	},

	unFocus: function() {
		this.triggerBlur();
	},

	fireChangeEvent: function(value, oldValue, isInitByEvent) {
		if (!this.valueInit) {
			return;
		}
		var opt = {
			isInitByEvent: isInitByEvent || false
		};
		this.startValue = value;
		this.fireEvent('change', this, value, oldValue, opt);
	},

	setValue: Ext.emptyFn,

	getValue: Ext.emptyFn,

	getStartValue: function() {
		return this.getValue();
	},

	checkChange: function() {
		var newValue = this.getValue();
		var oldValue = this.startValue;
		if (String(newValue) !== String(this.startValue)) {
			this.startValue = newValue;
			this.fireEvent('change', this, newValue, oldValue);
		}
	},

	parseValue: Ext.emptyFn,

	getFlexValue: function(size) {
		var percentSignIndex = size.indexOf('%');
		var flex = NaN;
		if (percentSignIndex != -1) {
			var percentStringValue = size.substring(0, percentSignIndex);
			flex = parseFloat(percentStringValue);
		}
		return isNaN(flex) ? null : flex;
	},

	getColumnUId: function (columnUId) {
		return columnUId === "00000000-0000-0000-0000-000000000000" ? null : columnUId;
	},

	getColumnBase: function(columnUId, columnName) {
		var dataSource = this.dataSource;
		columnUId = this.getColumnUId(columnUId);
		if (!dataSource || (!columnUId && !columnName)) {
			return null;
		}
		return columnUId ? dataSource.getColumnByUId(columnUId) : dataSource.getColumnByName(columnName);
	},

	getColumn: function() {
		return this.getColumnBase(this.columnUId, this.columnName);
	},

	getColumnValue: function () {
		var dataSource = this.dataSource;
		var columnUId = this.getColumnUId(this.columnUId);
		return columnUId ? dataSource.getColumnValueByColumnUId(columnUId) : dataSource.getColumnValue(this.columnName);
	},

	onChange: function(o, columnValue, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		columnValue = Ext.isDate(columnValue) ? columnValue.clone() : columnValue;
		columnValue = !Ext.isEmpty(columnValue) ? columnValue : '';
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, columnValue);
			}
		}
	},

	onDataSourceDataChanged: function(record, columnName) {
		var column = this.getColumn();
		if (!record || columnName != column.name) {
			return;
		}
		this.setValue(record.getColumnValue(columnName), true);
	},

	onDataSourceLoaded: function(dataSource) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValue(value, true);
	},

	onDataSourceActiveRowChanged: function(dataSource, primaryColumnValue) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValue(value, true);
	},

	onDataSourceActiveRowValidated: function (columnName, isValid, extrsMessage) {
		var column = this.getColumn();
		if (!column || columnName != column.name) {
			return;
		}
		isValid ? this.clearInvalid() : this.markInvalid();
		this.serverValidationResult = isValid;
		var items = this.items;
		for (var i = 0, length = items.length; i < length; i += 1) {
			items[i].serverValidationResult = isValid;
		}
		this.validationMessage = extrsMessage;
	},

	getFieldSize: function() {
		var size = null;
		var column = this.getColumn();
		if (column) {
			size = column.dataValueType.size;
		}
		return size;
	},

	onStructureLoadedComplete: function() {
		var size = this.getFieldSize();
		if (size && this.rendered) {
			this.el.dom.setAttribute('maxlength', size);
		}
		var ownerCt = this.ownerCt;
		if (!ownerCt) {
			return;
		}
		var alignGroupContainer = ownerCt.getAlignGroupContainer();
		var deferLayoutList = Terrasoft.deferLayoutList;
		if (deferLayoutList && deferLayoutList.indexOf(alignGroupContainer) != -1) {
			alignGroupContainer.beginContentUpdateCallCounter = 1;
			deferLayoutList.remove(alignGroupContainer);
			if (deferLayoutList.length == 0) {
				delete Terrasoft.deferLayoutList;
			}
			alignGroupContainer.updateControlsCaptionWidth();
			alignGroupContainer.endContentUpdate();
			return;
		}
	},

	onDataSourceStructureLoaded: function(dataSource) {
		var ownerCt = this.ownerCt;
		if (ownerCt) {
			var deferLayoutList = Terrasoft.deferLayoutList || (Terrasoft.deferLayoutList = []);
			var alignGroupContainer = ownerCt.getAlignGroupContainer();
			if (deferLayoutList.indexOf(alignGroupContainer) == -1) {
				alignGroupContainer.beginContentUpdate();
				deferLayoutList.push(alignGroupContainer);
			}
		}
		this.setPropertiesByColumn();
	},

	setPropertiesByColumn: function(column) {
		column = column || this.getColumn();
		if (!column) {
			return;
		}
		this.setEnabled(this.enabled);
		if (this.isDefaultPropertyValue('caption') && column.caption !== undefined) {
			this.setCaption(column.caption);
		}
		if (this.isDefaultPropertyValue('required') && column.required !== undefined) {
			this.setRequired(column.required);
		}
	},

	disable: function() {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			items[i].disable();
		}
		Terrasoft.CompositeLayoutControl.superclass.disable.call(this);
	},

	enable: function () {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			items[i].enable();
		}
		Terrasoft.CompositeLayoutControl.superclass.enable.call(this);
	},

	setEnabled: function(enabled) {
		var column = this.getColumn();
		if (column && !this.dataSource.canEditColumn(column)) {
			enabled = false;
		}
		Ext.form.Field.superclass.setEnabled.call(this, enabled);
	},

	setDisabled: function(disabled) {
		this.setEnabled(!disabled);
	},

	markRequired: function(required) {
		if (required == undefined) {
			return;
		}
		this.required = required;
		var items = this.items;
		Ext.each(items, function(item) {
			if (item.markRequired) {
				item.markRequired(required);
			}
		});
		var labelEl = this.getLabelEl();
		if (!labelEl) {
			return;
		}
		if (required) {
			labelEl.addClass([this.requiredClass, 'x-display-name-required']);
			if (this.numberLabelEl) {
				this.numberLabelEl.addClass([this.requiredClass, 'x-display-name-required']);
			}
		} else {
			labelEl.removeClass([this.requiredClass, 'x-display-name-required']);
			if (this.numberLabelEl) {
				this.numberLabelEl.removeClass([this.requiredClass, 'x-display-name-required']);
			}
		}
	},

	markInvalid: function(msg) {
		var items = this.items;
		Ext.each(items, function(item) {
			if (item.markInvalid) {
				item.markInvalid(msg);
			}
		});
	},

	clearInvalid: function() {
		var items = this.items;
		Ext.each(items, function(item) {
			if (item.clearInvalid) {
				item.clearInvalid();
			}
		});
	},

	getLinkConfig: function() {
		var caption = this.caption;
		return {
			linkId: this.id,
			caption: caption
		};
	},

	getValidationResult: function() {
		return {
			type: this.validationType,
			message: this.getValidationMessage()
		};
	},

	getValidationMessage: function(message, id, value) {
		if (!message) {
			return this.validationMessage || this.invalidText;
		}
		return this.validationMessage = Ext.Link.applyLinks(String.format(message, '{' + id + '}', value),
			this.getLinkConfig());
	},

	isValid: function() {
		return this.validate(true);
	},

	validate: function(preventMark) {
		if (!this.enabled) {
			return true;
		}
		var restore = this.preventMark;
		this.preventMark = (preventMark === true);
		var result;
		var items = this.items;
		var savedMark = {};
		var item;
		var itemsLength = items.length;
		for (var i = 0; i < itemsLength; i++) {
			item = items[i];
			savedMark[item.id] = item.preventMark;
			item.preventMark = preventMark === true;
		}
		for (var i = 0; i < itemsLength; i++) {
			item = items[i];
			if (item.validate) {
				result = item.validate(preventMark);
				if (result === false) {
					break;
				}
			}
		}
		this.validationType = 'custom';
		result = (result === false) ? result :
			this.validateValue(this.processValue(this.getRawValue()));
		result = (this.serverValidationResult === false) ? false : result;
		if (result) {
			this.clearInvalid();
		}
		this.preventMark = restore;
		for (var i = 0; i < itemsLength; i++) {
			item = items[i];
			item.preventMark = savedMark[item.id];
		}
		return result;
	},

	setRequired: function(required) {
		this.markRequired(required);
		this.validate(true);
	},

	processValue: function(value) {
		return value;
	},

	validateValue: function(value) {
		return true;
	},

	getRawValue: function() {
		return this.rendered ? this.getValue() : Ext.value(this.value, '');
	},

	getFocusEl: function() {
		return this.getFirstItem();
	},

	startEditing: function() {
		this.focus(undefined, 50);
	},

	endEditing: Ext.emptyFn,

	onDblClick: function(e) {
		this.fireEvent("dblclick", this, e);
	},

	onDestroy: function() {
		var dataSource = this.dataSource;
		if (dataSource) {
			dataSource.un('loaded', this.onDataSourceLoaded, this);
			dataSource.un('activerowchanged', this.onDataSourceActiveRowChanged, this);
			dataSource.un('datachanged', this.onDataSourceDataChanged, this);
			dataSource.un('structureloaded', this.onDataSourceStructureLoaded, this);
			dataSource.on('onstructureloadedcomplete', this.onStructureLoadedComplete, this);
			dataSource.un('activerowvalidated', this.onDataSourceActiveRowValidated, this);
		}
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			item.destroy();
		}
		Terrasoft.CompositeLayoutControl.superclass.onDestroy.call(this);
	}
});

Ext.reg('compositelayoutcontrol', Terrasoft.CompositeLayoutControl);