Terrasoft.FileUploadButton = Ext.extend(Terrasoft.Button, {
	type : 'file',
	isMultiSelect: false,

	initComponent: function() {
		Terrasoft.FileUploadButton.superclass.initComponent.call(this);
		this.addEvents(
			'fileselected',
			'beforeupload',
			'upload'
		);
	},

	onRender : function (ct, position) {
		Terrasoft.FileUploadButton.superclass.onRender.call(this, ct, position);
		this.createFileInput();
	},

	getFileInputId : function() {
		return this.id + '-file';
	},

	createFileInput: function() {
		if (this.fileInput) {
			Ext.destroy(this.fileInput);
		}
		var id = this.getFileInputId();
		if (Ext.isIE) {
			var button = this.wrap.child('.x-btns-m');
			button.wrap({
				tag   : 'label',
				cls   : 'x-btns-label',
				"for" : id
			});
		}
		var container = this.wrap.child('.x-btns');
		this.fileInput = container.createChild({
			id		: id,
			name	: this.name || id,
			cls		: 'x-btns-file-upload',
			tag		: 'input',
			type	: 'file',
			size	: '1024'
		});
		if (this.isMultiSelect) {
			this.fileInput.set({
				multiple : ""
			});
		}
		this.fileInput.on('change', function() {
			var input = this.fileInput;
			if (input && input.dom.value) {
				var form = document.forms[0];
				form.setAttribute('enctype','multipart/form-data');
				form.setAttribute('method','post');
				this.fireEvent('upload', this, {});
			}
		}, this);
		if (!Ext.isIE) {
			this.on('click', function() {
				this.fileInput.dom.click();
			}, this);
		}
		if (this.designMode || this.disabled) {
			this.fileInput.dom.disabled = true;
		}
	}
});

Ext.reg('fileuploadbutton', Terrasoft.FileUploadButton);