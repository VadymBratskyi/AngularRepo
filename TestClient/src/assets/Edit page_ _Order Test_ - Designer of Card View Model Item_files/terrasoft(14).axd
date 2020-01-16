Terrasoft.DataSourceRequest = function (dataSource) {
    this.dataSource = dataSource;
};

Ext.extend(Terrasoft.DataSourceRequest, {});

Terrasoft.DataSourceRequest.prototype = {

    configure: function (cfg) {
        var dataSource = this.dataSource;
        var request = {
            id: cfg.id,
            dataSourceId: dataSource.id,
            schemaUId: dataSource.schemaUId,
            structureContextId: dataSource.structureContextId
        };
        if (!Ext.isEmpty(dataSource.managerName)) {
            request.managerName = dataSource.managerName;
        }
        if (!Ext.isEmpty(dataSource.structureName)) {
            request.structureName = dataSource.structureName;
        }
        if (cfg.primaryColumnValue) {
            request.primaryColumnValue = cfg.primaryColumnValue;
        }
        if (cfg.columns) {
            request.columns = cfg.columns;
        }
        if (cfg.values) {
            request.values = cfg.values;
        }
        if (cfg.pageableRowId) {
            request.values = this.getSortedColumnValues(cfg.pageableRowId);
        }
        if (cfg.pageableDirection) {
            request.pageableDirection = cfg.pageableDirection;
        }
        if (cfg.filters) {
            request.filters = cfg.filters.encode()
        }
        if (!Ext.isEmpty(cfg.filteredColumnName) && !Ext.isEmpty(cfg.filterValue)) {
            request.hierarchicalColumnName = cfg.filteredColumnName;
            request.hierarchicalColumnValue = cfg.filterValue;
            if (cfg.row) {
                request.row = cfg.row;
            }
        }
        if (cfg.summaryColumnName) {
            request.summaryColumnName = cfg.summaryColumnName;
        }
        if (cfg.alreadyContainsRows) {
            request.alreadyContainsRows = cfg.alreadyContainsRows;
        }
        return Ext.encode(request);
    },

    //private
    getSortedColumnValues: function (rowId) {
        var dataSource = this.dataSource;
        var structure = dataSource.structure;
        var primaryColumnName = structure.primaryColumnName;
        var row = dataSource.getRow(rowId);
        if (row) {
            var values = {};
            values[primaryColumnName] = row.getPrimaryColumnValue();
            for (var i = 0, l = structure.columns.length; i < l; i++) {
                var column = structure.columns[i], columnName = column.valueColumnName;
                if (column.orderDirection != "None") {
                    values[columnName] = column.isLookup
						? row.getColumnDisplayValue(column.name) : row.getColumnValue(columnName);
                }
            }
            return values;
        }
        return null;
    }

};

Terrasoft.FilterBase = function (cfg) {
};

Ext.extend(Terrasoft.FilterBase, Ext.util.Observable, {

    parentGroup: null,
    isEnabled: true,

    getFirstLevelGroup: function () {
        var group = null, parentGroup = this.parentGroup;
        if (parentGroup && parentGroup.parentGroup == null) {
            return this;
        }
        while (parentGroup.parentGroup != null) {
            group = parentGroup;
            parentGroup = parentGroup.parentGroup;
        }
        return group;
    },

    getRootGroup: function () {
        var parentGroup = this.parentGroup, group = parentGroup;
        if (parentGroup == null) {
            return this;
        }
        while (parentGroup != null) {
            group = parentGroup;
            parentGroup = parentGroup.parentGroup;
        }
        return group;
    },

    // private
    synchronizeResponse: function (filterItem) {
        if (!filterItem) {
            return;
        }
        var existingFilterItem = this.findItemByUId(filterItem.uId);
        if (!existingFilterItem) {
            return;
        }
        Ext.apply(existingFilterItem, filterItem);
        if (!filterItem.leftExpression) {
            delete existingFilterItem.leftExpression;
        }
        if (filterItem.rightExpression) {
            var rightExpression = filterItem.rightExpression;
            var paramValues = rightExpression.parameterValues;
            if (rightExpression.expressionType == Terrasoft.Filter.ExpressionType.PARAMETER ||
					(paramValues && paramValues.length > 0)) {
                this.decodeExpressionValues(paramValues, rightExpression.dataValueType);
            }
        } else {
            existingFilterItem.rightExpression = {};
        }
        if (existingFilterItem.isNot) {
            throw "'filterItem.isNot' is not supported";
        }
        if (filterItem.subFilters) {
            existingFilterItem.subFilters = new Terrasoft.FiltersGroup(filterItem.subFilters);
            existingFilterItem.subFilters.parentGroup = existingFilterItem.parentGroup;
            existingFilterItem.subFilters.parentItem = existingFilterItem;
        }
        this.getRootGroup().fireEvent("updated", existingFilterItem);
    },

    synchronize: function (refreshData) {
        refreshData = (refreshData == undefined) ? "" : Ext.encode(refreshData);
        if (this instanceof Terrasoft.Filter) {
            this.getRootGroup().fireEvent("internalupdatefilter", this.encode(), refreshData);
        } else {
            this.getRootGroup().fireEvent("internalupdatefiltersgroup", this.encode(true), refreshData);
        }
    },

    decodeExpressionValues: function (parameterValues, dataValueType) {
        for (var i = 0, l = parameterValues.length; i < l; i++) {
            var paramValue = parameterValues[i];
            var decodedValue = Ext.decode(Ext.util.Format.htmlDecode(paramValue.displayValue));
            paramValue.displayValue = decodedValue;
            decodedValue = dataValueType.useClientEncoding == true
				? Ext.util.Format.htmlDecode(paramValue.parameterValue)
				: paramValue.parameterValue;
            decodedValue = Ext.decode(decodedValue);
            paramValue.parameterValue = decodedValue;
        }
    }

});

Terrasoft.Filter = Ext.extend(Terrasoft.FilterBase, {

    useDisplayValue: false,
    _isFilter: true,

    constructor: function (cfg) {
        Ext.apply(this, cfg);
        this.uId = this.uId || new Ext.ux.GUID().id;
    },

    initComponent: function () {
        this.addEvents(
			'updated'
		);
    },

    encodeRightExpressions: function () {
        var rightExpression = this.rightExpression;
        if (rightExpression) {
            var encodedRightExpression = {
                caption: rightExpression.caption,
                dataValueType: rightExpression.dataValueType,
                expressionType: rightExpression.expressionType,
                macrosType: rightExpression.macrosType,
                metaPath: rightExpression.metaPath,
                parameterValues: []
            };
            if (rightExpression.parameterValues && rightExpression.parameterValues.length !== 0) {
                for (var i = 0, l = rightExpression.parameterValues.length; i < l; i++) {
                    var paramValue = rightExpression.parameterValues[i];
                    var encodedParamValue = {};
                    var encodedValue = Ext.util.Format.htmlEncode(Ext.encode(paramValue.displayValue));
                    encodedParamValue.displayValue = encodedValue;
                    encodedValue = Ext.encode(paramValue.parameterValue);
                    if (rightExpression.dataValueType.useClientEncoding == true) {
                        encodedValue = Ext.util.Format.htmlEncode(encodedValue);
                    }
                    encodedParamValue.parameterValue = encodedValue;
                    encodedRightExpression.parameterValues[i] = encodedParamValue;
                }
            }
            return encodedRightExpression;
        }
        return null;
    },

    encode: function () {
        var filter = {
            _isFilter: true,
            entitySchemaManagerName: this.entitySchemaManagerName,
            entitySchemaKind: this.entitySchemaKind,
            _filterSchemaUId: this._filterSchemaUId,
            name: this.name,
            uId: this.uId,
            isEnabled: this.isEnabled,
            leftExpression: this.leftExpression,
            comparisonType: this.comparisonType,
            trimDateTimeParameterToDate: this.trimDateTimeParameterToDate
        };
        if (this.useDisplayValue) {
            filter.useDisplayValue = this.useDisplayValue;
        }
        filter.rightExpression = this.encodeRightExpressions();
        if (this.subFilters) {
            filter.subFilters = this.subFilters.encode();
        }
        return filter;
    }

});

Ext.reg('filter', Terrasoft.Filter);

Terrasoft.Filter.ExpressionType = {
    PARAMETER: 'Parameter',
    SCHEMA_COLUMN: 'SchemaColumn',
    FUNCTION: 'Function',
    AGGREGATION: 'Aggregation',
    MACROS: 'Macros',
    EXISTS: 'Exists',
    CUSTOM: 'Custom'
};

Terrasoft.FilterExperssionType = Terrasoft.Filter.ExpressionType;

Terrasoft.Filter.ComparisonType = {
    EQUAL: 'Equal',
    NOT_EQUAL: 'NotEqual',
    IS_NULL: 'IsNull',
    IS_NOT_NULL: 'IsNotNull',
    LESS: 'Less',
    LESS_OR_EQUAL: 'LessOrEqual',
    GREATER: 'Greater',
    GREATER_OR_EQUAL: 'GreaterOrEqual',
    START_WITH: 'StartWith',
    NOT_START_WITH: 'NotStartWith',
    CONTAIN: 'Contain',
    NOT_CONTAIN: 'NotContain',
    END_WITH: 'EndWith',
    NOT_END_WITH: 'NotEndWith',
    BETWEEN: 'Between',
    EXISTS: 'Exists',
    NOTEXISTS: 'NotExists'
};

Terrasoft.FilterComparisonType = Terrasoft.Filter.ComparisonType;

Terrasoft.Filter.LogicalOperation = {
    AND: 'And',
    OR: 'Or'
};

Terrasoft.FilterLogicalOperation = Terrasoft.Filter.LogicalOperation;

Terrasoft.Filter.AggregationType = {
    MIN: 'Min',
    MAX: 'Max',
    SUM: 'Sum',
    AVG: 'Avg',
    COUNT: 'Count',
    EXISTS: 'Exists', // TODO: remove on 'Exists' rework
    NOTEXISTS: 'NotExists', // TODO: remove on 'Exists' rework
    NONE: 'None'
};

Terrasoft.FilterAggregationType = Terrasoft.Filter.AggregationType;

Terrasoft.Filter.MacrosEditorPosition = {
    RIGHT: 'Right',
    LEFT: 'Left'
};

Terrasoft.Filter.MacrosList = [
	{
	    id: 'CurrentUserContact', refSchemaUIds: [
           '16be3651-8fe2-4159-8dd0-a803d4683dd3',
           'fb1c2bed-91d4-4b06-a28c-621a3d187008']
	},
	{
	    id: 'CurrentUser', refSchemaUIds: [
           '84f44b9a-4bc3-4cbf-a1a8-cec02c1c029c',
           'd5d01fcd-6d8c-4b29-9e58-cca3ffe62364']
	},
	{ id: 'PreviousHour', dataValueTypes: ['Time', 'DateTime'], group: 'Hour' },
	{ id: 'CurrentHour', dataValueTypes: ['Time', 'DateTime'], group: 'Hour' },
	{ id: 'NextHour', dataValueTypes: ['Time', 'DateTime'], group: 'Hour' },
	{ id: '', type: 'Separator', group: 'Hour' },
	{
	    id: 'HourMinute',
	    dataValueTypes: ['Time', 'DateTime'],
	    parameterType: 'Time',
	    group: 'Hour',
	    isSpecialMacros: true,
	    editor: {
	        xtype: 'datetimeedit',
	        kind: 'time',
	        listClass: "x-menu-no-hide-all"
	    },
	    editorPosition: Terrasoft.Filter.MacrosEditorPosition.RIGHT
	},
	{
	    id: 'PreviousNHours', type: 'CustomAmount', dataValueTypes: ['Time', 'DateTime'], parameterType: 'Integer',
	    group: 'Hour', isSpecialMacros: true
	},
	{
	    id: 'NextNHours', type: 'CustomAmount', dataValueTypes: ['Time', 'DateTime'], parameterType: 'Integer', group: 'Hour',
	    isSpecialMacros: true
	},
	{ id: 'Yesterday', dataValueTypes: ['Date', 'DateTime'], group: 'Day' },
	{ id: 'Today', dataValueTypes: ['Date', 'DateTime'], group: 'Day' },
	{ id: 'Tomorrow', dataValueTypes: ['Date', 'DateTime'], group: 'Day' },
	{ id: '', type: 'Separator', group: 'Day' },
	{
	    id: 'DayOfMonth',
	    dataValueTypes: ['Date', 'DateTime'],
	    parameterType: 'Integer',
	    group: 'Day',
	    isSpecialMacros: true,
	    editor: {
	        xtype: 'integeredit',
	        maxValue: 31,
	        minValue: 1
	    },
	    editorPosition: Terrasoft.Filter.MacrosEditorPosition.RIGHT
	},
	{
	    id: 'DayOfWeek',
	    dataValueTypes: ['Date', 'DateTime'],
	    parameterType: 'Integer',
	    group: 'Day',
	    isSpecialMacros: true,
	    editor: {
	        xtype: 'combo',
	        listClass: "x-menu-no-hide-all"
	    },
	    dataProviderXType: 'culturedayofweekdataprovider',
	    editorPosition: Terrasoft.Filter.MacrosEditorPosition.RIGHT
	},
	{
	    id: 'PreviousNDays', type: 'CustomAmount', dataValueTypes: ['Date', 'DateTime'], parameterType: 'Integer',
	    group: 'Day', isSpecialMacros: true
	},
	{
	    id: 'NextNDays', type: 'CustomAmount', dataValueTypes: ['Date', 'DateTime'], parameterType: 'Integer',
	    group: 'Day', isSpecialMacros: true
	},
	{ id: 'PreviousWeek', dataValueTypes: ['Date', 'DateTime'], group: 'Week' },
	{ id: 'CurrentWeek', dataValueTypes: ['Date', 'DateTime'], group: 'Week' },
	{ id: 'NextWeek', dataValueTypes: ['Date', 'DateTime'], group: 'Week' },
	{ id: 'PreviousMonth', dataValueTypes: ['Date', 'DateTime'], group: 'Month' },
	{ id: 'CurrentMonth', dataValueTypes: ['Date', 'DateTime'], group: 'Month' },
	{ id: 'NextMonth', dataValueTypes: ['Date', 'DateTime'], group: 'Month' },
	{ id: '', type: 'Separator', group: 'Month' },
	{
	    id: 'Month',
	    dataValueTypes: ['Date', 'DateTime'],
	    parameterType: 'Integer',
	    group: 'Month',
	    isSpecialMacros: true,
	    editor: {
	        xtype: 'combo',
	        listClass: "x-menu-no-hide-all"
	    },
	    dataProviderXType: 'culturemonthsdataprovider',
	    editorPosition: Terrasoft.Filter.MacrosEditorPosition.RIGHT
	},
	{ id: 'PreviousQuarter', dataValueTypes: ['Date', 'DateTime'], group: 'Quarter' },
	{ id: 'CurrentQuarter', dataValueTypes: ['Date', 'DateTime'], group: 'Quarter' },
	{ id: 'NextQuarter', dataValueTypes: ['Date', 'DateTime'], group: 'Quarter' },
	{ id: 'PreviousHalfYear', dataValueTypes: ['Date', 'DateTime'], group: 'HalfYear' },
	{ id: 'CurrentHalfYear', dataValueTypes: ['Date', 'DateTime'], group: 'HalfYear' },
	{ id: 'NextHalfYear', dataValueTypes: ['Date', 'DateTime'], group: 'HalfYear' },
	{ id: 'PreviousYear', dataValueTypes: ['Date', 'DateTime'], group: 'Year' },
	{ id: 'CurrentYear', dataValueTypes: ['Date', 'DateTime'], group: 'Year' },
	{ id: 'NextYear', dataValueTypes: ['Date', 'DateTime'], group: 'Year' },
	{ id: '', type: 'Separator', group: 'Year' },
	{
	    id: 'Year',
	    dataValueTypes: ['Date', 'DateTime'],
	    parameterType: 'Integer',
	    group: 'Year',
	    editor: {
	        xtype: 'integeredit',
	        showThousandsSeparator: false
	    },
	    isSpecialMacros: true
	}
];

Terrasoft.FilterMacrosList = Terrasoft.Filter.MacrosList;

Terrasoft.FiltersGroup = function (cfg) {
    this.items = new Ext.util.MixedCollection(false, function (item) {
        return item.uId;
    });
    this.logicalOperation = Terrasoft.FilterLogicalOperation.AND;
    this.initComponent();
    if (!cfg || cfg._isFilter) {
        return;
    }
    this._isFilter = cfg._isFilter;
    this.uId = this.uId || cfg.uId || new Ext.ux.GUID().id;
    this.isNot = !!cfg.isNot;
    this.name = cfg.name;
    this.isEnabled = Ext.isEmpty(cfg.isEnabled) ? true : cfg.isEnabled;
    if (cfg.logicalOperation) {
        this.logicalOperation = cfg.logicalOperation;
    }
    if (cfg.items) {
        for (var i = 0, l = cfg.items.length; i < l; i++) {
            this.internalAddResponse(!cfg.items[i]._isFilter ?
				new Terrasoft.FiltersGroup(cfg.items[i]) : new Terrasoft.Filter(cfg.items[i]));
        }
    }
};

Ext.extend(Terrasoft.FiltersGroup, Terrasoft.FilterBase, {

    initComponent: function () {
        this.addEvents(
			'added',
			'enabled',
			'inserted',
			'removed',
			'moved',
			'updated',
			'internaladd',
			'internalgroupfilters',
			'internalungroup',
			'internalmove',
			'internalupdatefilter',
			'internalupdatefiltersgroup'
		);
    },

    setEnabled: function (itemId, enabled) {
        var item = this.findItemByUId(itemId);
        if (item && item.isEnabled != enabled) {
            this.getRootGroup().fireEvent("enabled", item);
        }
    },

    findItemByUId: function (uId) {
        if (Ext.isEmpty(uId)) {
            return null;
        }
        if (this.uId == uId) {
            return this;
        }
        var item;
        if (this.items.containsKey(uId)) {
            return this.items.item(uId);
        } else {
            for (var i = 0, l = this.items.length; i < l; i++) {
                if (this.items.items[i] instanceof Terrasoft.FiltersGroup) {
                    item = this.items.items[i].findItemByUId(uId);
                    if (item) {
                        return item;
                    }
                } else {
                    if (this.items.items[i] instanceof Terrasoft.Filter) {
                        if (this.items.items[i].subFilters) {
                            if (this.items.items[i].subFilters.uId == uId) {
                                return this.items.items[i].subFilters;
                            }
                            item = this.items.items[i].subFilters.findItemByUId(uId);
                            if (item) {
                                return item
                            }
                        }
                    }
                }
            }
        }
        return null;
    },

    createFilterWithParameters: function (comparisonType, leftExpressionMetaPath, rightExpressionParameterValues) {
        var parameters = Ext.isArray(rightExpressionParameterValues) ?
            rightExpressionParameterValues : (rightExpressionParameterValues == undefined ? [] : [rightExpressionParameterValues]);
        var cfg = {
            comparisonType: comparisonType,
            leftExpression: {
                expressionType: Terrasoft.Filter.ExpressionType.SCHEMA_COLUMN,
                metaPath: leftExpressionMetaPath
            },
            rightExpression: {
                expressionType: Terrasoft.Filter.ExpressionType.PARAMETER,
                dataValueType: {},
                parameterValues: parameters
            }
        };
        return new Terrasoft.Filter(cfg);
    },

    createGroup: function (cfg) {
        return new Terrasoft.FiltersGroup(cfg);
    },

    addGroup: function (logicalOperation) {
        var filtersGroup = logicalOperation instanceof Terrasoft.FiltersGroup ?
            logicalOperation : this.createGroup({ logicalOperation: logicalOperation || Terrasoft.Filter.LogicalOperation.AND });
        this.add(filtersGroup);
    },

    remove: function (itemUId, refreshData) {
        refreshData = (refreshData == undefined) ? "" : Ext.encode(refreshData);
        this.getRootGroup().fireEvent("internalremove", itemUId, refreshData);
    },

    clear: function (refreshData) {
        refreshData = (refreshData == undefined) ? "" : Ext.encode(refreshData);
        var groupUId = this.uId;
        this.getRootGroup().fireEvent("internalcleargroup", groupUId, refreshData);
    },

    // private
    onInternalRemoveResponse: function (itemUId) {
        var item = this.findItemByUId(itemUId);
        if (!item) {
            return null;
        }
        var parentGroup = item.parentGroup || this;
        if (item instanceof Terrasoft.Filter) {
            parentGroup.items.removeKey(itemUId);
            this.getRootGroup().fireEvent("removed", item);
            return item;
        }
        if (item instanceof Terrasoft.FiltersGroup) {
            parentGroup.removeGroup(item);
            if (item.parentGroup != null) {
                this.getRootGroup().fireEvent("removed", item);
            }
        }
    },

    internalUpdateSubFilters: function (filterUId, item) {
        var filter = this.findItemByUId(filterUId);
        if (filter != null) {
            if (item) {
                var subFilters = filter.subFilters = new Terrasoft.FiltersGroup(item);
                subFilters.parentItem = filter;
                subFilters.parentGroup = this.parentGroup;
            } else {
                filter.subFilters = null;
            }
        }
    },

    // private
    removeGroup: function (group) {
        while (group.items.items[0]) {
            if (group.items.items[0] instanceof Terrasoft.Filter) {
                group.items.removeAt(0);
            } else {
                group.removeGroup(group.items.items[0]);
            }
        }
        this.items.remove(group);
    },

    move: function (itemUId, targetUId, position) {
        this.getRootGroup().fireEvent("internalmove", itemUId, targetUId, position);
    },

    // private
    moveResponse: function (itemUId, targetUId, position) {
        var item = this.findItemByUId(itemUId);
        if (!item) {
            return null;
        }
        var targetItem = (this.uId == targetUId) ? this : this.findItemByUId(targetUId);
        if (!targetItem) {
            return null;
        }
        item.parentGroup.items.remove(item);
        var targetIsFilter = targetItem instanceof Terrasoft.Filter;
        var parent = targetItem.parentGroup;
        var targetIndex = parent.items.indexOfKey(targetUId);
        switch (position) {
            case "Append":
                if (targetIsFilter) {
                    parent.items.internalAddResponse(item, targetIndex >= 0 ? ++targetIndex : 0);
                    item.parentGroup = parent;
                    this.getRootGroup().fireEvent("moved", item);
                    return item;
                }
                item.parentGroup = targetItem;
                targetItem.items.insert(0, item);
                this.getRootGroup().fireEvent("moved", item)
                break;
            case "Above":
                parent.items.insert(targetIndex > 0 ? targetIndex : 0, item);
                item.parentGroup = parent;
                break;
            case "Below":
                parent.items.insert(targetIndex >= 0 ? ++targetIndex : 0, item);
                item.parentGroup = parent;
                break;
        }
        this.getRootGroup().fireEvent("moved", item);
    },

    insertGroup: function (targetId, position, logicalOperation) {
        logicalOperation = logicalOperation || Terrasoft.Filter.LogicalOperation.AND;
        var targetItem = this.findItemByUId(targetId);
        if (!targetItem) {
            return null;
        }
        var targetIsFilter = targetItem instanceof Terrasoft.Filter;
        var parent = targetItem.parentGroup;
        var targetIndex = -1;
        var newGroup = this.createGroup({
            logicalOperation: logicalOperation
        });
        targetIndex = parent.items.indexOfKey(targetId);
        switch (position) {
            case "Append":
                if (targetIsFilter) {
                    return this.insertGroup(targetId, "Below", logicalOperation);
                }
                return targetItem.internalAddResponse(newGroup);
                break;
            case "Above":
                return parent.internalAddResponse(newGroup, targetIndex > 0 ? targetIndex : 0);
                break;
            case "Below":
                return parent.internalAddResponse(newGroup, targetIndex >= 0 ? ++targetIndex : 0);
                break;
        }
    },

    add: function (item, refreshData) {
        if (Ext.isEmpty(item)) {
            return;
        }
        refreshData = (refreshData == undefined) ? "" : Ext.encode(refreshData);
        this.getRootGroup().fireEvent("internaladd", this.uId, item.encode(), refreshData);
    },

    internalAdd: function (filter) {
        if (Ext.isEmpty(filter)) {
            return;
        }
        filter.rightExpression = filter.encodeRightExpressions();
        this.internalAddResponse(filter);
    },

    // private
    internalAddResponse: function (item, index, targetUId) {
        if (!Ext.isEmpty(targetUId)) {
            var target = this.findItemByUId(targetUId);
            return target.internalAddResponse(item, index);
        }
        if (!item) {
            return null;
        }
        if (!item._isFilter && item.name) {
            var existingGroup = this.items.find(function (itm) {
                if (!itm._isFilter && itm.name == item.name) {
                    return true;
                }
                return false;
            });
            if (existingGroup) {
                var items = item.items.items || item.items;
                for (var j = 0, gLength = items.length; j < gLength; j++) {
                    existingGroup.internalAddResponse(items[j], -1);
                }
                return item;
            }
        }
        if (!(item instanceof Terrasoft.Filter) && !(item instanceof Terrasoft.FiltersGroup)) {
            item = item._isFilter ? new Terrasoft.Filter(item) : new Terrasoft.FiltersGroup(item);
        }
        item.parentGroup = this;
        item.uId = item.uId || new Ext.ux.GUID().id;
        if (item instanceof Terrasoft.Filter) {
            var rightExpression = item.rightExpression;
            if (rightExpression) {
                var expressionType = rightExpression.expressionType;
                var parameterValues = rightExpression.parameterValues;
                if (parameterValues && (
						expressionType == Terrasoft.Filter.ExpressionType.PARAMETER ||
						expressionType == Terrasoft.Filter.ExpressionType.MACROS ||
						expressionType == Terrasoft.Filter.ExpressionType.CUSTOM)) {
                    this.decodeExpressionValues(parameterValues, rightExpression.dataValueType);
                }
            }
            if (item.subFilters) {
                item.subFilters = new Terrasoft.FiltersGroup(item.subFilters);
                item.subFilters.parentItem = item;
                item.subFilters.parentGroup = this;
            }
        }
        var insertionIndex = ((typeof index == "undefined") || (index == -1)) ? this.items.length : index;
        this.items.insert(insertionIndex, item);
        if (typeof index != "undefined" && index >= 0) {
            this.getRootGroup().fireEvent("inserted", item);
        } else {
            this.getRootGroup().fireEvent("added", item);
        }
        return item;
    },

    addFilter: function (comparisonType, leftExpressionMetaPath, rightExpressionParameterValues, cfg) {
        var filter = this.createFilterWithParameters(comparisonType, leftExpressionMetaPath, rightExpressionParameterValues);
        if (cfg) {
            Ext.apply(filter, cfg);
        }
        this.add(filter);
        return filter;
    },

    // TODO  Переименовать метод
    encode: function (omitItems) {
        var items = {
            _isFilter: false,
            name: this.name,
            uId: this.uId,
            isEnabled: this.isEnabled,
            logicalOperation: this.logicalOperation,
            items: []
        }
        if (this.logicalOperation == Terrasoft.Filter.LogicalOperation.ANDNOT) {
            items.isNot = true;
            items.logicalOperation = Terrasoft.Filter.LogicalOperation.AND;
        } else if (this.logicalOperation == Terrasoft.Filter.LogicalOperation.ORNOT) {
            items.isNot = true;
            items.logicalOperation = Terrasoft.Filter.LogicalOperation.OR;
        }
        if (omitItems !== true) {
            var item;
            for (var i = 0, len = this.items.length; i < len; i++) {
                item = this.items.items[i];
                items.items.push(item.encode());
            }
        }
        return items;
    },

    group: function (filterUIds) {
        if (Ext.isEmpty(filterUIds)) {
            return;
        }
        this.getRootGroup().fireEvent("internalgroupfilters", this.uId, Ext.encode(filterUIds));
    },

    ungroup: function () {
        if (this.parentGroup == null) {
            return;
        }
        this.getRootGroup().fireEvent("internalungroup", this.uId);
    }

});

Ext.reg('filtersgroup', Terrasoft.FiltersGroup);

Terrasoft.Row = function (cfg) {
    cfg = cfg || {
        columns: {}
    };
    this.dataSource = cfg.dataSource;
    this.modifiedValues = this.state = null;
    this.dirty = false;
    this.columns = cfg.columns || {};
};

Terrasoft.ColumnRightLevel = {
    CAN_EDIT: 'CanEdit',
    CAN_READ: 'CanRead',
    DENY: 'Deny'
};

Ext.extend(Terrasoft.Row, {});

Terrasoft.Row.NEW = 'New';
Terrasoft.Row.CHANGED = 'Changed';

Terrasoft.Row.prototype = {

    stateRe: '/^(?:New|Changed)$/',

    getPrimaryColumnName: function () {
        return this.dataSource.getPrimaryColumnName();
    },

    getHierarchicalColumnName: function () {
        return this.dataSource.getHierarchicalColumnName();
    },

    index: function () {
        if (!this.columns) {
            return -1;
        }
        var dataSource = this.dataSource;
        return dataSource.rows.indexOfKey(this.getPrimaryColumnValue());
    },

    getColumnValue: function (columnName) {
        var column = this.dataSource.getColumnByName(columnName);
        var valueColumnName = column ? (column.isLookup ? column.valueColumnName : columnName) : columnName;
        var value = this.columns[valueColumnName];
        return value != undefined ? value : null;
    },

    getColumnValueByColumnUId: function (columnUId) {
        var column = this.dataSource.getColumnByUId(columnUId);
        var value = this.getColumnValue(column.name);
        return value;
    },

    getColumnDisplayValue: function (columnName) {
        var column = this.dataSource.getColumnByName(columnName);
        var value = this.columns[column.displayColumnName];
        return value != undefined ? value : null;
    },

    getColumnOldValue: function (columnName) {
        var m = this.modifiedValues;
        if (m && m[columnName]) {
            return m[columnName];
        }
        return this.columns[columnName];
    },

    getPrimaryColumnValue: function () {
        return this.getColumnValue(this.getPrimaryColumnName());
    },

    getParentColumnValue: function () {
        var parentColumnValueName = this.dataSource.getParentColumnValueName();
        if (!parentColumnValueName) {
            return null;
        }
        return this.getColumnValue(parentColumnValueName);
    },

    setColumnValue: function (columnName, value) {
        this.setModified(true);
        if (!this.modifiedValues) {
            this.dirty = true;
            if (this.state != Terrasoft.Row.NEW) {
                this.state = Terrasoft.Row.CHANGED;
            }
            this.modifiedValues = {};
        }
        if (typeof this.modifiedValues[columnName] == 'undefined') {
            this.modifiedValues[columnName] = this.columns[columnName];
        }
        this.columns[columnName] = value;
        this.dataSource.updateActiveRowHiddenField(this);
        return this.columns[columnName];
    },

    getState: function () {
        if (this.state == null) {
            return null;
        }
        var result = this.stateRe.match(this.state);
        return result ? result[0] : null;
    },

    save: function () {
        if (!this.modifiedValues) {
            return;
        }
        this.dataSource.save(this);
    },

    cancel: function (cfg) {
        cfg = cfg || {};
        var state = this.getState();
        if (state == Terrasoft.Row.NEW) {
            cfg.primaryColumnValue = this.getPrimaryColumnValue();
            this.dataSource.remove(cfg);
            return;
        }
        if (this.dirty === false) {
            return;
        }
        var m = this.modifiedValues;
        for (var n in m) {
            this.columns[n] = m[n];
            this.dataSource.fireEvent("datachanged", this, n);
        }
        this.clearState();
        this.dataSource.fireEvent('canceled', this.dataSource, [this.columns], cfg);
    },

    hasChanges: function () {
        return this.dirty;
    },

    // private
    applyChanges: function () {
        var m = this.modifiedValues;
        for (var n in m) {
            this.columns[n] = m[n];
        }
        this.clearState();
    },

    // private
    clearState: function () {
        this.dirty = false;
        this.state = null;
        delete this.modifiedValues;
        this.setModified(false);
    },

    // private
    setModified: function (value) {
        this.modified = !!value;
        if (!this.activeRowModifiedHiddenField) {
            var formEl = Ext.get(document.forms[0]);
            var hiddenFieldActiveRowModifiedName = this.dataSource.id + '_ActiveRowModified';
            this.activeRowModifiedHiddenField = Ext.get(formEl.createChild({
                tag: 'input',
                type: 'hidden',
                name: hiddenFieldActiveRowModifiedName,
                id: hiddenFieldActiveRowModifiedName
            }, undefined, true));
        }
        this.activeRowModifiedHiddenField.dom.value = value;
    }

};

Terrasoft.DataSource = Ext.extend(Ext.Component, {
    enableServerActiveRow: false,
    structure: {},
    activeRow: null,
    _activeRowPrimaryColumnValue: null,
    requestConfig: {},
    invalidColumns: [],
    rows: null,

    initComponent: function () {
        this.rows = new Ext.util.MixedCollection(false, function (row) {
            return row.getPrimaryColumnValue();
        });
        Terrasoft.DataSource.superclass.initComponent.call(this);
        this.addEvents(
			'beforeloadstructure',
			'structureloaded',
			'structureloadexception',
			'beforeupdatestructure',
			'structureupdated',
			'quickviewcolumnsupdated',
			'structureupdateexception',
			'beforeload',
			'loaded',
			'loadexception',
			'datachanged',
			'beforeloadsummary',
			'summaryloaded',
			'summaryloadexception',
			'beforerowdataload',
			'rowdataload',
			'beforeloadrow',
			'rowloaded',
			'rowloadexception',
			'beforeloadquickview',
			'quickviewload',
			'quickviewloadexception',
			'beforesave',
			'saved',
			'saveexception',
			'beforeinsert',
			'inserted',
			'insertexception',
			'beforeremove',
			'remove',
			'removeexception',
			'canceled',
			'internalload',
			'internalloadrow',
			'internalloadquickview',
			'internalloadsummary',
			'internalsave',
			'internalinsert',
			'internalremove',
			'internalupdatestructure',
			'activerowchanged',
			'selectionchanged',
			'internaladdfilteritem',
			'internalupdatefilter',
			'internalremovefilteritem',
			'internalclearfiltergroup',
			'internalmovefilteritem',
			'internalgroupfilteritems',
			'internalungroup',
			'internalmovestructurecolumn',
			'internalremovestructurecolumns',
			'columnmoved',
			'columnsremoved',
			'beforerowmove',
			'rowmoved',
			'internalupdatefiltersgroup',
			'removed'
		);
        // TODO убрать этот HACK после того как будет решена проблема с init_ev
        if (this.ajaxEvents) {
            if (this.ajaxEvents.structureloaded) {
                this.on({
                    structureloaded: this.ajaxEvents.structureloaded
                });
                delete this.ajaxEvents.structureloaded;
            }
            if (this.ajaxEvents.loaded) {
                this.on({
                    loaded: this.ajaxEvents.loaded
                });
                delete this.ajaxEvents.loaded;
            }
            if (this.ajaxEvents.internalload) {
                this.on({
                    internalload: this.ajaxEvents.internalload
                });
                delete this.ajaxEvents.internalload;
            }
            if (this.ajaxEvents.internalloadsummary) {
                this.on({
                    internalloadsummary: this.ajaxEvents.internalloadsummary
                });
                delete this.ajaxEvents.internalloadsummary;
            }
            if (this.ajaxEvents.internaladdfilteritem) {
                this.on({
                    internaladdfilteritem: this.ajaxEvents.internaladdfilteritem
                });
                delete this.ajaxEvents.internaladdfilteritem;
            }
            if (this.ajaxEvents.activerowchanged) {
                this.on({
                    activerowchanged: this.ajaxEvents.activerowchanged
                });
                delete this.ajaxEvents.activerowchanged;
            }
        }
    },

    render: function () {
        var formEl = Ext.get(document.forms[0]);
        var hiddenFieldActiveRowPrimaryColumnValueName = this.id + '_ActiveRowPrimaryColumnValue';
        this.el = this.activeRowPrimaryColumnValueHiddenField = Ext.get(formEl.createChild({
            tag: 'input',
            type: 'hidden',
            name: hiddenFieldActiveRowPrimaryColumnValueName,
            id: hiddenFieldActiveRowPrimaryColumnValueName
        }, undefined, true));
        this.initSelectionHiddenField();
        this.initEvents();
        this.rendered = true;
    },

    initEvents: Ext.emptyFn,

    regRequestConfig: function (config) {
        var id = Ext.id();
        config.id = id;
        if (!Ext.isEmptyObj(config)) {
            this.requestConfig[id] = !Ext.isIE ? config : this.cloneRequestConfig(config);;
        }
    },

    cloneRequestConfig: function (config) {
        var configObj = {};
        for (var prop in config) {
            configObj[prop] = config[prop];
        }
        return configObj;
    },

    getRequestConfig: function (id) {
        if (this.requestConfig) {
            return this.requestConfig[id];
        }
        return null;
    },

    removeRequestConfig: function (id) {
        if (Ext.isEmpty(id) || !this.requestConfig) {
            return;
        }
        delete this.requestConfig[id];
    },

    onActiveRowValidationResponse: function (validationInfo, showMessage) {
        var markValid = [], index, newInvalidColumns = [],
		oldLength = this.invalidColumns ? this.invalidColumns.length : 0,
		newLength = validationInfo ? validationInfo.length : 0;
        if (oldLength == 0 && newLength == 0) {
            return;
        }
        for (var key in validationInfo) {
            if (validationInfo.hasOwnProperty(key)) {
                newInvalidColumns.push(key);
            }
        }
        if (newLength == 0 && oldLength != 0) {
            markValid = this.invalidColumns;
            this.invalidColumns = [];
        } else {
            Ext.each(this.invalidColumns, function (item) {
                (index = newInvalidColumns.indexOf(item)) >= 0 ? newInvalidColumns.splice(index, 1) : markValid.push(item);
            }, this);
        }
        if (this.invalidColumns.length > 0) {
            Ext.each(markValid, function (item) {
                this.fireEvent("activerowvalidated", item, true);
                this.invalidColumns.splice(this.invalidColumns.indexOf(item), 1);
            }, this);
        } else {
            Ext.each(markValid, function (item) {
                this.fireEvent("activerowvalidated", item, true);
            }, this);
        }
        Ext.each(newInvalidColumns, function (item) {
            this.fireEvent("activerowvalidated", item, false, validationInfo[item]);
        }, this);
        if (showMessage === true) {
            Ext.each(this.invalidColumns, function (item) {
                if (validationInfo[item]) {
                    this.fireEvent("activerowvalidated", item, false, validationInfo[item]);
                }
            }, this);
        }
        this.invalidColumns = this.invalidColumns.concat(newInvalidColumns);
    },

    setActiveRow: function (key, silent) {
        var activeRow;
        if (Ext.isEmpty(key)) {
            activeRow = null;
        } else if (typeof key == "string" || typeof key == "number") {
            activeRow = this.getRow(key);
        } else if (key instanceof Terrasoft.Row) {
            activeRow = this.getRow(key.getPrimaryColumnValue());
        } else if (key[this.getPrimaryColumnName()]) {
            activeRow = this.getRow(key[this.getPrimaryColumnName()]);
            if (!activeRow) {
                this.onInsertResponse(key, silent);
                return;
            }
        }
        if (this.activeRow != activeRow) {
            this.activeRow = activeRow;
            var activeRowPrimaryColumnValue = this.activeRow ? this.activeRow.getPrimaryColumnValue() : null;
            this.activeRowPrimaryColumnValueHiddenField.dom.value = activeRowPrimaryColumnValue;
            if (this.enableServerActiveRow) {
                if (!this.activeRowHiddenField) {
                    var formEl = Ext.get(document.forms[0]);
                    var hiddenFieldActiveRowName = this.id + '_ActiveRow';
                    this.activeRowHiddenField = Ext.get(formEl.createChild({
                        tag: 'input',
                        type: 'hidden',
                        name: hiddenFieldActiveRowName,
                        id: hiddenFieldActiveRowName
                    }, undefined, true));
                }
                this.updateActiveRowHiddenField(this.activeRow);
            }
            if (!this._activeRowPrimaryColumnValue && silent !== true) {
                this.fireEvent("activerowchanged", this, activeRowPrimaryColumnValue);
            }
        }
        if (!this.activeRow) {
            this._activeRowPrimaryColumnValue = key;
        } else {
            this._activeRowPrimaryColumnValue = null;
        }
        if (Ext.isEmpty(key)) {
            this.activeRowPrimaryColumnValueHiddenField.dom.value = null;
        }
        return this.activeRow;
    },

    initSelectionHiddenField: function () {
        var hiddenFieldSelectedItemIdsName = this.id + '_SelectedItemPrimaryColumnValues';
        if (Ext.get(hiddenFieldSelectedItemIdsName)) {
            return;
        }
        var formEl = Ext.get(document.forms[0]);
        this.selectedItemPrimaryColumnValuesHiddenField = Ext.get(formEl.createChild({
            tag: 'input',
            type: 'hidden',
            name: hiddenFieldSelectedItemIdsName,
            id: hiddenFieldSelectedItemIdsName
        }, undefined, true));
        this.selData = [];
    },

    setSelection: function (primaryColumnValues, senderKey) {
        this.selData = primaryColumnValues;
        if (this.selData == null) {
            return;
        }
        if (this.selectedItemPrimaryColumnValuesHiddenField) {
            this.selectedItemPrimaryColumnValuesHiddenField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData);
        }
        this.fireEvent("selectionchanged", this, senderKey || "");
    },

    addToSelection: function (primaryColumnValue, keepExisting, senderKey) {
        if (this.selData == null || (keepExisting != undefined && !keepExisting)) {
            this.selData = [];
        }
        this.selData.push(primaryColumnValue);
        this.selectedItemPrimaryColumnValuesHiddenField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData);
        this.fireEvent("selectionchanged", this, senderKey || "");
    },

    removeFromSelection: function (primaryColumnValue, senderKey) {
        if (!this.selData) {
            return;
        }
        for (var i = 0; i < this.selData.length; i++) {
            if (this.selData[i] == primaryColumnValue) {
                this.selData.splice(i, 1);
                this.selectedItemPrimaryColumnValuesHiddenField.dom.value = Ext.util.JSON.encodeNamedArray(this.selData);
                this.fireEvent("selectionchanged", this, senderKey || "");
                return;
            }
        }
    },

    clearSelection: function (senderKey) {
        this.selData = [];
        this.selectedItemPrimaryColumnValuesHiddenField.dom.value = "";
        this.fireEvent("selectionchanged", this, senderKey || "");
    },

    // private
    updateActiveRowHiddenField: function (row) {
        if (!this.enableServerActiveRow || this.activeRow != row) {
            return;
        }
        var hasActiveRow = !!this.activeRow;
        var activeRowCfg = {
            isNew: hasActiveRow ? this.activeRow.getState() == Terrasoft.Row.NEW : true,
            changes: this.getChanges()
        };
        this.activeRowHiddenField.dom.value = Ext.encode(activeRowCfg);
    },

    getColumnByName: function (name) {
        if (Ext.isEmpty(name) || !this.hasStructure()) {
            return null;
        }
        for (var i = 0; i < this.structure.columns.length; i++) {
            if (this.structure.columns[i].name == name) {
                return this.structure.columns[i];
            }
        }
        return null;
    },

    getColumnByUId: function (uId) {
        if (Ext.isEmpty(uId) || !this.hasStructure()) {
            return null;
        }
        for (var i = 0; i < this.structure.columns.length; i++) {
            if (this.structure.columns[i].uId == uId) {
                return this.structure.columns[i];
            }
        }
        return null;
    },

    getPrimaryColumnName: function () {
        return this.hasStructure() ? this.structure.primaryColumnName : "";
    },

    getPrimaryColumnValue: function () {
        return this.activeRow ? this.activeRow.getPrimaryColumnValue() : null;
    },

    getHierarchicalColumnName: function () {
        return this.hasStructure() ? this.structure.hierarchicalColumnName : "";
    },

    getParentColumnValueName: function () {
        var parentColumn = this.getColumnByName(this.getHierarchicalColumnName());
        if (!parentColumn) {
            return null;
        }
        var columnName = parentColumn.isLookup ? parentColumn.valueColumnName : parentColumn.name;
        return columnName;
    },

    hasStructure: function () {
        var structure = this.structure
        return (structure && structure.columns && (structure.columns.length > 0));
    },

    hasColumn: function (columnName) {
        return this.getColumnByName(columnName) != null ? true : false;
    },

    createRow: function (columns) {
        if (!columns) {
            return null;
        }
        return new Terrasoft.Row({
            dataSource: this,
            columns: columns
        });
    },

    findRow: function (columnName, value, ignoreCase) {
        if (!this.rows || !columnName) {
            return null;
        }
        for (var i = 0, l = this.rows.length; i < l; i++) {
            var item = this.rows.items[i];
            var columnValue = item.getColumnValue(columnName);
            var isLowerCaseEquals = ignoreCase && 
                typeof(columnValue) === 'string' && typeof(value) === 'string' && 
                    columnValue.toLowerCase() === value.toLowerCase();
            if (isLowerCaseEquals || columnValue == value) {
                return item;
            }
        }
        return null;
    },

    findRowByColumnValues: function (columnValues) {
        if (!this.rows || !Ext.isArray(columnValues)) {
            return null;
        }
        var columnValuesLength = columnValues.length;
        for (var i = 0; i < columnValuesLength; i++) {
            var column = columnValues[i];
            if (typeof(column) !== 'object') {
                return null;
            }
        }
        var item = null;
        for (var i = 0, l = this.rows.length; i < l; i++) {
            item = this.rows.items[i];
            for (var x = 0; x < columnValuesLength; x++) {
                var column = columnValues[x];
                var columnValue = column.value;
                var itemValue = item.getColumnValue(column.name);
                var isLowerCaseEquals = column.ignoreCase && 
                    typeof(itemValue) === 'string' && typeof(columnValue) === 'string' && 
                        itemValue.toLowerCase() === columnValue.toLowerCase();
                if (!isLowerCaseEquals && itemValue != columnValue) {
                    item = null;
                    break;
                }
            }
            if (item) {
                break;
            }
        }
        return item;
    },

    getRow: function (key) {
        if (!this.rows) {
            return null;
        }
        return this.rows.get(key);
    },

    // private
    getChildRows: function (parentColumnValue) {
        var childRows = [], hierarchicalColumnName = this.getParentColumnValueName();
        this.rows.each(function (item, index, len) {
            if (item.columns[hierarchicalColumnName] == parentColumnValue) {
                childRows.push(item);
            }
        }, this);
        return childRows;
    },

    getRowState: function (key) {
        if (typeof key == "string") {
            key = this.getRow(key);
        }
        if (!key) {
            key = this.activeRow;
        }
        return key ? key.getState() : null;
    },

    getValue: function (key, columnName) {
        var row = this.getRow(key);
        return row ? row.getColumnValue(columnName) : null;
    },

    getChanges: function (row) {
        row = row || this.activeRow;
        if (!this.hasChanges(row)) {
            return null;
        }
        var changes = {}, column;
        for (var c in row.modifiedValues) {
            column = this.getColumnByName(c);
            if (column && column.isLookup) {
                continue;
            }
            changes[c] = row.columns[c];
        }
        return changes;
    },

    hasChanges: function (row) {
        row = row || this.activeRow;
        return (!row || !row.dirty) ? false : true;
    },

    getColumnValue: function (columnName) {
        return !this.activeRow ? null : this.activeRow.getColumnValue(columnName);
    },

    getColumnValueByColumnUId: function (columnUId) {
        return !this.activeRow ? null : this.activeRow.getColumnValueByColumnUId(columnUId);
    },

    getColumnDisplayValue: function (columnName) {
        return !this.activeRow ? null : this.activeRow.getColumnDisplayValue(columnName);
    },

    setColumnValue: function (columnName, columnValue, row) {
        row = row || this.activeRow;
        if (!row) {
            return null;
        }
        var column = this.getColumnByName(columnName);
        if (column && column.refSchemaName && columnValue) {
            var displayValue = this.getColumnDisplayValue(columnName);
            this.setColumnBothValues(columnName, columnValue, displayValue);
            return;
        }
        columnValue = Ext.value(columnValue, "");
        row.setColumnValue(columnName, columnValue);
        this.fireEvent("datachanged", row, columnName);
    },

    onActiveRowColumnValuesChangedResponse: function (id, data) {
        var row = this.getRow(id);
        if (!row) {
            return;
        }
        for (var columnName in data) {
            var item = data[columnName];
            var columnValue = item.columnValue;
            var displayColumnValue = item.displayColumnValue;
            if (displayColumnValue == undefined) {
                columnValue = this.decodeColumnValue(columnValue, columnName);
                this.setColumnValue(columnName, columnValue, row);
            } else {
                displayColumnValue = this.decodeColumnValue(displayColumnValue, columnName);
                this.setColumnBothValues(columnName, columnValue, displayColumnValue);
            }
        }
    },

    setColumnBothValues: function (columnName, columnValue, displayValue) {
        if (!columnValue || displayValue === undefined) {
            columnValue = "";
            displayValue = "";
        }
        var column = this.getColumnByName(columnName);
        if (!column || (!column.refSchemaName)) {
            return;
        }
        var row = this.activeRow;
        if (!row) {
            return;
        }
        row.setColumnValue(column.valueColumnName, columnValue);
        row.setColumnValue(column.displayColumnName, displayValue);
        if (!Ext.isEmpty(column.sourceSchemaUIdColumnValueName)) {
            delete row.modifiedValues[column.sourceSchemaUIdColumnValueName];
        }
        this.fireEvent("datachanged", row, columnName);
    },

    canReadColumn: function (column) {
        return true;
    },

    canEditColumn: function (column) {
        return true;
    },

    loadStructure: function (cfg) {
        if (this.fireEvent('beforeloadstructure', this, cfg) !== false) {
            this.doLoadStructure(cfg);
        }
    },

    // private
    doLoadStructure: function (cfg) {
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalloadstructure', this, request.configure(cfg));
    },

    // private
    getStructureColumnsProfileData: function () {
        var profileData = new Array();
        for (var i = 0, l = this.structure.columns.length; i < l; i++) {
            var column = this.structure.columns[i];
            var columnData = {
                columnUId: column.uId,
                metaPath: column.metaPath,
                metaPathCaption: column.metaPathCaption,
                width: column.width,
                isAlwaysSelect: Ext.value(column.isAlwaysSelect, false),
                isVisible: Ext.value(column.isVisible, true),
                orderDirection: column.orderDirection,
                orderPosition: column.orderPosition,
                aggregationType: column.aggregationType,
                summaryAggregationType: column.summaryAggregationType,
                name: column.name,
                caption: column.caption,
                subFilters: column.subFilters
            };
            profileData.push(columnData);
        }
        return profileData;
    },

    setColumnsProfileData: function () {
        if (!this.hasStructure()) {
            return;
        }
        this.setProfileData('structure', Ext.encode(this.getStructureColumnsProfileData()));
    },

    // private
    getStructureQuickColumnsProfileData: function () {
        var profileData = new Array();
        for (var i = 0, l = this.structure.quickViewColumns.length; i < l; i++) {
            var column = this.structure.quickViewColumns[i];
            var columnData = {
                columnUId: column.uId,
                metaPath: column.metaPath
            };
            profileData.push(columnData);
        }
        return profileData;
    },

    setQuickViewColumnsProfileData: function () {
        if (!this.hasStructure() || !this.structure.quickViewColumns) {
            return;
        }
        this.setProfileData('quickviewcolumns', Ext.encode(this.getStructureQuickColumnsProfileData()));
    },

    // private
    onLoadStructureResponse: function (structure, requestId) {
        if (this.hasStructure()) {
            // TODO Отписаться от события в деструкторе
            this.structure.filters.un("internaladd", this.onInternalFilterItemAdd, this);
            this.structure.filters.un("internalremove", this.onInternalFilterItemRemove, this);
            this.structure.filters.un("internalcleargroup", this.onInternalFilterGroupClear, this);
            this.structure.filters.un("internalmove", this.onInternalMoveFilterItem, this);
            this.structure.filters.un("internalgroupfilters", this.onInternalGroupFilterItems, this);
            this.structure.filters.un("internalungroup", this.onInternalUngroup, this);
            this.structure.filters.un("internalupdatefilter", this.onInternalUpdateFilter, this);
            this.structure.filters.un("internalupdatefiltersgroup", this.onInternalUpdateFiltersGroup, this);
        }
        this.structure = structure;
        this.setColumnsProfileData();
        this.structure.filters.on("internaladd", this.onInternalFilterItemAdd, this);
        this.structure.filters.on("internalremove", this.onInternalFilterItemRemove, this);
        this.structure.filters.on("internalcleargroup", this.onInternalFilterGroupClear, this);
        this.structure.filters.on("internalmove", this.onInternalMoveFilterItem, this);
        this.structure.filters.on("internalgroupfilters", this.onInternalGroupFilterItems, this);
        this.structure.filters.on("internalungroup", this.onInternalUngroup, this);
        this.structure.filters.on("internalupdatefilter", this.onInternalUpdateFilter, this);
        this.structure.filters.on("internalupdatefiltersgroup", this.onInternalUpdateFiltersGroup, this);
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('structureloaded', this, cfg);
        this.fireEvent('onstructureloadedcomplete', this, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    applyStructure: function (structure) {
        if (Ext.isArray(structure)) {
            for (var i = 0, l = structure.length; i < l; i++) {
                this.applyStructure(structure[i]);
            }
            return;
        }
        for (var p in structure) {
            var column = this.getColumnByName(p);
            if (column == null) {
                continue;
            };
            Ext.apply(column, structure[p]);
        }
    },

    moveStructureColumn: function (columnUId, position, refreshData, cfg) {
        if (Ext.isEmpty(columnUId) || !this.hasStructure()) {
            return;
        }
        cfg = cfg || {};
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalmovestructurecolumn', this, Ext.encode(columnUId), Ext.encode(position), Ext.encode(refreshData), request.configure(cfg));
    },

    // private
    onMoveStructureColumnResponse: function (columnUId, position, requestId) {
        if (this.hasStructure()) {
            var cfg = this.getRequestConfig(requestId);
            this.fireEvent("columnmoved", columnUId, position, cfg);
        }
    },

    removeStructureColumns: function (columnUIDs, cfg) {
        if (Ext.isEmpty(columnUIDs) || !this.hasStructure()) {
            return;
        }
        if (!Ext.isArray(columnUIDs)) {
            columnUIDs = [columnUIDs];
        }
        cfg = cfg || {};
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalremovestructurecolumns', this, Ext.encode(columnUIDs), request.configure(cfg));
    },

    // private
    onRemoveStructureColumnsResponse: function (removedColumns, requestId) {
        if (this.hasStructure()) {
            for (var i = 0, l = removedColumns.length; i < l; i++) {
                for (var j = 0, l1 = this.structure.columns.length; j < l1; j++) {
                    if (removedColumns[i] == this.structure.columns[j].name) {
                        this.structure.columns.splice(j, 1);
                        break;
                    }
                }
            }
            var cfg = this.getRequestConfig(requestId);
            this.fireEvent("columnsremoved", removedColumns, cfg);
        }
    },

    // private
    onInternalFilterItemAdd: function (parentUId, serializedItem, refreshData) {
        this.fireEvent("internaladdfilteritem", parentUId, Ext.encode(serializedItem), refreshData);
    },

    // private
    onInternalFilterItemRemove: function (itemUId, refreshData) {
        this.fireEvent("internalremovefilteritem", itemUId, refreshData);
    },

    // private
    onInternalFilterGroupClear: function (groupUId, refreshData) {
        this.fireEvent("internalclearfiltergroup", groupUId, refreshData);
    },

    // private
    onInternalMoveFilterItem: function (itemUId, targetUId, position) {
        this.fireEvent("internalmovefilteritem", itemUId, targetUId, position);
    },

    // private
    onInternalGroupFilterItems: function (parentUId, filterUIds) {
        this.fireEvent("internalgroupfilteritems", parentUId, filterUIds);
    },

    // private
    onInternalUngroup: function (uId) {
        this.fireEvent("internalungroup", uId);
    },

    // private
    onInternalUpdateFilter: function (filter, refreshData) {
        this.fireEvent("internalupdatefilter", Ext.encode(filter), refreshData);
    },

    // private
    onInternalUpdateFiltersGroup: function (filtersGroup, refreshData) {
        this.fireEvent("internalupdatefiltersgroup", Ext.encode(filtersGroup), refreshData);
    },

    updateStructure: function (cfg, refreshData) {
        if (this.fireEvent('beforeupdatestructure', this, cfg) !== false) {
            this.doUpdateStructure(cfg, refreshData);
        }
    },

    // private
    doUpdateStructure: function (cfg, refreshData) {
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        refreshData = (refreshData == undefined) ? "" : Ext.encode(refreshData);
        this.fireEvent('internalupdatestructure', this, refreshData, request.configure(cfg));
    },

    // private
    onUpdateStructureResponse: function (structure, requestId) {
        this.applyStructure(structure);
        this.setColumnsProfileData();
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('structureupdated', this, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    onUpdateQuickViewColumnsResponse: function (quickViewColumns) {
        this.structure.quickViewColumns = quickViewColumns;
        this.setQuickViewColumnsProfileData();
        this.fireEvent('quickviewcolumnsupdated', this);
    },

    // private
    processRows: function (dataArray, cfg) {
        var add = cfg ? cfg.add : false;
        if (add !== true) {
            this.activeRow = null;
            this.rows.clear();
        }
        if (dataArray) {
            this.decodeRows(dataArray);
            if (this.isPageable()) {
                this.applyPagingSettings(dataArray, cfg);
            }
            Ext.each(dataArray, function (el, i, all) {
                if (el) {
                    this.addRow(el[this.getPrimaryColumnName()], el);
                }
            }, this);
        }
    },

    //private
    decodeRow: function (row) {
        var structureColumnsLength = this.structure.columns.length;
        var structureColumns = this.structure.columns;
        for (var i = 0; i < structureColumnsLength; i++) {
            var structureColumn = structureColumns[i];
            var columnName =
				structureColumn.isLookup == true ? structureColumn.displayColumnName : structureColumn.name;
            var value = row[columnName];
            value = this.decodeColumnValue(value, structureColumn);
            row[columnName] = value;
        }
    },

    //private
    decodeRows: function (rows) {
        for (var rowIndex = 0, rowsLength = rows.length; rowIndex < rowsLength; rowIndex++) {
            var row = rows[rowIndex];
            this.decodeRow(row);
        }
    },

    //private
    decodeColumnValue: function (value, column) {
        var structureColumn = typeof column === 'string' ? this.getColumnByName(column) : column;
        if (!structureColumn) {
            return value;
        }
        if (value !== undefined && structureColumn.dataValueType.useClientEncoding == true) {
            return Ext.util.Format.htmlDecode(value);
        }
        return value;
    },

    //private
    applyPagingSettings: function (dataArray, cfg) {
        var parentColumnName = this.structure.hierarchicalColumnName;
        if (parentColumnName) {
            cfg.hasNextPage = this.getTreePagingConfig(dataArray);
        } else {
            cfg.hasNextPage = false;
            if (dataArray.length > this.pageRowsCount) {
                dataArray.pop();
                cfg.hasNextPage = true;
            }
        }
    },

    isPageable: function () {
        return this.pageRowsCount > -1;
    },

    isDynamicDataLoading: function () {
        return this.hierarchicalDepth != -1;
    },

    getTreePagingConfig: function (dataArray) {
        var pagingConfig = {};
        if (dataArray.length) {
            var recordsCounter = {};
            var deletedRecordIds = {};
            var structure = this.structure;
            var pageRowsCount = this.pageRowsCount;
            var parentColumnName = this.getColumnByName(structure.hierarchicalColumnName).valueColumnName;
            var primaryColumnName = this.getColumnByName(structure.primaryColumnName).valueColumnName;
            for (var i = 0, dataLength = dataArray.length; i < dataLength; i++) {
                var record = dataArray[i];
                var parentColumnValue = record[parentColumnName];
                if (recordsCounter[parentColumnValue]) {
                    recordsCounter[parentColumnValue]++;
                } else {
                    recordsCounter[parentColumnValue] = 1;
                }
                if ((recordsCounter[parentColumnValue] > pageRowsCount) || (deletedRecordIds[parentColumnValue])) {
                    var primaryColumnValue = record[primaryColumnName];
                    deletedRecordIds[primaryColumnValue] = true;
                    delete dataArray[i];
                }
            }
            for (var parent in recordsCounter) {
                if (recordsCounter[parent] > pageRowsCount) {
                    pagingConfig[parent] = true;
                }
            }
        }
        return pagingConfig;
    },

    load: function (cfg) {
        if (this.fireEvent('beforeload', this, cfg) !== false) {
            this.doLoad(cfg);
        }
    },

    // private
    doLoad: function (cfg) {
        cfg = cfg || {};
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalload', this, request.configure(cfg));
    },

    // private
    onLoadResponse: function (rows, requestId) {
        var cfg = this.getRequestConfig(requestId) || {};
        this.processRows(rows, cfg);
        if (this.rows.length == 0) {
            this.setActiveRow(null);
        }
        if (this._activeRowPrimaryColumnValue) {
            this.setActiveRow(this._activeRowPrimaryColumnValue);
        }
        this.fireEvent('loaded', this, rows, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    onLoadFailure: function (error, requestId) {
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('loadexception', this, error, cfg);
        this.removeRequestConfig(requestId);
    },

    loadRow: function (cfg) {
        var rowId = cfg.primaryColumnValue;
        if (this.fireEvent('beforeloadrow', this, cfg) !== false) {
            this.doLoadRow(cfg);
        }
    },

    // private
    doLoadRow: function (cfg) {
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalloadrow', this, request.configure(cfg));
    },

    // private
    onLoadRowResponse: function (rows, requestId) {
        if (rows) {
            this.decodeRows(rows);
            var primaryColumnName = this.getPrimaryColumnName();
            var row = rows[0];
            this.addRow(row[primaryColumnName], row);
            this.getRow(row[primaryColumnName]).clearState();
        }
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('rowloaded', this, rows, cfg);
        this.removeRequestConfig(requestId);
    },

    refreshPage: function (cfg) {
        cfg = this.getLoadPageCfg(cfg, 'Current');
        return this.load(cfg);
    },

    loadSummary: function (cfg) {
        if (this.fireEvent('beforeloadsummary', this, cfg) !== false) {
            this.doLoadSummary(cfg);
        }
    },

    // private
    doLoadSummary: function (cfg) {
        cfg = cfg || {};
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalloadsummary', this, request.configure(cfg));
    },

    // private
    onLoadSummaryResponse: function (data, requestId) {
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('summaryloaded', this, data, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    getLoadPageCfg: function (cfg, direction) {
        cfg.pageableDirection = direction;
        cfg.add = cfg.add ? cfg.add : !Ext.isEmpty(cfg.parentColumnValue);
        return cfg;
    },

    loadFirstPage: function (cfg) {
        cfg = this.getLoadPageCfg(cfg, 'First');
        this.load(cfg);
    },

    loadNextPage: function (cfg) {
        cfg = this.getLoadPageCfg(cfg, 'Next');
        this.load(cfg);
    },

    loadPreviousPage: function (cfg) {
        cfg = this.getLoadPageCfg(cfg, 'Prior');
        this.load(cfg);
    },

    // private
    addRow: function (key, columns) {
        if (Ext.isEmpty(key)) {
            return null;
        }
        var row = this.createRow(columns);
        if (this.activeRow && this.activeRow.getPrimaryColumnValue() == row.getPrimaryColumnValue()) {
            this.activeRow = row;
        }
        return this.rows.add(key, row);
    },

    // private
    removeRow: function (key, clearActiveRow) {
        var rows = this.rows, func;
        if (typeof key == "string") {
            func = rows.removeKey;
        } else if (typeof key == "number") {
            func = rows.removeAt;
        } else if (key instanceof Terrasoft.Row) {
            func = rows.remove;
        }
        if (this.activeRow && clearActiveRow !== false) {
            var row = this.getRow(key);
            if (row == this.activeRow) {
                this.setActiveRow(null);
            }
        }
        this.removeChildRows(key);
        return func.call(rows, key);
    },

    // private
    onRemoveException: function (requestId) {
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('removeexception', this, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    getTreeRows: function () {
        var rows = this.rows, treeRows = rows.clone(true), row, parentRow;
        for (var i = 0, l = treeRows.getCount() ; i < l; i++) {
            row = treeRows.itemAt(i);
            parentColumnValue = row.getParentColumnValue();
            if (!Ext.isEmpty(parentColumnValue)) {
                parentRow = treeRows.get(parentColumnValue);
                if (parentRow) {
                    if (!parentRow.childRows) {
                        parentRow.childRows = new Ext.util.MixedCollection(false, function (row) {
                            return row.getPrimaryColumnValue();
                        });
                    }
                    parentRow.childRows.add(row);
                    row.processed = true;
                }
            }
        }
        treeRows.each(function (item) {
            if (item.processed) {
                this.remove(item);
            }
        }, treeRows);
        return treeRows;
    },

    // private
    findRowRecurse: function (treeRows, primaryColumnValue) {
        var row = treeRows.get(primaryColumnValue), childRows;
        if (row) {
            return row;
        }
        for (var i = 0, l = treeRows.getCount() ; i < l; i++) {
            childRows = treeRows.get(i).childRows;
            if (childRows) {
                row = this.findRowRecurse(childRows, primaryColumnValue);
                if (row) {
                    return row;
                }
            }
        }
        return null;
    },

    // private
    getInsertIndex: function (targetRow, position) {
        if (!targetRow) {
            return this.rows.getCount() + 1;
        }
        var insertIndex = targetRow.index();
        switch (position) {
            case "Append":
                insertIndex = findParentRowLastRowIndex.call(this);
                insertIndex++;
                break;
            case "Above":
                //insertIndex--;
                break;
            case "Below":
                insertIndex++;
                break;
        }
        return insertIndex;
        // private
        function findParentRowLastRowIndex() {
            var childRows = this.getChildRows(targetRow.getPrimaryColumnValue());
            var lastRow = childRows[childRows.length - 1];
            return lastRow ? lastRow.index() : 0;
        }
    },

    // private
    move: function (primaryColumnValue, targetRowPrimaryColumnValue, movePosition) {
        if (this.fireEvent("beforerowmove", primaryColumnValue, targetRowPrimaryColumnValue, movePosition) === false) {
            return;
        }
        var row = this.getRow(primaryColumnValue);
        if (!row) {
            return;
        }
        this.rows.removeKey(primaryColumnValue);
        var targetRow = this.getRow(targetRowPrimaryColumnValue),
			hierarchicalColumnName = row.getHierarchicalColumnName(),
			newRowIndex = this.getInsertIndex(targetRow, movePosition);
        switch (movePosition) {
            case "Append":
                row.columns[hierarchicalColumnName] = targetRowPrimaryColumnValue;
                break;
            case "Above":
                row.columns[hierarchicalColumnName] = targetRow.columns[hierarchicalColumnName];
                break;
            case "Below":
                row.columns[hierarchicalColumnName] = targetRow.columns[hierarchicalColumnName];
                break;
        }
        this.rows.insert(newRowIndex < 0 ? 0 : newRowIndex, primaryColumnValue, row);
        this.fireEvent("rowmoved", primaryColumnValue, targetRowPrimaryColumnValue, movePosition);
    },

    // todo оптимизировать реализацию - устранить повторное создание treeRows
    removeChildRows: function (source) {
        var treeRows = this.getTreeRows();
        if (source == null) {
            var primaryColumnValue;
            var cfg = {
                primaryColumnValue: null
            };
            for (var i = 0, l = treeRows.getCount() ; i < l; i++) {
                primaryColumnValue = cfg.primaryColumnValue = treeRows.itemAt(i).getPrimaryColumnValue();
                this.removeRow(primaryColumnValue);
                var request = new Terrasoft.DataSourceRequest(this);
                this.fireEvent('removed', this, request.configure(cfg));
            }
            return;
        }
        if (!treeRows || !source) {
            return null;
        }
        var parentRow = this.findRowRecurse(treeRows, source);
        if (!parentRow) {
            return;
        }
        this.doRemoveChildRows(parentRow);
    },

    // private
    doRemoveChildRows: function (parentRow) {
        if (!parentRow.childRows) {
            return;
        }
        var row;
        for (var i = 0, l = parentRow.childRows.length; i < l; i++) {
            row = parentRow.childRows.get(i);
            if (row.childRows) {
                this.doRemoveChildRows(row);
            }
            this.rows.removeKey(row.getPrimaryColumnValue());
            var cfg = {
                primaryColumnValue: row.getPrimaryColumnValue()
            };
            var request = new Terrasoft.DataSourceRequest(this);
            this.fireEvent('removed', this, request.configure(cfg));
        }
    },

    remove: function (cfg) {
        if (this.fireEvent('beforeremove', this, cfg) !== false) {
            return this.doRemove(cfg);
        }
    },

    // private
    doRemove: function (cfg) {
        var request = new Terrasoft.DataSourceRequest(this);
        this.regRequestConfig(cfg);
        if (cfg.primaryColumnValue) {
            var row = this.getRow(cfg.primaryColumnValue);
            var rowState = row.getState();
            if (rowState == Terrasoft.Row.NEW) {
                this.onRemoveResponse(cfg.primaryColumnValue);
                return;
            }
        }
        this.fireEvent('internalremove', this, request.configure(cfg));
    },

    getRelativeRowPrimaryColumnValue: function (targetRowPrimaryColumnValue) {
        if (!targetRowPrimaryColumnValue) {
            return;
        }
        var row = this.getRow(targetRowPrimaryColumnValue);
        if (!row) {
            return;
        }
        var position = "Below";
        var rowIndex = row.index();
        var parentColumnValue = row.getParentColumnValue();
        var isInhierarchicalTree = !Ext.isEmpty(parentColumnValue);
        if (isInhierarchicalTree) {
            var childRows = this.getChildRows(parentColumnValue);
            var positionInTree = -1;
            Ext.each(childRows, function (childRow, i) {
                if (childRow.getColumnValue(childRow.getPrimaryColumnName()) == targetRowPrimaryColumnValue) {
                    positionInTree = i;
                }
            }, this);
            if (positionInTree == childRows.length - 1) position = "Above";
        } else {
            if (rowIndex == this.rows.length - 1) position = "Above";
        }
        switch (position) {
            case "Above":
                if (!isInhierarchicalTree) {
                    return this.rows.keys[--rowIndex];
                } else {
                    if (positionInTree == 0) {
                        return parentColumnValue;
                    } else if (positionInTree > 0) {
                        return childRows[--positionInTree].getPrimaryColumnValue();
                    }
                }
                break;
            case "Below":
                if (!isInhierarchicalTree) {
                    if (rowIndex < (this.rows.length - 1)) {
                        return this.rows.keys[++rowIndex];
                    }
                } else {
                    if (positionInTree < (childRows.length - 1)) {
                        return childRows[++positionInTree].getPrimaryColumnValue();
                    }
                }
                break;
        }
        return;

        function indexOf(array, serchElemnt) {
            if (!array.length || array.length == 0) {
                return -1;
            }
            for (var i = 0; i < array.length; i++) {
                if (array[i] == serchElemnt) {
                    return i;
                }
            }
            return -1;
        }
    },

    // private
    onRemoveResponse: function (primaryColumnValue, requestId) {
        var cfg = this.getRequestConfig(requestId) || {};
        cfg.primaryColumnValue = primaryColumnValue;
        var targetRowPrimaryColumnValue = primaryColumnValue || cfg.primaryColumnValue;
        if (targetRowPrimaryColumnValue == null) {
            this.removeChildRows(targetRowPrimaryColumnValue);
            return;
        }
        var previousRowPrimaryColumnValue = this.getRelativeRowPrimaryColumnValue(targetRowPrimaryColumnValue);
        var clearActiveRow = previousRowPrimaryColumnValue == null;
        if (!this.removeRow(targetRowPrimaryColumnValue, clearActiveRow)) {
            return;
        };
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('removed', this, request.configure(cfg));
        this.removeRequestConfig(requestId);
        if (previousRowPrimaryColumnValue) {
            this.setSelection([previousRowPrimaryColumnValue]);
            this.setActiveRow(previousRowPrimaryColumnValue);
        }
    },

    localRemove: function (primaryColumnValue) {
        this.onRemoveResponse(primaryColumnValue);
    },

    insert: function (cfg) {
        if (this.fireEvent('beforeinsert', this, cfg) !== false) {
            this.doInsert(cfg);
        }
    },

    // private
    doInsert: function (cfg) {
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalinsert', this, request.configure(cfg));
    },

    // private
    onInsertResponse: function (newRow, requestId, targetRowPrimaryColumnValue, insertPosition, silentMode) {
        if (!newRow) {
            return null;
        }
        this.decodeRow(newRow);
        var row = this.createRow(newRow);
        row.state = Terrasoft.Row.NEW;
        row.dirty = true;
        row.modifiedValues = Ext.apply(row.modifiedValues || {}, row.columns);
        var structureColumns = this.structure.columns;
        for (var i = 0, l = structureColumns.length; i < l; i++) {
            if (structureColumns[i].isLookup) {
                if (!Ext.isEmpty(structureColumns[i].sourceSchemaUIdColumnValueName)) {
                    delete row.modifiedValues[structureColumns[i].sourceSchemaUIdColumnValueName];
                }
            }
        }
        var targetRow = this.getRow(targetRowPrimaryColumnValue),
			insertIndex = this.getInsertIndex(targetRow, insertPosition);
        this.rows.insert(insertIndex < 0 ? 0 : insertIndex, row.getPrimaryColumnValue(), row);
        var cfg = this.getRequestConfig(requestId) || {};
        if (targetRowPrimaryColumnValue) {
            cfg.targetRowPrimaryColumnValue = targetRowPrimaryColumnValue;
            cfg.insertPosition = insertPosition;
        }
        this.fireEvent('inserted', this, row, cfg);
        this.setActiveRow(row);
        this.removeRequestConfig(requestId);
    },

    save: function (cfg) {
        if (this.fireEvent('beforesave', this, cfg) !== false) {
            return this.doSave(cfg);
        }
    },

    // private
    doSave: function (cfg) {
        var request = new Terrasoft.DataSourceRequest(this);
        var row = this.activeRow;
        var primaryColumnValue = row.getPrimaryColumnValue();
        var changes = this.getChanges(row);
        if (!changes) {
            return null;
        }
        changes[row.getPrimaryColumnName()] = row.getPrimaryColumnValue();
        var cfg = {
            primaryColumnValue: primaryColumnValue,
            values: changes
        }
        this.regRequestConfig(cfg);
        this.fireEvent('internalsave', this, request.configure(cfg));
    },

    // private
    onSaveResponse: function (updatedRow, requestId) {
        var cfg = this.getRequestConfig(requestId);
        var row = !cfg ? this.activeRow : this.getRow(cfg.primaryColumnValue);
        if (!row || !row.dirty) {
            return;
        }
        row.clearState();
        this.updateActiveRowHiddenField(row);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('saved', this, row, request.configure(cfg || {}));
        this.removeRequestConfig(requestId);
    },

    // private
    onSaveException: function (requestId) {
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('saveexception', this, cfg);
        this.removeRequestConfig(requestId);
    },

    cancel: function (cfg) {
        if (this.fireEvent('beforecancel', this, cfg) !== false) {
            this.doCancel(cfg);
        }
    },

    // private
    doCancel: function (cfg) {
        var row = this.activeRow;
        if (!row) {
            return;
        }
        row.cancel(cfg);
    },

    // TODO
    onControlDataChanged: function (columnName, oldColumnValue, columnValue, opt) {
        if (opt && opt.isLookup) {
            this.setColumnBothValues(columnName, columnValue, opt.displayValue);
            return;
        }
        this.setColumnValue.call(this, columnName, columnValue);
    },

    loadQuickView: function (cfg) {
        if (this.fireEvent('beforeloadquickview', this, cfg) !== false) {
            this.doLoadQuickView(cfg);
        }
    },

    // private
    doLoadQuickView: function (cfg) {
        if (Ext.isEmpty(cfg)) {
            return;
        }
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalloadquickview', this, request.configure(cfg));
    },

    // private
    onLoadQuickViewResponse: function (data, requestId) {
        var cfg = this.getRequestConfig(requestId);
        this.fireEvent('quickviewload', this, data, cfg);
        this.removeRequestConfig(requestId);
    },

    onDestroy: function () {
        if (this.rendered) {
            Ext.destroy(this.activeRowModifiedHiddenField, this.activeRowPrimaryColumnValueHiddenField,
				this.selectedItemPrimaryColumnValuesHiddenField, this.activeRowHiddenField);
        }
    }

});

Ext.reg('datasource', Terrasoft.DataSource);

Terrasoft.VirtualDataSource = function (cfg) {
    Terrasoft.VirtualDataSource.superclass.constructor.call(this, cfg);
};

Ext.extend(Terrasoft.VirtualDataSource, Terrasoft.DataSource, {

    applyPagingSettings: function (dataArray, cfg) {
        cfg.hasNextPage = false;
    },

    //private
    sort: function (sortingColumns) {
        var sortFn = function (r1, r2) {
            var result;
            for (var i = 0; !result && i < sortingColumns.length; i++) {
                var v1 = r1.columns[sortingColumns[i].name];
                var v2 = r2.columns[sortingColumns[i].name];
                result = (v1 > v2) ? 1 : ((v1 < v2) ? -1 : 0);
                if (sortingColumns[i].orderDirection == 'Descending') {
                    result = -result;
                }
            }
            return result;
        };
        this.rows.sort('ASC', sortFn);
    },

    // private
    doLoad: function (cfg) {
        if (!Ext.isEmpty(cfg.filteredColumnName) && !Ext.isEmpty(cfg.filterValue)) {
            var row = this.getRow(cfg.filterValue);
            cfg.row = row.columns;
        }
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.fireEvent('internalload', this, request.configure(cfg));
    },

    // private
    onLoadResponse: function (newRows, requestId) {
        var cfg = this.getRequestConfig(requestId) || {};
        if ((cfg.parentColumnValue || Ext.isEmpty(requestId))) {
            cfg.add = true;
        }
        var primaryColumnName = this.getPrimaryColumnName();
        if (cfg && cfg.add === false) {
            this.rows.clear();
        }
        var onlyNewRows = [];
        for (var i = 0, len = newRows.length; i < len; i++) {
            if (!this.getRow(newRows[i][primaryColumnName])) {
                onlyNewRows.push(newRows[i]);
            }
        }
        this.processRows(onlyNewRows, cfg);
        var sortingColumns = this.getSortingColumns();
        if (sortingColumns.length > 0) {
            this.sort(sortingColumns);
            var newRowsCollection = new Ext.util.MixedCollection(false, function (row) {
                return row[primaryColumnName];
            });
            newRowsCollection.addAll(onlyNewRows);
            cfg.positions = {};
            var sortedRowsArray = [], dataSourceItems = this.rows.items, newRow;
            for (var i = 0, itemsLen = dataSourceItems.length; i < itemsLen; i++) {
                primaryColumnValue = dataSourceItems[i].getPrimaryColumnValue();
                newRow = newRowsCollection.get(primaryColumnValue);
                if (newRow && primaryColumnValue == newRow[primaryColumnName]) {
                    sortedRowsArray.push(newRow);
                    cfg.positions[primaryColumnValue] = this.createRowPositionConfig(dataSourceItems[i]);
                }
            }
        }
        this.fireEvent('loaded', this, sortedRowsArray || onlyNewRows, cfg);
        this.removeRequestConfig(requestId);
    },

    // private
    doUpdateStructure: function (cfg, refreshData) {
        this.regRequestConfig(cfg);
        var request = new Terrasoft.DataSourceRequest(this);
        this.onUpdateStructureResponse(cfg.columns, cfg.id);
        if (refreshData) {
            var records = new Array();
            var rows = this.rows.items;
            for (var i = 0; i < rows.length; i++) {
                records.push(rows[i].columns);
            }
            this.rows.clear();
            this.onLoadResponse(records);
        }
    },

    // private
    createRowPositionConfig: function (row) {
        var rowIndex = row.index(), targetRowPrimaryColumnValue, position;
        var previousRow = this.rows.itemAt(rowIndex - 1), cfg = {};
        var rowParentColumnValue = row.getParentColumnValue();
        if (rowIndex == 0 || rowParentColumnValue != previousRow.getParentColumnValue()) {
            cfg.targetRowPrimaryColumnValue = rowParentColumnValue;
            cfg.position = "Append";
        } else {
            cfg.targetRowPrimaryColumnValue = previousRow.getPrimaryColumnValue();
            cfg.position = "Below";
        }
        return cfg;
    },

    getSortingColumns: function () {
        var structure = this.structure.columns;
        var sortingColumns = [];
        for (var i = 0, l = structure.length; i < l; i++) {
            if (structure[i].orderDirection != "None") {
                var column = {
                    name: structure[i].displayColumnName || structure[i].name,
                    orderPosition: structure[i].orderPosition,
                    orderDirection: structure[i].orderDirection
                };
                sortingColumns.push(column);
            }
        }
        var sortFunction = function (a, b) {
            return (a.orderPosition - b.orderPosition);
        };
        sortingColumns.sort(sortFunction);
        return sortingColumns;
    },

    // private
    updateRow: function (updatedRow) {
        if (!updatedRow) {
            return;
        }
        var row = this.getRow(updatedRow[this.getPrimaryColumnName()]);
        for (var сolumnName in updatedRow) {
            row.columns[сolumnName] = updatedRow[сolumnName];
        }
        this.fireEvent('rowloaded', this, [row.columns]);
    }

});

Ext.reg('virtualdatasource', Terrasoft.VirtualDataSource);

Terrasoft.EntityDataSourceMgr = function () {
    var dataSources = new Ext.util.MixedCollection();
    return {
        register: function (dataSourceId) {
            dataSources.add(dataSourceId);
        },

        unregister: function (dataSourceId) {
            dataSources.remove(dataSourceId);
        },

        getDataSourceCacheItemNames: function () {
            var cacheItemNames = [];
            Ext.each(dataSources.items, function (dataSource) {
                if (window[dataSource].cacheItemName) {
                    cacheItemNames.push(window[dataSource].cacheItemName);
                }
            }, this);
            return cacheItemNames;
        }
    };
}();

Terrasoft.EntityDataSource = function (cfg) {
    Terrasoft.EntityDataSourceMgr.register(cfg.id);
    Terrasoft.EntityDataSource.superclass.constructor.call(this, cfg);
    this.structure.columns = [];
};

Ext.extend(Terrasoft.EntityDataSource, Terrasoft.DataSource, {

    canReadColumn: function (column) {
        return this.canEditColumn(column) || column.columnRightLevel == Terrasoft.ColumnRightLevel.CAN_READ;
    },

    canEditColumn: function (column) {
        var rightLevel = column.columnRightLevel;
        return rightLevel == undefined || rightLevel == Terrasoft.ColumnRightLevel.CAN_EDIT;
    },

    onDestroy: function () {
        Terrasoft.EntityDataSource.superclass.onDestroy.call(this);
        Terrasoft.EntityDataSourceMgr.unregister(this.id);
    }

});

Ext.reg('entitydatasource', Terrasoft.EntityDataSource);

if (typeof Sys !== "undefined") {
    Sys.Application.notifyScriptLoaded();
}