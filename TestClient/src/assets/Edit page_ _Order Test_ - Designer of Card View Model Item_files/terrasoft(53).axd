Terrasoft.ObjectInspector = Ext.extend(Terrasoft.ControlLayout, {
	isReadOnly: false,
	direction: 'vertical',
	objectInfo: null,
	objectInfoField: null,
	viewName: 'Properties',
	viewNameField: null,
	properties: null,
	viewButtonsMode: 'Object',
	toolbar: null,
	toolbarLayout: null,
	propertiesLayout: null,
	descriptionLayout: null,
	descriptionEdit: null,
	editors: [],
	levelIdent: 5,
	startNewAlignGroup: true,
	isDescriptionVisible: false,
	isGroupButtonVisible: true,
	isSortingButtonVisible: true,
	generalGroupName: "general",
	sortingTypes: new Array('Alphabet', 'Position'),
	sortingType: 'Position',
	useGroups: true,
	startUseGroups: true,
	collapseGoups: false,
	displayProperties: new Array('General', 'Availiable'),
	displayProperty: 'General',
	startDisplayProperty: 'General',
	fitHeightByContent: false,
	maxCaptionWidth: '150',
	useFilter: false,
	filterValue: '',

	initComponent: function() {
		Terrasoft.ObjectInspector.superclass.initComponent.call(this);
		this.addEvents(
			'propertychange',
			'viewchange',
			'designmodeusagetypechange',
			'eventeditorrequest'
		);
		if ((this.viewButtonsMode != 'None') || this.isGroupButtonVisible || this.isSortingButtonVisible) {
			this.addToolbar();
		}
		this.propertiesLayout = new Terrasoft.ControlLayout({
			id: this.id + '_properties',
			direction: 'vertical',
			layoutConfig: { defaultMargins: '3 3 0 5', padding: '0 0 10 0' },
			height: '100%',
			width: '100%',
			autoScroll: true,
			hasSplitter: true,
			maxCaptionWidth: this.maxCaptionWidth,
			margins: "0 0 0 0",
			fitHeightByContent: this.fitHeightByContent
		});
		this.add(this.propertiesLayout);
		if (this.isDescriptionVisible) {
			this.addDescriptionControl();
		}
		if (this.classDescriptor) {
			this.setClassDescriptor(this.classDescriptor, this.isReadOnly);
		}
		this.startUseGroups = this.useGroups;
		this.startDisplayProperty = this.displayProperty;
	},

	addToolbar: function() {
		this.toolbar = new Terrasoft.ControlLayout({
			width: '100%',
			displayStyle: 'topbar',
			edges: '0 0 1 0'
		});
		this.toolbar.on('render', this.onToolbarRender, this);
		this.add(this.toolbar);
	},

	addDescriptionControl: function() {
		this.descriptionLayout = new Terrasoft.ControlLayout({
			id: this.id + '_description',
			width: '100%',
			height: 45
		});
		this.add(this.descriptionLayout);
		this.descriptionEdit = new Terrasoft.MemoEdit({
			useDefTools: false,
			readOnly: true,
			height: '100%',
			width: '100%'
		});
		this.descriptionLayout.add(this.descriptionEdit);
	},

	getDisplaySettingsMenu: function() {
		var displaySettingsMenu = new Ext.menu.Menu();
		var objectInspectorStringList = Ext.StringList('WC.ObjectInspector');
		if (this.isSortingButtonVisible) {
			displaySettingsMenu.addItem(new Ext.menu.Separator({ caption:
				objectInspectorStringList.getValue('DisplaySettings.Sorting')
			}));
			var sortingTypes = this.sortingTypes;
			for (var i = 0, itemsCount = sortingTypes.length; i < itemsCount; i++) {
				var sortingType = sortingTypes[i];
				displaySettingsMenu.add({
					id: sortingType,
					scope: this,
					caption: objectInspectorStringList.getValue('DisplaySettings.PropertySortingType.'
						+ sortingType),
					checked: this.sortingType == sortingType,
					group: 'SortingTypes',
					handler: this.onSortingMenuClick
				});
			}
		}
		if (this.isGroupButtonVisible) {
			displaySettingsMenu.addItem(new Ext.menu.Separator({ caption:
				objectInspectorStringList.getValue('DisplaySettings.Grouping')
			}));
			displaySettingsMenu.add({
				scope: this,
				caption: objectInspectorStringList.getValue('DisplaySettings.UseGroups'),
				checked: this.useGroups,
				handler: this.onGroupingMenuClick
			});
			displaySettingsMenu.add({
				scope: this,
				id: 'psdObjectInspector_сollapseGroups_id',
				caption: objectInspectorStringList.getValue('DisplaySettings.CollapseGroups'),
				enabled: this.useGroups,
				//checked: this.useGroups, collapseGoups
				handler: function () { this.onGroupsCollapseChacnge(true) }
			});
			displaySettingsMenu.add({
				scope: this,
				id: 'psdObjectInspector_expandGroups_id',
				caption: objectInspectorStringList.getValue('DisplaySettings.ExpandGroups'),
				enabled: this.useGroups,
				//checked: this.useGroups,
				handler: function () {
					this.onGroupsCollapseChacnge(false);
				}
			});
		}
		displaySettingsMenu.addItem(new Ext.menu.Separator({ caption:
				objectInspectorStringList.getValue('DisplaySettings.DisplayProperties')
		}));
		var displayProperties = this.displayProperties;
		for (var i = 0, itemsCount = displayProperties.length; i < itemsCount; i++) {
			var displayProperty = displayProperties[i];
			displaySettingsMenu.add({
				id: displayProperty,
				scope: this,
				caption: objectInspectorStringList.getValue('DisplaySettings.DisplayProperty.' + displayProperty),
				checked: this.displayProperty == displayProperty,
				group: 'DisplayProperties',
				handler: this.onDesignModeUsageTypeClick
			});
		}
		return displaySettingsMenu;
	},

	onGroupsCollapseChacnge: function(collapseGroups) {
		if (this.collapseGoups != collapseGroups) {
			this.collapseGoups = collapseGroups;
			this.rebuild();
		} else {
			if (!this.useGroups) {
				return;
			}
			var items = this.propertiesLayout.items;
			for (var i = 0; i < items.length; i++) {
				var layout = items.itemAt(i);
				if (layout.collapsed != collapseGroups) {
					this.collapseGoups = collapseGroups;
					this.rebuild();
					return;
				}
			}
		}
	},

	onGroupingMenuClick: function(menuItem) {
		Ext.getCmp('psdObjectInspector_сollapseGroups_id').setDisabled(menuItem.checked);
		Ext.getCmp('psdObjectInspector_expandGroups_id').setDisabled(menuItem.checked);
		this.enableGrouping(!menuItem.checked);
	},

	onSortingMenuClick: function(menuItem) {
		this.sortingMenuClick(menuItem);
	},

	onDesignModeUsageTypeClick: function(menuItem) {
		this.changeDesignModeUsageType(menuItem.id);
	},

	filterProperties: function(filterValue) {
		this.filterValue = filterValue;
		this.showLoadMask();
		var changeUserType;
		if (Ext.isEmpty(filterValue)) {
			this.useFilter = false;
			this.useGroups = this.startUseGroups;
			if (this.displayProperty != this.startDisplayProperty) {
				this.displayProperty = this.startDisplayProperty;
				changeUserType = true;
			}
		} else {
			this.useGroups = false;
			this.useFilter = true;
			if (this.displayProperty != 'Availiable') {
				changeUserType = true;
				this.displayProperty = 'Availiable';
			}
		}
		if (changeUserType) {
			this.fireEvent('designmodeusagetypechange', this.displayProperty);
			return;
		}
		this.rebuild();
	},

	onSearchEditSpecialKey: function(el, e) {
		var key = e.getKey();
		var text = el.getValue();
		switch (key) {
			case e.ESC :
				text = '';
				el.setValue('');
			case e.ENTER :
				this.filterProperties(text);
				break;
			default:
				return;
		}
		if (this.useFilter) {
			el.getEl().addClass('x-qf-text');
			el.tools[0].show();
		} else {
			el.getEl().removeClass('x-qf-text');
			el.tools[0].hide();
		}
	},

	onObjcetInspectorClearFilter: function(el) {
		var searchEdit = this.toolbar.items.itemAt(0);
		searchEdit.setValue('');
		searchEdit.getEl().removeClass('x-qf-text');
		el.hide();
		this.filterProperties('');
	},

	onToolbarRender: function() {
		var searchEdit = new Terrasoft.TextEdit({
			scope: this,
			width: '100%',
			emptyText: Ext.StringList('WebApp.Common').getValue('SearchEmptyText.Caption'),
			alignedByCaption: false,
			toolsConfig: {
				id: this.id + '_clear_filter_toolbutton',
				xtype:"toolbutton",
				hidden: true,
				imageConfig: {
					source: "ResourceManager",
					resourceManagerName: "Terrasoft.UI.WebControls",
					resourceItemName: "toolbutton-close.gif"
				}
			}
		});
		searchEdit.tools[0].on('click', this.onObjcetInspectorClearFilter, this);
		searchEdit.on('specialkey', this.onSearchEditSpecialKey, this);
		this.toolbar.add(searchEdit);
		if (this.viewButtonsMode != 'None') {
			this.toolbar.add(new Ext.Spacer({stripeVisible: true}));
			this.toolbar.add(new Terrasoft.Button({
				imageList: 'Terrasoft.UI.WebControls',
				imageName: 'properties.png',
				imageAsSprite: false,
				scope: this,
				enableToggle: true,
				toggleGroup: this.id + 'objectInspector',
				pressed: true,
				viewName: 'Properties',
				handler: function(button) { this.changeView(button.viewName); }
			}));
		}
		if (this.viewButtonsMode == 'AjaxControl') {
			this.toolbar.add(new Terrasoft.Button({
				scope: this,
				imageList: 'Terrasoft.UI.WebControls',
				imageName: 'events.png',
				imageAsSprite: false,
				enableToggle: true,
				toggleGroup: this.id + 'objectInspector',
				viewName: 'AjaxEvents',
				handler: function(button) { this.changeView(button.viewName); }
			}));
		}
		if (this.isGroupButtonVisible || this.isSortingButtonVisible) {
			this.toolbar.add(new Ext.Spacer({stripeVisible: true}));
			this.toolbar.add(new Terrasoft.Button({
				scope: this,
				imageList: 'Terrasoft.UI.WebControls',
				imageAsSprite: false,
				imageName: 'config.png',
				menu: this.getDisplaySettingsMenu()
			}));
		}
	},

	changeView: function(viewName) {
		this.setViewName(viewName);
		this.fireEvent("viewchange", viewName);
		this.rebuild();
	},

	enableGrouping: function(enable) {
		this.useGroups = enable;
		this.startUseGroups = this.useGroups;
		this.rebuild();
	},

	sortingMenuClick: function(item) {
		this.setSorting(item.id);
	},

	setSorting: function(sortingType) {
		this.sortingType = sortingType;
		this.rebuild();
	},

	changeDesignModeUsageType: function(designModeUsageType) {
		this.startDisplayProperty = designModeUsageType;
		if (!this.useFilter) {
			this.displayProperty = designModeUsageType;
			this.fireEvent('designmodeusagetypechange', designModeUsageType);
		}
	},

	getViewNameField: function() {
		if (!this.viewNameField) {
			this.viewNameField = Ext.get(this.id + '_ViewName').dom;
		}
		return this.viewNameField;
	},

	setViewName: function(viewName) {
		this.viewName = viewName;
		this.getViewNameField().value = viewName;
	},

	getGeneralGroupIndex: function(groups) {
		for (var i = 0, groupCount = groups.length; i < groupCount; i++) {
			if (groups[i].Name == this.defaultGroupName) {
				return i;
			}
		}
	},

	moveAllPropertiesToGeneralGroup: function(groups) {
		var items = new Array();
		for (var i = 0, groupCount = groups.length; i < groupCount; i++) {
			items = items.concat(groups[i].items);
		}
		var groups = new Array();
		var group = new Object();
		var generalGroupIndex = this.getGeneralGroupIndex(groups);
		Ext.apply(group, groups[generalGroupIndex]);
		group.items = items;
		groups.push(group);
		return groups;
	},

	getAllPropertiesArray: function() {
		var classDescriptor = new Object();
		Ext.apply(classDescriptor, this.classDescriptor);
		var groups = classDescriptor.propertyGroups;
		var items = new Array();
		for (var i = 0, groupCount = groups.length; i < groupCount; i++) {
			items = items.concat(groups[i].items);
		}
		groups = classDescriptor.eventGroups;
		for (var i = 0, groupCount = groups.length; i < groupCount; i++) {
			items = items.concat(groups[i].items);
		}
		return items;
	},

	prepareClassDescriptor: function(classDescriptor, sortingType, useGroups) {
		var sortingFunction = (sortingType == 'Alphabet') ? this.sortByCaption : this.sortByPosition;
		if (!useGroups) {
			classDescriptor.groups = this.moveAllPropertiesToGeneralGroup(classDescriptor.groups);
		} else {
			classDescriptor.groups = classDescriptor.groups.sort(sortingFunction);
		}
		var group;
		for (var i = 0, groupCount = classDescriptor.groups.length; i < groupCount; i++) {
			group = classDescriptor.groups[i];
			group.items = group.items.sort(sortingFunction);
		}
	},

	sortByCaption: function(a, b) {
		return a.caption < b.caption ? -1 : 1;
	},

	sortByPosition: function(a, b) {
		if (((a.position == undefined) && (b.position == undefined)) || (a.position == b.position)) {
			return a.caption > b.caption ? 1 : -1;
		} else if (a.position == undefined) {
			return 1;
		} else if (b.position == undefined) {
			return -1;
		} else {
			return a.position > b.position ? 1 : -1;
		}
	},

	cloneDescriptorGroups: function(descriptorGroups) {
		var groups = new Array();
		for (var i = 0; i < descriptorGroups.length; i++) {
			var descriptorGroup = descriptorGroups[i]
			var group = new Object();
			group.name = descriptorGroup.name;
			group.caption = descriptorGroup.caption;
			group.position = descriptorGroup.position;
			group.items = new Array();
			for (var j = 0; j < descriptorGroup.items.length; j++) {
				group.items[j] = new Object();
				Ext.apply(group.items[j], descriptorGroup.items[j]);
			}
			groups[i] = group;
		}
		return groups;
	},

	rebuild: function(classDescriptor) {
		if (classDescriptor) {
			this.classDescriptor = classDescriptor;
		}
		// TODO Из-за того, что при первой загрузке страницы в ObjectInspectore не видны св-ва
		// для Page - this.classDescriptor = undefined и возникает ошибка при обращении к propertyGroups
		if (this.classDescriptor == undefined) {
			return;
		}
		this.showLoadMask();
		this.clear();
		if (!this.propertyDataSource.hasListener("removed")) {
			this.propertyDataSource.on('removed', this.clear, this);
		}
		var classDescriptor = new Object();
		if (this.viewName == 'Properties') {
			classDescriptor.groups = this.cloneDescriptorGroups(this.classDescriptor.propertyGroups)
		} else {
			classDescriptor.groups = this.cloneDescriptorGroups(this.classDescriptor.eventGroups)
		}
		this.prepareClassDescriptor(classDescriptor, this.sortingType, this.useGroups);
		this.forceProcessHandlers();
		this.createPropertyEditors(this.propertiesLayout, classDescriptor, 0, true);
		this.calculateControlsCaptionWidth();
		if (!this.rendered) {
			return;
		}
		this.doLayout();
		this.hideLoadMask();
	},

	getObjectInfoField: function() {
		if (!this.objectInfoField) {
			this.objectInfoField = Ext.get(this.id + '_ObjectInfo').dom;
		}
		return this.objectInfoField;
	},

	setObjectInfo: function(objectInfo) {
		this.objectInfo = objectInfo;
		this.getObjectInfoField().value = objectInfo;
	},

	clear: function(inContentUpdate) {
		if (!this.classDescriptor) {
			return;
		}
		this.editors = [];
		this.propertiesLayout.removeControls();
		if (inContentUpdate != true) {
			this.propertiesLayout.doLayout();
		}
		if (this.propertyDataSource.hasListener("removed")) {
			this.propertyDataSource.un('removed', this.clear, this);
		}
	},

	addPropertyGroup: function(group, layout) {
		var propertyGroupLayout = new Terrasoft.ControlLayout({
			id: group.name + '_group',
			direction: 'vertical',
			width: '100%',
			layoutConfig: { defaultMargins: '3 3 0 5' },
			fitHeightByContent: true,
			caption: group.caption,
			maxCaptionWidth: layout.maxCaptionWidth,
			isCollapsible: true,
			collapsed: this.collapseGoups,
			margins: "0 0 5 5"
		});
		layout.add(propertyGroupLayout);
		return propertyGroupLayout;
	},

	createPropertyEditors: function(layout, classDescriptor, level, inContentUpdate) {
		var item, group, controlsLayout;
		var useFilter = this.useFilter;
		var filterValue = this.filterValue;
		if (level == 0) {
			for (var i = 0, groupCount = classDescriptor.groups.length; i < groupCount; i++) {
				group = classDescriptor.groups[i];
				if (this.useGroups) {
					controlsLayout = this.addPropertyGroup(group, layout);
				} else {
					controlsLayout = layout;
				}
				for (var j = 0, itemCount = group.items.length; j < itemCount; j++) {
					item = group.items[j];
					if (item.viewName != this.viewName) {
						continue;
					}
					if (useFilter && !(item.caption.toLowerCase().search(filterValue.toLowerCase()) != -1 ||
						item.name.toLowerCase().search(filterValue.toLowerCase()) != -1)) {
						continue;
					}
					this.createPropertyEditor(item, controlsLayout, level, -1, inContentUpdate);
				}
			}
		} else {
			for (var i = 0, itemCount = classDescriptor.length; i < itemCount; i++) {
				item = classDescriptor[i];
				if (item.viewName != this.viewName) {
					continue;
				}
				this.createPropertyEditor(item, layout, level, -1, inContentUpdate);
			}
		}
	},

	createPropertyEditor: function(item, layout, level, index, inContentUpdate) {
		var editor = this.getPropertyEditor(item, level);
		if (!editor) {
			return null;
		}
		if (index != -1) {
			layout.insert(index, editor);
		} else {
			layout.add(editor);
		}
		return editor;
	},

	getPropertyEditor: function(item, level) {
		var propertyType = item.extendedPropertyType || item.propertyType;
		item.isVisible = (item.isVisible != false);
		if (item.isVisible == false) {
			return null;
		}
		var editor;
		// TODO Временная реализация. Удалить, когда будет продумано как должны работать редакторы для событий
		if (this.viewName == "AjaxEvents") {
			propertyType = 'String';
		}
		try {
			var editorConfig = this.getDefaultEditorConfig(item, this.propertyDataSource);
			editorConfig.ignoreDataSourceProperties = true;
			if (item.editor !== undefined) {
				this.applyEditorConfig(editorConfig, item.editor);
				editor = Ext.ComponentMgr.create(editorConfig);
				if (editor.dataProvider) {
					editor.dataProvider = Ext.ComponentMgr.create({
						xtype: editor.dataProvider
					});
					var dataProvider = editor.dataProvider;
					var provider = item.provider;
					dataProvider.dataService = provider.DataService;
					dataProvider.dataGetMethod = provider.DataGetMethod;
					dataProvider.filters = provider.filters;
				}
			} else {
				switch (propertyType) {
					case 'String':
						editor = this.getStringEditor(editorConfig, item);
						break;
					case 'Integer':
						editor = new Terrasoft.IntegerEdit(editorConfig);
						break;
					case 'Numeric':
						editor = new Terrasoft.FloatEdit(editorConfig);
						break;
					case 'Decimal':
						editor = new Terrasoft.FloatEdit(editorConfig);
						break;
					case 'Date':
						defConfig.type = 'date';
						editor = new Terrasoft.DateTimeEdit(editorConfig);
						break;
					case 'Time':
						defConfig.type = 'time';
						editor = new Terrasoft.DateTimeEdit(editorConfig);
						break;
					case 'DateTime':
						editorConfig.type = 'datetime';
						editorConfig.controlsSpacingWidth = 1;
						editor = new Terrasoft.DateTimeEdit(editorConfig);
						break;
					case 'Boolean':
						editorConfig.captionPosition = 'left';
						editor = new Terrasoft.CheckBox(editorConfig);
						return;
					case 'Color':
						editorConfig.displayMode = 'Both';
						editor = new Terrasoft.ColorEdit(editorConfig);
						break;
					case 'List':
						editor = this.getListEditor(editorConfig, item);
						break;
					case 'LocalizableString':
						item.values = item.childrenProperties;
						editor = new Terrasoft.LocalizableTextEdit(editorConfig);
						break;
					case 'LocalizableImage':
						item.values = item.childrenProperties;
						editor = new Terrasoft.FileUploadEdit(editorConfig);
						break;
					case 'Unit':
						editorConfig.controlsSpacingWidth = 1;
						editorConfig.allowEmpty = true;
						editor = new Terrasoft.UnitEdit(editorConfig);
						break;
					case 'Object':
						editorConfig.enabled = false;
						editor = new Terrasoft.TextEdit(editorConfig);
						break;
					default:
						editor = new Terrasoft.TextEdit(editorConfig);
						break;
				}
			}
		} finally {
			item.isEnabled = (item.isEnabled != false) && !this.isReadOnly && editor.enabled;
			editor.on('focus', this.onEditorFocus, this);
			editor.enabled = item.isEnabled;
			editor.objectInspectorProperty = item;
			editor.objectInspectorPropertyLevel = level;
			this.editors.push(editor);
			return editor;
		}
	},

	getDefaultEditorConfig: function(item, dataSource) {
		var config = {
			width: '100%',
			caption: item.caption,
			dataSource: dataSource,
			columnName: item.name,
			required: item.required,
			readOnly: item.readOnly,
			enabled: !item.disabled
		}
		return config;
	},
	
	applyEditorConfig: function(config, editor) {
		var properties = editor.split(";");
		for (var i=0; i<properties.length; i++){
			var property = properties[i].split("=");
			if (property.length == 2){
				var name = property[0];
				var value = property[1];
				config[name] = value;
			}
		}
	},

	onAjaxEventSetValue: function(value) {
		Ext.form.TextField.superclass.setRawValue.call(this, value);
		var row = this.dataSource.activeRow;
		if (!row) {
			return;
		}
		var eventHandled = row.getColumnValue(this.eventName + '_Handled');
		if (eventHandled == 'true') {
			this.el.setStyle('background', '#F8F2EC');
		}
		if (this.showLoadMaskEnable) {
			var showLoadMask = row.getColumnValue(this.eventName + '_ShowLoadMask');
			var showLoadMaskMenuItem = this.tools[1].menu.items.items[2];
			showLoadMaskMenuItem.setChecked(showLoadMask, true);
		}
	},

	onRemoveEventHandler: function(editor) {
		var eventName = editor.eventName;
		var row = editor.dataSource.activeRow;
		var eventHandled = row.getColumnValue(eventName + '_Handled');
		if (eventHandled == 'false') {
			return;
		}
		editor.setValue('');
		editor.checkChange();
		row.setColumnValue(eventName + '_Handled', 'false');
		this.fireEvent("eventeditorrequest", eventName, false);
		editor.el.setStyle('background', 'white');
	},

	onShowLoadMaskHandler: function(editor, checked) {
		var eventName = editor.eventName;
		var showLoadMask = checked;
		editor.dataSource.setColumnValue(eventName + '_ShowLoadMask', showLoadMask);
		this.fireEvent("eventeditorrequest", eventName, false);
	},

	getStringEditor: function(defConfig, item) {
		var editor;
		if (this.viewName == 'AjaxEvents') {
			var eventName = item.name;
			var toolButtonMenu = new Ext.menu.Menu();
			toolButtonMenu.addMenuItem({
				id: this.id + item.id + eventName,
				caption: Ext.StringList('WC.ObjectInspector').getValue('AjaxEvents.DeleteEventHandler'),
				eventName: eventName,
				dataSource: defConfig.dataSource,
				columnName: item.name
			});
			var showLoadMaskEnable = defConfig.dataSource.hasColumn(eventName + '_ShowLoadMask');
			if (showLoadMaskEnable)
			{
				toolButtonMenu.addSeparator();
				toolButtonMenu.addMenuItem({
					id: this.id + item.id + eventName + '_showLoadMask',
					tag: 'showLoadMask',
					caption: Ext.StringList('WC.ObjectInspector').getValue('AjaxEvents.ShowLoadMask'),
					eventName: eventName,
					checked: false,
					dataSource: defConfig.dataSource,
					columnName: item.name
				});
			}
			defConfig.toolsConfig = [{
				xtype: "toolbutton",
				imageCls: "x-form-flash-toolbutton"
			},
			{
				xtype: "toolbutton",
				imageConfig: {
					source: 'ResourceManager',
					resourceManagerName: 'Terrasoft.UI.WebControls',
					resourceItemName: 'combobox-ico-btn-select.gif'
				},
				menu: toolButtonMenu
			}];
			defConfig.setValue = this.onAjaxEventSetValue;
			editor = new Terrasoft.TextEdit(defConfig);
			editor.readOnly = true;
			editor.eventName = eventName;
			var handler = this.onEventEditorButtonClick.createDelegate(this, [editor]);
			var removeEventHandler = this.onRemoveEventHandler.createDelegate(this, [editor]);
			var menuItem = Ext.getCmp(this.id + item.id + eventName);
			editor.showLoadMaskEnable = false;
			menuItem.on('click', removeEventHandler);
			if (showLoadMaskEnable) {
				editor.showLoadMaskEnable = true;
				var showLoadMaskHandler = this.onShowLoadMaskHandler.createDelegate(this, [editor], true);
				var showLoadMaskMenuItem = Ext.getCmp(this.id + item.id + eventName + '_showLoadMask');
				showLoadMaskMenuItem.on('checkchange', showLoadMaskHandler);
			}
			editor.tools[0].on('click', handler);
			editor.on('dblclick', handler);
		} else {
			editor = new Terrasoft.TextEdit(defConfig);
		}
		return editor;
	},

	getListEditor: function(defConfig, property) {
		defConfig.strictedToItemsList = true;
		if (property.allowEmpty !== undefined) {
			defConfig.allowEmpty = property.allowEmpty;
		} else {
			defConfig.allowEmpty = property.provider.filters[0][0] != 'EnumType';
		}
		defConfig.checkColumnAccess = false;
		//// TODO Должен ли editor быть глобальным
		editor = new Terrasoft.ComboBox(defConfig);
		editor.dataProvider = new Terrasoft.combobox.WebServiceDataProvider({
			dataService: property.provider.DataService,
			dataGetMethod: property.provider.DataGetMethod
		});
		editor.dataProvider.filters = property.provider.filters;
		return editor;
	},

	findParentProperties: function(parentPath) {
		var items = this.properties;
		if (parentPath) {
			var parents = parentPath ? parentPath.split('|') : [];
			for (var i = 0; i < parents.length; i++) {
				var parentProperty = this.findPropertyInArray(parents[i], items);
				if (!parentProperty) {
					return null;
				}
				items = parentProperty.childrenProperties;
			}
		}
		return items;
	},

	findProperty: function(propertyName, parentPath) {
		var items = this.findParentProperties(parentPath);
		if (!items) {
			return null;
		}
		return this.findPropertyInArray(propertyName, items);
	},

	findPropertyIndex: function(item, parentPath) {
		var items = this.findParentProperties(parentPath);
		if (!items) {
			return -1;
		}
		return items.indexOf(item);
	},

	findPropertyInArray: function(propertyName, items) {
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			if (item.name == propertyName) {
				return item;
			}
		}
		return null;
	},

	findPropertyEditor: function(item) {
		for (var i = 0; i < this.editors.length; i++) {
			var editor = this.editors[i];
			if (editor.objectInspectorProperty == item) {
				return editor;
			}
		}
		return null;
	},

	findParentsLayout: function(parents) {
		var layout = this.propertiesLayout;
		for (var i = 0; i < parents.length; i++) {
			var parentName = parents[i];
			for (var j = 0; j < layout.items.length; j++) {
				var item = layout.items.items[j];
				if (item.objectInspectorProperty.name == parentName) {
					layout = item;
					break;
				}
			}
		}
		return layout;
	},

	setPropertyIsEnabled: function(propertyName, parentPath, value) {
		var item = this.findProperty(propertyName, parentPath);
		if ((!item) || (item.isEnabled == value)) {
			return;
		}
		item.isEnabled = value;
		var editor = this.findPropertyEditor(item);
		if (editor) {
			editor.setEnabled(value);
		}
	},

	setPropertyIsVisible: function(propertyName, parentPath, value) {
		var item = this.findProperty(propertyName, parentPath);
		if ((!item) || ((item.isVisible != false) == value)) {
			return;
		}
		item.isVisible = value;
		var editor;
		if (value) {
			var parents = parentPath ? parentPath.split('|') : [];
			editor = this.createPropertyEditor(item, this.findParentsLayout(parents), parents.length, this.findPropertyIndex(item, parentPath), false);
			if (editor) {
				editor.ownerCt.doLayout();
			}
		} else {
			editor = this.findPropertyEditor(item);
			if (editor) {
				this.editors.splice(this.editors.indexOf(editor), 1);
				var ownerCt = editor.ownerCt;
				ownerCt.removeControl(editor);
				ownerCt.doLayout();
			}
		}
	},

	refreshPropertyList: function(propertyName, parentPath, filterName, value) {
		var item = this.findProperty(propertyName, parentPath);
		if ((!item) || (!item.provider)) {
			return;
		}
		var filters = [];
		filters.push(filterName, value);
		item.provider.filters = filters;
		var editor = this.findPropertyEditor(item);
		if (editor) {
			editor.clearValue(true);
			editor.unprepareList();
			editor.dataProvider.filters = filters;
		}
	},

	setPropertyValue: function(propertyName, parentPath, value) {
		var item = this.findProperty(propertyName, parentPath);
		if (!item) {
			return;
		}
		var editor = this.findPropertyEditor(item);
		if (editor) {
			editor.setValue(value);
		}
	},

	getPropertyPath: function(editor) {
		if (!editor.objectInspectorProperty) {
			return '';
		}
		var parentPath = this.getPropertyPath(editor.ownerCt);
		if (parentPath) {
			parentPath = parentPath + '|';
		}
		return parentPath + editor.objectInspectorProperty.name;
	},

	onEditorFocus: function(editor) {
		descriptionEdit = this.descriptionEdit;
		if (descriptionEdit) {
			descriptionEdit.setValue(editor.objectInspectorProperty.description || editor.objectInspectorProperty.caption);
		}
	},

	onEventEditorButtonClick: function(editor) {
		var eventName = editor.eventName;
		var row = editor.dataSource.activeRow;
		var signalName = row.getColumnValue('Name') + eventName;
		row.setColumnValue(eventName + '_Handled', 'true');
		editor.startValue = '-1';
		editor.setValue(signalName);
		editor.checkChange();
		editor.el.setStyle('background', '#F8F2EC');
	},

	processHandlers: function(handlers, value, oldValue, oldValuesEqual) {
		if (!handlers) {
			return;
		}
		for (var i = 0; i < handlers.length; i++) {
			var handler = handlers[i];
			var values = handler.Values ? handler.Values.split(',') : null;
			var valueEqual = false;
			var oldValueEqual = oldValuesEqual;
			if (values && values.length > 0) {
				for (var j = 0; j < values.length; j++) {
					if (String(value) == values[j]) {
						valueEqual = true;
					}
					if (String(oldValue) == values[j]) {
						oldValueEqual = true;
					}
				}
			} else {
				valueEqual = true;
			}
			var twoDirectional = (handler.TwoDirectional != false);
			if (valueEqual || (twoDirectional && oldValueEqual)) {
				this.processHandler(handler, valueEqual, value, oldValuesEqual);
			}
		}
	},

	processHandler: function(handler, valueEqual, value, initialValue) {
		var isAccessebilityAction = (handler.Action == "SetIsEnabled" || handler.Action == "SetIsVisible");
		if (initialValue && !isAccessebilityAction) {
			return;
		}
		var items = handler.DependedProperties.split(',');
		var actionValue = (handler.Action == "RefreshList") ? value : (handler.ActionValue == "True");
		if (!valueEqual) {
			actionValue = isAccessebilityAction ? !actionValue : '';
		}
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			switch (handler.Action) {
				case "SetIsEnabled":
					this.setPropertyIsEnabled(item, '', actionValue);
					break;
				case "SetIsVisible":
					this.setPropertyIsVisible(item, '', actionValue);
					break;
				case "SetValue":
					this.setPropertyValue(item, '', actionValue);
					break;
				case "RefreshList":
					this.refreshPropertyList(item, '', handler.ListFilterName, actionValue);
					break;
			}
		}
	},

	forceProcessHandlers: function() {
		if (!this.classDescriptor) {
			return;
		}
		var groups = this.classDescriptor[this.viewName == 'Properties' ? 'propertyGroups' : 'eventGroups'];
		for (var i = 0, groupCount = groups.length; i < groupCount; i++) {
			var group = groups[i];
			for (var j = 0, itemCount = group.items.length; j < itemCount; j++) {
				var item = group.items[j];
				//TODO Check view
				this.processHandlers(item.handlers, item.value, null, true);
			}
		}
	},

	initializeLoadMask: function() {
		var container = this.propertiesLayout.el;
		this.loadMask = new Ext.LoadMask(container, { extCls: 'blue', fitToElement: true });
	},

	showLoadMask: function() {
		if (!this.rendered) {
			return;
		}
		if (!this.loadMask) {
			this.initializeLoadMask();
		}
		this.loadMask.show();
	},

	hideLoadMask: function() {
		if (this.loadMask) {
			this.loadMask.hide();
		}
	}

});

Ext.reg("objectinspector", Terrasoft.ObjectInspector);

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}