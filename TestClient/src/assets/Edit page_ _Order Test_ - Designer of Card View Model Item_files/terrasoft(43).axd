Terrasoft.ControlEntitySchemaColumnDefEdit = Ext.extend(Terrasoft.TextEdit, {
	sources: [
		'None',
		'Const',
		'Settings',
		'SystemValue'],
	displayValuesStringList: null,
	displayLocalizableSources: {},
	windowLocalizableSources: {},
	windowLocalizableSourcesCaptions: {},
	dataMethods: {},
	dataLayouts: {},
	schemaColumnUId: null,
	dataValueTypeId: null,
	value: {
		source: 'None',
		defValue: '',
		valueSource: '',
		defValueConstEditorConfig: null
	},
	defValueConstEditorConfig: null,
	controls: {
		radioButtons: {},
		constValueControl: null,
		sysSettingControl: null,
		sysValueControl: null
	},

	initComponent: function () {
		Terrasoft.ControlEntitySchemaColumnDefEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = {
			id: this.primaryToolButtonId(),
			imageCls: 'lookupedit-ico-btn-lookup'
		};
		this.displayValuesStringList = Ext.StringList('WC.EntitySchemaColumnDef');
		var displayLocalizableSources = this.displayLocalizableSources;
		var windowLocalizableSources = this.windowLocalizableSources;
		var windowLocalizableSourcesCaptions = this.windowLocalizableSourcesCaptions;
		var defValueSources = this.sources;
		for (var i = 0; i < defValueSources.length; i++) {
			var defValueSource = defValueSources[i];
			displayLocalizableSources[defValueSource] = this.displayValuesStringList.getValue('Source.' + defValueSource);
			windowLocalizableSources[defValueSource] = this.displayValuesStringList.getValue('WindowSource.' + defValueSource);
			if(defValueSource != "None") {
				windowLocalizableSourcesCaptions[defValueSource] = this.displayValuesStringList.getValue('WindowSourceCaptions.' + defValueSource + "Caption");
			}
		}
	},

	onPrimaryToolButtonClick: function () {
		if (!this.enabled) {
			return;
		}
		this.initializeParameters();
		Terrasoft.ControlEntitySchemaColumnDefEdit.superclass
			.onPrimaryToolButtonClick.call(this, null, this.el, { t: this.primaryToolButton });
		this.showEditWindow();
	},

	initializeParameters: function () {
		var row = this.dataSource.activeRow;
		this.schemaColumnUId = row.getColumnValue('UId');
		var dataProvider = this.dataProvider;
		var filters = dataProvider.filters;
		for (var i = 0; i < filters.length; i++) {
			var filter = filters[i];
			if (filter[0] == 'dataValueTypeId') {
				this.dataValueTypeId = filter[1];
			}
			var name;
			var value;
			var j;
			if (filter[0] == 'sourceCaptions') {
				var tokens = filter[1].split(';');
				for (j = 0; j < tokens.length; j++) {
					var source = tokens[j].split('=');
					if (source.length == 2) {
						name = source[0];
						value = source[1];
						this.displayLocalizableSources[name] = value;
					}
				}
			}
			if (filter[0] == "getDataMethods") {
				var configs = filter[1].split(";");
				for (j = 0; j < configs.length; j++) {
					var method = configs[j].split("=");
					if (method.length == 2) {
						name = method[0];
						value = method[1];
						this.dataMethods[name] = value;
					}
				}
			}
			if (filter[0] == "valueListSchemaUId") {
				this.valueListSchemaUId = filter[1];
			}
		}
		if (dataProvider) {
			dataProvider.initializeProvider(this);
		}
	},

	addEditWindowButtons: function (mainLayout) {
		var buttonsLayout = new Terrasoft.ControlLayout({
			width: '100%',
			displayStyle: 'footer',
			edges: '1 0 0 0'
		});
		var stringListCommon = Ext.StringList('WC.Common');
		var spacer = new Ext.Spacer({ size: '100%' });
		buttonsLayout.add(spacer);
		var okButton = new Terrasoft.Button({
			id: 'okButton',
			caption: stringListCommon.getValue('Button.Ok'),
			handler: this.onOkButtonClick.createDelegate(this)
		});
		buttonsLayout.add(okButton);
		var cancelButton = new Terrasoft.Button({
			id: 'cancelButton',
			caption: stringListCommon.getValue('Button.Cancel'),
			handler: this.onCancelButtonClick.createDelegate(this)
		});
		buttonsLayout.add(cancelButton);
		mainLayout.add(buttonsLayout);
	},

	onCancelButtonClick: function () {
		Ext.apply(this.value, this.startValue);
		this.editWindow.close();
	},

	getValue: function () {
		return Ext.util.JSON.encode(this.value);
	},

	onOkButtonClick: function () {
		this.submitChanges();
	},

	getSource: function() {
		var radioButtons = this.controls.radioButtons;
		for (var i = 0; i < this.sources.length; i++) {
			var defValueSource = this.sources[i];
			if (radioButtons[defValueSource].checked) {
				return defValueSource;
			}
		}
		return 'None';
	},

	getEditWindowControlValues: function () {
		var value = {};
		Ext.apply(value, this.value);
		if (!this.editWindow) {
			return value;
		}
		value.source = this.getSource();
		var controls = this.controls;
		for (var controlName in controls) {
			var control = controls[controlName];
			if (!controls.hasOwnProperty(controlName) || controlName == 'radioButtons') {
				continue;
			}
			if (value.source == control.defValueSource) {
				var controlValue = control.getValue();
				var valueEmpty = Ext.isEmpty(controlValue);
				value.valueSource = valueEmpty ? null : controlValue;
				if (control.defValueSource == 'Const') {
					if (control.xtype == 'lookupedit') {
						value.displayConstValue = control.getText();
						value.referenceSchemaUID = control.hiddenFieldSourceSchemaUId.value;
					} else if (control.xtype == 'combo') {
						value.displayConstValue = control.getText();
						value.referenceValueListSchemaUId = this.valueListSchemaUId;
					} else if ((control.xtype == 'integeredit' || control.xtype == 'floatedit') && valueEmpty) {
						value.valueSource = 0;
					}
				}
				break;
			}
		}
		return value;
	},

	validateEditWindowControlValues: function (value) {
		if (value && Ext.isEmpty(value.valueSource) && value.source == 'Const') {
			var stringList = Ext.StringList('WC.Common');
			var requiredFieldMessage = stringList.getValue('FormValidator.RequiredFieldMessage');
			var message = String.format(requiredFieldMessage, this.controls.constValueControl.caption);
			Ext.Msg.show({ caption: 'Warning', msg: message, buttons: Ext.MessageBox.OK, icon: Ext.MessageBox.WARNING });
			return false;
		}
		return true;
	},

	submitChanges: function () {
		var value = this.getEditWindowControlValues();
		if (!this.validateEditWindowControlValues(value)) {
			return;
		}
		var encodedValue = Ext.util.JSON.encode(value);
		this.setValue(encodedValue);
		this.editWindow.close();
	},

	showEditWindow: function () {
		var needRecalculateHeight = false;
		if (!this.editWindow) {
			this.editWindow = this.createEditWindow();
			needRecalculateHeight = true;
		} else {
			if (this.value.editorType == 'lookupedit') {
				this.editWindow.destroy();
				this.editWindow = this.createEditWindow();
				needRecalculateHeight = true;
			}
		}
		var editWindow = this.editWindow;
		var windowItems = editWindow.items;
		var mainLayout = windowItems.items[0];
		var buttonsLayout = windowItems.items[1];
		editWindow.show();
		this.updateEditWindowControlValues();
		if (needRecalculateHeight) {
			var height = mainLayout.getHeight() + buttonsLayout.getHeight() + editWindow.header.getHeight();
			editWindow.setHeight(height);
		}
	},

	createEditWindow: function () {
		var window = new Terrasoft.Window({
			name: this.editWindowName,
			caption: this.displayValuesStringList.getValue('WindowSource.Caption'),
			resizable: false,
			width: 400,
			frame: true,
			height: 480,
			modal: true,
			frameStyle: 'padding: 0 0 0 0',
			closeAction: 'hide'
		});

		var mainLayout = new Terrasoft.ControlLayout({
			id: 'mainLayout',
			direction: 'vertical',
			displayStyle: 'controls',
			width: '100%',
			layoutConfig: {
				padding: '5 5 5 5'
			},
			fitHeightByContent: true
		});
		this.addEditWindowControls(mainLayout);
		window.add(mainLayout);
		this.addEditWindowButtons(window);
		return window;
	},

	addEditWindowControls: function(mainLayout) {
		var config = {
			width: '100%',
			allowEmpty: true
		};
		for (var i = 0; i < this.sources.length; i++) {
			config.xtype = 'combo';
			config.value = "";
			config.defValueSource = this.sources[i];
			this.addEditLayout(mainLayout, config);
		}
	},

	addEditLayout: function(mainLayout, config) {
		var defValueSource = config.defValueSource;
		var controls = this.controls;
		var editLayout = new Terrasoft.ControlLayout({
			id: 'editLayout_' + defValueSource,
			direction: 'vertical',
			width: '100%',
			displayStyle: 'controls',
			fitHeightByContent: true
		});
		
		var radioButton = new Terrasoft.Radio({
			id: defValueSource + '_rbtn',
			name: 'source',
			alignedByCaption: false,
			width: '100%',
			defValueSource: defValueSource,
			checked: this.value.source === defValueSource,
			caption:this.windowLocalizableSources[defValueSource]
		});
		radioButton.on('check', this.onRadioChange, this);
		controls.radioButtons[defValueSource] = radioButton;
		editLayout.add(radioButton);
		if (defValueSource != 'None') {
			var dataLayout = new Terrasoft.ControlLayout({
				id: 'dataLayout_' + defValueSource,
				width: '100%',
				fitHeightByContent: true,
				displayStyle: 'controls',
				defValueSource: defValueSource,
				layoutConfig: {
					padding: '0 0 0 17'
				}
			});
			this.dataLayouts[defValueSource] = dataLayout;
			config.caption = this.windowLocalizableSourcesCaptions[defValueSource];
			switch (defValueSource) {
				case 'Const':
					config.id = defValueSource + '_constValue';
					config.enabled = this.value.source === defValueSource;
					Ext.apply(config, this.defValueConstEditorConfig);
					controls.constValueControl = this.createControl(config);
					dataLayout.add(controls.constValueControl);
					controls.constValueControl.on('focus', this.onControlFocus, this, controls.constValueControl);
					break;
				case 'Settings':
					config.id = defValueSource + '_sysSettings';
					config.enabled = this.value.source === defValueSource;
					controls.sysSettingControl = this.createControl(config);
					dataLayout.add(controls.sysSettingControl);
					controls.sysSettingControl.on('focus', this.onControlFocus, this, controls.sysSettingControl);
					break;
				case 'SystemValue':
					config.id = defValueSource + '_sysValue';
					config.enabled = this.value.source === defValueSource;
					controls.sysValueControl = this.createControl(config);
					dataLayout.add(controls.sysValueControl);
					controls.sysValueControl.on('focus', this.onControlFocus, this, controls.sysValueControl);
					break;
			}
			editLayout.add(dataLayout);
		}
		mainLayout.add(editLayout);
	},

	createControl: function (config) {
		var editControl = Ext.ComponentMgr.create(config);
		var dataProvider = this.dataProvider;
		if (config.xtype == 'combo') {
			editControl.dataProvider = new Terrasoft.combobox.WebServiceDataProvider({
				dataService: dataProvider.dataService,
				dataGetMethod: this.dataMethods[config.id] || "",
				filters: dataProvider.filters
			});
			this.prepareFilter(editControl.dataProvider.filters);
		}
		if (config.xtype == 'lookupedit') {
			var referenceSchemaList = this.value.referenceSchemaList;
			var referenceSchemaUId = this.value.referenceSchemaUId;
			var sourceSchemaUIdColumnValueName = this.value.sourceSchemaUIdColumnValueName;
			editControl.lookupGridPageParams = {
				referenceSchemaList: referenceSchemaList,
				sourceSchemaUIdColumnValueName: sourceSchemaUIdColumnValueName,
				sourceSchemaUId: this.value.sourceSchemaUId,
				referenceSchemaUId: referenceSchemaUId
			};
			editControl.on("valueselected", this.editControlValueSelected, this);
		}
		return editControl;
	},

	editControlValueSelected: function(o, keyValue, displayValue) {
		var lookupGridPageParams = o.lookupGridPageParams;
		if (lookupGridPageParams.referenceSchemaList && lookupGridPageParams.referenceSchemaList.length > 0) {
			lookupGridPageParams.sourceSchemaUId = o.hiddenFieldSourceSchemaUId.value;
		}
	},

	prepareFilter: function(filters) {
		var hasColumnUIdFilter = false;
		var hasdataValueTypeIdFilter = false;
		for (var i = 0; i < filters.length; i++) {
			var filter = filters[i];
			if (filter[0] == 'ColumnUId') {
				filter[1] = this.schemaColumnUId;
				hasColumnUIdFilter = true;
			}
			if (filter[0] == 'dataValueTypeId') {
				filter[1] = this.dataValueTypeId;
				hasdataValueTypeIdFilter = true;
			}
		}
		if (!hasColumnUIdFilter) {
			filters.push(['ColumnUId', this.schemaColumnUId]);
		}
		if (!hasdataValueTypeIdFilter) {
			filters.push(['dataValueTypeId', this.dataValueTypeId]);
		}
	},

	onControlFocus: function(e) {
		var radioButtons = this.controls.radioButtons;
		for (var controlName in radioButtons) {
			var radioButton = radioButtons[controlName];
			if (radioButton.defValueSource == e.defValueSource) {
				radioButton.setValue(true);
			} else {
				radioButton.setValue(false);
			}
		}
	},

	onRadioChange: function (obj, checked) {
		if (obj.defValueSource != 'None') {
			var dataLayoutItems = this.dataLayouts[obj.defValueSource].items;
			for (var i = 0; i < dataLayoutItems.length; i++) {
				dataLayoutItems.itemAt(i).setDisabled(!checked);
			}
			
		}
	},

	getDisplayValue: function () {
		return '(' + (this.displayLocalizableSources[this.value.source] || '') + ')';
	},

	onChange: function(o, value, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnBothValues(column.name, value, this.getDisplayValue());
			}
		}
	},

	setValue: function (value, isInitByEvent) {
		if (value == undefined || Ext.isEmpty(value)) {
			return;
		}
		value = value instanceof Object ? value : Ext.util.JSON.decode(value);
		if (this.equals(value)) {
			return;
		}
		this.value = value;
		this.defValueConstEditorConfig = value.defaultEditorConfig || {};
		this.defValueConstEditorConfig.xtype = value.editorType;
		var startValue = Ext.util.JSON.encode(this.startValue);
		var oldValue = this.getEditWindowControlValues();
		this.el.dom.value = this.getDisplayValue();
		if (value.fireEvent == true) {
			value.fireEvent = false;
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnBothValues(column.name, Ext.util.JSON.encode(value), this.getDisplayValue());
			}
			return;
		}
		var encodedOldValue = Ext.util.JSON.encode(oldValue);
		this.fireChangeEvent(encodedOldValue, startValue, isInitByEvent);
	},

	equals: function(value) {
		var startValue = this.startValue;
		if (!startValue) {
			return false;
		}
		var hasHanges = false;
		for (propertyName in startValue) {
			if (startValue.hasOwnProperty(propertyName) && propertyName != 'defaultEditorConfig') {
				var valueProperty = startValue[propertyName] || null;
				var newValueProperty = value[propertyName] || null;
				if (valueProperty != newValueProperty) {
					hasHanges = true;
				}
			}
		}
		return !hasHanges;
	},

	updateEditWindowControlValues: function() {
		var controls = this.controls;
		var value = this.value;
		var defValueSource = value.source;
		for (var controlName in controls) {
			if (controlName == 'radioButtons') {
				continue;
			}
			var control = controls[controlName];
			if (control.defValueSource == defValueSource) {
				if (control.xtype == 'lookupedit') {
					control.setValueAndText(value.valueSource, value.displayConstValue, false);
				}
				control.setValue(value.valueSource);
			} else {
				if (control.clearValue) {
					control.clearValue(false);
				} else {
					control.setValue("");
				}
			}
		}
	},

	onDestroy: function () {
		if (this.editWindow) {
			this.editWindow.destroy();
		}
		Terrasoft.ControlEntitySchemaColumnDefEdit.superclass.onDestroy.call(this);
	}

});

Ext.reg('controlentityschemacolumndefedit', Terrasoft.ControlEntitySchemaColumnDefEdit);

Terrasoft.ControlEntitySchemaColumnDefEdit.DataProvider = function (config) {
	Ext.apply(this, config);
	Terrasoft.ControlEntitySchemaColumnDefEdit.DataProvider.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.ControlEntitySchemaColumnDefEdit.DataProvider, Ext.util.Observable, {
	isProviderInitialized: false,

	initializeProvider: function (ControlEntitySchemaColumnDefEdit) {
		if (this.isProviderInitialized) {
			return;
		}
		this.ControlEntitySchemaColumnDefEdit = ControlEntitySchemaColumnDefEdit;
		this.isProviderInitialized = true;
	}

});

Terrasoft.ControlEntitySchemaColumnDefEdit.WebServiceDataProvider =
Ext.extend(Terrasoft.ControlEntitySchemaColumnDefEdit.DataProvider, {
	dataService: '',
	dataGetMethod: '',

	loadData: function () {
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

	getLoadDataParams: function () {
		var buf = [];
		if (!this.filters) {
			this.filters = [];
		}
		buf.push("filters=", Ext.encode(this.filters));
		return buf.join("");
	},

	handleResponse: function (response) {
		try {
			var xmlData = response.responseXML;
			var root = xmlData.documentElement || xmlData;
			var data = root.textContent || root.text;
			if (data == undefined || Ext.isEmpty(data)) {
				return;
			}
			this.ControlEntitySchemaColumnDefEdit.setValue(data, true);
		} finally {
		}
	},

	handleFailure: function (response) {
	}

});

Ext.reg('controlentityschemacolumndefdataprovider', Terrasoft.ControlEntitySchemaColumnDefEdit.WebServiceDataProvider);

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}
