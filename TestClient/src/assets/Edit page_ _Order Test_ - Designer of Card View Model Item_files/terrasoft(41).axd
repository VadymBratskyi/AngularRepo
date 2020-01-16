Ext.form.TextArea=Ext.extend(Ext.form.TextField,{
	enterIsSpecial: false,
	supportsCaption: true,
	supportsCaptionNumber: true,
	captionVerticalAlign: 'top',
	preventScrollbars: false,
	width: 300,
	height: 100,
	wordWrap: true,
	mimicing: false,
	useDefTools: false,

	initEvents: function() {
		Ext.form.TextArea.superclass.initEvents.call(this);
		this.on("specialkey", this.specialkey,this);
	},

	onRender: function(ct ,position) {
		if (!this.el) {
			this.defaultAutoCreate = {
				tag: "textarea",
				autocomplete: "off"
			};
		}
		if (this.wordWrap === false) {
			this.defaultAutoCreate.wrap = "off";
		}
		Ext.form.TextArea.superclass.onRender.call(this, ct, position);
		this.wrap = this.el.wrap({
			cls: "x-form-textarea-wrap"
		});
		if (Ext.isSafari) {
			this.el.setStyle('resize', 'none');
		}
		this.el.setOverflow('auto');
		if (this.preventScrollbars === true) {
			this.el.setStyle("overflow", "hidden");
		}
		this.toolsConfig = this.toolsConfig
			? (!Ext.isArray(this.toolsConfig) ? [this.toolsConfig] : this.toolsConfig)
			: [];
		var dtb = this.dynamicToolbar = new Ext.Layer({
			id: this.getId('dtb'),
			cls: "x-memo-floating-toolbar",
			constrain: false
		});
		dtb.toolBar = new Terrasoft.ControlLayout({
			width: '100%',
			displayStyle: 'topbar'
		}).render(dtb);
		if (this.useDefTools && this.enabled) {
			this.addDefTools();
		}
		this.initTools(this.toolsConfig);
		this.addToolBtn(this.tools);
		delete this.toolsConfig;
	},

	specialkey: function(field, e) {
		var key = e.getKey();
		if (key == e.TAB && e.ctrlKey == true) {
			e.stopEvent();
			this.insertTextFragment('\t');
		}
	},

	getId: function(id) {
		return String.format("{0}_{1}", this.id, id);
	},

	addToolBtn: function(toolBtns) {
		if (Ext.isEmpty(toolBtns)) {
			return;
		}
		var dtb = this.dynamicToolbar;
		if (!dtb) {
			return;
		}
		dtb.toolBar.add.apply(dtb.toolBar, toolBtns);
	},

	addDefTools: function() {
		this.toolsConfig.unshift({
				id: this.getId('btnCopy')
			},
			{
				id: this.getId('btnPaste')
			},
			(this.toolsConfig.length > 0
				? { xtype: 'tbseparator' }
				: {})
		);
	},

	onFocus: function() {
		Ext.form.TextArea.superclass.onFocus.call(this);
		// -- todo устранить дублирование кода из TextField
		if (!this.mimicing) {
			this.mimicing = true;
			this.startValue = this.getValue();
			Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, { delay: 10 });
			if (this.monitorTab) {
				this.el.on("keydown", this.checkTab, this);
			}
		}
		this.showDynamicToolbar();
	},

	onBlur: Ext.emptyFn,

	// -- todo устранить дублирование кода из TextField

	checkTab: function(e) {
		if (e.getKey() == e.TAB) {
			this.triggerBlur();
		}
	},

	mimicBlur: function(e) {
		if (!this.wrap.contains(e.target) && this.validateBlur(e)) {
			this.triggerBlur();
		}
	},

	triggerBlur: function() {
		this.mimicing = false;
		Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.mimicBlur, this);
		if (this.monitorTab) {
			this.el.un("keydown", this.checkTab, this);
		}
		this.hideDynamicToolbar();
		Ext.form.TextArea.superclass.onBlur.call(this);
	},

	// --

	validateBlur: function(e) {
		var dtb = this.dynamicToolbar;
		if (!dtb || !dtb.toolBar) {
			return true;
		}
		if (dtb.toolBar.el.contains(e.target)) {
			this.el.focus();
			return false;
		}
		return true;
	},

	showDynamicToolbar: function() {
		if (!this.rendered || !this.dynamicToolbar || this.tools.length == 0) {
			return;
		}
		var dtb = this.dynamicToolbar;
		dtb.setWidth(this.wrap.getWidth());
		dtb.show().alignTo(this.wrap, 'tl', [0, -dtb.getHeight()]);
	},

	hideDynamicToolbar: function() {
		if (!this.rendered || !this.dynamicToolbar) {
			return;
		}
		this.dynamicToolbar.hide();
	},

	setSize: function(w, h) {
		w = this.processSizeUnit(w);
		h = this.processSizeUnit(h);
		Ext.form.TextArea.superclass.setSize.call(this,w,h);
		if (h == undefined || !this.rendered) {
			return;
		}
		this.wrap.setHeight(h);
	},

	getResizeEl: function() {
		return this.captionWrap || this.wrap;
	},

	getPositionEl: function() {
		return this.captionWrap || this.wrap;
	},

	getActionEl: function() {
		return this.wrap;
	},

	getCaptionPositionOffset: function() {
		if (this.captionPosition == 'left') {
			if (this.captionVerticalAlign == 'top' || this.captionVerticalAlign == 'notset') {
				return 2.5;
			} else if (this.captionVerticalAlign == 'middle') {
				return -1;
			}
		}
		return 0;
	},

	fireKey: function(e) {
		var key = e.getKey();
		if (e.isSpecialKey() && (this.enterIsSpecial || (key != e.ENTER || e.hasModifier()))) {
			this.fireEvent("specialkey", this, e);
		} else if (this.isScriptEditor&&key == e.F2) {
			this.checkChange();
			this.showScriptEditWindow();
		}
	},
	
	getScriptEditWindow: function() {
		var scriptWindowEdit = DesignModeManager.scriptWindowEdit;
		if (!scriptWindowEdit) {
			scriptWindowEdit = DesignModeManager.scriptWindowEdit = new Terrasoft.ScriptWindowEdit({
				designModeManager: DesignModeManager,
				width: '800px',
				height: '600px'
			});
		}
		return scriptWindowEdit;
	},

	showScriptEditWindow: function() {
		/*
		var dataSource = this.dataSource;
		var column = this.getColumn();
		if(!column || typeof DesignModeManager == "undefined") {
			return;
		}
		var primaryColumnName = dataSource.getPrimaryColumnName();
		var itemUId = dataSource.getColumnValue(primaryColumnName);
		var scriptWindowEdit = this.getScriptEditWindow();
		scriptWindowEdit.setEditingItem({
			value: this.getValue(),
			itemUId: itemUId,
			propertyName: column.name
		});
		scriptWindowEdit.show();
		*/

		var dataSource = this.dataSource;
		var column = this.getColumn();
		if(!column || typeof DesignModeManager == "undefined") {
			return;
		}
		var columnName = column.name;
		var pagePath = 'ScriptMemoEdit.aspx';
		var schemaUId = DesignModeManager.parentSchemaUId || DesignModeManager.schemaUId;
		var uId = dataSource.getColumnValue('UId');
		var params = '?uid=' + uId + '&propertyname=' + columnName + '&schemauid=' + schemaUId;
		var url = Terrasoft.applicationPath + '/' + pagePath + params;
		var windowName = (schemaUId + uId + columnName).replace(/-/g, '');
		var winParams = 'location=no,toolbar=no,menubar=no,scrollbars=no,status=no';
		window.open(url, windowName, winParams);
	},

	setValue: function(value, isInitByEvent) {
		var oldValue = this.getRawValue();
		if (value == this.startValue && value == oldValue) {
			return;
		}
		value = Ext.form.TextArea.superclass.checkSize.call(this, value);
		Ext.form.TextArea.superclass.setValue.call(this, value);
		value = value || "";
		this.fireChangeEvent(value, oldValue, isInitByEvent);
	},

	fireChangeEvent: function(value, oldValue, isInitByEvent) {
		if (!this.valueInit) {
			return;
		}
		var opt = {
			isInitByEvent: isInitByEvent || false
		};
		this.startValue = value;
		this.fireEvent('change', this, value, oldValue, opt);
	},

	unFocus: function() {
		this.triggerBlur();
	},

	getSelectedText: function() {
		if (this.rendered) {
			if (document.selection) {
				this.focus();
				var range = document.selection.createRange();
				return range.text;
			} else {
				var elDom = this.el.dom;
				var value = elDom.value;
				var startIndex = elDom.selectionStart || 0;
				var endIndex = elDom.selectionEnd || value.length;
				if (elDom.selectionEnd == 0) {
					endIndex = 0;
				}
				return value.substring(startIndex, endIndex);
			}
		}
		return "";
	},

	insertTextFragment: function(text) {
		if (this.rendered) {
			var oldValue = this.getRawValue();
			if (document.selection) {
				this.focus();
				var range = document.selection.createRange();
				range.text = text;
				range.select();
			} else {
				var elDom = this.el.dom;
				var value = elDom.value;
				var startIndex = elDom.selectionStart || 0;
				var endIndex = elDom.selectionEnd || value.length;
				if (elDom.selectionEnd == 0) {
					endIndex = 0;
				}
				var beforeSelection = value.substring(0, startIndex);
				var afterSelection = value.substr(endIndex);
				elDom.value = beforeSelection + text + afterSelection;
				elDom.selectionStart = startIndex + text.length;
				elDom.selectionEnd = elDom.selectionStart;
			}
			this.validate();
			var newValue = this.getValue();
			this.fireChangeEvent(newValue, oldValue);
		}
	},
	
	encloseSelectedText: function(leftPart, rightPart) {
		this.insertTextFragment(leftPart + this.getSelectedText() + rightPart);
	}

});

Ext.reg('textarea', Ext.form.TextArea);

Terrasoft.MemoEdit = Ext.form.TextArea;

Ext.reg('memoedit', Terrasoft.MemoEdit);