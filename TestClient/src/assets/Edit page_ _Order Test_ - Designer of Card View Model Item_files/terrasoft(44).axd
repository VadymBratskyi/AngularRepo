// jscs:disable
/* jshint ignore:start */
/*ignore jslint start*/
Terrasoft.ProcessSchemaParameterValueEdit = Ext.extend(Terrasoft.TextEdit, {
    valueSources: [
		'None',
		'ConstValue',
		'Mapping',
		'Script',
		'SystemValue',
		'SystemSetting'
    ],
    defaultAvailableValueSources: [
		'None',
		'ConstValue',
		'Mapping',
		'SystemValue',
		'SystemSetting'
    ],
    invalidSources: [],
    hiddenField: null,
    showLookupEditToolButton: false,
    displayLocalizableSources: {},
    windowlocalizableSources: {},
    windowLocalizableSourcesCaptions: {},
    dataMethods: {},
    processSchemaParameterValueStringList: null,
    showMappingWindowAjaxMethodName: null,
    parameterTypeId: null,
    samplingSchemaUId: null,
    value: {
        source: 'None',
        value: ''
    },

    initComponent: function () {
        if (!this.toolsConfig) {
            this.toolsConfig = [];
        }
        var fxToolButtonConfig = {
            id: this.id ? this.id + '_FxToolButton' : Ext.id(),
            imageCls: 'processschemaparametervalueedit-ico-btn-formula'
        };
        var lookupEditToolButtonConfig = {
            id: this.id ? this.id + '_LookupEditToolButton' : Ext.id(),
            hidden: this.showLookupEditToolButton === false,
            imageCls: 'lookupedit-ico-btn-lookup'
        };
        this.toolsConfig.push(fxToolButtonConfig);
        this.toolsConfig.push(lookupEditToolButtonConfig);
        var processSchemaParameterValueStringList = this.processSchemaParameterValueStringList =
            Ext.StringList('WC.ProcessSchemaParameterValue');
        var displayLocalizableSources = this.displayLocalizableSources;
        var windowlocalizableSources = this.windowlocalizableSources;
        var windowLocalizableSourcesCaptions = this.windowLocalizableSourcesCaptions;
        var valueSources = this.valueSources;
        for (var i = 0; i < valueSources.length; i++) {
            var source = valueSources[i];
            displayLocalizableSources[source] = processSchemaParameterValueStringList.getValue('Source.' + source);
            windowlocalizableSources[source] = processSchemaParameterValueStringList.getValue('WindowSource.' + source);
            if (source != "None") {
                windowLocalizableSourcesCaptions[source] = processSchemaParameterValueStringList.getValue('WindowSourceCaptions.' + source + "Caption");
            }
        }
        Terrasoft.ProcessSchemaParameterValueEdit.superclass.initComponent.call(this);
		var provider = this.dataProvider;
		if (provider && typeof (provider) != "string") {
			this.dataProvider = Ext.ComponentMgr.create(provider);
		}
    },

    initEvents: function () {
        Terrasoft.ProcessSchemaParameterValueEdit.superclass.initEvents.call(this);
        this.addEvents('showmappingwindow');
    },

    onRender: function (ct, position) {
        Terrasoft.ProcessSchemaParameterValueEdit.superclass.onRender.call(this, ct, position);
        var showFxPageHandler = this.onFxToolButtonClick.createDelegate(this, [false]);
        var showLookupGridPageHandler = this.showLookupGridPage.createDelegate(this, [false]);
        this.tools[0].on('click', showFxPageHandler, this);
        this.tools[1].on('click', showLookupGridPageHandler, this);
        this.hiddenField = this.el.insertSibling({
            tag: 'input',
            type: 'hidden',
            name: this.id + '_Value',
            id: this.id + '_Value'
        }, 'before', true);
    },

    onFxToolButtonClick: function () {
        if (!this.enabled) {
            return;
        }
        this.initaializeParameters();
        var key = this.id;
        var callBackFunctionText = 'Ext.getCmp("' + this.id + '").onPutValueToSession()';
        this.fireEvent('showmappingwindow', key, callBackFunctionText);
        if (this.showMappingWindowAjaxMethodName) {
            var method = Terrasoft.AjaxMethods[this.showMappingWindowAjaxMethodName];
            var dataSource = this.dataSource;
            if (!dataSource) {
                return;
            }
            var row = dataSource.activeRow;
            var itemUId = row.getColumnValue('UId');
            method(itemUId, key, callBackFunctionText);
        }
    },

    onPutValueToSession: function () {
        this.schemaUId = this.schemaUId || this.value.schemaUId;
        this.schemaManagerName = this.schemaManagerName || this.value.schemaManagerName;
        this.showEditPage();
    },

    showEditPage: function () {
        var controlValue = this.value;
        var schemaUId = this.schemaUId;
        var schemaManagerName = this.schemaManagerName;
        var key = this.id;
        var editItemUId = null;
        var samplingSchemaUId = this.samplingSchemaUId;
        if (this.dataSource) {
            editItemUId = this.dataSource.activeRow.getColumnValue('UId');
        }
        Terrasoft.ProcessSchemaParameterValueEditPage.show(key, this, this.onFxEditComplete, schemaUId, schemaManagerName,
            this.parameterTypeId, controlValue.source, controlValue.value, controlValue.displayValue, null, key,
                controlValue.metaDataValue);
    },

    showLookupGridPage: function () {
        var controlValue = this.value;
        var key = this.id;
        Terrasoft.LookupGridPage.show(key, this, this.onLookupEditComplete, controlValue.referenceSchemaUId, null, null,
        controlValue.displayValue, key + '_LookupFilters', null, null);
    },

    onFxEditComplete: function (newValue) {
        this.setValue(newValue);
    },

	onLookupEditComplete: function (newValues) {
		var lookupValue = newValues[0];
		if (lookupValue) {
			this.setValue({
				source: "Script",
				value: '[#Lookup.' + lookupValue.dataValue.schemaUId + '.' + lookupValue.keyValue + '#]',
				displayValue: lookupValue.dataValue[lookupValue.primaryDisplayColumnName],
				metaDataValue: this.value.metaDataValue,
				dataValueTypeUId: this.value.dataValueTypeUId,
				referenceSchemaUId: this.value.referenceSchemaUId,
				schemaManagerName: this.value.schemaManagerName,
				schemaUId: this.value.schemaUId
			});
		}
	},

    initaializeParameters: function () {
        if (this.dataProvider == null) {
            return;
        }
        var dataProvider = this.dataProvider;
        var filters = dataProvider.filters;
        for (var i = 0; i < filters.length; i++) {
            var filter = filters[i];
            if (filter[0] == 'dataValueTypeId') {
                this.parameterTypeId = filter[1];
            }
            if (filter[0] == 'schemaUId') {
                this.schemaUId = filter[1];
            }
            if (filter[0] == 'schemaManagerName') {
                this.schemaManagerName = filter[1];
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
        }
        if (dataProvider) {
            dataProvider.initializeProvider(this);
        }
    },

    onChange: function (o, value, oldColumnValue, opt) {
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

    getDisplayValue: function () {
        if (this.value.source == 'Script' || this.value.source == 'SamplingEntityMapping') {
            return this.value.displayValue;
        }
        return '(' + (this.displayLocalizableSources[this.value.source] || '') + ')';
    },

    setValue: function (value, isInitByEvent) {
        if (value == undefined || Ext.isEmpty(value)) {
            return;
        }
        value = value instanceof Object ? value : Ext.util.JSON.decode(value);
        if (this.equals(value)) {
            return;
        }
        value.value = Ext.util.Format.htmlDecode(value.value);
        value.displayValue = Ext.util.Format.htmlDecode(value.displayValue);
        this.value = {
            source: value.source,
            value: value.value,
            displayValue: value.displayValue,
            metaDataValue: value.metaDataValue,
            schemaUId: value.schemaUId,
            referenceSchemaUId: value.referenceSchemaUId,
            schemaManagerName: value.schemaManagerName,
            dataValueTypeUId: value.dataValueTypeUId
        };
        var startValue = Ext.util.JSON.encode(this.startValue);
        this.actualizeDisplayValue();
        var encodedValue = Ext.util.JSON.encode(value);
        if (this.rendered) {
            this.hiddenField.value = encodedValue;
        }
        if (value.fireEvent == true) {
            value.fireEvent = false;
            var column = this.getColumn();
            if (column) {
                this.dataSource.setColumnBothValues(column.name, Ext.util.JSON.encode(value), this.getDisplayValue());
            }
            return;
        }
        this.fireChangeEvent(encodedValue, startValue, isInitByEvent);
        this.validate(true);
    },

	validate: function(preventMark) {
		var restore = this.preventMark;
		this.preventMark = preventMark === true;
		var v = this.validateValue(this.value);
		if (v) {
			this.clearInvalid();
		}
		this.preventMark = restore;
		return v;
	},

	validateValue: function(value) {
		var source = value.source;
		var invalidSources = this.invalidSources;
		for (var i = 0, length = invalidSources.length; i < length; i++) {
			if (invalidSources[i] == source) {
				this.markInvalid();
				return false;
			}
		}
		return true;
	},

	setRequired: function(required) {
		this.setInvalidSource("None", required);
		Terrasoft.ProcessSchemaParameterValueEdit.superclass.setRequired.call(this, required);
	},

	setInvalidSource: function(invalidSource, required) {
		var invalidSources = this.invalidSources;
		var newInvalidSources = [];
		for (var i = 0, length = invalidSources.length; i < length; i++) {
			var source = invalidSources[i];
			if(source != invalidSource) {
				newInvalidSources.push(source);
			}
		}
		if (required) {
			newInvalidSources.push(invalidSource);
		}
		this.invalidSources = newInvalidSources;
	},

    actualizeDisplayValue: function () {
        if (!this.rendered) {
            return;
        }
        this.el.dom.value = this.getDisplayValue();
    },

    equals: function (value) {
        var startValue = this.startValue;
        if (Ext.isEmpty(startValue)) {
            return false;
        }
        startValue = startValue instanceof Object ? startValue : Ext.util.JSON.decode(startValue);
        var hasHanges = false;
        var values = [startValue, value];
        for (var i = 0; i < values.length; i++) {
            for (propertyName in values[i]) {
                if (value.hasOwnProperty(propertyName)) {
                    valueProperty = value[propertyName] || null;
                    newValueProperty = startValue[propertyName] || null;
                    if (valueProperty != newValueProperty) {
                        hasHanges = true;
                    }
                }
            }
        }
        return !hasHanges;
    },

    getValue: function () {
        var hiddenField = this.hiddenField;
        return hiddenField ? hiddenField.value : Ext.util.JSON.encode(this.value);
    }

});

Ext.reg('processschemaparametervalueedit', Terrasoft.ProcessSchemaParameterValueEdit);

Terrasoft.ProcessSchemaParameterValueEdit.DataProvider = function (config) {
    Ext.apply(this, config);
    Terrasoft.ProcessSchemaParameterValueEdit.DataProvider.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.ProcessSchemaParameterValueEdit.DataProvider, Ext.util.Observable, {
    isProviderInitialized: false,

    initializeProvider: function (ProcessSchemaParameterValueEdit) {
        if (this.isProviderInitialized) {
            return;
        }
        this.ProcessSchemaParameterValueEdit = ProcessSchemaParameterValueEdit;
        this.isProviderInitialized = true;
    }

});

Terrasoft.ProcessSchemaParameterValueEdit.WebServiceDataProvider = Ext.extend(
		Terrasoft.ProcessSchemaParameterValueEdit.DataProvider, {
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
		        this.ProcessSchemaParameterValueEdit.fireEvent('preparefilters', this);
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
		            this.ProcessSchemaParameterValueEdit.setValue(data);
		        } finally {
		        }
		    },

		    handleFailure: function (response) {
		    }
		});

Ext.reg('processschemaparametervalueprovider', Terrasoft.ProcessSchemaParameterValueEdit.WebServiceDataProvider);

if (typeof Sys !== "undefined") {
    Sys.Application.notifyScriptLoaded();
}