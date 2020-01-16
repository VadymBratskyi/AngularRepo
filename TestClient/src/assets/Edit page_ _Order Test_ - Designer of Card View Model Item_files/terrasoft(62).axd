Terrasoft.schemaDesigner = {};
Terrasoft.schemaDesigner.SourceCodeLanguage = {
	CSHARP: 'CSharp',
	JAVASCRIPT: 'JavaScript'
};
Terrasoft.SourceCodeLanguage = Terrasoft.schemaDesigner.SourceCodeLanguage;

Terrasoft.SchemaDesignModeManager = function (config) {
	config = config || {};
	Ext.apply(this, config);
	this.changedSettings = new Array();
	this.typeDescriptors = new Ext.util.MixedCollection(false, function (typeDescriptor) {
		return typeDescriptor.type;
	});
	Terrasoft.SchemaDesignModeManager.superclass.constructor.call(this);
	this.initComponent();
};

Ext.extend(Terrasoft.SchemaDesignModeManager, Ext.util.Observable, {

	currentItemId: '',
	cancelingPropertyChange: false,
	managerName: '',

	// private
	usageType: '',
	defaultUsageType: 'General',

	initComponent: function () {
		this.addEvents(
			'settingchanged',
			'propertychanged',
			'itemsadd',
			'itemremove',
			'itemsremove',
			'itemmove',
			'selectionchanged'
		);
		if (this.ajaxEvents) {
			if (this.ajaxEvents.selectionchanged) {
				this.on({
					selectionchanged: this.ajaxEvents.selectionchanged
				});
				delete this.ajaxEvents.selectionchanged;
			}
		}
	},

	// private
	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	// private
	cacheDescriptor: function (descriptor) {
		if (!descriptor) {
			return;
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		this.typeDescriptors.add(descriptor.type + usageType, descriptor);
	},

	isValidName: function (checkedName) {
		return checkedName.match('^(?:[A-Za-z][A-Za-z0-9_]?|_[A-Za-z_])+[A-Za-z0-9_\.]*$');
	},

	isValidColumnName: function (checkedName) {
		return checkedName.match('^(?:[A-Za-z][A-Za-z0-9]?|[A-Za-z])+[A-Za-z0-9\.]*$');
	},

	setUsageType: function (newUsageType) {
		if (newUsageType == this.usageType) {
			return;
		}
		this.usageType = newUsageType;
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var descriptor = this.getCachedDescriptor(typeName);
		this.fireEvent("selectionchanged", this.currentItemId, true, this.usageType);
	},

	getCachedDescriptor: function (typeName) {
		if (Ext.isEmpty(typeName)) {
			throw Ext.StringList('WC.SchemaDesignModeManager').getValue('SchemaDesignModeManager.TypeNotFound');
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		return this.typeDescriptors.get(typeName + usageType) || null;
	},

	getPropertyDescriptor: function (descriptor, propertyName) {
		var propertyGroups = descriptor.propertyGroups;
		for (var i = 0; i < propertyGroups.length; i++) {
			var items = propertyGroups[i].items;
			for (var j = 0; j < items.length; j++) {
				var item = items[j];
				if (item.name == propertyName) {
					return item;
				}
			}
		}
		return null;
	},

	getEventDescriptor: function (descriptor, eventName) {
		var eventGroups = descriptor.eventGroups;
		for (var i = 0; i < eventGroups.length; i++) {
			var items = eventGroups[i].items;
			for (var j = 0; j < items.length; j++) {
				var item = items[j];
				if (item.name == eventName) {
					return item;
				}
			}
		}
		return null;
	},

	findItemRow: function (itemUId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemUId);
	},

	selectItem: function (parentId, itemId) {
		this.onItemSelect(parentId, itemId);
	},

	onSettingChanged: function (settingChangedList) {
		this.fireEvent("settingchanged", settingChangedList);
		if (this.changedSettings.length > 0) {
			this.changedSettings = [];
		}
		return false;
	},

	onSettingDataSourceDataChanged: function (row, columnName) {
		var changedSettings = this.changedSettings;
		changedSettings[changedSettings.length] = {
			column: columnName,
			value: row.columns[columnName] == undefined ? row.columns[columnName + 'Id'] : row.columns[columnName]
		};
	},

	onSettingChangedResponse: function (propertyName, propertyValue) {
		// TODO убрать если не используется
	},

	onItemSelect: function (containerId, selectedItemId) {
		if (selectedItemId == this.currentItemId) {
			return;
		}
		this.currentItemId = selectedItemId;
		var typeName = this.getItemTypeName(selectedItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = (this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", selectedItemId, requireTypeDescriptor, this.usageType);
		return false;
	},

	onSelectionChangedResponse: function (itemId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (itemId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		this.schemaDataSource.setActiveRow(itemId);
	},

	addItems: function (parentId, data, position) {
		this.fireEvent('itemsadd', parentId, data, position);
	},

	removeItem: function (itemId, parentItemId, parentPropertyId) {
		if (Ext.isEmpty(itemId)) {
			return;
		}
		if (this.canRemove(itemId)) {
			this.fireEvent("itemremove", itemId, parentItemId, parentPropertyId);
		}
	},

	removeItems: function (itemIds, silentRemoveMode) {
		if (Ext.isEmpty(itemIds)) {
			return;
		}
		this.fireEvent("itemsremove", itemIds, silentRemoveMode);
	},

	setPropertyValue: function (itemId, propertyName, propertyValue) {
		if (this.cancelingPropertyChange) {
			this.cancelingPropertyChange = false;
			return;
		}
		this.fireEvent('propertychanged', itemId, propertyName, propertyValue);
	},

	cancelPropertyChange: function(itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var row = propertyDataSource.findRow('UId', itemUId);
		if (!row) {
			return;
		}
		this.cancelingPropertyChange = true;
		propertyDataSource.setColumnValue(propertyName, propertyValue);
	},

	getCurrentItemDescriptor: function () {
		var type = this.getItemTypeName(this.currentItemId);
		return this.getCachedDescriptor(type);
	},

	unselectItems: function () {
		this.currentItemId = null;
		if (this.schemaDataSource) {
			this.schemaDataSource.setActiveRow(null);
		}
	},

	canRemove: function (itemId) {
		return !this.isInheritedControl(itemId);
	},

	canMove: function (itemId) {
		return !this.isInheritedControl(itemId);
	},

	isInheritedControl: function (itemId) {
		var isInherited;
		var row = this.findItemRow(itemId);
		if (row) {
			var columnValue = row.getColumnValue("IsInherited");
			isInherited = columnValue && Ext.decode(columnValue.toLowerCase());
		}
		return Boolean(isInherited);
	}

});

Ext.reg('schemadesignmodemanager', Terrasoft.SchemaDesignModeManager);

Terrasoft.PageSchemaDesignModeManager = function (config) {
	Terrasoft.PageSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'PageSchemaManager';
};

Ext.extend(Terrasoft.PageSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	onControlsAddResponse: function (config) {
		if (!config) {
			return;
		}
		var controlConfig = {
			id: config.id,
			designMode: true,
			caption: config.caption
		};
		if (config.initialConfig) {
			Ext.apply(controlConfig, config.initialConfig);
		}
		var listenersConfig = config.listenersConfig;
		if (!Ext.isEmpty(listenersConfig)) {
			controlConfig.listeners = listenersConfig;
		}
		var dragDropMode = config.dragDropMode;
		if (!Ext.isEmpty(dragDropMode)) {
			controlConfig.dragDropMode = dragDropMode;
		}
		var control = new config.constructor(controlConfig);
		var parentControl = !Ext.isEmpty(config.parentId) ? Ext.getCmp(config.parentId) : null;
		if (!parentControl) {
			return;
		}
		if (!config.isControlVisible) {
			window[control.id] = control;
			return;
		}
		var configIndex = config.index;
		if (configIndex != undefined) {
			parentControl.insert(configIndex, control, true);
		}
		parentControl.onContentChanged();
		if (control instanceof Terrasoft.ControlLayout) {
			control.doLayout();
		}
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var changedControl = schemaDataSource.findRow('Name', propertyValue);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				//schemaDataSource.cancel(schemaActiveRow);
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	getDataSourceColumnConfig: function(config) {
		var dataSourceControlRow = this.findEntityDataSourceRow(config.UId);
		var dataSourceControlUId = dataSourceControlRow.getColumnValue('UId');
		var data = {
			isControl: false,
			TypeName: 'DataSourceStructureColumn',
			DataSourceControlUId: dataSourceControlUId,
			ColumnUId: config.UId
		};
		return data;
	},

	getDataSourceStructureConfig: function(config) {
		var dataSourceControlRow = this.findEntityDataSourceRow(config.UId);
		var dataSourceName = dataSourceControlRow.getColumnValue('Name');
		var data = {
			ControlType: "TreeGrid",
			NodeType: "PageSchemaControlType",
			DataSourceId: dataSourceName
		};
		return data;
	},

	findEntityDataSourceRow: function(uid) {
		var row = this.schemaDataSource.findRow('UId', uid);
		var typeName = row.getColumnValue('TypeName');
		if (typeName == 'EntityDataSource') {
			return row;
		}
		var parentId = row.getColumnValue('ParentId');
		if (!parentId) {
			return null;
		}
		return this.findEntityDataSourceRow(parentId);
	},

	addItems: function (parentId, data, position, targetControlId, movePosition) {
		this.fireEvent('itemsadd', parentId, data, position, targetControlId, movePosition);
	},

	onItemsDrop: function (parentId, data, position, targetControlId, movePosition) {
		var controlData = Ext.decode(data);
		var needEncode = false;
		for (var i = 0; i < controlData.length; i++) {
			var control = controlData[i];
			if (control.TypeName == 'EntityDataSource') {
				controlData[i] = this.getTreeGridDataByDataSource(control);
				needEncode = true;
			} else if (control.TypeName == 'EntityDataSourceStructure') {
				controlData[i] = this.getDataSourceStructureConfig(control);
				needEncode = true;
			} else if (control.TypeName == 'DataSourceStructureColumn') {
				controlData[i] = this.getDataSourceColumnConfig(control);
				needEncode = true;
			}
		}
		if (needEncode) {
			data = Ext.encode(controlData);
		}
		this.addItems(parentId, data, position, targetControlId, movePosition);
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var propertyColumn = propertyDataSource.getColumnByName(propertyName);
			var propertyColumnValueName = propertyColumn.valueColumnName;
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyColumnValueName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var visualizeChangedProperty = true;
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var controlId = row.getColumnValue('ControlId');
		var controlPropertyValue = propertyValue;
		if (propertyName == 'Name' || propertyName == 'Caption') {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				var parentId = row.getColumnValue('ParentId');
				if (parentId) {
					schemaDataSourceRow['ControlId'] = decodedPropertyValue;
				} else {
					visualizeChangedProperty = false;
				}
				if (structureCaptionMode == 'Name') {
					schemaDataSourceRow['Caption'] = decodedPropertyValue;
				}
			} else {
				var currentCultureName = decodedPropertyValue.currentCultureName;
				var cultureValues = decodedPropertyValue.values;
				var captionValue = '';
				for(var i = 0; i < cultureValues.length; i++) {
					var culture = cultureValues[i];
					if (!culture.hasValue) {
						continue;
					}
					if (culture.name != currentCultureName) {
						continue;
					}
					captionValue = culture.value;
					break;
				}
				controlPropertyValue = "'" + captionValue + "'";
				if (Ext.isEmpty(captionValue)) {
					captionValue = row.getColumnValue('Name');
				}
				schemaDataSourceRow[propertyName] = captionValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
		if (visualizeChangedProperty !== false) {
			this.visualizeChangedProperty(controlId, propertyName, controlPropertyValue);
		}
	},

	onBeforeControlMove: function (parentId, itemId, position, targetControlId, movePosition) {
		this.unselectItems();
		if (this.canMove(itemId)) {
			this.fireEvent('itemmove', parentId, itemId, position, targetControlId, movePosition);
		}
		return false;
	},

	onControlMoveResponse: function (controlLayoutId, controlId, position, targetControlId, movePosition) {
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('ControlId', controlId);
		var targetRow = schemaDataSource.findRow('ControlId', targetControlId);
		schemaDataSource.move(row.getPrimaryColumnValue(), targetRow.getPrimaryColumnValue(),
			movePosition);
		this.visualizeControlMove(controlLayoutId, controlId, position);
	},

	onControlRemoveResponse: function (controlId, parentControlId) {
		var control = Ext.getCmp(controlId);
		if (!control) {
			return;
		}
		var parentControl = Ext.getCmp(parentControlId) || control.ownerCt;
		if (parentControl) {
			parentControl.removeControl(control);
			parentControl.onContentChanged();
		}
	},

	onBeforeControlRemove: function (el, component) {
		return false;
	},

	onSelectionChangedResponse: function (controlUId, controlId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (controlId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		this.schemaDataSource.setActiveRow(controlUId);
		var control = Ext.getCmp(controlId);
		if (control) {
			var ownerCt = control.ownerCt;
			if (ownerCt) {
				ownerCt.selectControl(control, true);
			}
		}
	},

	getItemTypeName: function (itemId) {
		if (Ext.isEmpty(itemId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('ControlId', itemId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("ControlId", itemId);
	},

	visualizeChangedProperty: function (controlId, propertyName, propertyValue) {
		var control = Ext.getCmp(controlId);
		if (!control) {
			return;
		}
		if (propertyName == 'Name') {
			var name = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
			if (control.id != name) {
				control.handleNameChanging(control.id, name);
				Ext.ComponentMgr.register(control);
				Terrasoft.lazyInit([control.id]);
			}
		} else {
			var typeName = this.getItemTypeName(controlId);
			var descriptor = this.getCachedDescriptor(typeName);
			var propertyDescriptor = this.getPropertyDescriptor(descriptor, propertyName);
			if (!propertyDescriptor) {
				return;
			}
			var clientScriptFormat = Ext.isEmpty(propertyDescriptor.clientScriptFormat) ?
				"{0}." + propertyName[0].toLowerCase() + propertyName.slice(1) + "={1};" :
				propertyDescriptor.clientScriptFormat;
			var script = String.format(clientScriptFormat, controlId, propertyValue);
			eval(script);
		}
	},

	visualizeControlMove: function (controlLayoutId, controlId, position) {
		var controlLayout = Ext.getCmp(controlLayoutId);
		if (!controlLayout) {
			return;
		}
		var control = Ext.getCmp(controlId);
		if (!control) {
			return;
		}
		controlLayout.moveControl(control, position, true);
	},

	getTreeGridDataByDataSource: function (dataSourceData) {
		var data = {
			ControlType: "TreeGrid",
			NodeType: "PageSchemaControlType",
			DataSourceId: dataSourceData.Name
		};
		return data;
	},

	onItemSelect: function (containerId, selectedItemId) {
		if (selectedItemId == this.currentItemId) {
			return;
		}
		this.currentItemId = selectedItemId;
		var typeName = this.getItemTypeName(selectedItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", selectedItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('pageschemadesignmodemanager', Terrasoft.PageSchemaDesignModeManager);

Terrasoft.ProcessSchemaDesignModeManager = function (config) {
	Terrasoft.ProcessSchemaDesignModeManager.superclass.constructor.call(this, config);
};

Ext.extend(Terrasoft.ProcessSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	isEmbedded: null,
	ownerSchemaManagerName: null,

	cacheDescriptor: function (descriptor) {
		if (!descriptor) {
			return;
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		this.typeDescriptors.add(descriptor.type + usageType + this.currentItemId, descriptor);
	},

	getCachedDescriptor: function (typeName) {
		if (Ext.isEmpty(typeName)) {
			throw Ext.StringList('WC.SchemaDesignModeManager').getValue('SchemaDesignModeManager.TypeNotFound');
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		return this.typeDescriptors.get(typeName + usageType + this.currentItemId) || null;
	},

	moveItem: function (itemId, containerId) {
		this.unselectItems();
		this.fireEvent('itemmove', containerId, itemId, '');
		return false;
	},

	onElementMoveResponse: function (elementUId, sourceContainerId, targetContainerUId, movePosition) {
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', elementUId);
		var targetRow = schemaDataSource.findRow('UId', targetContainerUId);
		schemaDataSource.move(row.getPrimaryColumnValue(), targetRow.getPrimaryColumnValue(),
			movePosition);
	},

	getItemNamespace: function(key, namespaceColumnName) {
		if (!key) {
			return null;
		}
		var currentRow;
		var schemaDataSource = this.schemaDataSource;
		var primaryColumnName = schemaDataSource.structure.primaryColumnName;
		var hierarchicalColumnName = schemaDataSource.structure.hierarchicalColumnName;
		if (key instanceof Terrasoft.Row) {
			currentRow = key;
		} else {
			currentRow = schemaDataSource.findRow(primaryColumnName, key);
		}
		if (!currentRow) {
			return null;
		}
		var parentColumnPrimaryValue = currentRow.getColumnValue(hierarchicalColumnName);
		var namespace = '';
		if (parentColumnPrimaryValue) {
			var parentRow = schemaDataSource.findRow(primaryColumnName, parentColumnPrimaryValue);
			namespace = this.getItemNamespace(parentRow, namespaceColumnName);
		}
		var curentNamespace = currentRow.getColumnValue(namespaceColumnName);
		curentNamespace = curentNamespace ? curentNamespace : '';
		if (!Ext.isEmpty(namespace) && !Ext.isEmpty(curentNamespace)) {
			if (namespace.match(curentNamespace)) {
				var primaryDisplayColumnName = schemaDataSource.structure.primaryDisplayColumnName;
				return namespace + '.' + currentRow.getColumnValue(primaryDisplayColumnName);
			} else {
				return namespace + '.' + curentNamespace;
			}
		}
		return namespace + curentNamespace;
	},

	findRowsByColumn: function (dataSource, columnName, value) {
		var findRows = [];
		if (!dataSource.rows || !columnName) {
			return findRows;
		}
		var dataSourceRows = dataSource.rows;
		for (var i = 0, l = dataSourceRows.length; i < l; i++) {
			var item = dataSourceRows.items[i];
			var columnValue = item.getColumnValue(columnName) || "";
			if (columnValue.toUpperCase() == value.toUpperCase()) {
				findRows.push(item);
			}
		}
		return findRows;
	},

	isNameDublicate: function(elementUId, checkedName) {
		var namespaceColumnName = "Namespace";
		var nameColumnName = "Name";
		var schemaDataSource = this.schemaDataSource;
		var primaryColumnName = schemaDataSource.structure.primaryColumnName;
		var primaryDisplayColumnName = schemaDataSource.structure.primaryDisplayColumnName;
		var elementRow = schemaDataSource.findRow(schemaDataSource.structure.primaryColumnName, elementUId);
		var currentNamespace = elementRow.getColumnValue(namespaceColumnName);
		var currentName = elementRow.getColumnValue(primaryDisplayColumnName);
		var existedElements = this.findRowsByColumn(schemaDataSource, nameColumnName, checkedName);
		if (existedElements.length === 0) {
			return false;
		}
		var currentUId = elementRow.getColumnValue(primaryColumnName);
		var currentElementNamespace = this.getItemNamespace(elementUId, namespaceColumnName);
		if (!Ext.isEmpty(currentNamespace)) {
			currentElementNamespace = currentElementNamespace.replace(currentName, checkedName);
		}
		for (var i = 0; i < existedElements.length; i++) {
			var existedElement = existedElements[i];
			if (existedElement.getColumnValue(primaryColumnName) === currentUId) {
				if (currentName && (currentName.toUpperCase() === checkedName.toUpperCase())) {
					return false;
				}
			}
			var existElementNamespace = this.getItemNamespace(existedElement, namespaceColumnName);
			if (currentElementNamespace.toUpperCase() === existElementNamespace.toUpperCase() ||
					currentElementNamespace.match(existElementNamespace) ||
					existElementNamespace.match(currentElementNamespace)) {
				return true;
			}
		}
		return false;
	},

	verifyName: function(elementUId, name, row) {
		schemaDataSource = this.schemaDataSource;
		var cancelEvent = !this.isValidName(name);
		var stringList;
		var messageCaption = '';
		var messageText = '';
		if (cancelEvent) {
			cancelEvent = true;
			stringList = Ext.StringList('WebApp.Common');
			messageCaption = stringList.getValue('Message.NotValidName.Caption');
			messageText = stringList.getValue('Message.NotValidName.Msg');
		}
		if (!cancelEvent && this.isNameDublicate(elementUId, name)) {
			cancelEvent = true;
			stringList = Ext.StringList('WebApp.Common');
			messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
			messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), name);
		}
		if (cancelEvent) {
			var schemaActiveRow = schemaDataSource.activeRow;
			row.columns.Name = schemaActiveRow.columns.Name;
			schemaActiveRow.clearState();
			Ext.MessageBox.show({
				caption: messageCaption,
				msg: messageText,
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
			return false;
		}
		return true;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var elementUId = (columnName == 'UId') ? row.getColumnOldValue('UId') :
			row.getColumnValue('UId');
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			if (!this.verifyName(elementUId, propertyValue, row)) {
				this.setPropertyValue(elementUId, columnName, row.modifiedValues.Name);
				return false;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(elementUId, columnName, propertyValue);
	},

	changeItemNamespace: function(elementUId, namespace) {
		var row = schemaDataSource.findRow('UId', elementUId);
		row.setColumnValue('Namespace', Ext.decode(namespace));
	},

	onPropertyChangedMessage: function (messageToken) {
		if (messageToken) {
			var stringList = Ext.StringList('WebApp.Common');
			Ext.MessageBox.show({
				caption: stringList.getValue('Message.' + messageToken + '.Caption'),
				msg: stringList.getValue('Message.' + messageToken + '.Msg'),
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
		}
	},

	onPropertyChangedResponse: function (elementUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var propertyDataSourceRow = propertyDataSource.findRow('UId', elementUId);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			var propertyColumn = propertyDataSource.getColumnByName(propertyName);
			var propertyColumnValueName = propertyColumn.valueColumnName;
			updatedRow[propertyColumnValueName] = Ext.decode(propertyValue);
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = this.settingsDataSource.getColumnValue('StructureCaptionMode');
		if ((propertyName == 'Caption' && structureCaptionMode == 'Caption') || propertyName == 'Name') {
			var schemaDataSource = this.schemaDataSource;
			var row = schemaDataSource.findRow('UId', elementUId);
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			var decodedPropertyValue = Ext.decode(propertyValue);
			if (propertyName == 'Caption') {
				var currentCultureName = decodedPropertyValue.currentCultureName;
				var cultureValues = decodedPropertyValue.values;
				var captionValue = '';
				for(var i = 0; i < cultureValues.length; i++) {
					var culture = cultureValues[i];
					if (!culture.hasValue) {
						continue;
					}
					if (culture.name != currentCultureName) {
						continue;
					}
					captionValue = culture.value;
					break;
				}
				if (Ext.isEmpty(captionValue)) {
					captionValue = row.getColumnValue('Name');
				}
				schemaDataSourceRow[propertyName] = captionValue;
			} else {
				schemaDataSourceRow[propertyName] = decodedPropertyValue;
			}
			if (propertyName == 'Name' && structureCaptionMode == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
	},

	onItemSelect: function (containerId, selectedItemId) {
		if (selectedItemId == this.currentItemId) {
			return;
		}
		this.currentItemId = selectedItemId;
		var typeName = this.getItemTypeName(selectedItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = (this.getCachedDescriptor(typeName) == null);
		var row = this.findItemRow(selectedItemId);
		var rowValues = Ext.encode(row.columns, 2);
		this.fireEvent("selectionchanged", selectedItemId, requireTypeDescriptor, this.usageType, rowValues);
		return false;
	},

	setPropertyValue: function (itemId, propertyName, propertyValue) {
		if (this.cancelingPropertyChange) {
			this.cancelingPropertyChange = false;
			return;
		}
		var row = this.findItemRow(itemId);
		var rowValues = Ext.encode(row.columns, 2);
		this.fireEvent('propertychanged', itemId, propertyName, propertyValue, this.cancelingPropertyChange, rowValues,
			this.usageType);
	}

});

Ext.reg('processschemadesignmodemanager', Terrasoft.ProcessSchemaDesignModeManager);

Terrasoft.EntitySchemaDesignModeManager = function (config) {
	Terrasoft.EntitySchemaDesignModeManager.superclass.constructor.call(this, config);
};

Ext.extend(Terrasoft.EntitySchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	cacheDescriptor: function (descriptor) {
		if (!descriptor) {
			return;
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		this.typeDescriptors.add(descriptor.type + usageType + this.currentItemId, descriptor);
	},

	setUsageType: function (newUsageType) {
		if (newUsageType == this.usageType) {
			return;
		}
		this.usageType = newUsageType;
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var descriptor = this.getCachedDescriptor(typeName);
		this.fireEvent("selectionchanged", this.currentItemId, true, this.usageType);
	},

	getCachedDescriptor: function (typeName) {
		if (Ext.isEmpty(typeName)) {
			throw Ext.StringList('WC.SchemaDesignModeManager').getValue('SchemaDesignModeManager.TypeNotFound');
		}
		var usageType = this.usageType;
		if (Ext.isEmpty(usageType)) {
			usageType = this.defaultUsageType;
		}
		return this.typeDescriptors.get(typeName + usageType + this.currentItemId) || null;
	},

	addItems: function (parentId, data, position) {
		this.fireEvent('itemsadd', parentId, data, position);
	},

	removeItems: function (ids) {
		if (Ext.isEmpty(ids)) {
			return;
		}
		this.fireEvent("itemremove", ids);
	},

	moveItem: function (parentId, itemId, position) {
		this.unselectItems();
		this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = (columnName == 'UId') ? row.getColumnOldValue('UId') :
			row.getColumnValue('UId');
		var schemaDataSourceRow = this.schemaDataSource.findRow('UId', itemUId);
		var parentId = schemaDataSourceRow.getColumnValue('ParentId');
		var data = new Object();
		data.itemId = itemUId;
		data.parentId = parentId;
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			var typeName = this.getItemTypeName(this.currentItemId);
			if (!this.isValidName(propertyValue) ||
					((typeName == "EntitySchemaColumn") && !this.isValidColumnName(propertyValue))) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var schemaDataSourceRowNodeType = schemaDataSourceRow.getColumnValue('NodeType');
			var columnValues = [
				{name: "Name", value: propertyValue, ignoreCase: true},
				{name: "NodeType", value: schemaDataSourceRowNodeType, ignoreCase: true}
			];
			var changedControl = schemaDataSource.findRowByColumnValues(columnValues);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(Ext.encode(data), columnName, propertyValue);
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var decodedPropertyValue = Ext.decode(propertyValue);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSource = this.schemaDataSource;
			var row = schemaDataSource.findRow('UId', itemUId);
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name' && structureCaptionMode == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			else {
				schemaDataSource.updateRow(schemaDataSourceRow);
			}
		}
	},

	onItemSelect: function (parentId, itemId) {
		if (itemId == this.currentItemId) {
			return;
		}
		this.currentItemId = itemId;
		var typeName = this.getItemTypeName(itemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		// TODO this.getCachedDescriptor при добавлении колонок после указания род.схемы сбоит
		var requireTypeDescriptor = (this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", itemId, requireTypeDescriptor, this.usageType);
		return false;
	}
});

Ext.reg('entityschemadesignmodemanager', Terrasoft.EntitySchemaDesignModeManager);

Terrasoft.ImageListSchemaDesignModeManager = function (config) {
	Terrasoft.ImageListSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'ImageListSchemaManager';
};

Ext.extend(Terrasoft.ImageListSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	onControlsAddResponse: function (config) {
		var controlConfig = {
			id: config.clientId,
			designMode: true,
			width: '150px',
			height: '150px',
			center: true
		};
		var listenersConfig = config.listenersConfig;
		if (!Ext.isEmpty(listenersConfig)) {
			controlConfig.listeners = listenersConfig;
		}
		var dragDropMode = config.dragDropMode;
		if (!Ext.isEmpty(dragDropMode)) {
			controlConfig.dragDropMode = dragDropMode;
		}
		var control = new config.constructor(controlConfig);
		var schemaDataSource = this.schemaDataSource;
		var parentRow = schemaDataSource.findRow('UId', config.parentId);
		var parentControlId = parentRow.getColumnValue('ClientId');
		var parentControl = !Ext.isEmpty(parentControlId) ? Ext.getCmp(parentControlId) : null;
		if (!parentControl) {
			return;
		}
		var imageLabel = new Terrasoft.Label({
			id: config.Name + 'Label',
			style: 'text-align:center',
			width: '100%'
		});
		imageLabel.setCaption(config.caption);
		var configIndex = config.index;
		if (configIndex != undefined) {
			parentControl.insert(configIndex, control, true);
			parentControl.insert(configIndex + 1, imageLabel, true);
		}
		parentControl.onContentChanged();
		if (control instanceof Terrasoft.ControlLayout) {
			control.doLayout();
		}
		control.setEdges("1 1 1 1");
		var row = schemaDataSource.findRow('UId', config.id);
		schemaDataSource.setActiveRow(row.getPrimaryColumnValue());
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var changedControl = schemaDataSource.findRow('Name', propertyValue);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var primaryColumnName = propertyDataSource.getPrimaryColumnName();
		var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
		var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
		if (propertyName != 'Image') {
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var visualizeChangedProperty = true;
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var clientId = row.getColumnValue('ClientId');
		if (propertyName == 'Caption') {
			var label = Ext.getCmp(row.getColumnValue('Name') + 'Label');
			label.setCaption(decodedPropertyValue);
		}
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				var parentId = row.getColumnValue('ParentId');
				if (parentId) {
					schemaDataSourceRow['ClientId'] = decodedPropertyValue;
				} else {
					visualizeChangedProperty = false;
				}
				if (structureCaptionMode == 'Name') {
					schemaDataSourceRow['Caption'] = decodedPropertyValue;
				}
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
		if (visualizeChangedProperty !== false) {
			this.visualizeChangedProperty(itemUId, clientId, propertyName, propertyValue);
		}
	},

	onBeforeControlMove: function (parentId, itemId, position) {
		this.unselectItems();
		if (this.canMove(itemId)) {
			this.fireEvent('itemmove', parentId, itemId, position);
		}
		return false;
	},

	onControlMoveResponse: function (controlLayoutUId, controlUId, position, targetControlUId, movePosition) {
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', controlUId);
		var targetRow = schemaDataSource.findRow('UId', targetControlUId);
		schemaDataSource.move(row.getPrimaryColumnValue(), targetRow.getPrimaryColumnValue(), movePosition);
		var parentId = schemaDataSource.findRow('UId', controlLayoutUId).getColumnValue('ClientId');
		var itemId = row.getColumnValue('ClientId');
		this.visualizeControlMove(parentId, itemId, position, movePosition);
	},

	onControlRemoveResponse: function (controlId, parentControlId) {
		var control = Ext.getCmp(controlId);
		var label = Ext.getCmp(controlId + 'Label');
		if (!control) {
			return;
		}
		var parentControl = Ext.getCmp(parentControlId) || control.ownerCt;
		if (parentControl) {
			parentControl.removeControl(control);
			parentControl.removeControl(label);
			parentControl.onContentChanged();
		}
	},

	onBeforeControlRemove: function (el, component) {
		return false;
	},

	onSelectionChangedResponse: function (controlUId, controlId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (controlId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		var schemaDataSource = this.schemaDataSource;
		schemaDataSource.setActiveRow(controlUId);
		var controlClientId = schemaDataSource.activeRow.getColumnValue('ClientId');
		var control = Ext.getCmp(controlClientId);
		if (control) {
			var ownerCt = control.ownerCt;
			if (ownerCt) {
				ownerCt.selectControl(control, true);
			}
		}
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("ControlId", itemId);
	},

	visualizeChangedProperty: function (itemId, controlId, propertyName, propertyValue) {
		var control = Ext.getCmp(controlId);
		var label = Ext.getCmp(controlId + 'Label');
		if (!control) {
			return;
		}
		if (propertyName == 'Name') {
			var name = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
			if (control.id != name) {
				window[control.id] = undefined;
				window[label.id] = undefined;
				Ext.ComponentMgr.unregister(control);
				Ext.ComponentMgr.unregister(label);
				control.id = name;
				label.id = name + 'Label';
				Ext.ComponentMgr.register(control);
				Ext.ComponentMgr.register(label);
				Terrasoft.lazyInit([control.id]);
				Terrasoft.lazyInit([label.id]);
			}
		} else {
			var typeName = this.getItemTypeName(itemId);
			var descriptor = this.getCachedDescriptor(typeName);
			var propertyDescriptor = this.getPropertyDescriptor(descriptor, propertyName);
			var clientScriptFormat = Ext.isEmpty(propertyDescriptor.clientScriptFormat) ?
				"{0}." + propertyName[0].toLowerCase() + propertyName.slice(1) + "={1};" :
				propertyDescriptor.clientScriptFormat;
			var script = String.format(clientScriptFormat, controlId, propertyValue);
			eval(script);
		}
	},

	visualizeControlMove: function (controlLayoutId, controlId, position, movePosition) {
		var controlLayout = Ext.getCmp(controlLayoutId);
		if (!controlLayout) {
			return;
		}
		var control = Ext.getCmp(controlId);
		var label = Ext.getCmp(controlId + 'Label');
		if (!control) {
			return;
		}
		if (movePosition == 'Above') {
			controlLayout.moveControl(control, position * 2, true);
			controlLayout.moveControl(label, (position * 2) + 1, true);
		} else {
			controlLayout.moveControl(control, (position * 2) + 1, true);
			controlLayout.moveControl(label, (position * 2) + 1, true);
		}
	},

	onItemSelect: function (containerId, selectedItemId) {
		if (selectedItemId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('ClientId', selectedItemId);
		this.currentItemId = row.getPrimaryColumnValue();
		//this.currentItemId = selectedItemId;
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = (this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('imagelistschemadesignmodemanager', Terrasoft.ImageListSchemaDesignModeManager);

Terrasoft.ProcessUserTaskSchemaDesignModeManager = function (config) {
	Terrasoft.ProcessUserTaskSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'ProcessUserTaskSchemaManager';
};

Ext.extend(Terrasoft.ProcessUserTaskSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	addItems: function (selectedItemUId, data, position) {
		this.fireEvent('itemsadd', selectedItemUId, data, position);
	},

	moveItem: function (parentId, itemId, position) {
		this.unselectItems();
		this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var schemaDataSourceRow = schemaDataSource.findRow('UId', itemUId);
			var parentUId = schemaDataSourceRow.getColumnValue('ParentUId');
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var columnValues = [
				{name: "Name", value: propertyValue, ignoreCase: true},
				{name: "ParentUId", value: parentUId, ignoreCase: true}
			];
			var changedControl = schemaDataSource.findRowByColumnValues(columnValues);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	onPropertyChangedMessage: function (messageToken) {
		if (messageToken) {
			var stringList = Ext.StringList('WebApp.Common');
			Ext.MessageBox.show({
				caption: stringList.getValue('Message.' + messageToken + '.Caption'),
				msg: stringList.getValue('Message.' + messageToken + '.Msg'),
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
		}
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var clientId = row.getColumnValue('ClientId');
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
	},

	onSelectionChangedResponse: function (controlUId, controlId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (controlUId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		var schemaDataSource = this.schemaDataSource;
		schemaDataSource.setActiveRow(controlUId);
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemId);
	},

	onItemSelect: function (containerId, selectedItemUId) {
		if (selectedItemUId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('UId', selectedItemUId);
		this.currentItemId = row.getPrimaryColumnValue();
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('processusertaskschemadesignmodemanager', Terrasoft.ProcessUserTaskSchemaDesignModeManager);

Terrasoft.SourceCodeSchemaDesignModeManager = function (config) {
	Terrasoft.SourceCodeSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'SourceCodeSchemaManager';
};

Ext.extend(Terrasoft.SourceCodeSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	addItems: function (selectedItemUId, data, position) {
		this.fireEvent('itemsadd', selectedItemUId, data, position);
	},

	moveItem: function (parentId, itemId, position) {
		this.unselectItems();
		this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var schemaDataSourceRow = schemaDataSource.findRow('UId', itemUId);
			var parentId = schemaDataSourceRow.getColumnValue('ParentId');
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var columnValues = [
				{name: "Name", value: propertyValue, ignoreCase: true},
				{name: "ParentId", value: parentId, ignoreCase: true}
			];
			var changedControl = schemaDataSource.findRowByColumnValues(columnValues);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	onPropertyChangedMessage: function (messageToken) {
		if (messageToken) {
			var stringList = Ext.StringList('WebApp.Common');
			Ext.MessageBox.show({
				caption: stringList.getValue('Message.' + messageToken + '.Caption'),
				msg: stringList.getValue('Message.' + messageToken + '.Msg'),
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
		}
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
		if (typeof(decodedPropertyValue) === "string") {
			decodedPropertyValue = Ext.util.Format.htmlDecode(decodedPropertyValue);
		}
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var clientId = row.getColumnValue('ClientId');
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
	},

	onSelectionChangedResponse: function (controlUId, controlId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (controlUId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		var schemaDataSource = this.schemaDataSource;
		schemaDataSource.setActiveRow(controlUId);
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemId);
	},

	onItemSelect: function (containerId, selectedItemUId) {
		if (selectedItemUId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('UId', selectedItemUId);
		this.currentItemId = row.getPrimaryColumnValue();
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('sourcecodeschemadesignmodemanager', Terrasoft.SourceCodeSchemaDesignModeManager);

Terrasoft.ClientUnitSchemaDesignModeManager = function (config) {
	Terrasoft.ClientUnitSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'ClientUnitSchemaManager';
};

Ext.extend(Terrasoft.ClientUnitSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	addItems: function (selectedItemUId, data, position) {
		this.fireEvent('itemsadd', selectedItemUId, data, position);
	},

	moveItem: function (parentId, itemId, position) {
		this.unselectItems();
		this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	isUniqueName: function(itemUId, checkedName) {
		const rows = this.schemaDataSource.rows.filterBy(function(row) {
			return row.getColumnValue('Name') === checkedName &&
				row.getPrimaryColumnValue() !== itemUId;
		}, this);
		return rows.getCount() === 0;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName === "Name") {
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			if (!cancelEvent && !this.isUniqueName(itemUId, propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				var messagegTextTpl = stringList.getValue('Message.DesignDublicateNames.Msg');
				messageText = String.format(messagegTextTpl, propertyValue);
			}
			if (cancelEvent) {
				var activeRow = this.schemaDataSource.activeRow;
				row.columns.Name = activeRow.columns.Name;
				activeRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	onPropertyChangedMessage: function (messageToken) {
		if (messageToken) {
			var stringList = Ext.StringList('WebApp.Common');
			Ext.MessageBox.show({
				caption: stringList.getValue('Message.' + messageToken + '.Caption'),
				msg: stringList.getValue('Message.' + messageToken + '.Msg'),
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
		}
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
		if (typeof(decodedPropertyValue) === "string") {
			decodedPropertyValue = Ext.util.Format.htmlDecode(decodedPropertyValue);
		}
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var clientId = row.getColumnValue('ClientId');
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
	},

	onSelectionChangedResponse: function (controlUId, controlId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = (controlUId == this.currentItemId);
		if (!this.isCurrentItemResponse) {
			return;
		}
		var schemaDataSource = this.schemaDataSource;
		schemaDataSource.setActiveRow(controlUId);
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemId);
	},

	onItemSelect: function (containerId, selectedItemUId) {
		if (selectedItemUId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('UId', selectedItemUId);
		this.currentItemId = row.getPrimaryColumnValue();
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('clientunitschemadesignmodemanager', Terrasoft.ClientUnitSchemaDesignModeManager);


Terrasoft.ReportSchemaDesignModeManager = function (config) {
	Terrasoft.ReportSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'ReportSchemaManager';
};

Ext.extend(Terrasoft.ReportSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	addItems: function (selectedItemUId, data, position) {
		// this.fireEvent('itemsadd', selectedItemUId, data, position);
	},

	moveItem: function (parentId, itemId, position) {
		//this.unselectItems();
		//this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = row.getPrimaryColumnValue();
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var changedControl = schemaDataSource.findRow('Name', propertyValue);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				//schemaDataSource.cancel(schemaActiveRow);
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(itemUId, columnName, propertyValue);
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var primaryColumnName = propertyDataSource.getPrimaryColumnName();
		var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
		var decodedPropertyValue = Ext.isEmpty(propertyValue) ? "" : Ext.decode(propertyValue);
		var updatedRow = {};
		updatedRow[primaryColumnName] = primaryColumnValue;
		updatedRow[propertyName] = decodedPropertyValue;
		propertyDataSource.updateRow(updatedRow);
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var schemaDataSource = this.schemaDataSource;
		var row = schemaDataSource.findRow('UId', itemUId);
		var clientId = row.getColumnValue('ClientId');
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			schemaDataSource.updateRow(schemaDataSourceRow);
		}
	},

	onSelectionChangedResponse: function (schemaUId, schemaId, typeName, descriptor) {
		this.cacheDescriptor(descriptor);
		this.isCurrentItemResponse = true;
		this.currentItemId = schemaUId;
		var schemaDataSource = this.schemaDataSource;
		schemaDataSource.setActiveRow(schemaUId);
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemId);
	},

	onItemSelect: function (containerId, selectedItemUId) {
		if (selectedItemUId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('UId', selectedItemUId);
		this.currentItemId = row.getPrimaryColumnValue();
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Terrasoft.ValueListSchemaDesignModeManager = function (config) {
	Terrasoft.ValueListSchemaDesignModeManager.superclass.constructor.call(this, config);
	Ext.ImageUrlHelper.DesignSchemaManagerName = 'ValueListSchemaManager';
};

Ext.extend(Terrasoft.ValueListSchemaDesignModeManager, Terrasoft.SchemaDesignModeManager, {

	addItems: function (selectedItemUId, data, position) {
		this.fireEvent('itemsadd', selectedItemUId, data, position);
	},

	moveItem: function (parentId, itemId, position) {
		this.unselectItems();
		this.fireEvent('itemmove', parentId, itemId, position);
		return false;
	},

	removeItems: function (ids) {
		if (Ext.isEmpty(ids)) {
			return;
		}
		this.fireEvent("itemremove", ids);
	},

	onPropertyChangedMessage: function (messageToken) {
		if (messageToken) {
			var stringList = Ext.StringList('WebApp.Common');
			Ext.MessageBox.show({
				caption: stringList.getValue('Message.' + messageToken + '.Caption'),
				msg: stringList.getValue('Message.' + messageToken + '.Msg'),
				buttons: Ext.MessageBox.OK,
				icon: Ext.MessageBox.INFO
			});
		}
	},

	onPropertyDataSourceDataChanged: function (row, columnName) {
		var itemUId = (columnName == 'UId') ? row.getColumnOldValue('UId') :
			row.getColumnValue('UId');
		var schemaDataSourceRow = this.schemaDataSource.findRow('UId', itemUId);
		var parentId = schemaDataSourceRow.getColumnValue('ParentId');
		var data = new Object();
		data.itemId = itemUId;
		data.parentId = parentId;
		var propertyValue = row.getColumnValue(columnName);
		if (columnName == "Name") {
			schemaDataSource = this.schemaDataSource;
			var cancelEvent = false;
			var stringList = Ext.StringList('WebApp.Common');
			var messageCaption = '';
			var messageText = '';
			if (!this.isValidName(propertyValue)) {
				cancelEvent = true;
				messageCaption = stringList.getValue('Message.NotValidName.Caption');
				messageText = stringList.getValue('Message.NotValidName.Msg');
			}
			var changedControl = schemaDataSource.findRow('Name', propertyValue);
			if (changedControl != null && (changedControl.columns.UId != itemUId)) {
				cancelEvent = cancelEvent || true;
				messageCaption = stringList.getValue('Message.DesignDublicateNames.Caption');
				messageText = String.format(stringList.getValue('Message.DesignDublicateNames.Msg'), propertyValue);
			}
			if (cancelEvent) {
				var schemaActiveRow = schemaDataSource.activeRow;
				row.columns.Name = schemaActiveRow.columns.Name;
				schemaActiveRow.clearState();
				Ext.MessageBox.show({
					caption: messageCaption,
					msg: messageText,
					buttons: Ext.MessageBox.OK,
					icon: Ext.MessageBox.INFO
				});
				return;
			}
			this.currentItemId = propertyValue;
		}
		this.setPropertyValue(Ext.encode(data), columnName, propertyValue);
	},

	onPropertyChangedResponse: function (itemUId, propertyName, propertyValue) {
		var propertyDataSource = this.propertyDataSource;
		var settingsDataSource = this.settingsDataSource;
		var propertyDataSourceRow = propertyDataSource.findRow('UId', itemUId);
		var structureCaptionMode = settingsDataSource.getColumnValue('StructureCaptionMode');
		var decodedPropertyValue = Ext.decode(propertyValue);
		if (propertyDataSourceRow) {
			var primaryColumnName = propertyDataSource.getPrimaryColumnName();
			var primaryColumnValue = propertyDataSource.getColumnValue(primaryColumnName);
			var updatedRow = {};
			updatedRow[primaryColumnName] = primaryColumnValue;
			updatedRow[propertyName] = decodedPropertyValue;
			propertyDataSource.updateRow(updatedRow);
		}
		if (propertyName == 'Name' || (propertyName == 'Caption' && structureCaptionMode == 'Caption')) {
			var schemaDataSource = this.schemaDataSource;
			var row = schemaDataSource.findRow('UId', itemUId);
			var schemaDataSourceRow = {};
			schemaDataSourceRow[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
			schemaDataSourceRow[propertyName] = decodedPropertyValue;
			if (propertyName == 'Name' && structureCaptionMode == 'Name') {
				schemaDataSourceRow['Caption'] = decodedPropertyValue;
			}
			else {
				schemaDataSource.updateRow(schemaDataSourceRow);
			}
		}
	},

	getItemTypeName: function (itemUId) {
		if (Ext.isEmpty(itemUId)) {
			return '';
		}
		var row = this.schemaDataSource.findRow('UId', itemUId);
		return row ? row.getColumnValue('TypeName') : '';
	},

	findItemRow: function (itemId) {
		var schemaDataSource = this.schemaDataSource;
		return schemaDataSource.findRow("UId", itemId);
	},

	onItemSelect: function (containerId, selectedItemUId) {
		if (selectedItemUId == this.currentItemId) {
			return;
		}
		var row = this.schemaDataSource.findRow('UId', selectedItemUId);
		this.currentItemId = row.getPrimaryColumnValue();
		var typeName = this.getItemTypeName(this.currentItemId);
		if (Ext.isEmpty(typeName)) {
			return;
		}
		var requireTypeDescriptor = true; //(this.getCachedDescriptor(typeName) == null);
		this.fireEvent("selectionchanged", this.currentItemId, requireTypeDescriptor, this.usageType);
		return false;
	}

});

Ext.reg('valuelistschemadesignmodemanager', Terrasoft.ValueListSchemaDesignModeManager);
Ext.reg('reportschemadesignmodemanager', Terrasoft.ReportSchemaDesignModeManager);

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}