Ext.namespace("Terrasoft.combobox");

Terrasoft.ComboBox = Ext.extend(Terrasoft.BaseEdit, {
	defaultAutoCreate: { tag: "input", type: "text", autocomplete: "off" },
	listClass: '',
	selectedClass: 'x-combo-selected',
	shadow: 'simple',
	listAlign: 'tl-bl?',
	maxHeight: 300,
	minHeight: 90,
	toolButtonAction: 'all',
	minChars: 0,
	typeAhead: false,
	queryDelay: 10,
	pageSize: 0,
	selectOnFocus: false,
	resizable: false,
	handleHeight: 8,
	editable: true,
	strictedToItemsList: true,
	allQuery: '',
	mode: 'local',
	minListWidth: 70,
	forceSelection: false,
	typeAheadDelay: 250,
	lazyInit: true,
	valueInit: true,
	initSelect: false,
	valueField: 'value',
	displayField: 'text',
	listPrepared: false,
	sorted: false,
	allowEmpty: true,
	filters: [],
	primaryToolbuttonImageCls: 'combobox-ico-btn-select',
	checkColumnAccess: true,

	initComponent: function() {
		Terrasoft.ComboBox.superclass.initComponent.call(this);
		this.addEvents(
			'load',
			'collapse',
			'beforeselect',
			'select',
			'beforequery',
			'preparefilters',
			'primarytoolbuttonclick',
			'internalpreparelookupfilter'
		);
		this.primaryToolButtonConfig = {
			id: this.primaryToolButtonId(),
			imageCls: this.primaryToolbuttonImageCls
		};
		this.checkDataProperties();
		if (!this.store) {
			var storeConfig = {};
			storeConfig.fields = ['value', 'text'];
			storeConfig.data = [];
			this.store = new Ext.data.SimpleStore(storeConfig);
			this.valueField = 'value';
			this.displayField = 'text';
		} else {
			if (this.sorted) {
				if (this.sortFunction) {
					this.store.setCustomSort('text', this.sortFunction);
					this.sortData();
				} else {
					this.store.setDefaultSort('text');
				}
			}
		}
		this.selectedIndex = -1;
	},

	checkDataProperties: function() {
		this.isLocalList = Boolean(this.store);
		this.isDataControl = ((this.dataSource != undefined) && (this.columnName != undefined || this.getColumnUId(this.columnUId)));
	},

	onRender: function(ct, position) {
		Terrasoft.ComboBox.superclass.onRender.call(this, ct, position);
		this.hiddenName = this.id + '_Value';
		this.hiddenSelectedIndexName = this.id + '_SelIndex';
		if (this.hiddenName) {
			this.hiddenField = this.el.insertSibling({
				tag: 'input',
				type: 'hidden',
				name: this.hiddenName,
				id: (this.hiddenId || this.hiddenName)
			}, 'before', true);
			this.hiddenFieldSelectedIndex = this.el.insertSibling({
				tag: 'input',
				type: 'hidden',
				name: this.hiddenSelectedIndexName,
				id: this.hiddenSelectedIndexName
			}, 'before', true);
			this.el.dom.value = this.startText ? this.startText : '';
			this.hiddenField.value = this.value ? this.value : '';
			this.hiddenFieldSelectedIndex.value = this.selectedIndex ? this.selectedIndex : -1;
		}
		this.getEl().dom.setAttribute("name", this.uniqueName || this.id);
		if (Ext.isGecko) {
			this.el.dom.setAttribute('autocomplete', 'off');
		}
		if (!this.lazyInit) {
			this.initList();
		}
		if (!this.editable) {
			this.editable = true;
			this.setEditable(false);
		}
	},

	initEvents: function() {
		Terrasoft.ComboBox.superclass.initEvents.call(this);
		if (!this.designMode) {
			this.keyNav = new Ext.KeyNav(this.el, {
				"up": function(e) {
					this.inKeyMode = true;
					this.selectPrev();
				},
				"down": function(e) {
					if (!this.isExpanded()) {
						this.onPrimaryToolButtonClick();
					} else {
						this.inKeyMode = true;
						this.selectNext();
					}
				},
				"home": function(e) {
					this.inKeyMode = true;
					this.selectFirst();
				},
				"end": function(e) {
					this.inKeyMode = true;
					this.selectLast();
				},
				"pageUp": function(e) {
					this.inKeyMode = true;
					this.selectPrevPage();
				},
				"pageDown": function(e) {
					this.inKeyMode = true;
					this.selectNextPage();
				},
				"enter": function(e) {
					var index = this.view.getSelectedIndexes()[0];
					var store = this.store;
					if (index === undefined) {
						if (store.getCount() == 0) {
							return;
						}
						index = 0;
						this.select(index, true);
					}
					var r = store.getAt(index);
					var text = r.data.text;
					if (text !== this.getText()) {
						if (text && !Ext.isEmpty(text) || this.allowEmpty) {
							this.el.dom.value = text;
						}
					}
					this.onViewClick();
					this.delayedCheck = true;
					this.unsetDelayCheck.defer(10, this);
				},
				"esc": function(e) {
					this.collapse();
				},
				"tab": function(e) {
					this.monitorTab = false;
					this.onViewClick(false);
					this.triggerBlur();
					return true;
				},
				scope: this,
				doRelay: function(foo, bar, hname) {
					if (hname == 'down' || this.scope.isExpanded()) {
						return Ext.KeyNav.prototype.doRelay.apply(this, arguments);
					}
					return true;
				},
				forceKeyDown: true
			});
		}
		this.queryDelay = Math.max(this.queryDelay || 10,
				this.mode == 'local' ? 10 : 250);
		this.dqTask = new Ext.util.DelayedTask(this.initQuery, this);
		if (this.typeAhead) {
			this.taTask = new Ext.util.DelayedTask(this.onTypeAhead, this);
		}
		if ((this.editable !== false) && (!this.designMode)) {
			this.el.on("keyup", this.onKeyUp, this);
		}
		if (this.forceSelection) {
			this.on('blur', this.doForce, this);
		}
	},

	initValue: function() {
		try {
			this.valueInit = false;
			if (this.isDataControl) {
				var value;
				var text;
				var column = this.getColumn();
				if (column) {
					value = this.getColumnValue();
					text = this.dataSource.getColumnDisplayValue(column.name);
				}
				if (value && text) {
					this.el.dom.value = text;
					this.hiddenField.value = value;
				} else {
					this.setValue(value || "");
				}
				return;
			}
			this.setValue(this.value);
		} finally {
			this.validate(true);
			this.setImageClass(this.imageCls);
			this.valueInit = true;
		}
	},

	onDataSourceLoaded: function(dataSource) {
		this.handleDataSourceLoaded(dataSource);
	},

	onDataSourceRowLoaded: function(dataSource) {
		this.handleDataSourceLoaded(dataSource);
	},

	handleDataSourceLoaded: function(dataSource) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var displayValue = dataSource.getColumnDisplayValue(column.name);
		var value = this.getColumnValue();
		if (displayValue === undefined || displayValue === null) {
			displayValue = "";
		}
		if (!this.rendered) {
			this.value = value;
			return;
		}
		this.el.dom.value = displayValue;
		this.hiddenField.value = this.getColumnValue();
		this.validate(true);
		if (this.checkColumnAccess) {
			this.setEmptyText();
		}
	},

	onDataSourceActiveRowChanged: function(dataSource, primaryColumnValue) {
		this.onDataSourceLoaded(dataSource);
	},

	onDataSourceDataChanged: function(row, columnName) {
		var column = this.getColumn();
		if (!row || !column || (column && columnName != column.name)) {
			return;
		}
		var columnValue = row.getColumnValue(columnName);
		var columnDisplayValue = row.getColumnDisplayValue(columnName);
		this.setValueAndText(columnValue, columnDisplayValue);
	},

	unprepareList: function() {
		this.listPrepared = false;
	},

	loadData: function(data) {
		if (this.store != undefined) {
			this.store.loadData(data);
		}
		this.fireEvent("load", this);
	},

	loadRemoteData: function() {
		if (this.hasListener('internalpreparelookupfilter')) {
			this.fireEvent('internalpreparelookupfilter', this);
		} else {
			this.doLoadRemoteData();
		}
	},

	initList: function() {
		var result = true;
		if (!this.list) {
			var cls = 'x-combo-list';
			this.list = new Ext.Layer({
				shadow: this.shadow, cls: [cls, this.listClass].join(' '), constrain: false
			});
			var lw = this.wrap.getWidth();
			this.list.setWidth(lw);
			this.list.swallowEvent('mousewheel');
			this.assetHeight = 0;
			this.list.scrollBar = Ext.ScrollBar.insertScrollBar(this.list.id, { useHScroll: false });
			this.innerList = this.list.scrollBar.contentWrap;
			this.innerList.addClass(cls + '-inner');
			this.innerList.on('mouseover', this.onViewOver, this);
			this.innerList.on('mousemove', this.onViewMove, this);
			this.innerList.setWidth(lw - this.list.getFrameWidth('lr'));
			if (this.pageSize) {
				this.footer = this.list.createChild({ cls: cls + '-ft' });
				this.pageTb = new Ext.PagingToolbar({
					store: this.store,
					pageSize: this.pageSize,
					renderTo: this.footer
				});
				this.assetHeight += this.footer.getHeight();
			}
			var itemCls = Ext.isEmpty(this.itemCls) ? '' : ' ' + this.itemCls;
			if (!this.tpl) {
				this.tpl = '<tpl for="."><div class="' + cls + '-item' + itemCls + '">{' + this.displayField + ':htmlEncode}</div></tpl>';
			}
			this.view = new Ext.DataView({
				applyTo: this.innerList,
				tpl: this.tpl,
				singleSelect: true,
				selectedClass: this.selectedClass,
				itemSelector: this.itemSelector || '.' + cls + '-item'
			});
			this.view.on('click', this.onViewClick, this);
			this.bindStore(this.store, true);
			if (this.resizable) {
				this.resizer = new Ext.Resizable(this.list, {
					pinned: true, handles: 'se'
				});
				this.resizer.on('resize', function(r, w, h) {
					this.maxHeight = h - this.handleHeight - this.list.getFrameWidth('tb') - this.assetHeight;
					this.restrictWidth();
					this.restrictHeight();
				}, this);
				this[this.pageSize ? 'footer' : 'innerList'].setStyle('margin-bottom', this.handleHeight + 'px');
			}
		}
		if (!this.isLocalList && !this.listPrepared) {
			this.loadRemoteData();
			result = false;
		}
		return result;
	},

	bindStore: function(store, initial) {
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
	},

	onDestroy: function() {
		if (this.view) {
			this.view.el.removeAllListeners();
			this.view.el.remove();
			this.view.purgeListeners();
		}
		if (this.list) {
			this.list.destroy();
		}
		this.bindStore(null);
		Terrasoft.ComboBox.superclass.onDestroy.call(this);
	},

	unsetDelayCheck: function() {
		delete this.delayedCheck;
	},

	fireKey: function(e) {
		if (this.isExpanded()) {
			return;
		}
		var k = e.getKey();
		if (k == e.DELETE && this.enabled !== false) {
			this.clearValue(true);
		}
		if (k == e.ENTER && !this.delayedCheck && this.enabled !== false) {
			this.checkChange();
		}
		if (e.isNavKeyPress() && !this.delayedCheck) {
			this.fireEvent("specialkey", this, e);
		}
		// TODO: убрать этот код, когда будет решена проблема с получением фокуса treegrid-а
		{
			if (!this.mimicing) {
				this.mimicing = true;
				Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, {delay: 10});
			}
		}
	},

	onResize: function(w, h) {
		Terrasoft.ComboBox.superclass.onResize.apply(this, arguments);
		if (this.list) {
			this.restrictWidth(w, h);
		}
	},

	setEditable: function(value) {
		if (value == this.editable) {
			return;
		}
		this.editable = value;
		if (!value) {
			this.el.dom.setAttribute('readOnly', true);
			this.el.on('mousedown', this.onPrimaryToolButtonClick, this);
			this.el.addClass('x-combo-noedit');
		} else {
			this.el.dom.setAttribute('readOnly', false);
			this.el.un('mousedown', this.onPrimaryToolButtonClick, this);
			this.el.removeClass('x-combo-noedit');
		}
	},

	onBeforeLoad: function() {
		this.restrictHeight();
		this.selectedIndex = -1;
	},

	onLoad: function() {
		if (!this.store) {
			return;
		}
		if (this.store.getCount() > 0) {
			if (!this.list) {
				return;
			}
			this.expand();
			this.restrictHeight();
			if (this.lastQuery == this.allQuery) {
				if (this.editable) {
					this.el.dom.select();
				}
				if (!this.selectByValue(this.getValue(), true)) {
					this.select(0, true);
				}
			} else {
				this.selectNext();
				if (this.typeAhead && this.lastKey != Ext.EventObject.BACKSPACE &&
						this.lastKey != Ext.EventObject.DELETE) {
					this.taTask.delay(this.typeAheadDelay);
				}
			}
		} else {
			this.onEmptyResults();
		}
	},

	onTypeAhead: function() {
		if (this.store.getCount() > 0) {
			var r = this.store.getAt(0);
			var newValue = r.data[this.displayField];
			var len = newValue.length;
			var selStart = this.getRawValue().length;
			if (selStart != len) {
				this.setRawValue(newValue);
				this.selectText(selStart, newValue.length);
			}
		}
	},

	onSelect: function(record, index) {
		if ((this.fireEvent('beforeselect', this, record, index) == false)) {
			this.collapse();
			return;
		}
		var oldValue = this.getValue();
		var recordData = record.data[this.valueField];
		if (!recordData) {
			recordData = record.data[this.displayField];
		}
		this.setValue(recordData);
		this.collapse();
		var hiddenFieldSelectedIndex = this.hiddenFieldSelectedIndex;
		if (!Ext.isEmpty(hiddenFieldSelectedIndex)) {
			hiddenFieldSelectedIndex.value = this.getSelectedIndex();
		}
		this.selValue = this.getValue();
		this.selText = this.el.dom.value;
		this.fireSelectEvent(record.data, index, oldValue);
	},

	getValue: function() {
		if (!this.rendered) {
			return this.value;
		}
		var value;
		if (this.hiddenField) {
			value = this.hiddenField.value;
		}
		return Ext.value(value, '');
	},

	getDisplayValue: function() {
		return this.selText || '';
	},

	clearValue: function(fireEvent) {
		var oldValue = this.getValue();
		if (!oldValue || !this.allowEmpty) {
			return;
		}
		if (this.hiddenField) {
			this.hiddenField.value = '';
		}
		this.setRawValue('');
		this.lastSelectionText = '';
		this.applyEmptyText();
		this.value = '';
		this.selText = '';
		if (fireEvent) {
			this.fireSelectEvent(null, -1, oldValue);
		}
	},

	fireSelectEvent: function(record, index, oldValue) {
		this.fireEvent('select', this, Ext.encode(record), index, oldValue);
	},

	onChange: function(o, columnValue, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnBothValues(column.name, columnValue, this.getText());
			}
		}
	},

	setValueAndText: function(value, text) {
		value = value || "";
		var oldValue = this.getValue();
		if (value == oldValue) {
			return;
		}
		if (!this.rendered) {
			this.value = value;
			this.startText = text;
			this.selText = text;
			this.startValue = value;
			return;
		}
		if (!value || !text) {
			this.clearValue(false);
		} else {
			this.hiddenField.value = value;
			this.el.dom.value = text;
			this.value = value;
			this.startText = text;
			this.selText = text;
			this.startValue = value;
		}
		this.validate(true);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = false;
			this.startValue = value;
			this.fireEvent('change', this, value, oldValue, opt);
		}
	},

	setValue: function(value, isInitByEvent) {
		this.value = value;
		if (!this.el) {
			return;
		}
		var oldValue =
			this.useExternalDisplayValue ? null : ((this.valueField == 'value') ? this.getValue() : this.getText());
		if (value == oldValue) {
			var textWasCleared = (this.getText() == "" && this.startText != "");
			if (textWasCleared && this.value) {
				this.el.dom.value = this.startText;
			}
			this.useExternalDisplayValue = false;
			return;
		}
		var text = value;
		try {
			if (this.useExternalDisplayValue) {
				text = this.externalDisplayValue;
				this.useExternalDisplayValue = false;
			} else {
				this.store.clearFilter();
				if (!this.isLocalList && !this.listPrepared) {
					this.loadRemoteData();
					this.store.on('load',
						function() {
							this.setValue(this.value, isInitByEvent);
						},
						this,
						{
							single: true
						}
					);
					return;
				}
				var r = this.findRecord(this.valueField, value);
				if (!r && this.strictedToItemsList) {
					this.clearValue(false);
					return;
				}
				if (r) {
					text = r.data[this.displayField];
				}
				text = Ext.value(text, '');
			}
			this.lastSelectionText = text;
			this.selText = text;
			if (this.hiddenField) {
				this.hiddenField.value = value;
			}
			this.el.dom.value = text;
		} finally {
			this.validate(true);
		}
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.startValue = value;
			this.startText = text;
			this.fireEvent('change', this, value, oldValue, opt);
		}
	},

	addItem: function(value, text) {
		var record = new this.store.reader.recordType({ value: value, text: text }, null);
		if (this.sorted) {
			this.store.addSorted(record);
		} else {
			this.store.add([record]);
		}
	},

	updateItemById: function(id, text) {
		var record = this.store.findByValue(id);
		if (!record) {
			return;
		}
		record.set('text', text);
	},

	updateItemByIndex: function(index, text) {
		var record = this.store.data.items[index];
		if (!record) {
			return;
		}
		record.set('text', text);
	},

	removeItemById: function(id) {
		this.store.remove(this.store.findByValue(id));
	},

	removeItemByIndex: function(index) {
		this.store.remove(this.store.data.items[index]);
	},

	sortData: function() {
		if (this.sorted) {
			this.store.sortData('text');
		}
	},

	clear: function() {
		this.store.removeAll();
	},

	findRecord: function(prop, value) {
		var record;
		if ((prop) && (this.store.getCount() > 0)) {
			this.store.each(function(r) {
				if (r.data[prop] == value) {
					record = r;
					return false;
				}
			});
		}
		return record;
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

	onViewClick: function(doFocus) {
		var index = this.view.getSelectedIndexes()[0];
		var r = this.store.getAt(index);
		if (r) {
			this.onSelect(r, index);
		}
		if (doFocus !== false) {
			this.el.focus();
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
		var heightOnewRow = parseInt(this.innerList.dom.clientHeight / this.view.all.elements.length);
		var countInList = parseInt(h / heightOnewRow);
		return heightOnewRow * countInList + pad;
	},

	restrictHeight: function() {
		this.innerList.dom.style.height = '';
		this.list.beginUpdate();
		this.list.setHeight(this.getListHeight());
		this.list.alignTo(this.wrap, this.listAlign, [0, -1]);
		this.list.endUpdate(false);
		this.list.scrollBar.update();
		this.innerList.setWidth(this.list.getWidth() - this.list.getFrameWidth('lr') - this.list.scrollBar.getVScrollWidth());
	},

	restrictWidth: function(w, h) {
		var maxItemWidth = 0;
		var storeItems = this.store.data.items;
		for (var i = 1; i < storeItems.length; i++) {
			var itemWidth = this.getRawTextWidth(storeItems[i].data.text);
			if (itemWidth > maxItemWidth) {
				maxItemWidth = itemWidth;
			}
		}
		var frameWidth = this.list.getFrameWidth('lr');
		var listItemPaddings = 10;
		maxItemWidth = maxItemWidth + frameWidth + listItemPaddings;
		var listWidth = (w != undefined) ? w : this.wrap.getWidth();
		var newWidth;
		if (maxItemWidth <= listWidth) {
			newWidth = listWidth;
		} else {
			newWidth = (this.maxListWidth && this.maxListWidth < maxItemWidth) ? this.maxListWidth : maxItemWidth;
		}
		var minListWidth = this.minListWidth;
		if (minListWidth && (newWidth < minListWidth)) {
			newWidth = minListWidth;
		}
		this.list.setWidth(newWidth);
		this.innerList.setWidth(newWidth - this.list.getFrameWidth('lr'));
	},

	onEmptyResults: function() {
		this.collapse();
	},

	isExpanded: function() {
		return this.list && this.list.isVisible();
	},

	selectByValue: function(v, scrollIntoView) {
		if (v !== undefined && v !== null) {
			var r = this.findRecord(this.valueField || this.displayField, v);
			if (r) {
				this.select(this.store.indexOf(r), scrollIntoView);
				return true;
			}
		}
		return false;
	},

	select: function(index, scrollIntoView) {
		if (this.oldIndexForScroll == undefined) {
			this.oldIndexForScroll = 0;
		}
		var ct = this.store.getCount();
		if (ct > 0) {
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

	selectNext: function() {
		this.select(this.selectedIndex + 1);
	},

	selectPrev: function() {
		this.select(this.selectedIndex - 1);
	},

	selectFirst: function() {
		this.select(0);
	},

	selectLast: function() {
		this.select(this.store.getCount() - 1);
	},

	selectPrevPage: function() {
		this.select(this.selectedIndex - this.getListPageRowCount());
	},

	selectNextPage: function() {
		this.select(this.selectedIndex + this.getListPageRowCount());
	},

	onKeyUp: function(e) {
		if (!this.enabled) {
			return;
		}
		if (this.editable !== false && !e.isSpecialKey()) {
			this.lastKey = e.getKey();
			if (this.lastKey == e.DELETE) {
				return;
			}
			this.dqTask.delay(this.queryDelay);
		}
	},

	validateBlur: function(e) {
		return !this.list || !this.list.isVisible();
	},

	initQuery: function() {
		if (!this.isLocalList && !this.listPrepared) {
			this.loadRemoteData();
			this.store.on('load', function() { this.initQuery(); }, this, { single: true });
			return;
		}
		if (!this.initList()) {
			this.el.focus();
			return;
		}
		this.doQuery(this.getRawValue());
	},

	doForce: function() {
		if (this.el.dom.value.length > 0) {
			this.el.dom.value =
				this.lastSelectionText === undefined ? '' : this.lastSelectionText;
			this.applyEmptyText();
		}
	},

	doQuery: function(q, forceAll, ignoreBeforeQuery) {
		if (q === undefined || q === null) {
			q = '';
		}
		var qe = {
			query: q,
			forceAll: forceAll,
			combo: this,
			cancel: false
		};
		if (ignoreBeforeQuery !== true) {
			if (this.fireEvent('beforequery', qe) === false || qe.cancel) {
				return false;
			}
		}
		q = qe.query;
		forceAll = qe.forceAll;
		if (forceAll === true || (q.length >= this.minChars)) {
			if (this.lastQuery !== q) {
				this.lastQuery = q;
				if (this.mode == 'local') {
					this.selectedIndex = -1;
					if (forceAll) {
						this.store.clearFilter();
					} else {
						this.store.filter(this.displayField, q);
					}
					this.onLoad();
				}
			} else {
				this.selectedIndex = -1;
				this.onLoad();
			}
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

	collapseIf: function(e) {
		if (!e.within(this.wrap) && !e.within(this.list)) {
			this.collapse();
		}
	},

	expand: function() {
		if (this.isExpanded()) {
			return;
		}
		//this.list.alignTo(this.wrap, this.listAlign, [0, -1]);
		this.list.show();
		this.restrictWidth();
		this.restrictHeight();
		Ext.getDoc().on('mousewheel', this.collapseIf, this);
		Ext.getDoc().on('mousedown', this.collapseIf, this);
	},

	innerPrimaryToolButtonClick: function() {
		Terrasoft.ComboBox.superclass.onPrimaryToolButtonClick.call(this, null, this.el, { t: this.primaryToolButton });
	},

	onPrimaryToolButtonClick: function() {
		if (!this.enabled || !this.primaryToolButton || !this.primaryToolButton.enabled) {
			return;
		}
		if (!this.isLocalList && !this.listPrepared) {
			this.initList();
			return;
		}
		this.innerPrimaryToolButtonClick();
		if (this.isExpanded()) {
			this.collapse();
			this.el.focus();
		} else {
			if (!this.initList()) {
				this.el.focus();
				return;
			}
			if (this.toolButtonAction == 'all') {
				this.doQuery(this.allQuery, true);
			} else {
				this.doQuery(this.getRawValue());
			}
			this.el.focus();
		}
	},

	endEditing: function() {
		this.el.blur();
	},

	getText: function() {
		return this.el.getValue();
	},

	getSelectedItem: function() {
		return { text: this.getText(), value: this.getValue() };
	},

	setValueAndFireSelect: function(v) {
		this.setValue(v);
		var r = this.findRecord(this.valueField, v);

		if (!Ext.isEmpty(r)) {
			var index = this.store.indexOf(r);
			this.initSelect = true;
			this.fireEvent("select", this, Ext.encode(r.data), index);
			this.initSelect = false;
		}
	},

	findRecordByText: function(prop, text) {
		var record;
		/* TODO: разобраться почему this.store = NULL */
		if (this.store && this.store.getCount() > 0) {
			this.store.each(function(r) {
				if (r.data[prop] == text) {
					record = r;
					return false;
				}
			});
		}
		return record;
	},

	findRecordEx: function(prop, value) {
		if (this.store.snapshot && this.store.snapshot.getCount() > 0) {
			var record;
			if (this.store.snapshot.getCount() > 0) {
				this.store.snapshot.each(function(r) {
					if (r.data[prop] == value) {
						record = r;
						return false;
					}
				});
			}
			return record;
		}
		return this.findRecord(prop, value);
	},

	indexOfEx: function(record) {
		if (this.store.snapshot && this.store.snapshot.getCount() > 0) {
			return this.store.snapshot.indexOf(record);
		}
		return this.store.data.indexOf(record);
	},

	getSelectedIndex: function() {
		var r = this.findRecordEx(this.valueField, this.getValue());
		return (!Ext.isEmpty(r)) ? this.indexOfEx(r) : -1;
	},

	onFocus: function() {
		Terrasoft.ComboBox.superclass.onFocus.call(this);
		var text = this.getText();
		if (this.allowEmpty || !Ext.isEmpty(text)) {
			this.startText = Ext.value(text, '');
		}
	},

	checkChange: function() {
		var value = this.getText();
		var startValue = this.startText;
		if (String(value) !== String(startValue)) {
			if (!this.strictedToItemsList || (this.allowEmpty && Ext.isEmpty(value))) {
				if (this.hiddenField) {
					this.hiddenField.value = value;
				}
			} else {
				this.el.dom.value = Ext.value(startValue, '');
			}
		} else {
			value = this.getValue();
			if (!this.allowEmpty && startValue != value) {
				this.el.dom.value = Ext.value(this.startText, '');
			}
		}
		value = this.getValue();
		if (!this.allowEmpty && Ext.isEmpty(this.el.dom.value)) {
			this.el.dom.value = Ext.value(this.startText, '');
		}
		startValue = this.startValue;
		if (String(value) !== String(startValue)) {
			this.startValue = value;
			this.fireEvent('change', this, value, startValue);
		}
	},

	startProcessing: function() {
		this.primaryToolButton.el.dom.style.cursor = 'wait';
	},

	endProcessing: function() {
		this.primaryToolButton.el.dom.style.cursor = 'pointer';
	},

	// private
	onInternalPrepareLookupFilterResponse: function(filters) {
		this.filters = Ext.decode(filters);
		this.doLoadRemoteData();
	},

	doLoadRemoteData: function() {
		if (!this.dataProvider && this.isDataControl) {
			this.dataProvider = new Terrasoft.combobox.WebServiceDataProvider({
				dataService: 'Services/DataService',
				dataGetMethod: 'GetEntitySchemaData'
			});
		}
		if (this.dataProvider) {
			this.dataProvider.initializeProvider(this);
			this.dataProvider.loadData();
		}
		this.listPrepared = true;
	},

	setListPrepared: function(value) {
		this.listPrepared = value;
	},

	setDefaultEmptyText: function() {
		if (!this.defaultEmptyText) {
			var accessDeniedMessage = Ext.StringList('WC.TreeGrid').getValue('AccessDenied');
			this.defaultEmptyText = "<" + accessDeniedMessage + ">";
		}
	},

	applyEmptyText: function () {
		var isEmptyValue = this.getRawValue().length < 1;
		var isEmptyText = this.getText().length < 1;
		if (this.rendered && this.emptyText && (isEmptyValue || !isEmptyValue && isEmptyText) && this.hasFocus == false) {
			this.setRawValue(this.emptyText);
			this.el.addClass(this.emptyClass);
		}
	}
});

Ext.reg('combo', Terrasoft.ComboBox);

Terrasoft.combobox.DataProvider = function(config) {
	Ext.apply(this, config);
	Terrasoft.combobox.DataProvider.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.combobox.DataProvider, Ext.util.Observable, {
	isProviderInitialized: false,

	initializeProvider: function(combobox) {
		if (this.isProviderInitialized) {
			return;
		}
		this.combobox = combobox;
		this.isProviderInitialized = true;
	}

});

Terrasoft.combobox.WebServiceDataProvider = Ext.extend(Terrasoft.combobox.DataProvider, {
	dataService: '',
	dataGetMethod: '',

	loadData: function() {
		this.combobox.startProcessing();
		var url = Terrasoft.getWebServiceUrl(this.dataService, this.dataGetMethod);
		Ext.Ajax.request({
			cleanRequest: true,
			method: this.requestMethod,
			url: url,
			success: this.handleResponse,
			failure: this.handleFailure,
			scope: this,
			argument: {},
			params: this.getLoadDataParams
		});
	},

	getLoadDataParams: function() {
		var buf = [];
		var names = [];
		var filters = this.filters;
		var combobox = this.combobox;
		var comboboxFilters = combobox.filters;
		filters = (comboboxFilters.length > 0 ? comboboxFilters : (filters || []));
		if (combobox.isDataControl) {
			var column = combobox.getColumn();
			var referenceSchemaUId = column.refSchemaUId;
			var refSchemaPrimaryColumnName = column.refSchemaPrimaryColumnName;
			var refSchemaPrimaryDisplayColumnName = column.refSchemaPrimaryDisplayColumnName;
			names.push(refSchemaPrimaryColumnName);
			names.push(refSchemaPrimaryDisplayColumnName);
			var additionalColumns = combobox.additionalColumns;
			if (additionalColumns) {
				for (var i = 0; i < additionalColumns.length; i++) {
					var columnName = additionalColumns[i];
					names.push(columnName);
				}
			}
			if (column.referenceSchemaList && column.referenceSchemaList.length > 0) {
				var sourceSchemaUId = combobox.getSourceSchemaUId() || column.referenceSchemaList[0].referenceSchemaUId;
			}
		}
		var schemaUId = sourceSchemaUId || combobox.lookupSchemaUId || referenceSchemaUId;
		var rowCount = combobox.listMaxRowCount || '';
		buf.push("schemaUId=", schemaUId, "&");
		buf.push("columnNames=", Ext.util.JSON.encode(names), "&");
		buf.push("filters=", Ext.encode(filters), "&");
		buf.push("rowCount=", rowCount);
		return buf.join("");
	},

	processResponseData: function (data) {
		var items = [];
		if (data) {
			var nodes = eval("(" + data + ")");
			for (var i = 0, len = nodes.length; i < len; i++) {
				var entityValues = nodes[i];
				if (entityValues.text) {
					entityValues.text = unescape(entityValues.text)
				};
				items.push([]);
				for (var item in entityValues) {
					var entityValue = Ext.util.Format.htmlDecode(Ext.value(entityValues[item], ''));
					items[i].push(entityValue);
				}
			}
		}
		return items;
	},

	applySorting: function(combobox) {
		if (combobox.sorted) {
			var sortFunction = combobox.sortFunction;
			if (sortFunction) {
				combobox.store.setCustomSort(this.displayField, sortFunction);
				combobox.sortData();
			} else {
				combobox.store.setDefaultSort(this.displayField);
			}
		}
	},

	handleResponse: function(response) {
		var combobox = this.combobox;
		try {
			var xmlData = response.responseXML;
			var root = xmlData.documentElement || xmlData;
			var data = root.text || root.textContent;
			var items = this.processResponseData(data);
			this.applySorting(combobox);
			combobox.loadData(items);
		} finally {
			combobox.endProcessing();
		}
	},

	handleFailure: function(response) {
		try {
			this.combobox.loadData([]);
		} finally {
			this.combobox.endProcessing();
		}
	}
});

Terrasoft.combobox.EnumDataProvider = Ext.extend(Terrasoft.combobox.WebServiceDataProvider, {
	dataService: 'Services/DataService',
	dataGetMethod: 'GetEnumDataProviderValues'
});

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}
