Terrasoft.TextEdit = Ext.extend(Terrasoft.BaseEdit, {
	autoCompleteEnabled: false,
	searchMinCharCount: 3,
	splitChar: ';',
	showListLoadMask: false,
	moveListToCursor: false,

	listLoadMaskCls: 'x-mask-loading blue',
	listClass: '',
	itemCls: '',
	selectedClass: 'x-combo-selected',
	shadow: 'simple',
	listAlign: 'tl-bl?',

	sourceSchemaUId: null,
	sourceSchemaColumnName: '',
	filterComparisonType: Terrasoft.FilterComparisonType.START_WITH,
	dataService: 'Services/DataService',
	dataGetMethod: 'GetEntitySchemaData',
	loadDataDelay: 500,
	deferExpand: 10,

	maxHeight: 300,
	maxListWidth: 300,
	list: null,
	selectedIndex: 0,
	listDataStore: null,

	initComponent: function() {
		this.loadDataMessage = Ext.StringList('WC.Common').getValue('LoadMask.Loading');
		Terrasoft.TextEdit.superclass.initComponent.call(this);
		this.addEvents(
			'expand',
			'collapse'
		);
		var storeConfig = {};
		storeConfig.fields = ['value', 'text'];
		storeConfig.data = [];
		this.listDataStore = new Ext.data.SimpleStore(storeConfig);
	},

	onRender: function(ct, position) {
		Terrasoft.TextEdit.superclass.onRender.call(this, ct, position);
		if (this.autoCompleteEnabled === true) {
			this.enableAutoComplete(true);
		}
	},

	enableAutoComplete: function(autoCompleteEnabled) {
		this.autoCompleteEnabled = autoCompleteEnabled;
		this.el[autoCompleteEnabled ? 'on' : 'un'](Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress",
			this.onAutocompleteKeyDown, this);
	},

	onAutocompleteKeyDown: function(event) {
		if (this.isSpecialKey(event)) {
			this.onSpecialKeyDown.defer(this.deferExpand, this, [event], 1);
		} else {
			this.onKeyDown.defer(this.deferExpand, this, [event], 1);
		}
	},

	onSpecialKeyDown: function() {
		var event = arguments[(Ext.isGecko ? 1 : 0)];
		var key = event.getKey();
		switch (key) {
			case Ext.EventObject.ESC:
				this.collapse();
				break;
			case Ext.EventObject.ENTER:
				this.selectCurrentItem();
				break;
			case Ext.EventObject.UP:
				this.selectPrev();
				break;
			case Ext.EventObject.DOWN:
				this.selectNext();
				break;
			default:
				return;
		}
		return;
	},

	isSpecialKey: function(event) {
		if (event.isSpecialKey()) {
			return true;
		}
		var isSpecialKey;
		var key = event.getKey();
		switch (key) {
			case Ext.EventObject.F1:
			case Ext.EventObject.F2:
			case Ext.EventObject.F3:
			case Ext.EventObject.F4:
			case Ext.EventObject.F5:
			case Ext.EventObject.F6:
			case Ext.EventObject.F7:
			case Ext.EventObject.F8:
			case Ext.EventObject.F9:
			case Ext.EventObject.F10:
			case Ext.EventObject.F11:
			case Ext.EventObject.F12:
				isSpecialKey = true;
				break;
			default:
				isSpecialKey = false;
		}
		return isSpecialKey;
	},

	fireKey: function(e) {
		if (!this.isExpanded()) {
			Terrasoft.TextEdit.superclass.fireKey.call(this, e);
		}
	},

	onKeyDown: function(event) {
		if (this.autoCompleteEnabled !== true) {
			return;
		}
		if (this.hasFocus !== true) {
			return;
		}
		var value = this.getValue();
		var filterValue = this.getFilterValue(value);
		var list = this.list;
		if (filterValue.length >= this.searchMinCharCount) {
			var dataProvider = this.dataProvider;
			if (!list) {
				this.createList();
				list = this.list;
				this.on('expand', this.onListExpand, this);
				dataProvider = this.dataProvider = new Terrasoft.TextEditDataProvider({
					requestTimeout: this.loadDataDelay
				});
				dataProvider.on('success', this.onSuccess, this);
				dataProvider.on('failure', this.onFailure, this);
			}
			var url = Terrasoft.getWebServiceUrl(this.dataService, this.dataGetMethod);
			dataProvider.cancelRequest();
			dataProvider.loadData(url, this.getLoadDataParams());
			if (this.isExpanded()) {
				if (this.showListLoadMask == true) {
					list.mask(this.loadDataMessage, this.listLoadMaskCls, true, false, true);
				}
				this.alignList();
			}
		} else if (list) {
			this.collapse();
		}
	},

	getFilterValue: function(checkValue) {
		var value = checkValue || this.getValue();
		var values = value.split(this.splitChar);
		var length = values.length;
		if (length == 0) {
			return '';
		}
		var filterValue = values[length - 1];
		return filterValue.replace(/^\s+|/g, ""); // trimStart
	},

	getLoadDataParams: function() {
		var value = this.getValue();
		var filterValue = this.getFilterValue(value, this.splitChar);
		var params = [];
		var columnNames = [];
		var filters = [
			{
				comparisonType: this.filterComparisonType,
				leftExpressionColumnPath: this.sourceSchemaColumnName,
				rightExpressionParameterValues: [filterValue],
				useDisplayValue: false
			}
		];
		var rowCount = '';
		params.push("schemaUId=", this.sourceSchemaUId, "&");
		params.push("columnNames=", Ext.util.JSON.encode(columnNames), "&");
		params.push("filters=", Ext.encode(filters), "&");
		params.push("rowCount=", rowCount);
		return params.join("");
	},

	onSuccess: function(data, response) {
		var items = [];
		var listData = [];
		if (data) {
			var nodes = eval("(" + data + ")");
			for (var i = 0, len = nodes.length; i < len; i++) {
				var entityValues = nodes[i];
				items.push([]);
				listData.push([]);
				for (var item in entityValues) {
					listData[i].push(Ext.util.Format.htmlDecode(entityValues[item]));
					items[i].push(entityValues[this.sourceSchemaColumnName]);
				}
			}
		}
		if (items) {
			this.listDataStore.loadData(listData);
		}
		this.bindListStore(items);
		this.expand();
	},

	onFailure: function(response) {
		this.bindListStore();
	},

	bindListStore: function(items) {
		var storeConfig = {};
		storeConfig.fields = ['value', 'text'];
		storeConfig.data = [];
		var store = new Ext.data.SimpleStore(storeConfig);
		if (items) {
			store.loadData(items);
		}
		var list = this.list;
		this.bindStore(store, true);
		if (this.showListLoadMask === true) {
			list.unmask();
		}
	},

	onListExpand: function() {
		this.alignList();
	},

	createList: function() {
		var cls = 'x-combo-list';
		this.displayField = 'text';
		this.itemSelector = undefined;
		this.assetHeight = 0;
		var list = this.list = new Ext.Layer({
			shadow: this.shadow,
			cls: [cls, this.listClass].join(' '),
			constrain: false
		});
		list.setWidth(this.maxListWidth);
		list.swallowEvent('mousewheel');
		list.scrollBar = Ext.ScrollBar.insertScrollBar(list.id, { useHScroll: false });
		var innerList = this.innerList = list.scrollBar.contentWrap;
		innerList.addClass(cls + '-inner');
		innerList.on('mouseover', this.onViewOver, this);
		innerList.on('mousemove', this.onViewMove, this);
		innerList.setWidth(this.maxListWidth - list.getFrameWidth('lr'));
		var itemCls = Ext.isEmpty(this.itemCls) ? '' : ' ' + this.itemCls;
		if (!this.tpl) {
			this.tpl = '<tpl for="."><div class="' + cls +
				'-item' + itemCls + '">{' + this.displayField + '}</div></tpl>';
		}
		this.view = new Ext.DataView({
			applyTo: this.innerList,
			tpl: this.tpl,
			singleSelect: true,
			selectedClass: this.selectedClass,
			itemSelector: this.itemSelector || '.' + cls + '-item'
		});
		this.view.on('click', this.onViewClick, this);
	},

	onViewMove: function(e, t) {
		this.inKeyMode = false;
	},

	onViewOver: function(e, t) {
		if (this.inKeyMode) {
			return;
		}
		var item = this.view.findItemFromChild(t);
		if (item) {
			var index = this.view.indexOf(item);
			this.select(index, false);
		}
	},

	selectPrev: function() {
		this.select(this.selectedIndex - 1);
	},

	selectNext: function() {
		this.select(this.selectedIndex + 1);
	},

	select: function(index, scrollIntoView) {
		if (this.oldIndexForScroll == undefined) {
			this.oldIndexForScroll = 0;
		}
		var ct = this.store.getCount();
		if (ct > 0) {
			var index = index;
			if (index > ct - 1) {
				index = ct - 1;
			}
			if (index < 0) {
				index = 0;
			}
			if (index > this.selectedIndex) {
				var indexForScroll = index - this.getListPageRowCount() + 1;
				if (indexForScroll < 0) {
					indexForScroll = 0;
				}
			} else if (index < this.selectedIndex) {
				indexForScroll = index;
			}
			this.selectedIndex = index;
			this.view.select(index);

			if (scrollIntoView !== false) {
				var el = this.view.getNode(indexForScroll);
				if (el) {
					if ((index > this.oldIndexForScroll + this.getListPageRowCount() - 1) ||
							(index < this.oldIndexForScroll)) {
						this.list.dom.scrollToElement(el, false);
						this.oldIndexForScroll = indexForScroll;
					}
				}
			}
		} else {
			this.selectedIndex = -1;
		}
	},

	getListPageRowCount: function() {
		return parseInt(this.view.all.elements.length * this.getListHeight() / this.innerList.dom.clientHeight);
	},

	getListHeight: function() {
		var inner = this.innerList.dom;
		var pad = this.list.getFrameWidth('tb') + (this.resizable ? this.handleHeight : 0) + this.assetHeight;
		var h = Math.max(inner.clientHeight, inner.offsetHeight, inner.scrollHeight);
		var ha = this.getPosition()[1] - Ext.getBody().getScroll().top;
		var hb = Ext.lib.Dom.getViewHeight() - ha - this.getSize().height;
		var space = Math.max(ha, hb, this.minHeight || 0) - this.list.shadowOffset - pad - 5;
		h = Math.min(h, space, this.maxHeight);
		if (this.view.all.elements.length != 0) {
			var heightOnewRow = parseInt(this.innerList.dom.clientHeight / this.view.all.elements.length);
			var countInList = parseInt(h / heightOnewRow);
			return heightOnewRow * countInList + pad;
		} else {
			return 0;
		}
		//return heightOnewRow * countInList + pad;
	},

	alignList: function() {
		var value = this.getValue();
		var xOffset;
		if (this.moveListToCursor) {
			xOffset = Ext.util.TextMetrics.measure(this.el, value).width;
		} else {
			var lastSplitCharIndex = value.lastIndexOf(this.splitChar);
			var selValue = value.substring(0, lastSplitCharIndex);
			xOffset = Ext.util.TextMetrics.measure(this.el, selValue).width;
		}
		this.list.alignTo(this.wrap, this.listAlign, [xOffset, -1]);
		this.restrictHeight();
		this.restrictWidth();
	},

	onViewClick: function(doFocus) {
		var index = this.view.getSelectedIndexes()[0];
		this.selectItem(index);
	},

	selectItem: function(index) {
		var record = this.listDataStore.getAt(index);
		if (record) {
			var value = this.getValue();
			var startFilterIndex = value.lastIndexOf(this.splitChar);
			var newValue = value;
			if (startFilterIndex == -1) {
				newValue = record.data.text;
			} else {
				newValue = newValue.substring(0, startFilterIndex + 1) + ' ' + record.data.text;
			}
			newValue += this.splitChar + ' ';
			this.setValue(newValue);
			this.collapse();
			this.el.focus();
		}
	},

	selectCurrentItem: function() {
		this.selectItem(this.selectedIndex);
	},

	isExpanded: function() {
		return this.list && this.list.isVisible();
	},

	expand: function() {
		if (this.isExpanded()) {
			return;
		}
		var store = this.store;
		if (store && store.data.length == 0) {
			return;
		}
		this.list.show();
		this.restrictHeight();
		this.restrictWidth();
		this.fireEvent('expand', this);
		this.select(0, true);
		Ext.getDoc().on('mousewheel', this.collapseIf, this);
		Ext.getDoc().on('mousedown', this.collapseIf, this);
	},

	restrictHeight: function() {
		this.innerList.dom.style.height = '';
		this.list.beginUpdate();
		this.list.setHeight(this.getListHeight());
		this.list.endUpdate(false);
		this.list.scrollBar.update();
		var newListWidth = this.list.getWidth() - this.list.getFrameWidth('lr') - this.list.scrollBar.getVScrollWidth();
		this.innerList.setWidth(newListWidth);
	},

	restrictWidth: function(w, h) {
		var maxItemWidth = 0;
		var storeItems = this.store.data.items;
		for (var i = 0; i < storeItems.length; i++) {
			var itemWidth = this.getRawTextWidth(storeItems[i].data.text);
			if (itemWidth > maxItemWidth) {
				maxItemWidth = itemWidth;
			}
		}
		var frameWidth = this.list.getFrameWidth('lr');
		var listItemPaddings = 10;
		maxItemWidth = maxItemWidth + frameWidth + listItemPaddings + this.list.scrollBar.getVScrollWidth();
		var listWidth = (w != undefined) ? w : this.maxListWidth;
		var newWidth;
		if (maxItemWidth <= listWidth) {
			newWidth = maxItemWidth;
		} else {
			newWidth = (this.maxListWidth && this.maxListWidth < maxItemWidth) ? this.maxListWidth : maxItemWidth;
		}
		this.list.setWidth(newWidth);
		this.innerList.setWidth(newWidth - this.list.getFrameWidth('lr'));
		this.list.scrollBar.update();
	},

	getRawTextWidth: function(text) {
		if (text == undefined) {
			return 0;
		}
		var el = Ext.getRawTextWidthEl;
		if (!el) {
			el = Ext.get(document.createElement('div'));
			Ext.getRawTextWidthEl = el;
			var styles = {
				fontFamily: 'tahoma',
				fontSize: '11px'
			};
			el.applyStyles(styles);
		}
		el.dom.innerHTML = text;
		return el.getTextWidth();
	},

	collapseIf: function(event) {
		if (!event.within(this.list)) {
			this.collapse();
		}
	},

	collapse: function() {
		if (!this.isExpanded()) {
			return;
		}
		this.list.hide();
		Ext.getDoc().un('mousewheel', this.collapseIf, this);
		Ext.getDoc().un('mousedown', this.collapseIf, this);
		this.fireEvent('collapse', this);
	},

	onBeforeLoad: function() {
	},

	bindStore: function(store, initial) {
		var storeConfig = {};
		storeConfig.fields = ['value', 'text'];
		storeConfig.data = [];
		this.store = new Ext.data.SimpleStore(storeConfig);
		if (this.store && !initial) {
			this.store.un('beforeload', this.onBeforeLoad, this);
			this.store.un('load', this.onLoad, this);
			this.store.un('loadexception', this.collapse, this);
			if (!store) {
				this.store = null;
				if (this.view) {
					this.view.setStore(null);
				}
			}
		}
		if (store) {
			this.store = Ext.StoreMgr.lookup(store);
			this.store.on('beforeload', this.onBeforeLoad, this);
			this.store.on('load', this.onLoad, this);
			this.store.on('loadexception', this.collapse, this);
			if (this.view) {
				this.view.setStore(store);
			}
		}
		if (this.store.data.items.length == 0) {
			this.collapse();
			return;
		}
		this.restrictHeight();
		this.restrictWidth();
		this.select(0, true);
	}

});

Ext.reg('textedit', Terrasoft.TextEdit);

Terrasoft.TextEditDataProvider = function(config) {
	Ext.apply(this, config);
	Terrasoft.TextEditDataProvider.superclass.constructor.call(this);
	this.initializeProvider();
};

Ext.extend(Terrasoft.TextEditDataProvider, Ext.util.Observable, {
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