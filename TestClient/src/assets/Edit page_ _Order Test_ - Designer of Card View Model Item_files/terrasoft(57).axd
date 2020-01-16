Terrasoft.ScheduleEdit = function (cfg) {
	cfg = cfg || {};
	Ext.apply(this, cfg);
	Terrasoft.ScheduleEdit.superclass.constructor.call(this);
	this.initComponent();
};

Ext.extend(Terrasoft.ScheduleEdit, Terrasoft.SilverlightContainer, {
	xtype: 'scheduleedit',
	width: 300,
	height: 300,
	source: "/ClientBin/Terrasoft.UI.WindowsControls.Scheduler.xap",

	initComponent: function () {
		this.addEvents("taskdblclick");
		this.addEvents("createTask");
		this.parameters = {};
		this.parameters.source = this.source;
		this.on('onpluginloaded', this.onPluginLoaded, this);
		Terrasoft.ScheduleEdit.superclass.initComponent.call(this);
		this.initDataSouce();
		this.dataSourceLoaded = false;
	},

	onRender: function (ct, position) {
		Terrasoft.ScheduleEdit.superclass.onRender.call(this, ct, position);
		this.el.insertSibling({ tag: 'input', type: 'hidden', name: this.id + '_SE_StartDate', id: this.id +
			'_SE_StartDate'
		}, 'before', true);
		this.el.insertSibling({ tag: 'input', type: 'hidden', name: this.id + '_SE_EndDate', id: this.id +
			'_SE_EndDate'
		}, 'before', true);
	},

	initDataSouce: function () {
		var dataSource = this.dataSource;
		if (!dataSource) {
			return;
		}
		dataSource.on("inserted", this.onDataSourceInserted, this);
		dataSource.on("saved", this.onDataSourceSaved, this);
		dataSource.on("rowloaded", this.onDataSourceRowLoaded, this);
		dataSource.on("removed", this.onDataSourceRemoved, this);
		dataSource.on("loaded", this.onDataSourceLoaded, this);
	},

	removeTasks: function (rows) {
		var rows = this.scriptableObject.GetSelectedTasks();
		var dataSource = this.dataSource;
		var tasks = Ext.decode(rows);
		Ext.each(tasks, function (task, index) {
			var toRemove = new Object();
			toRemove.primaryColumnValue = task[dataSource.getPrimaryColumnName()];
			dataSource.remove(toRemove);
		});
	},

	addConfigs: function (configs) {
		configs = eval(configs);
		if (!this.configs) {
			this.configs = new Object();
		}
		for (var i = 0; i < configs.length; i++) {
			var config = configs[i];
			var configId = config.id;
			this.configs[configId] = config;
			delete config.id;
		}
		if (this.dataSourceLoaded) {
			this.onScheduleEditLoadData();
		}
	},

	setDisplayPeriod: function (startDate, endDate, timeStep) {
		if (this.isPluginLoaded() && this.scriptableObject) {
			this.scriptableObject.SetDisplayPeriod(Ext.encode(startDate), Ext.encode(endDate), Ext.encode(timeStep));
			delete this.startDate;
			delete this.endDate;
			delete this.timeStep;
		} else {
			this.startDate = startDate;
			this.endDate = endDate;
			this.timeStep = timeStep;
		}
	},

	exportToFile: function () {
		this.scriptableObject.OpenExportWindow();
	},

	onDataSourceLoaded: function (el, rows, cfg) {
		this.dataSourceLoaded = true;
		if (this.isPluginLoaded() && this.configs) {
			this.onScheduleEditLoadData();
		}
	},

	onDataSourceSaved: function (el, row, cfg) {
		if (this.isPluginLoaded()) {
			var item = row;
			var config = this.configs[item.columns[this.dataSource.getPrimaryColumnName()]];
			this.initializeImageResourcesUrl(config, this);
		    item.columns.config = config;
			this.scriptableObject.ForceUpdate(Ext.encode(row.columns));
		}
	},

	onDataSourceRowLoaded: function (el, row, cfg) {
		if (this.isPluginLoaded()) {
			var item = row[0];
			item.config = this.configs[item.Id];
			this.initializeImageResourcesUrl(item.config, this);
			this.scriptableObject.ForceUpdate(Ext.encode(item));
		}
	},

	onDataSourceRemoved: function (el, row, cfg) {
		if (this.isPluginLoaded() && this.scriptableObject) {
			this.scriptableObject.RemoveSelectedTasks(row);
		}
	},

	onPluginLoaded: function () {
		if (this.isPluginLoaded()) {
			this.loadLocalizableResources();
			this.scriptableObject.SetDataColumnNames(this.dataSource.getPrimaryColumnName(),
				this.startDateColumnName, this.dueDateColumnName, this.taskTextColumnName);
			if (this.startDate && this.endDate) {
				this.setDisplayPeriod(this.startDate, this.endDate, this.timeStep);
			}
			if (this.dataSourceLoaded && this.configs) {
				this.onScheduleEditLoadData();
			}
		}
	},

	onScheduleEditCustomEvent: function (sender, args) {
		var eventName = args.EventName;
		switch (eventName) {
			case "FocusedTaskChanged":
				this.updateActiveRow(Ext.decode(args.JsonStringData));
				break;
			case "TaskPropertiesChanged":
				this.updateTaskInformation(Ext.decode(args.JsonStringData));
				break;
			case "TaskDblClick":
				this.onScheduleEditTaskDoubleClick(Ext.decode(args.JsonStringData));
				break;
			case "FocusedPeriodChanged":
				this.onScheduleEditFocusedPeriodChanged(Ext.decode(args.JsonStringData));
				break;
			case "DirectlyCreateTask":
				this.onScheduleEditDirectlyCreeateTask(args.JsonStringData);
				break;
			case "TimeStepChanged":
				this.saveToProfile(Ext.decode(args.JsonStringData));
				break;
		}
	},

	onScheduleEditDirectlyCreeateTask: function (row) {
		this.fireEvent("createTask", row);
	},

	onScheduleEditFocusedPeriodChanged: function (period) {
		var startDate = Ext.get(this.id + '_SE_StartDate');
		var endDate = Ext.get(this.id + '_SE_EndDate');
		startDate.dom.value = Ext.encode(period["FocusedStartDate"]);
		endDate.dom.value = Ext.encode(period["FocusedEndDate"]);
	},

	updateActiveRow: function (task) {
		this.dataSource.setActiveRow(task[this.dataSource.getPrimaryColumnName()]);
	},

	updateTaskInformation: function (task) {
		var dataSource = this.dataSource;
		var row = dataSource.getRow(task[dataSource.getPrimaryColumnName()]);
		if (!row) {
			return;
		}
		dataSource.setActiveRow(row);
		if (task[this.startDateColumnName]) {
			var startDate = new Date(Date.parse(task[this.startDateColumnName]));
			dataSource.setColumnValue(this.startDateColumnName, startDate);
		}
		if (task[this.dueDateColumnName]) {
			var dueDate = new Date(Date.parse(task[this.dueDateColumnName]));
			dataSource.setColumnValue(this.dueDateColumnName, dueDate);
		}
		if (task[this.taskTextColumnName]) {
			var title = task[this.taskTextColumnName];
			dataSource.setColumnValue(this.taskTextColumnName, title);
		}
		dataSource.save();
	},

	onScheduleEditTaskDoubleClick: function (task) {
		this.fireEvent("taskdblclick", task[this.dataSource.getPrimaryColumnName()]);
	},

	getShortMonthNames: function () {
		if (!this.shortMonthNames) {
			this.shortMonthNames = Terrasoft.CultureInfo.shortMonthNames;
		}
		return this.shortMonthNames;
	},

	getMinutesCaption: function () {
		return Ext.StringList('WC.DateTime').getValue('Minutes.Minutes');
	},

	getExportWindowResources: function () {
		var exportWindowResources = new Object();
		exportWindowResources.MessageCaption = Ext.StringList('WC.Common').getValue('FormValidator.Warning');
		exportWindowResources.MessageText = Ext.StringList('WC.Common').getValue('FormValidator.RequiredFieldMessage');
		exportWindowResources.Title = Ext.StringList('WC.Common').getValue('ExportWindow.Title');
		exportWindowResources.FileFormat = Ext.StringList('WC.Common').getValue('ExportWindow.FileFormat');
		exportWindowResources.FileName = Ext.StringList('WC.Common').getValue('ExportWindow.FileName');
		exportWindowResources.ButtonCancel = Ext.StringList('WC.Common').getValue('Button.Cancel');
		exportWindowResources.ButtonOk = Ext.StringList('WC.Common').getValue('Button.Ok');
		exportWindowResources.Warning = Ext.StringList('WC.Common').getValue('FormValidator.Warning');
		exportWindowResources.RequiredFieldMessage = Ext.StringList('WC.Common').getValue('FormValidator.RequiredFieldMessage');
		return exportWindowResources;
	},

	getShortDayOfWeekNames: function () {
		if (!this.shortDayOfWeekNames) {
			var dayNames = {};
			var shortDayNames = Terrasoft.CultureInfo.shortDayNames;
			var dayPropertyNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
			for (var i = 0; i < 7; i++) {
				var propertyName = dayPropertyNames[i];
				dayNames[propertyName] = shortDayNames[i];
			}
			this.shortDayOfWeekNames = dayNames;
		}
		return this.shortDayOfWeekNames;
	},

	initializeImageResourcesUrl: function (itemConfig, scheduleEdit) {
		if (itemConfig.columnIcons) {
			var icons = itemConfig.columnIcons;
			for (var iconName in icons) {
				var wrapper = scheduleEdit.getImageConfigWrapper(icons[iconName]);
				wrapper.notWrap = true;
				icons[iconName] = Ext.ImageUrlHelper.getImageUrl(wrapper);
			}
		}
	},

	loadLocalizableResources: function () {
		var resources = new Object();
		resources.shortMonthNames = this.getShortMonthNames();
		resources.shortDayOfWeekNames = this.getShortDayOfWeekNames();
		resources.minutesCaption = this.getMinutesCaption();
		resources.exportWindowResources = this.getExportWindowResources();
		this.scriptableObject.LoadResources(Ext.encode(resources));
	},

	saveToProfile: function (data) {
		for (var param in data) {
			this.setProfileData(param, data[param]);
			this.setCustomData(param, data[param])
		}
	},
	onScheduleEditLoadData: function () {
		if (!this.isPluginLoaded() || !this.dataSourceLoaded || !this.configs) {
			return;
		}
		var rows = new Array();
		var configs = this.configs;
		var scheduleEdit = this;
		Ext.each(this.dataSource.rows.items, function (row, index) {
			var item = row.columns;
			item.config = configs[item.Id];
			scheduleEdit.initializeImageResourcesUrl(item.config, scheduleEdit);
			rows.push(item);
		});
		this.scriptableObject.LoadTasks(Ext.encode(rows));
		this.dataSourceLoaded = false;
	}
});
Ext.reg("scheduleedit", Terrasoft.ScheduleEdit);
