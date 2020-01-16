Terrasoft.ControlImageEditWindow = function() {
	var controlImageSources = [
		'None',
		'Image',
		'ImageList',
		'ImageListSchema',
		'Url',
		'ResourceManager'
	];
	var defaultAvailableControlImageSources = [
		'None',
		'Image',
		'ImageList',
		'ImageListSchema',
		'Url'
	];
	var controlImageCaptions = {
		file: '',
		list: '',
		image: '',
		url: ''
	};
	var availableControlImageSources = null;

	var sourceEditorsConfig = {
		defaultEditorConfig: {
			width: '100%',
			allowEmpty: true,
			value: '',
			canFocus: false
		},
		none: [],
		image: {
			dafaultConfig: {
				controlImageSource: 'Image'
			},
			count: 1,
			configs: [
				{
					index: 0,
					id: 'Image_image',
					xtype: 'fileuploadedit',
					submitFileOnChange: false,
					focusOnClick: true,
					valuePropertyName: 'image'
				}
			]
		},
		imagelist: {
			dafaultConfig: {
				xtype: 'combo',
				controlImageSource: 'ImageList'
			},
			count: 2,
			configs: [
				{
					index: 1,
					id: 'ImageList_ImageUId',
					valuePropertyName: 'imageUId',
					requiredOnSelection: true
				},
				{
					index: 0,
					id: 'ImageList_ImageListUId',
					valuePropertyName: 'imageListUId',
					requiredOnSelection: true
				}
			]
		},
		imagelistschema: {
			dafaultConfig: {
				xtype: 'combo',
				controlImageSource: 'ImageListSchema'
			},
			count: 2,
			configs: [
				{
					index: 1,
					id: 'ImageListSchema_ItemUId',
					valuePropertyName: 'itemUId',
					requiredOnSelection: true
				},
				{
					index: 0,
					id: 'ImageListSchema_SchemaUId',
					valuePropertyName: 'schemaUId',
					requiredOnSelection: true
				}
			]
		},
		url: {
			dafaultConfig: {
				controlImageSource: 'Url'
			},
			count: 1,
			configs: [
				{
					index: 0,
					id: 'Url_Url',
					xtype: 'textedit',
					valuePropertyName: 'url'
				}
			]
		},
		resourcemanager: {
			dafaultConfig: {
				xtype: 'textedit',
				controlImageSource: 'ResourceManager'
			},
			count: 1,
			configs: [
				{
					index: 0,
					id: 'ResourceManager_ResMngr',
					valuePropertyName: 'resourceManagerName'
				},
				{
					index: 1,
					id: 'ResourceManager_ResItem',
					valuePropertyName: 'resourceItemName'
				}
			]
		}
	};

	var displaylocalizableSources = {};
	var imageNotLoadedCaption = '';
	var imageLoadedCaption = '';
	var windowlocalizableSources = {};
	var fileUploadControlId = null;

	//var parametersInitialized = false;

	//dataProvider = null;
	var filters = null;
	var dataService = null;
	var getDataMethods = {};
	var dataLayouts = { };


	var controlImageValue = {
		source: 'None',
		curSchemaUId: '',
		schemaUId: '',
		itemUId: '',
		imageListUId: '',
		imageUId: '',
		resourceManagerName: '',
		resourceItemName: '',
		url: '',
		resourceName: '',
		entityPrimaryColumnValue: '',
		entitySchemaColumnUId: '',
		usePrimaryImageColumn: true
	};
	var editWindow = null;
	var localizableStringsInitialized = false;
	var editWindowHandlers= {
		okButtonClick: null,
		cancelButtonClick: null
	};
	var controls = {
		radioButtons: {},
		imageControl: null,
		schemaControl: null,
		schemaItemControl: null,
		imageListControl: null,
		imageListItemControl: null,
		urlControl: null,
		resourceManagerNameControl: null,
		resourceItemNameControl: null
	};

	var createEditWindow = function () {
		var window = new Terrasoft.Window({
			renderTo: document.forms[0].id,
			caption: controlImageStringList.getValue('WindowSource.Caption'),
			resizable: false,
			width: 450,
			frame: true,
			height: 480,
			modal: true,
			frameStyle: 'padding: 0 0 0 0',
			closeAction: 'hide'
		});
		var mainLayout = new Terrasoft.ControlLayout({
			id: 'mainLayout',
			direction: 'vertical',
			width: '100%',
			layoutConfig: {
				padding: '5 5 5 5'
			},
			fitHeightByContent: true
		});
		addEditWindowControls(mainLayout);
		window.add(mainLayout);
		addEditWindowButtons(window);
		return window;
	};

	var addEditWindowButtons = function (mainLayout) {
		var buttonsLayout = new Terrasoft.ControlLayout({
			width: '100%',
			displayStyle: 'footer'
		});
		var stringListCommon = Ext.StringList('WC.Common');
		var spacer = new Ext.Spacer({ size: '100%' });
		buttonsLayout.add(spacer);
		var okButton = new Terrasoft.Button({
			id: 'okButton',
			caption: stringListCommon.getValue('Button.Ok'),
			handler: okButtonClick.createDelegate(this)
		});
		buttonsLayout.add(okButton);
		var cancelButton = new Terrasoft.Button({
			id: 'cancelButton',
			caption: stringListCommon.getValue('Button.Cancel'),
			handler: cancelButtonClick.createDelegate(this)
		});
		buttonsLayout.add(cancelButton);
		mainLayout.add(buttonsLayout);
	};

	var validateWindowValue = function(value) {
		switch (value.source) {
			case "ImageListSchema":
				return (!Ext.isEmpty(value.itemUId) && !Ext.isEmpty(value.schemaUId));
			case "ImageList":
				return !Ext.isEmpty(value.itemUId);
			default:
				return true;
		}
	};

	var getEditWindowControlValues = function () {
		var value = {};
		Ext.apply(value, controlImageValue);
		if (!editWindow) {
			return value;
		}
		value.source = getSource();
		//var controls = this.controls;
		for (var controlName in controls) {
			var control = controls[controlName];
			if (control == null) {
				continue;
			}
			if (!controls.hasOwnProperty(controlName) ||
				controlName == 'radioButtons' ||
				control.controlImageSource != value.source) {
					continue;
			}
			value[control.valuePropertyName] = control.getValue();
			if (control.xtype == 'lookupedit') {
				value.displayValue = control.getText();
			}
		}
		return value;
	};

	var copyConfig = function(config, extendedConfig) {
		var newConfig = {};
		Ext.apply(newConfig, config);
		for (var property in extendedConfig) {
			newConfig[property] = extendedConfig[property];
		}
		return newConfig;
	};

	var getEditorConfig = function(source, valuePropertyName) {
		var config = {};
		config = copyConfig(config, sourceEditorsConfig.defaultEditorConfig);
		var sourceName = source.toLowerCase();
		config = copyConfig(config, sourceEditorsConfig[sourceName].dafaultConfig);
		var configs = sourceEditorsConfig[sourceName].configs;
		for (var i = 0; i < configs.length; i++) {
			var editorConfig = configs[i];
			if (configs[i].valuePropertyName == valuePropertyName) {
				return copyConfig(config, editorConfig);
			}
		}
		return null;
	};

	var addEditWindowControls = function (mainLayout) {
		for (var i = 0; i < availableControlImageSources.length; i++) {
			addEditLayout(mainLayout, availableControlImageSources[i]);
		}
		mainLayout.calculateControlsCaptionWidth();
	};

	var createControl = function (config) {
		var editControl = Ext.ComponentMgr.create(config);
		if (config.xtype == 'combo') {
			editControl.dataProvider = new Terrasoft.combobox.WebServiceDataProvider({
				dataService: dataService,
				dataGetMethod: getDataMethods[config.id] || "",
				filters: filters
			});
		}
		return editControl;
	};

	var addEditLayout = function (mainLayout, controlImageSource) {
		var editLayout = new Terrasoft.ControlLayout({
			id: 'editLayout_' + controlImageSource,
			direction: 'vertical',
			width: '100%',
			displayStyle: 'controls',
			fitHeightByContent: true
		});
		var radio = new Terrasoft.Radio({
			id: controlImageSource + '_rbtn',
			name: 'source',
			alignedByCaption: false,
			canFocus: true,
			width: '100%',
			caption: windowlocalizableSources[controlImageSource],
			controlImageSource: controlImageSource,
			checked: controlImageValue.source === controlImageSource
		});
		radio.on('check', onRadioChange, this);
		controls.radioButtons[controlImageSource] = radio;
		editLayout.add(radio);
		if(controlImageSource != "None") {
			var dataLayout = new Terrasoft.ControlLayout({
				id: 'dataLayout_' + controlImageSource,
				width: '100%',
				enabled: true,
				fitHeightByContent: true,
				displayStyle: 'controls',
				direction: 'vertical',
				layoutConfig: {
					padding: "0 0 0 17"
				}
			});
			dataLayouts[controlImageSource] = dataLayout;
			var editorConfig;
			switch (controlImageSource) {
				case 'Image':
					editorConfig = getEditorConfig(controlImageSource, 'image');
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					if (fileUploadControlId != null) {
						editorConfig.id = fileUploadControlId;
					}
					editorConfig.caption = controlImageCaptions.file;
					controls.imageControl = createControl(editorConfig);
					controls.imageControl.on("fileselected", onFileSelected, this);
					var displayText = '(' + (controlImageValue.source == 'Image' ? imageLoadedCaption : imageNotLoadedCaption) + ')';
					controls.imageControl.setDisplayText(displayText);
					dataLayout.add(controls.imageControl);
					controls.imageControl.on('focus', onControlFocus, this, controls.imageControl);
					break;
				case 'ImageListSchema':
					editorConfig = getEditorConfig(controlImageSource, 'schemaUId');
					editorConfig.caption = controlImageCaptions.list;
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.schemaControl = createControl(editorConfig);
					controls.schemaControl.on('change', onImageListSchemaChange, this);
					dataLayout.add(controls.schemaControl);
					controls.schemaControl.on('focus', onControlFocus, this, controls.schemaControl);

					editorConfig = getEditorConfig(controlImageSource, 'itemUId');
					editorConfig.caption = controlImageCaptions.image;
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.schemaItemControl = createControl(editorConfig);
					dataLayout.add(controls.schemaItemControl);
					controls.schemaItemControl.on('focus', onControlFocus, this, controls.schemaItemControl);
					break;
				case 'ImageList':
					editorConfig = getEditorConfig(controlImageSource, 'imageListUId');
					editorConfig.caption = controlImageCaptions.list;
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.imageListControl = createControl(editorConfig);
					controls.imageListControl.on('change', onImageListChange, this);
					dataLayout.add(controls.imageListControl);
					controls.imageListControl.on('focus', onControlFocus, this, controls.imageListControl);

					editorConfig = getEditorConfig(controlImageSource, 'imageUId');
					editorConfig.caption = controlImageCaptions.image;
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.imageListItemControl = createControl(editorConfig);
					dataLayout.add(controls.imageListItemControl);
					controls.imageListItemControl.on('focus', onControlFocus, this, controls.imageListItemControl);
					break;
				case 'Url':
					editorConfig = getEditorConfig(controlImageSource, 'url');
					editorConfig.caption = controlImageCaptions.url;
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.urlControl = createControl(editorConfig);
					dataLayout.add(controls.urlControl);
					controls.urlControl.on('focus', onControlFocus, this, controls.urlControl);
					break;
				case 'ResourceManager':
					editorConfig = getEditorConfig(controlImageSource, 'resourceManagerName');
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.resourceManagerNameControl = createControl(editorConfig);
					dataLayout.add(controls.resourceManagerNameControl);

					editorConfig = getEditorConfig(controlImageSource, 'resourceItemName');
					editorConfig.enabled = controlImageValue.source === controlImageSource;
					controls.resourceItemNameControl = createControl(editorConfig);
					dataLayout.add(controls.resourceItemNameControl);
					break;
			}
			editLayout.add(dataLayout);
		}
		mainLayout.add(editLayout);
	};

	var onImageListChange = function(obj, newValue, oldValue) {
		prepareFilter(controls.imageListItemControl, "imageListUId", newValue);
	};

	var onImageListSchemaChange = function(obj, newValue, oldValue) {
		prepareFilter(controls.schemaItemControl, "SchemaUId", newValue);
	};

	//TODO проверить область видимости 
	var fileSelected; 
	var onFileSelected = function(fileUploadEdit, e) {
		fileSelected = true;
	};

	var prepareFilter = function(control, key, value) {
		if (control.dataProvider) {
			control.listPrepared = false;
			var hasFilter = false;
			var filters = control.dataProvider.filters;
			for (var i = 0; i < filters.length; i++) {
				var filter = filters[i];
				if (filter[0] == key) {
					filter[1] = value;
					hasFilter = true;
				}
			}
			if (!hasFilter) {
				filters.push([key, value]);
			}
		}
	};

	var onControlFocus = function(e) {
		var radioButtons = controls.radioButtons;
		for (var controlName in radioButtons) {
			var radioButton = radioButtons[controlName];
			if (radioButton.controlImageSource == e.controlImageSource) {
				radioButton.setValue(true);
			} else {
				radioButton.setValue(false);
			}
		}
	};

	var onRadioChange = function (obj, checked) {
		if (typeof dataLayouts[obj.controlImageSource] === "undefined") {
			return;
		}
		var dataLayoutItems = dataLayouts[obj.controlImageSource].items;
		for (var i = 0; i < dataLayoutItems.length; i++) {
			var control = dataLayoutItems.itemAt(i);
			control.setDisabled(!checked);
			if (control.requiredOnSelection) {
				control.setRequired(checked);
			}
		}
	};

	var getSource = function() {
		var radioButtons = controls.radioButtons;
		for (var i = 0; i < controlImageSources.length; i++) {
			var source = controlImageSources[i];
			if (radioButtons[source] && radioButtons[source].checked) {
				return source;
			}
		}
		return 'None';
	};

	var updateEditWindowControlValues = function() {
		var source = controlImageValue.source;
		for (var controlName in controls) {
			var control = controls[controlName];
			if (control == null || !control.hasOwnProperty('valuePropertyName')) {
				continue;
			}
			if (control.controlImageSource == 'Image') {
				continue;
			}
			if (control.controlImageSource == source) {
				if (control.requiredOnSelection) {
					control.setRequired(control.requiredOnSelection);
				}
				control.setValue(controlImageValue[control.valuePropertyName]);
				control.focus();
			} else {
				if (control.clearValue) {
					control.clearValue(false);
				} else {
					control.setValue("");
				}
			}
		}
		var radioButtons = controls.radioButtons;
		for (controlName in radioButtons) {
			var radioButton = radioButtons[controlName];
			if (radioButton.controlImageSource == source) {
				radioButton.setValue(true);
			} else {
				radioButton.setValue(false);
			}
		}
	};

	function okButtonClick(el, event) {
		var value = getEditWindowControlValues();
		if (!validateWindowValue(value)) {
			return;
		}
		if (value.source == "Image") {
			var imageControl = controls.imageControl;
			if (imageControl.checkLoadedFile) {
				value.imageHash = null;
				imageControl.on("beforeupload", function() {
					editWindowHandlers.okButtonClick(value);
				}, this);
				imageControl.submitFile(true);
				return;
			}
		}
		editWindowHandlers.okButtonClick(value);
	};

	function cancelButtonClick(el, event) {
		editWindowHandlers.cancelButtonClick();
	};

	return {

		closeWindow: function() {
			editWindow.close();
			editWindow.destroy();
			controls.imageControl.destroy();
			editWindow = null;
			getDataMethods = {};
			dataService = '';
			availableControlImageSources = null;
			fileUploadControlId = null;
		},

//		config: {
//			value: {}
//			availableControlImageSources: []
//			getDataMethods: {}
//			filters: []
//			dataService: ''
//			okButtonClickHandler: func
//			cancelButtonClickHandler: func
//			fileUploadControlId: ''
//		}
		showEditWindow: function(config) {
			if (!localizableStringsInitialized) {
				controlImageStringList = Ext.StringList('WC.ControlImage');
				var i;
				for (i = 0; i < controlImageSources.length; i++) {
					var source = controlImageSources[i];
					displaylocalizableSources[source] = controlImageStringList.getValue('Source.' + source);
					windowlocalizableSources[source] = controlImageStringList.getValue('WindowSource.' + source);
				}
				for (i in controlImageCaptions) {
					controlImageCaptions[i] = controlImageStringList.getValue('Captions.' + i);
				}
				imageNotLoadedCaption = controlImageStringList.getValue('Iamge.ImageNotLoaded');
				imageLoadedCaption = controlImageStringList.getValue('Iamge.ImageLoaded');
				localizableStringsInitialized = true;
			}
			var needRecalculateHeight = false;
			filters = config.filters;
			dataService = config.dataService;
			Ext.apply(getDataMethods, config.getDataMethods);
			Ext.apply(controlImageValue, config.value);
			if (config.availableControlImageSources) {
				//editWindow && editWindow.destroy();
				availableControlImageSources = config.availableControlImageSources;
			}
			if (!availableControlImageSources || availableControlImageSources.length == 0) {
				availableControlImageSources = defaultAvailableControlImageSources;
			}
			if (config.fileUploadControlId) {
				fileUploadControlId = config.fileUploadControlId;
			}
			editWindowHandlers.okButtonClick = config.okButtonClickHandler;
			editWindowHandlers.cancelButtonClick = config.cancelButtonClickHandler;
			if (!editWindow) {
				editWindow = createEditWindow();
				needRecalculateHeight = true;
			}
			var windowItems = editWindow.items.items;
			var mainLayout = windowItems[0];
			var buttonsLayout = windowItems[1];
			editWindow.show();
			updateEditWindowControlValues();
			if (needRecalculateHeight) {
				var height = mainLayout.getHeight() + buttonsLayout.getHeight() + editWindow.header.getHeight();
				editWindow.setHeight(height);
			}
		}

	};
}();


Terrasoft.ControlImageEdit = Ext.extend(Terrasoft.TextEdit, {
	controlImageSources: [
		'None',
		'Image',
		'ImageList',
		'ImageListSchema',
		'Url'
	],
	displaylocalizableSources: {},
	dataMethods: {},
	controlImageStringList: null,
	value: {
		source: 'None',
		curSchemaUId: '',
		schemaUId: '',
		itemUId: '',
		imageListUId: '',
		imageUId: '',
		resourceManagerName: '',
		resourceItemName: '',
		url: '',
		resourceName: '',
		entityPrimaryColumnValue: '',
		entitySchemaColumnUId: '',
		usePrimaryImageColumn: true
	},

	initComponent: function () {
		Terrasoft.ControlImageEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = {
			id: this.primaryToolButtonId(),
			imageCls: 'lookupedit-ico-btn-lookup'
		};
		var controlImageStringList = this.controlImageStringList = Ext.StringList('WC.ControlImage');
		var displaylocalizableSources = this.displaylocalizableSources;
		var controlImageSources = this.controlImageSources;
		for (var i = 0; i < controlImageSources.length; i++) {
			var source = controlImageSources[i];
			displaylocalizableSources[source] = controlImageStringList.getValue('Source.' + source);
		}
	},

	onPrimaryToolButtonClick: function () {
		if (!this.enabled) {
			return;
		}
		this.initaializeParameters();
		Terrasoft.ControlImageEdit.superclass.onPrimaryToolButtonClick.call(this, null, this.el, { t: this.primaryToolButton });
		var controlImageEdit = this;
		var dataProvider = this.dataProvider;
		this.removeBlurListeners();
		Terrasoft.ControlImageEditWindow.showEditWindow({
			value: this.value,
			filters: dataProvider.filters,
			dataService: dataProvider.dataService,
			getDataMethods: this.dataMethods,
			okButtonClickHandler: function(value) {
				controlImageEdit.setValue(value);
				Terrasoft.ControlImageEditWindow.closeWindow();
				controlImageEdit.addBlurListeners();
			},
			cancelButtonClickHandler: function() {
				Terrasoft.ControlImageEditWindow.closeWindow();
				controlImageEdit.addBlurListeners();
			}
		});
	},

	addBlurListeners: function() {
		this.on('focus', this.onFocus, this);
		this.on('blur', this.onBlur, this);
		if (this.mimicing) {
			Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, { delay: 10 });
			if (this.monitorTab) {
				this.el.on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.checkTab, this);
			}
		}
	},

	removeBlurListeners: function() {
		this.un('focus', this.onFocus, this);
		this.un('blur', this.onBlur, this);
		if (this.mimicing) {
			Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.mimicBlur, this);
			if (this.monitorTab) {
				this.el.un(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.checkTab, this);
			}
		}
	},

	initaializeParameters: function () {
		var dataProvider = this.dataProvider;
		var filters = dataProvider.filters;
		for (var i = 0; i < filters.length; i++) {
			var filter = filters[i];
			if (filter[0] == "CurSchemaUId") {
				this.value.curSchemaUId = filter[1];
				continue;
			}
			if (filter[0] == "getDataMethods") {
				var configs = filter[1].split(";");
				for (var j = 0; j < configs.length; j++) {
					var method = configs[j].split("=");
					if (method.length == 2) {
						var name = method[0];
						var value = method[1];
						this.dataMethods[name] = value;
					}
				}
			}
		}
		if (dataProvider) {
			dataProvider.initializeProvider(this);
		}
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
			this.fileSelected = false;
		}
	},

	getDisplayValue: function () {
		return '(' + (this.displaylocalizableSources[this.value.source] || '') + ')';
	},

	setValue: function (value, isInitByEvent) {
		if (value == undefined || Ext.isEmpty(value)) {
			return;
		}
		value = value instanceof Object ? value : Ext.util.JSON.decode(value);
		if (this.equals(value) && !this.fileSelected) {
			return;
		}
		if (value.source != "ImageListSchema") {
			value.schemaUId = value.curSchemaUId;
		}
		this.value = value;
		var startValue = Ext.util.JSON.encode(this.startValue);
		var oldValue = Ext.util.JSON.encode(this.value); //this.getEditWindowControlValues();
		this.el.dom.value = this.getDisplayValue();
		this.fireChangeEvent(oldValue, startValue, isInitByEvent);
	},

	equals: function(value) {
		var startValue = Ext.util.JSON.decode(this.startValue);
		if (!startValue) {
			return false;
		}
		var hasHanges = false;
		var valueProperty;
		var newValueProperty;
		for (propertyName in startValue) {
			if (startValue.hasOwnProperty(propertyName)) {
				valueProperty = startValue[propertyName] || null;
				newValueProperty = value[propertyName] || null;
				if (valueProperty != newValueProperty) {
					hasHanges = true;
				}
			}
		}
		for (propertyName in value) {
			if (value.hasOwnProperty(propertyName)) {
				valueProperty = value[propertyName] || null;
				newValueProperty = startValue[propertyName] || null;
				if (valueProperty != newValueProperty) {
					hasHanges = true;
				}
			}
		}
		return !hasHanges;
	},

	getValue: function () {
		return Ext.util.JSON.encode(this.value);
	},

	/*
	onFileSelected: function(fileUploadEdit, e) {
		this.fileSelected = true;
	},
	*/

	onDestroy: function () {
		Terrasoft.ControlImageEdit.superclass.onDestroy.call(this);
	}
});

Ext.reg('controlimageedit', Terrasoft.ControlImageEdit);

Terrasoft.ControlImageEdit.DataProvider = function(config) {
	Ext.apply(this, config);
	Terrasoft.ControlImageEdit.DataProvider.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.ControlImageEdit.DataProvider, Ext.util.Observable, {
	isProviderInitialized: false,

	initializeProvider: function(ControlImageEdit) {
		if (this.isProviderInitialized) {
			return;
		}
		this.ControlImageEdit = ControlImageEdit;
		this.isProviderInitialized = true;
	}

});

Terrasoft.ControlImageEdit.WebServiceDataProvider = Ext.extend(Terrasoft.ControlImageEdit.DataProvider, {
	dataService: '',
	dataGetMethod: '',

	loadData: function() {
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
		if (!this.filters) {
			this.filters = [];
		}
		this.ControlImageEdit.fireEvent('preparefilters', this);
		buf.push("filters=", Ext.encode(this.filters));
		return buf.join("");
	},

	handleResponse: function(response) {
		try {
			var xmlData = response.responseXML;
			var root = xmlData.documentElement || xmlData;
			var data = root.textContent || root.text;
			if (data == undefined || Ext.isEmpty(data)) {
				return;
			}
			this.ControlImageEdit.setValue(data);
		} finally {
		}
	},

	handleFailure: function(response) {
	}
});

Ext.reg('controlimagedataprovider', Terrasoft.ControlImageEdit.WebServiceDataProvider);

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}
