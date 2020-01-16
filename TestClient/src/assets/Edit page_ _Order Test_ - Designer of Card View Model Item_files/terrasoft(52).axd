Ext.namespace("Terrasoft.lookupedit");

Terrasoft.LookupEdit = Ext.extend(Terrasoft.BaseEdit, {
	fieldClass: "x-form-field x-form-lookup-field",
	lookupSchemaUId: "",
	userContextUId: "",
	multiSelectMode: false,
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
	queryDelay: 500,
	pageSize: 0,
	selectOnFocus: false,
	resizable: false,
	handleHeight: 8,
	editable: true,
	allQuery: '',
	mode: 'local',
	minListWidth: 70,
	forceSelection: false,
	typeAheadDelay: 500,
	lazyInit: true,
	valueInit: true,
	initSelect: false,
	valueField: 'value',
	displayField: 'text',
	listPrepared: false,
	sorted: false,
	allowEmpty: true,
	filters: [],
	listMaxRowCount: 21,
	stringColumnSearchMinCharCount: 3,
	stringColumnSearchComparisonType: 'StartWith',
	useContainAsComparisonType: false,
	useDropDownList: true,
	maxSearchValueLength: 50,

	initComponent: function() {
		Terrasoft.LookupEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = {
			id: this.primaryToolButtonId(),
			imageCls: 'lookupedit-ico-btn-lookup'
		};
		this.checkDataProperties();
		if (this.stringColumnSearchComparisonType == "Contain") {
			this.useContainAsComparisonType = true;
		}
		if (!this.store) {
			var storeConfig = {};
			storeConfig.fields = ['value', 'text'];
			storeConfig.data = [];
			this.store = new Ext.data.SimpleStore(storeConfig);
			this.valueField = 'value';
			this.displayField = 'text';
		} else {
			this.sortData();
		}
		this.selectedIndex = -1;
	},

	initEvents: function() {
		Terrasoft.LookupEdit.superclass.initEvents.call(this);
		this.addEvents(
			'load',
			'collapse',
			'beforeselect',
			'select',
			'beforequery',
			'primarytoolbuttonclick',
			'valueselected',
			'internalpreparelookupfilter'
		);

		if (!this.designMode && this.useDropDownList) {
			this.keyNav = new Ext.KeyNav(this.el, {
				"up": function(e) {
					this.inKeyMode = true;
					this.selectPrev();
				},
				"down": function(e) {
					if (!this.isExpanded()) {
						this.toggleDropDownList();
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
					this.cancelCheckValueAndText = true;
					var store = this.store;
					var rowCount = this.store.getCount();
					if (rowCount !== this.listMaxRowCount) {
						var index = this.view.getSelectedIndexes()[0];
						if (index === undefined) {
							if (rowCount == 0) {
								return;
							}
							index = 0;
							this.select(index, true);
						}
						var r = store.getAt(index);
						var text = r.data.text;
						if (text !== this.getText()) {
							if (text && !Ext.isEmpty(text) || this.allowEmpty) {
								this.el.dom.value = Ext.util.Format.htmlDecode(text);
							}
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
		if (this.useDropDownList) {
			this.queryDelay = Math.max(this.queryDelay || 10,
					this.mode == 'local' ? 10 : 250);
			this.dqTask = new Ext.util.DelayedTask(this.initQuery, this);
			if (this.typeAhead) {
				this.taTask = new Ext.util.DelayedTask(this.onTypeAhead, this);
			}
		}
		if (!this.designMode) {
			this.el.on("keyup", this.onKeyUp, this);
			this.el.on('keydown', this.onKeyDown, this);
		}
		if (this.forceSelection) {
			this.on('blur', this.doForce, this);
		}
	},

	unsetDelayCheck: function() {
		delete this.delayedCheck;
	},

	onRender: function(ct, position) {
		Terrasoft.LookupEdit.superclass.onRender.call(this, ct, position);
		this.hiddenFieldSourceSchemaUId = this.el.insertSibling({ tag: 'input', type: 'hidden',
			name: this.id + '_SourceSchemaUId', id: this.id + '_SourceSchemaUId'
		}, 'before', true);
		this.hiddenFieldSourceSchemaUId.value = this.sourceSchemaUId || '';
		this.prepareFilterContext = this.el.insertSibling({ tag: 'input', type: 'hidden',
			name: this.id + '_PrepareFilterContext', id: this.id + '_PrepareFilterContext'
		}, 'before', true);
		this.hiddenName = this.id + '_Value';
		this.hiddenSelectedIndexName = this.id + '_SelIndex';
		if (this.hiddenName) {
			this.hiddenField = this.el.insertSibling({ tag: 'input', type: 'hidden', name: this.hiddenName,
				id: (this.hiddenId || this.hiddenName)
			}, 'before', true);
			this.hiddenFieldSelectedIndex = this.el.insertSibling({ tag: 'input', type: 'hidden',
				name: this.hiddenSelectedIndexName, id: this.hiddenSelectedIndexName
			}, 'before', true);
			this.hiddenFieldSelectedIndex.value = this.selectedIndex ? this.selectedIndex : -1;
		}
		this.getEl().dom.setAttribute("name", this.uniqueName || this.id);
		if (Ext.isGecko) {
			this.el.dom.setAttribute('autocomplete', 'off');
		}
		if (!this.lazyInit && this.useDropDownlist) {
			this.initList();
		}
		this.showSelectedValues();
	},

	doForce: function() {
		if (this.el.dom.value.length > 0) {
			this.el.dom.value =
				this.lastSelectionText === undefined ? '' : this.lastSelectionText;
			this.applyEmptyText();
		}
	},

	checkDataProperties: function() {
		this.isLocalList = Boolean(this.store);
		this.isDataControl = ((this.dataSource != undefined) && (this.columnName != undefined || this.getColumnUId(this.columnUId)));
	},

	initValue: function() {
		try {
			this.valueInit = false;
			var column = this.getColumn();
			if (column) {
				var value = this.getColumnValue();
				var dataSource = this.dataSource;
				var sourceSchemaUIdColumnValueName = column.sourceSchemaUIdColumnValueName;
				if (sourceSchemaUIdColumnValueName) {
					var columnValue = dataSource.getColumnValue(sourceSchemaUIdColumnValueName);
					this.setSourceSchemaUId(columnValue);
				}
				var text = dataSource.getColumnDisplayValue(column.name);
				if (value && text) {
					this.setValueAndText(value, text);
				} else {
					this.setValue(value || "");
				}
				return;
			}
			if (this.value == undefined) {
				return;
			}
			if (this.text != undefined) {
				this.setValueAndText(this.value, this.text);
			} else {
				this.setValue(this.value);
			}
		} finally {
			this.validate(true);
			this.setImageClass(this.imageCls);
			this.valueInit = true;
		}
	},

	initQuery: function() {
		var minCharCount = this.stringColumnSearchMinCharCount;
		var valueCharCount = this.getFieldRawValue().length;
		if (valueCharCount < minCharCount) {
			return;
		}
		if (!this.isLocalList && !this.listPrepared) {
			this.loadDropDownListRemoteData();
			this.store.on('load', function() { this.initQuery(); }, this, { single: true });
			return;
		}
		if (!this.initList()) {
			this.el.focus();
			return;
		}
		this.doQuery(this.getFieldRawValue());
	},

	onTypeAhead: function() {
		if (this.store.getCount() > 0) {
			var r = this.store.getAt(0);
			var newValue = r.data[this.displayField];
			var len = newValue.length;
			var selStart = this.getFieldRawValue().length;
			if (selStart != len) {
				this.setRawValue(newValue);
				this.selectText(selStart, newValue.length);
			}
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

	setSourceSchemaUId: function(sourceSchemaUId) {
		this.sourceSchemaUId = sourceSchemaUId;
		if (this.rendered) {
			this.hiddenFieldSourceSchemaUId.value = sourceSchemaUId || '';
		}
	},

	onDataSourceLoaded: function(dataSource) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValueAndText(value, dataSource.getColumnDisplayValue(column.name), true);
		var sourceSchemaUIdColumnValueName = column.sourceSchemaUIdColumnValueName;
		if (sourceSchemaUIdColumnValueName) {
			var columnValue = dataSource.getColumnValue(sourceSchemaUIdColumnValueName);
			this.setSourceSchemaUId(columnValue);
		}
		this.setEmptyText();
	},

	onDataSourceRowLoaded: function(dataSource, rowColumns) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValueAndText(value, dataSource.getColumnDisplayValue(column.name), true);
		var sourceSchemaUIdColumnValueName = column.sourceSchemaUIdColumnValueName;
		if (sourceSchemaUIdColumnValueName) {
			var columnValue = dataSource.getColumnValue(sourceSchemaUIdColumnValueName);
			this.setSourceSchemaUId(columnValue);
		}
	},

	onDataSourceActiveRowChanged: function(dataSource) {
		this.onDataSourceLoaded(dataSource);
	},

	onDataSourceDataChanged: function(row, columnName) {
		var column = this.getColumn();
		if (!row || !column || (column && columnName != column.name)) {
			return;
		}
		var columnValue = row.getColumnValue(columnName);
		var columnDisplayValue = row.getColumnDisplayValue(columnName);
		this.setValueAndText(columnValue, columnDisplayValue, true);
	},

	onPrimaryToolButtonClick: function() {
		if (!this.enabled) {
			return;
		}
		if (this.isExpanded()) {
			this.collapse();
		}
		Terrasoft.LookupEdit.superclass.onPrimaryToolButtonClick.call(this, null, this.el, { t: this.primaryToolButton });
		if (this.hasListener('internalpreparelookupfilter')) {
			this.prepareFilterContext.value = 'lookup';
			this.fireEvent('internalpreparelookupfilter', this);
		} else {
			this.showLookupGridPage();
		}
	},

	toggleDropDownList: function() {
		if (!this.enabled) {
			return;
		}
		if (!this.isLocalList && !this.listPrepared) {
			this.initList();
			return;
		}
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

	initList: function() {
		var result = true;
		if (!this.isLocalList && !this.listPrepared) {
			this.loadDropDownListRemoteData();
			result = false;
		}
		if (!this.list) {
			var cls = 'x-combo-list';
			this.list = new Ext.Layer({
				shadow: this.shadow, cls: [cls, this.listClass].join(' '), constrain: false
			});
			var lw = this.listWidth || Math.max(this.wrap.getWidth(), this.minListWidth);
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
					this.listWidth = w;
					this.innerList.setWidth(w - this.list.getFrameWidth('lr'));
					this.restrictHeight();
				}, this);
				this[this.pageSize ? 'footer' : 'innerList'].setStyle('margin-bottom', this.handleHeight + 'px');
			}
		}
		return result;
	},

	bindStore: function(store, initial) {
		if (this.store && !initial) {
			this.store.un('beforeload', this.onDropDownListBeforeLoad, this);
			this.store.un('load', this.onDropDownListLoad, this);
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
			this.store.on('beforeload', this.onDropDownListBeforeLoad, this);
			this.store.on('load', this.onDropDownListLoad, this);
			this.store.on('loadexception', this.collapse, this);
			if (this.view) {
				this.view.setStore(store);
			}
		}
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
			this.onDropDownListSelect(r, index);
		}
		if (doFocus !== false) {
			this.el.focus();
		}
	},

	onDropDownListSelect: function(record, index) {
		if ((this.fireEvent('beforeselect', this, record, index) == false)) {
			this.collapse();
			return;
		}
		var oldValue = this.getValue();
		var recordData = record.data[this.valueField];
		if (!recordData) {
			recordData = record.data[this.displayField];
		}
		var dropDownListMoreRecordsItemId = this.dropDownListMoreRecordsItemId();
		if (recordData == dropDownListMoreRecordsItemId) {
			this.onPrimaryToolButtonClick();
			this.collapse();
			return;
		}
		this.listPrepared = true;
		this.el.addClass('x-form-field-lookup-value');
		this.setValue(recordData);
		this.collapse();
		var hiddenFieldSelectedIndex = this.hiddenFieldSelectedIndex;
		if (!Ext.isEmpty(hiddenFieldSelectedIndex)) {
			hiddenFieldSelectedIndex.value = this.getSelectedIndex();
		}
		this.selValue = this.getValue();
		this.text = this.el.dom.value;
		this.fireSelectEvent(record.data, index, oldValue);
	},

	onEmptyResults: function() {
		this.collapse();
	},

	isExpanded: function() {
		return this.list && this.list.isVisible();
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
		this.list.show();
		this.restrictWidth();
		this.restrictHeight();
		Ext.getDoc().on('mousewheel', this.collapseIf, this);
		Ext.getDoc().on('mousedown', this.collapseIf, this);
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
						this.store.filter(this.displayField, q, this.useContainAsComparisonType);
					}
					this.onDropDownListLoad();
				}
			} else {
				this.selectedIndex = -1;
				this.onDropDownListLoad();
			}
		}
	},

	onDropDownListBeforeLoad: function() {
		this.restrictHeight();
		this.selectedIndex = -1;
	},

	onDropDownListLoad: function() {
		var store = this.store;
		if (!store) {
			return;
		}
		var rowCount = store.getCount();
		if (rowCount > 0) {
			if (!this.list) {
				return;
			}
			if (rowCount >= (this.listMaxRowCount)) {
				this.removeItemByIndex(rowCount - 1);
				var dropDownListMoreRecordsItemId = this.dropDownListMoreRecordsItemId();
				var record = store.findByValue(dropDownListMoreRecordsItemId);
				var message = Ext.StringList('WC.LookupEdit').getValue('LookupEdit.MoreRecords');
				if (!record) {
					this.addItem(dropDownListMoreRecordsItemId, message);
				}
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

	addItem: function(value, text) {
		var record = new this.store.reader.recordType({ value: value, text: text }, null);
		if (this.sorted) {
			this.store.addSorted(record);
		} else {
			this.store.add([record]);
		}
	},

	removeItemById: function(id) {
		this.store.remove(this.store.findByValue(id));
	},

	removeItemByIndex: function(index) {
		this.store.remove(this.store.data.items[index]);
	},

	getValue: function() {
		if (!this.rendered) {
			return this.value || '';
		}
		if (this.hiddenField) {
			var value = this.hiddenField.value;
		}
		return Ext.value(value, '');
	},

	getSourceSchemaUId: function() {
		if (this.hiddenFieldSourceSchemaUId) {
			var value = this.hiddenFieldSourceSchemaUId.value;
		}
		return value || "";
	},

	getDisplayValue: function() {
		return this.text;
	},

	setValue: function(value, isInitByEvent) {
		this.value = value;
		if (!this.el) {
			return;
		}
		var oldValue =
			this.useExternalDisplayValue ? null : ((this.valueField == 'value') ? this.getValue() : this.getText());
		if (value == oldValue) {
			this.useExternalDisplayValue = false;
			return;
		}
		var text = value;
		try {
			if (this.useExternalDisplayValue) {
				text = this.externalDisplayValue;
				this.useExternalDisplayValue = false;
			} else if (this.useDropDownList) {
				this.store.clearFilter();
				if (!this.isLocalList && !this.listPrepared) {
					this.loadDropDownListRemoteData();
					this.store.on('load', function() { this.setValue(this.value, isInitByEvent) }, this, { single: true });
					return;
				}
				var r = this.findRecord(this.valueField, value);
				if (r) {
					text = r.data[this.displayField];
				}
				text = Ext.value(text, '');
			}
			this.lastSelectionText = text;
			this.text = text;
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

	setValueAndText: function(value, text, isInitByEvent) {
		value = value || "";
		var oldValue = this.getValue();
		if (value == oldValue) {
			return;
		}
		if (!this.el) {
			this.value = value;
			this.text = text;
			return;
		}
		if (!text || !value) {
			this.clearText();
			this.clearValue();
			value = null;
		} else {
			this.value = value;
			this.text = text;
			this.el.dom.value = text;
			this.hiddenField.value = value;
			this.el.removeClass(this.emptyClass);
			this.el.addClass('x-form-field-lookup-value');
		}
		this.validate(true);
		if (this.valueInit) {
			var opt = {};
			opt.isInitByEvent = isInitByEvent || false;
			this.startValue = value;
			this.fireEvent('change', this, value, oldValue, opt);
		}
	},

	validateValue: function(value) {
		if (value.length < 1 || value === this.emptyText) {
			if (this.required) {
				this.markInvalid();
				return false;
			}
		}
		return true;
	},

	getRawValue: function() {
		return this.getValue();
	},

	getFieldRawValue: function() {
		return Terrasoft.LookupEdit.superclass.getRawValue.call(this);
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
		var h = Math.min(h, space, this.maxHeight);
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
		var maxItemWidth = maxItemWidth + frameWidth + listItemPaddings;
		var listWidth = (w != undefined) ? w : this.wrap.getWidth();
		var newWidth;
		if (maxItemWidth <= listWidth) {
			newWidth = listWidth;
		} else {
			newWidth = (this.maxListWidth && this.maxListWidth < maxItemWidth) ? this.maxListWidth : maxItemWidth;
		}
		this.list.setWidth(newWidth);
		this.innerList.setWidth(newWidth - this.list.getFrameWidth('lr'));
	},

	handleResponse: function(response) {
		var xmlData = response.responseXML;
		var root = xmlData.documentElement || xmlData;
		var data = root.text || root.textContent;
		var items = [];
		try {
			var nodes = eval("(" + data + ")");
			var entityValues = nodes[0].values;
			var column = this.getColumn();
			var refSchemaName = column.refSchemaName;
			var refSchemaPrimaryColumnName = column.refSchemaPrimaryColumnName;
			var refSchemaPrimaryDisplayColumnName = column.refSchemaPrimaryDisplayColumnName;
			var value = entityValues[refSchemaPrimaryColumnName];
			var text = entityValues[refSchemaPrimaryDisplayColumnName];
			if (value && text) {
				this.setValueAndText(value, text);
			}
		} catch (e) {
			this.handleFailure(response);
		}
	},

	handleFailure: function(response) {
	},

	loadData: function(data) {
		if (this.store != undefined) {
			this.store.loadData(data);
		}
		this.fireEvent("load", this);
	},

	loadDropDownListRemoteData: function() {
		if (this.hasListener('internalpreparelookupfilter')) {
			this.prepareFilterContext.value = 'list';
			this.fireEvent('internalpreparelookupfilter', this);
		} else {
			this.doLoadDropDownListRemoteData();
		}
	},

	doLoadDropDownListRemoteData: function() {
		if (!this.dataProvider) {
			this.dataProvider = new Terrasoft.lookupedit.WebServiceDataProvider({
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

	startProcessing: Ext.emptyFn,

	endProcessing: Ext.emptyFn,

	onFocus: function() {
		Terrasoft.LookupEdit.superclass.onFocus.call(this);
		var text = this.getText();
		if (this.allowEmpty || !Ext.isEmpty(text)) {
			this.startText = Ext.value(text, '');
		}
	},

	getText: function() {
		return this.el.dom.value;
	},

	setText: function(text) {
		this.text = text || '';
		this.el.dom.value = this.text;
		this.clearValue();
	},

	clear: function() {
		this.clearValue();
		this.clearText();
		this.clearPrepareFilterContext();
		this.store.removeAll();
	},

	clearValue: function() {
		this.hiddenField.value = '';
		this.hiddenFieldSourceSchemaUId.value = '';
		this.el.removeClass('x-form-field-lookup-value');
		this.lastSelectionText = '';
		this.value = '';
	},

	internalClearValue: function() {
		this.hiddenField.value = '';
		this.el.removeClass('x-form-field-lookup-value');
		this.lastSelectionText = '';
		this.value = '';
	},

	clearText: function() {
		this.text = '';
		this.el.dom.value = '';
	},

	clearPrepareFilterContext: function() {
		this.prepareFilterContext.value = '';
	},

	onKeyUp: function(e) {
		if (!this.enabled) {
			return;
		}
		if (!this.useDropDownList) {
			if (this.getValue() && (this.text != this.el.dom.value)) {
				this.clearValue();
			}
			return;
		}
		this.listPrepared = false;
		if (this.editable !== false && !e.isSpecialKey()) {
			this.lastKey = e.getKey();
			if (this.lastKey == e.DELETE) {
				return;
			}
			this.dqTask.delay(this.queryDelay);
			if (this.getValue() && (this.text != this.el.dom.value)) {
				this.internalClearValue();
			}
		}
	},

	onKeyDown: function(e) {
		var k = e.getKey();
		switch (k) {
			case e.F2:
				this.onPrimaryToolButtonClick();
				break;
			case e.ENTER:
				if ((!this.isExpanded() && !this.cancelCheckValueAndText) || !this.useDropDownList) {
					this.checkValueAndText();
				}
				this.cancelCheckValueAndText = false;
				break;
		}
	},

	fireKey: function(e) {
		if (this.isExpanded()) {
			return;
		}
		var k = e.getKey();
		if (k == e.ENTER && !this.delayedCheck && this.enabled !== false) {
			this.checkChange();
		}
		if (e.isNavKeyPress() && !this.delayedCheck) {
			this.fireEvent("specialkey", this, e);
		}
		if (k == e.DELETE && this.enabled !== false) {
			this.internalClearValue();
		}
		// TODO: убрать этот код, когда будет решена проблема с получением фокуса treegrid-а
		{
			if (!this.mimicing) {
				this.mimicing = true;
				Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, {delay: 10});
			}
		}
	},

	checkValueAndText: function() {
		var text = this.getText();
		if (text && !this.getValue()) {
			this.text = text;
			this.onPrimaryToolButtonClick();
		}
	},

	beforeBlur: function() {
		this.checkValueAndText();
	},

	validateBlur: function(e) {
		return !this.list || !this.list.isVisible();
	},

	showLookupGridPage: function() {
		var referenceSchemaUId;
		var referenceSchemaList;
		var sourceSchemaUId;
		var sourceSchemaUIdColumnValueName;
		var column = this.getColumn();
		var lookupGridPageParams = this.lookupGridPageParams;
		var lookupSchemaUId = this.lookupSchemaUId;
		var lookupPageSchemaUId = this.lookupPageSchemaUId;
		if (lookupSchemaUId === Terrasoft.GUID_EMPTY) {
			lookupSchemaUId = null;
		}
		if (lookupPageSchemaUId === Terrasoft.GUID_EMPTY) {
			lookupPageSchemaUId = null;
		}
		if (!column && !lookupGridPageParams && !lookupSchemaUId) {
			return;
		}
		if (column) {
			if (column.referenceSchemaList && column.referenceSchemaList.length > 0) {
				referenceSchemaList = column.referenceSchemaList;
				sourceSchemaUId = this.hiddenFieldSourceSchemaUId.value;
			} else {
				referenceSchemaUId = column.refSchemaUId;
			}
		} else if (lookupGridPageParams) {
			if (lookupGridPageParams.referenceSchemaList && lookupGridPageParams.referenceSchemaList.length > 0) {
				referenceSchemaList = lookupGridPageParams.referenceSchemaList;
				if (lookupGridPageParams.sourceSchemaUId) {
					sourceSchemaUId = lookupGridPageParams.sourceSchemaUId;
				}
			} else {
				referenceSchemaUId = lookupGridPageParams.referenceSchemaUId;
			}
		}
		var schemaUId = sourceSchemaUId || lookupSchemaUId || referenceSchemaUId;
		if (!schemaUId && referenceSchemaList && referenceSchemaList.length > 0) {
			schemaUId = referenceSchemaList[0].referenceSchemaUId;
		}
		var key = this.id + schemaUId.replace(/-/g, '');
		var multiSelectMode = this.multiSelectMode;
		var searchValue = multiSelectMode ? null : this.getText();
		var maxSearchValueLength = this.maxSearchValueLength;
		if (searchValue && maxSearchValueLength) {
			searchValue = searchValue.substr(0, maxSearchValueLength);
		}
		Terrasoft.LookupGridPage.show(key, this, this.onLookupValueEditComplete, schemaUId, referenceSchemaList, null,
			searchValue, this.userContextUId, lookupPageSchemaUId, multiSelectMode);
	},

	onLookupValueEditComplete: function(values, referenceSchemaUId) {
		if (!values && values.length < 1) {
			return;
		}
		var sourceSchemaUId = this.hiddenFieldSourceSchemaUId.value;
		if (sourceSchemaUId != referenceSchemaUId) {
			this.setListPrepared(false);
		}
		this.hiddenFieldSourceSchemaUId.value = referenceSchemaUId;
		var keyValue = '';
		var displayValue = '';
		var dataValue;
		var primaryDisplayColumnName;
		var primaryDisplayColumnValue;
		var length = values.length;
		var displayValueSeparator = ';';
		var equalSeparator = '=';
		var ampSeparator = '&';
		if (this.multiSelectMode) {
			var selectedValues = this.selectedValues = { };
		}
		for (var i = 0; i < length; ) {
			var value = values[i];
			keyValue += value.keyValue;
			dataValue = value.dataValue;
			primaryDisplayColumnName = value.primaryDisplayColumnName;
			primaryDisplayColumnValue = dataValue[primaryDisplayColumnName];
			displayValue += primaryDisplayColumnValue;
			if (!this.multiSelectMode) {
				break;
			}
			selectedValues[value.keyValue] = dataValue;
			keyValue += equalSeparator + Ext.encode(dataValue);
			if (++i < length) {
				keyValue += ampSeparator;
				displayValue += displayValueSeparator;
			}
		}
		this.setValueAndText(keyValue, displayValue);
		this.fireEvent('valueselected', this, Ext.util.JSON.encode(keyValue), displayValue);
	},
	
	addSelectedValue: function(key, values) {
		if (key && values) {
			this.selectedValues[key] = values;
			this.showSelectedValues();
		}
	},

	showSelectedValues: function() {
		var selectedValues = this.selectedValues;
		if (!selectedValues) {
			return;
		}
		var displayColumnName = this.getDisplayColumnName();
		if (!displayColumnName) {
			return;
		}
		var keyValue = '';
		var displayValue = '';
		var displayValueSeparator = ';';
		var equalSeparator = '=';
		var ampSeparator = '&';
		var started = false;
		for (var uid in selectedValues) {
			if (started) {
				keyValue += ampSeparator;
				displayValue += displayValueSeparator;
			}
			var selectedValue = selectedValues[uid];
			keyValue += uid;
			displayValue += selectedValue[displayColumnName];
			keyValue += equalSeparator + Ext.encode(selectedValue);
			started = true;
		}
		if (started) {
			this.setValueAndText(keyValue, displayValue);
			this.fireEvent('valueselected', this, Ext.util.JSON.encode(keyValue), displayValue);
		}
	},
	
	getDisplayColumnName: function() {
		var displayColumnName = this.selectedValuesDisplayColumnName;
		if (!displayColumnName && this.dataSorce) {
			var column = this.getColumn();
			displayColumnName = column ? column.displayColumnName : null;
		}
		return displayColumnName;
	},

	// private
	onInternalPrepareLookupFilterResponse: function(filters, contextToken) {
		if (contextToken === 'lookup') {
			this.showLookupGridPage();
		} else {
			this.filters = Ext.decode(filters);
			this.doLoadDropDownListRemoteData();
		}
	},

	dropDownListMoreRecordsItemId: function() {
		return this.id ? this.id + '_DropDownListMoreRecordsItem' : Ext.id();
	},

	setListPrepared: function(value) {
		this.listPrepared = value;
	},

	onResize: function(w, h) {
		Terrasoft.LookupEdit.superclass.onResize.apply(this, arguments);
		if (this.list) {
			this.restrictWidth(w, h);
		}
	},

	setDefaultEmptyText: function() {
		if (!this.defaultEmptyText) {
			var accessDeniedMessage = Ext.StringList('WC.TreeGrid').getValue('AccessDenied');
			this.defaultEmptyText = "<" + accessDeniedMessage + ">";
		}
	},

	setSelectedValuesDisplayColumnName: function(value) {
		this.selectedValuesDisplayColumnName = value;
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

Ext.reg('lookupedit', Terrasoft.LookupEdit);

Terrasoft.lookupedit.WebServiceDataProvider = Ext.extend(Terrasoft.combobox.DataProvider, {
	dataService: '',
	dataGetMethod: '',
	filterComparisonType: { StartWith : 9, Contain : 11 },

	initializeProvider: function(lookup) {
		if (this.isProviderInitialized) {
			return;
		}
		this.lookup = lookup;
		this.isProviderInitialized = true;
	},

	loadData: function() {
		this.lookup.startProcessing();
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
		var lookup = this.lookup;
		var lookupFilters = lookup.filters;
		filters = (lookupFilters.length > 0 ? lookupFilters : (filters || []));
		var text = lookup.getText();
		var filterComparisonType = this.filterComparisonType;
		var comparisonType = lookup.useContainAsComparisonType ? filterComparisonType.Contain : filterComparisonType.StartWith;
		var primaryDisplayColumnNameFilterItem = {
			comparisonType: comparisonType,
			leftExpressionColumnPath: '[PrimaryDisplayColumnName]',
			useDisplayValue: false,
			rightExpressionParameterValues: [encodeURIComponent(Ext.util.Format.htmlEncode(text))]
		};
		filters.push(primaryDisplayColumnNameFilterItem);
		var rowCount = lookup.listMaxRowCount || '';
		if (lookup.isDataControl) {
			var column = lookup.getColumn();
			var referenceSchemaUId = column.refSchemaUId;
			var refSchemaPrimaryColumnName = column.refSchemaPrimaryColumnName;
			var refSchemaPrimaryDisplayColumnName = column.refSchemaPrimaryDisplayColumnName;
			if (refSchemaPrimaryColumnName) {
				names.push(refSchemaPrimaryColumnName);
			}
			if (refSchemaPrimaryDisplayColumnName) {
				names.push(refSchemaPrimaryDisplayColumnName);
			}
			var additionalColumns = lookup.additionalColumns;
			if (additionalColumns) {
				for (var i = 0; i < additionalColumns.length; i++) {
					var columnName = additionalColumns[i];
					names.push(columnName);
				}
			}
			if (column.referenceSchemaList && column.referenceSchemaList.length > 0) {
				var sourceSchemaUId = lookup.getSourceSchemaUId() || column.referenceSchemaList[0].referenceSchemaUId;
			}
		}
		var schemaUId = sourceSchemaUId || lookup.lookupSchemaUId || referenceSchemaUId;
		buf.push("schemaUId=", schemaUId, "&");
		buf.push("columnNames=", Ext.util.JSON.encode(names), "&");
		buf.push("filters=", Ext.encode(filters), "&");
		buf.push("rowCount=", rowCount);
		return buf.join("");
	},

	handleResponse: function(response) {
		try {
			var xmlData = response.responseXML;
			var root = xmlData.documentElement || xmlData;
			var data = root.text || root.textContent;
			var items = [];
			if (data) {
				var nodes = eval("(" + data + ")");
				for (i = 0, len = nodes.length; i < len; i++) {
					var entityValues = nodes[i];
					items.push([]);
					for (var item in entityValues) {
						var entityValue = Ext.util.Format.htmlDecode(Ext.value(entityValues[item], ''));
						items[i].push(entityValue);
					}
				}
			}
			if (this.lookup.sorted) {
				if (this.lookup.sortFunction) {
					this.lookup.store.setCustomSort('text', this.lookup.sortFunction);
					this.lookup.sortData();
				} else {
					this.lookup.store.setDefaultSort('text');
				}
			}
			this.lookup.loadData(items);
		} finally {
			this.lookup.endProcessing();
		}
	},

	handleFailure: function(response) {
		try {
			this.lookup.loadData([]);
		} finally {
			this.lookup.endProcessing();
		}
	}
});