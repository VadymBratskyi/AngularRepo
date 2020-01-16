Terrasoft.MultiCurrencyEdit = Ext.extend(Terrasoft.CompositeLayoutControl, {
	invalidClass: "x-form-field-item-invalid",
	requiredClass: "x-form-item-label-required",
	hiddenField: null,
	width: 300,
	allowEmpty: false,
	editMode: false,
	loadDataDelay: 500,
	marginRight: 5,
	expandCurrencyListOnFocus: true,
	dataService: 'Services/DataService',
	RecalculateMethod: 'RecalculateMultiCurrency',
	getCurrenciesDataMethod: 'GetCurrencies',
	symbolPositions: ['right', 'left'],
	captionColumnPropertyName: 'currentCurrencyValue',
	decimalSeparator: '.',
	showTrailingZeros: false,
	labelCaptions: {
		rate: '',
		equals: '',
		notSetCurrencySymbol: ''
	},
	baseCurrencyUId: null,
	defaultValue: {
		currentCurrencyUId: null,
		currentCurrencyValue: 0,
		baseCurrencyValue: 0,
		rate: 1
	},
	value: {
		currentCurrencyUId: null,
		currentCurrencyValue: 0,
		baseCurrencyValue: 0,
		rate: 1
	},
	valueRequired: {
		currentCurrencyUId: false,
		currentCurrencyValue: false,
		baseCurrencyValue: false,
		rate: false
	},
	defaultCurrency: {
		symbol: '',
		symbolPosition: 'left',
		code: '',
		uid: null,
		shortName: '',
		caption: ''
	},
	baseCurrency: {
		symbol: '',
		symbolPosition: 'right',
		code: '',
		uid: null,
		shortName: '',
		caption: ''
	},
	currentCurrency: {
		symbol: '',
		symbolPosition: 'left',
		code: '',
		uid: null,
		shortName: '',
		caption: ''
	},
	itemsIds: {
		currentCurrencySymbol: 'currentCurrencySymbol',
		currentCurrencyValue: 'currentCurrencyValue',
		baseCurrencySymbol: 'baseCurrencySymbol',
		baseCurrencyValue: 'baseCurrencyValue',
		currentCurrencyRate: 'currentCurrencyRate',
		rateLabel: 'rateLabel',
		equalsLabel: 'equalsLabel'
	},
	editorsMap: {
		currentCurrencySymbol: 'currentCurrencyUId',
		currentCurrencyValue: 'currentCurrencyValue',
		baseCurrencyValue: 'baseCurrencyValue',
		currentCurrencyRate: 'rate'
	},
	defaultItemsEditRights: {
		currentCurrencySymbol: true,
		currentCurrencyValue: true,
		currentCurrencyRate: true,
		baseCurrencyValue: true
	},
	labelConfig: {
		autoWidth: true,
		wrapClass: 'x-form-multicurrencyedit'
	},

	initComponent: function() {
		if (this.initialConfig.value.currentCurrencyUId) {
			this.updateCurrency('currentCurrency', this.value.currentCurrencyUId);
		}
		if (this.initialConfig.baseCurrencyUId) {
			this.updateCurrency('baseCurrency', this.baseCurrencyUId);
		}
		this.valueRequired = Ext.apply({}, this.valueRequired, this.valueRequired);
		this.itemsEditRights = Ext.apply({}, this.itemsEditRights, this.defaultItemsEditRights);
		this.decimalSeparator = Terrasoft.CultureInfo.decimalSeparator;
		var stringList = this.stringList = Ext.StringList('WC.MultiCurrencyEdit');
		var labelCaptions = this.labelCaptions;
		labelCaptions.rate = stringList.getValue('RateLabel.Caption');
		labelCaptions.equals = stringList.getValue('EqualsLabel.Caption');
		labelCaptions.notSetCurrencySymbol = stringList.getValue('NotSetCurrencySymbol.Caption');
		Terrasoft.MultiCurrencyEdit.superclass.initComponent.call(this);
	},

	initItemsEvents: function() {
		if (this.designMode === true) {
			return;
		}
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var item = this.items[i];
			if (item.canFocusElement) {
				if (!this.editMode) {
					item.on('linkFocused', this.onFocus, this);
					item.on('linkclick', this.onLinkClick, this);
				} else {
					item.on('focus', this.onFocus, this);
					item.on('dblclick', this.onDblClick, this);
					item.on('change', this.onItemChange, this);
				}
			}
		}
	},

	initItems: function() {
		var itemConfig = {
			setForceFocus: true,
			required: false,
			allowEmpty: this.allowEmpty,
			width: 50
		};
		if (this.editMode) {
			this.initEditMode(itemConfig);
		} else {
			this.initDisplayMode(itemConfig);
		}
	},

	initEditMode: function(itemConfig) {
		var items = this.items = [];
		var currency = this.currentCurrency;
		var baseCurrency = this.baseCurrency;
		var itemsEditorsIds = this.itemsIds;
		var editorConfig = Ext.apply({}, {
			canFocusElement: true,
			hidePrimaryToolButton: true,
			cls: 'x-form-multicurrencyedit',
			wrapClass: 'x-form-multicurrencyedit'
		}, itemConfig);
		var numberEditConfig = Ext.apply({}, {
			borders: {
				left: '0px'
			},
			width: '100%',
			cls: 'x-form-multicurrencyedit',
			canFocusElement: true,
			minValue: 0
		}, editorConfig);
		var isSymbolPositionLeft = currency.symbolPosition === 'left';
		var currencySymbolEditorWrapClass = 'x-form-multicurrencyedit';
		var currencySymbolEditorMarginLeft = 1;
		var currentCurrencyValueEditorWrapClass = 'x-form-multicurrencyedit';
		var currentCurrencyValueEditorMarginLeft = 1;
		if (isSymbolPositionLeft) {
			currentCurrencyValueEditorWrapClass = 'x-form-multicurrencyedit-first-editor';
			currentCurrencyValueEditorMarginLeft = 0;
		} else {
			currencySymbolEditorWrapClass = 'x-form-multicurrencyedit-first-editor';
			currencySymbolEditorMarginLeft = 0;
		}
		var currencySymbolEditor = new Terrasoft.ComboBox(Ext.apply({}, {
			id: this.id + '_' + itemsEditorsIds.currentCurrencySymbol,
			primaryToolbuttonImageCls: 'multicurrencyedit-combobox-ico-btn-select',
			itemId: itemsEditorsIds.currentCurrencySymbol,
			hidePrimaryToolButton: false,
			marginLeft: currencySymbolEditorMarginLeft,
			wrapClass: currencySymbolEditorWrapClass,
			width: 45,
			minListWidth: 60,
			enabled: this.getIsEditorEnabled(itemsEditorsIds.currentCurrencySymbol),
			value: currency.code
		}, editorConfig));
		currencySymbolEditor.on('render', this.onItemRender, this);
		currencySymbolEditor.dataProvider = new Terrasoft.combobox.MultiCurrencyDataProvider({
			dataService: this.dataService,
			dataGetMethod: this.getCurrenciesDataMethod,
			processResponseData: this.processGetCurrenciesResponse.createDelegate(this)
		});
		currencySymbolEditor.on('rendercomplete', function(combobox) {
			var displayValue = this.getCurrencySymbol(currency);
			combobox.el.dom.value = displayValue == this.labelCaptions.notSetCurrencySymbol ? '' : displayValue;
			combobox.hiddenField.value = currency.uid;
		}, this);
		currencySymbolEditor.on('select', function(editor, recordData, index, oldValue) {
			var baseCurrencyUId = this.baseCurrencyUId;
			var needRebuild = false;
			if (this.isMultiCurrencyMode()) {
				needRebuild = oldValue === baseCurrencyUId;
			} else {
				needRebuild = oldValue !== baseCurrencyUId;
			}
			if (needRebuild) {
				this.rebuild();
				var symbolEditor = this.getEditorByItemId(itemsEditorsIds.currentCurrencySymbol);
				symbolEditor.focus();
			}
		}, this);
		var value = this.getValue();
		var currentCurrencyValueEditor = new Terrasoft.FloatEdit(Ext.apply({}, {
			width: '40%',
			id: this.id + '_' + itemsEditorsIds.currentCurrencyValue,
			itemId: itemsEditorsIds.currentCurrencyValue,
			marginLeft: currentCurrencyValueEditorMarginLeft,
			wrapClass: currentCurrencyValueEditorWrapClass,
			enabled: this.getIsEditorEnabled(itemsEditorsIds.currentCurrencyValue),
			value: value.currentCurrencyValue
		}, numberEditConfig));
		currentCurrencyValueEditor.on('render', this.onItemRender, this);
		if (isSymbolPositionLeft) {
			items.push(currencySymbolEditor);
			items.push(currentCurrencyValueEditor);
		} else {
			items.push(currentCurrencyValueEditor);
			items.push(currencySymbolEditor);
		}
		if (this.isMultiCurrencyMode()) {
			var labelConfig = Ext.apply({}, this.labelConfig, itemConfig);
			var labelCaptions = this.labelCaptions;
			var rateLabel = new Terrasoft.Label(Ext.apply({}, {
				id: this.id + '_' + itemsEditorsIds.rateLabel,
				itemId: itemsEditorsIds.rateLabel,
				caption: labelCaptions.rate
			}, labelConfig));
			rateLabel.on('render', this.onItemRender, this);
			items.push(rateLabel);
			var rateEditor = new Terrasoft.FloatEdit(Ext.apply({}, {
				width: 40,
				id: this.id + '_' + itemsEditorsIds.currentCurrencyRate,
				itemId: itemsEditorsIds.currentCurrencyRate,
				enabled: this.getIsEditorEnabled(itemsEditorsIds.currentCurrencyRate),
				value: value.rate
			}, numberEditConfig));
			rateEditor.on('render', this.onItemRender, this);
			items.push(rateEditor);
			var equalsLabel = new Terrasoft.Label(Ext.apply({}, {
				id: this.id + '_' + itemsEditorsIds.equalsLabel,
				itemId: itemsEditorsIds.equalsLabel,
				caption: labelCaptions.equals
			}, labelConfig));
			equalsLabel.on('render', this.onItemRender, this);
			items.push(equalsLabel);
			var baseCurrencyValueEditor = new Terrasoft.FloatEdit(Ext.apply({}, {
				width: '40%',
				id: this.id + '_' + itemsEditorsIds.baseCurrencyValue,
				itemId: itemsEditorsIds.baseCurrencyValue,
				enabled: this.getIsEditorEnabled(itemsEditorsIds.baseCurrencyValue),
				value: value.baseCurrencyValue
			}, numberEditConfig));
			baseCurrencyValueEditor.on('render', this.onItemRender, this);
			var baseCurrencySymbol = new Terrasoft.Label(Ext.apply({}, {
				id: this.id + '_' + itemsEditorsIds.baseCurrencySymbol,
				itemId: itemsEditorsIds.baseCurrencySymbol,
				caption: this.getCurrencySymbol(baseCurrency)
			}, labelConfig));
			baseCurrencySymbol.on('render', this.onItemRender, this);
			if (baseCurrency.symbolPosition == 'left') {
				items.push(baseCurrencySymbol);
				items.push(baseCurrencyValueEditor);
			} else {
				items.push(baseCurrencyValueEditor);
				items.push(baseCurrencySymbol);
			}
		}
		items[items.length - 1].marginRight = 1;
	},

	initDisplayMode: function(itemConfig) {
		this.items = [];
		var value = this.getValue();
		var itemsIds = this.itemsIds;
		var currency = this.currentCurrency;
		var baseCurrency = this.baseCurrency;
		var showTrailingZeros = this.showTrailingZeros;
		var labelConfig = Ext.apply(itemConfig, {
			autoWidth: true,
			itemId: 'currencyDisplayModeValues',
			id: this.id + '_displayLabel',
			marginLeft: 4,
			canFocusElement: true,
			wrapClass: 'x-form-multicurrencyedit'
		});
		var linkConfig = {
			url: '',
			cls: 'x-label-link-multicurrencyedit',
			imageCls: ''
		};
		var linksCfg = [];
		var currencySymbolConfig = Ext.apply({}, {
			linkId: itemsIds.currentCurrencySymbol,
			caption: this.getCurrencySymbol(currency)
		}, linkConfig);
		var currencyValueConfig = Ext.apply({}, {
			linkId: itemsIds.currentCurrencyValue,
			caption: Terrasoft.Math.getDisplayValue(value.currentCurrencyValue, {showTrailingZeros: showTrailingZeros})
		}, linkConfig);
		var linkCaption =
			this.getCurrencyTemplate(currency, itemsIds.currentCurrencyValue, itemsIds.currentCurrencySymbol);
		linksCfg.push(currencySymbolConfig);
		linksCfg.push(currencyValueConfig);
		if (this.isMultiCurrencyMode()) {
			var currencyRateConfig = Ext.apply({}, {
				linkId: itemsIds.currentCurrencyRate,
				caption: Terrasoft.Math.getDisplayValue(value.rate, {showTrailingZeros: showTrailingZeros})
			}, linkConfig);
			var baseCurrencyValueConfig = Ext.apply({}, {
				linkId: itemsIds.baseCurrencyValue,
				caption: Terrasoft.Math.getDisplayValue(value.baseCurrencyValue, {showTrailingZeros: showTrailingZeros})
			}, linkConfig);
			var baseCurrencySymbolConfig = Ext.apply({}, {
				linkId: itemsIds.baseCurrencySymbol,
				caption: this.getCurrencySymbol(baseCurrency)
			}, linkConfig);
			var labelCaptions = this.labelCaptions;
			linkCaption +=
				String.format('{0}{{1}}{2}', labelCaptions.rate, itemsIds.currentCurrencyRate, labelCaptions.equals);
			linkCaption +=
				this.getCurrencyTemplate(baseCurrency, itemsIds.baseCurrencyValue, itemsIds.baseCurrencySymbol, false);
			linksCfg.push(currencyRateConfig);
			linksCfg.push(baseCurrencySymbolConfig);
			linksCfg.push(baseCurrencyValueConfig);
		}
		for(var linkIndex in linksCfg) {
			var linkCfg = linksCfg[linkIndex];
			if (this.getIsEditorEnabled(linkCfg.linkId) == false) {
				linkCfg.cls += ' x-label-link-disabled';
			}
		}
		labelConfig.linksCfg = linksCfg;
		labelConfig.caption = linkCaption;
		var displayLabel = new Terrasoft.Label(labelConfig);
		displayLabel.on('render', this.onItemRender, this);
		this.items[0] = displayLabel;
	},

	initValue: function() {
		try {
			this.valueInit = false;
			var dataSource = this.dataSource;
			if (!dataSource || !dataSource.activeRow) {
				return;
			}
			this.iterateValueProperties(function (propertyName) {
				var value = this.getColumnValueByPropertyName(propertyName);
				if (this.checkValue(value, propertyName)) {
					this.setValue(value, propertyName, true);
				}
			});
		} finally {
			this.valueInit = true;
		}
	},

	getValuePropertyNameByItemId: function(itemId) {
		var editorsMap = this.editorsMap;
		for (var propertyName in editorsMap) {
			if (!editorsMap.hasOwnProperty(propertyName)) {
				continue;
			}
			if (propertyName === itemId) {
				return editorsMap[propertyName];
			}
		}
		return null;
	},

	getEditorByValuePropertyName: function(valuePropertyName) {
		var editorId = this.getEditorIdByValuePropertyName(valuePropertyName);
		return this.getEditorByItemId(editorId);
	},

	getEditorIdByValuePropertyName: function(valuePropertyName) {
		var editorsMap = this.editorsMap;
		for (var propertyName in editorsMap) {
			if (!editorsMap.hasOwnProperty(propertyName)) {
				continue;
			}
			var editorMap = editorsMap[propertyName];
			if (editorMap === valuePropertyName) {
				return propertyName;
			}
		}
		return null;
	},

	getEditorByItemId: function(itemId) {
		var items = this.items;
		for (var i = 0, itemsLength = items.length; i < itemsLength; i++) {
			var item = items[i];
			if (item.canFocusElement !== true) {
				continue;
			}
			if (item.itemId === itemId) {
				return item;
			}
		}
		return null;
	},

	getCurrencySymbol: function(currency) {
		var notSetCurrencySymbol = this.labelCaptions.notSetCurrencySymbol;
		if (Ext.isEmptyObj(currency)) {
			return notSetCurrencySymbol;
		}
		if (!Ext.ux.GUID.isGUID(currency.uid)) {
			return notSetCurrencySymbol;
		}
		if (Ext.ux.GUID.isEmptyGUID(currency.uid)) {
			return notSetCurrencySymbol;
		}
		if (!Ext.isEmpty(currency.symbol)) {
			return currency.symbol;
		}
		if (!Ext.isEmpty(currency.shortName)) {
			return currency.shortName;
		}
		if (!Ext.isEmpty(currency.code)) {
			return currency.code;
		}
		return null;
	},

	getCurrencyTemplate: function(currencyConfig, currencyValueId, currencySymbolId, showCurrencySymbolAsLink) {
		var template;
		var symbolTemplate;
		var currencySymbol;
		if (showCurrencySymbolAsLink !== false) {
			symbolTemplate = '{{1}}';
			currencySymbol = currencySymbolId;
		} else {
			symbolTemplate = '{1}';
			currencySymbol = this.getCurrencySymbol(currencyConfig);
		}
		if (currencyConfig.symbolPosition == 'left') {
			template = symbolTemplate + '{{0}}';
		} else {
			template = '{{0}}' + symbolTemplate;
		}
		return String.format(template, currencyValueId, currencySymbol);
	},

	showLoadMask: function() {
		if (!this.rendered) {
			return;
		}
		if (this.maskVisible === true) {
			return;
		}
		var isDynamicPosition = true;
		var fitToElement = true;
		var isTransparent = true;
		var opacity = null;
		var isTopElement = false;
		var maskMessage = '';
		var maskCls = 'multicurrency';
		var maskEl = this.el;
		maskEl.mask(maskMessage, maskCls, isDynamicPosition, fitToElement, isTransparent, opacity, isTopElement);
		this.maskVisible = true;
	},

	hideLoadMask: function() {
		if (this.maskVisible === true) {
			var maskEl = this.el;
			maskEl.unmask();
			this.maskVisible = false;
		}
	},

	onItemChange: function(editor, value, oldValue) {
		var valuePropertyName = this.getValuePropertyNameByItemId(editor.itemId);
		if (!value) {
			value = this.getDefaultValue()[valuePropertyName];
		}
		if (valuePropertyName !== this.editorsMap.currentCurrencySymbol) {
			value = Terrasoft.Math.fixPrecision(value);
		}
		this.setValue(value, valuePropertyName);
	},

	fireChangeEvent: function(value, oldValue, propertyName, isInitByEvent) {
		if (!this.valueInit) {
			return;
		}
		var opt = {
			isInitByEvent: isInitByEvent || false
		};
		this.startValue = this.getValue();
		this.fireEvent('change', this, value, oldValue, propertyName, opt);
	},

	onRender: function(ct, position) {
		Terrasoft.MultiCurrencyEdit.superclass.onRender.call(this, ct, position);
		this.el.addClass('x-multiCurrencyEdit');
		this.el.on('click', this.onClick, this);
		this.hiddenField = this.el.insertSibling({
			tag: 'input',
			type: 'hidden',
			name: this.id + '_Value',
			id: this.id + '_Value'
		}, 'before', true);
	},

	onItemRender: function(editor) {
		var el = editor.getResizeEl();
		if (el && !Ext.isEmpty(editor.wrapClass)) {
			el.addClass(editor.wrapClass);
		}
	},

	setElHeight: function() {
	},

	processGetCurrenciesResponse: function(data) {
		var nodes = eval(data);
		Terrasoft.CurrenciesStorage.updateCurrenciesCaptions(nodes);
		var currencies = [];
		Terrasoft.CurrenciesStorage.loadCurrencies(nodes);
		for (var i = 0, len = nodes.length; i < len; i++) {
			var entityValues = nodes[i];
			currencies.push([
					entityValues.uid,
					Ext.util.Format.htmlEncode(entityValues.caption)
				]);
		}
		return currencies;
	},

	getIsEditorEnabled: function(itemId) {
		var itemsEditRights = this.itemsEditRights;
		return itemsEditRights[itemId];
	},

	handleNameChanging: function(oldName, name) {
		Terrasoft.MultiCurrencyEdit.superclass.handleNameChanging.call(this, oldName, name, true);
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			item.handleNameChanging(item.id, name + '_' + item.itemId, true);
		}
		this.fireEvent("nameChanged", this, oldName, name);
	},

	checkValue: function(value, propertyName) {
		return !Ext.isEmpty(value, false)
			|| (value === null && propertyName === this.editorsMap.currentCurrencySymbol);
	},

	setValue: function(propertyValue, propertyName, isInitByEvent) {
		var oldPropertyValue = this.getValue(propertyName);
		if (propertyValue === oldPropertyValue){
			return;
		}
		this.value[propertyName] = propertyValue;
		if (propertyName === this.editorsMap.currentCurrencySymbol) {
			this.updateCurrency('currentCurrency', propertyValue);
		}
		if (this.rendered) {
			var newValue = this.getValue();
			this.hiddenField.value = Ext.util.JSON.encode(newValue);
			if (this.editMode) {
				var editor = this.getEditorByValuePropertyName(propertyName);
				editor && editor.setValue(newValue[propertyName]);
			} else {
				this.rebuild();
			}
		}
		if (this.valueInit) {
			this.fireChangeEvent(propertyValue, oldPropertyValue, propertyName, isInitByEvent);
		}
		this.validate(true);
	},

	setCurrentCurrencyUId: function(value) {
		this.setValue(value, 'currentCurrencyUId');
	},

	isMultiCurrencyMode: function() {
		var value = Ext.apply({}, this.value, this.defaultValue);
		var currentCurrencyUId = value['currentCurrencyUId'];
		var baseCurrencyUId = this.baseCurrencyUId;
		var isCurrenciesEquals = currentCurrencyUId === baseCurrencyUId;
		if (!this.dataSource) {
			return !isCurrenciesEquals;
		}
		var currentCurrencyUIdColumn = this.getColumnByPropertyName('currentCurrencyUId');
		var currentCurrencyValueColumn = this.getColumnByPropertyName('currentCurrencyValue');
		var baseCurrencyValueColumn = this.getColumnByPropertyName('baseCurrencyValue');
		var rateCurrencyValueColumn = this.getColumnByPropertyName('rate');
		var isCurrencyAndValueColumnsMapped = currentCurrencyUIdColumn != null && currentCurrencyValueColumn != null;
		if (isCurrencyAndValueColumnsMapped && baseCurrencyValueColumn == null && rateCurrencyValueColumn == null) {
			return false;
		}
		return !isCurrenciesEquals;
	},

	setRate: function(value) {
		this.setValue(value, 'rate');
	},

	setBaseCurrencyValue: function(value) {
		this.setValue(value, 'baseCurrencyValue');
	},

	setCurrentCurrencyValue: function(value) {
		this.setValue(value, 'currentCurrencyValue');
	},

	setCurrentCurrencyEditEnabled: function(value) {
		this.setEditorEnabled('currentCurrencySymbol', value);
	},

	setCurrentCurrencyValueEditEnabled: function(value) {
		this.setEditorEnabled('currentCurrencyValue', value);
	},

	setCurrentCurrencyRateEditEnabled: function(value) {
		this.setEditorEnabled('currentCurrencyRate', value);
	},

	setBaseCurrencyValueEditEnabled: function(value) {
		this.setEditorEnabled('baseCurrencyValue', value);
	},

	setEditorEnabled: function(editorId, enabled) {
		this.itemsEditRights[editorId] = enabled;
		if (this.editMode == true) {
			var editor = this.getEditorByItemId(editorId);
			var editorValue = editor == null ? null : editor.getEl().dom.value;
			this.rebuild();
			editor = this.getEditorByItemId(editorId);
			if (editor) {
				editor.focus();
				editorValue && editor.setValue(editorValue);
			}
		} else {
			var linkEl = this.el.child('a[linkid="' + editorId + '"]');
			if (linkEl) {
				linkEl[enabled ? 'removeClass' : 'addClass']('x-label-link-disabled');
			}
		}
	},

	getValue: function(propertyName) {
		var value;
		if (propertyName) {
			value = this.getValue();
			return value[propertyName];
		}
		value = Ext.apply({}, this.value, this.defaultValue);
		return value;
	},

	getDefaultValue: function (propertyName) {
		var value;
		if (propertyName) {
			value = this.getDefaultValue();
			return value[propertyName];
		}
		value = Ext.apply({}, this.defaultValue);
		return value;
	},

	getFirstItem: function() {
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			if (item.canFocusElement) {
				return item;
			}
		}
		return null;
	},

	getLastItem: function() {
		var items = this.items;
		for (var i = items.length - 1; i >= 0; i--) {
			var item = items[i];
			if (item.canFocusElement) {
				return item;
			}
		}
		return null;
	},

	rebuild: function() {
		for (var i = this.items.length - 1; i >= 0; i--) {
			this.items[i].destroy();
			delete this.items[i];
		}
		this.initItems();
		this.unregisterItems();
		this.initItemsEvents();
		this.rerenderItems();
	},

	setEditMode: function (editMode) {
		if (typeof(editMode) !== 'boolean') {
			return;
		}
		this.clearInvalid();
		this.editMode = editMode;
		this.rebuild();
		this.validate(true);
	},

	rerenderItems: function() {
		this.renderItems(this.el);
		this.layoutItems();
	},

	onFocus: function (editor) {
		if (this.designMode === true) {
			return;
		}
		this.startValue = this.getValue();
		if (this.editMode) {
			Terrasoft.MultiCurrencyEdit.superclass.onFocus.call(this);
			return;
		}
		Terrasoft.MultiCurrencyEdit.superclass.onFocus.call(this);
		this.setEditMode(true);
		var focusEditor = this.getFirstItem();
		setTimeout(function() {
			focusEditor.focus(true);
		}, 10);
	},

	onClick: function(e, t) {
		this.onLinkClick();
	},

	onLinkClick: function(linkEl, linkId) {
		if (this.enabled !== true || this.editMode == true) {
			return;
		}
		var currentCurrencyValueLinkId = this.editorsMap.currentCurrencyValue;
		if (this.getIsEditorEnabled(currentCurrencyValueLinkId) == true) {
			linkId = currentCurrencyValueLinkId;
		} else if (linkId == null) {
			var itemsIds = this.itemsIds;
			var itemsEditRights = this.itemsEditRights;
			for (var itemId in itemsIds) {
				if (itemsIds.hasOwnProperty(itemId) && itemsEditRights[itemId] != false) {
					linkId = itemId;
					break;
				}
			}
		}
		if (linkId == null) {
			return;
		}
		this.setEditMode(true);
		var focusEditor = this.getEditorByItemId(linkId);
		if (!focusEditor) {
			return;
		}
		focusEditor.focus(true);
		if (this.editMode) {
			var isEnabled = this.getIsEditorEnabled(linkId);
			if (focusEditor.getXType() == 'combo' && this.expandCurrencyListOnFocus === true && isEnabled === true) {
				focusEditor.initList();
				focusEditor.expand();
			}
		}
	},

	checkBlur: function(e) {
		if (!(this.el.contains(e.target) || this.el.dom === e.target) && this.validateBlur(e)) {
			var itemId = this.itemsIds.currentCurrencySymbol;
			var editor = this.getEditorByItemId(itemId);
			if (!editor || !editor.list || !editor.list.contains(e.target)) {
				this.triggerBlur();
			}
		}
	},

	findFocusedEditor: function() {
		if (!this.editMode) {
			return null;
		}
		return Terrasoft.MultiCurrencyEdit.superclass.findFocusedEditor.call(this);
	},

	customFocusElCondition: function(item) {
		return item.canFocusElement === true;
	},

	processFocusedEditor: function(editor) {
		editor.unFocus();
		var valuePropertyName = this.getValuePropertyNameByItemId(editor.itemId);
		var value = editor.getValue();
		if (!value) {
			var defValue = this.getDefaultValue();
			value = defValue[valuePropertyName];
		}
		this.setValue(value, valuePropertyName);
	},

	forceFocus: function() {
		var ownerCt = this.ownerCt;
		if (ownerCt && ownerCt.forceFocus) {
			ownerCt.forceFocus();
		}
		if (this.hidden) {
			this.show();
		}
		if (this.editMode) {
			this.focus();
		} else {
			this.setEditMode(true);
			var focusEditor = this.getFirstItem();
			setTimeout(function() {
				focusEditor.focus(true);
			}, 10);
		}
	},

	triggerBlur: function() {
		Terrasoft.MultiCurrencyEdit.superclass.triggerBlur.call(this);
		if (this.editMode) {
			this.hasFocus = false;
			this.setEditMode(false);
		}
	},

	checkChange: function() {
		var newValue = this.getValue();
		var oldValue = this.startValue;
		this.iterateValueProperties(function(propertyName) {
			var oldPropertyValue = oldValue[propertyName];
			var newPropertyValue = newValue[propertyName];
			if (!newPropertyValue) {
				newPropertyValue = this.getDefaultValue()[propertyName];
			}
			if (oldPropertyValue != newPropertyValue) {
				this.fireChangeEvent(newPropertyValue, oldPropertyValue, propertyName);
			}
		});
	},

	enable: function() {
		Terrasoft.MultiCurrencyEdit.superclass.enable.call(this);
		if (this.editMode !== true) {
			return;
		}
		var itemsIds = this.itemsIds;
		for (var propertyName in itemsIds) {
			if (!itemsIds.hasOwnProperty(propertyName)) {
				continue;
			}
			var itemId = itemsIds[propertyName];
			var editor = this.getEditorByItemId(itemId);
			if (editor) {
				editor[this.getIsEditorEnabled(itemId) ? 'enable' : 'disable']();
			}
		}
	},

	isValuePropertyRequired: function (valuePropertyName) {
		return this.valueRequired[valuePropertyName];
	},

	setRequiredEditor: function(required, valuePropertyName) {
		if (!Ext.isEmpty(valuePropertyName) && this.getValue().hasOwnProperty(valuePropertyName)) {
			this.valueRequired[valuePropertyName] = required;
		}
	},

	validateValuePropertyName: function(value, propertyName) {
		if (!this.isValuePropertyRequired(propertyName)) {
			return true;
		}
		var valueProperty = value[propertyName];
		switch (propertyName) {
			case 'currentCurrencyUId':
				return Ext.ux.GUID.isGUID(valueProperty) && !Ext.ux.GUID.isEmptyGUID(valueProperty);
			case 'currentCurrencyValue':
			case 'baseCurrencyValue':
			case 'rate':
				return !Ext.isEmpty(valueProperty);
			default:
				return false;
		}
	},

	isRequired: function() {
		return this.isValuePropertyRequired(this.itemsIds.currentCurrencyValue);
	},

	validateValue: function(value) {
		if (!this.isRequired()) {
			return true;
		}
		var isValid = true;
		this.iterateValueProperties(function(valuePropertyName) {
			var isItemValid = this.validateValuePropertyName(value, valuePropertyName);
			if (!isItemValid && this.editMode) {
				var item = this.getEditorByValuePropertyName(valuePropertyName);
				item.markInvalid && item.markInvalid(this.blankText);
			}
			isValid = isValid && isItemValid;
		});
		if (!isValid) {
			this.markInvalid(this.blankText);
		}
		return isValid;
	},

	markInvalid: function(msg) {
		if (!this.rendered || !this.container) {
			return;
		}
		if (this.editMode) {
			return;
		}
		var el = this.el;
		el.addClass(this.invalidClass);
		if (this.preventMark || this.isRequired()) {
			return;
		}
		msg = msg || this.invalidText;
		Ext.FormValidator.addMessage(Ext.Link.applyLinks(String.format(msg, this.id), this.getLinkConfig()));
		this.fireEvent('invalid', this, msg);
	},

	clearInvalid: function() {
		if (!this.rendered || !this.container) {
			return;
		}
		if (this.editMode) {
			Terrasoft.MultiCurrencyEdit.superclass.clearInvalid.call(this);
			return;
		}
		var el = this.el;
		el.removeClass(this.invalidClass);
		if (this.preventMark) {
			return;
		}
		var vmp = Ext.FormValidator.validationMessagePanel;
		if (vmp = Ext.getCmp(vmp)) {
			vmp.remove(this.id + '_invalid');
		}
		this.fireEvent('valid', this);
	},

	iterateValueProperties: function(action) {
		if (typeof(action) !== 'function') {
			return;
		}
		var value = this.getValue();
		for (var propertyName in value) {
			if (!value.hasOwnProperty(propertyName)) {
				continue;
			}
			Array.prototype.shift.call(arguments);
			Array.prototype.unshift.call(arguments, propertyName);
			if (action.apply(this, arguments) === false) {
				break;
			}
		}
	},

	getColumnUIdByPropertyName: function(propertyName) {
		var columnUId = null;
		if (propertyName) {
			columnUId = this[propertyName + 'ColumnUId'];
			columnUId = this.getColumnUId(columnUId);
		}
		return columnUId;
	},

	getColumnByPropertyName: function(propertyName) {
		if (!this.dataSource) {
			return null;
		}
		var columnUId = this.getColumnUIdByPropertyName(propertyName);
		return this.getColumnBase(columnUId);
	},

	getColumnValueByPropertyName: function(propertyName) {
		var dataSource = this.dataSource;
		var columnUId = this.getColumnUIdByPropertyName(propertyName);
		return columnUId ? dataSource.getColumnValueByColumnUId(columnUId) : null;
	},

	onChange: function(o, columnValue, oldColumnValue, propertyName, opt) {
		if (opt && opt.isInitByEvent) {
			return;
		}
		if (!this.dataSource) {
			return;
		}
		var column = this.getColumnByPropertyName(propertyName);
		if (column) {
			this.dataSource.setColumnValue(column.name, columnValue);
		}
	},

	onDataSourceDataChanged: function(record, columnName) {
		if (!record) {
			return;
		}
		this.iterateValueProperties(function(propertyName) {
			var column = this.getColumnByPropertyName(propertyName);
			if (column && columnName == column.name) {
				var columnValue = record.getColumnValue(columnName);
				if (this.checkValue(columnValue, propertyName)) {
					this.setValue(columnValue, propertyName, true);
				}
				return false;
			}
			return true;
		});
	},

	onDataSourceLoaded: function(dataSource) {
		if (!this.dataSource.activeRow) {
			return;
		}
		this.iterateValueProperties(function(propertyName) {
			var columnUId = this.getColumnUIdByPropertyName(propertyName);
			if (!columnUId) {
				return;
			}
			var propertyValue = this.getColumnValueByPropertyName(propertyName);
			if (this.checkValue(propertyValue, propertyName)) {
				this.setValue(propertyValue, propertyName, true);
			}
		});
	},

	onDataSourceActiveRowChanged: function(dataSource, primaryColumnValue) {
		this.onDataSourceLoaded(dataSource);
	},

	onDataSourceActiveRowValidated: function(columnName, isValid, extrsMessage) {
		var valuePropertyName;
		this.iterateValueProperties(function(propertyName) {
			var column = this.getColumnByPropertyName(propertyName);
			if (column && columnName == column.name) {
				valuePropertyName = propertyName;
				return false;
			}
			return true;
		});
		if (valuePropertyName) {
			if (this.editMode) {
				var editor = this.getEditorByValuePropertyName(valuePropertyName);
				if (editor) {
					isValid ? editor.clearInvalid() : editor.markInvalid();
					editor.serverValidationResult = isValid;
					var items = editor.items;
					for (var i = 0, l = items.length; i < l; i++) {
						items[i].serverValidationResult = isValid;
					}
				}
			} else {
				isValid ? this.clearInvalid() : this.markInvalid();
			}
			this.serverValidationResult = isValid;
			this.validationMessage = extrsMessage;
		}
	},

	onDataSourceStructureLoaded: function(dataSource) {
		Terrasoft.MultiCurrencyEdit.superclass.onDataSourceStructureLoaded.call(this, dataSource);
		if (this.rendered) {
			this.rebuild();
		}
	},

	setPropertiesByColumn: function() {
		this.iterateValueProperties(function(propertyName) {
			var column = this.getColumnByPropertyName(propertyName);
			if (!column) {
				return;
			}
			var editorId = this.getEditorIdByValuePropertyName(propertyName);
			this.itemsEditRights[editorId] = (this.itemsEditRights[editorId] == true) && this.dataSource.canEditColumn(column);
			var editor = this.getEditorByItemId(editorId);
			var columnRequired = column.required;
			if (columnRequired !== undefined) {
				this.setRequiredEditor(columnRequired, propertyName);
				if (editor && editor.isDefaultPropertyValue('required')) {
					editor.setRequired(columnRequired);
				}
			}
			if (propertyName == this.captionColumnPropertyName) {
				if (this.isDefaultPropertyValue('caption') && column.caption !== undefined) {
					this.setCaption(column.caption);
				}
			}
		});
		this.setRequired(this.isRequired());
	},

	updateCurrency: function(propertyName, currencyUId, noLoad) {
		if (!propertyName || !currencyUId) {
			return;
		}
		var currency = this[propertyName];
		if (currency.uid == currencyUId) {
			return;
		}
		var newCurrency = Ext.ux.GUID.isEmptyGUID(currencyUId) ?
			this.defaultCurrency :
			Terrasoft.CurrenciesStorage.findCurrencyByUId(currencyUId);
		if (newCurrency) {
			this[propertyName] = newCurrency;
		} else if (!noLoad) {
			var provider = new Terrasoft.MultiCurrencyDataProvider();
			provider.on('success', function(data, response) {
				var nodes = eval(data);
				Terrasoft.CurrenciesStorage.updateCurrenciesCaptions(nodes);
				Terrasoft.CurrenciesStorage.loadCurrencies(nodes);
				this.updateCurrency(propertyName, currencyUId, true);
				this.rebuild();
				this.hideLoadMask();
			}, this);
			provider.on('failure', function(response) {
				this.hideLoadMask();
			}, this);
			this.showLoadMask();
			var url = Terrasoft.getWebServiceUrl(this.dataService, this.getCurrenciesDataMethod);
			provider.loadData(url);
		}
	}
});

Ext.reg('multicurrencyedit', Terrasoft.MultiCurrencyEdit);

Terrasoft.MultiCurrencyDataProvider = function(config) {
	Ext.apply(this, config);
	Terrasoft.MultiCurrencyDataProvider.superclass.constructor.call(this);
	this.initializeProvider();
};

Ext.extend(Terrasoft.MultiCurrencyDataProvider, Ext.util.Observable, {
	isProviderInitialized: false,
	requestTimeout: 500,
	requestStarted: false,

	initializeProvider: function() {
		if (this.isProviderInitialized) {
			return;
		}
		this.addEvents(
			'success',
			'failure'
		);
		this.isProviderInitialized = true;
	},

	cancelRequest: function() {
		if (this.requestStarted) {
			clearTimeout(this.delayedRequestTimeoutId);
			delete this.delayedRequestTimeoutId;
		}
	},

	loadData: function(url, loadDataParams) {
		if (this.isProviderInitialized !== true) {
			return;
		}
		this.requestStarted = true;
		var dataProvider = this;
		this.delayedRequestTimeoutId = setTimeout(function() {
			dataProvider.request(url, loadDataParams);
		}, this.requestTimeout);
	},

	request: function(url, loadDataParams) {
		Ext.Ajax.request({
			cleanRequest: true,
			method: this.requestMethod,
			url: url,
			success: this.onSuccess,
			failure: this.onFailure,
			scope: this,
			argument: {},
			params: loadDataParams
		});
	},

	onSuccess: function(response) {
		this.requestStarted = false;
		var xmlData = response.responseXML;
		var root = xmlData.documentElement || xmlData;
		var data = root.text || root.textContent;
		this.fireEvent('success', data, response);
	},

	onFailure: function(response) {
		this.requestStarted = false;
		this.fireEvent('failure', response);
	}
});

Terrasoft.combobox.MultiCurrencyDataProvider = Ext.extend(Terrasoft.combobox.WebServiceDataProvider, {
	loadData: function() {
		if (Terrasoft.CurrenciesStorage.isCurrenciesLoaded()) {
			var items = Terrasoft.CurrenciesStorage.getCurrencies();
			if (!this.combobox.isLocalList && !this.combobox.listPrepared) {
				Terrasoft.CurrenciesStorage.updateCurrenciesCaptions(items);
				Terrasoft.CurrenciesStorage.loadCurrencies(items);
			}
			var currencies = [];
			for (var i = 0, len = items.length; i < len; i++) {
				var entityValues = items[i];
				currencies.push([
						entityValues.uid,
						Ext.util.Format.htmlEncode(entityValues.caption)
					]);
			}
			this.updateComboboxStorage(currencies);
			return;
		}
		Terrasoft.combobox.MultiCurrencyDataProvider.superclass.loadData.apply(this, arguments);
	},

	handleResponse: function(response) {
		var xmlData = response.responseXML;
		var root = xmlData.documentElement || xmlData;
		var data = root.text || root.textContent;
		var items = this.processResponseData(data);
		this.updateComboboxStorage(items);
	},

	updateComboboxStorage: function(items) {
		var cb = this.combobox;
		try {
			if (cb.sorted) {
				if (cb.sortFunction) {
					cb.store.setCustomSort(this.displayField, cb.sortFunction);
					cb.sortData();
				} else {
					cb.store.setDefaultSort(this.displayField);
				}
			}
			cb.loadData(items);
		} finally {
			cb.endProcessing();
		}
	}
});

Terrasoft.ClientMultiCurrencyCalculationDataProvider = Ext.extend(Terrasoft.MultiCurrencyDataProvider, {
	cancelRequest: Ext.emptyFn,
	request: Ext.emptyFn,

	initializeProvider: function() {
		if (this.isProviderInitialized) {
			return;
		}
		this.addEvents(
			'success',
			'failure'
		);
		this.isProviderInitialized = true;
	},

	loadData: function(url, params) {
		if (this.isProviderInitialized !== true) {
			return;
		}
		var parameters = params.split('&');
		var value = Ext.util.JSON.decode(parameters[0]);
		var propertyName = Ext.util.JSON.decode(parameters[1]);
		var propertyValue = Ext.util.JSON.decode(parameters[2]);
		this.recalcMultiCurrencyValue(value, propertyName, propertyValue);
	},

	recalcMultiCurrencyValue: function(value, propertyName, propertyValue) {
		if (Ext.isEmpty(propertyValue)) {
			this.fireEvent('failure', Ext.util.JSON.encode(value));
			return;
		}
		value[propertyName] = propertyValue;
		switch (propertyName) {
			case 'currentCurrencyUId':
				var currency = Terrasoft.CurrenciesStorage.findCurrencyByUId(propertyValue);
				value.currentCurrencyUId = currency.uid;
				value.rate = propertyValue = currency.rate;
				value.baseCurrencyValue = Terrasoft.Math.fixPrecision(value.currentCurrencyValue / propertyValue);
				break;
			case 'rate':
				value.baseCurrencyValue = Terrasoft.Math.fixPrecision(value.currentCurrencyValue / propertyValue);
				break;
			case 'currentCurrencyValue':
				value.baseCurrencyValue = Terrasoft.Math.fixPrecision(propertyValue / value.rate);
				break;
			case 'baseCurrencyValue':
				value.currentCurrencyValue = Terrasoft.Math.fixPrecision(value.rate * value.baseCurrencyValue);
				break;
			default:
		}
		this.fireEvent('success', Ext.util.JSON.encode(value));
	}
});

Terrasoft.CurrenciesStorage = function() {
	var currenciesStorage = [];

	return {
		isCurrenciesLoaded: function() {
			return currenciesStorage.length != 0;
		},

		getCurrencies: function() {
			return currenciesStorage;
		},

		loadCurrencies: function(currencies) {
			currenciesStorage = currencies;
		},

		findCurrencyByUId: function(uid) {
			for (var i = 0, length = currenciesStorage.length; i < length; i++) {
				var currency = currenciesStorage[i];
				if (currency.uid == uid) {
					return currency;
				}
			}
			return null;
		},

		add: function(currency) {
			if (this.findCurrencyByUId(currency.uid) !== null) {
				return;
			}
			currenciesStorage.push(currency);
		},
		
		updateCurrenciesCaptions: function(currencies) {
			if (!currencies) {
				return;
			}
			for (var i = 0, length = currencies.length; i < length; i++) {
				var currency = currencies[i];
				currency.caption = this.getCurrencyCaption(currency);
			}
		},

		getCurrencyCaption: function(currency) {
			if (!Ext.isEmpty(currency.shortName)) {
				return currency.shortName;
			}
			if (!Ext.isEmpty(currency.symbol)) {
				return currency.symbol;
			}
			if (!Ext.isEmpty(currency.code)) {
				return currency.code;
			}
			return null;
		}
	};
}();