Terrasoft.FileUploadEdit = Ext.extend(Terrasoft.BaseEdit, {
	type : 'file',
	width : 150,
	readOnly: true,
	submitFileOnChange: true,
	uploadButtonVisible: false,
	focusOnClick: false,

	initComponent: function() {
		var configBtn;
		if (!this.toolsConfig) {
			this.toolsConfig = [];
		} else {
			configBtn = this.toolsConfig;
			this.toolsConfig = [];
		}		
		this.toolsConfig.push({
			id: this.id ? this.id + '_OpenToolButton' : Ext.id(),
			imageCls: 'fileuploadedit-ico-btn-open'
		});
		this.toolsConfig.push({
			id: this.id ? this.id + '_ResetToolButton' : Ext.id(),
			enabled: false,
			imageCls: 'fileuploadedit-ico-btn-reset'
		});
		if (this.uploadButtonVisible) {
			this.toolsConfig.push({
				id: this.id ? this.id + '_UploadToolButton' : Ext.id(),
				enabled: false,
				upload: true,
				imageCls: 'fileuploadedit-ico-btn-upload'
			});
		}
		if (configBtn) {
			if (Ext.isArray(configBtn)) {
				Ext.each(configBtn, function(t, i) {
					this.toolsConfig.push(t);
				}, this);
			} else {
				this.toolsConfig.push(configBtn);
			}
		}
		Terrasoft.FileUploadEdit.superclass.initComponent.call(this);
		this.addEvents(
			'fileselected',
			'beforeupload',
			'upload'
		);
	},

	validate: function() {
		var isValid = Terrasoft.FileUploadEdit.superclass.validate.call(this);
		if (isValid && this.required) {
			var stringListCommon = Ext.StringList('WC.Common');
			if (stringListCommon) {
				isValid = (this.getValue() !== stringListCommon.getValue('FileUploadEdit.NotSet'));
			}
		}
		return isValid;
	},

	resetFile: function(e) {
		if (this.enabled && !this.designMode) {
			var stringListCommon = Ext.StringList('WC.Common');
			Ext.MessageBox.confirm(stringListCommon.getValue('MessageType.Warning'), 
				stringListCommon.getValue('MessageType.ClearFileSelection'), function(btn) {
					if (btn == 'yes') {
						this.reset(true);
						this.resetFileToolButton.disable();
						if (this.uploadFileToolButton) {
							this.uploadFileToolButton.disable();
						}
					}
				}, this);
		}
	},

	onRender : function (ct, position) {
		Terrasoft.FileUploadEdit.superclass.onRender.call(this, ct, position);
		this.wrap.addClass('x-form-file-wrap');
		this.el.dom.removeAttribute('name');
		this.createFileInput();
		this.selectFileToolButton = this.tools[0];
		this.resetFileToolButton = this.tools[1];
		if (this.tools.length > 2 && this.tools[2].upload) {
			this.uploadFileToolButton = this.tools[2];
			this.uploadFileToolButton.on('click', function() {
				this.submitFile(true);
			}, this);
		}
		this.resetFileToolButton.on('click', this.resetFile, this);
	},

	setDisplayText: function(fileName) {
		Ext.form.TextField.superclass.setValue.call(this, fileName);
	},

	inputOver: function(e) {
		this.selectFileToolButton.addClass('x-edit-toolbutton-over');
	},

	inputOut: function(e) {
		this.selectFileToolButton.removeClass('x-edit-toolbutton-over');
	},

	inputDown: function(e) {
		this.selectFileToolButton.addClass('x-edit-toolbutton-click');
	},

	inputUp: function(e) {
		this.selectFileToolButton.removeClass('x-edit-toolbutton-click');
	},

	requestcallback: function(o) {
		if (this.fileInput && this.fileInput.dom.value) {
			var fileName = this.extractFileName();
			this.reset();
			Ext.form.TextField.superclass.setValue.call(this, fileName);
			Ext.AjaxEvent.un('requestcomplete', this.requestcallback, this);
		}
	},

	checkLoadedFile: function() {
		return this.fileInput && this.fileInput.dom.value;
	},

	setValue: function(value) {
		var oldValue = this.getValue();
		if (oldValue == value) {
			return;
		}
		var stringListCommon = Ext.StringList('WC.Common');
		var noImageText = stringListCommon.getValue('FileUploadEdit.NotSet');
		if (value && value != noImageText && value != '') {
			this.resetFileToolButton.enable();
			if (this.uploadFileToolButton) {
				this.uploadFileToolButton.enable();
			}
		}
		Ext.form.TextField.superclass.setValue.call(this, value);
	},

	submitFile: function(firePropertyChangeEvent) {
		if (!this.checkLoadedFile) {
			return;
		}
		var fileName = this.extractFileName();
		var encType = document.forms[0].enctype;
		var method = document.forms[0].method;
		document.forms[0].setAttribute('enctype','multipart/form-data');
		document.forms[0].setAttribute('method','post');
		Ext.AjaxEvent.on('requestcomplete', this.requestcallback, this);
		if (firePropertyChangeEvent) {
			this.fireEvent("beforeupload", this, {});
		} else {
			Terrasoft.TextEdit.superclass.setValue.call(this, fileName);
		}
		this.resetFileToolButton.enable();
		if (this.uploadFileToolButton) {
			this.uploadFileToolButton.enable();
		}
		document.forms[0].setAttribute('enctype', encType);
		document.forms[0].setAttribute('method', method);
		if (this.enabled && !this.designMode) {
			this.fireEvent("upload", this, {});
		}
	},

	extractFileName: function() {
		if (!this.fileInput || !this.fileInput.dom.value) {
			return '';
		}
		var fileName = this.fileInput.dom.value;
		var indexCharPath = fileName.lastIndexOf('\\');
		return indexCharPath == -1 ? fileName : fileName.substr(indexCharPath + 1);
	},

	beforeUploadHandler: function() {
		var fileName = this.extractFileName();
		Terrasoft.FileUploadEdit.superclass.setValue.call(this, fileName);
		this.un('beforeupload', this.beforeUploadHandler, this);
	},

	createFileInput: function () {
		if (this.fileInput) {
			Ext.destroy(this.fileInput);
		}
		this.fileInput = this.wrap.createChild({
			id   : this.getFileInputId(),
			name : this.name || this.getFileInputId(),
			cls  : 'x-form-file',
			tag  : 'input',
			size : '1024',
			type: this.type,
			runat: 'server'
		});
		if (this.submitFileOnChange) {
			this.on('beforeupload', this.beforeUploadHandler, this);
		}
		var numBtns = 3;
		if (!this.uploadButtonVisible) {
			numBtns--;
		}
		this.fileInput.setRight(this.imageWidth * (numBtns - 1) + (this.tools.length - numBtns) * this.imageWidth);
		this.fileInput.setWidth('100%');
		this.fileInput.on('mouseover',this.inputOver, this);
		this.fileInput.on('mouseout',this.inputOut, this);
		this.fileInput.on('mousedown',this.inputDown, this);
		this.fileInput.on('mouseup',this.inputUp, this);
		if (this.focusOnClick == true) {
			this.fileInput.on('click', function() {
				this.el.focus();
			}, this);
		}
		this.fileInput.on('change', function () {
			this.fireEvent('fileselected', this, {});
			if (this.submitFileOnChange) {
				this.submitFile(true);
			} else {
				var fileName = this.extractFileName();
				Terrasoft.TextEdit.superclass.setValue.call(this, fileName);
			}
		}, this);
		if (this.designMode) {
			this.fileInput.dom.disabled = true;
		}
		if (this.disabled) {
			this.fileInput.dom.disabled = true;
		}
	},

	getFileInputId : function () {
		return this.id + '-file';
	},

	disableTools: function (disabled) {
		if (!this.rendered) {
			return;
		}
		if (!this.fileInput) {
			this.selectFileToolButton.dom.disabled = disabled;
			return;
		}
		if (!this.designMode) {
			this.fileInput.dom.disabled = disabled;
		}
		if (this.fileInput.dom.value && this.fileInput.dom.value != '') {
			this.resetFileToolButton.el.dom.disabled = disabled;
			if (this.uploadFileToolButton) {
				this.uploadFileToolButton.dom.disabled = disabled;
			}
		} else {
			this.resetFileToolButton.el.dom.disabled = true;
			if (this.uploadFileToolButton) {
				this.uploadFileToolButton.dom.disabled = true;
			}
		}
	},

	setEnabled: function (enabled) {
		Terrasoft.FileUploadEdit.superclass.setEnabled.call(this, enabled);
		this.disableTools(!enabled);
	},

	setDisabled: function (disabled) {
		Terrasoft.FileUploadEdit.superclass.setDisabled.call(this, disabled);
		this.disableTools(disabled);
	},

	reset: function (firePropertyChangeEvent) {
		this.createFileInput();
		var stringListCommon = Ext.StringList('WC.Common');
		var noImageText = stringListCommon.getValue('FileUploadEdit.NotSet');
		if (firePropertyChangeEvent) {
			Terrasoft.FileUploadEdit.superclass.setValue.call(this, noImageText);
		} else {
			Ext.form.TextField.superclass.setValue.call(this, noImageText);
		}
	},

	beforeDestroy: function() {
		if (this.rendered) {
			if (this.uploadFileToolButton) {
				this.uploadFileToolButton.un('click', function() {
					this.submitFile(true);
				}, this);
			}
			this.resetFileToolButton.un('click', this.resetFile, this);
			this.fileInput.removeAllListeners();
		}
		Terrasoft.FileUploadEdit.superclass.beforeDestroy.call(this);
	},

	onDestroy: function() {
		Ext.AjaxEvent.un('requestcomplete', this.requestcallback, this);
		if (this.fileInput) {
			Ext.destroy(this.fileInput);
		}
		if (this.rendered) {
			Ext.destroy(this.selectFileToolButton, this.resetFileToolButton);
		}
		if (this.uploadFileToolButton) {
			Ext.destroy(this.resetFileToolButton);
		}
		Terrasoft.FileUploadEdit.superclass.onDestroy.call(this);
	}
});

Ext.reg('fileuploadedit', Terrasoft.FileUploadEdit);