Terrasoft.FilterEdit = Ext.extend(Ext.Panel, {
	customFilterEnable: false,
	toolbarVisible: true,
	aggregationEnable: true,
	width: 300,
	height: 150,
	filterGroupName: "FilterEdit",
	useDefaultLayout: false,
	toolsAutoEl: { tag: 'span', cls: 'x-form-tools' },
	loadingCls: 'loading',
	elements: 'header,body',
	headerAsText: false,
	ownToolsConfig: [
		{
			xtype: 'button',
			autoWidth: true,
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.UI.WebControls',
				resourceItemName: 'filteredit-group-filters-btn.png'
			},
			tag: 'group',
			isOwnTool: true,
			enabled: false
		},
		{
			xtype: 'button',
			autoWidth: true,
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.UI.WebControls',
				resourceItemName: 'filteredit-ungroup-filters-btn.png'
			},
			tag: 'ungroup',
			isOwnTool: true,
			enabled: false
		},
		{
			xtype: 'button',
			autoWidth: true,
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.UI.WebControls',
				resourceItemName: 'filteredit-up-filter-btn.png'
			},
			isOwnTool: true,
			tag: 'moveUp'
		},
		{
			xtype: 'button',
			autoWidth: true,
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.UI.WebControls',
				resourceItemName: 'filteredit-down-filter-btn.png'
			},
			isOwnTool: true,
			tag: 'moveDown'
		}
	],

	initComponent: function() {
		if (this.toolbarVisible) {
			this.initToolbar();
		}
		Terrasoft.FilterEdit.superclass.initComponent.call(this);
		this.selectionModel = new Terrasoft.FilterEdit.SelectionModel();
		this.selectionModel.on("selectionchange", this.onSelectionChange, this);
		this.initDataSourceEvents();
		this.addEvents(
			"editfilter",
			"beforeeditfilter",
			"editrightexpressioncolumn",
			"editrightexpressioncustomfilter"
		);
	},

	initDesignedTools: function(tools) {
		var toolsConfig = this.toolsConfig || [];
		if (!Ext.isArray(toolsConfig)) {
			toolsConfig = [toolsConfig];
		}
		var toolsConfigLength = toolsConfig.length;
		if (toolsConfigLength != 0) {
			tools.push({
				xtype: 'spacer',
				stripeVisible: true
			});
		}
		for (var i = 0; i < toolsConfigLength; i++) {
			var tool = toolsConfig[i];
			if (tool.xtype == 'toolbutton') {
				tool.xtype = 'button';
			}
			tools.push(toolsConfig[i]);
		}
		return tools;
	},

	initTools: function() {
		var tools = [];
		var ownToolsConfig = this.ownToolsConfig;
		var ownToolsConfigLength = ownToolsConfig.length;
		for (var i = 0; i < ownToolsConfigLength; i++) {
			tools.push(ownToolsConfig[i]);
		}
		return tools;
	},

	findToolItemByTag: function(tag) {
		if (!this.toolbarVisible) {
			return null;
		}
		var toolBarItems = this.toolBar.items;
		for(var i = 0, itemsLength = toolBarItems.length; i < itemsLength; i++) {
			var item = toolBarItems.itemAt(i);
			if (item.tag == tag) {
				return item;
			}
		}
		return null;
	},

	initToolbar: function() {
		var tools = this.initTools();
		tools = this.initDesignedTools(tools);
		this.toolBar = new Terrasoft.ControlLayout({
			id: this.id + '_toolbar',
			designMode: this.designMode,
			owner: this,
			className: "x-filteredit-toolbar",
			edges: '0 0 1 0',
			items: tools,
			width: '100%',
			displayStyle: 'topbar'
		});
	},

	onToolbarContentChange: function() {
		this.toolBar.onContentChanged();
	},

	onToolClick: function(toolItem) {
		var toolItemTag = toolItem.tag;
		var selectedItems = this.selectionModel.selectedItems;
		if ((selectedItems.items.length < 1) && (toolItemTag != "addGroup")) {
			return;
		}
		switch (toolItemTag) {
			case "group":
				this.group(selectedItems);
				break;
			case "ungroup":
				var item = selectedItems.items[0];
				this.ungroup(item);
				break;
			case "moveUp":
				item = selectedItems.items[0];
				this.moveUp(item);
				break;
			case "moveDown":
				item = selectedItems.items[0];
				this.moveDown(item);
				break;
		}
	},

	initEvents: function() {
		Terrasoft.FilterEdit.superclass.initEvents.apply(this);
		if (this.toolbarVisible) {
			var toolBar = this.toolBar;
			toolBar.on('contentchanged', this.onToolbarContentChange, this);
			toolBar.on('add', this.onToolbarContentChange, this);
			toolBar.on('remove', this.onToolbarContentChange, this);
			var tools = toolBar.items;
			for (var i = 0, itemsLength = tools.length; i < itemsLength; i++) {
				var toolItem = tools.itemAt(i);
				if (toolItem.isOwnTool) {
					toolItem.on('click', this.onToolClick, this);
				}
			}
		}
	},

	initDataSourceEvents: function() {
		var dataSource = this.dataSource;
		if (!dataSource) {
			return;
		}
		dataSource.on("structureloaded", this.onDataSourceStructureLoaded, this);
	},

	render: function() {
		Terrasoft.FilterEdit.superclass.render.apply(this, arguments);
		this.renderToolbar();
		this.addFiltersBody();
		if (!this.designMode && this.dataSource.structure.filters) {
			this.initializeEvents();
			this.renderDesignedFilters();
		}
	},

	renderToolbar: function () {
		if (this.toolbarVisible) {
			var header = this.header;
			header.dom.className = '';
			header.addClass('x-filteredit-toolbar');
			this.toolBar.render(this.header);
		}
	},

	setEnabled: function(enabled) {
		Terrasoft.FilterEdit.superclass.setEnabled.apply(this, arguments);
		if (!this.toolbarVisible) {
			return;
		}
		var toolBar = this.toolBar;
		toolBar.setEnabled(enabled);
		var initializingTopToolbarButtonsEnabledStates = false;
		if(!this.topToolbarButtonsEnabledStates && !enabled) {
			initializingTopToolbarButtonsEnabledStates = true;
			this.topToolbarButtonsEnabledStates = [];
		}
		var tools = toolBar.items;
		var toolsLength = tools.length;
		var i;
		var toolItem;
		for(i = 0; i < toolsLength; i++) {
			toolItem = tools.itemAt(i);
			if (toolItem.getXType() == 'button') {
				var isOwnTool = toolItem.isOwnTool;
				var isItemEnabled = toolItem.enabled;
				var itemId = toolItem.id;
				if(!enabled && !isOwnTool && initializingTopToolbarButtonsEnabledStates) {
					this.topToolbarButtonsEnabledStates[itemId] = isItemEnabled;
				}
				var canEnableToolButton = isOwnTool || (!(!isOwnTool && enabled && !isItemEnabled));
				if(canEnableToolButton) {
					toolItem.setEnabled(enabled);
				}
			}
		}
		if(enabled) {
			if(this.topToolbarButtonsEnabledStates) {
				toolsLength = tools.length;
				for(i = 0; i < toolsLength; i++) {
					toolItem = tools.itemAt(i);
					if (toolItem.isOwnTool) {
						continue;
					}
					var isEnabled = this.topToolbarButtonsEnabledStates[toolItem.id];
					toolItem.setEnabled(isEnabled);
				}
				this.topToolbarButtonsEnabledStates = null;
			}
			if (this.filters) {
				this.actualizeToolbarButtons(this.filters.items);
			}
		}
	},

	getFiltersBody: function() {
		var el= this.getEl();
		if (el==undefined) {
			return null;
		}
		return el.child("div.x-filter-edit");
	},

	getPanelBody: function() {
		var el = this.getEl();
		return el.child("div.x-panel-body");
	},

	addFiltersBody: function() {
		var el = this.getPanelBody();
		this.initScrollBar(el.dom);
		this.on("resize", this.onResizeEl, this);
		var tag = document.createElement("div");
		tag.className = "x-filter-edit";
		this.scrollBar.contentWrap.appendChild(tag);
		var scrollWrapper = this.scrollBar.contentWrap.dom.parentNode.nextSibling;
		scrollWrapper.className += " filter-edit";
	},

	onResizeEl: function() {
		if (this.scrollBar) {
			this.scrollBar.update({useHScroll: false});
		}
	},

	onResize: function() {
		Terrasoft.FilterEdit.superclass.onResize.apply(this, arguments);
		this.onResizeEl();
		if (this.toolbarVisible) {
			var headerWidth = this.header.getWidth();
			this.toolBar.setWidth(headerWidth);
		}
	},

	initScrollBar: function(el) {
		this.scrollBar = Ext.ScrollBar.insertScrollBar(el);
	},

	showFilterEditWindow: function(parentGroup, filterUi, isAggregated) {
		if (this.fireEvent("beforeeditfilter", isAggregated) !== false) {
			var parentGroupUId = "";
			if (parentGroup) {
				parentGroupUId = parentGroup.filter.uId;
			}
			var filterUId = "";
			if (filterUi) {
				filterUId = filterUi.filter.uId;
			}
			isAggregated = (isAggregated == undefined) ? "" : Ext.encode(isAggregated);
			this.fireEvent("editfilter", parentGroupUId, filterUId, isAggregated);
		}
	},

	onDataSourceStructureLoaded: function() {
		if (!this.designMode) {
			if (!this.filters) {
				this.initializeEvents();
				this.renderDesignedFilters();
			} else {
				this.setDataSource(this.dataSource);
			}
		}
	},

	initializeEvents: function() {
		this.filters = this.dataSource.structure.filters;
		this.filters.on("added", this.onDataSourceAddFilter, this);
		this.filters.on("removed", this.onDataSourceRemoveFilter, this);
		this.filters.on("moved", this.onDataSourceMoveFilter, this);
		this.filters.on("inserted", this.onDataSourceInsertFilter, this);
		this.filters.on("updated", this.onDataSourceUpdateFilter, this);
	},

	setDataSource: function(dataSource) {
		if (this.filters) {
			var filterEditGroup = this.findDataSourceFilterEditGroup();
			this.onDataSourceRemoveFilter(filterEditGroup);
			this.filters = null;
		}
		this.dataSource = dataSource;
		this.initDataSourceEvents();
		if (this.dataSource.structure && this.dataSource.structure.filters) {
			this.onDataSourceStructureLoaded();
		}
	},

	//TODO: #134688 Obsolete: Используйте setDataSource()
	reinitialize: function(dataSource) {
		this.setDataSource(dataSource);
	},

	renderDesignedFilters: function() {
		var filterEditGroup = this.findDataSourceFilterEditGroup();
		if (filterEditGroup) {
			this.ui = this.getUiByDataSourceFilter(filterEditGroup);
			var container = this.getFiltersBody();
			if (container != null) {
				this.ui.render(container);
			}
			if (this.scrollBar) {
				this.scrollBar.update({useHScroll: false});
			}
		}
	},

	getUiByDataSourceFilter: function(filter, forceIsSubFilter) {
		var uiItem;
		if (this.itemIsFiltersGroup(filter)) {
			uiItem = new Terrasoft.FilterEdit.FiltersGroupUI({
				id: Ext.id(),
				filter: filter,
				filterEdit: this 
			});
			for (var i=0; i < filter.items.length; i++) {
				var child = this.getUiByDataSourceFilter(filter.items.items[i], forceIsSubFilter);
				uiItem.add(child);
			}
		} else {
			uiItem = new Terrasoft.FilterEdit.FilterItemUI({
				id: Ext.id(),
				filter: filter,
				filterEdit: this
			});
			if (filter.subFilters) {
				uiItem.subFilters = this.getUiByDataSourceFilter(filter.subFilters, true);
				uiItem.subFilters.isSubFilter = true;
			}
		}
		if (forceIsSubFilter === true) {
			uiItem.isSubFilter = true;
		}
		return uiItem;
	},

	correctDataSourceFilter: function(dataSourceFilter) {
		if (dataSourceFilter._isFilter === true) {
			if (dataSourceFilter.leftExpression && dataSourceFilter.leftExpression.dataValueType &&
				dataSourceFilter.leftExpression.dataValueType.name == 'MaxSizeText') {
				var newDataValueTypeEditorConfig = {
					controlTypeName : "TextEdit",
					controlXType : "textedit"
				};
				Ext.apply(dataSourceFilter.leftExpression.dataValueType.editor, newDataValueTypeEditorConfig);
			}
		}
	},

	checkFirstFilter: function(filters) {
		var filtersItems = filters.items;
		var isFirstItem = true;
		for (var i = 0, itemsLength = filtersItems.length; i < itemsLength; i++) {
			var item = filtersItems.itemAt(i);
			if (this.itemIsFiltersGroup(item)) {
				this.checkFirstFilter(item);
				isFirstItem = false;
			} else {
				var filterUI = this.findUiItemByDataSourceFilter(item);
				if (filterUI) {
					filterUI.setFirstFilter(isFirstItem);
					isFirstItem = false;
				}
			}
		}
	},

	onDataSourceAddFilter: function(dataSourceFilter) {
		if (!this.isNeedProcessingOnEvent(dataSourceFilter) || !this.rendered) {
			return;
		}
		this.correctDataSourceFilter(dataSourceFilter);
		var uiItem = this.getUiByDataSourceFilter(dataSourceFilter);
		var firstLevelGroup = dataSourceFilter.getFirstLevelGroup();
		if (dataSourceFilter == firstLevelGroup) {
			this.ui = uiItem;
			var container = this.getFiltersBody();
			if (container!=null) {
				this.ui.render(container);
			}
		} else {
			var parentFilter = this.findUiItemByDataSourceFilter(dataSourceFilter.parentGroup);
			if (parentFilter) {
				parentFilter.add(uiItem);
				if (this.rendered) {
					uiItem.render();
					this.scrollBar.update({useHScroll: false});
				}
			}
		}
		this.checkFirstFilter(this.findDataSourceFilterEditGroup());
	},

	onDataSourceRemoveFilter: function(dataSourceFilter) {
		if (!this.rendered || !this.isNeedProcessingOnEvent(dataSourceFilter)) {
			return;
		}
		var uiItem = this.findUiItemByDataSourceFilter(dataSourceFilter);
		if (!uiItem) {
			return;
		}
		uiItem.remove();
		this.checkFirstFilter(this.findDataSourceFilterEditGroup());
		this.scrollBar.update({
			useHScroll: false
		});
	},

	onDataSourceMoveFilter: function(filter) {
		if (!this.isNeedProcessingOnEvent(filter) || !this.rendered) {
			return;
		}
		this.correctDataSourceFilter(filter);
		var itemUi = this.findUiItemByDataSourceFilter(filter);
		var isSelected = this.selectionModel.isSelected(itemUi);
		itemUi.remove();
		var newParent = filter.parentGroup;
		var index = newParent.items.items.indexOf(filter);
		var newParentUi = this.findUiItemByDataSourceFilter(newParent);
		itemUi = this.getUiByDataSourceFilter(filter);
		newParentUi.insert(itemUi, index);
		itemUi.render();
		if (isSelected) {
			this.selectionModel.select(itemUi);
		}
		this.checkFirstFilter(this.findDataSourceFilterEditGroup());
		this.scrollBar.update({
			useHScroll: false
		});
	},
	
	onDataSourceInsertFilter: function(filter) {
		if (!this.isNeedProcessingOnEvent(filter) || !this.rendered) {
			return;
		}
		this.correctDataSourceFilter(filter);
		var filterUi = this.getUiByDataSourceFilter(filter);
		var parent = filter.parentGroup;
		var itemIndex = parent.items.indexOf(filter);
		var parentUi = this.findUiItemByDataSourceFilter(parent);
		parentUi.insert(filterUi, itemIndex);
		filterUi.render();
		this.checkFirstFilter(this.findDataSourceFilterEditGroup());
		this.scrollBar.update({
			useHScroll: false
		});
	},

	onDataSourceUpdateFilter: function(filter) {
		if (!this.isNeedProcessingOnEvent(filter) || !this.rendered) {
			return;
		}
		this.correctDataSourceFilter(filter);
		var filterUi = this.findUiItemByDataSourceFilter(filter);
		filterUi.rerender();
		this.disableLoadingState(filterUi);
		this.scrollBar.update({
			useHScroll: false
		});
	},

	findUiItemByDataSourceFilter: function(filter) {
		if (!filter) {
			return null;
		}
		var filterEditGroupUi = this.ui;
		if (filterEditGroupUi.filter.uId == filter.uId) {
			return filterEditGroupUi;
		} else {
			return filterEditGroupUi.findChildItemByFilter(filter);
		}
	},

	findDataSourceFilterEditGroup: function() {
		var group = this.findGroupByName(this.filters, this.filterGroupName);
		return group;
	},

	findGroupByName: function(parentGroup, groupName) {
		var children = parentGroup.items;
		for (var i=0; i<children.length; i++) {
			var child = children.items[i];
			if (!this.itemIsFiltersGroup(child)) {
				continue;
			}
			if (child.name == groupName) {
				return child;
			}
		}
		return null;
	},

	itemIsFiltersGroup: function(item) {
		return item instanceof Terrasoft.FiltersGroup;
	},

	isNeedProcessingOnEvent: function(item) {
		var firstLevelGroup = item.getFirstLevelGroup();
		if (firstLevelGroup.name != this.filterGroupName) {
			return false;
		}
		return true;
	},

	group: function(filters) {
		if (!this.groupIsPossible(filters)) {
			return false;
		}
		var parentGroupUi = filters.items[0].parentGroup;
		var parentGroup = parentGroupUi.filter;
		var ids = new Array();
		for (var i=0; i<filters.items.length; i++) {
			ids.push(filters.items[i].filter.uId);
		}
		parentGroup.group(ids);
	},

	groupIsPossible: function(filters) {
		if (filters.items.length < 1) {
			return false;
		}
		var parentGroup = filters.items[0].parentGroup;
		for (var i = 0; i < filters.items.length; i++) {
			var item = filters.items[i];
			if (!(item instanceof Terrasoft.FilterEdit.FilterItemUI) || (item.parentGroup != parentGroup)) {
				return false;
			}
		}
		return true;
	},

	ungroup: function(filterUi) {
		if (!this.ungroupIsPossible(filterUi)) {
			return false;
		}
		filterUi.filter.ungroup();
	},

	ungroupIsPossible: function(filterUi) {
		if (!(filterUi instanceof Terrasoft.FilterEdit.FiltersGroupUI)){
			return false;
		}
		var firstLevelGroup = filterUi.filter.getFirstLevelGroup();
		if ((filterUi.filter == firstLevelGroup) 
			|| (firstLevelGroup.name != this.filterGroupName) || filterUi.filter.isSubFilter) {
			return false;
		}
		return true;
	},

	moveUp: function(item) {
		var parentGroup = item.parentGroup;
		if (!parentGroup) {
			return;
		}
		var index = parentGroup.items.items.indexOf(item);
		var target;
		var position = "Above";
		var parentFilter = parentGroup.filter;
		if (index > 0) {
			target = parentGroup.items.items[index-1];
			if (target instanceof Terrasoft.FilterEdit.FiltersGroupUI) {
				var children = target.items;
				if (children.items.length > 0) {
					target = children.items[children.length-1];
					position = "Below";
				} else {
					position = "Append";
				}
			}
		} else {
			if (parentFilter.name == this.filterGroupName) {
				return;
			}
			if (parentGroup.isSubFilter) {
				return;
			}
			target = parentGroup;
		}
		parentFilter.move(item.filter.uId, target.filter.uId, position);
	},

	moveDown: function(item) {
		var parentGroup = item.parentGroup;
		if (!parentGroup) {
			return;
		}
		var index = parentGroup.items.items.indexOf(item);
		var target;
		var position = "Below";
		var parentFilter = parentGroup.filter;
		if (index < parentGroup.items.length-1) {
			target = parentGroup.items.items[index+1];
			if (target instanceof Terrasoft.FilterEdit.FiltersGroupUI) {
				var children = target.items;
				if (children.items.length > 0) {
					target = children.items[0];
					position = "Above";
				} else {
					position = "Append";
				}
			}
		} else {
			if (parentFilter.name == this.filterGroupName) {
				return;
			}
			if (parentGroup.isSubFilter) {
				return;
			}
			target = parentGroup;
		}
		parentFilter.move(item.filter.uId, target.filter.uId, position);
	},

	insert: function(index, toolItem, force) {
		if (!this.toolbarVisible) {
			return;
		}
		toolItem.designMode = this.designMode;
		var toolBar = this.toolBar;
		var ownToolsLength = this.ownToolsConfig.length;
		var toolsLength = toolBar.items.length;
		if (ownToolsLength == toolsLength) {
			toolBar.add(new Ext.Spacer({
				stripeVisible: true
			}));
		}
		if (index < 0 || index > toolBar.items.length) {
			toolBar.add(toolItem, force);
		} else {
			index += ownToolsLength + 1;
			toolBar.insert(index, toolItem, force);
		}
	},

	moveControl: function(item, position) {
		var oldOwner = item.ownerCt;
		oldOwner.removeControl(item);
		item.rendered = false;
		this.insert(position, item);
		Ext.ComponentMgr.register(item);
	},

	removeControl: function(control) {
		if (!this.toolbarVisible) {
			return;
		}
		var toolBar = this.toolBar;
		toolBar.remove(control);
		var toolsLength = toolBar.items.length;
		var lastItem = toolBar.items.itemAt(toolsLength - 1);
		if (lastItem.xtype == 'spacer') {
			toolBar.remove(lastItem);
		}
	},

	selectControl: function(control) {
	},

	disableLoadingState: function(filter) {
		if (filter.loading) {
			filter.loadingIconWrapper.removeClass(this.loadingCls);
			filter.checkBox.setVisible(true);
			filter.loading = false;
		}
		if (filter instanceof Terrasoft.FilterEdit.FiltersGroupUI) {
			var children = filter.items;
			for (var i=0; i < children.length; i++) {
				this.disableLoadingState(children.items[i]);
			}
		}
	},

	onSelectionChange: function(selectedItems) {
		this.actualizeToolbarButtons(selectedItems);
	},

	actualizeToolbarButtons: function(selectedItems) {
		if (!this.toolbarVisible) {
			return;
		}
		var groupIsPossible = this.groupIsPossible(selectedItems);
		var ungroupIsPossible = (selectedItems.length == 1) && this.ungroupIsPossible(selectedItems.items[0]);
		var groupToolItem = this.findToolItemByTag('group');
		groupToolItem.setEnabled(groupIsPossible);
		var ungroupToolItem = this.findToolItemByTag('ungroup');
		ungroupToolItem.setEnabled(ungroupIsPossible);
	}

});

Ext.reg("filteredit", Terrasoft.FilterEdit);

Terrasoft.FilterEdit.FiltersGroupUI = function(cfg) {
	this.items = new Ext.util.MixedCollection(false, function(o) { return o.id; });
	Ext.apply(this, cfg);
	if (!this.id) {
		this.id = Ext.id();
	}
	if (!this.logicalOperation) {
		this.logicalOperation = Terrasoft.Filter.LogicalOperation.AND;
	}
};

Ext.extend(Terrasoft.FilterEdit.FiltersGroupUI, {});

Terrasoft.FilterEdit.FiltersGroupUI.prototype = {
	
	add: function(filter) {
		var id = filter.id || Ext.id();
		filter.parentGroup = this;
		this.items.add(id, filter);
	},
	
	insert: function(filter, index) {
		var id = filter.id || Ext.id();
		filter.parentGroup = this;
		this.items.insert(index, id, filter);
	},
	
	render: function(container) {
		var groupNode = this.createGroupNode(container);
		this.el = Ext.get(groupNode);
		var checkBoxPlace = this.el.child("span.check-box");
		var isEnabled = this.filter.isEnabled;
		this.checkBox = new Terrasoft.CheckBox({
			renderTo: checkBoxPlace.dom,
			checked: isEnabled
		});
		this.loadingIconWrapper = this.el.child("td.group-operation");
		this.checkBox.on("check", this.onCheck, this);
		this.newConditionEl = this.el.child("span.new-condition-link");
		var handler = this.filterEdit.showFilterEditWindow.createDelegate(this.filterEdit, [this]);
		this.newConditionEl.on("click", handler, this.filterEdit);
		this.newConditionEl.addClassOnOver("over");
		this.logicalOperation = this.el.child("span.logical-operation");
		this.logicalOperation.on("click", this.editLogicalOperation, this);
		this.logicalOperation.addClassOnOver("over");
		var selectionEl = this.el.child("td.group-operation");
		if (!this.isFirstLevelGroup()) {
			selectionEl.addClassOnOver("over");
		}
		this.filterKindButton = this.el.child("img.filter-kind-button");
		var needShowFilterKindMenu = true;
		var menu = null;
		if (this.isSubFilter) {
			needShowFilterKindMenu = false;
		} else {
			menu = this.getFilterKindMenu();
			if (menu.items.length <= 1) {
				needShowFilterKindMenu = false;
			}
		}
		if (needShowFilterKindMenu) {
			this.filterKindButton.menu = menu;
			this.filterKindButton.on("click", this.onFilterKindButtonClick, this);
			this.filterKindButton.addClassOnClick("click");
		} else {
			this.filterKindButton.setStyle('display', 'none');
		}
		this.closeIcon = this.el.child("img.close-icon");
		if (this.closeIcon) {
			this.closeIcon.on("click", this.onCloseIconClick, this);
			this.closeIcon.addClassOnClick("click");
		}
		this.filterEdit.selectionModel.subscribe(this, selectionEl);
		var filters = this.items;
		this.rendered = true;
		if (filters.length > 0) {
			for (var i = filters.length - 1; i >= 0; i--) {
				var item = filters.items[i];
				item.parentGroup = this;
				item.render();
			}
		}
		if (!isEnabled) {
			this.disable(true);
		}
		this.rendered = true;
	},
	
	rerender: function() {
		this.repaintLogicalOperation();
		var isEnabled = !!this.filter.isEnabled;
		this.checkBox.setValue(isEnabled, true);
		this.disable(!isEnabled);
	},
	
	repaintLogicalOperation: function() {
		var logicalOperation = Ext.StringList('WC.FilterEdit').getValue("LogicalOperation."+this.filter.logicalOperation);
		this.logicalOperation.dom.innerHTML = logicalOperation;
	},
	
	createGroupNode: function(container) {
		var groupTemplate = new Ext.Template(
				'<table class="group">',
					'<tr>',
						'<td class="group-operation">',
							'<span class="check-box"></span>',
							'<span class="loading-icon-wrapper">',
								'<img src="{emptyImage}" class="loading-icon">',
							'</span>',
							'<span class="logical-operation">{logicalOperation}</span>',
							'<img src="{emptyImage}" class="close-icon">',
						'</td>',
						'<td class="filters">',
							'<div class="new-condition">',
								'<span class="new-condition-link">',
									'{newConditionLabel}',
								'</span>',
								'<img src="{emptyImage}" class="filter-kind-button">',
							'</div>',
						'</td>',
					'</tr>' ,
				'</table>'
		);
		var node = document.createElement("div");
		node.className = "group-frame";
		if (this.isFirstLevelGroup()) {
			node.className +=" first-group";
		}
		node.innerHTML = groupTemplate.apply({
			logicalOperation: Ext.StringList('WC.FilterEdit').getValue('LogicalOperation.'+this.filter.logicalOperation),
			newConditionLabel: Ext.StringList('WC.FilterEdit').getValue('AddNewCondition'),
			emptyImage: Ext.BLANK_IMAGE_URL
		});
		if (container) {
			container.dom.appendChild(node);
		} else {
			var parent = this.parentGroup;
			var nextSibling = this.getNextSibling();
			var beforeNode = nextSibling ? nextSibling.el.dom : parent.newConditionEl.dom.parentNode;
			var filtersNode = parent.getItemsContainer();
			filtersNode.dom.insertBefore(node, beforeNode);
		}
		return node;
	},

	isFirstLevelGroup: function(){
		if (this.isSubFilter) {
			return false;
		}
		var filter = this.filter;
		var firstLevelGroup = filter.getFirstLevelGroup();
		return (filter == firstLevelGroup);
	},

	getNextSibling: function() {
		var parent = this.parentGroup;
		if (parent.items.last() == this) {
			return null;
		}
		var index = parent.items.indexOf(this);
		return parent.items.items[index + 1];
	},
	
	getItemsContainer: function() {
		return this.el.child("td.filters");
	},

	onCheck: function(checkBox, checked, opt) {
		if (opt.isInitByEvent) {
			return;
		}
		var prevEnabled = this.filter.isEnabled;
		this.filter.isEnabled = checked;
		this.filter.synchronize();
		checkBox.setValue(prevEnabled, true);
		checkBox.setVisible(false);
		this.loadingIconWrapper.addClass(this.filterEdit.loadingCls);
		this.loading = true;
	},

	onCloseIconClick: function(e) {
		var dataSourceFilter = this.filter;
		var filterEditGroup = this.filterEdit.findDataSourceFilterEditGroup();
		if (dataSourceFilter == filterEditGroup || dataSourceFilter.parentItem) {
			dataSourceFilter.clear();
		} else {
			dataSourceFilter.parentGroup.remove(dataSourceFilter.uId);
		}
		e.stopEvent();	
	}, 

	remove: function() {
		this.filterEdit.selectionModel.unselect(this);
		if (this.rendered) {
			var filters = this.items;
			for (var i=filters.length-1; i>=0; i--) {
				var filter = filters.items[i];
				filter.remove();
			}
			this.checkBox.un("check", this.onCheck, this);
			this.checkBox.destroy();
			this.newConditionEl.removeAllListeners();
			this.logicalOperation.removeAllListeners();
			if (this.closeIcon) {
				this.closeIcon.removeAllListeners();
			}
			this.el.remove();
		}
		if (this.parentGroup) {
			this.parentGroup.items.remove(this);
		}
	},

	editLogicalOperation: function() {
		this.filter.logicalOperation = (this.filter.logicalOperation == Terrasoft.Filter.LogicalOperation.AND ? 
			Terrasoft.Filter.LogicalOperation.OR : Terrasoft.Filter.LogicalOperation.AND);
		this.filter.synchronize();
	},

	removeNewConditionEl: function() {
		var newConditionEl = this.newConditionEl;
		newConditionEl.un("click", this.onRemove, this);
		var row = newConditionEl.dom.parentNode.parentNode;
		row.parentNode.removeChild(row);
	},

	disable: function(disabled) {
		if (disabled == this.disabled) {
			return;
		}
		if (disabled) {
			this.el.addClass("disabled");
		} else {
			this.el.removeClass("disabled");
		}
		this.disabled = disabled;
	},

	getIsFirstLevelChildren: function(itemIds) {
		for (var i=0; i<itemIds; i++) {
			var item = this.items.get(itemIds[i]);
			if (!item || (item.parentGroup.id != this.id)) {
				return false;
			}
		}
		return true;
	},

	findChildItemByFilter: function(filter) {
		var children = this.items;
		var itemUi;
		for (var i=0; i<children.length; i++) {
			var child = children.items[i];
			if (child.filter.uId == filter.uId) {
				itemUi = child;
			} else {
				if (child instanceof Terrasoft.FilterEdit.FiltersGroupUI) {
					itemUi = child.findChildItemByFilter(filter);
				} else {
					if (child instanceof Terrasoft.FilterEdit.FilterItemUI && child.subFilters) {
						if (child.subFilters.filter.uId == filter.uId) {
							return child.subFilters;
						}
						itemUi = child.subFilters.findChildItemByFilter(filter);
					}
				}
			}
			if (itemUi) {
				return itemUi;
			}
		}
		return null;
	},

	onFilterKindButtonClick: function(e) {
		if (this.filterKindButton && this.filterKindButton.menu){
			this.filterKindButton.menu.show(e.target, "tl-bl?");
		}
		e.stopEvent();
	},

	getFilterKindMenu: function() {
		var menu = new Ext.menu.Menu();
		var filterEditStringList = Ext.StringList('WC.FilterEdit');
		menu.add({ id: "default", caption: filterEditStringList.getValue('FilterKind.Default') });
		if (this.filterEdit.aggregationEnable) {
			menu.add({ id: "aggregated", caption: filterEditStringList.getValue('FilterKind.Aggregated') });
		}
		menu.on("itemclick", this.filterKindMenuClick, this);
		return menu;
	},

	filterKindMenuClick: function(item) {
		switch (item.id) {
			case "default":
				this.filterEdit.showFilterEditWindow(this);
				break;
			case "aggregated":
				this.filterEdit.showFilterEditWindow(this, null, true);
				break;
		}
	}
};

Terrasoft.FilterEdit.FilterItemUI = function(cfg) {
	Ext.apply(this, cfg);
	if (!this.id) {
		this.id = Ext.id();
	}
};

Ext.extend(Terrasoft.FilterEdit.FilterItemUI, {});

Terrasoft.FilterEdit.FilterItemUI.prototype = {

	render: function() {
		var item = this.createItemNode();
		this.el = Ext.get(item);
		var checkBoxPlace = this.el.child("td.check-box-wrapper");
		var filter = this.filter;
		this.checkBox = new Terrasoft.CheckBox({
			renderTo: checkBoxPlace.dom,
			checked: filter.isEnabled
		});
		this.loadingIconWrapper = checkBoxPlace;
		this.checkBox.on("check", this.onCheck, this);
		var leftExpression = this.leftExpression = this.el.child("span.left-expression");
		var filterLeftExpression = filter.leftExpression;
		var filterEdit = this.filterEdit;
		if (filterLeftExpression) {
			if (filterLeftExpression.aggregationType) {
				var aggregationType = this.aggregationType = this.el.child("span.aggregation-type");
				aggregationType.addClassOnOver("over");
				aggregationType.on("click", this.editAggregationType, this);
			}
			var handler = filterEdit.showFilterEditWindow.createDelegate(filterEdit, [null, this]);
			leftExpression.on("click", handler, filterEdit);
			leftExpression.addClassOnOver("over");
		} else {
			leftExpression.remove();
		}
		var comparisonType;
		if (!this.isBoolColumnType()) {
			comparisonType = this.comparisonType = this.el.child("span.comparison-type");
			comparisonType.addClassOnOver("over");
			comparisonType.on("click", this.editFilterType, this);
		}
		var rightExpressionValue = this.rightExpressionValue = this.el.child("span.right-expression-value");
		comparisonType = filter.comparisonType;
		var isRightExpressionValueExist = (comparisonType == Terrasoft.Filter.ComparisonType.IS_NULL) ||
			(comparisonType == Terrasoft.Filter.ComparisonType.IS_NOT_NULL);
		if (isRightExpressionValueExist) {
			rightExpressionValue.remove();
		} else {
			rightExpressionValue.addClassOnOver("over");
			rightExpressionValue.on("click", this.onRightExpressionValueClick, this);
		}
		var rightExpressionAdditionalValue =
			this.rightExpressionAdditionalValue = this.el.child("span.right-expression-additional_value");
		if (rightExpressionAdditionalValue) {
			rightExpressionAdditionalValue.addClassOnOver("over");
			rightExpressionAdditionalValue.on("click", this.macrosAdditionalParametersClick, this);
		}
		var filterEditStringList = Ext.StringList('WC.FilterEdit');
		var macrosButton = this.el.child("img.macros-button");
		if (!filter.leftExpression || isRightExpressionValueExist) {
			macrosButton.remove();
		} else {
			var macrosMenu = this.getMacrosMenu();
			macrosMenu.addSeparator();
			var columnMnuItem = macrosMenu.add({
				id: 'FilterValue',
				caption: filterEditStringList.getValue('RightExpressionValueMenu.' + 'FilterValue')
			});
			columnMnuItem.on('click', this.onRightExpressionValueMenuItemClick, this);
			//TODO: #128293
//			columnMnuItem = macrosMenu.add({
//				id: 'Column',
//				caption: filterEditStringList.getValue('RightExpressionValueMenu.' + 'Column')
//			});
//			columnMnuItem.on('click', this.handleColumnMenuItemClick, this);
			if (filterEdit.customFilterEnable) {
				columnMnuItem = macrosMenu.add({
					id: 'CustomFilter',
					caption: filterEditStringList.getValue('RightExpressionValueMenu.' + 'CustomFilter')
				});
				columnMnuItem.on('click', this.handleCustomFilterMenuItemClick, this);
			}
			macrosButton.macrosMenu = macrosMenu;
			macrosButton.on("click", this.onMacrosButtonClick, this);
			this.macrosButton = macrosButton;
			macrosButton.addClassOnClick("click");
		}
		var closeIcon = this.closeIcon = this.el.child("img.close-icon");
		closeIcon.on("click", this.onCloseIconClick, this);
		closeIcon.addClassOnClick("click");
		var subFilters = this.subFilters;
		if (subFilters) {
			var subFiltersContainer = this.el.child("div.subFilters-item-container");
			subFilters.render(subFiltersContainer);
			var filterItemSelectionEl = this.el.child("tr.filter-item-container");
			filterItemSelectionEl.addClassOnOver("over");
			filterEdit.selectionModel.subscribe(this, filterItemSelectionEl);
		} else {
			filterEdit.selectionModel.subscribe(this, this.el);
			this.el.addClassOnOver("over");
		}
		this.rendered = true;
	},

	rerender: function() {
		var isSelected = this.isSelected();
		this.removeUi();
		this.render();
		if (isSelected) {
			this.select();
		}
	},

	setFirstFilter: function(isFirstFilter) {
		var firstFilterClassName = 'firstFilter';
		var filterItemEl = this.el;
		filterItemEl.removeClass(firstFilterClassName);
		if (isFirstFilter === true) {
			filterItemEl.addClass(firstFilterClassName);
		}
	},

	findMacrosByType: function(type) {
		var macroses = Terrasoft.FilterMacrosList;
		for (var i = 0, l = macroses.length; i < l; i++) {
			var macros = macroses[i];
			if (macros.id === type) {
				return macros;
			}
		}
		return null;
	},

	createItemNode: function() {
		var filter = this.filter;
		var isSpecialRightExpression = false;
		var rightExpression = filter.rightExpression;
		var macrosEditorPosition = Terrasoft.Filter.MacrosEditorPosition.LEFT;
		if (!Ext.isEmpty(rightExpression) && rightExpression.expressionType == Terrasoft.FilterExperssionType.MACROS) {
			var macros = this.findMacrosByType(rightExpression.macrosType);
			macrosEditorPosition = macros.editorPosition || Terrasoft.Filter.MacrosEditorPosition.LEFT;
			isSpecialRightExpression = macros.isSpecialMacros;
		}
		var aggregationTypeTemplate = (filter.leftExpression && filter.leftExpression.aggregationType)
			? '<span class="aggregation-type">{aggregationType}</span>' : '';
		var rightExpressionAdditionalValueTemplate = isSpecialRightExpression
			? '<span class="right-expression-additional_value">{rightExpressionAdditionalValue}</span>' : '';
		var rightExpressionValueTemplate =
			macrosEditorPosition == Terrasoft.Filter.MacrosEditorPosition.RIGHT ? '{1}{0}' : '{0}{1}';
		var rightExpressionTemplate =
			String.format(rightExpressionValueTemplate, rightExpressionAdditionalValueTemplate,
				'<span class="right-expression-value">{rightExpressionValue}</span>');
		var itemTemplate = new Ext.Template(
			'<table class="item" cellspacing="0">',
			'<tr class="filter-item-container">',
				'<td class="check-box-wrapper">',
					'<img src="{emptyImage}" class="loading-icon">',
				'</td>',
				'<td class="expression">',
					aggregationTypeTemplate,
					'<span class="left-expression">{leftExpression}</span> ',
					'<span class="comparison-type-wrapper">',
						'<span class="comparison-type">{comparisonType}</span>',
					'</span> ',
					'<span class="right-expression">',
						rightExpressionTemplate,
						'<span class="right-expression-editor"></span>',
						'<img src="{emptyImage}" class="macros-button">',
					'</span>',
				'</td>',
				'<td class="close-icon-wrapper">',
					'<img src="{emptyImage}" class="close-icon">',
				'</td>',
			'</tr>',
			'<tr>',
				'<td>',
				'</td>',
				'<td>',
					'<div class="subFilters-item-container">',
					'</div>',
				'</td>',
				'<td>',
				'</td>',
			'</tr>',
		'</table>'
		);
		var node = document.createElement("div");
		var className = "filter-item";
		if (filter.parentGroup.items.indexOf(filter) == 0) {
			className += " firstFilter";
		}
		if (filter.isEnabled === false) {
			className+= " disabled";
		}
		if (this.isBoolColumnType()){
			className+= " bool";
		}
		node.className = className;
		var comparisonType = this.isBoolColumnType() ? '' :
			Ext.StringList('WC.FilterEdit').getValue('ComparisonType.' + filter.comparisonType);
		var rightExpressionValue = this.getRightExpressionValue(filter);
		var rightExpressionAdditionalValue = this.getRightExpressionAdditionalValue(filter);
		var leftExpressionCaption = "";
		var aggregationType = "";
		if (filter.leftExpression) {
			leftExpressionCaption = this.getShortColumnCaption(filter.leftExpression.caption);
			if (filter.leftExpression.aggregationType) {
				leftExpressionCaption = '(' + leftExpressionCaption + ')';
				aggregationType = this.getAggregationTypeCaption(filter.leftExpression.aggregationType);
			}
		}
		node.innerHTML = itemTemplate.apply({
			leftExpression: Ext.util.Format.htmlEncode(leftExpressionCaption),
			aggregationType: aggregationType,
			comparisonType: comparisonType,
			rightExpressionValue: Ext.util.Format.htmlEncode(rightExpressionValue),
			emptyImage: Ext.BLANK_IMAGE_URL,
			rightExpressionAdditionalValue: (isSpecialRightExpression ? Ext.util.Format.htmlEncode(rightExpressionAdditionalValue) : '')
		});
		var parent = this.parentGroup;
		var nextSibling = this.getNextSibling();
		var beforeNode = nextSibling ? nextSibling.el.dom : parent.newConditionEl.dom.parentNode;
		var filtersNode = parent.getItemsContainer();
		filtersNode.dom.insertBefore(node, beforeNode);
		return node;
	},

	onRightExpressionValueClick: function() {
		if (this.getIsComparisonTypeExists(this.filter.comparisonType)) {
			this.filterEdit.showFilterEditWindow(null, this, true);
		} else {
			this.editFilterValue(false);
		}
	},

	onRightExpressionValueMenuItemClick: function() {
		this.editFilterValue(true);
	},

	getShortColumnCaption: function(longCaption, includeParenthesis) {
		var startIndex = longCaption.indexOf(" (по колонке");
		if (startIndex < 0) {
			return includeParenthesis ? '(' + longCaption + ')' : longCaption;
		}
		var endIndex = longCaption.lastIndexOf(")") + 1;
		var startString = longCaption.substring(0, startIndex);
		var endString = longCaption.substring(endIndex, longCaption.length);
		longCaption = startString + endString;
		return this.getShortColumnCaption(longCaption, includeParenthesis);
	},

	getRightExpressionValue: function(filter) {
		var rightExpressions = filter.rightExpression;
		var value = "";
		if (!Ext.isEmpty(rightExpressions)) {
			switch (filter.rightExpression.expressionType) {
				case Terrasoft.Filter.ExpressionType.PARAMETER : {
					for (var i=0; i<rightExpressions.parameterValues.length; i++) {
						var itemValue = rightExpressions.parameterValues[i].displayValue || rightExpressions.parameterValues[i].parameterValue;
						if (this.isBoolColumnType()) {
							itemValue = Ext.StringList('WC.Common').getValue('BoolValues.'+itemValue.toString());
						}
						value += itemValue;
						if (i != (rightExpressions.parameterValues.length - 1)) {
							value += '; ';
						}
					}
					break;
				}
				case Terrasoft.Filter.ExpressionType.EXISTS : {
					value = this.getShortColumnCaption(rightExpressions.caption, true);
					break;
				}
				case Terrasoft.Filter.ExpressionType.SCHEMA_COLUMN : {
					value = rightExpressions.caption;
					break;
				}
				case Terrasoft.Filter.ExpressionType.MACROS : {
					value = Ext.StringList('WC.FilterEdit').getValue('Macroses.' + rightExpressions.macrosType);
				break;
				}
				case Terrasoft.Filter.ExpressionType.CUSTOM : {
					if (rightExpressions.parameterValues) {
						itemValue = rightExpressions.parameterValues[0].displayValue || rightExpressions.parameterValues[0].parameterValue;
						value = itemValue;
					}
				break;
				}
			}
		}
		if (Ext.isEmpty(value)) {
			value = "<?>";
		}
		return value;
	},

	getRightExpressionAdditionalValue: function(filter) {
		var value = '';
		var rightExpression = filter.rightExpression;
		if (!Ext.isEmpty(rightExpression) && rightExpression.expressionType == Terrasoft.FilterExperssionType.MACROS) {
			var macros = this.findMacrosByType(rightExpression.macrosType);
			if (macros.isSpecialMacros) {
				var parameter= rightExpression.parameterValues ? rightExpression.parameterValues[0] : null;
				var displayValue = null;
				if (parameter) {
					displayValue = parameter.displayValue ? parameter.displayValue : null;
				}
				value = displayValue || (parameter? parameter.parameterValue : '');
				if (Ext.isEmpty(value)) {
					value = "<?>";
				}
			}
		}
		return value;
	},

	isBoolColumnType: function() {
		return this.filter.leftExpression && this.filter.leftExpression.dataValueType.name == "Boolean";
	},
	
	getMacrosMenu: function() {
		var macrosMenu = new Ext.menu.Menu();
		var macroses = Terrasoft.FilterMacrosList;
		var filterEditStringList = Ext.StringList('WC.FilterEdit');
		var separators = {};
		for (var i = 0; i < macroses.length; i++) {
			var macros = macroses[i];
			var macrosGroupName = macros.group;
			if (macros.type == 'Separator') {
				separators[macrosGroupName] = true;
				continue;
			}
			if (this.isCompatibleMacros(macros)) {
				var macrosTarget = macrosMenu;
				if (macrosGroupName) {
					var macrosGroup = macrosMenu.items.get(macrosGroupName);
					if (!macrosGroup) {
						macrosGroup = macrosMenu.add({
							id: macrosGroupName,
							caption: filterEditStringList.getValue('MacrosGroup.' + macrosGroupName),
							tag: 'macros'
						});
						var macrosGroupSubmenu = new Ext.menu.Menu();
						macrosGroupSubmenu.owner = macrosGroup;
						macrosGroup.menu = macrosGroupSubmenu;
					}
					macrosTarget = macrosGroup.menu; 
				}
				if (separators[macrosGroupName]) {
					macrosTarget.addSeparator();
					delete separators[macrosGroupName];
				}
				var isSpecialMacros = macros.isSpecialMacros;
				var macrosMenuItem = macrosTarget.add({
					id: macros.id,
					caption: (isSpecialMacros ? Ext.util.Format.htmlEncode("<?> ") : '')
						+ filterEditStringList.getValue('Macroses.' + macros.id),
					tag: 'macros'
				});
				macrosMenuItem.on('click', this.handleMacrosTypeMenuItemClick, this);
			}
		}
		return macrosMenu;
	},

	handleMacrosTypeMenuItemClick: function(menuItem) {
		if (menuItem) {
			this.applyTrimDateTimeParameterToDate();
			this.filter.rightExpression = {
				expressionType: Terrasoft.Filter.ExpressionType.MACROS,
				macrosType: menuItem.id
			};
			this.filter.synchronize();
			this.filterEdit.scrollBar.update({useHScroll: false});
		}
	},

	macrosAdditionalParametersClick: function() {
		var rightExpression = this.filter.rightExpression;
		var currentValue = rightExpression.parameterValues ? rightExpression.parameterValues[0].parameterValue : '';
		var currentDisplayValue = rightExpression.parameterValues ? rightExpression.parameterValues[0].displayValue : '';
		var editorMenu = new Ext.menu.Menu({
			cls: "filter-value-editor"
		});
		var macros = this.findMacrosByType(rightExpression.macrosType);
		var defaultConfig = {
			xtype:'integeredit',
			required: true,
			toolsConfig: this.getEditorToolsConfig(editorMenu)
		};
		var config = Ext.apply({}, macros.editor || {}, defaultConfig);
		var menuItem = new Terrasoft.EditMenuItem({
			config: config,
			hideOnClick: false
		});
		var dataProviderXType = macros.dataProviderXType;
		var editor = menuItem.editor;
		if (!Ext.isEmpty(dataProviderXType)) {
			editor.dataProvider = Ext.ComponentMgr.create({
				xtype: dataProviderXType
			});
		}
		if (currentValue) {
			if (editor.setValueAndText && currentDisplayValue) {
				editor.setValueAndText(currentValue, currentDisplayValue);
			} else {
				editor.setValue(currentValue);
			}
		}
		if (rightExpression.macrosType == 'Month' || rightExpression.macrosType == 'DayOfWeek' ||
				rightExpression.macrosType == 'HourMinute') {
			var selectCmp = rightExpression.macrosType == 'HourMinute' ? editor.time : editor;
			selectCmp.on("select", function() {
				this.onAllowButtonClick.call(menuItem);
				this.handleMacroParametersEditComplete(menuItem);
			}, this);
			editorMenu.on('show', function() {
				this.onPrimaryToolButtonClick();
			}, selectCmp);
		}
		editorMenu.add(menuItem);
		this.attachEditorToolButtonEventHandlers(editorMenu, menuItem);
		editorMenu.on("itemclick", this.handleMacroParametersEditComplete, this);
		editorMenu.on("hide", function() {
			editorMenu.destroy();
		}, this);
		editorMenu.show(this.rightExpressionValue.dom, "tl-bl?");
	},

	handleMacroParametersEditComplete: function(menuItem) {
		var valueEditor = menuItem.editor;
		if (!valueEditor || !menuItem.allowButtonClick) {
			return;
		}
		valueEditor.unFocus();
		var rightExpression = this.filter.rightExpression;
		var macros = this.findMacrosByType(rightExpression.macrosType);
		rightExpression.dataValueType.name = macros.parameterType;
		var parameter = {
			parameterValue: valueEditor.getValue()
		};
		if (menuItem.editor.getDisplayValue) {
			parameter.displayValue = valueEditor.getDisplayValue();
		}
		rightExpression.parameterValues = [parameter];
		this.filter.synchronize();
		this.filterEdit.scrollBar.update({useHScroll: false});
		menuItem.parentMenu.hide();
	},

	applyTrimDateTimeParameterToDate: function() {
		var columnType = this.filter.leftExpression.dataValueType.name;
		this.filter.trimDateTimeParameterToDate = columnType == 'DateTime' || columnType == 'Date';
	},

	handleCustomFilterMenuItemClick: function() {
		var isSubFilter = this.isSubFilter;
		this.filter.rightExpression.expressionType = Terrasoft.Filter.ExpressionType.CUSTOM;
		this.filterEdit.fireEvent("editrightexpressioncustomfilter", this.filter.uId, isSubFilter);
	},

	handleColumnMenuItemClick: function() {
		var isSubFilter = this.isSubFilter;
		this.filterEdit.fireEvent("editrightexpressioncolumn", this.filter.uId, isSubFilter);
	},

	isCompatibleMacros: function(macros) {
		var leftExpression = this.filter.leftExpression;
		var isCompatibleByRefSchema = false;
		if (leftExpression.expressionType != Terrasoft.Filter.ExpressionType.AGGREGATION &&
				leftExpression.expressionType != Terrasoft.Filter.ExpressionType.PARAMETER &&
				macros.refSchemaUIds && leftExpression.referenceSchemaUId) {
			var refSchemaUId = leftExpression.referenceSchemaUId;
			for (var i=0; i<macros.refSchemaUIds.length; i++) {
				if (macros.refSchemaUIds[i] == refSchemaUId) {
					isCompatibleByRefSchema = true;
					break;
				}
			}
		}
		var isCompatibleByDataValueType = false;
		if (macros.dataValueTypes) {
			var dataValueType = leftExpression.dataValueType.name;
			for (i=0; i<macros.dataValueTypes.length; i++) {
				if (macros.dataValueTypes[i] == dataValueType) {
					isCompatibleByDataValueType = true;
					break;
				}
			}
		}
		return isCompatibleByRefSchema || isCompatibleByDataValueType;
	},

	isEmptyRightExpressionParameterValues: function() {
		var rightExpression = this.filter.rightExpression;
		if (!rightExpression || !rightExpression.parameterValues) {
			return true;
		} else {
			return rightExpression.expressionType != Terrasoft.Filter.ExpressionType.PARAMETER ?
				true : rightExpression.parameterValues.length == 0;
		}
	},

	isEmptyRightExpression: function() {
		var result;
		if (!this.filter.rightExpression) {
			result = true;
		} else {
			switch(this.filter.rightExpression.expressionType) {
				case Terrasoft.Filter.ExpressionType.PARAMETER : {
					result = this.filter.rightExpression.parameterValues.length == 0;
					break;
				}
				case Terrasoft.Filter.ExpressionType.CUSTOM : {
					result = this.filter.rightExpression.parameterValues.length == 0;
					break;
				}
				case Terrasoft.Filter.ExpressionType.MACROS : {
					result = Ext.isEmpty(this.filter.rightExpression.macrosType);
					break;
				}
				case Terrasoft.Filter.ExpressionType.SCHEMA_COLUMN : {
					result = Ext.isEmpty(this.filter.rightExpression.metaPath);
					break;
				}
				default: {
					result = true;
				}
			}
		}
		return result;
	},

	getNextSibling: function() {
		var parent = this.parentGroup;
		if (parent.items.last() == this) {
			return null;
		}
		var index = parent.items.indexOf(this);
		return parent.items.items[index + 1];
	},

	onCloseIconClick: function(e) {
		var dataSourceFilter = this.filter;
		dataSourceFilter.parentGroup.remove(dataSourceFilter.uId);
		e.stopEvent();
	},

	onMacrosButtonClick: function(e) {
		this.showOnlyMacrosMenuItem(false);
		this.showMacrosMenu(e.target);
		e.stopEvent();
	},

	showMacrosMenu: function(target) {
		if (this.macrosButton && this.macrosButton.macrosMenu){
			this.macrosButton.macrosMenu.show(target, "tl-bl?");
		}
	},

	remove: function() {
		this.removeUi();
		this.parentGroup.items.remove(this);
	},

	removeUi: function() {
		this.filterEdit.selectionModel.unselect(this);
		if (this.rendered) {
			this.filterEdit.selectionModel.unsubscribe(this);
			this.checkBox.un("check", this.onCheck, this);
			this.checkBox.destroy();
			this.leftExpression.removeAllListeners();
			if (this.comparisonType) {
				this.comparisonType.removeAllListeners();
			}
			this.rightExpressionValue.removeAllListeners();
			if (this.comparisonTypeMenu) {
				this.comparisonTypeMenu.un("itemclick", this.handleComparisonTypeMenuClick, this);
				this.comparisonTypeMenu.destroy();
			}
			if (this.macrosButton && this.macrosButton.macrosMenu) {
				this.macrosButton.un("click", this.onCloseIconClick, this);
				this.macrosButton.macrosMenu.destroy();
			}
			this.closeIcon.removeAllListeners();
			this.el.remove();
			this.rendered = false;
		}
	},

	onCheck: function(checkBox, checked, opt) {
		if (opt.isInitByEvent) {
			return;
		}
		var prevEnabled = this.filter.isEnabled;
		this.filter.isEnabled = checked;
		this.filter.synchronize();
		checkBox.setValue(prevEnabled, true);
		this.loadingIconWrapper.addClass(this.filterEdit.loadingCls);
		checkBox.setVisible(false);
		this.loading = true;
	},

	disable: function(disabled) {
		if (disabled == this.disabled) {
			return;
		}
		if (disabled) {
			this.el.addClass("disabled");
		} else {
			this.el.removeClass("disabled");
		}
		this.disabled = disabled;
	},

	isSelected: function() {
		return this.filterEdit.selectionModel.isSelected(this);
	},

	select: function(){
		this.filterEdit.selectionModel.select(this);
	},

	editFilterType: function() {
		var comparisonType = this.filter.comparisonType;
		var dataValueType;
		if (this.getIsComparisonTypeExists(comparisonType)) {
			dataValueType = this.filter.rightExpression.dataValueType.name;
		} else {
			dataValueType = this.filter.leftExpression.dataValueType.name;
		}
		this.comparisonTypeMenu = this.getComparisonTypeMenu(dataValueType, comparisonType);
		this.comparisonTypeMenu.show(this.comparisonType.dom, "tl-bl?");
	},

	getComparisonTypeMenu: function(dataValueType, comparisonType) {
		var menu = new Ext.menu.Menu();
		var belongTypesArray = this.getBelongComparisonTypesArray(dataValueType, comparisonType);
		for (var i = 0; i < belongTypesArray.length; i++) {
			var type = belongTypesArray[i];
			menu.add({
				id: type,
				caption: this.getComparisonTypeCaption(type),
				checked: type == comparisonType,
				group: 'comparisonType'
			});
		}
		menu.on("itemclick", this.handleComparisonTypeMenuClick, this);
		return menu;
	},

	getIsComparisonTypeExists: function(comparisonType) {
		return comparisonType == Terrasoft.Filter.ComparisonType.EXISTS
			|| comparisonType == Terrasoft.Filter.ComparisonType.NOTEXISTS;
	},

	getBelongComparisonTypesArray: function(dataValueType, comparisonType) {
		var belongArray;
		belongArray = [];
		if (this.getIsComparisonTypeExists(comparisonType)) {
			belongArray = [
				Terrasoft.Filter.ComparisonType.EXISTS,
				Terrasoft.Filter.ComparisonType.NOTEXISTS
			];
		} else {
			switch (dataValueType) {
				case 'Integer':
				case 'Float1':
				case 'Float2':
				case 'Float3':
				case 'Float4':
				case 'Money':
				case 'DateTime':
				case 'Date':
				case 'Time':
					belongArray = [
						Terrasoft.Filter.ComparisonType.EQUAL,
						Terrasoft.Filter.ComparisonType.NOT_EQUAL,
						Terrasoft.Filter.ComparisonType.LESS,
						Terrasoft.Filter.ComparisonType.LESS_OR_EQUAL,
						Terrasoft.Filter.ComparisonType.GREATER,
						Terrasoft.Filter.ComparisonType.GREATER_OR_EQUAL,
						Terrasoft.Filter.ComparisonType.IS_NOT_NULL,
						Terrasoft.Filter.ComparisonType.IS_NULL
					];
					break;
				case 'Text':
				case 'Guid':
				case 'MaxSizeText':
				case 'HashText':
				case 'SecureText':
				case 'ShortText':
				case 'MediumText':
				case 'LongText':
					belongArray = [
						Terrasoft.Filter.ComparisonType.EQUAL,
						Terrasoft.Filter.ComparisonType.NOT_EQUAL,
						Terrasoft.Filter.ComparisonType.CONTAIN,
						Terrasoft.Filter.ComparisonType.NOT_CONTAIN,
						Terrasoft.Filter.ComparisonType.START_WITH,
						Terrasoft.Filter.ComparisonType.NOT_START_WITH,
						Terrasoft.Filter.ComparisonType.END_WITH,
						Terrasoft.Filter.ComparisonType.NOT_END_WITH,
						Terrasoft.Filter.ComparisonType.IS_NOT_NULL,
						Terrasoft.Filter.ComparisonType.IS_NULL
					];
					break;
				case 'Boolean':
				case 'Binary':
				case 'Lookup':
				case 'Enum':
				case 'Color':
				case 'File':
				case 'Image':
					belongArray = [
						Terrasoft.Filter.ComparisonType.EQUAL,
						Terrasoft.Filter.ComparisonType.NOT_EQUAL,
						Terrasoft.Filter.ComparisonType.IS_NOT_NULL,
						Terrasoft.Filter.ComparisonType.IS_NULL
					];
					break;
			}
		}
		return belongArray;
	},

	handleComparisonTypeMenuClick: function(item) {
		var type = item.id;
		this.filter.comparisonType = type;
		this.filter.synchronize();
		this.filterEdit.scrollBar.update({useHScroll: false});
	},

	editAggregationType: function() {
		var dataValueType = this.filter.leftExpression.clearDataValueType.name;
		this.aggregationTypeMenu = this.getAggregationTypeMenu(dataValueType);
		this.aggregationTypeMenu.on("beforeshow", this.beforeShowAggregationMenu, this);
		this.aggregationTypeMenu.show(this.aggregationType.dom, "tl-bl?");
	},

	getAggregationType: function(filter) {
		return filter.leftExpression.aggregationType;
	},

	beforeShowAggregationMenu: function() {
		var menu = this.aggregationTypeMenu;
		var type = this.getAggregationType(this.filter);
		var item = menu.items.map[type];
		item.setChecked(true);
	},

	getAggregationTypeMenu: function(dataValueType) {
		var menu = new Ext.menu.Menu();
		var belongTypesArray = this.getBelongAggregationTypesArray(dataValueType);
		var currentType = this.filter.aggregationType;
		for (var i=0; i<belongTypesArray.length; i++) {
			var type = belongTypesArray[i];
			menu.add({
				id:type, 
				caption: this.getAggregationTypeCaption(type), 
				checked: type == currentType, 
				group: 'AggregationType'
			});
		}
		menu.on("itemclick", this.handleAggregationTypeMenuClick, this);
		return menu;
	},

	getBelongAggregationTypesArray: function(dataValueType) {
		var belongArray;
		belongArray = [];
		switch(dataValueType) {
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
			case 'Guid':
				belongArray = [
					Terrasoft.Filter.AggregationType.COUNT
				];
				break;
		}
		return belongArray;
	},

	handleAggregationTypeMenuClick: function(item) {
		var type = item.id;
		this.filter.leftExpression.aggregationType = type;
		this.filter.synchronize();
		this.filterEdit.scrollBar.update({useHScroll: false});
	},

	editFilterValue: function(useValue) {
		var isEmpty = this.isEmptyRightExpression();
		var currentFilter = this.filter;
		var dataValueType = currentFilter.leftExpression.dataValueType;
		currentFilter.rightExpression = currentFilter.rightExpression || { parameterValues : [] };
		currentFilter.rightExpression.dataValueType = dataValueType;
		var currentValue = this.isEmptyRightExpressionParameterValues() ? null :
			currentFilter.rightExpression.parameterValues[0].parameterValue;
		this.applyTrimDateTimeParameterToDate();
		var columnType = dataValueType.name;
		if (isEmpty || useValue) {
			this.editFilterParameterValue(columnType, currentValue);
		} else {
			var expressionType = currentFilter.rightExpression.expressionType;
			switch (expressionType) {
				case Terrasoft.Filter.ExpressionType.PARAMETER : {
					this.editFilterParameterValue(columnType, currentValue);
					break;
				}
				case Terrasoft.Filter.ExpressionType.CUSTOM : {
					this.handleCustomFilterMenuItemClick();
					break;
				}
				case Terrasoft.Filter.ExpressionType.SCHEMA_COLUMN : {
					this.handleColumnMenuItemClick();
					break;
				}
				case Terrasoft.Filter.ExpressionType.MACROS : {
					this.showOnlyMacrosMenuItem(true);
					this.showMacrosMenu(this.macrosButton);
					break;
				}
			}
		}
	},

	showOnlyMacrosMenuItem: function(show) {
		var items = this.macrosButton.macrosMenu.items, item;
		for (var i =0, length = items.length; i < length; i += 1) {
			item = items.itemAt(i);
			if (item.tag != 'macros') {
				if (show) {
					item.hide();
				} else {
					item.show();
				}
			}
		}
	},

	getMenuItemByKey: function(menu, key) {
		var index = menu.items.indexOfKey(key);
		return menu.items.itemAt(index);
	},

	editFilterParameterValue: function(columnType, currentValue) {
		switch (columnType) {
			case 'Lookup':
				this.editLookupValue(currentValue);
				break;
			case 'Boolean':
				this.editBoolTypeValue(currentValue);
				break;
			default: 
				this.editSimpleTypeValue(currentValue);
		}
	},

	editLookupValue: function() {
		var key = this.id + '_' + Ext.id();
		key = key.replace(/-/g,'');
		referenceSchemaUId =  this.filter.leftExpression.referenceSchemaUId,
		Terrasoft.LookupGridPage.show(key, this, this.onLookupValueEditComplete, referenceSchemaUId);
	},

	editBoolTypeValue: function(currentValue) {
		this.filter.rightExpression.expressionType = Terrasoft.Filter.ExpressionType.PARAMETER;
		this.filter.rightExpression.parameterValues = [{ parameterValue: !currentValue }];
		this.filter.synchronize();
	},

	attachEditorToolButtonEventHandlers: function(editorWindow, menuItem) {
		var acceptToolButtonEl = Ext.getCmp(editorWindow.id + '_AcceptToolButton');
		if (acceptToolButtonEl) {
			acceptToolButtonEl.on('click', this.onAllowButtonClick, menuItem);
		}
		var cancelToolButtonEl = Ext.getCmp(editorWindow.id + '_CancelToolButton');
		if (cancelToolButtonEl) {
			cancelToolButtonEl.on('click', this.onCancelButtonClick, menuItem);
		}
	},

	editSimpleTypeValue: function (currentValue) {
		var xtype = this.getEditorXType(this.filter);
		var editorWindow = new Ext.menu.Menu({
			cls: "filter-value-editor"
		});
		var config = this.getEditorConfig(this.filter, editorWindow);
		var dataValueType = this.filter.rightExpression.dataValueType.name;
		if (xtype == 'textedit' && dataValueType == 'Guid') {
			config.validateValue = function(validationValue) {
				if (!Terrasoft.TextEdit.superclass.validateValue.call(this, validationValue)) {
					return false;
				}
				if(!Ext.ux.GUID.isGUID(validationValue)) {
					this.markInvalid();
					return false;
				}
				return true;
			};
		}
		var menuItem = new Terrasoft.EditMenuItem({
			xtype: xtype,
			config: config,
			value: currentValue,
			hideOnClick: false
		});
		editorWindow.add(menuItem);
		this.attachEditorToolButtonEventHandlers(editorWindow, menuItem);
		editorWindow.on("itemclick", this.handleRightExpressionEditComplete, this);
		editorWindow.on('hide', function() {
			editorWindow.destroy();
		}, this);
		editorWindow.show(this.rightExpressionValue.dom, "tl-bl?");
	},

	getEditorXType: function(filter){
		return filter.leftExpression.dataValueType.editor.controlXType;
	},
	
	getEditorToolsConfig: function(menu) {
		return [
			{ id: menu.id +"_AcceptToolButton", xtype: "toolbutton", 
				imageConfig: {source:"ResourceManager", resourceManagerName:"Terrasoft.UI.WebControls",
					resourceItemName:"filteredit-icon-apply-filters.png" }},
			{ id: menu.id + "_CancelToolButton", xtype: "toolbutton", 
				imageConfig: { source: "ResourceManager", resourceManagerName: "Terrasoft.UI.WebControls",
					resourceItemName: "filteredit-icon-cancel-filters.png"}
			}];
	},

	getEditorConfig: function (filter, menu) {
		var defaultConfiguration = filter.leftExpression.dataValueType.editor.defaultConfiguration;
		var config = Ext.isEmpty(defaultConfiguration) ? {} : Ext.decode(defaultConfiguration);
		config.toolsConfig = this.getEditorToolsConfig(menu);
		var xtype = this.getEditorXType(filter);
		var referenceSchemaUId = filter.leftExpression.referenceSchemaUId;
		config.required = true;
		switch (xtype) {
			case "lookupedit":
				config.lookupGridPageParams = {
					referenceSchemaUId: referenceSchemaUId
				};
				break;
			case "datetimeedit":
				if (config.kind == "datetime") {
					config.kind = "date";
				}
				break;
		}
		return config;
	},

	onCancelButtonClick: function (t, e) {
		this.parentMenu.hide();
		this.allowButtonClick = false;
	},
	
	onAllowButtonClick: function(el, e) {
		this.allowButtonClick = this.editor.validate();
	},

	handleRightExpressionEditComplete: function(item) {
		if (!item.editor || !item.allowButtonClick) {
			return false;
		}
		item.editor.unFocus();
		var editorValue = { 
			parameterValue: item.editor.getValue(),
			displayValue: item.editor.getDisplayValue()
		};
		if (this.isEmptyRightExpressionParameterValues()) {
			this.filter.rightExpression.expressionType = Terrasoft.Filter.ExpressionType.PARAMETER;
			this.filter.rightExpression.parameterValues = [ editorValue ];
		} else {
			var rightExpression = this.filter.rightExpression.parameterValues[0];
			Ext.apply(rightExpression, editorValue);
		}
		this.filter.synchronize();
		item.parentMenu.hide();
	},
	
	onLookupValueEditComplete: function(values, referenceSchemaUId) {
		var rightExpressions = [];
		var dataValue;
		var primaryDisplayColumnName;
		var primaryDisplayColumnValue;
		this.filter.rightExpression = this.filter.rightExpression || {};
		for (var i=0; i<values.length; i++) {
			dataValue = values[i].dataValue;
			primaryDisplayColumnName = values[i].primaryDisplayColumnName;
			primaryDisplayColumnValue = dataValue[primaryDisplayColumnName];
			rightExpressions.push({
				parameterValue: values[i].keyValue,
				displayValue: primaryDisplayColumnValue
			});
		}
		this.filter.rightExpression.expressionType = Terrasoft.Filter.ExpressionType.PARAMETER;
		this.filter.rightExpression.parameterValues = rightExpressions;
		this.filter.synchronize();
	},
	
	getFilterEditStringListItem:function(prefix, item) {
		var stringList = Ext.StringList('WC.FilterEdit');
		return stringList.getValue(prefix + '.' + item);
	},
	
	getComparisonTypeCaption: function(type) {
		return this.getFilterEditStringListItem('ComparisonType', type);
	},
	
	getAggregationTypeCaption: function(type) {
		return this.getFilterEditStringListItem('AggregationType', type);
	}
};

Terrasoft.FilterEdit.SelectionModel = function(cfg) {
	Ext.apply(this, cfg);
	this.addEvents(
		"selectionchange"
	);
	this.selectedItems = new Ext.util.MixedCollection(false, function(o) { return o.id; });
	Terrasoft.FilterEdit.SelectionModel.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.FilterEdit.SelectionModel, Ext.util.Observable, {

	subscribe: function(item, eventEl) {
		item.selectEl = eventEl;
		item.selectEl.on("click", this.onClick.createDelegate(this, [item], true), this);
	},
	
	unsubscribe: function(item) {
		item.selectEl.un("click", this.onClick.createDelegate(this, [item], true), this);
		delete item.selectEl;
	},
	
	onClick: function(e, el, t, item) {
		if ( !e.ctrlKey || this.isSelectOtherLevel(item)) {
			this.clearSelections();
		}
		if (e.ctrlKey && this.isSelected(item)) {
			this.unselect(item);
		} else {
			this.select(item);
		}
		this.fireEvent("selectionchange", this.selectedItems);
	},
	
	clearSelections: function() {
		var items = this.selectedItems.items;
		for (var i=items.length-1; i>=0; i--) {
			this.unselect(items[i]);
		}
	},
	
	isSelectOtherLevel: function(item) {
		return (this.selectedItems.length > 0) && (this.selectedItems.items[0].parentGroup != item.parentGroup);
	},
	
	isSelected: function(item) {
		return this.selectedItems.contains(item);
	},
	
	select: function(item) {
		item.selectEl.addClass("selected");
		this.selectedItems.add(item);
	},
	
	unselect: function(item) {
		item.selectEl.removeClass("selected");
		this.selectedItems.remove(item);
	}
});

Terrasoft.combobox.CultureDayOfWeekDataProvider = Ext.extend(Terrasoft.combobox.WebServiceDataProvider, {
	loadData: function() {
		var store = [];
		var days = Terrasoft.CultureInfo.dayNames;
		for (var i = Terrasoft.CultureInfo.startDay; i < 7; i++) {
			store.push([i+'', days[i]]);
		}
		for (i = 0; i < Terrasoft.CultureInfo.startDay; i++) {
			store.push([i+'', days[i]]);
		}
		var combobox = this.combobox;
		this.applySorting(combobox);
		combobox.loadData.defer(50, combobox, [store]);
		combobox.endProcessing();
	}
});

Ext.reg('culturedayofweekdataprovider', Terrasoft.combobox.CultureDayOfWeekDataProvider);

Terrasoft.combobox.CultureMonthsDataProvider = Ext.extend(Terrasoft.combobox.WebServiceDataProvider, {
	loadData: function() {
		var store = [];
		var months = Terrasoft.CultureInfo.monthNames;
		for (var i = 0; i < 12; i++) {
			store.push([(i+1)+'', months[i]]);
		}
		var combobox = this.combobox;
		this.applySorting(combobox);
		combobox.loadData.defer(50, combobox, [store]);
		combobox.endProcessing();
	}
});

Ext.reg('culturemonthsdataprovider', Terrasoft.combobox.CultureMonthsDataProvider);
