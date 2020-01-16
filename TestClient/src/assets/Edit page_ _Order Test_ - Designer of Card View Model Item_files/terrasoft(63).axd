var codeText = '';
var lessText = '';
var schemaDifferences = '';

function onAddItemButtonClick() {
	var selectedNode = SourceCodeGrid.getSelectionModel().selNodes[0];
	if (selectedNode) {
		var data = new Object();
		var row = ClientUnitSchemaDataSource.findRow('UId', selectedNode.id);
		data.typeName = row.getColumnValue('TypeName');
		data.parentId = row.getColumnValue('ParentId');
		DesignModeManager.addItems(row.getColumnValue('UId'), Ext.encode(data), 0);
	}
}

function onSchemaDataSourceActiveRowChanged(dataSource, primaryColumnValue) {
	var activeRow = dataSource.getRow(primaryColumnValue);
	if (activeRow) {
		var controlId = activeRow.getColumnValue('UId');
		DesignModeManager.onItemSelect('', controlId);
		SourceCodeGrid.selectNodeById(primaryColumnValue);
		SourceCodeGrid.setActiveNodeById(primaryColumnValue);
		var rowIndex = activeRow.index();
		var rowsCount = dataSource.rows.length;
		var enableUpButton = rowIndex > 1;
		var enableDownButton = rowIndex + 1 == rowsCount ? false : rowIndex >= 1;
		MoveUp.setEnabled(enableUpButton);
		MoveDown.setEnabled(enableDownButton);
		MoveUpMenuItem.setEnabled(enableUpButton);
		MoveDownMenuItem.setEnabled(enableDownButton);
	}
}

function onPropertiesDataSourceLoaded(dataSource, dataArray, request) {
	PropertiesDataSource.setActiveRow(0);
}

function onPropertiesDataSourceStructureLoaded(dataSource) {
	if (DesignModeManager.isCurrentItemResponse) {
		var descriptor = DesignModeManager.getCurrentItemDescriptor();
		objectInspector.rebuild(descriptor);
	}
}

function onSettingsDataSourceLoaded(dataSource, dataArray, request) {
	SettingsDataSource.setActiveRow(0);
}

function onObjectInspectorDesignModeUsageTypeChange(designModeUsageType) {
	DesignModeManager.setUsageType(designModeUsageType);
	var descriptor = DesignModeManager.getCurrentItemDescriptor();
	objectInspector.rebuild(descriptor);
}

function removeSelectedClientUnitSchemaItem() {
	var selNodeId = SourceCodeGrid.selModel.selNodes[0].id;
	var row = ClientUnitSchemaDataSource.getRow(selNodeId);
	var itemUId = row.getColumnValue('UId');
	var parentItemId = row.getColumnValue('ParentId');
	DesignModeManager.removeItem(itemUId, parentItemId, null);
}

function MoveUpButtonClick() {
	var selectedNode = SourceCodeGrid.getSelectionModel().selNodes[0];
	if (selectedNode) {
		var data = new Object();
		data.position = "Above";
		DesignModeManager.moveItem('', selectedNode.id, "Above");
	}
}

function MoveDownButtonClick() {
	var selectedNode = SourceCodeGrid.getSelectionModel().selNodes[0];
	if (selectedNode) {
		var data = new Object();
		data.position = "Below";
		DesignModeManager.moveItem('', selectedNode.id, "Below");
	}
}

function onPageSchemaControlsTreeBeforeNodesDrop(dropEvent) {
	DesignModeManager.unselectItems();
	return dropEvent.customDrop = true;
}

function OnApplySettings() {
	DesignModeManager.onSettingChanged(Ext.encode(DesignModeManager.changedSettings));
}

function processSchemaEditOnPluginLoaded() {
}

function onSourceCodeItemsComboboxSelect(control, recordParameter, index) {
	var record = Ext.decode(recordParameter);
	var id = record.value;
	DesignModeManager.selectItem(null, id);
}

function onSourceCodeItemsComboboxBeforeQuery(queryEvent) {
	var control = queryEvent.combo;
	var itemList = getControlsListBySchemaDataSource(ClientUnitSchemaDataSource);
	control.store.setDefaultSort('text');
	control.loadData(itemList);
}

function getControlsListBySchemaDataSource(SchemaDataSource) {
	var controlsList = new Array();
	for (var i = 0; i < SchemaDataSource.rows.length; i++) {
		var record = SchemaDataSource.rows.items[i];
		var nodeType = record.getColumnValue("NodeType");
		var typeName = record.getColumnValue("TypeName");
		if ((nodeType != "InnerProperty") && (typeName != "DataSourceStructureColumn")) {
			var control = new Array();
			control.push(record.getColumnValue("UId"));
			control.push(record.getColumnValue("Caption"));
			controlsList.push(control);
		}
	}
	return controlsList;
}

// Sources Validation

function onPropertyChanged(itemId, propertyName, propertyValue) {
	if (propertyName === "Language") {
		CodeSyntaxMemoEdit.scriptableObject.SetLanguage(propertyValue);
		var isNotJavascriptLang = propertyValue.toLowerCase() !== "javascript";
		CodeValidationButton.setHidden(isNotJavascriptLang);
		SourceCodeLogTab.setHidden(isNotJavascriptLang);
		SourceCodeLogGrid.clear();
	}
}

function onEditTabPanelBeforeTabChange(tabPanel, newTab, currentTab) {
	var newTabId = newTab.id;
	var validationEnabled = newTabId == 'SourceTab' || newTabId == 'LessTab' || newTabId == 'SchemaDifferencesTab';
	CodeValidationButton.setEnabled(validationEnabled);
	if (currentTab.id == 'LessTab') {
		MessagePanel.remove('lessParserMessage');
	}
}

function loadScript(text, isReadOnly, line, column) {
	codeText = Ext.util.Format.htmlDecode(text);
	CodeSyntaxMemoEdit.on('onpluginloaded', function () {
		this.scriptableObject.SetLanguage("javascript");
		this.scriptableObject.SetText(codeText);
		this.scriptableObject.IsReadOnly = isReadOnly;
		if (line > 0) {
			this.scriptableObject.SetCaretPosition(line, column);
		}
	}, CodeSyntaxMemoEdit);
}

function loadLess(text, isReadOnly) {
	lessText = Ext.util.Format.htmlDecode(text);
	LessSyntaxMemoEdit.on("onpluginloaded", function () {
		this.scriptableObject.SetLanguage("less");
		this.scriptableObject.SetText(lessText);
		this.scriptableObject.IsReadOnly = isReadOnly;
		validateLess(lessText);
	}, LessSyntaxMemoEdit);
}

function loadSchemaDifferences(text, isReadOnly, line, column) {
	schemaDifferences = Ext.util.Format.htmlDecode(text);
	SchemaDifferencesSyntaxMemoEdit.on('onpluginloaded', function () {
		this.scriptableObject.SetLanguage("javascript");
		this.scriptableObject.SetText(schemaDifferences);
		this.scriptableObject.IsReadOnly = isReadOnly;
		if (line > 0) {
			this.scriptableObject.SetCaretPosition(line, column);
		}
	}, SchemaDifferencesSyntaxMemoEdit);
}

function processCodeCustomEvents(sender, args) {
	switch (args.EventName) {
		case "FocusChanged":
			var row = ClientUnitSchemaDataSource.findRow('ParentId', null);
			codeText = CodeSyntaxMemoEdit.scriptableObject.GetText();
			DesignModeManager.setPropertyValue(row.getPrimaryColumnValue(), 'Body', codeText);
			break;
	}
}

function processLessCustomEvents(sender, args) {
	switch (args.EventName) {
		case "FocusChanged":
			var row = ClientUnitSchemaDataSource.findRow('ParentId', null);
			var id = row.getPrimaryColumnValue();
			lessText = LessSyntaxMemoEdit.scriptableObject.GetText();
			DesignModeManager.setPropertyValue(id, "Less", lessText);
			validateLess(lessText, function(result) {
				DesignModeManager.setPropertyValue(id, "Css", result.css);
			}, this);
			break;
	}
}

function processSchemaDifferencesCustomEvents(sender, args) {
	switch (args.EventName) {
		case "FocusChanged":
			var row = ClientUnitSchemaDataSource.findRow('ParentId', null);
			schemaDifferences = SchemaDifferencesSyntaxMemoEdit.scriptableObject.GetText();
			DesignModeManager.setPropertyValue(row.getPrimaryColumnValue(), 'SchemaDifferences', schemaDifferences);
			break;
	}
}

function showJSHintValidationMessage() {
	var messageList = Ext.StringList('WebApp.ClientUnitSchemaDesigner');
	var title = messageList.getValue('JSHint.ErrorTitle');
	var message = messageList.getValue('JSHint.ErrorMessage');
	MessagePanel.addMessage('jshintMessage', title, message, 'error', true, true);
}

function showJSHintIE8Message() {
	var messageList = Ext.StringList('WebApp.ClientUnitSchemaDesigner');
	var title = messageList.getValue('JSHint.JSHintUnavailableTitle');
	var message = messageList.getValue('JSHint.JSHintUnavailableMessage');
	MessagePanel.addMessage('jshintMessage', title, message, 'warning', true, true);
}

function showLessParserMessage(err) {
	var messageList = Ext.StringList('WebApp.ClientUnitSchemaDesigner');
	var title = messageList.getValue('LessParser.ErrorTitle') + ' ' + Ext.util.Format.htmlEncode(err.message);
	var message = 'Line {0}, Col {1}, Type: {2}{3}';
	var evidence = err.extract != null ? '\r\n<i>Code:</i>\r\n' + err.extract.join('\r\n') : '';
	message = String.format(message, err.line, err.column, err.type, evidence);
	MessagePanel.addMessage('lessParserMessage', title, message, 'error', true, true);
}

function validateLess(lessText, callback, scope) {
	MessagePanel.remove("lessParserMessage");
	if (!window.less) {
		return;
	}
	less.render(lessText, function(error, output) {
		if (error) {
			showLessParserMessage(error);
		} else {
			Ext.callback(callback, scope, [output]);
		}
	});
}

function validateJavaScript(code) {
	if (Ext.isIE8) {
		showJSHintIE8Message();
		return 0;
	}
	function trim(str) {
		return str ? str.trim() : '';
	}
	function addRowToLogGrid(position, code, description, type) {
		var columns = {
			UId: new Ext.ux.GUID().id,
			Position: position,
			Code: code,
			Description: description,
			Type: type
		};
		var row = SourceCodeLogDataSource.createRow(columns);
		SourceCodeLogDataSource.rows.add(columns.UId, row);
		SourceCodeLogDataSource.fireEvent('rowloaded', SourceCodeLogDataSource, [columns]);
	}
	var messageList = Ext.StringList('WebApp.ClientUnitSchemaDesigner');
	var options = Terrasoft.JSHintConfig.options;
	var globals = Terrasoft.JSHintConfig.options.globals;
	SourceCodeLogTab.setHidden(false);
	SourceCodeLogTab.forceFocus();
	SourceCodeLogGrid.clear();
	SourceCodeLogDataSource.rows.clear();
	SourceCodeLogDataSource.selData = [];
	function addNoErrorsMessage() {
		addRowToLogGrid('', '', messageList.getValue('SourceCodeLog.SourceCodeLogGrid.NoErrorsMessage'), '');
	}
	var errorCount = 0;
	if (Ext.isEmpty(code)) {
		addNoErrorsMessage();
		return errorCount;
	}
	JSHINT(code, options, globals);
	var data = JSHINT.data();
	var errors = data ? data.errors : null;
	if (errors) {
		errorCount = errors.length;
		for (var i = 0; i < errorCount; i++) {
			var error = errors[i];
			var evidence = trim(error.evidence);
			addRowToLogGrid(error.line + ',' + error.character, evidence, error.reason, error.id);
		}
	} else {
		addNoErrorsMessage();
	}
	return errorCount;
}

function getCurrentTabId() {
	if(!window.SourcePanel) {
		return "SourceTab";
	}
	if (SourcePanel.activeTab) {
		return SourcePanel.activeTab.id;
	}
	return null;
}

function updateSourceFromCurrentEditor(currentTabId) {
	switch (currentTabId) {
		case "SourceTab":
			codeText = CodeSyntaxMemoEdit.scriptableObject.GetText();
			break;
		case "LessTab":
			lessText = LessSyntaxMemoEdit.scriptableObject.GetText();
			break;
		case "SchemaDifferencesTab":
			schemaDifferences = SchemaDifferencesSyntaxMemoEdit.scriptableObject.GetText();
			break;
	}
}

function onCodeValidationButtonClick() {
	var currentTabId = getCurrentTabId();
	updateSourceFromCurrentEditor(currentTabId);
	switch (currentTabId) {
		case "SourceTab":
			validateJavaScript(codeText);
			break;
		case "LessTab":
			validateLess(lessText);
			break;
		case "SchemaDifferencesTab":
			validateJavaScript(schemaDifferences);
			break;
		default:
			return;
	}
}

function onSourceCodeLogGridDblClick() {
	if (getCurrentTabId() !== "SourceTab") {
		return;
	}
	var selectedIds = SourceCodeLogDataSource.selData;
	if (selectedIds && selectedIds.length > 0) {
		var rowNumber = SourceCodeLogDataSource.rows.get(selectedIds[0]).columns.Position.split(',');
		if (rowNumber.length == 2) {
			var line = parseInt(rowNumber[0], 10);
			var column = parseInt(rowNumber[1], 10);
			if (!isNaN(line) && !isNaN(column)) {
				CodeSyntaxMemoEdit.scriptableObject.SetCaretPosition(line, column);
			}
		}
	}
}

function validateSources() {
	var currentTabId = getCurrentTabId();
	updateSourceFromCurrentEditor(currentTabId);
	var errorCount = validateJavaScript(codeText);
	if (errorCount > 0) {
		showJSHintValidationMessage();
	}
	validateLess(lessText);
}
