Terrasoft.StructureExplorer = function(cfg) {
	cfg = cfg || {};
	Ext.apply(this, cfg);
	this.ddGroup = "StructureExplorer";
	Terrasoft.StructureExplorer.superclass.constructor.call(this);
	if (!this.params) {
		this.params = {};
	}
	this.initComponent();
};

Ext.extend(Terrasoft.StructureExplorer, Ext.util.Observable, {
	isMultiSelect: false,
	isRootMode: true,
	isShowStructureItemsProperties: true,
	isShowSystemColumns: false,
	isShowSystemReference: false,
	isShowSystemReferenceOption: true,
	isColumnDuplicationAllowed: false,

	initComponent: function() {
		this.addEvents(
			"editcomplete",
			"updatestructuretree",
			"updatestructureitems",
			"editcolumnbuttonclick"
		);
		var btnOk = this.findOkButton();
		btnOk.on("click", this.onEditComplete, this);
		this.searchField.on("render", function() {
			this.searchField.el.on("keydown", this.onSearchFieldChange, this);
		}, this);
		this.clearSearchToolButton = this.findClearSearchToolButton();
		this.clearSearchToolButton.on("click", this.onClearSearchField, this);
		this.onClearSearchField(null, true);
		this.structureItemsGrid.ddGroup = this.ddGroup;
		this.structureItemsGrid.dataSource.on("loaded", this.updateStructureItemsGridLocalBySearchValue, this);
		var structurePropertiesButton = this.findStructurePropertiesButton();
		if (!this.isRootMode) {
			this.structureTree.on("selectionchange", this.updateStructureItemsGrid, this);
		}
		if (this.isShowStructureItemsProperties) {
			this.generateStructurePropertiesContextMenu(structurePropertiesButton.getMenu());
			if (!this.isRootMode) {
				this.addStructureTreeContextMenu(this.structureTree);
			}
			this.addStructureItemsContextMenu(this.structureItemsGrid);
		}
		if (this.isMultiSelect) {
			this.addSelectedItemsContextMenu(this.selectedItemsGrid);
			this.selectedItemsGrid.ddGroup = this.ddGroup;
			this.selectedItemsGrid.on("nodesdrop", this.onSelectedItemsGridNodesDrop, this);
			this.structureItemsGrid.on("nodesdrop", this.onStructureItemsGridNodesDrop, this);
			this.structureItemsGrid.on("dblclick", this.addToSelectedItemsByDbClick, this);
			this.selectedItemsGrid.on("dblclick", this.onRemoveColumnClick, this);
			var btnEditColumn = this.findEditColumnButton();
			btnEditColumn.on("click", this.onSelectedItemsGridDblClick, this);
			var btnDragUp = this.findDragUpButton();
			btnDragUp.on("click", this.onRemoveColumnClick, this);
			var btnDragDown = this.findDragDownButton();
			btnDragDown.on("click", this.onDragDownClick, this);
			var btnMoveDown = this.findMoveDownButton();
			btnMoveDown.on("click", this.onMoveDownClick, this);
			var btnMoveUp = this.findMoveUpButton();
			btnMoveUp.on("click", this.onMoveUpnClick, this);
		} else {
			this.structureItemsGrid.on("dblclick", this.onItemsGridDblClick, this);
		}
	},

	onClearSearchField: function(e, suppressChange) {
		this.searchField.setValue("");
		this.clearSearchToolButton.hide();
		if (suppressChange !== true) {
			this.updateStructureItemsGridLocalBySearchValue();
		}
	},

	onMoveDownClick: function() {
		this.selectedItemsGrid.moveSelectedRowsDown();
	},

	onMoveUpnClick: function() {
		this.selectedItemsGrid.moveSelectedRowsUp();
	},

	onDragDownClick: function() {
		var rows = this.structureItemsGrid.selModel.selData;
		var path = this.getSelectedStructureTreeRow();
		var targetRowId = "Root";
		var point = "Append";
		var rowsCount = rows.length;
		for (var i = 0; i < rowsCount; i++) {
			var row = rows[i];
			this.insertRowToSelected(targetRowId, point, row, path);
		}
	},

	onSelectedItemsGridDblClick: function(treeGrid) {
		var schema;
		var row = this.selectedItemsGrid.dataSource.activeRow;
		if (!row) {
			return;
		}
		var isOppositeColumn = false;
		var path = row.columns["MetaPath"];
		var startIndex = path.lastIndexOf("[");
		if (startIndex >= 0) {
			isOppositeColumn = true;
			startIndex += 1;
			var endIndex = path.lastIndexOf(":");
			schema = path.substring(startIndex, endIndex);
		} else {
			schema = this.rootSchemaUId;
		}
		var primaryColumnValue = row.getPrimaryColumnValue();
		var key = this.id + primaryColumnValue.replace(/-/g, '');
		var serializedItem = JSON.stringify(row.columns);
		Terrasoft.ColumnEditPage[key] = {
			key: key,
			sender: this,
			callbackFunction: this.editColumnComplete,
			pageSchemaUId: null,
			columnId: primaryColumnValue,
			structureExplorerId: this.id,
			rootSchemaUId: schema,
			isOppositeColumn: isOppositeColumn
		};
		this.fireEvent("editcolumnbuttonclick", key, serializedItem);
	},

	editColumnComplete: function(key) {
	},

	containsOppositePath: function(metaPath) {
		return metaPath.indexOf("[") >= 0;
	},

	onRemoveColumnClick: function() {
		var rows = this.selectedItemsGrid.selModel.selData;
		this.removeSelectedItemsRows(rows);
	},

	onShowSystemReference: function(checked) {
		this.isShowSystemReference = !checked;
		var path = this.getSelectedStructureTreeRow();
		var item = this.structureItemsGrid.selModel.selData[0];
		var itemInfo = {
			caption: null,
			metaPath: null
		};
		if (path && item) {
			itemInfo = {
				caption: this.getShortCaption(item["Caption"]),
				metaPath: item["UId"]
			};
			itemInfo = this.getItemInfoByPath(path, itemInfo);
		}
		this.fireEvent("updatestructuretree", this.isShowSystemReference, this.rootSchemaUId, this.rootSchemaKind,
			Ext.encode(itemInfo));
	},

	loadRootStructureTreeRow: function(rows) {
		this.selectedRootStructureTreeRow = rows[0];
	},

	getSelectedStructureTreeRow: function() {
		if (this.isRootMode) {
			return this.selectedRootStructureTreeRow;
		} else {
			return this.structureTree.selModel.selData[0];
		}
	},

	addSelectedItemsContextMenu: function(treegrid) {
		var menu = new Ext.menu.Menu({ id: "SelectedItemsContextMenu" });
		var moveUpImageCfg = { resourceManager: "Terrasoft.WebApp", resourceName: "entityschemadesigner-menu-upitem.png" };
		var moveDownImageCfg = { resourceManager: "Terrasoft.WebApp", resourceName: "entityschemadesigner-menu-downitem.png" };
		var stringList = Ext.StringList('WC.StructureExplorer');
		var separator = new Ext.menu.Separator({ id: "selectedItemSeparator", xtype: "menuseparator", caption: stringList.getValue("MenuItems.SelectedItemMenuGroupCaption") });
		menu.items.add(separator);
		menu.add(
			{ id: "remove", caption: stringList.getValue("MenuItems.RemoveSelectedItems") },
			{ id: "moveup", caption: stringList.getValue("MenuItems.MoveUp"), imageCfg: moveUpImageCfg },
			{ id: "movedown", caption: stringList.getValue("MenuItems.MoveDown"), imageCfg: moveDownImageCfg }
		);
		separator = new Ext.menu.Separator({ id: "aggregationseparator", xtype: "menuseparator", caption: stringList.getValue("MenuItems.AggregationType") });
		menu.items.add(separator);
		menu.add(
			{ id: "Count", caption: this.getAggregationCaption(Terrasoft.Filter.AggregationType.COUNT), checked: false, group: "aggregationType" },
			{ id: "Sum", caption: this.getAggregationCaption(Terrasoft.Filter.AggregationType.SUM), checked: false, group: "aggregationType" },
			{ id: "Max", caption: this.getAggregationCaption(Terrasoft.Filter.AggregationType.MAX), checked: false, group: "aggregationType" },
			{ id: "Min", caption: this.getAggregationCaption(Terrasoft.Filter.AggregationType.MIN), checked: false, group: "aggregationType" }
		);
		menu.on("itemclick", this.onSelectedItemsContextMenuItemClick, this);
		menu.on("beforeshow", this.onPrepareSelectedItemsMenu, this);
		treegrid.contextMenuId = menu;
	},

	onPrepareSelectedItemsMenu: function(menu) {
		var row = this.selectedItemsGrid.selModel.selData[0], item;
		this.findMenuItem(menu, 'aggregationseparator').hide();
		this.findMenuItem(menu, 'Count').hide();
		this.findMenuItem(menu, 'Sum').hide();
		this.findMenuItem(menu, 'Max').hide();
		this.findMenuItem(menu, 'Min').hide();
		var isVirtual = row.IsVirtual == 'True' || (row.MetaPath.indexOf('[') >= 0
			&& row.AggregationType == Terrasoft.Filter.AggregationType.COUNT);
		var isAggregated = row && (!Ext.isEmpty(row.AggregationType) && row.AggregationType != Terrasoft.Filter.AggregationType.NONE);
		if (isAggregated && !isVirtual) {
			this.findMenuItem(menu, 'aggregationseparator').show();
			var belongAggregationTypes = this.getBelongAggregationTypesArray(row.DataValueType);
			for (var i = 0, length = belongAggregationTypes.length; i < length; i += 1) {
				item = this.findMenuItem(menu, belongAggregationTypes[i]);
				if (item) {
					item.show();
				}
			}
			item = this.findMenuItem(menu, row.AggregationType);
			if (item) {
				item.setChecked(true, true);
			}
		}
	},

	setColumnAggregationType: function(aggregationType) {
		var row = this.selectedItemsGrid.selModel.selData[0];
		var dataSource = this.selectedItemsGrid.dataSource;
		var dataSourceRow = dataSource.getRow(row[dataSource.getPrimaryColumnName()]);
		if (dataSourceRow) {
			var caption = dataSourceRow.getColumnValue('Caption');
			var oldAggregationType = dataSourceRow.getColumnValue('AggregationType');
			caption = caption.replace(this.getAggregationCaption(oldAggregationType), this.getAggregationCaption(aggregationType));
			dataSourceRow.setColumnValue('AggregationType', aggregationType);
			dataSourceRow.setColumnValue('Caption', caption);
			rows = [dataSourceRow.columns];
			dataSource.fireEvent('rowloaded', dataSource, rows, {});
		}
	},

	getBelongAggregationTypesArray: function(dataValueType) {
		var belongArray;
		belongArray = [];
		switch (dataValueType) {
			case 'Integer':
			case 'Float1':
			case 'Float2':
			case 'Float3':
			case 'Float4':
			case 'Money':
				belongArray = [
					Terrasoft.Filter.AggregationType.SUM,
					Terrasoft.Filter.AggregationType.MIN,
					Terrasoft.Filter.AggregationType.MAX,
					Terrasoft.Filter.AggregationType.AVG
				];
				break;
			case 'Date':
			case 'Time':
			case 'DateTime':
				belongArray = [
					Terrasoft.Filter.AggregationType.MIN,
					Terrasoft.Filter.AggregationType.MAX
				];
				break;
		}
		return belongArray;
	},

	findMenuItem: function(menu, key) {
		var itemIndex = menu.items.indexOfKey(key);
		var item = menu.items.itemAt(itemIndex);
		return item;
	},

	generateStructurePropertiesContextMenu: function(menu) {
		var stringList = Ext.StringList('WC.StructureExplorer');
		menu.on("beforeshow", this.beforeStructureItemsContextMenuShow, this);
		if (this.isShowSystemReferenceOption) {
			menu.addItem(new Ext.menu.CheckItem({
				id: "showSystemReference",
				caption: stringList.getValue('MenuItems.StraitLinkedEntities'),
				checked: this.isShowSystemReference
			}));
		}
		menu.addItem(new Ext.menu.CheckItem({
			id: "showSystemColumns",
			caption: stringList.getValue('MenuItems.MainColumns'),
			checked: this.isShowSystemColumns
		}));
		menu.on("itemclick", this.onStructureContextMenuItemClick, this);
	},

	addStructureTreeContextMenu: function(treegrid) {
		var stringList = Ext.StringList('WC.StructureExplorer');
		var menu = new Ext.menu.Menu({ id: "StructureTreeContextMenu" });
		menu.on("beforeshow", this.beforeStructureTreeContextMenuShow, this);
		if (this.isShowSystemReferenceOption) {
			menu.add({
				id: "showSystemReference",
				caption: stringList.getValue('MenuItems.StraitLinkedEntities'),
				checked: this.isShowSystemReference
			});
		}
		menu.on("itemclick", this.onStructureContextMenuItemClick, this);
		treegrid.contextMenuId = menu;
	},

	addStructureItemsContextMenu: function(treegrid) {
		var stringList = Ext.StringList('WC.StructureExplorer');
		var menu = new Ext.menu.Menu({ id: "StructureItemsContextMenu" });
		menu.on("beforeshow", this.beforeStructureItemsContextMenuShow, this);
		if (this.isMultiSelect) {
			var addImageCfg = { resourceManager: "Terrasoft.WebApp", resourceName: "common-icon-add.png" };
			menu.add(
				{ id: "add", caption: stringList.getValue("MenuItems.AddSelectedItems"), imageCfg: addImageCfg }
			);
		}
		menu.add({
			id: "showSystemColumns",
			caption: stringList.getValue('MenuItems.MainColumns'),
			checked: this.isShowSystemColumns
		});
		menu.on("itemclick", this.onStructureContextMenuItemClick, this);
		treegrid.contextMenuId = menu;
	},

	beforeStructureTreeContextMenuShow: function(menu) {
		var item = menu.items.map["showSystemReference"];
		if (item) {
			item.setChecked(this.isShowSystemReference);
		}
	},

	beforeStructureItemsContextMenuShow: function(menu) {
		var item = menu.items.map["showSystemReference"];
		if (item) {
			item.setChecked(this.isShowSystemReference);
		}
		item = menu.items.map["showSystemColumns"];
		if (item) {
			item.setChecked(this.isShowSystemColumns);
		}
	},

	onSelectedItemsContextMenuItemClick: function(item) {
		switch (item.id) {
			case "remove":
				var rows = this.selectedItemsGrid.selModel.selData;
				this.removeSelectedItemsRows(rows);
				break;
			case "moveup":
				this.selectedItemsGrid.moveSelectedRowsUp();
				break;
			case "movedown":
				this.selectedItemsGrid.moveSelectedRowsDown();
				break;
			case "Count":
			case "Sum":
			case "Min":
			case "Max":
				this.setColumnAggregationType(item.id);
				break;
		}
	},

	onStructureContextMenuItemClick: function(item) {
		switch (item.id) {
			case "add":
				var items = this.structureItemsGrid.selModel.selData;
				this.addItemsToSelected(items);
				break;
			case "showSystemColumns":
				this.showSystemColumnsMenuClick(item);
				break;
			case "showSystemReference":
				this.onShowSystemReference(item.checked);
				break;
		}
	},

	showSystemColumnsMenuClick: function(item) {
		this.isShowSystemColumns = !item.checked;
		this.updateStructureItemsGrid();
	},

	getBelongAggregationType: function(dataValueType) {
		var result;
		switch (dataValueType) {
			case 'Guid':
				result = Terrasoft.Filter.AggregationType.COUNT;
				break;
			case 'Integer':
			case 'Float1':
			case 'Float2':
			case 'Float3':
			case 'Money':
				result = Terrasoft.Filter.AggregationType.SUM;
				break;
			case 'DateTime':
			case 'Date':
			case 'Time':
				result = Terrasoft.Filter.AggregationType.MAX;
				break;
		}
		return result;
	},

	getAggregationCaption: function(aggregationType) {
		if (Ext.isEmpty(aggregationType)) {
			return;
		}
		var treegridStringList = Ext.StringList('WC.TreeGrid');
		return treegridStringList.getValue('AggregationType.' + aggregationType);
	},

	getAggregationType: function(isOpposite, isVirtual, item) {
		return isOpposite
			? (isVirtual
				? Terrasoft.Filter.AggregationType.COUNT
				: this.getBelongAggregationType(item["DataValueType"]))
			: "";
	},

	getComparisonType: function(isOpposite, isVirtual, item) {
		return (isOpposite && isVirtual && item && item.Position == "2")
			? Terrasoft.Filter.AggregationType.EXISTS
			: "";
	},

	onEditComplete: function(e) {
		if (this.isMultiSelect) {
			var items = this.getSelectedItems(this.selectedItemsGrid.dataSource);
			this.fireEvent("editcomplete", Ext.encode(items));
		} else {
			var path = this.getSelectedStructureTreeRow();
			var item = this.structureItemsGrid.selModel.selData[0];
			if (item && path) {
				var isVirtual = item.IsVirtual == true;
				var isOpposite = path.IsBackRelation == true || path.IsPartOfBackRelation == true;
				var itemInfo = {
					caption: isVirtual ? "" : this.getShortCaption(item["Caption"]),
					metaPath: item["UId"],
					dataValueTypeName: item["DataValueType"],
					referenceSchemaUId: item["ReferenceSchemaUId"],
					comparisonType: this.getComparisonType(isOpposite, isVirtual, item),
					aggregationType: this.getAggregationType(isOpposite, isVirtual, item)
				};
				itemInfo = this.getItemInfoByPath(path, itemInfo);
				this.fireEvent("editcomplete", Ext.encode(itemInfo));
			}
		}
	},

	onItemsGridDblClick: function(e) {
		var okButton = this.findOkButton();
		if (okButton) {
			e.button = 0;
			okButton.onClick(e);
		}
	},

	confirmRemoveSelectedItem: function(row) {
		var stringList = Ext.StringList('WC.StructureExplorer');
		Ext.MessageBox.confirm(stringList.getValue("MenuItems.ConfirmRemoveSelectedItemsCaption"), 
			stringList.getValue("MenuItems.ConfirmRemoveSelectedItems").replace("{0}", row.Caption), 
			function(btn) {
				if (btn == 'yes') {
					this.removeSelectedItemsRow(row);
				}
			}, this);
		return false;
	},

	removeSelectedItemsRow: function(row) {
		var dataSource = this.selectedItemsGrid.dataSource;
		var id = row.Id;
		delete this.selectedItemsGrid.configs[id];
		dataSource.localRemove(id);
	},

	removeSelectedItemsRows: function(rows) {
		var dataSource = this.selectedItemsGrid.dataSource;
		for (var i = 0; i < rows.length; i++) {
			var row = rows[i];
			var id = row.Id;
			if (dataSource.getRow(id) && this.isItemHasDefaultSettings(row)) {
				this.removeSelectedItemsRow(row);
				rows.splice(i--, 1);
			} else {
				this.confirmRemoveSelectedItem(row);
			}
		}
	},

	onStructureItemsGridNodesDrop: function(encodedNodes, encodedTarget, encodedParentNode, point) {
		var rows = Ext.decode(encodedNodes);
		this.removeSelectedItemsRows(rows);
	},

	addToSelectedItemsByDbClick: function(treeGrid) {
		var row = this.structureItemsGrid.selModel.selData[0];
		var targetRowId = this.selectedItemsGrid.dataSource.rows.keys[this.selectedItemsGrid.dataSource.rows.length - 1];
		var path = this.getSelectedStructureTreeRow();
		this.insertRowToSelected(targetRowId, "Below", row, path);
	},

	onSelectedItemsGridNodesDrop: function(encodedNodes, encodedTarget, encodedParentNode, point) {
		var rows = Ext.decode(encodedNodes);
		var targetRow = Ext.decode(encodedTarget);
		var targetRowId = targetRow["Id"];
		var path = this.getSelectedStructureTreeRow();
		var isInnerDragDrop = this.isInnerDragDrop(rows);
		if ((point == "Append") && (targetRow != "Root")) {
			point = "Below";
		}
		var dataSource = this.selectedItemsGrid.dataSource;
		var primaryColumnName = dataSource.structure.primaryColumnName;
		if (isInnerDragDrop) {
			this.selectedItemsGrid.selModel.clearSelections();
		}
		var ids = new Array();
		if (point == "Below") {
			for (var i = rows.length - 1; i >= 0; i--) {
				var row = rows[i];
				if (isInnerDragDrop) {
					this.moveSelectedRow(row, targetRowId, point);
					ids.push(row[primaryColumnName]);
				} else {
					this.insertRowToSelected(targetRowId, point, row, path);
				}
			}
		} else {
			for (var i = 0; i < rows.length; i++) {
				var row = rows[i];
				if (isInnerDragDrop) {
					this.moveSelectedRow(row, targetRowId, point);
					ids.push(row[primaryColumnName]);
				} else {
					this.insertRowToSelected(targetRowId, point, row, path);
				}
			}
		}
		this.selectedItemsGrid.selectNodes(ids, false, true);
	},

	onSearchFieldChange: function(event) {
		var key = event.getKey();
		switch (key) {
			case Ext.EventObject.ENTER:
				event.stopEvent();
				this.updateStructureItemsGridLocalBySearchValue.defer(10, this, [event], 1);
				break;
			case Ext.EventObject.ESC:
				event.stopEvent();
				this.onClearSearchField();
				break;
			default:
				return;
		}
	},

	updateStructureItemsGridLocalBySearchValue: function() {
		var searchValue = this.searchField.getValue().toLowerCase();
		if (searchValue.length > 0) this.clearSearchToolButton.show();
		else this.clearSearchToolButton.hide();
		var dataSource = this.structureItemsGrid.dataSource;
		var rows = dataSource.rows;
		var primaryColumnName = dataSource.structure.primaryColumnName;
		var primaryDisplayColumnName = dataSource.structure.primaryDisplayColumnName;
		var rowcount = rows.length;
		var visibleNodeId;
		for (var i = 0; i < rowcount; ++i) {
			var nodeId = rows.items[i].columns[primaryColumnName];
			var node = this.structureItemsGrid.getNodeById(nodeId);
			if (node) {
				var primaryDisplayColumnValue = rows.items[i].columns[primaryDisplayColumnName];
				if (primaryDisplayColumnValue.toLowerCase().indexOf(searchValue) < 0) {
					node.ui.hide();
				} else {
					if (Ext.isEmpty(visibleNodeId)) visibleNodeId = nodeId;
					node.ui.show();
				}
			}
		}
		if (this.structureItemsGrid.rendered) {
			this.structureItemsGrid.updateScroll();
		}
		if (!Ext.isEmpty(visibleNodeId)) {
			this.structureItemsGrid.selectNodeById(visibleNodeId, false);
		}
	},

	updateStructureItemsGrid: function(definedRowValues) {
		definedRowValues = typeof(definedRowValues) == "string" ? definedRowValues : null;
		var rowValues = definedRowValues || Ext.encode(this.getSelectedStructureTreeRow(), 2);
		
		// TODO: откатить всю ревизию после выполнения #129301
		if (this.selectedItemsGrid) {
			var rv = Ext.decode(rowValues);
			rv.disableExistsColumn = true;
			rowValues = Ext.encode(rv);
		}
		this.fireEvent("updatestructureitems", this.isShowSystemColumns, rowValues);
	},

	addItemsToSelected: function(items) {
		var path = this.getSelectedStructureTreeRow();
		var point = "Append";
		for (var i = 0; i < items.length; i++) {
			var row = items[i];
			this.insertRowToSelected(null, point, row, path);
		}
	},

	isInnerDragDrop: function(rows) {
		var dataSource = this.selectedItemsGrid.dataSource;
		var primaryColumnName = dataSource.structure.primaryColumnName;
		var firstRowId = rows[0][primaryColumnName];
		return !Ext.isEmpty(dataSource.getRow(firstRowId));
	},

	isItemHasDefaultSettings: function(row) {
		var isAggregated = row && (!Ext.isEmpty(row.AggregationType) && row.AggregationType != Terrasoft.Filter.AggregationType.NONE);
		if (!isAggregated) {
			return row.Caption == row.MetaPathCaption;
		} else {
			var defaultCaption = row.MetaPathCaption;
			var aggregationCaption = this.getAggregationCaption(row.AggregationType);
			if (!Ext.isEmpty(aggregationCaption)) {
				defaultCaption = aggregationCaption + "(" + defaultCaption + ")";
			}
			if (defaultCaption !== row.Caption) return false;
			var defaultAggregationType = this.getAggregationType(true, row.IsVirtual, row);
			if (defaultAggregationType != row.AggregationType) return false;
			if (!Ext.isEmpty(row.SubFilters)) return false;
			return true;
		}
	},

	insertRowToSelected: function(targetRowId, point, row, path) {
		var dataSource = this.selectedItemsGrid.dataSource;
		var primaryColumnName = dataSource.structure.primaryColumnName;
		var isVirtual = row.IsVirtual == true;
		var isOpposite = path.IsBackRelation == true || path.IsPartOfBackRelation == true;
		var itemInfo = {
			caption: isVirtual ? "" : this.getShortCaption(row["Caption"]),
			metaPath: row["UId"],
			aggregationType: this.getAggregationType(isOpposite, isVirtual, row)
		};
		var aggregationCaption = this.getAggregationCaption(itemInfo.aggregationType);
		itemInfo = this.getItemInfoByPath(path, itemInfo);
		var metaPathCaption = itemInfo.caption;
		if (!Ext.isEmpty(aggregationCaption)) {
			itemInfo.caption = aggregationCaption + "(" + itemInfo.caption + ")";
		}
		if (isOpposite || this.isColumnDuplicationAllowed || !dataSource.findRow("MetaPath", itemInfo.metaPath)) {
			var item = {};
			Ext.apply(item, row);
			item[primaryColumnName] = new Ext.ux.GUID().id;
			item["Caption"] = itemInfo.caption;
			item["MetaPath"] = itemInfo.metaPath;
			item["MetaPathCaption"] = metaPathCaption;
			item["AggregationType"] = itemInfo.aggregationType;
			this.copyRowConfigs(row[primaryColumnName], item[primaryColumnName]);
			dataSource.onInsertResponse(item, null, targetRowId, point);
		}
	},

	moveSelectedRow: function(row, targetRowId, point) {
		var dataSource = this.selectedItemsGrid.dataSource;
		var primaryColumnName = dataSource.structure.primaryColumnName;
		var nodeId = row[primaryColumnName];
		var node = this.selectedItemsGrid.getNodeById(nodeId);
		this.selectedItemsGrid.selModel.unselect(node);
		dataSource.move(nodeId, targetRowId, point);
		this.selectedItemsGrid.selectNodeById(nodeId, false, true);
	},

	copyRowConfigs: function(targetId, destinationId) {
		var targetConfig = this.structureItemsGrid.configs[targetId];
		if (!this.selectedItemsGrid.configs) {
			this.selectedItemsGrid.configs = new Object();
		}
		this.selectedItemsGrid.configs[destinationId] = {
			columnIcons: targetConfig.columnIcons,
			dropTags: ["StructureItem"],
			dragTags: ["Root", "SelectedItem"]
		};

	},

	getSelectedItems: function(dataSource) {
		var items = new Array();
		var rows = dataSource.rows;
		for (var i = 0, count = rows.getCount(); i < count; i++) {
			var row = rows.itemAt(i);
			var item = {
				caption: row.columns["Caption"],
				columnUId: row.columns["ColumnUId"],
				metaPath: row.columns["MetaPath"],
				metaPathCaption: row.getColumnValue("MetaPathCaption"),
				aggregationType: row.getColumnValue("AggregationType"),
				subFilters: row.getColumnValue("SubFilters")
			};
			if (item.subFilters) {
				item.subFilters = item.subFilters.substring(1, item.subFilters.length - 1);
			}
			items.push(item);
		}
		return items;
	},

	getItemInfoByPath: function(row, itemInfo) {
		if (this.structureTree == null) {
			return itemInfo;
		}
		var parent = this.getParentRow(row, this.structureTree.dataSource);
		if (parent) {
			itemInfo.caption = this.getShortCaption(row["Caption"]) + (Ext.isEmpty(itemInfo.caption) ? "" : ".") + itemInfo.caption;
			itemInfo.metaPath = this.getColumnMetaPath(row) + "." + itemInfo.metaPath;
			if (row["IsPartOfProcessElement"] == true) {
				itemInfo.caption = parent.columns["Caption"] + "." + itemInfo.caption;
				return itemInfo;
			}
			return this.getItemInfoByPath(parent.columns, itemInfo);
		} else {
			return itemInfo;
		}
	},

	getColumnMetaPath: function(path) {
		var isPartOfProcessElement = path["IsPartOfProcessElement"];
		var isBackRelation = path["IsBackRelation"];
		var metapath;
		if (isBackRelation) {
			metapath = String.format("[{0}:{1}]", path["ReferenceSchemaUId"], path["UId"]);
		} else if (isPartOfProcessElement) {
			metapath = String.format("{0}.{1}", path["ParentId"], path["UId"]);
		} else {
			metapath = path["UId"];
		}
		return metapath;
	},

	getShortCaption: function(caption) {
		if (Ext.isEmpty(caption)) {
			return caption;
		}
		var bracketPosition = caption.indexOf('[');
		if (bracketPosition != -1) {
			return caption.substring(0, bracketPosition - 1);
		} else {
			return caption;
		}
	},

	getParentRow: function(row, dataSource) {
		var hierarchicalColumnName = dataSource.structure.hierarchicalColumnName;
		var parentId = row[hierarchicalColumnName];
		return dataSource.getRow(parentId);
	},

	findOkButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_ButtonOk");
	},

	findEditColumnButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_EditColumnButton");
	},

	findDragUpButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_DragUpColumnButton");
	},

	findDragDownButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_DragDownColumnButton");
	},

	findMoveDownButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_MoveDownColumnButton");
	},

	findMoveUpButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_MoveUpColumnButton");
	},

	findClearSearchToolButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_ClearSearchToolButton");
	},

	findStructurePropertiesButton: function() {
		return Ext.getCmp(this.editWindow.id + "_" + this.id + "_StructureItemsProperies");
	}
});

Ext.reg("structureexplorer", Terrasoft.StructureExplorer);