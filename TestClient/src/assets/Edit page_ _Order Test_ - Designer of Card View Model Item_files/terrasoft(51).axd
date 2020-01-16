Terrasoft.LocalizableTextEdit = Ext.extend(Terrasoft.TextEdit, {
	fieldClass: "x-form-field x-form-localizable-text",
	memoHeight: 45,
	value: {
		currentCultureName: '',
		values: []
	},
	values: [],
	
	initComponent: function() {
		Terrasoft.LocalizableTextEdit.superclass.initComponent.call(this);
		this.primaryToolButtonConfig = { 
			id: this.primaryToolButtonId(),
			imageCls: 'localizabletextedit-ico-btn-primary'
		};
		this.addEvents(
			'localizablepropertychange'
		);
		this.updateValue();
	},
	
	updateValue: function () {
		var value = this.value;
		if (Ext.isEmpty(value.currentCultureName)) {
			value.currentCultureName = Terrasoft.CultureInfo.name;
		}
		var cultures = Terrasoft.AvailableCultures;
		for(var i = 0, l = cultures.length; i < l; i++) {
			var culture = cultures[i];
			var cultureValue = this.findCulture(culture.name, true);
			if (!cultureValue) {
				value.values.push({
					name: culture.name,
					caption: culture.caption,
					hasValue: false,
					value: ''
				});
			}
		}
	},
	
	initEvents: function() {
		Terrasoft.LocalizableTextEdit.superclass.initEvents.call(this);
		this.addEvents('editdata');
	},

	onRender: function (ct, position) {
		Terrasoft.LocalizableTextEdit.superclass.onRender.call(this, ct, position);
		this.hiddenField = this.el.insertSibling({
			tag: 'input',
			type: 'hidden',
			name: this.id + '_Value',
			id: this.id + '_Value'
		}, 'before', true);
	},
	
	onPrimaryToolButtonClick: function() {
		if (!this.enabled) {
			return;
		}
		Terrasoft.LocalizableTextEdit.superclass.onPrimaryToolButtonClick.call(this,
			null, this.el, { t: this.primaryToolButton });
		this.showEditWindow();
	},
	
	showEditWindow: function(){
		var needRecalculateHeight = false;
		if (!this.editWindow){
			this.editWindow = this.createEditWindow();
			needRecalculateHeight = true;
		}
		else {
			this.updateEditWindowControlValues();
		}
		var editWindow = this.editWindow;
		editWindow.show();
		if (needRecalculateHeight) {
			var editWindowItems = editWindow.items.items;
			var mainLayout = editWindowItems[0];
			var editLayout = mainLayout.items.items[0];
			var mainLayoutHeight = mainLayout.getHeight();
			var editLayoutHeight = editLayout.getHeight();
			if (editLayoutHeight < mainLayoutHeight) {
				mainLayout.height = undefined;
				mainLayout.flex = undefined;
				mainLayout.setHeight(editLayoutHeight);
				mainLayout.doLayout();
				mainLayoutHeight = mainLayout.getHeight();
				var height = mainLayoutHeight + editWindowItems[1].getHeight() + editWindow.header.getHeight();
				editWindow.setHeight(height);
			}
		}
	},
	
	createEditWindow: function(){
		var window = new Terrasoft.Window({
			caption: this.caption,
			width: 400,
			height: 500,
			modal: true,
			frameStyle: 'padding: 0 0 0 0',
			resizable: false,
			closeAction: 'hide'
		});
		var mainLayout = new Terrasoft.ControlLayout({
			direction: 'vertical',
			height: '100%',
			width: '100%',
			autoScroll: true,
			layoutConfig: {
				padding: '0 5 0 5'
			}
		});
		window.add(mainLayout);
		this.addEditWindowControls(mainLayout);
		this.addEditWindowButtons(window);
		return window;
	},
	
	addEditWindowControls: function(mainLayout){
		var editLayout = new Terrasoft.ControlLayout({
			direction: 'vertical',
			width: '100%',
			fitHeightByContent: true,
			displayStyle: 'controls',
			layoutConfig: {
				padding: '5 5 5 5'
			}
		});
		var item, memoEdit;
		if (this.values) {
			for (var i = 0, count = this.values.length; i < count; i++){
				item = this.values[i];
				memoEdit = new Terrasoft.MemoEdit({
					id: this.id + item.name,
					caption: item.caption,
					value: item.value,
					cultureName: item.name,
					width: '100%',
					height: this.memoHeight,
					useDefTools: false
				});
				memoEdit.on('change', this.onCultureValueChange, this);
				editLayout.add(memoEdit);
			}
		}
		mainLayout.add(editLayout);
	},
	
	addEditWindowButtons: function(mainLayout){
		var buttonsLayout = new Terrasoft.ControlLayout({
			width: '100%',
			fitHeightByContent: true,
			displayStyle: 'footer'
		});
		var stringListCommon = Ext.StringList('WC.Common');
		var spacer = new Ext.Spacer({size:'100%'});
		buttonsLayout.add(spacer);
		var okButton = new Terrasoft.Button({
			id: 'okButton',
			caption: stringListCommon.getValue('Button.Ok'),
			handler: this.onEditComplete.createDelegate(this)
		});
		buttonsLayout.add(okButton);
		var cancelButton = new Terrasoft.Button({
			id: 'cancelButton',
			caption: stringListCommon.getValue('Button.Cancel'),
			handler: this.onCloseWindow.createDelegate(this)
		});
		buttonsLayout.add(cancelButton);
		mainLayout.add(buttonsLayout);
	},
	
	onCloseWindow: function(){
		this.editWindow.close();
	},
	
	onEditComplete: function(){
		var item, memoEdit, oldValue, newValue;
		for (var i=0, count=this.values.length; i<count; i++){
			item = this.values[i];
			oldValue = item.value;
			memoEdit = Ext.get(this.id + item.name);
			newValue = memoEdit.dom.value;
			if (newValue != oldValue){
				item.value = newValue;
				this.fireEvent('localizablepropertychange', this, item.name, newValue, oldValue);
			}
		}
		this.setValue(this.getWindowValues());
		this.editWindow.close();
	},
	
	updateEditWindowControlValues: function(){
		var values = this.values;
		for (var i = 0, count = values.length; i < count; i++){
			var item = values[i];
			var memoEdit = Ext.get(this.id + item.name);
			memoEdit.dom.value = item.value;
		}
	},

	getWindowValues: function() {
		var windowValue = {
			values: this.values,
			currentCultureName: this.value.currentCultureName
		};
		return Ext.util.JSON.encode(windowValue);
	},

	onCultureValueChange: function(editor, value, oldValue, opt) {
		var culture = this.findCulture(editor.cultureName);
		culture.hasValue = true;
		culture.value = value;
	},

	onChange: function(o, value, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, value, this.getCurrentCultureValue());
			}
			this.fileSelected = false;
		}
	},

	checkChange: function() {
		var newValue = this.el.dom.value;
		var currentCultureName = this.value.currentCultureName;
		var currentCulture = this.findCulture(currentCultureName, true);
		if (currentCulture.value !== newValue) {
			currentCulture.value = newValue;
			currentCulture.hasValue = true;
		}
		if (this.rendered) {
			this.hiddenField.value = Ext.util.JSON.encode(this.value);
		}
		if (this.editWindow) {
			var memoEdit = Ext.get(this.id + currentCultureName);
			memoEdit.dom.value = newValue;
			currentCulture = this.findCulture(currentCultureName, false);
			currentCulture.value = newValue;
			//this.updateEditWindowControlValues();
		}
		Terrasoft.LocalizableTextEdit.superclass.checkChange.call(this);
	},

	setValue: function(value, isInitByEvent) {
		if (value == undefined || Ext.isEmpty(value)) {
			return;
		}
		value = value instanceof Object ? value : Ext.util.JSON.decode(value);
		this.value = {
			values: value.values,
			currentCultureName: value.currentCultureName
		};
		var rendered = this.rendered;
		if (rendered) {
			this.hiddenField.value = Ext.util.JSON.encode(this.value);
			if (value.values && value.values.length == 1) {
				this.primaryToolButton.hide();
			}
		}
		this.values = value.values;
		rendered && this.actualizeDisplayValue();
		var startValue = Ext.util.JSON.encode(this.startValue);
		this.fireChangeEvent(this.getWindowValues(), startValue, isInitByEvent);
	},

	getValue: function () {
		return Ext.util.JSON.encode(this.value);
	},

	actualizeDisplayValue: function() {
		this.el.dom.value = this.getCurrentCultureValue() || "";
	},

	getCurrentCultureValue: function() {
		var currentCulture = this.findCulture(this.value.currentCultureName);
		return (currentCulture && currentCulture.value) || null;
	},

	getCultureValue: function(cultureName) {
		var culture = this.findCulture(cultureName);
		return culture.value;
	},

	findCulture: function(cultureName, isValue) {
		var values = isValue ? this.value.values : this.values;
		for (var i = 0; i < values.length; i++) {
			var culture = values[i];
			if (culture.name == cultureName) {
				return culture;
			}
		}
		return null;
	}

});

Ext.reg('localizabletextedit', Terrasoft.LocalizableTextEdit);